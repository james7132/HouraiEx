defmodule PermissionTest do
  alias Hourai.Permissions
  use ExUnit.Case

  test "" do
    assert Permissions.has_permission(0x11, :create_instant_invite)
  end
end
