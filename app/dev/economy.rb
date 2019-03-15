# Crystal: Economy


# This crystal contains the featues of Cobalt's economy system.
module Bot::Economy
  extend Discordrb::Commands::CommandContainer
  extend Discordrb::EventContainer
  include Bot::Models
  
  include Constants

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
  }
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

    # Responds with embed containing user's economy profile
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
end