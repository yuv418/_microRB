require 'mongoid'
require 'discordrb'

class ModerationModel
  include Mongoid::Document

  field :role, type: String
  field :guild, type: String

end

