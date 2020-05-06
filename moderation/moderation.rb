require './moderation/moderationmodel'
require './botpatcher/dmwizardcontainer'
require 'discordrb'

module Moderation
  include EnhancedEventContainer
  extend EnhancedEventContainer

  HELP_DATA = {
    "desc" => "Add bot-enhanced moderation to your server.",
    "commands" => {
      ".adminrole" => "Add this role as an admin.",
      ".adminrole delete <role>" => "Delete the admin role given. Whomever was part of this admin role will no longer be an admin after deletion.",
      ".adminroles" => "Get the admin roles for this server.",
      "..kick <users> <message>" => "**Note: admin command.** Kicks a list of users (or just one) followed by a message. The message is required."
    }
  }

  message(start_with: ".adminrole") do |event|
    next unless event.message.content.match? /^.adminrole <@&\d+>/
    next unless ModerationModel.where(guild: event.server.id.to_s, role: event.message.role_mentions[0].id.to_s).count == 0
    next unless user_is_admin event

    newModModel = ModerationModel.new role: event.message.role_mentions[0].id.to_s, guild: event.server.id.to_s
    newModModel.save

    event.channel.send_embed do |embed|
      embed.title = "Admin Role Added"
      embed.description = "Admin role for #{event.message.role_mentions[0].mention} added successfully"
      embed.color = @@success
    end
  end

  message(content: ".adminroles") do |event|
    guildAdminRoles = ModerationModel.where(guild: event.server.id.to_s)
    next unless guildAdminRoles.count > 0

    event.channel.send_embed do |embed|
      embed.title = "Admin Roles"
      embed.description = "People with this role can perform administrative tasks on this server, like kicking and banning, provided that the bot has permissions to do these things in the first place."
      guildAdminRoles.each_with_index do |role, index|
        embed.add_field name: "Role #{index+1}", value: event.server.role(role.role.to_i).mention
      end
    end
  end

  message(start_with: ".adminrole delete") do |event|
    next unless user_is_admin event

    guildAdminRoles = ModerationModel.where(guild: event.server.id.to_s, role: event.message.role_mentions[0].id.to_s)

    if guildAdminRoles.count == 0
      event.channel.send_embed do |embed|
        embed.title = "Error Deleting Admin Role"
        embed.color = @@error
        embed.description = "The admin role #{event.message.role_mentions[0].mention} does not exist."
      end

    end

    next unless guildAdminRoles.count > 0

    guildAdminRoles.each { |role| role.destroy }

    event.channel.send_embed do |embed|
      embed.title = "Deleted Admin Role"
      embed.color = @@success
      embed.description = "The admin role #{event.message.role_mentions[0].mention} was deleted."
    end


  end

  message(start_with: "..kick") do |event|
    next unless user_is_admin event

    kick_users = event.message.mentions
    kick_message = event.message.content.gsub( /(<@!\d+>+)/, '').gsub('..kick', '').strip

    next unless kick_message

    kick_users.each do |kick_user|


      event.bot.user(kick_user.id).dm.send_embed do |embed|
        embed.title = "Kicked from #{event.server.name}"
        embed.description = "Hello. You have been kicked from the server #{event.server.name} for the following reason:\n**#{kick_message}**"
        embed.color = @@error
      end

      event.server.kick kick_user, kick_message

    end

    event.channel.send_embed do |embed|
      embed.title = "Kicked User(s) Successfully"
      embed.description = "Here is the list of kicked users:"
      embed.color = @@success
      kick_users.each_with_index do |kick_user, index|
        embed.add_field name: "User #{index+1}", value: "#{kick_user.mention}"
      end
    end

  end

  def self.user_is_admin(event)
    search_roles = ModerationModel.where(guild: event.server.id.to_s).all

    found = false

    search_roles.each do |role|
      found = event.user.role? role.role
    end

    if not found
      found = event.user.owner?
    end

    found
  end




end
