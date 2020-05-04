require './hangman/hangmanmodel'
require './jeepapi/jeep'
require './botpatcher/dmwizardcontainer'
require 'discordrb'
require 'securerandom'


module Hangman
  include DMWizardContainer
  extend DMWizardContainer

  HELP_DATA = {
    "desc" => "Play hangman!",
    "commands" => {
      ".hangman newgame" => "Make a hangman game (channel specific). This doesn't work if there's already a game in the channel.",
      ".hangman deletegame" => "Delete a hangman game in the channel (only if you are the creator).\n**Note:** the bot will ignore you with this command if there is no existing game." # TODO admins too
    }
  }

  @jeep = JeepAPI.new base_url: @@config['jeep_url'], user_id: @@config['jeep_user'], key: @@config['jeep_key'], verify_ssl: @@config['jeep_verify_ssl']


  message(content: '.hangman newgame') do |event|

#    @wizardData[event.user.id.to_s] = { # TODO delete this after the wizard completes
#      :creator => event.user.id.to_s,
#      :channel => event.channel.id.to_s,
#      :stage => 2
#    }

    event.user.dm.send_embed do |embed|
      embed.title = "Welcome to the Hangman Game Creation Wizard!"
      embed.color = 0xb412ea
      embed.description = "What's the word for the game you want to create?"
    end

    stage_create event.user.id.to_s do |data|
      data[:channel] = event.channel.id.to_s
      data[:creator] = event.user.id.to_s
    end

  end

  message(content: '.hangman deletegame') do |event|
    next unless HangmanGame.where(channel: event.channel.id.to_s).count == 1
    game = HangmanGame.where(channel: event.channel.id.to_s).first
    next unless game.creator == event.user.id.to_s

    game.destroy

    event.channel.send_embed do |embed|
      embed.title = "Game Deleted"
      embed.description = "The current game in this channel has been deleted.\n**Anyone can start a new game.**"
      embed.color = 0xff0000

      embed.footer = Discordrb::Webhooks::EmbedFooter.new(
        text: "Game deleted by @#{event.user.username}##{event.user.discriminator}",
        icon_url: event.user.avatar_url
      )
    end

  end

  dm do |event|

    stage stage: 1, event: event, key: event.user.id.to_s do |data, key|
      data[:template] = event.message.content.downcase.strip.split ''
      data[:guessed] = event.message.content.downcase.strip.gsub(/[^\s-]/, '_').split ''

      event.user.dm.send_embed do |embed|
        embed.title = "Number of Guesses for Game"
        embed.color = 0xb412ea
        embed.description = "How many guesses will your game have?"
      end

      advance_stage key
    end

  end


  dm do |event|

    stage stage: 2, event: event, key: event.user.id.to_s do |data, key|
      next unless event.message.content.to_i > 0 # Validation

      data[:guesses] = event.message.content.to_i

      event.user.dm.send_embed do |embed|
        embed.title = "Paid Game"
        embed.color = 0xb412ea
        embed.description = "Do you want this game to be worth money (yes/no)?"
      end

      advance_stage key
    end
  end

  def self.start_game(event, data)
    data.delete :stage

    if HangmanGame.where(channel: data[:channel]).count == 0
      game = HangmanGame.new **data
      game.save

      event.bot.channel(data[:channel].to_i).send_embed do |embed|
        templateStr = data[:guessed].join(" ")

        embed.title = "New Game"
        embed.description = "Here's your new game!\n```#{templateStr}```\nYou have #{game.guesses} guesses.\n**Start guessing!**"

        if not data[:paid]
          embed.description += "\n\nThe game is worth **$#{data[:value]}.**\n**No one has paid for this game yet.**"
          puts @jeep.request user: game.creator, amount: game.value, destination: event.bot.bot_application.id.to_s, message: "Money for your hangman game."
        end

        embed.footer =  Discordrb::Webhooks::EmbedFooter.new(
          text: "Created by @#{event.user.username}##{event.user.discriminator}",
          icon_url: event.user.avatar_url
        )

      end
    else
      event.user.pm.send_embed do |embed|
        embed.title = "Error Creating Game"
        embed.description = "A game already exists in that channel."
        embed.color = 0xff0000
      end

    end

  end

  dm do |event|

    stage stage: 3, event: event, key: event.user.id.to_s do |data, key|
      if event.message.content.strip.downcase == 'no'
        data[:paid] = true

        start_game event, data

        stage_finish key
      end

      next unless event.message.content.strip.downcase == 'yes' 
      data[:paid] = false

      event.user.dm.send_embed do |embed|
        embed.title = "Game Value"
        embed.color = 0xb412ea
        embed.description = "How much should this game be worth?"
      end

      advance_stage key
    end
  end

  dm do |event|

    stage stage: 4, event: event, key: event.user.id.to_s do |data, key|
      next unless event.message.content.to_i > 0

      data[:value] = event.message.content.to_i

      start_game event, data
      stage_finish key # really dont know if this is gonna work

    end

  end

  dm do |event|
    next if event.user.id == @@config['jeep_id']

    puts event.inspect
    puts
    puts event.message.inspect


  end

  message do |event|

    next unless HangmanGame.where(channel: event.channel.id.to_s).count == 1 # Game for channel exists
    next unless event.message.content.length == 1 # Is a 1-letter guess

    game = HangmanGame.where(channel: event.channel.id.to_s).first

    next unless game[:creator] != event.user.id.to_s
    next unless game[:paid]

    guess = event.message.content.downcase

    if not game[:template].include? guess and not game[:wrong_guesses].has_key? guess
      game.guesses -= 1
      game.wrong_guesses[guess] = event.user.id.to_s
      game.save
      if game.guesses != 0
        event.channel.send_embed do |embed|
          templateStr = game.guessed.join(" ")

          embed.title = "Guess Wrong"
          embed.description = "Try again! You've guessed: \n```#{templateStr}```\nYou have #{game.guesses} guess(es) left.\nCorrect guesses: `#{game.correct_guesses.keys.join(' ')}`\nWrong guesses: `#{game.wrong_guesses.keys.join(' ')}`"
          embed.color = 0xff0000

          embed.footer =  Discordrb::Webhooks::EmbedFooter.new( # TODO: Consolidate repeated code
            text: "Guess by @#{event.user.username}##{event.user.discriminator}",
            icon_url: event.user.avatar_url
          )
        end
      else
        event.channel.send_embed do |embed|
          templateStr = game.template.join("")

          embed.title = "You Lose!"
          embed.description = "Too bad! The word was\n```#{templateStr}```\nBetter luck next time!"
          embed.color = 0xff0000
        end
        game.destroy 
      end
    end
    next unless game[:template].include? guess # Has character
    next unless not game[:correct_guesses].has_key? guess # Already guessed correctly


    guessed = game[:guessed]
    guessIndices = game[:template].each_index do |i|
      if game[:template][i] == guess
        game.guessed[i] = game[:template][i] # it... doesn't save unless I do this? Can't use a symbol, whatever I guess.
      end
    end

    game.correct_guesses[guess] = event.user.id.to_s

    game.save

    if game[:guessed] != game[:template]
      event.channel.send_embed do |embed|
        templateStr = game[:guessed].join(" ")

        embed.title = "Guess Correct"
        embed.color = 0x00ff00
        embed.description = "```#{templateStr}```\nCorrect guesses: `#{game.correct_guesses.keys.join(' ')}`\nWrong guesses: `#{game.wrong_guesses.keys.join(' ')}`"

        embed.footer = Discordrb::Webhooks::EmbedFooter.new(
          text: "Guessed by @#{event.user.username}##{event.user.discriminator}",
          icon_url: event.user.avatar_url
        )
      end
    else

      event.channel.send_embed do |embed|
        templateStr = game[:template].join("")

        embed.title = "You Win!"
        embed.color = 0x00ff00
        embed.description = "The word was\n```#{templateStr}```"

        embed.footer = Discordrb::Webhooks::EmbedFooter.new(
          text: "Won by @#{event.user.username}##{event.user.discriminator}",
          icon_url: event.user.avatar_url
        )
      end

      # Jeppy logic

      # The end
      game.destroy
    end


  end

end
