# Migration: AddPrimaryKeyToTags
Sequel.migration do
  change do
    alter_table :tags do
      add_primary_key :id
    end
  end
end