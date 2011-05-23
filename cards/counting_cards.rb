module CountingCards
  require 'set'
  class Card

    CARD_VALUES = (2..9).map(&:to_s).map(&:to_sym) + [:J, :Q, :K, :A]
    CARD_SUIT = [:C, :D, :S, :H]

    attr_reader :value
    attr_reader :suit

    def initialize(input)
      if input == "??"
        @suit = nil
      else
        match = input.match /([\dJQKA]+)([CDSH])/
        @value = match[1].to_sym
        @suit = match[2].to_sym
      end
    end

    def unknown?
      @suit.nil?
    end

    def ==(other)
      if self.unknown? || other.unknown?
        false
      else
        @value == other.value && @suit == other.suit
      end
    end
  end

  class Action

    ACTIONS = [:draw, :pass, :receive, :discard]

    attr_accessor :type
    attr_accessor :partner
    attr_accessor :card

    def initialize(input)
      match = input.match /([+-])([^:]+):*(\w*)/
      if match[1] == '+'
        if match[3].empty?
          @type = :draw
        else
          @type = :receive
          @partner = match[3].to_sym
        end
      else
        if match[3] == 'discard'
          @type = :discard
        else
          @type = :pass
          @partner = match[3].to_sym
        end
      end
      @card = Card.new(match[2])
    end
  end

  class Moves
    attr_accessor :player
    attr_accessor :actions

    def initialize(input)
      words = input.scan(/[^ ]+/)
      @player = words.shift.to_sym
      @actions = words.map { |w| Action.new(w) }
    end
  end

  class GameTurn

    PLAYER_NAMES = [:Rocky, :Lil, :Danny, :Shady]

    attr_accessor :players
    attr_accessor :discard_pile

    def initialize
      @players = Hash[ PLAYER_NAMES.map { |p| [p, Set.new] } ]
      @discard_pile = Set.new
    end

    def clone
      turn = GameTurn.new
      turn.discard_pile = @discard_pile.clone
      @players.each { |k,v| turn.players[k] = v.clone }
      turn
    end

    def apply_moves(moves)
      # TODO after every move check if the card *is* still on someelse's hand
      moves.actions.each do |action|
        case action.type
        when :pass
          players[moves.player].delete(action.card)
        when :receive
          players[moves.player].add(action.card)
        when :discard
          discard_pile.add(action.card)
          players[moves.player].delete(action.card)
        when :draw
          players[moves.player].add(action.card)
        end
      end
    end
  end
end

include CountingCards

require 'rubygems'
require 'ruby-debug'

game = []
turn = GameTurn.new

input_file = File.new("input.txt", "r")
first_move = true
while line = input_file.gets do
  moves = Moves.new(line.chop)
  if moves.player == :Lil
    if first_move
      first_move = false
    else
      # Read signals
      debugger
      while (line = input_file.gets) && line =~ /^\* / do
        signed_moves = Moves.new(line.chop.sub!('* ', 'Lil '))
        moves.actions.each do |action|
          action.card = signed_moves.actions.shift.card if action.card.unknown?
        end
      end
    end

    # Now we can apply the move
    turn.apply_moves(moves)

    # Make a copy for keep record of the game story
    game << turn.clone
  else
    turn.apply_moves(moves)
  end
end

debugger
a = 'test'
