defmodule PhxBb.Repo do
  use Ecto.Repo,
    otp_app: :phx_bb,
    adapter: Ecto.Adapters.Postgres
end
