defmodule ParserTest do

  alias Hourai.CommandParser
  alias Nostrum.Struct.Guild
  alias Nostrum.Struct.Guild.Member
  alias Nostrum.Struct.Guild.Role
  alias Nostrum.Struct.Guild.Channel
  alias Nostrum.Struct.User
  use ExUnit.Case

  test "Split acts normally without quotes" do
    assert CommandParser.split("Test 1  2  6   56") == ["Test", "1", "2", "6", "56"]
  end

  test "Split ignores spaces inside quotes" do
    assert CommandParser.split("Test 20 \"1  2  6\" 42    56") == ["Test", "20", "1  2  6", "42", "56"]
  end

  test "Split can work with multiple quoted sections" do
    assert CommandParser.split("Test 20 \"1  2  6\" 200 \"42    56\"") ==
      ["Test", "20", "1  2  6", "200", "42    56"]
  end

  test "parse_channel works on names" do
    channel = %Channel{ id: 274989267086868480, name: "bot-stuff" }
    guild = %Guild{ channels: [channel] }
    assert CommandParser.parse_channel("bot-stuff", guild) == channel
  end

  test "parse_member works on usernames" do
    member = %Member{ user: %User{ username: "GeorgePBurdell", id: 274989267086868480 }}
    guild = %Guild{ members: [member] }
    assert CommandParser.parse_guild_member("GeorgePBurdell", guild) == member
  end

  test "parse_member works on nicknames" do
    member = %Member{ nick: "Reimu Hakurei", user: %User{ id: 274989267086868480 }}
    guild = %Guild{ members: [member] }
    assert CommandParser.parse_guild_member("Reimu Hakurei", guild) == member
  end

  test "parse_role works on role names" do
    role = %Role{ id: 274989267086868480, name: "Moderator" }
    guild = %Guild{ roles: [role] }
    assert CommandParser.parse_role("Moderator", guild) == role
  end

  test "parse_channel works on mentions" do
    channel = %Channel{ id: 274989267086868480 }
    guild = %Guild{ channels: [channel] }
    assert CommandParser.parse_channel("<#274989267086868480>", guild) == channel
  end

  test "parse_member works on mentions" do
    member = %Member{ user: %User{ id: 274989267086868480 }}
    guild = %Guild{ members: [member] }
    assert CommandParser.parse_guild_member("<@274989267086868480>", guild) == member
  end

  test "parse_member works on nickname mentions" do
    member = %Member{ user: %User{ id: 274989267086868480 }}
    guild = %Guild{ members: [member] }
    assert CommandParser.parse_guild_member("<@!274989267086868480>", guild) == member
  end

  test "parse_role works on mentions" do
    role = %Role{ id: 274989267086868480 }
    guild = %Guild{ roles: [role] }
    assert CommandParser.parse_role("<@&274989267086868480>", guild) == role
  end

  test "parse_channel works on ids" do
    channel = %Channel{ id: 274989267086868480 }
    guild = %Guild{ channels: [channel] }
    assert CommandParser.parse_channel("274989267086868480", guild) == channel
  end

  test "parse_member works on ids" do
    member = %Member{ user: %User{ id: 274989267086868480 }}
    guild = %Guild{ members: [member] }
    assert CommandParser.parse_guild_member("274989267086868480", guild) == member
  end

  test "parse_role works on ids" do
    role = %Role{ id: 274989267086868480 }
    guild = %Guild{ roles: [role] }
    assert CommandParser.parse_role("&274989267086868480", guild) == role
  end
end
