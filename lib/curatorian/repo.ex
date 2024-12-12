defmodule Curatorian.Repo do
  use Ecto.Repo,
    otp_app: :curatorian,
    adapter: Ecto.Adapters.Postgres
end
