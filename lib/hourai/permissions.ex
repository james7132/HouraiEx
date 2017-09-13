defmodule Hourai.Permissions do

  use Bitwise

  @permissions [
    :create_instant_invite,
    :kick_members,
    :ban_members,
    :ban_members,
    :administrator,
    :manage_channels,
    :manage_guild,
    :add_reactions,
    :view_audit_log,
    :read_messages,
    :send_messages,
    :send_tts_messages,
    :manage_messages,
    :embed_links,
    :attach_files,
    :mention_everyone,
    :use_external_emojis,
    :voice_connect,
    :voice_speak,
    :mute_members,
    :deafen_members,
    :move_members,
    :use_vad,
    :change_nickname,
    :manage_nicknames,
    :manage_roles,
    :manage_webhooks,
    :manage_emoji
  ]

  def has_permission(permission_set, permission)  do
    index = Enum.find_index(@permissions, &Kernel.==(&1,permission))
    mask = 1 <<< index
    has_perm = (permission_set &&& mask) != 0
    case permission do
      :administrator -> has_perm
      _ -> has_perm or has_permission(permission_set, :administrator)
    end
  end

  def get_permissions(permissions) do
    Enum.filter(@permissions, &has_permission(permissions, &1))
  end

end
