defmodule Hourai.Commands.Misc do

  alias Hourai.Util

  @lenny [
    "( ͡° ͜ʖ ͡°)",
    "( ͠° ͟ʖ ͡°)",
    "ᕦ( ͡° ͜ʖ ͡°)ᕤ",
    "( ͡~ ͜ʖ ͡°)",
    "(ง ͠° ͟ل͜ ͡°)ง"
  ]

  @eight_ball [
    "It is certain.",
    "It is decidedly so.",
    "Without a doubt.",
    "Yes, definitely.",
    "You may rely on it.",
    "As I see it, yes.",
    "Most likely.",
    "Outlook good.",
    "Yes.",
    "Signs point to yes.",
    "Reply hazy try again...",
    "Ask again later...",
    "Better not tell you now...",
    "Cannot predict now...",
    "Concentrate and ask again...",
    "Don't count on it.",
    "My reply is no.",
    "My sources say no.",
    "Outlook not so good.",
    "Very doubtful.",
    "Why not?"
  ]

  def lmgtfy(msg, options) do
    Util.reply("https://lmgtfy.com/?q=#{options |> Enum.join(" ") |> URI.encode}", msg);
  end

  def shrug(msg) do
    Util.reply("¯\\\\\\\_(ツ)_/¯", msg);
  end

  def blah(msg) do
    Util.reply("Blah to you too, #{Util.mention(msg.author)}.", msg);
  end

  def lenny(msg) do
    Util.reply(Enum.random(@lenny), msg);
  end

  def eight_ball(msg) do
    Util.reply(Enum.random(@eight_ball), msg);
  end

end
