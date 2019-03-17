# Migration: AddRaffleTableToDatabase
Sequel.migration do
  change do
    create_table(:raffle) do
      primary_key :id
      Integer :pool
      Time :end_time
    end
  end
end