defmodule Hourai.Commands.Custom do

  use Hourai.CommandModule

  alias Hourai.Precondition
  alias Hourai.Repo
  alias Hourai.Schema.Discord.CustomCommand

  import Ecto.Query

  def module_preconditions(context) do
    Precondition.in_guild(context)
  end

  def module_descriptor(%{guild: _} = context) do
    default_context = default_module_descriptor(context)
    commands = get_guild_commands(context)
    if Enum.any?(commands) do
      %{default_context | commands: commands}
    end
  end

  def module_descriptor(context) do
    default_module_descriptor(context)
  end

  def get_guild_commands(context) do
    guild_id = context.guild.id
    IO.puts guild_id
    query =
      from command in CustomCommand,
      where: command.guild_id == ^guild_id,
      select: command.name
    for command <- Repo.all(query), do: {command, []}
  end

  def fallback_execute([prefix | args], msg) do
    context = %{msg: msg, args: args}
    with %{} = context <- Precondition.in_guild(context) do
      case Repo.get_by(CustomCommand, guild_id: context.guild.id, name: prefix) do
        nil -> {:error, "no matching custom command"}
        %CustomCommand{response: response} -> reply(context, response)
      end
    end
  end

end
