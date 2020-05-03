# coding: utf-8
require 'discordrb'
require 'json'
require 'rubygems'
require 'mongoid'

# Bot containers

require './utils/utils'
require './help/help'
require './notes/notes'
require './hangman/hangman'
require './polls/polls'

# Bot class monkey patcher

require './botpatcher/botpatcher'

# Configure CouchPotato

Mongoid.load!('./mongoid.yml', :development)

# Set up the bot

bot = MicroBot.new token: JSON.parse(File.read 'config.json')["bot_token"]

bot.ready do |event|
  #  bot.game = "花子ちゃん、どこですか"
  bot.game = '​'
  bot.idle
end


bot.include! Utils
bot.include! Help
bot.include! Notes
bot.include! Hangman
bot.include! Polls

puts "Starting bot."
puts bot.help_modules

at_exit do
  bot.stop
end

if __FILE__ == $0
  bot.run #Apparently I shouldn't do this
end

