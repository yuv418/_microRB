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

  message(content: ".q") do |event|
    next unless event.author.id == JSON.parse(File.read 'config.json')["admin_user"] # fix this later

    event.respond "bye"
    exit
  end

  message(content: '.r') do |event|
    next unless event.author.id == JSON.parse(File.read 'config.json')["admin_user"] # fix this later

    event.respond "restarting"
    exec('bundle exec ruby micro.rb')

  end


end
