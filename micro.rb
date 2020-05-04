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
require './wizardtester/wizardtester'

# Bot class monkey patcher

require './botpatcher/botpatcher'

# Configure CouchPotato

Mongoid.load!('./mongoid.yml', :development)

# Set up the bot

bot = MicroBot.new token: JSON.parse(File.read 'config.json')["bot_token"]

bot.ready do |event|
  #  bot.game = "花子ちゃん、どこですか"
  if JSON.parse(File.read 'config.json')["stable"]
    bot.game = '​'
  else
    bot.game = 'with rubies'
  end

  bot.idle
end


bot.include! Utils
bot.include! Help
bot.include! Notes
bot.include! Hangman
bot.include! Polls
bot.include! WizardTester

puts "Starting bot."

if ARGV[0]
  bot.channel(ARGV[0]).send_message "started up"
end

at_exit do
  bot.stop
end

if __FILE__ == $0
  bot.run #Apparently I shouldn't do this
end

