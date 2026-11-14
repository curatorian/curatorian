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

  @doc "Registration confirmation — event details plus the registration code."
  def deliver_registration_confirmation(registration, event) do
    recipient = registration_email(registration)

    if is_binary(recipient) and recipient != "" do
      body = """
      Terima kasih! Pendaftaran Anda untuk event berikut telah dicatat:

      #{event.title}
      Mulai: #{format_dt(event.starts_at)}
      Selesai: #{format_dt(event.ends_at)}
      #{venue_line(event)}

      Kode pendaftaran Anda: #{registration.registration_code}
      (simpan kode ini untuk check-in saat event)

      Detail event: /events/#{event.slug}
      """

      email =
        new()
        |> to(recipient)
        |> from({@app_name, @from_email})
        |> subject("Pendaftaran event diterima — #{event.title}")
        |> text_body(body)
        |> html_body("<pre style=\"font-family:inherit\">#{body}</pre>")

      case Mailer.deliver(email) do
        {:ok, _metadata} -> {:ok, :sent}
        {:error, reason} -> {:error, reason}
      end
    else
      {:error, :no_recipient}
    end
  end

  defp registration_email(%{voile_user_id: nil}), do: nil

  defp registration_email(%{voile_user_id: user_id}) do
    # Best-effort — registration is written to atrium.event_registrations and
    # the email lives in the voile users table (same database).
    Curatorian.Repo.one(
      Ecto.Query.from u in User,
        where: u.id == ^user_id,
        select: u.email
    )
    |> case do
      email when is_binary(email) and email != "" -> email
      _ -> nil
    end
  end

  defp registration_email(_), do: nil

  defp format_dt(nil), do: "-"
  defp format_dt(dt), do: Calendar.strftime(dt, "%A, %d %B %Y %H:%M UTC")

  defp venue_line(%{mode: :online}), do: " Lokasi: Online"
  defp venue_line(%{venue_name: name}) when is_binary(name), do: " Lokasi: #{name}"
  defp venue_line(_), do: ""
end
