defmodule Project41.Repo.Migrations.FollowerDatabase do
  use Ecto.Migration

  def change do
    create table(:follower_database) do
      add :userid, :binary_id
      add :followers, {:array, :binary_id}
    end
  end
end
