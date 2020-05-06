require 'mongoid'
require 'discordrb'

class AdminRoleModel
  include Mongoid::Document

  field :role, type: String
  field :guild, type: String

end

