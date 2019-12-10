defmodule Project41.Repo.Migrations.Tweeter do
  use Ecto.Migration

  def change do
    create table(:user_database, primary_key: false) do
      add :userid, :uuid, primary_key: true
      add :username, :string
      add :password, :string
    end
  end
end
