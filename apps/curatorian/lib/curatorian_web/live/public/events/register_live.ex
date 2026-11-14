defmodule CuratorianWeb.Public.Events.RegisterLive do
  @moduledoc """
  Multi-step event registration flow with payment integration.
  Guides users through registration questions, payment (if required), and confirmation.
  """

  use CuratorianWeb, :live_view

  alias Curatorian.EventPayments
  alias Curatorian.Public

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    case Public.get_event_by_slug(slug) do
      nil ->
        raise Ecto.NoResultsError, queryable: "event"

      event ->
        current_scope = socket.assigns.current_scope

        user_id =
          if current_scope && current_scope.user do
            current_scope.user.id
          end

        # Check if already registered
        existing_registration =
          if user_id do
            Public.get_registration_for_user(user_id, event.id)
          end

        if existing_registration do
          {:ok,
           socket
           |> put_flash(:info, "Anda sudah terdaftar untuk event ini.")
           |> push_navigate(to: "/events/#{event.slug}")}
        else
          {:ok,
           socket
           |> assign(:page_title, "Daftar — #{event.title}")
           |> assign(:event, event)
           |> assign(:user_id, user_id)
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

  def handle_event("submit_registration", params, socket) do
    %{event: event, user_id: user_id, registration_data: data} = socket.assigns

    user = socket.assigns.current_scope && socket.assigns.current_scope.user

    # Auto-fill the account identity into the registration data (custom
    # question answers keep precedence), so organizers always receive the
    # participant's real name and contact.
    user_data =
      if user do
        %{
          "name" => user.fullname || user.username || "",
          "email" => user.email || "",
          "phone" => user.phone_number || ""
        }
      else
        %{}
      end

    final_data = Map.merge(data, Map.merge(params, user_data))

    opts = [
      registration_data: final_data,
      requires_approval: event.requires_approval
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

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Gagal mendaftar, silakan coba lagi.")}
    end
  end

  @impl true
  def handle_event("start_payment", _params, socket) do
    %{event: event, registration: registration, user_id: user_id} = socket.assigns

    if is_nil(registration) or is_nil(user_id) do
      {:noreply, put_flash(socket, :error, "Pendaftaran tidak ditemukan.")}
    else
      case EventPayments.start_payment(event.id, registration.id, user_id) do
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
                  form={@form}
                  registration_data={@registration_data}
                />
              <% 3 -> %>
                <.render_step_confirmation
                  event={@event}
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
            <p>🕐 {format_time(@event.starts_at)} - {format_time(@event.ends_at)}</p>
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

        <div class="flex justify-between gap-3">
          <button type="button" phx-click="prev_step" class="btn btn-ghost">
            <.icon name="hero-arrow-left" class="w-4 h-4 mr-1" /> Kembali
          </button>

          <button type="submit" class="btn btn-primary">
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
            Pendaftaran Anda tercatat. Selesaikan pembayaran online di bawah —
            atau penyelenggara akan menghubungi Anda.
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

  defp format_date(datetime) do
    Calendar.strftime(datetime, "%d %B %Y")
  end

  defp format_time(datetime) do
    Calendar.strftime(datetime, "%H:%M WIB")
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
