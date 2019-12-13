defmodule ProjectWeb.TweetsController do
  use ProjectWeb, :controller


  def index(conn, _params) do
    # IO.inspect(conn)

    username = Plug.Conn.get_session(conn, :current_user_name)
    IO.puts "Showing Feed for #{username}"

    tweets = getFeed(username)
    IO.inspect "LOOKIE HERE"
    IO.inspect tweets
    IO.inspect "LOOKIE HERE OVER"
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
    reply = Project.ClientFunctions.subscribeToUser(subscriber, user_name)
    IO.inspect reply

    conn =
      conn
      |> put_flash(:reply, reply)
    redirect(conn, to: Routes.tweets_path(conn, :index))
  end

  def tweetQuery(conn, %{"value" => value}) do
    IO.inspect "Here"
    {replyatom, response} = Project.ClientFunctions.query(value)

    IO.inspect "Reply atom"
    IO.inspect replyatom
    IO.inspect "Reply atom"
    cond do
      replyatom == :error ->
        #something
        conn =
          conn
          |> put_flash(:error, response)
        redirect(conn, to: Routes.tweets_path(conn, :index))
      replyatom == :reply ->
        username = Plug.Conn.get_session(conn, :current_user_name)
        conn = conn
        |> put_session(:current_user_name, username)
        |> put_session(:replyatom, replyatom)
        |> put_session(:response, response)
        |> put_session(:value, value)
        redirect(conn, to: Routes.query_path(conn, :queryPage))
      true ->
        conn =
          conn
          |> put_flash(:error, "Unmitigated Error (CODE01)")
        redirect(conn, to: Routes.tweets_path(conn, :index))
    end

  end

  def retweet(conn, %{"tweetid" => tweet_id}) do
    username = Plug.Conn.get_session(conn, :current_user_name)
    Project.TweetFacility.reTweet(username, tweet_id)

    redirect(conn, to: Routes.tweets_path(conn, :index))
  end

  def getFeed(username) do
    userID = Project.TweetFacility.getUserIDFromName(username)
    tweets = Project.TweetFacility.getFeedFromDb(userID)
    tweets = Enum.reverse(tweets)
    IO.inspect(tweets)
    tweets
  end

end
