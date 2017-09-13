defmodule Hourai.CommandParser do

  def split(msg) when is_binary(msg) do
    {result, _} =
      msg
      |> String.split("\"")
      |> Enum.reduce({[], false},
        fn(opt, {opts, state}) ->
          if state do
            {[opt] ++ opts , false}
          else
            {(opt |> String.split |> Enum.reverse) ++ opts , true}
          end
        end)
    Enum.reverse(result)
  end

end
