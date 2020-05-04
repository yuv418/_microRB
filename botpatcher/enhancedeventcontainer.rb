require 'discordrb'

module EnhancedEventContainer
  include Discordrb::EventContainer

  @error = 0xff0000
  @success = 0x00ff00
  @@config = JSON.parse(File.read './config.json')


end

