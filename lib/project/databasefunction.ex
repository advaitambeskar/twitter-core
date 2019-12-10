defmodule Project.DatabaseFunction do
  import Ecto.Query

  def addToFeed(userid, tweetid) do
    [user] = from(user in Project.Feed, select: user, where: user.userid==^userid) |> Project.Repo.all
      # IO.inspect user

      response = if(user == []) do
        []
      else
        user.tweets
      end
      response = response ++ [tweetid]
      response = Enum.uniq(response)

      [id] = from(user in Project.Feed, select: user.id, where: user.userid == ^userid)
                          |> Project.Repo.all
      # IO.inspect "here"
      # IO.inspect id
      struc = Project.Feed |> Ecto.Query.where(id: ^id) |> Project.Repo.one
      # IO.inspect struc

      changeset = Project.Feed.changeset(struc, %{tweets: response})
      Project.Repo.update(changeset)

      # IO.inspect Project.Feed |> Ecto.Query.where(id: ^id) |> Project.Repo.one
      {:ok}
  end

  def addTweetToDB(userid, tweet) do
    [tweet, hashtag, mention] = Project.TweetFacility.tweetFormat(tweet)
    mentionids = Enum.map(mention, fn x ->
      q = from(user in Project.Userdata, select: user.userid, where: user.username==^x)
      [answer] = q |> Project.Repo.all
      answer
    end)

    # IO.inspect hashtag


    hashtagids = Enum.map(hashtag, fn x ->
      # IO.inspect x
      q = from(user in Project.Topic, select: user.hashid, where: user.hashtags==^x)
      |> Project.Repo.all
      #IO.inspect "reply"
      #IO.inspect reply
      solution = if(q == []) do
        # IO.inspect x
        newHash = %Project.Topic{hashid: Ecto.UUID.generate(),
          hashtags: x, userids: [], tweet: []}
        Project.Repo.insert!(newHash)
        newHash.hashid
        #IO.inspect struc.hashid
      else
        [solution] = q
        # IO.inspect solution
        solution
      end
      # IO.inspect "solution"
      # IO.inspect solution
      solution
    end)


    newTweet = %Project.Tweetdata{tweetid: Ecto.UUID.generate(),
    tweet: tweet, owner: userid, hashtags: hashtagids, mentions: mentionids}
    #IO.inspect "right before tweet insert"
    Project.Repo.insert(newTweet)

    # IO.inspect "hashtagids"
    # IO.inspect hashtagids
    # When a tweet is added, one must also add the tweet to respective hashtags
    Project.DatabaseFunction.addTweetToHashTag(hashtagids, newTweet.tweetid)

    {newTweet.tweetid}
    # When a tweet is added, one must also add the tweet to the feed of the mentioned userids
  end

  def addTweetToHashTag(hashtag, tweetid) do
    Enum.each(hashtag, fn individual_hashid ->
      [entry] = from(user in Project.Topic, select: user, where: user.hashid==^individual_hashid)
      |> Project.Repo.all

      response = if(entry == []) do
        []
      else
        entry.tweet
      end

      response = response ++ [tweetid]
      response = Enum.uniq(response)

      struc = Project.Topic |> Ecto.Query.where(hashid: ^individual_hashid) |> Project.Repo.one
      changeset = Project.Topic.changeset(struc, %{tweet: response})
      Project.Repo.update(changeset)
    end)
  end

  def addFollowerToDatabase(subscriber, username) do
    [userid] = from(user in Project.Userdata, select: user.userid, where: user.username==^username)
    |> Project.Repo.all
#    IO.inspect userid
    [subscriber_id] = from(user in Project.Userdata, select: user.userid, where: user.username==^subscriber)
    |> Project.Repo.all
#    IO.inspect subscriber_id

    [entry] = from(user in Project.Follower, select: user, where: user.userid==^userid)
      |> Project.Repo.all

      response = if(entry == []) do
        []
      else
        entry.followers
      end
      response = response ++ [subscriber_id]
      response = Enum.uniq(response)
#      IO.inspect response
      struc = Project.Follower |> Ecto.Query.where(userid: ^userid) |> Project.Repo.one
      changeset = Project.Follower.changeset(struc, %{followers: response})
      Project.Repo.update(changeset)
  end

  def subscribeToHashtag(hashtag, username) do
      userid = from(user in Project.Userdata, select: user.userid, where: user.username==^username)
      |> Project.Repo.all

      hashid = from(user in Project.Topic, select: user.hashid, where: user.hashtags==^hashtag)
      |> Project.Repo.all
      [entry] = from(user in Project.Topic, select: user, where: user.hashid==^hashid)
      |> Project.Repo.all

      response = if(entry == []) do
        []
      else
        entry.userids
      end

      response = response ++ [userid]
      response = Enum.uniq(response)

      struc = Project.Topic |> Ecto.Query.where(hashid: ^hashtag) |> Project.Repo.one
      changeset = Project.Topic.changeset(struc, %{userids: response})
      Project.Repo.update(changeset)
  end

  def mentions(username) do
    #return all the tweets which mention the userid
    userid = from(user in Project.Userdata, select: user.userid, where: user.username==^username)
    |> Project.Repo.all
    if(userid == []) do
      IO.inspect "The username does not exist/ has not been registered."
    else
      [id] = userid
      all_tweet_entries = from(user in Project.Tweetdata, select: user) |> Project.Repo.all
      #IO.inspect all_tweet_entries
      possibleTweets = Enum.map(all_tweet_entries, fn each_entry ->
        #IO.inspect each_entry.mentions
        response = if(Enum.member?(each_entry.mentions, id)) do
          each_entry.tweetid
        else
        end
        # IO.inspect "HERE"
        # IO.inspect response
        # answer = Enum.each(each_entry.mentions, fn mentions ->
        #   response = if(Enum.member?(mentions, id)) do
        #     each_entry.tweetid
        #   end
        #   response
        response
        # end)
      end)
      possibleTweets = Enum.filter(possibleTweets, fn x ->
        x != nil
      end)
      response = Enum.map(possibleTweets, fn tweet ->
        m = from(user in Project.Tweetdata, select: user.tweet, where: user.tweetid==^tweet)
        |> Project.Repo.all
        m
      end)
      # IO.inspect "response"
      # IO.inspect response
      if(response == []) do
        IO.inspect "No tweets mentioning @#{username} yet"
      else
        res = response
        Enum.map(res, fn x ->
          [tweet] = x
          IO.inspect tweet
        end)
      end
    end
    "All tweets have been printed"
  end
end
