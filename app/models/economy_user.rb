# Model: EconomyUser


# This class encapsulates a user's economy info. The user's ID is the primary key, and the model has fields for
# the user's money, next checkin time, and information on their color role.
class Bot::Models::EconomyUser < Sequel::Model
  unrestrict_primary_key
end