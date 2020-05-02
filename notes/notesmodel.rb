require 'mongoid'

class Note
  include Mongoid::Document

  field :title, type: String
  field :body, type: String
  field :type, type: String # User, channel, or server
  field :identifier, type: String # The identifier for the user, channel, or server. 
  field :user, type: String # creator's identifier
  field :uuid, type: String # For showing notes in places they aren't supposed to be. 

end
