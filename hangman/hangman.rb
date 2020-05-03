require './hangman/hangmanmodel'
require 'discordrb'
require 'securerandom'


module Hangman
  extend Discordrb::EventContainer

  HELP_DATA = {
    "desc" => "Play hangman!",
    "commands" => {
      ".hangman newgame" => "Make a hangman game (channel specific)"
    }
  }
  @wizardData = {}

  message(start_with: '.hangman newgame') do |event|

    @wizardData[event.user.id.to_s] = { # TODO delete this after the wizard completes
      :creator => event.user.id.to_s,
      :channel => event.channel.id.to_s,
      :stage => 2
    }

    puts "Stage 1 #{@wizardData}"

    event.user.dm.send_embed do |embed|
      embed.title = "Welcome to the Hangman Game Creation Wizard!"
      embed.color = 0xb412ea
      embed.description = "What's the word for the game you want to create?"
    end
  end

  dm do |event|

    next unless @wizardData.has_key? event.user.id.to_s
    next unless @wizardData[event.user.id.to_s][:stage] == 2

    @wizardData[event.user.id.to_s][:template] = event.message.content.downcase.strip.split ''
    @wizardData[event.user.id.to_s][:guessed] = event.message.content.downcase.strip.gsub(/[^\s-]/, '_').split ''


    event.user.dm.send_embed do |embed|
      embed.title = "Number of Guesses for Game"
      embed.color = 0xb412ea
      embed.description = "How many guesses will your game have?"
    end

    @wizardData[event.user.id.to_s][:stage] = 3
  end

  dm do |event|

    next unless @wizardData.has_key? event.user.id.to_s
    next unless @wizardData[event.user.id.to_s][:stage] == 3
    next unless event.message.content.to_i > 0


    puts event.message.content

    @wizardData[event.user.id.to_s][:guesses] = event.message.content.to_i
    @wizardData[event.user.id.to_s].delete :stage

    if HangmanGame.where(channel: @wizardData[event.user.id.to_s][:channel]).count == 0
      game = HangmanGame.new **@wizardData[event.user.id.to_s]
      game.save

      puts "Stage 3 #{@wizardData}"

      event.bot.channel(@wizardData[event.user.id.to_s][:channel].to_i).send_embed do |embed|

        templateStr = @wizardData[event.user.id.to_s][:guessed].join(" ")

        embed.title = "New Game"
        embed.description = "Here's your new game!\n```#{templateStr}```\nYou have #{game.guesses} guesses.\n**Start guessing!**"
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

  message do |event|

    next unless HangmanGame.where(channel: event.channel.id.to_s).count == 1 # Game for channel exists
    next unless event.message.content.length == 1 # Is a 1-letter guess

    game = HangmanGame.where(channel: event.channel.id.to_s).first

    next unless game[:creator] != event.user.id.to_s

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
          templateStr = game.template.join(" ")

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
