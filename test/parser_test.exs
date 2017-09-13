defmodule ParserTest do
  alias Hourai.CommandParser
  use ExUnit.Case

  test "Parser acts normally without quotes" do
    assert CommandParser.split("Test 1  2  6   56") == ["Test", "1", "2", "6", "56"]
  end

  test "Parser ignores spaces inside quotes" do
    assert CommandParser.split("Test 20 \"1  2  6\" 42    56") == ["Test", "20", "1  2  6", "42", "56"]
  end

  test "Parser can work with multiple quoted sections" do
    assert CommandParser.split("Test 20 \"1  2  6\" 200 \"42    56\"") ==
      ["Test", "20", "1  2  6", "200", "42    56"]
  end

end
