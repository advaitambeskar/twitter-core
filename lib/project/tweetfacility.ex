
defmodule Project.TweetFacility do
  import Ecto.Query

  def tweetFormat(tweet) do
    split_tweet = String.split(tweet, " ");
    hashtag = Enum.map(split_tweet, fn x ->
      l = String.length(x);
      if(String.starts_with?(x, "#")) do
        String.slice(x, 1..l)
      end
    end)
    hashtag = Enum.filter(hashtag, fn x ->
      x != nil
    end)

    mention = Enum.map(split_tweet, fn x ->
      l = String.length(x);
      if(String.starts_with?(x, "@")) do
        String.slice(x, 1..l)
      end
    end)
    mention = Enum.filter(mention, fn x->
      x != nil
    end)
#    IO.inspect(hashtag)
    [tweet, hashtag, mention]
  end



  def hashtagSearchQuery(hashtag) do

    # @primary_key {:hashid, :binary_id, autogenerate: true}
    # schema "topic_database" do
    #   field :hashtags, :string
    #   field :userids, {:array, :binary_id}
    #   field :tweet, {:array, :binary_id}
    # end
    query = from(user in Project.Topic, select: user.tweet, where: user.hashtags==^hashtag)
    available_tweets = query |> Project.Repo.all
    count = 0;
    response = if(available_tweets == []) do
      []
    else
      # IO.inspect "what"
      # IO.inspect(available_tweets)
      [tweet_list] = available_tweets
      tweet_list
    end
    IO.inspect "The following tweets have been published for ##{hashtag} in the lifetime"
    Enum.each(response, fn tweet_id ->
      [tweet_string] = from(user in Project.Tweetdata, select: user.tweet, where: user.tweetid==^tweet_id)
      |> Project.Repo.all
      [tweet_owner] = from(user in Project.Tweetdata, select: user.owner, where: user.tweetid==^tweet_id)
      |> Project.Repo.all
      tweet_owner_name = from(user in Project.Userdata, select: user.username, where: user.userid==^tweet_owner)
      |> Project.Repo.all

      newTweetFormat = "@#{tweet_owner_name} tweeted '#{tweet_string}'"
      IO.puts newTweetFormat
    end)
    if(Enum.count(response) != 0) do
      "These are all the tweets published on ##{hashtag}"
    else
      "There are no tweets published on ##{hashtag} yet"
    end
  end

  def userSearchQuery(user) do

    # @primary_key {:hashid, :binary_id, autogenerate: true}
    # schema "topic_database" do
    #   field :hashtags, :string
    #   field :userids, {:array, :binary_id}
    #   field :tweet, {:array, :binary_id}
    # end
    userid = from(user in Project.Userdata, select: user.userid, where: user.username==^user)
    |> Project.Repo.all

    response = if(userid == []) do
      []
    else
      # IO.inspect "what"
      # IO.inspect(available_tweets)
      [user_id] = userid
      tweet_list = from(user in Project.Tweetdata, select: user.tweetid, where: user.owner==^user_id)
      |> Project.Repo.all
      tweet_list
    end
    #IO.inspect response
    if(response != []) do
      IO.inspect "The following tweets have been published for @#{user} in the lifetime"
      Enum.each(response, fn tweet_id ->
        [tweet_string] = from(user in Project.Tweetdata, select: user.tweet, where: user.tweetid==^tweet_id)
        |> Project.Repo.all
        [tweet_owner] = from(user in Project.Tweetdata, select: user.owner, where: user.tweetid==^tweet_id)
        |> Project.Repo.all
        tweet_owner_name = from(user in Project.Userdata, select: user.username, where: user.userid==^tweet_owner)
        |> Project.Repo.all

        newTweetFormat = "@#{tweet_owner_name} tweeted '#{tweet_string}'"
        IO.puts newTweetFormat
      end)
      if(Enum.count(response) == 0) do
        IO.puts "\n"
        "There are no associated tweets by @#{user}"
      else
        IO.puts "\n"
        "These are all the tweets published on @#{user}"
      end
    else
      "No user associated with #{user}"
    end
  end

  def sendTweet(userName, tweet) do
    liveUserMap =  Project.LiveUserServer.get_state() #get map of live users from server
    [userID] = from(user in Project.Userdata, select: user.userid, where: user.username==^userName)
      |> Project.Repo.all
    # IO.inspect userID
    if Map.has_key?(liveUserMap, userID) do
      userProcessId = Map.get(liveUserMap, userID)

      [tweet, hashtag, mentions] = Project.TweetFacility.tweetFormat(tweet)
      {tweetid} = Project.DatabaseFunction.addTweetToDB(userID, tweet)

      # Enum.each(hashtag, fn x ->
      #   Project.DatabaseFunction.addTweetToHashTag(x, tweetid)
      # end)
      # IO.puts "tweetid"
      # IO.inspect(tweetid)
      Project.TweetEngine.addTweet(userProcessId, tweetid)

      # update the feed of the mentioned users with the current tweet
      Project.TweetFacility.updateUserFeed(mentions, liveUserMap, tweetid)

      followers = Project.TweetEngine.getFollowers(userProcessId)
      follower_name = Enum.map(followers, fn x ->
        q = from( user in Project.Userdata, select: user.username, where: user.userid== ^x)
        [answer] = q |> Project.Repo.all
        answer
      end)
      #update the feed of the followers with the current tweet
      updateUserFeed(follower_name, liveUserMap, tweetid)

      # Updating the Feed Database
      Project.DatabaseFunction.addToFeed(userID, tweetid)
      # Project.Repo.update!(changeset)
      #IO.inspect "Tweet added to feed"
    else
        IO.puts "Please log in first"
    end
  end

  def getFeedFromDb(userid) do
    [feed] = from(user in Project.Feed, select: user.tweets, where: user.userid==^userid)
               |> Project.Repo.all
    tweets =
      Enum.reduce(feed, [], fn feed_id, list ->
        [tweet] = from(user in Project.Tweetdata, where: user.tweetid==^feed_id)
                      |> Project.Repo.all
        [ownerName] = from(user in Project.Userdata, select: user.username, where: user.userid==^tweet.owner)
                     |> Project.Repo.all
        list = list ++ [%{tweetid: feed_id, tweet: tweet.tweet, owner: ownerName}]
      end)
    tweets
  end

  def reTweet(userName, tweetid) do
    tweets = from(user in Project.Tweetdata, select: user.tweet, where: user.tweetid==^tweetid)
                      |> Project.Repo.all
    if(tweets == []) do
      "The tweet does not exist."
    else
      [tweet] = tweets
      tweetOwners = from(user in Project.Tweetdata, select: user.owner, where: user.tweetid==^tweetid)
                 |> Project.Repo.all
      if(tweetOwners == []) do
      else
        [tweetOwner] = tweetOwners
        ownerNames = from(user in Project.Userdata, select: user.username, where: user.userid==^tweetOwner)
                  |> Project.Repo.all
        if(ownerNames == []) do
          "The owner name does not exist"
        else
          [ownerName] = ownerNames
          prefix = "Retweet by @#{userName} -> "
          retweet = prefix <> tweet
          sendTweet(userName, retweet)
          "#{retweet}"
        end

      end
    end


  end

  def getUserIDFromName(userName) do
    userIDs = from(user in Project.Userdata, select: user.userid, where: user.username==^userName)
               |> Project.Repo.all
    if length(userIDs) > 0 do
      [userID|_tail] = userIDs
      userID
    else
      nil
    end
  end

  def updateUserFeed(users, liveUserMap, tweet) do
    Enum.each(users, fn userName ->
      userID = getUserIDFromName(userName)
      pid = Map.get(liveUserMap, userID)
      if pid != nil do
        Project.TweetEngine.updateFeed(pid, tweet)
        Project.DatabaseFunction.addToFeed(userID, tweet)
      end
      {:ok}
    end)
  end

end
