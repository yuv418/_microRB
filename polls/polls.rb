# coding: utf-8
require 'discordrb'
require './polls/pollsmodel.rb'

module Polls
  extend Discordrb::EventContainer # TODO make custom container with colors and other cool thing we will need

  HELP_DATA = {
    "desc"=> "Make multiple choice, open-ended, or vote polls.",
    "commands"=> {
      ".poll"=> "Make a poll in the current channel."
    }
  }


  @pollColor = 0x329efc
  @error = 0xff0000
  @success = 0x00ff00
  @wizardData = {}
  @collectionData = {}

  message(content: ".poll") do |event|
    @wizardData[event.user.id.to_s] = {
      :creator => event.user.id.to_s,
      :channel => event.channel.id.to_s,
      :stage => 2
    }

    event.user.dm.send_embed do |embed|
      embed.title = "Welcome to the New Poll Wizard!"
      embed.description = "What do you want the title of your poll to be?"
      embed.color = @pollColor
    end

  end

  dm do |event| # Stage 2: title
    next unless @wizardData.has_key? event.user.id.to_s
    next unless @wizardData[event.user.id.to_s][:stage] == 2

    @wizardData[event.user.id.to_s][:title] = event.message.content.strip
    puts "Stage 2 #{@wizardData}"

    event.user.dm.send_embed do |embed|
      embed.title = "Description for Poll `#{@wizardData[event.user.id.to_s][:title]}`"
      embed.description = "What do you want the description of your poll to be?"
      embed.color = @success
    end

    @wizardData[event.user.id.to_s][:stage] = 3 # Maybe solve async issues please 

  end

  dm do |event|
    next unless @wizardData.has_key? event.user.id.to_s
    next unless @wizardData[event.user.id.to_s][:stage] == 3

    @wizardData[event.user.id.to_s][:description] = event.message.content.strip

    puts "Stage 3 #{@wizardData}"

    event.user.dm.send_embed do |embed|
      embed.title = "Poll Type for Poll `#{@wizardData[event.user.id.to_s][:title]}`"
      embed.description = "Multiple-choice `1`, open-ended `2`, or vote `3`?"
      embed.color = @success
    end

    @wizardData[event.user.id.to_s][:stage] = 4
  end

  dm do |event|
    next unless @wizardData.has_key? event.user.id.to_s
    next unless @wizardData[event.user.id.to_s][:stage] == 4
    next unless event.message.content.strip.to_i > 0 and event.message.content.strip.to_i < 4

    @wizardData[event.user.id.to_s][:type] = event.message.content.strip.to_i

    puts "Stage 4 #{@wizardData[event.user.id.to_s]}"


    if @wizardData[event.user.id.to_s][:type] == Poll::MULTIPLE_CHOICE
      event.user.dm.send_embed do |embed|
        embed.title = "Poll Choices for Poll `#{@wizardData[event.user.id.to_s][:title]}`"
        embed.description = 'Enter your choices in this specific format:' + "\n" + '`"Choice 1" "Choice 2" "Choice 3"`' + "\n" + '**Make sure you have quotes and everything and if you don\'t follow this format, your poll might not work!**'
        embed.color = @success
      end
      @wizardData[event.user.id.to_s][:stage] = 5
    end

    next unless @wizardData[event.user.id.to_s][:type] != Poll::MULTIPLE_CHOICE

    @wizardData[event.user.id.to_s].delete :stage
    newPoll = Poll.new **@wizardData[event.user.id.to_s]


    pollEmbed = event.bot.channel(newPoll.channel).send_embed do |embed|
      embed.title = "Poll `#{newPoll.title}`"
      embed.description = "Description: #{newPoll.description}"

      case newPoll.type
      when Poll::MULTIPLE_CHOICE
        embed.description += "\n**This is a multiple choice poll. React to the :arrow_right_hook: emoji to respond.**"
      when Poll::OPEN_ENDED
        embed.description += "\n**This is an open ended poll. React to the :arrow_right_hook: emoji to respond.**"
      when Poll::VOTE
        embed.description += "\n**This is vote poll. React with :thumbsup: and :thumbsdown: to respond.**"
      end
      embed.description += "\n**Poll creators, you can close the poll by reacting to :key:.**"
      embed.footer = Discordrb::Webhooks::EmbedFooter.new(
        text: "Poll Created by @#{event.user.username}##{event.user.discriminator}",
        icon_url: event.user.avatar_url
      )
#      embed.add_field name: "No responses yet", value: "Be the first to respond!"

    end

    case newPoll.type
    when Poll::VOTE
      pollEmbed.react "👍"
      pollEmbed.react "👎"
      pollEmbed.react "🔑" # KEY icon
    else
      pollEmbed.react "↪" # Seriously?
      pollEmbed.react "🔑" # KEY icon
    end


    newPoll.pollid = pollEmbed.id.to_s
    newPoll.save # Yes you can have more than one poll

    @wizardData.delete event.user.id.to_s


  end

  dm do |event|
    next unless @wizardData.has_key? event.user.id.to_s
    next unless @wizardData[event.user.id.to_s][:stage] == 5

    data = event.message.content.strip
    @wizardData[event.user.id.to_s][:choices] = data.split('"').select{ |val| val.strip != '' }
    @wizardData[event.user.id.to_s].delete :stage

    newPoll = Poll.new **@wizardData[event.user.id.to_s]


    puts "Stage 5 #{newPoll.inspect}"

    pollEmbed = event.bot.channel(newPoll.channel).send_embed do |embed|
      embed.title = "Poll `#{newPoll.title}`"
      embed.description = "Description: #{newPoll.description}"
      embed.description += "\n**This is a multiple choice poll. React to the :arrow_right_hook: emoji to respond.**"
      embed.description += "\n**Poll creators, you can close the poll by reacting to :key:.**"
      embed.footer = Discordrb::Webhooks::EmbedFooter.new(
        text: "Poll Created by @#{event.user.username}##{event.user.discriminator}",
        icon_url: event.user.avatar_url
      )

      newPoll.choices.each_with_index do |choice, i|
        embed.add_field name: "Choice #{i+1}", value: choice
      end
#      embed.add_field name: "No responses yet", value: "Be the first to respond!"

    end

    pollEmbed.react "↪" # Seriously?
    pollEmbed.react "🔑" # KEY icon

    newPoll.pollid = pollEmbed.id.to_s
    newPoll.save # Yes you can have more than one poll

    @wizardData.delete event.user.id.to_s

  end

  reaction_add(emoji: "↪") do |event|

    next unless Poll.where(pollid: event.message.id.to_s).count == 1

    poll = Poll.where(pollid: event.message.id.to_s).first
    puts poll.attributes
    next unless not poll.closed
    puts "here"

    @collectionData[event.user.id.to_s] = {
      :pollid => poll.pollid
    }

    event.user.dm.send_embed do |embed|
      embed.title = "Poll `#{poll.title}`"
      embed.description = "Poll description: #{poll.description}"

      case poll.type
      when Poll::OPEN_ENDED
        embed.description += "\n**What is your answer?**"
      when Poll::MULTIPLE_CHOICE
        embed.description += "\n**Choose a choice based on the numbers next to the choices below.**"
        poll.choices.each_with_index do |choice, i|
          embed.add_field name: "Choice #{i+1}", value: choice
        end

      end



    end

  end

  reaction_add(emoji: "🔑") do |event|
    next unless Poll.where(pollid: event.message.id.to_s).count == 1

    poll = Poll.where(pollid: event.message.id.to_s).first

    next unless event.user.id.to_s == poll.creator

    poll_message = event.bot.channel(poll.channel).load_message(poll.pollid) # kinda unecessary here


    embed = poll_message.embeds[0]

#    embed.color = @error
    embed_out = embed_convert_push_field embed, nil, nil, false, "Description: #{poll.description}\n**The poll is closed**", @error

    puts embed_out.inspect
    poll_message.edit '', embed_out

    poll.closed = true
    poll.save



  end

  dm do |event|
    next unless @collectionData.has_key? event.user.id.to_s

    poll = Poll.where(pollid: @collectionData[event.user.id.to_s][:pollid]).first

    next unless poll.type != Poll::VOTE

    poll_message = nil
    embed_out = nil

    if poll.type == Poll::OPEN_ENDED
      response = event.message.content.strip

      poll.responses[event.user.id.to_s] = response
      poll.save

      poll_message = event.bot.channel(poll.channel).load_message(poll.pollid)
      embed = poll_message.embeds[0]

      puts embed.inspect

      embed_out = embed_convert_push_field embed, "#{event.user.username}##{event.user.discriminator}", response, true
    elsif poll.type == Poll::MULTIPLE_CHOICE
      response = event.message.content.strip.to_i

      poll.responses[event.user.id.to_s] = response - 1
      poll.save

      occurrences = poll.responses.values.inject(Hash.new(0)) { |h,v| h[v] += 1; h } # try to undrestand this later pls
      puts occurrences

      poll_message = event.bot.channel(poll.channel).load_message(poll.pollid)
      embed = poll_message.embeds[0]

      embed.fields.each_with_index do |field, index|
        embed.fields[index] = Discordrb::EmbedField.new({'name' => "Choice #{index+1}: <#{occurrences[index]} selections>", 'value' => embed.fields[index].value}, embed)
      end

      embed_out = embed_convert_push_field embed, nil, nil, false
    end


    #    poll.save

    puts embed_out.inspect

    poll_message.edit '', embed_out


    puts poll.inspect

    @collectionData.delete event.user.id.to_s

    event.user.dm.send_embed do |embed|
      embed.title = "Success"
      embed.description = "Thanks for your response. \n**The poll has been updated and you can see it in the channel with the poll.**"
      embed.color = @success
    end


  end

  def self.embed_convert_push_field(embed_in, name, value, inline, description=nil, color=nil)
    embed_out = Discordrb::Webhooks::Embed.new(
      title: embed_in.title,
      description: description ? description : embed_in.description,
      colour: color ? color : embed_in.colour,
      footer: Discordrb::Webhooks::EmbedFooter.new(
        text: embed_in.footer.text,
        icon_url: embed_in.footer.icon_url
      )
    )

    name_pre_exist = false

    if embed_in.fields
      embed_in.fields.each do |field|
        if not name == field.name
          embed_out.add_field name: field.name, value: field.value, inline: field.inline
        else
          embed_out.add_field name: name, value: value, inline: inline
        end

        name_pre_exist = name == field.name
      end
    end

    if (not name_pre_exist) and (name and value)
      puts 'here'
      embed_out.add_field name: name, value: value, inline: inline
    end

    embed_out
  end

end
