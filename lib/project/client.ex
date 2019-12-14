defmodule Project.Client do
  import Ecto.Query

  def main() do
    Project.Client.registerBlock()
    #Project.Client.subscriberBlock()
    Enum.each(1..100, fn x ->
      Project.Client.sendTweet()
    end)
    Project.ClientFunctions.tweet("advaitambeskar", "HELLLLOOOOOO!! #hey #dog")
    :end
  end

  def registerBlock() do
    user = "user"
    password = "pwd"
    noOfUsers = 1..100
    IO.inspect noOfUsers
    for x <- noOfUsers do
      IO.inspect user <> Integer.to_string(x)
      Project.ClientFunctions.register(user<>Integer.to_string(x), password)
    end
  end

  def subscriberBlock() do
    numberOfMessage = 1..125
    [allExistingUser] = from(user in Project.Userdata, select: user.username) |> Project.Repo.all
    Enum.each(numberOfMessage, fn x ->
      firstUser = Enum.random(allExistingUser)
      secondUser = Enum.random(allExistingUser)
      Project.ClientFunctions.subscribeToUser(firstUser, secondUser)
    end)
  end

  def sendTweet() do
    firstword =
    ["I", "love", "eating", "toasted", "cheese", "and", "tuna", "sandwiches", "the", "body", "may", "perhaps", "compensates", "for", "the", "loss"]
    secondword =
    ["sixty", "four", "comes", "asking", "for", "bread"]
    thirdword =
    ["he","turned","in", "the", "research", "paper", "on", "friday"]
    hashtag =
    [ "#dog", "#dogsofinstagram", "#dogs", "#dogstagram", "#doglover", "#dogoftheday", "#doglife", "#doglovers",
      "#doggy", "#dogsofinsta", "#dogsofig", "#doggo", "#doglove", "#dogsitting", "#dogslife",
      "#dogsofinstaworld", "#doggie", "#dogscorner"]
    tweet = Enum.random(firstword)<>" "<>Enum.random(secondword)<>" "<>Enum.random(thirdword)<>" "
    tweet = tweet<>Enum.random(firstword)<>" "<>Enum.random(secondword)<>" "<>Enum.random(thirdword)<>" "<>Enum.random(hashtag)
    # IO.inspect tweet
    allExistingUser = from(user in Project.Userdata, select: user.username) |> Project.Repo.all

    firstUser = Enum.random(allExistingUser)
    secondUser = "@" <> Enum.random(allExistingUser)
    tweet = tweet <> " " <> secondUser
    Project.ClientFunctions.tweet(firstUser, tweet)
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
    Project.TweetEngine.subscribe_to_user(subscriber, username)
  end

  def tweet(user, tweet) do
    Project.TweetFacility.sendTweet(user, tweet)
  end

  def retweet(user, tweetid) do
    Project.TweetFacility.reTweet(user, tweetid)
  end

  def loadFeed(user) do
    userid = from(user in Project.Userdata, select: user.userid, where: user.username == ^user)
            |> Project.Repo.all;
    # IO.inspect user
    # IO.inspect userid
    if(userid == []) do
      {:error, ["User does not exist!"]}
    else
      [id] = userid
      feed_raw = from(user in Project.Feed, select: user.tweets, where: user.userid == ^id)
                |> Project.Repo.all;
      if(feed_raw != []) do
        [feed] = feed_raw
        tweet = Enum.map(feed, fn x ->
          [tweet_string] = from(user in Project.Tweetdata, select: user.tweet, where: user.tweetid == ^x)
                        |> Project.Repo.all
           tweet_string
        end)
        {:reply, tweet}
      else
        {:error, ["User has no tweets at this time"]}
      end
    end
  end

  def query(value) do
    # If value begins with @ then it is a username. If value begins with # it is a hashtag
    response = nil
    response = cond do
      String.starts_with?(value, "@") ->
        length = String.length(value)
        username = String.slice(value, 1..length)
        {atom, reply} = Project.TweetFacility.userSearchQuery(username)
        response = if(atom == :reply) do
          {:reply, reply}
        else
          {:error, [reply]}
          #what
        end
      String.starts_with?(value, "#") ->
        length = String.length(value)
        hashtag = String.slice(value, 1..length)
        {atom, reply} = Project.TweetFacility.hashtagSearchQuery(hashtag)
        IO.inspect {atom, reply}
        response = if(atom == :reply) do
          {:reply, reply}
        else
          {:error, [reply]}
        end
        true -> response = {:error, ["Please enter username starting with '@' and hashtag starting with '#'"]}
      end
      response
  end

  def getHashTagTweets(hashtag) do
    tweets = from(user in Project.Topic, select: user.tweet, where: user.hashtags == ^hashtag)
            |> Project.Repo.all

    response =
    if(tweets == []) do
      %{}
    else
      [tweetids] = tweets
      Enum.map(tweetids, fn x ->
        owner = from(user in Project.Tweetdata, select: user.owner, where: user.tweetid==^x)
        |> Project.Repo.all
        [owner_name] = from(user in Project.Userdata, select: user.username, where: [user.userid]==^owner)
        |> Project.Repo.all
        [tweet] = from(user in Project.Tweetdata, select: user.tweet, where: user.tweetid==^x)
        |> Project.Repo.all
        %{owner: owner_name, tweet: tweet, tweetid: x}
      end)
    end
    IO.inspect response
    if(response == %{}) do
      {:error, response}
    else
      {:reply, response}
    end
  end
  # mentions and hashtag querying and user querying can occur only if the user is logged in. Login check
  # is needed to be done/ performed
end
