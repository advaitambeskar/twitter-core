defmodule ProjectWeb.Router do
  use ProjectWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ProjectWeb do
    pipe_through :browser

    get "/", LoginController, :show
    post "/", LoginController, :create
    get "/tweets", TweetsController, :index
    get "/log-out", LoginController, :logout
    post "/tweets/subscribe", TweetsController, :subscribe
    post "/tweets/send", TweetsController, :sendTweet
    post "/tweets/retweet", TweetsController, :retweet
    post "/query", TweetsController, :tweetQuery
    get "/query", QueryController, :queryPage
    post "/query/query", QueryController, :searchValue
    post "/query/subscribe", QueryController, :querysubscribe
  end
end
