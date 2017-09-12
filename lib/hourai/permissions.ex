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

  def has_permission(permission_set, permission) do
    permission_set &&& Enum.find_index(@permissions, permission) != 0
  end

  def get_permissions(permissions) do
    get_perms(permissions, @permissions, [])
  end

  defp get_perms(permissions, [current | rest], perm_list) do
    perm_list = if (permissions &&& 1) == 0, do: perm_list ++ [current], else: perm_list
    get_perms(permissions >>> 1, rest, perm_list)
  end

  defp get_perms(0, _, perm_list) do perm_list end

  defp get_perms(_, [], perm_list) do perm_list end

end
