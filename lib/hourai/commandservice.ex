defmodule Hourai.CommandService do

  alias Hourai.CommandParser
  alias Hourai.Util

  defp root_modules() do
    Application.get_env(:hourai, :root_modules)
  end

  defmacro __using__(_) do
    for module <- root_modules() do
      quote do
        require(unquote(module))
      end
    end
    ++
    [quote do
      import Hourai.CommandService

      @before_compile Hourai.CommandService

      Module.put_attribute(__MODULE__, :root_modules, unquote(root_modules()))

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
        general_help(@root_modules, %{msg: msg, args: []})
      end

    end]
  end

  defmacro __before_compile__(_) do
    for module <- root_modules() do
      quote_module_commands(module.module_descriptor(%{}))
    end
    ++
    [quote do
      # Must be defined last as a catch-all
      def execute(args, msg) do
        Enum.reduce(@root_modules, false, fn (module, found) ->
          found or not match?({:error, _}, module.fallback_execute(args, msg))
        end)
      end

      def help(_, msg) do
        Hourai.Util.reply("Unknown command.", msg)
      end
    end]
  end

  defp quote_module_commands(descriptor, prefix \\ []) do
    module_prefix = Map.get(descriptor, :prefix)
    prefix_list = if module_prefix, do: prefix ++ [module_prefix], else: prefix
    commands = for command <- descriptor.commands, do:
                 command_matchers(prefix_list, descriptor.module, command)
    submodule_commands = for sub <- descriptor.submodules, do:
                           quote_module_commands(sub, prefix_list)
    [commands | submodule_commands]
  end

  defp command_matchers(prefix, module, {func, opts} = command) do
    command_name = if Keyword.get(opts, :default), do: prefix, else: prefix ++ [Atom.to_string(func)]
    full_name = Enum.join(command_name, " ")
    help = "`~#{full_name}`\n" <> (Keyword.get(opts, :help) || "")
    IO.puts("Compiling matchers for command \"#{full_name}\"...")
    quote do
      def execute([unquote_splicing(command_name) | args], msg) do
        context = %{msg: msg, args: args}
        case check_command_preconditions(context,
                                         unquote(module),
                                         unquote(command)) do
          {:error, reason} -> Hourai.Util.reply(reason, msg)
          %{} = ctx -> unquote(module).unquote(func)(ctx)
        end
      end

      def help([unquote_splicing(command_name) | _], msg) do
        Nostrum.Api.create_message(msg.channel_id, unquote(help))
      end
    end
  end

  def general_help(modules, context) do
    {context, valid_modules} = filter_invalid_modules(modules, context)
    modules =
      valid_modules
      |> Enum.map(&module_summary(&1, context))
      |> Enum.filter(&(&1))
      |> Enum.sort()
      |> Enum.join("\n")
    Hourai.Util.reply(
      """
      Available Commands:
      #{modules}
      Use `~help <command>` for more information on individual commands.
      """, context.msg)
  end

  defp module_summary(descriptor, context) do
    {context, valid_commands} =
      filter_invalid_commands(descriptor.module, descriptor.commands, context)
    {_, valid_submodules} =
      filter_invalid_modules(descriptor.submodules, context)
    commands = for {cmd, _} <- valid_commands, do: String.Chars.to_string(cmd)
    submodules = for sub <- valid_submodules, do: "#{sub.prefix}*"
    IO.inspect {descriptor.module, commands, submodules}
    if Enum.any?(commands) or Enum.any?(submodules) do
      "**#{descriptor.name}**: #{
        Enum.sort(commands) ++ Enum.sort(submodules)
        |> Util.codify_list()
      }"
    end
  end

  defp filter_invalid_modules(modules, context) do
    Enum.reduce(modules, {context, []}, fn (module, {ctx, mods}) ->
      command_module =
        case module do
          %{:module => mod} -> mod
          _ -> module
        end
      case command_module.module_preconditions(ctx) do
        %{} = new_ctx ->
          descriptor = command_module.module_descriptor(new_ctx)
          if descriptor, do: {new_ctx, [descriptor] ++ mods}, else: {new_ctx, mods}
        {:error, _} -> {ctx, mods}
      end
    end)
  end

  defp filter_invalid_commands(module, commands, context) do
    Enum.reduce(commands, {context, []}, fn (command, {ctx, cmds}) ->
      case module.command_preconditions(ctx, command) do
        %{} = new_ctx -> {new_ctx, [command] ++ cmds}
        {:error, _} -> {ctx, cmds}
      end
    end)
  end

  def check_command_preconditions(context, module, command) do
    with %{} = context <- module.module_preconditions(context),
         %{} = context <- module.command_preconditions(context, command) do
      context
    end
  end


end
