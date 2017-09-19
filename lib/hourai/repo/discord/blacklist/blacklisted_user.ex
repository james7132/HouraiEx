defmodule Hourai.Schema.Discord.BlacklistedUser do

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "discord_blacklisted_user" do
    field :id, :integer, primary_key: true
  end

  def changeset(user, params \\ %{}) do
    user
    |> cast(params, [:id])
    |> validate_required([:id])
  end

end
