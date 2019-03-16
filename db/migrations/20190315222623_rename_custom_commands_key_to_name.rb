# Migration: RenameCustomCommandsKeyToName
Sequel.migration do
  change do
    alter_table :custom_commands do
      rename_column :key, :name
    end
  end
end