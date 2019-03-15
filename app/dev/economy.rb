# Crystal: Economy


# This crystal contains the featues of Cobalt's economy system.
module Bot::Economy
  extend Discordrb::Commands::CommandContainer
  extend Discordrb::EventContainer
  include Bot::Models
  
  include Constants

  # Path to this crystal's data folder
  ECON_DATA_PATH = "#{ENV['DATA_PATH']}/economy"
  # Color role names and IDs
  COLOR_ROLES = {
      'Ghastly Green'     => 308634210564964353,
      'Obsolete Orange'   => 434036486808272916,
      'Breathtaking Blue' => 434036732162211861,
      'Lullaby Lavender'  => 434037025663090688,
      'Retro Red'         => 434040026192543764,
      'Whitey White'      => 436566003896418307,
      'Shallow Yellow'    => 440174617697583105,
      'Marvelous Magenta' => 440182036800471041
  }.freeze
  # Color role short names and IDs
  COLOR_ROLES_SHORT = {
      'green'    => 308634210564964353,
      'orange'   => 434036486808272916,
      'blue'     => 434036732162211861,
      'lavender' => 434037025663090688,
      'red'      => 434040026192543764,
      'white'    => 436566003896418307,
      'yellow'   => 440174617697583105,
      'magenta'  => 440182036800471041
  }.freeze
  # Mee6 override role names and IDs
  OVERRIDE_ROLES = {
      'Citizen Override'    => 460505017120587796,
      'Squire Override'     => 460505130203217921,
      'Knight Override'     => 460505230128185365,
      'Noble Override'      => 553320915409305609,
      'Monarch Override'    => 481049629773922304,
      'Wandbearer Override' => 553319697420910632
  }.freeze
  # Mee6 role IDs
  MEE6_ROLES = {
      citizen:    320438721923252225,
      squire:     347071589768101908,
      knight:     321206686872502274,
      noble:      553320915409305609,
      monarch:    481049629773922304,
      wandbearer: 318519367971241984
  }.freeze
  # #bot_commands ID
  BOT_COMMANDS_ID = 307726225458331649
  # #moderation_channel ID
  MODERATION_CHANNEL_ID = 330586271116165120
  # Time interval in seconds between checkins (23 hours)
  CHECKIN_INTERVAL = 82800
  # Time interval in seconds between payments for color roles (24 hours)
  COLOR_ROLE_DAILY_INTERVAL = 86400
  # Bucket for rate limiting money earning through chat activity (once every two minutes)
  EARN_BUCKET = Bot::BOT.bucket(
      :earn,
      limit:     1,
      time_span: 120
  )
  # Bucket for rate limiting money transfers (once every minute)
  TRANSFER_BUCKET = Bot::BOT.nucket(
      :transfer,
      limit:     1,
      time_span: 60
  )

  multiplier = 1

  # Give user Starbucks for every message they send, with a 2 minute delay between earning money this way
  message do |event|
    # Skips if event channel is disabled from message activity earning
    next if YAML.load_data!("#{ECON_DATA_PATH}/earn_disabled_channels.yml").include? event.channel.id

    # Skips is user is currently rate limited (has already earned money within the past 2 minutes)
    next if EARN_BUCKET.rate_limited? event.user.id

    economy_user = EconomyUser[event.user.id] || EconomyUser.create(id: event.user.id)

    # Adds Starbucks to user and saves to database
    economy_user.money += (rand(1..5) * multiplier)
    economy_user.save
  end

  # Check user's economy profile
  command :profile, channels: [BOT_COMMANDS_ID, MODERATION_CHANNEL_ID] do |event, *args|
    # Sets argument default to event user
    args[0] ||= event.user.id

    # Breaks unless given user is valid
    break unless (user = SERVER.get_user(args.join(' ')))

    economy_user = EconomyUser[user.id] || EconomyUser.create(id: user.id)
    to_next_checkin = if economy_user.next_checkin && economy_user.next_checkin > Time.now
                        (economy_user.next_checkin - Time.now).round.to_dhms
                      else 'None'
                      end

    # Respond with embed
    event.channel.send_embed do |embed|
      embed.author = {
          name:     "#{user.display_name} (#{user.distinct})",
          icon_url: user.avatar_url
      }
      embed.description = <<~DESC.strip
        **Balance:** #{economy_user.money} Starbucks
        **Time until next check-in:** #{to_next_checkin}
      DESC
      embed.add_field(
          name:  'Color Role',
          value: economy_user.color_role
      )
      embed.color = 0xFFD700
      embed.footer = {text: 'Use +checkin once every 23 hours to earn 50 Starbucks.'}
    end
  end

  # Check in and get daily Starbucks
  command :checkin, channels: [BOT_COMMANDS_ID] do |event|
    economy_user = EconomyUser[event.user.id] || EconomyUser.create(id: event.user.id)

    # If user's next checkin time exists and has not passed, respond to user
    if economy_user.next_checkin && economy_user.next_checkin > Time.now
      time_to_next_checkin = (economy_user.next_checkin - Time.now).round.to_dhms
      event << "**#{event.user.mention}, you can't check in yet!** Time until next check-in: #{time_to_next_checkin}"

    # Otherwise:
    else
      # Add Starbucks based on user's highest Mewman role
      earned_money = if event.user.role? MEWMAN_ROLES[:wandbearer]
                       200
                     elsif event.user.role? MEWMAN_ROLES[:monarch]
                       175
                     elsif event.user.role? MEWMAN_ROLES[:noble]
                       150
                     elsif event.user.role? MEWMAN_ROLES[:knight]
                       125
                     elsif event.user.role? MEWMAN_ROLES[:squire]
                       100
                     elsif event.user.role? MEWMAN_ROLES[:citizen]
                       75
                     else 50
                     end
      earned_money *= multiplier
      economy_user.money += earned_money

      # Set next checkin time
      economy_user.next_checkin = Time.now + CHECKIN_INTERVAL

      # Save to database
      economy_user.save

      # Respond to user
      event.respond(
          <<~RESPONSE.strip,
            **#{event.user.mention}, you have checked in! You receive #{earned_money} Starbucks.**
            Check in again in 23 hours.
          RESPONSE
          false,
          {image: {url: 'http://i65.tinypic.com/2rc5379.gif'}}
      )
    end
  end

  command :multiplier do |event, arg|
    # Breaks unless user is moderator
    break unless event.user.role? MODERATOR_ID

    # If argument is given and greater than or equal to 0, sets earn multiplier to argument
    if arg && arg.to_i >= 0
      multiplier = arg.to_i
      event << "**Set earn multiplier to #{multiplier}x.**"

    # Otherwise, returns current multiplier
    else event << "**The current earn multiplier is #{multiplier}x.**"
    end
  end

  # Rent a color role
  command :rentarole do |event, arg|
    # If argument is given:
    if arg
      # Validates that the given argument is one of the color roles
      break unless (role_id = COLOR_ROLES_SHORT[arg.downcase])

      role_name = COLOR_ROLES.key(role_id)
      economy_user = EconomyUser[event.user.id] || EconomyUser.create(id: event.user.id)

      # If user has enough money to rent a role:
      if economy_user.money >= 300
        # Takes upfront cost of 300 from user
        economy_user.money -= 300

        # Sets user's color role info
        economy_user.color_role = role_name
        economy_user.color_role_daily = Time.now + COLOR_ROLE_DAILY_INTERVAL

        # Saves to database
        economy_user.save

        # Responds to user
        event << "**#{event.user.mention}, you are now renting #{role_name}.** Enjoy your new color!"

      # Otherwise, responds to user
      else event.send_temp("#{event.user.mention}, you don't have enough money to rent a color role!", 5)
      end

    # If no argument is given, responds to user with information embed:
    else
      event.send_embed do |embed|
        embed.author = {
            name:     'Rent-A-Role: Info',
            icon_url: 'http://i68.tinypic.com/2rdkuwi.jpg'
        }
        embed.description = <<~DESC.strip
          This is the Rent-A-Role info page. You can rent one of the available color roles here at a time.
          Renting a role costs 300 starbucks upfront and costs 200 Starbucks a day to keep -- but it gives you a color and that's cool.
          The roles currently available are: #{COLOR_ROLES_SHORT.keys.join(', ')}
          To rent a role, use this command again with the color name (i.e. `+rentarole yellow`).
          Use the command `+unrentarole` if you would like to give up your role -- you will be returned 100 Starbucks.
          However, be warned! If you are unable to pay the fee on any day, you will lose the role and will not be returned anything.
          While you only need 300 Starbucks to make the initial payment on a role, it is recommended you have an excess of money before making the payment.
        DESC
        embed.color = 0xFFD700
        embed.footer = {text: 'Use +checkin once every 23 hours to earn Starbucks.'}
      end
    end
  end
end