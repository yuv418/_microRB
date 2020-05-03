require 'discordrb'

module Utils
  extend Discordrb::EventContainer

  HELP_DATA = {
    "desc" => "Bot utilities. Maybe kinda boring.",
    "commands" => {
      ".q" => "Stop trying to shut down my bot",
      ".r" => "Yeah no",
      ".ping" => "Ping the bot. Self-explanatory",
      ".testembed" => "Sends a test embed."
    }
  }

  message(start_with: ".ping") do |event|
    decim = event.message.content.strip.split[1]
    decim = decim.to_i ? decim.to_i : 2
    event.respond "pong #{((Time.now - event.timestamp) * 100).round(decim)} ms"
  end

  message(content: ".testembed") do |event|
    event.channel.send_embed do |embed|
      embed.title = "test embed"
      embed.color = 0x00ff00
      embed.description = "test embed"
    end
    exit
  end

  message(content: ".q") do |event|
    next unless event.author.id == JSON.parse(File.read 'config.json')["admin_user"] # fix this later

    event.respond "bye"
    exit
  end

  message(content: '.r') do |event|
    next unless event.author.id == JSON.parse(File.read 'config.json')["admin_user"] # fix this later

    event.respond "restarting"
    exec("bundle exec ruby micro.rb #{event.channel.id}")

  end


end
