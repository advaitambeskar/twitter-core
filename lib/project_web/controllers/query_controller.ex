defmodule ProjectWeb.QueryController do
  use ProjectWeb, :controller

  def queryPage(conn, params) do
    username = Plug.Conn.get_session(conn, :current_user_name)
    reply_atom = Plug.Conn.get_session(conn, :replyatom)
    response = Plug.Conn.get_session(conn, :response)
    value = Plug.Conn.get_session(conn, :value)

    IO.inspect params
    IO.inspect ""
    IO.puts "Showing Feed for #{username}"
    IO.inspect reply_atom
    IO.inspect response
    length = String.length(value)
    user = String.slice(value, 1..length)
    IO.inspect value
    IO.inspect ""
    tweets = nil
    tweets = cond do
      reply_atom == :error ->
        tweets = [%{}]
      reply_atom == :reply ->
        if(String.starts_with?(value, "@")) do
          tweet = getFeed(user)
        else
          tweets = getHashFeed(user)
          {atom, map} = tweets
          if(atom == :reply)do
            map
          else
            [%{}]
          end
        end
      true ->
        [%{}]
    end

    # tweets = getFeed(username)
    IO.inspect reply_atom
    render(conn, "index.html", username: username, tweets: tweets, value: value)
  end

  def querysubscribe(conn, %{"user" => user_name}) do
    #subscribe method
    subscriber = Plug.Conn.get_session(conn, :current_user_name)
    reply = Project.ClientFunctions.subscribeToUser(subscriber, user_name)
    IO.inspect reply

    conn =
      conn
      |> put_flash(:reply, reply)
    redirect(conn, to: Routes.query_path(conn, :queryPage))
  end

  def getFeed(username) do
    userID = Project.TweetFacility.getUserIDFromName(username)
    tweets = Project.TweetFacility.getFeedFromDb(userID)
    tweets = Enum.reverse(tweets)
    IO.inspect(tweets)
    tweets
  end

  def getHashFeed(hashtag) do
    {replyatom, response} = Project.ClientFunctions.getHashTagTweets(hashtag)
    IO.inspect response
    {replyatom, response}
  end

  def searchValue(conn, %{"value" => value}) do
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
        redirect(conn, to: Routes.query_path(conn, :queryPage))
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
        redirect(conn, to: Routes.query_path(conn, :queryPage))
    end
  end

end
