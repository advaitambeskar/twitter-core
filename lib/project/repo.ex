defmodule Project.Repo do
  use Ecto.Repo,
    otp_app: :project,
    adapter: Ecto.Adapters.Postgres
end
