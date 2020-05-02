# coding: utf-8
require 'discordrb'

module Help
  extend Discordrb::EventContainer

  message(start_with: ".help") do |event|
    help = JSON.parse(File.read './help/help.json')

    if event.message.content.split.length == 1
      event.channel.send_embed do |embed|
        embed.title = "Help Menu"
        embed.description = "You can find out more about each module by doing `.help <module name>`."

        help['modules'].keys.each do |moduleName|
          embed.add_field name: "`#{moduleName}`", value: "#{help['modules'][moduleName]['desc']}", inline: true
        end

      end
    else
      moduleName = event.message.content.split[1]

      next unless help['modules'].has_key? moduleName
      event.channel.send_embed do |embed|
        embed.title = "Help for module `#{moduleName}`"
        embed.description = "Below are the commands for this module and what you can do with them:"

        help['modules'][moduleName]['commands'].each do |command, description|
          embed.add_field name: "`#{command}`", value: "#{description}", inline: true
        end

      end
    end

  end

  mention do |event|
    event.channel.send_embed do |embed|
      embed.title = "Hi!"
      embed.description = "I'm _μ. To learn more, try `.help`."

      embed.color = 0x00ff00
    end
  end
end
