defmodule ParserTest do

  alias Hourai.CommandParser
  alias Nostrum.Struct.Guild
  alias Nostrum.Struct.Guild.Member
  alias Nostrum.Struct.Guild.Role
  alias Nostrum.Struct.Guild.Channel
  alias Nostrum.Struct.User

  use ExUnit.Case

  defp member() do
    %Member{
      nick: "GeorgePBurdell",
      user: %User{
        username: "ThatAintFalco",
        id: 89084521336541184
    }}
  end

  defp role() do
    %Role{
      id: 274989267086868480,
      name: "Moderator"
    }
  end

  defp channel do
    %Channel{
      id: 163914532157259777,
      name: "bot-stuff"
    }
  end

  defp guild() do
    %Guild{
      roles: [role()],
      channels: [channel()],
      members: [member()]
    }
  end

  test "split acts normally without quotes" do
    assert CommandParser.split("Test 1  2  6   56") == ["Test", "1", "2", "6", "56"]
  end

  test "split ignores spaces inside quotes" do
    assert CommandParser.split("Test 20 \"1  2  6\" 42    56") == ["Test", "20", "1  2  6", "42", "56"]
  end

  test "split can work with multiple quoted sections" do
    assert CommandParser.split("Test 20 \"1  2  6\" 200 \"42    56\"") ==
      ["Test", "20", "1  2  6", "200", "42    56"]
  end

  test "parse_tag passes the tag along if it doesn't match" do
    assert CommandParser.parse_tag("Unmatched Tag", guild()) == "Unmatched Tag"
  end

  test "parse_tag works on channel names" do
    assert CommandParser.parse_tag("bot-stuff", guild()) == channel()
  end

  test "parse_tag works on usernames" do
    assert CommandParser.parse_tag("ThatAintFalco", guild()) == member()
  end

  test "parse_tag works on user nicknames" do
    assert CommandParser.parse_tag("GeorgePBurdell", guild()) == member()
  end

  test "parse_tag works on role names" do
    assert CommandParser.parse_tag("Moderator", guild()) == role()
  end

  test "parse_tag works on channel mentions" do
    assert CommandParser.parse_tag("<#163914532157259777>", guild()) == channel()
  end

  test "parse_tag works on user mentions" do
    assert CommandParser.parse_tag("<@89084521336541184>", guild()) == member()
  end

  test "parse_tag works on user nickname mentions" do
    assert CommandParser.parse_tag("<@89084521336541184>", guild()) == member()
  end

  test "parse_tag works on role mentions" do
    assert CommandParser.parse_tag("<@&274989267086868480>", guild()) == role()
  end

  test "parse_tag works on channel ids" do
    assert CommandParser.parse_tag("163914532157259777", guild()) == channel()
  end

  test "parse_tag works on user ids" do
    assert CommandParser.parse_tag("89084521336541184", guild()) == member()
  end

  test "parse_tag works on role ids" do
    assert CommandParser.parse_tag("274989267086868480", guild()) == role()
  end

  test "parse_channel works on names" do
    assert CommandParser.parse_channel("bot-stuff", guild()) == channel()
  end

  test "parse_member works on usernames" do
    assert CommandParser.parse_guild_member("ThatAintFalco", guild()) == member()
  end

  test "parse_member works on nicknames" do
    assert CommandParser.parse_guild_member("GeorgePBurdell", guild()) == member()
  end

  test "parse_role works on role names" do
    assert CommandParser.parse_role("Moderator", guild()) == role()
  end

  test "parse_channel works on mentions" do
    assert CommandParser.parse_channel("<#163914532157259777>", guild()) == channel()
  end

  test "parse_member works on mentions" do
    assert CommandParser.parse_guild_member("<@89084521336541184>", guild()) == member()
  end

  test "parse_member works on nickname mentions" do
    assert CommandParser.parse_guild_member("<@!89084521336541184>", guild()) == member()
  end

  test "parse_role works on mentions" do
    assert CommandParser.parse_role("<@&274989267086868480>", guild()) == role()
  end

  test "parse_channel works on ids" do
    assert CommandParser.parse_channel("163914532157259777", guild()) == channel()
  end

  test "parse_member works on ids" do
    assert CommandParser.parse_guild_member("89084521336541184", guild()) == member()
  end

  test "parse_role works on ids" do
    assert CommandParser.parse_role("274989267086868480", guild()) == role()
  end

end
