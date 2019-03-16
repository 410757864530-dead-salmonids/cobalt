# Migration: AddRafflesTableToDatabase
Sequel.migration do
  change do
    create_table(:raffles) do
      primary_key :id
      Integer :pool
      Time :end_time
    end
  end
end