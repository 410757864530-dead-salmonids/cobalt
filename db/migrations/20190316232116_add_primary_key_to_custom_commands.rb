# Migration: AddPrimaryKeyToCustomCommands
Sequel.migration do
  change do
    alter_table :custom_commands do
      add_primary_key :id
    end
  end
end