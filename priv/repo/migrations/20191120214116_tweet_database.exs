defmodule Project41.Repo.Migrations.TweetDatabase do
  use Ecto.Migration

  def change do
    create table(:tweet_database, primary_key: false) do
      add :tweetid, :uuid, primary_key: true
      add :tweet, :string
      add :owner, :uuid
      add :hashtags, {:array, :binary_id}, default: []
      add :mentions, {:array, :binary_id}, default: []
    end
  end
end
