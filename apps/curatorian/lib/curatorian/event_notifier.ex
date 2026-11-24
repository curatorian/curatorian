defmodule Curatorian.EventNotifier do
  @moduledoc """
  Email notifier for public event registration confirmations.

  Sent fire-and-forget right after a successful registration — failures are
  logged and never block the registration itself.
  """

  import Swoosh.Email

  require Ecto.Query

  alias Curatorian.Mailer
  alias Voile.Schema.Accounts.User

  @app_name "Curatorian"
  @from_email "hi@curatorian.id"

  @doc "Registration confirmation — event details, participant page link, registration code."
  def deliver_registration_confirmation(registration, event) do
    recipient = registration_email(registration)

    if is_binary(recipient) and recipient != "" do
      body = """
      Terima kasih! Pendaftaran Anda untuk event berikut telah dicatat:

      #{event.title}
      Mulai: #{format_dt(event.starts_at, event.timezone)}
      Selesai: #{format_dt(event.ends_at, event.timezone)}
      #{venue_line(event)}
      #{payment_line(event)}
      Kode pendaftaran Anda: #{registration.registration_code}
      (simpan kode ini untuk check-in saat event)
      #{participant_page_line(registration)}

      Detail event: #{base_url()}/events/#{event.slug}
      """

      email =
        new()
        |> to(recipient)
        |> from({@app_name, @from_email})
        |> subject("Pendaftaran event diterima — #{event.title}")
        |> text_body(body)
        # The body embeds organizer-controlled content (event.title) — it must
        # be escaped before wrapping in HTML, or a crafted title would inject
        # markup into every participant's inbox.
        |> html_body("<pre style=\"font-family:inherit\">#{escape_html(body)}</pre>")

      case Mailer.deliver(email) do
        {:ok, _metadata} -> {:ok, :sent}
        {:error, reason} -> {:error, reason}
      end
    else
      {:error, :no_recipient}
    end
  end

  # The participant page hosts the personal QR check-in code, the session-code
  # entry, and the certificate link. Registrations created before the token
  # migration have no token — the line is simply omitted.
  defp participant_page_line(%{token: token}) when is_binary(token) and token != "" do
    "\nHalaman peserta Anda (QR check-in, kode sesi, sertifikat):\n#{base_url()}/r/#{token}\n"
  end

  defp participant_page_line(_), do: ""

  # Runtime lookup (not compile_env) so environment overrides in releases apply.
  defp base_url, do: Application.get_env(:curatorian, :curatorian_url, "https://curatorian.id")

  defp payment_line(%{is_paid: true}) do
    "\nSelesaikan pembayaran untuk mengamankan slot Anda."
  end

  defp payment_line(_), do: ""

  # Guests (no account) receive everything by their self-declared email;
  # account registrations resolve the voile user's email (best-effort — the
  # email lives in the voile users table, same database).
  defp registration_email(%{guest_email: email}) when is_binary(email) and email != "",
    do: email

  defp registration_email(%{voile_user_id: nil}), do: nil

  defp registration_email(%{voile_user_id: user_id}) do
    Curatorian.Repo.one(
      Ecto.Query.from(u in User,
        where: u.id == ^user_id,
        select: u.email
      )
    )
    |> case do
      email when is_binary(email) and email != "" -> email
      _ -> nil
    end
  end

  defp registration_email(_), do: nil

  # Event times are stored in UTC; show them in the event's own timezone
  # (default Asia/Jakarta) so participants see the wall-clock start time.
  defp format_dt(nil, _tz), do: "-"

  defp format_dt(dt, tz) when is_struct(dt, DateTime) do
    case DateTime.shift_zone(dt, tz || "Asia/Jakarta") do
      {:ok, shifted} -> Calendar.strftime(shifted, "%A, %d %B %Y %H:%M")
      _ -> Calendar.strftime(dt, "%A, %d %B %Y %H:%M UTC")
    end
  end

  defp format_dt(_, _), do: "-"

  defp venue_line(%{mode: :online}), do: " Lokasi: Online"
  defp venue_line(%{venue_name: name}) when is_binary(name), do: " Lokasi: #{name}"
  defp venue_line(_), do: ""

  defp escape_html(text) do
    text |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()
  end
end
