require 'discordrb'

module Utils
  extend Discordrb::EventContainer

  message(content: ".ping") do |event|
    event.respond "pong #{(Time.now - event.timestamp) * 100} ms"
  end

  message(content: ".testembed") do |event|
    event.channel.send_embed do |embed|
      embed.title = "test embed"
      embed.color = 0x00ff00
      embed.description = "test embed"
    end
    exit
  end

  message(content: ".apoptosis") do |event|
    break unless event.author.id == JSON.parse(File.read 'config.json')["admin_user"] # fix this later

    event.respond "bye"
    exit
  end




end
