# Migration: AddRaffleTicketsTableToDatabase
Sequel.migration do
  change do
    create_table(:raffle_tickets) do
      primary_key :id
      Integer :user
      foreign_key :raffle_id, :raffles
    end
  end
end