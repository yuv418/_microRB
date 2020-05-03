require 'discordrb'

class MicroBot < Discordrb::Bot

  attr_reader :help_modules

  def initialize(token:)
    super token: token
    @help_modules = []
  end

  def include!(module_name)
    super module_name
    @help_modules << module_name
  end
end
