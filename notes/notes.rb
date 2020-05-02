require 'discordrb'
require 'securerandom'
require './notes/notesmodel.rb'

module Notes
  extend Discordrb::EventContainer

  @wizardData = {}

  message(content: '.notecreate') do |event|
    @wizardData[event.message.id.to_s] = {
      :uuid => SecureRandom.uuid,
      :type => (event.channel.private?) ? "dm" : "channel",
      :identifier => event.channel.id.to_s,
    }
    event.channel.send_embed do |embed|
      embed.title = "Welcome to the Note Creation Wizard!"
      embed.color = 0xb412ea
      embed.description = "To get started, what is the **title** of your note?\nPlease respond with `.notetitle #{event.message.id} <title>`."
    end
  end

  message(start_with: '.notetitle') do |event|
    splitcmd = event.message.content.split(" ")
    wizardId = splitcmd[1]
    title = splitcmd[2..].join(" ")

    if not @wizardData.has_key? wizardId
      event.channel.send_embed do |embed|
        embed.title = "Error: Invalid Wizard Key"
        embed.color = 0xff0000
        embed.description = "Please use a valid key"
      end
    end

    puts @wizardData.has_key? wizardId

    next if not @wizardData.has_key? wizardId
    @wizardData[wizardId][:title] = title

    event.channel.send_embed do |embed|
      embed.title = "Creating Note '#{title}'"
      embed.color = 0xb412ea
      embed.description = "Great! What is the **content** of your note?\nPlease respond with `.notecontent #{wizardId} <content>`."
    end
  end

  message(start_with: '.notecontent') do |event|
    splitcmd = event.message.content.split(" ")
    wizardId = splitcmd[1]
    body = splitcmd[2..].join(" ")

    if not @wizardData.has_key? wizardId
      event.channel.send_embed do |embed|
        embed.title = "Error: Invalid Wizard Key"
        embed.color = 0xff0000
        embed.description = "Please use a valid key"
      end
    end

    next if not @wizardData.has_key? wizardId
    @wizardData[wizardId][:body] = body

    newNote = Note.new **@wizardData[wizardId]
    newNote.save

    event.channel.send_embed do |embed|
      embed.title = "Created Note '#{@wizardData[wizardId][:title]}'"
      embed.color = 0xb412ea
      embed.description = "Successfully created note with body\n```#{body}```"
    end


  end

  message(start_with: ".noteget") do |event|
    notes = Note.where(identifier: event.channel.id.to_s)
    event.channel.send_embed do |embed|
      embed.title = (event.channel.private?) ? "My Notes" : "Channel Notes"
      notes.each.with_index do |note, index|
        embed.add_field name: "#{index+1}. #{note.title}", value: "```#{note.body}```"
      end
    end
  end

  message(start_with: ".notedelete") do |event|
    notes = Note.where(identifier: event.channel.id.to_s)
    begin
      index = Integer(event.message.content.split(" ")[1]) - 1


      if notes[index]
        event.channel.send_embed do |embed|
          embed.title = "Deleted Note #{notes[index].title}!"
          embed.description = "Should you want it, the content of your note was\n```#{notes[index].body}```"
          embed.color = 0x00ef9ee
        end
        notes[index].destroy
      else
        raise "Invalid Note Index"
      end
    rescue
      event.channel.send_embed do |embed|
        embed.title = "Error: Invalid Note Index"
        embed.description = "Sorry, the index you provided for the note was invalid"
        embed.color = 0xff0000
      end
    end




  end




end
