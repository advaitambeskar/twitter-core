defmodule Project.Userdata do
  use Ecto.Schema
  import Ecto.Changeset

  alias Project.Userdata
  #
  # Schema for when a new user is registered.
  # When a user tries to register, it will check if it is already existing for a given username
  # if the given username already exists in user_database, then if ("username", "password") tuple
  # is correct, then login occurs instead, otherwise, you insert into the user_database
  # primary key has to be auto-incremented
  #
  @primary_key {:userid, :binary_id, autogenerate: true}
  # @derive {Pheonix.Param, key: :userid}
  schema "user_database" do
    field :username, :string
    field :password, :string
  end

  def changeset(%Userdata{} = user, params \\ %{}) do
    user
    |> cast(params, [:username, :password])
    |> unique_constraint(:username)
    |> validate_required([:username, :password])
  end
  #
  # In the perfect world, the userdata and tweets should be held on different databases. However,
  # I did not want to design a complicated schema so this rather inefficient model would have to be
  #
end

defmodule Project.Topic do
  use Ecto.Schema
  #
  # Schema for when a hashtag is mentioned, it keeps an accumalation of all the tweets in this hashtags,
  # also allows people to follow hashtags
  @primary_key {:hashid, :binary_id, autogenerate: true}
  schema "topic_database" do
    field :hashtags, :string
    field :userids, {:array, :binary_id}
    field :tweet, {:array, :binary_id}
  end

  def changeset(user, params \\ %{}) do
    user
    |> Ecto.Changeset.cast(params, [:hashid, :hashtags, :userids, :tweet])
  end
end

defmodule Project.Tweetdata do
  use Ecto.Schema

  #
  # create table(:tweet_database, primary_key: false) do
  #   add :tweetid, :uuid, primary_key: true
  #   add :tweet, :string
  #   add :owner, :uuid
  #   add :hashtags, :map
  #   add :mentions, :map
  #

  @primary_key {:tweetid, :binary_id, autogenerate: true}
  schema "tweet_database" do
    field :tweet, :string
    field :owner, :binary_id
    field :hashtags, {:array, :binary_id}
    field :mentions, {:array, :binary_id}
  end
end

defmodule Project.Follower do
  use Ecto.Schema
    #
    # create table(:follower_database) do
    #   add :userid, :uuid
    #   add :followers, :map
    # end
    #
    schema "follower_database" do
      field :userid, :binary_id
      field :followers, {:array, :binary_id}
    end

    def changeset(user, params \\ %{}) do
      user
      |> Ecto.Changeset.cast(params, [:userid, :followers])
    end
end

defmodule Project.Feed do
  use Ecto.Schema
  #
  # create table(:feed_database) do
  #   add :userid, :uuid
  #   add :tweets, :map
  # end
  #
  schema "feed_database" do
    field :userid, :binary_id
    field :tweets, {:array, :string}
  end

  def changeset(user, params \\ %{}) do
    user
    |> Ecto.Changeset.cast(params, [:userid, :tweets])
  end
end
