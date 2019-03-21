# Crystal: Chat


# This crystal manages the staff contact chat function.
module Bot::Chat
  extend Discordrb::Commands::CommandContainer
  extend Discordrb::EventContainer
  include Bot::Models

  include Constants

  # Moderation category ID
  MODERATION_ID = 360721386697654272
  # #staff_contact_logs channel ID
  STAFF_CONTACT_LOGS_ID = 346987188766113792

  event_handlers = Hash.new

  # Iterate through every existing chat user and defines event handlers for their and channels
  ready do
    ChatUser.all do |chat_user|
      user = Bot::BOT.user(chat_user.id)

      # Skip if an event handler for them already exists
      next if event_handlers[chat_user.id]

      # Define event handler for channel and store it in hash
      event_handlers[chat_user.id] = Bot::BOT.message in: chat_user.channel_id do |event|
        # Skip if the bot is the one sending the message or the message is the +end command
        next if event.user == Bot::BOT.profile ||
                event.message.content == '+end'

        # If no attachments were sent with the message, DM user, create chat message and add to log
        if event.message.attachments.empty?
          user.dm "**#{event.user.distinct}** | #{event.message.content}"
          chat_message = ChatMessage.create(message: "#{event.user.distinct} - #{event.message.content}")
          chat_user.add_chat_message(chat_message)

        # If attachments were sent with the message, DM user, create chat message and add to log
        else
          event.user.dm <<~DM.strip
            **#{event.user.distinct}:** #{event.message.content}

            #{event.message.attachments.each_with_index.map { |a, i| "**Attachment #{i + 1}:** #{a.url}" }.join("\n")}
          DM
          chat_message = ChatMessage.create(
              message: <<~MESSAGE.strip
                #{event.user.distinct} - #{event.message.content}
                #{event.message.attachments.each_with_index.map { |a, i| "Attachment #{i + 1}: #{a.url}" }.join("\n")}
              MESSAGE
          )
          chat_user.add_chat_message(chat_message)
        end
      end
    end
  end

  # Trigger a staff contact chat session
  command :chat do |event|
    # Skip unless used in DMs
    next unless event.channel.private?

    # Skip if user already has a ChatUser object
    next if ChatUser[event.user.id]

    chat_user = ChatUser.create(id: event.user.id, start_time: Time.now)

    # Create contact channel and set chat user's channel ID
    channel = SERVER.create_channel(
        "chat-#{event.user.name.scan(/\w|\s/).map { |c| c =~ /\s/ ? '_' : c }.join}-#{event.user.discrim}",
        topic:  "Chat with user #{event.user.mention}",
        parent: MODERATION_ID,
        reason: "Chat with user #{event.user.distinct}"
    )
    chat_user.channel_id = channel.id

    # Save to database
    chat_user.save

    # Send message in channel pinging online staff that a user would like to speak with them
    channel.send("@ here **User #{event.user.distinct} would like to speak with the staff.**")

    # Add event handler for messages sent in the channel and store it in hash
    event_handlers[event.user.id] = Bot::BOT.message in: channel do |subevent|
      # Skip if the bot is the one sending the message or the message is the +end command
      next if subevent.user == Bot::BOT.profile ||
              subevent.message.content == '+end'

      # If no attachments were sent with the message, DM user, create chat message and add to log
      if subevent.message.attachments.empty?
        event.user.dm "**#{subevent.user.distinct}** | #{subevent.message.content}"
        chat_message = ChatMessage.create(message: "#{subevent.user.distinct} - #{subevent.message.content}")
        chat_user.add_chat_message(chat_message)

        # Otherwise, DM user, create chat message and add to log
      else
        event.user.dm <<~DM.strip
          **#{subevent.user.distinct}:** #{subevent.message.content}

          #{subevent.message.attachments.each_with_index.map { |a, i| "**Attachment #{i + 1}:** #{a.url}" }.join("\n")}
        DM
        chat_message = ChatMessage.create(
            message: <<~MESSAGE.strip
              #{subevent.user.distinct} - #{subevent.message.content}
              #{subevent.message.attachments.each_with_index.map { |a, i| "Attachment #{i + 1}: #{a.url}" }.join("\n")}
            MESSAGE
        )
        chat_user.add_chat_message(chat_message)
      end
    end

    # Respond to user
    event.respond '**Your chat session has begun. You can speak to the staff through this DM.**'
  end

  # Relay message to contact channel when message is sent in DM during active chat session
  message private: true do |event|
    # Skip if message is the +chat command
    next if event.message.content == '+chat'

    # Skip unless event user has a chat user
    next unless (chat_user = ChatUser[event.user.id])

    channel = Bot::BOT.channel(chat_user.channel_id)

    # If no attachments were sent with the message, send message to contact channel, create chat message and add to log
    if event.message.attachments.empty?
      channel.send_message "**#{event.user.distinct}** | #{event.message.content}"
      chat_message = ChatMessage.create(message: "#{event.user.distinct} - #{event.message.content}")
      chat_user.add_chat_message(chat_message)

      # Otherwise, send message to contact channel, create chat message and add to log
    else
      channel.send_message <<~MESSAGE.strip
        **#{event.user.distinct}:** #{event.message.content}

        #{event.message.attachments.each_with_index.map { |a, i| "**Attachment #{i + 1}:** #{a.url}" }.join("\n")}
      MESSAGE
      chat_message = ChatMessage.create(
          message: <<~MESSAGE.strip
            #{event.user.distinct} - #{event.message.content}
            #{event.message.attachments.each_with_index.map { |a, i| "Attachment #{i + 1}: #{a.url}" }.join("\n")}
          MESSAGE
      )
      chat_user.add_chat_message(chat_message)
    end
  end

  # End a chat session with a user
  command :end do |event|
    # Break unless the command is used in a staff contact channel
    break unless (chat_user = ChatUser[channel_id: event.channel.id])

    user = Bot::BOT.user(chat_user.id)

    # DM user
    user.dm '**Your chat session with the staff has ended.**'

    # Write chat log to file and upload to log channel
    File.open("#{ENV['DATA_PATH']}/log.txt", 'w') do |file|
      file.write <<~LOG.strip
        Log of chat with user #{user.distinct} at #{chat_user.start_time}
        
        #{chat_user.chat_messages.map(&:message).join("\n--------------------\n")}
        
        Chat ended by #{event.user.distinct}.
      LOG
    end
    Bot::BOT.send_file(
        STAFF_CONTACT_LOGS_ID,
        File.open("#{ENV['DATA_PATH']}/log.txt"),
        caption: "**Log of chat with user `#{user.distinct}`**"
    )

    # Remove event handler for channel
    Bot::BOT.remove_handler(event_handlers[user.id])

    # Respond to user, sleep 5 seconds and delete channel
    event.respond '**The chat session has been logged. This channel will be deleted in 5 seconds.**'
    sleep 5
    event.channel.delete "Ended chat with #{user.distinct}"

    # Delete user's chat messages and user
    chat_user.chat_messages_dataset.delete
    chat_user.destroy

    nil # return nil so command doesn't send extra message
  end
end