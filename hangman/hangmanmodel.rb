require 'mongoid'

class HangmanGame
  include Mongoid::Document

  field :template, type: Array
  field :guessed, type: Array
  field :creator, type: String
  field :channel, type: String
  field :correct_guesses, type: Hash, default: -> {{}}
  field :wrong_guesses, type: Hash, default: -> {{}}
  field :guesses, type: Integer
  field :value, type: Integer, default: -> {0}
  field :paid, type: Boolean

end
