# Crystal: BasicCommands


# This crystal contains a ping and exit command for the bot.
module Bot::BasicCommands
  extend Discordrb::Commands::CommandContainer

  # Ping command
  command :ping do |event|
    ping = event.respond '**P** **O** **N** **G**'
    ping.edit "**P** **O** **N** **G** **|** **#{((Time.now - event.timestamp) * 1000).round}ms**"
    sleep 10
    ping.delete
  end


  # Exit command
  command :exit do |event|
    # Breaks unless event user is me (ink/salmon/ethane/whatever you call me)
    break unless event.user.id == Constants::MY_ID
    event.respond 'Shutting down.'
    exit
  end
end