defmodule Hourai.Permissions do

  use Bitwise

  @permissions %{
    create_instant_invite: 0x00000001,
    kick_members: 0x00000002,
    ban_members: 0x00000004,
    administrator: 0x00000008,
    manage_channels: 0x00000010,
    manage_guild: 0x00000020,
    add_reactions: 0x00000040,
    view_audit_log: 0x00000080,
    read_messages: 0x00000400,
    send_messages: 0x00000800,
    send_tts_messages: 0x00001000,
    manage_messages: 0x00002000,
    embed_links: 0x00004000,
    attach_files: 0x00008000,
    read_message_history: 0x00010000,
    mention_everyone: 0x00020000,
    use_external_emojis: 0x00040000,
    connect: 0x00100000,
    speak: 0x00200000,
    mute_members: 0x00400000,
    deafen_members: 0x00800000,
    move_members: 0x01000000,
    use_vad: 0x02000000,
    change_nickname: 0x04000000,
    manage_nicknames: 0x08000000,
    manage_roles: 0x10000000,
    manage_webhooks: 0x20000000,
    manage_emojis: 0x40000000
  }

  def has_permission(permission_set, permission) when is_integer(permission_set) and
                                                      is_atom(permission) do
    mask = @permissions[permission]
    has_perm = (permission_set &&& mask) != 0
    case permission do
      :administrator -> has_perm
      _ -> has_perm or has_permission(permission_set, :administrator)
    end
  end

  def get_permissions(permissions) do
    @permissions
    |> Enum.filter(&has_permission(permissions, elem(&1, 0)))
    |> Enum.map(&elem(&1, 0))
  end

  def to_string(permission) do
    permission
    |> Atom.to_string
    |> String.replace("_", " ")
    |> String.capitalize
  end

end
