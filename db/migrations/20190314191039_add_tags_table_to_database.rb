# Migration: AddTagsTableToDatabase
Sequel.migration do
  change do
    create_table(:tags) do
      String :key
      String :content
      Integer :user
    end
  end
end