# Migration: AddPrimaryKeyToChatMessage
Sequel.migration do
  change do
    alter_table :chat_messages do
      add_primary_key :id
    end
  end
end