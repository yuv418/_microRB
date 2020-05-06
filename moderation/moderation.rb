require './moderation/moderationmodel'
require './botpatcher/dmwizardcontainer'
require 'discordrb'

module Moderation
  include EnhancedEventContainer
  extend EnhancedEventContainer

  HELP_DATA = {
    "desc" => "Add bot-enhanced moderation to your server.",
    "commands" => {
      ".adminrole" => "**Note: admin command.** Add this role as an admin.",
      ".adminrole delete <role>" => "**Note: admin command.** Delete the admin role given. Whomever was part of this admin role will no longer be an admin after deletion.",
      ".adminroles" => "Get the admin roles for this server.",
      "..kick <users> <message>" => "**Note: admin command.** Kicks a list of users (or just one) followed by a message. The message is required.",
      "..ban <users> <message>" => "**Note: admin command.** Bans a list of users (or just one) followed by a message. The message is required."
    }
  }

  message(start_with: ".adminrole") do |event|
    next unless event.message.content.match? /^.adminrole <@&\d+>/
    next unless AdminRoleModel.where(guild: event.server.id.to_s, role: event.message.role_mentions[0].id.to_s).count == 0
    next unless user_is_admin event

    newModModel = AdminRoleModel.new role: event.message.role_mentions[0].id.to_s, guild: event.server.id.to_s
    newModModel.save

    event.channel.send_embed do |embed|
      embed.title = "Admin Role Added"
      embed.description = "Admin role for #{event.message.role_mentions[0].mention} added successfully"
      embed.color = @@success
    end
  end

  message(content: ".adminroles") do |event|
    guildAdminRoles = AdminRoleModel.where(guild: event.server.id.to_s)
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

    guildAdminRoles = AdminRoleModel.where(guild: event.server.id.to_s, role: event.message.role_mentions[0].id.to_s)

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
    moderation_action(:kick, event)
  end

  message(start_with: "..ban") do |event|
    moderation_action(:ban, event)
  end


  def self.moderation_action(action, event) # Action is a symbol

    unless user_is_admin event
      event.respond "Insufficient Permissions"
      return
    end

    action_users = event.message.mentions
    action_reason = event.message.content.gsub( /(<@!\d+>+)/, '').gsub("..#{action.to_s}", '').strip

    action_message = action.to_s
    if action == :ban
      action_message = "banned"
    elsif action == :kick
      puts "here"
      action_message = "kicked"
    end

    puts action_message

    if action_reason.empty?
      event.respond "You need a valid error message."
      return
    end

    action_users.each do |action_user|

      event.bot.user(action_user.id).dm.send_embed do |embed|
        embed.title = "#{action_message.titlecase} from #{event.server.name}"
        embed.description = "Hello. You have been #{action_message} from the server #{event.server.name} for the following reason:\n**#{action_reason}**"
        embed.color = @@error
      end

      event.server.method(action).call action_user, reason: action_reason

    end

    event.channel.send_embed do |embed|
      embed.title = "#{action_message.titlecase} User(s) Successfully"
      embed.description = "Here is the list of #{action_message} users:"
      embed.color = @@success
      action_users.each_with_index do |action_user, index|
        embed.add_field name: "User #{index+1}", value: "#{action_user.mention}"
      end
    end

  end

  def self.user_is_admin(event)
    search_roles = AdminRoleModel.where(guild: event.server.id.to_s).all

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
