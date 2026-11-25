defmodule CuratorianWeb.Public.Events.RegisterLive do
  @moduledoc """
  Multi-step event registration flow with payment integration.
  Guides users through registration questions, payment (if required), and confirmation.
  """

  use CuratorianWeb, :live_view

  alias Curatorian.EventPayments
  alias Curatorian.Public
  alias CuratorianWeb.Public.Events.TimeFormat

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    current_scope = socket.assigns.current_scope
    user_id = if current_scope && current_scope.user, do: current_scope.user.id

    # Guests register without an account (Google-Form style) — the wizard
    # collects their name/email/phone and the organizer approves. Login is
    # offered as a gentle option, never forced (see the guest step).
    case Public.get_event_by_slug(slug) do
      nil ->
        raise Ecto.NoResultsError, queryable: "event"

      event ->
        # Guests who logged in (e.g. via Google after being sent back here)
        # claim their matching guest registrations before the already-
        # registered check — the redirect then finds them a seat in the
        # account. Fire and forget; a failure must never block the wizard.
        if user_id do
          user = current_scope.user
          Public.claim_guest_registrations(user_id, user.email)
        end

        # Check if already registered (logged-in users only)
        existing_registration =
          if user_id, do: Public.get_registration_for_user(user_id, event.id)

        if existing_registration do
          {:ok,
           socket
           |> put_flash(:info, "Anda sudah terdaftar untuk event ini.")
           |> push_navigate(to: "/events/#{event.slug}")}
        else
          remote_ip =
            socket
            |> get_connect_info(:peer_data)
            |> case do
              %{address: address} -> address
              _ -> nil
            end

          {:ok,
           socket
           |> assign(:page_title, "Daftar — #{event.title}")
           |> assign(:event, event)
           |> assign(:user_id, user_id)
           |> assign(:remote_ip, remote_ip)
           # Guests must complete the Turnstile CAPTCHA before submitting
           # (the public form is spam-fillable otherwise); account holders
           # are behind login + per-user rate limits.
           |> assign(:captcha_valid, not is_nil(user_id))
           |> assign(:turnstile_theme, "light")
           |> assign(:registration, nil)
           |> assign(:current_step, 1)
           |> assign(:max_steps, 3)
           |> assign(:registration_data, %{})
           |> assign(:form, to_form(%{}, as: :registration))
           |> assign(:registration_code, nil)
           |> assign(:noindex, true)}
        end
    end
  end

  def handle_event("next_step", params, socket) do
    step = socket.assigns.current_step
    registration_data = Map.merge(socket.assigns.registration_data, params)

    {:noreply,
     socket
     |> assign(:registration_data, registration_data)
     |> assign(:current_step, step + 1)}
  end

  def handle_event("prev_step", _params, socket) do
    step = socket.assigns.current_step

    {:noreply, assign(socket, :current_step, max(1, step - 1))}
  end

  def handle_event("turnstile:success", _params, socket) do
    {:noreply, assign(socket, :captcha_valid, true)}
  end

  def handle_event("turnstile:error", _params, socket) do
    {:noreply, assign(socket, :captcha_valid, false)}
  end

  def handle_event("turnstile:expired", _params, socket) do
    {:noreply, assign(socket, :captcha_valid, false)}
  end

  def handle_event("submit_registration", params, socket) do
    %{event: event, user_id: user_id, registration_data: data} = socket.assigns

    user = socket.assigns.current_scope && socket.assigns.current_scope.user

    # Unwrap the form params: <.form for={to_form(%{}, as: :registration)}>
    # nests the answers under "registration".
    form_params = params["registration"] || %{}
    answers = extract_answers(event.registration_questions, form_params)

    # Server-side required-question validation — the HTML `required`
    # attribute is not enforcement.
    case missing_required_answer(event.registration_questions, answers) do
      nil ->
        # Guests must pass the Turnstile CAPTCHA — the client gate is not
        # enforcement, a bot can fire phx events directly.
        with {:ok, _} <- maybe_verify_turnstile(params, socket, user) do
          do_submit_registration(socket, user, user_id, event, form_params, answers, data)
        else
          {:error, _reason} ->
            {:noreply,
             assign(socket, :captcha_valid, false)
             |> put_flash(:error, "Verifikasi CAPTCHA gagal. Silakan coba lagi.")}
        end

      question ->
        {:noreply, put_flash(socket, :error, "Mohon jawab pertanyaan: #{question}")}
    end
  end

  @impl true
  def handle_event("start_payment", _params, socket) do
    %{event: event, registration: registration, user_id: user_id} = socket.assigns

    if is_nil(registration) do
      {:noreply, put_flash(socket, :error, "Pendaftaran tidak ditemukan.")}
    else
      # Guests pay with their registration token as the credential; account
      # registrations are authorized by the logged-in user.
      identity_opts =
        if user_id, do: [], else: [registration_token: registration.token]

      case EventPayments.start_payment(event.id, registration.id, user_id, identity_opts) do
        {:ok, %{redirect_url: redirect_url}} ->
          {:noreply, redirect(socket, external: redirect_url)}

        {:error, _reason} ->
          {:noreply,
           socket
           |> put_flash(
             :warning,
             "Pembayaran online sedang tidak tersedia. Penyelenggara akan menghubungi Anda untuk penyelesaian pembayaran."
           )}
      end
    end
  end

  # First human-readable changeset error, in Indonesian — guests don't get a
  # form they can fix field-by-field after submit, so the flash must say why.
  defp registration_error_message(changeset) do
    {message, _} =
      changeset.errors
      |> Enum.find(fn {_field, {msg, _opts}} -> msg != "already registered for this event" end)
      |> Kernel.||({nil, nil})

    case message do
      "guest name is required with a guest email" -> "Mohon isi nama Anda untuk mendaftar."
      "guest email is required with a guest name" -> "Mohon isi email Anda untuk mendaftar."
      "must be a valid email address" -> "Format email tidak valid."
      _ -> "Gagal mendaftar, silakan coba lagi."
    end
  end

  defp maybe_verify_turnstile(_params, _socket, user) when user != nil, do: {:ok, :skipped}

  defp maybe_verify_turnstile(params, socket, nil) do
    # Test seam: tests can't produce real Turnstile tokens (see config/test.exs).
    if Application.get_env(:curatorian, :disable_turnstile, false) do
      {:ok, %{"success" => true}}
    else
      case params["cf-turnstile-response"] do
        token when is_binary(token) and token != "" ->
          Turnstile.verify(params, socket.assigns.remote_ip)

        _ ->
          {:error, :missing_turnstile_token}
      end
    end
  end

  defp do_submit_registration(socket, user, user_id, event, form_params, answers, data) do
    # Auto-fill the identity into the registration data (identity wins
    # over any same-named question), so organizers always receive the
    # participant's real name and contact. Logged-in users contribute
    # their account identity; guests type it on step 2.
    user_data =
      if user do
        %{
          "name" => user.fullname || user.username || "",
          "email" => user.email || "",
          "phone" => user.phone_number || ""
        }
      else
        %{
          "name" => form_params["guest_name"] || "",
          "email" => form_params["guest_email"] || "",
          "phone" => form_params["guest_phone"] || ""
        }
      end

    final_data = data |> Map.merge(answers) |> Map.merge(user_data)

    guest =
      if user do
        nil
      else
        %{"name" => form_params["guest_name"] || "", "email" => form_params["guest_email"] || ""}
      end

    opts = [
      registration_data: final_data,
      requires_approval: event.requires_approval,
      guest: guest
    ]

    case Public.register_for_event(user_id, event.id, opts) do
      {:ok, registration} ->
        {:noreply,
         socket
         |> assign(:registration, registration)
         |> assign(:registration_code, registration.registration_code)
         |> assign(:current_step, socket.assigns.current_step + 1)
         |> put_flash(:info, "Pendaftaran berhasil!")}

      {:error, :already_registered} ->
        {:noreply,
         socket
         |> put_flash(:error, "Anda sudah terdaftar untuk event ini.")
         |> push_navigate(to: "/events/#{event.slug}")}

      {:error, :rate_limited} ->
        {:noreply,
         put_flash(socket, :error, "Terlalu banyak permintaan. Silakan coba lagi nanti.")}

      {:error, :event_full} ->
        {:noreply, put_flash(socket, :error, "Kuota event sudah penuh.")}

      {:error, :registration_closed} ->
        {:noreply,
         socket
         |> put_flash(:error, "Pendaftaran untuk event ini sudah ditutup.")
         |> push_navigate(to: "/events/#{event.slug}")}

      {:error, :event_not_found} ->
        {:noreply,
         socket
         |> put_flash(:error, "Event tidak ditemukan.")
         |> push_navigate(to: "/events")}

      {:error, :no_identity} ->
        {:noreply, put_flash(socket, :error, "Mohon isi nama dan email untuk mendaftar.")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, put_flash(socket, :error, registration_error_message(changeset))}
    end
  end

  # Maps the form's question_N fields to registration_data entries keyed by
  # the question text — the organizer-side display and CSV export align
  # answers with the event's registration_questions by text. Blank answers
  # are dropped. Raw `params` (which include the nested form wrapper and
  # LiveView bookkeeping keys) are never merged into the data.
  defp extract_answers(questions, form_params) do
    questions
    |> List.wrap()
    |> Enum.with_index()
    |> Enum.reduce(%{}, fn {question, idx}, acc ->
      text = question["question"]
      answer = form_params["question_#{idx}"]

      if is_binary(answer) and String.trim(answer) != "" do
        Map.put(acc, text, String.trim(answer))
      else
        acc
      end
    end)
  end

  defp missing_required_answer(questions, answers) do
    questions
    |> List.wrap()
    |> Enum.find(fn question ->
      question["required"] == true and blank_answer?(answers[question["question"]])
    end)
    |> case do
      nil -> nil
      question -> question["question"]
    end
  end

  defp blank_answer?(answer), do: not is_binary(answer) or String.trim(answer) == ""

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="min-h-screen bg-base-200/30 py-12">
        <div class="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8">
          <%!-- Progress Steps --%>
          <nav aria-label="Progress" class="mb-8">
            <ol class="flex items-center justify-between">
              <%= for step <- 1..@max_steps do %>
                <li class={[
                  "flex items-center",
                  if(step < @max_steps, do: "flex-1")
                ]}>
                  <div class="relative flex items-center justify-center">
                    <div class={[
                      "flex items-center justify-center w-10 h-10 rounded-full border-2 transition-all",
                      if(@current_step > step,
                        do: "bg-primary border-primary text-primary-content",
                        else:
                          if(@current_step == step,
                            do: "border-primary text-primary bg-base-100",
                            else: "border-base-300 text-base-content/50 bg-base-100"
                          )
                      )
                    ]}>
                      <%= if @current_step > step do %>
                        <.icon name="hero-check" class="w-5 h-5" />
                      <% else %>
                        <span class="text-sm font-medium">{step}</span>
                      <% end %>
                    </div>
                  </div>

                  <%= if step < @max_steps do %>
                    <div class={[
                      "flex-1 h-0.5 mx-4 transition-colors",
                      if(@current_step > step, do: "bg-primary", else: "bg-base-300")
                    ]}>
                    </div>
                  <% end %>
                </li>
              <% end %>
            </ol>

            <div class="flex justify-between mt-3">
              <p class="text-sm font-medium">
                {step_title(@current_step, @event.is_paid)}
              </p>
              <p class="text-sm text-base-content/60">
                Step {@current_step} dari {@max_steps}
              </p>
            </div>
          </nav>

          <%!-- Registration Card --%>
          <div class="bg-base-100 rounded-lg shadow-xl p-6 sm:p-8">
            <%= case @current_step do %>
              <% 1 -> %>
                <.render_step_1 event={@event} user_id={@user_id} form={@form} />
              <% 2 -> %>
                <.render_step_2
                  event={@event}
                  user_id={@user_id}
                  form={@form}
                  registration_data={@registration_data}
                  captcha_valid={@captcha_valid}
                  turnstile_theme={@turnstile_theme}
                />
              <% 3 -> %>
                <.render_step_confirmation
                  event={@event}
                  registration={@registration}
                  registration_code={@registration_code}
                />
            <% end %>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp render_step_1(assigns) do
    ~H"""
    <div>
      <h2 class="text-2xl font-bold mb-2">Konfirmasi Detail</h2>
      <p class="text-base-content/70 mb-6">
        Pastikan informasi Anda sudah benar sebelum melanjutkan.
      </p>

      <div class="space-y-4 mb-6">
        <div class="p-4 bg-base-200 rounded-lg">
          <h3 class="font-semibold mb-2">{@event.title}</h3>
          <div class="space-y-1 text-sm text-base-content/70">
            <p>📅 {format_date(@event.starts_at)}</p>
            <p>
              🕐 {format_time(@event.starts_at, @event.timezone)} - {format_time(
                @event.ends_at,
                @event.timezone
              )}
            </p>
            <p>📍 {venue_text(@event)}</p>
            <%= if @event.is_paid do %>
              <p class="font-semibold text-primary mt-2">
                💰 {format_idr(@event.price_idr)}
              </p>
            <% end %>
          </div>
        </div>

        <%= if @user_id do %>
          <div class="alert alert-info">
            <.icon name="hero-information-circle" class="w-5 h-5" />
            <span>Pendaftaran akan menggunakan akun Anda yang sudah login.</span>
          </div>
        <% else %>
          <%!-- Gentle nudge — never blocks the guest flow. Identity fields
          live on step 2, inside the form that submits. --%>
          <div class="text-sm text-base-content/70 bg-base-200/60 rounded-xl p-3 space-y-2">
            <div class="flex items-start gap-2">
              <.icon name="hero-user-circle" class="w-5 h-5 shrink-0 mt-0.5 text-primary" />
              <span>
                Anda mendaftar sebagai tamu. Ingin pendaftaran tersimpan rapi di akun Anda?
                Masuk — dan pendaftaran Anda otomatis tersambung ke akun. Boleh juga
                dilewati, Anda tetap bisa mendaftar sebagai tamu.
              </span>
            </div>
            <.link
              href={"/login?return_to=" <> URI.encode_www_form("/events/#{@event.slug}/register")}
              class="btn btn-outline btn-sm w-full gap-2 border-base-300"
            >
              <svg class="size-4" viewBox="0 0 24 24" aria-hidden="true">
                <path
                  d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
                  fill="#4285F4"
                />
                <path
                  d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
                  fill="#34A853"
                />
                <path
                  d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"
                  fill="#FBBC05"
                />
                <path
                  d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
                  fill="#EA4335"
                />
              </svg>
              Masuk / daftar dengan Google
            </.link>
          </div>
        <% end %>
      </div>

      <div class="flex justify-end gap-3">
        <.link navigate={"/events/#{@event.slug}"} class="btn btn-ghost">
          Batal
        </.link>
        <button type="button" phx-click="next_step" class="btn btn-primary">
          Lanjutkan <.icon name="hero-arrow-right" class="w-4 h-4 ml-1" />
        </button>
      </div>
    </div>
    """
  end

  defp render_step_2(assigns) do
    ~H"""
    <div>
      <h2 class="text-2xl font-bold mb-2">Pertanyaan Pendaftaran</h2>
      <p class="text-base-content/70 mb-6">
        <%= if @event.registration_questions == [] do %>
          Tidak ada pertanyaan tambahan untuk event ini.
        <% else %>
          Mohon jawab pertanyaan berikut untuk menyelesaikan pendaftaran.
        <% end %>
      </p>

      <.form for={@form} id="registration-questions-form" phx-submit="submit_registration">
        <%= if is_nil(@user_id) do %>
          <%!-- Guest identity — inside the submitting form (Google-Form style). --%>
          <div class="space-y-3 mb-6 p-4 bg-base-200/40 rounded-xl">
            <p class="text-sm font-semibold text-base-content">Data Diri Anda</p>
            <div>
              <label class="text-sm font-medium text-base-content" for="guest-name">
                Nama Lengkap <span class="text-error">*</span>
              </label>
              <input
                type="text"
                id="guest-name"
                name="registration[guest_name]"
                class="input input-bordered w-full mt-1"
                placeholder="Nama Anda"
                required
              />
            </div>
            <div>
              <label class="text-sm font-medium text-base-content" for="guest-email">
                Email <span class="text-error">*</span>
              </label>
              <input
                type="email"
                id="guest-email"
                name="registration[guest_email]"
                class="input input-bordered w-full mt-1"
                placeholder="email@contoh.com"
                required
              />
              <p class="text-xs text-base-content/50 mt-1">
                Konfirmasi pendaftaran dan tautan peserta dikirim ke email ini.
              </p>
            </div>
            <div>
              <label class="text-sm font-medium text-base-content" for="guest-phone">
                Nomor WhatsApp <span class="text-base-content/40">(opsional)</span>
              </label>
              <input
                type="tel"
                id="guest-phone"
                name="registration[guest_phone]"
                class="input input-bordered w-full mt-1"
                placeholder="08xxxxxxxxxx"
              />
            </div>
          </div>
        <% end %>

        <%= if @event.registration_questions != [] do %>
          <div class="space-y-4 mb-6">
            <%= for {question, idx} <- Enum.with_index(@event.registration_questions) do %>
              <div>
                <.input
                  field={@form[:"question_#{idx}"]}
                  type={question["type"] || "text"}
                  label={question["question"]}
                  required={question["required"] || false}
                  placeholder={question["placeholder"]}
                />
              </div>
            <% end %>
          </div>
        <% end %>

        <%= if is_nil(@user_id) do %>
          <.captcha
            id="event_registration_turnstile"
            theme={@turnstile_theme}
            events={[:success, :error, :expired]}
            captcha_valid={@captcha_valid}
          />
          <div class="mb-4"></div>
        <% end %>

        <div class="flex justify-between gap-3">
          <button type="button" phx-click="prev_step" class="btn btn-ghost">
            <.icon name="hero-arrow-left" class="w-4 h-4 mr-1" /> Kembali
          </button>

          <button
            type="submit"
            class={
              "btn btn-primary" <>
                if(is_nil(@user_id) and !@captcha_valid, do: " btn-disabled opacity-50", else: "")
            }
            disabled={is_nil(@user_id) and !@captcha_valid}
          >
            Submit Pendaftaran <.icon name="hero-arrow-right" class="w-4 h-4 ml-1" />
          </button>
        </div>
      </.form>
    </div>
    """
  end

  defp render_step_confirmation(assigns) do
    ~H"""
    <div class="text-center py-6">
      <div class="mb-6">
        <div class="w-20 h-20 bg-success/10 rounded-full flex items-center justify-center mx-auto mb-4">
          <.icon name="hero-check-circle" class="w-12 h-12 text-success" />
        </div>

        <h2 class="text-2xl font-bold mb-2">Pendaftaran Berhasil!</h2>
        <p class="text-base-content/70">
          <%= if @event.is_paid do %>
            <%= if @event.requires_approval do %>
              Pendaftaran Anda tercatat. Selesaikan pembayaran online di bawah —
              setelah pembayaran, pendaftaran Anda ditinjau oleh penyelenggara.
            <% else %>
              Pendaftaran Anda tercatat. Selesaikan pembayaran online di bawah —
              pembayaran akan menyetujui pendaftaran Anda secara otomatis.
            <% end %>
          <% else %>
            <%= if @event.requires_approval do %>
              Pendaftaran Anda sedang ditinjau oleh penyelenggara.
            <% else %>
              Kode pendaftaran di bawah dapat digunakan untuk check-in saat event.
            <% end %>
          <% end %>
        </p>
      </div>

      <%= if @registration_code do %>
        <div class="bg-base-200 rounded-lg p-6 mb-6">
          <p class="text-sm text-base-content/60 mb-2">Kode Pendaftaran Anda</p>
          <p class="text-3xl font-mono font-bold tracking-wider text-primary">
            {@registration_code}
          </p>
          <p class="text-xs text-base-content/60 mt-2">
            Simpan kode ini untuk check-in saat event
          </p>
        </div>
      <% end %>

      <%!-- Do not rely on the confirmation email: the participant page (QR,
      session-code check-in, certificate, materials) must be reachable right
      here, immediately after registering. --%>
      <%= if @registration && is_binary(@registration.token) do %>
        <div class="rounded-xl border border-primary/30 bg-primary/5 p-4 mb-6 text-left space-y-2">
          <p class="text-sm font-semibold text-base-content">Halaman Peserta Anda</p>
          <p class="text-xs text-base-content/60">
            Berisi QR check-in, kode sesi, sertifikat, dan materi pembelajaran.
            Simpan tautan ini agar mudah dibuka saat event berlangsung.
          </p>
          <.link
            navigate={~p"/r/#{@registration.token}"}
            class="inline-flex w-full items-center justify-center gap-2 rounded-xl bg-primary px-4 py-2.5 text-sm font-semibold text-primary-content transition hover:brightness-105"
          >
            <.icon name="hero-qr-code" class="size-4" /> Buka Halaman Peserta
          </.link>
        </div>
      <% end %>

      <%= if @event.is_paid and @registration do %>
        <button
          phx-click="start_payment"
          class="btn btn-warning w-full mb-6 gap-2"
        >
          <.icon name="hero-credit-card" class="w-5 h-5" /> Bayar Sekarang
        </button>
      <% end %>

      <div class="flex flex-col sm:flex-row gap-3 justify-center">
        <.link navigate={"/events/#{@event.slug}"} class="btn btn-ghost">
          Kembali ke Event
        </.link>
        <.link navigate="/foyer" class="btn btn-outline btn-primary">
          Lihat Dashboard Saya
        </.link>
      </div>
    </div>
    """
  end

  defp step_title(1, _paid), do: "Konfirmasi Detail"
  defp step_title(2, _paid), do: "Pertanyaan Pendaftaran"
  defp step_title(3, _paid), do: "Konfirmasi"

  defp format_date(datetime), do: TimeFormat.date(datetime)

  defp format_time(datetime, tz) do
    TimeFormat.time(datetime, tz)
  end

  defp venue_text(event) do
    case event.mode do
      :online -> "Online — #{event.platform || "Platform Digital"}"
      :offline -> event.venue_name || "Venue"
      :hybrid -> "Hybrid — Online & #{event.venue_name || "Venue"}"
    end
  end

  defp format_idr(amount) when is_integer(amount) do
    "Rp " <>
      (amount
       |> Integer.to_string()
       |> String.reverse()
       |> String.split("", trim: true)
       |> Enum.chunk_every(3)
       |> Enum.join(".")
       |> String.reverse())
  end

  defp format_idr(_), do: "Rp 0"
end
