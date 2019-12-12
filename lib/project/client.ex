defmodule Project.Client do
  import Ecto.Query

  def main() do
    Project.ClientFunctions.register("msa", "msa")
    Project.ClientFunctions.logout("msa")
    Project.ClientFunctions.login("msa", "msa")
    Project.ClientFunctions.logout("msa")
    Project.ClientFunctions.delete("msa", "msa")
    Project.ClientFunctions.logout("msa")
    Project.ClientFunctions.login("advaitambeskar", "advait")
    Project.ClientFunctions.login("msa", "msa")
    Project.ClientFunctions.delete("msa", "msa")
    :end
  end
end


defmodule Project.ClientFunctions do
  import Ecto.Query
  @moduledoc """
  Create Endpoints of sorts for client functions so that they can be directly used.
  Improved interface
  """
  def register(username, password) do
    {reply} = Project.LoginEngine.registerUser(username, password)
    cond do
      reply == :newUser ->
        IO.inspect "Successfully registered #{username} as a new user."
        Project.ClientFunctions.login(username, password)
      reply == :oldUser ->
          IO.inspect "User #{username} is an old user. Attempting login instead."
          Project.ClientFunctions.login(username, password)
    end
  end

  def login(username, password) do
    {login_reply, useriden} = Project.LoginEngine.login(username, password)
    #IO.inspect userid
    cond do
      login_reply == :loginSuccessful ->
        [userid] = useriden
        tweets = []

        [followers] = from(user in Project.Follower, select: user.followers, where: user.userid==^userid) |> Project.Repo.all

        [feed] = from(user in Project.Feed, select: user.tweets, where: user.userid==^userid) |> Project.Repo.all

        {pid, client_state} = Project.TweetEngine.start(userid, tweets, followers, feed)
        Project.LiveUserServer.userLogedIn(userid, pid)

        IO.puts "Login as #{username} was successful"
        true
      login_reply == :loginUnsucessful ->
        IO.puts "Sorry, the attempt to login to #{useriden} was unsuccessful"
        false
      login_reply == :duplicateLogin ->
        IO.puts "Previous sign in detected. You are already logged in as #{useriden}."
        false
      true ->
        IO.puts "Unexpected error during output. Please check the logs."
        false
    end
  end

  def logout(username) do
    IO.inspect Project.LoginEngine.logout(username)
  end

  def delete(username, password) do
    IO.inspect Project.LoginEngine.deleteUser(username, password)
  end

  def subscribeToUser(subscriber, username) do
    IO.puts Project.TweetEngine.subscribe_to_user(subscriber, username)
  end

  def tweet(user, tweet) do
    Project.TweetFacility.sendTweet(user, tweet)
  end

  def retweet(user, tweetid) do
    Project.TweetFacility.reTweet(user, tweetid)
  end

  def loadFeed(user) do

  end

  def query(value) do
    # If value begins with @ then it is a username. If value begins with # it is a hashtag
    response = nil
    cond do
      String.starts_with?(value, "@") ->
        length = String.length(value)
        username = String.slice(value, 1..length)
        {atom, reply} = Project.TweetFacility.userSearchQuery(username)
        response = if(atom == :reply) do
          reply
        else
          [reply]
          #what
        end
      String.starts_with?(value, "#") ->
        length = String.length(value)
        hashtag = String.slice(value, 1..length)
        {atom, reply} = Project.TweetFacility.hashtagSearchQuery(hashtag)
        response = if(atom == :reply) do
          reply
        else
          [reply]
        end
      end
      response
  end
  # mentions and hashtag querying and user querying can occur only if the user is logged in. Login check
  # is needed to be done/ performed
end
