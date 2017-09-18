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

      @command_doc @name
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def module_descriptor(include_submodules \\ true) do
        %{
          name: @name,
          prefix: @prefix,
          module: __MODULE__,
          commands: @commands,
          help: @command_doc,
          submodules: Enum.map(@submodules, fn submodule ->
            submodule.module_descriptor()
           end)
        }
      end
    end
  end

  defmacro command(name, opts \\ [], do: expression) do
    function_name = String.to_atom(name)
    quote do
      @doc unquote(Keyword.get(opts, :help) || false)
      @commands [{unquote(function_name), unquote(opts)}] ++ @commands
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
