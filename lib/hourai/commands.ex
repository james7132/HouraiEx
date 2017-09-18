defmodule Hourai.CommandService do

  alias Hourai.CommandParser
  alias Hourai.Util

  defmacro __using__(_) do
    [quote do
      @before_compile Hourai.CommandService
    end] ++
    Enum.map(Application.get_env(:hourai, :root_modules), fn module ->
      quote do
        require unquote(module)
      end
    end)
  end

  defmacro __before_compile__(_) do
    Enum.map(Application.get_env(:hourai, :root_modules), fn module ->
      quote_module_commands(module.module_descriptor(), [])
    end) ++
    [quote do
      def execute(command, msg) when is_binary(command) do
        command |> String.trim |> CommandParser.split |> execute(msg)
      end

      def execute(["help" | args], msg) do
        help(args, msg)
      end

      def help(command, msg) when is_binary(command) do
        command |> String.trim |> CommandParser.split |> help(msg)
      end

      # General Help
      def help([],  msg) do
        modules =
          Application.get_env(:hourai, :root_modules)
          |> Enum.map(fn module ->
            descriptor = module.module_descriptor()
            IO.inspect descriptor.help
            commands = for cmd <- descriptor.commands, do: Atom.to_string(cmd)
            submodules = for sub <- descriptor.submodules, do: "#{sub.prefix}*"
            "**#{descriptor.name}**: #{
              commands ++ submodules
              |> Util.codify_list()
            }"
          end)
        Nostrum.Api.create_message(msg.channel_id,
        """
        Available Commands:
        #{Enum.join(modules, "\n")}
        Use `~help <command>` for more information on individual commands.
        """)
      end

      # Must be defined last as a catch-all
      def execute(args, msg) do
        handle_event({:invalid_command, {args, msg}})
      end

      def help(_, msg) do
        Nostrum.Api.create_message(msg.channel_id, "Unknown command.")
      end
    end]
  end

  defp quote_module_commands(descriptor, prefix) do
    module_prefix = Map.get(descriptor, :prefix)
    prefix_list = if module_prefix, do: prefix ++ [module_prefix], else: prefix
    commands = Enum.map(descriptor.commands,
                        &create_matched_execute(prefix_list, descriptor.module,
                                                &1))
    submodule_commands = Enum.map(descriptor.submodules,
                                  &quote_module_commands(&1, prefix_list))
    commands ++ submodule_commands
  end

  defp create_matched_execute(prefix, module, {func, opts}) do
    IO.inspect opts
    command_name = prefix ++ [Atom.to_string(func)]
    full_name = Enum.join(command_name, " ")
    help = Keyword.get(opts, :help) || "`~#{full_name}`"
    IO.puts("Compiling matcher for command \"#{full_name}\"...")
    quote do
      def execute([unquote_splicing(command_name) | args], msg) do
        unquote(module).unquote(func)(%{msg: msg, args: args})
      end

      def help([unquote_splicing(command_name) | _], msg) do
        Nostrum.Api.create_message(msg.channel_id, unquote(help))
      end
    end
  end

end

defmodule Hourai.Commands do

  use Hourai.CommandService

  #alias Hourai.Schema.Discord.CustomCommand
  alias Hourai.Schema.Discord.BlacklistedUser
  alias Hourai.Repo
  alias Hourai.Util
  alias Nostrum.Cache.Guild.GuildServer

  require Logger

  @prefix "~"

  defp parse_comment(msg) do
    case  String.trim(msg.content) do
      @prefix <> content -> {:ok, content}
      _ -> {:not_command, "No command prefix"}
    end
  end

  defp is_valid_command(msg) do
    Repo.get(BlacklistedUser, msg.author.id) || :ok
  end

  def handle_message(msg) do
    {time, result} = :timer.tc fn ->
      with {:ok, command} <- parse_comment(msg),
           :ok <- is_valid_command(msg) do
        execute(command, msg)
        :ok
      end
    end
    case result do
      :ok -> Logger.info "Executed command '#{msg.content}'. Time: #{time} μs"
      {:error, error} ->
        Logger.error "Failed command: '#{msg.content}'. Error: '#{error}'. Time: #{time} μs"
      _ -> :noop
    end
  end

  def handle_event({:invalid_command, {args, msg}}) do
    custom_command(args, msg)
  end

  def custom_command([prefix | _], msg) do
    with {:ok, guild} <- GuildServer.get(channel_id: msg.channel_id) do
      command = Repo.get_by(CustomCommand, guild_id: guild.id, name: prefix)
      if command do
        Util.reply(command.response, msg)
      end
    end
  end

end
