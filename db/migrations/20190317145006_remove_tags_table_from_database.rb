# Migration: RemoveTagsTableFromDatabase
Sequel.migration do
  up do
    drop_table(:tags)
  end

  down do
    create_table(:tags) do
      String :key, :size=>255
      String :content, :size=>255
      Integer :user
      primary_key :id, :keep_order=>true
    end
  end
end