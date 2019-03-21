# Migration: AddChatMessagesTableToDatabase
Sequel.migration do
  change do
    create_table(:chat_messages) do
      String :message
      foreign_key :chat_user_id, :chat_users
    end
  end
end