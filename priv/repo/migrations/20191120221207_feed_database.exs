defmodule Project41.Repo.Migrations.FeedDatabase do
  use Ecto.Migration

  def change do
    create table(:feed_database) do
      add :userid, :uuid
      add :tweets, {:array, :string}, default: []
    end
  end
end
