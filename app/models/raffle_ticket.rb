# Model: RaffleTicket


# A ticket for the current raffle. Belongs to Raffle and has a single field for user ID.
class Bot::Models::RaffleTicket < Sequel::Model
  unrestrict_primary_key
end