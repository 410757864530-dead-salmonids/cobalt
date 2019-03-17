# Model: Raffle (singleton)


# Class to hold the current raffle information. Has fields for the current money pool and raffle end time
class Bot::Models::Raffle < Sequel::Model(:raffle)
  private_class_method :new, :create

  # Returns the only instance of this class
  def self.instance
    first || create
  end

  one_to_many :raffle_tickets
end