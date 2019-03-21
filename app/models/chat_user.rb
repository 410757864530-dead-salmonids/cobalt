# Model: ChatUser


# A user currently chatting with the staff. Has fields for the user's ID, start time of the chat and the ID of the
# staff contact channel and has many chat messages.
class Bot::Models::ChatUser < Sequel::Model
  unrestrict_primary_key
  one_to_many :chat_messages
end