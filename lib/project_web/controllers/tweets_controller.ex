defmodule ProjectWeb.TweetsController do
  use ProjectWeb, :controller


  def index(conn, _params) do
    IO.inspect(conn)

    username = Plug.Conn.get_session(conn, :current_user_name)
    IO.puts "Showing Feed for #{username}"

    tweets = getFeed(username)
    render(conn, "index.html", username: username, tweets: tweets)
  end

  def sendTweet(conn, %{"tweet" => tweet}) do
    IO.inspect(tweet)
    tweeter = Plug.Conn.get_session(conn, :current_user_name)
    Project.ClientFunctions.tweet(tweeter,tweet)

    redirect(conn, to: Routes.tweets_path(conn, :index))
  end

  def subscribe(conn, %{"user" => user_name}) do
    #subscribe method
    subscriber = Plug.Conn.get_session(conn, :current_user_name)
    Project.ClientFunctions.subscribeToUser(subscriber, user_name)

    redirect(conn, to: Routes.tweets_path(conn, :index))
  end

  def retweet(conn, %{"tweetid" => tweet_id}) do
    username = Plug.Conn.get_session(conn, :current_user_name)
    Project.TweetFacility.reTweet(username, tweet_id)

    redirect(conn, to: Routes.tweets_path(conn, :index))
  end

  def getFeed(username) do
    userID = Project.TweetFacility.getUserIDFromName(username)
    tweets = Project.TweetFacility.getFeedFromDb(userID)
    IO.inspect(tweets)
    tweets
  end

end
