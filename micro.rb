# coding: utf-8
require 'discordrb'
require 'json'
require 'rubygems'
require 'mongoid'

# Bot containers

require './notes/notes'
require './utils/utils'
require './hangman/hangman'
require './help/help'

# Configure CouchPotato

Mongoid.load!('./mongoid.yml', :development)

# Set up the bot

bot = Discordrb::Bot.new token: JSON.parse(File.read 'config.json')["bot_token"]

bot.ready do |event|
  bot.game = "花子ちゃん、どこですか"
  bot.idle
end

bot.include! Utils
bot.include! Help
bot.include! Notes
bot.include! Hangman

puts "Starting bot."

at_exit do
  bot.stop
end

bot.run

