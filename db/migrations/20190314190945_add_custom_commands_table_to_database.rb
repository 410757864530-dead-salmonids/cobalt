# Migration: AddCustomCommandsTableToDatabase
Sequel.migration do
  change do
    create_table(:custom_commands) do
      String :key
      String :content
      Integer :user
    end
  end
end