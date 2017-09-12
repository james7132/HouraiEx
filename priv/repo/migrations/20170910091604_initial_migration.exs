defmodule Hourai.Repo.Migrations.InitialMigration do
  use Ecto.Migration

  def change do

    create table(:discord_username, primary_key: false) do
      add :user_id, :bigint, pimary_key: true, null: false
      add :date, :utc_datetime, primary_key: true
      add :name, :string, size: 32
    end

    create index(:discord_username, :user_id)

    create table(:discord_blacklisted_user, primary_key: false) do
      add :id, :bigint, primary_key: true
    end

    create table(:discord_blacklisted_guild, primary_key: false) do
      add :id, :bigint, primary_key: true
    end

    create table(:discord_feed, primary_key: false) do
      add :id, :bigserial, primary_key: true
      add :feed_url, :string
    end

    create table(:discord_feed_channel, primary_key: false) do
      add :feed_id, references(:discord_feed), primary_key: true, null: false
      add :channel_id, :bigint, primary_key: true
    end

    create table(:discord_custom_command, primary_key: false) do
      add :guild_id, :bigint, primary_key: true, null: false
      add :name, :string, primary_key: true
      add :response, :string, null: false, size: 2000
    end

    create index(:discord_custom_command, :guild_id)
  end
end
