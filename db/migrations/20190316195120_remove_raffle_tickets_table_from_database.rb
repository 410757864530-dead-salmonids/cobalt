# Migration: RemoveRaffleTicketsTableFromDatabase
Sequel.migration do
  up do
    drop_table(:raffle_tickets)
  end

  down do
    create_table(:raffle_tickets) do
      primary_key :id
      Integer :user
      foreign_key :raffle_id, :raffles
    end
  end
end