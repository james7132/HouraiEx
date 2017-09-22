defmodule Hourai.Reddit.Subreddit do

  alias Hourai.Reddit.RequestServer

  def new(subreddit) do
    RequestServer.fetch("/r/#{subreddit}/new.json")
  end

end
