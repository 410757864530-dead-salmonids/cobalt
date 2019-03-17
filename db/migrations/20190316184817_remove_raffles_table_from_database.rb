# Migration: RemoveRafflesTableFromDatabase
Sequel.migration do
  up do
    drop_table(:raffles)
  end

  down do
    create_table(:raffles) do
      primary_key :id
      Integer :pool
      DateTime :end_time
    end
  end
end