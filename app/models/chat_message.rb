# Model: ChatMessage


# A message sent in a staff contact channel. Has a generic primary key and a field for a formatted string of the
# message. Belongs to a ChatUser.
class Bot::Models::ChatMessage < Sequel::Model
  # empty
end