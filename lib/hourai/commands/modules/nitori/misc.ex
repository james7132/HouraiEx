defmodule Hourai.Commands.Nitori.Misc do

  use Hourai.CommandModule

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

  command "lmgtfy", do:
    reply(context,
          "https://lmgtfy.com/?q=#{context.args |> Enum.join(" ") |> URI.encode}");

  command "shrug", do: reply(context, "¯\\\\\\\_(ツ)_/¯")
  command "blah", do: reply(context,
                            "Blah to you too, #{Util.mention(context.msg.author)}.")

  command "lenny", do: reply(context, Enum.random(@lenny))
  command "8ball", do: reply(context, Enum.random(@eight_ball))

end
