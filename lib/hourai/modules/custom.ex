defmodule Hourai.Commands.Custom do

  alias Hourai.Precondition
  alias Hourai.Repo
  alias Hourai.Util
  alias Hourai.Schema.Discord.CustomCommand

  def add_or_update_command(msg, name, response) do
    with {:ok, guild} <- Precondition.in_guild(msg) do
      result = %CustomCommand{}
                |> CustomCommand.changeset(%{
                  guild_id: guild.id,
                  name: name,
                  response: Enum.join(response, " ")
                })
                |> Repo.insert_or_update
      case result do
        {:ok, model} ->
          Util.reply("Command `#{model.name}` created with response \"#{model.response}\"", msg)
        {:error, error} ->
          Util.reply("Something went wrong: '#{error}'", msg)
      end
    end
  end

  def delete_command(msg, name) do
    with {:ok, guild} <- Precondition.in_guild(msg) do
      case Repo.get_by(CustomCommand, guild_id: guild.id, name: name) do
        nil ->
          Util.reply("Command `#{name}` does not exist!", msg)
        command ->
          Repo.delete(command)
          Util.reply("Command `#{name}` successfully deleted.", msg)
      end
    end
  end

end
