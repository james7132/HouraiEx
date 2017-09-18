defmodule Hourai.Commands.Custom do

  use Hourai.CommandModule

  alias Hourai.Precondition
  alias Hourai.Repo
  alias Hourai.Schema.Discord.CustomCommand

  command "command", help:
  """
  Creates, updates, or deletes custom commnands.
  First argument is always the name of the command, rest of the command is the expected response.

  Calling the command with only the name will delete the command.

  Examples:
  `~command hello Hello world! => Creates/updates command "hello" with response "Hello world!"`
  `~command hello => Deletes command "hello"`
  """
  do
    case context.args do
      [name] -> delete_command(context, name)
      [name | args] -> add_or_update_command(context, name, args)
    end
  end

  def add_or_update_command(context, name, response) do
    with {:ok, guild} <- Precondition.in_guild(context.msg) do
      result = %CustomCommand{}
                |> CustomCommand.changeset(%{
                  guild_id: guild.id,
                  name: name,
                  response: Enum.join(response, " ")
                })
                |> Repo.insert_or_update
      case result do
        {:ok, model} ->
          reply(context, "Command `#{model.name}` created with response \"#{model.response}\"")
        {:error, error} ->
          reply(context, "Something went wrong: '#{error}'")
      end
    end
  end

  def delete_command(context, name) do
    with {:ok, guild} <- Precondition.in_guild(context.msg) do
      case Repo.get_by(CustomCommand, guild_id: guild.id, name: name) do
        nil ->
          reply(context, "Command `#{name}` does not exist!")
        command ->
          Repo.delete(command)
          reply(context, "Command `#{name}` successfully deleted.")
      end
    end
  end

end
