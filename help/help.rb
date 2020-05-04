# coding: utf-8
require 'discordrb'

module Help
  extend Discordrb::EventContainer

  HELP_DATA = {
    "desc" => "The help module!",
    "commands" => {
      ".help" => "Lists the bot's modules and their descriptions",
      ".help <moduleName>" => "Detailed help about a module from `.help`"
    }
  }


  message(start_with: ".help") do |event|
    help = event.bot.help_modules
    help_strings = help.map{ |i| i.to_s }

    if event.message.content.split.length == 1
      event.channel.send_embed do |embed|
        embed.title = "Help Menu"
        embed.description = "You can find out more about each module by doing `.help <module name>`."

        help.each do |moduleName|
          embed.add_field name: "#{moduleName}", value: "#{moduleName::HELP_DATA['desc']}", inline: true
        end

      end
    else
      moduleName = event.message.content.strip.split[1]
      next unless help_strings.include? moduleName

      help_module = help[help_strings.index moduleName]

      event.channel.send_embed do |embed|
        embed.title = "Help for module `#{help_module}`"
        embed.description = "Below are the commands for this module and what you can do with them:"

        help_module::HELP_DATA['commands'].each do |command, description|
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
