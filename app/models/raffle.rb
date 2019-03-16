# Model: Raffle


# Singleton model class that holds the information of the currently running raffle. Contains fields for the
# raffle's current money pool, end time (raffle draw) and has many RaffleTickets.
class Bot::Models::Raffle < Sequel::Model
  one_to_many :raffle_tickets

  # Returns the instance of this singleton
  def self.get
    self.first || self.create
  end
end