defmodule Hourai.CommandModule do

  alias Hourai.Util

  defmacro __using__(_) do
    quote do
      import Hourai.CommandModule

      require Logger

      @before_compile Hourai.CommandModule

      @name Module.split(__MODULE__) |> List.last
      @prefix nil

      @commands []
      @submodules []

      def module_preconditions(context), do: context
      def command_preconditions(context, command), do: context
      def module_descriptor(context), do: default_module_descriptor(context)

      defoverridable [module_preconditions: 1,
                      command_preconditions: 2,
                      module_descriptor: 1]
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def default_module_descriptor(context) do
        submodules = for sub <- @submodules, do: sub.module_descriptor(context)
        %{
          name: @name,
          prefix: @prefix,
          module: __MODULE__,
          commands: @commands,
          submodules: submodules
        }
      end
    end
  end

  defmacro command(name, opts \\ [], do: expression) do
    function_name = String.to_atom(name)
    quote do
      @doc unquote(Keyword.get(opts, :help) || false)
      @commands [{unquote(function_name), unquote(opts)} | @commands]
      def unquote(function_name)(unquote_splicing([{:context, [], nil}])) do
        unquote(expression)
      end
    end
  end

  defmacro submodule(module) do
    quote do
      #require unquote(module)
      @submodules [unquote(module)] ++ @submodules
    end
  end

  def reply(context, response) do
    Util.reply(response, context.msg)
  end

end
