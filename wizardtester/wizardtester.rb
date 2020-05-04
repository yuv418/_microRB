require 'discordrb'
require './botpatcher/dmwizardcontainer'

module WizardTester
  extend DMWizardContainer
  include DMWizardContainer

  HELP_DATA = {
    "desc" => "To test DMWizardContainer",
    "commands" => {
      ".test2" => "returns `limes pongo`"
    }
  }

  message(contains: '.test2') do |event|
    next unless stage_create event.user.id.to_s
    event.user.dm 'lemon or lime?'
  end

  dm do |event|
    stage stage: 1, event: event, key: event.user.id.to_s do |data, key|
      puts event
      data[:choice] = event.message.content.strip
      event.user.dm 'green or blue?'

      advance_stage key
    end
  end

  dm do |event|
    stage stage: 2, event: event, key: event.user.id.to_s do |data, key|
      data[:color_choice] = event.message.content.strip
      event.user.dm 'ok great thx'


      stage_finish key
    end
  end


end
