require 'mongoid'

class Poll

  include Mongoid::Document

  MULTIPLE_CHOICE = 1
  OPEN_ENDED = 2
  VOTE = 3

  field :title, type: String
  field :description, type: String
  field :type, type: Integer # Multiple choice (1), openended (2), or vote (3)
  field :creator, type: String
  field :responses, type: Hash, default: -> {{}}
  field :channel, type: String
  field :pollid, type: String
  field :data, type: String
  field :closed, type: Boolean, default: -> {false}
  field :choices, type: Array, default: -> {[]}

end
