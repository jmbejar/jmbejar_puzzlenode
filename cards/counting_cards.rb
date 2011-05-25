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

    def to_s
      value.to_s + suit.to_s
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

    def unknown_cards_count
      @actions.count{ |a| a.card.unknown? }
    end

    def clone
      moves = Moves.new "#{@player}"
      moves.actions = @actions.map(&:clone)
      moves
    end
  end

  class GameTurn

    PLAYER_NAMES = [:Rocky, :Lil, :Danny, :Shady]

    attr_accessor :players
    attr_accessor :discard_pile

    def initialize
      @players = Hash[ PLAYER_NAMES.map { |p| [p, []] } ]
      @discard_pile = []
    end

    def clone
      turn = GameTurn.new
      turn.discard_pile = @discard_pile.map(&:clone)
      @players.each { |k,v| turn.players[k] = v.clone }
      turn
    end

    def apply_moves(moves)
      # TODO after every move check if the card *is* still on someelse's hand
      moves.actions.each do |action|
        raise "The card #{action.card} is in the discard pile, player #{moves.player}" if !action.card.unknown? && discard_pile.include?(action.card)
        case action.type
        when :pass
          raise "The player #{moves.player} is trying to pass the card #{action.card} " unless action.card.unknown? || players[moves.player].include?(action.card)
          players[moves.player].delete(action.card)
        when :receive
          raise "The sender player, #{action.partner}, has not the given card #{action.card}" unless action.card.unknown? || players[action.partner].include?(action.card)
          players[moves.player] << action.card
        when :discard
          raise "The player #{moves.player} is trying to discard the card #{action.card}" unless players[moves.player].include?(action.card)
          discard_pile << action.card
          players[moves.player].delete(action.card)
        when :draw
          players[moves.player] << action.card
        end
      end
    end
  end
end

include CountingCards

require 'rubygems'
require 'ruby-debug'

games = [[]]
initial_turn = GameTurn.new

input_file = File.new("input2.txt", "r")
first_move = true
while line = input_file.gets do
  moves = Moves.new(line.chop)
  if moves.player == :Lil
    if first_move
      first_move = false
      initial_turn.apply_moves(moves)
      games.first << initial_turn
    else
      new_games = []
      games.each do |game|
        turn = game.last

        # Read signals
        signed_moves_set = []
        while (line = input_file.gets) && line =~ /^\* / do
          signed_moves_set << Moves.new(line.chop.sub!('* ', 'Lil '))
        end

        # Remove invalid signals
        signed_moves_set.delete_if { |m| m.actions.count != moves.unknown_cards_count }

        success = 0
        signed_moves_set.each do |signed|
          turn_backup = turn.clone
          moves_backup = moves.clone
          begin
            moves.actions.each do |action|
              if action.card.unknown?
                if action.type != signed.actions.first.type
                  raise "The action is not the expected ( #{action.type} but expected #{signed.actions.first.type} )"
                elsif ((action.type == :receive || action.type == :pass) && action.partner != signed.actions.first.partner)
                  raise "The other player is not the correct ( #{action.partner} but expected #{signed.actions.first.partner} )"
                end
                action.card = signed.actions.shift.card
              end
            end
            turn.apply_moves(moves)
            success = success.succ
            if success == 1
              game << turn.clone
            else
              new_game = game.map(&:clone)
              new_game.pop
              new_game << turn.clone
              new_games << new_game
            end
          rescue
            puts $!
          ensure
            turn = turn_backup
            moves = moves_backup
          end
        end
      end
      games = games + new_games
    end
  else
    if first_move
      initial_turn.apply_moves(moves)
    else
      games.each do |game|
        game.last.apply_moves(moves)
      end
    end
  end
end

games.each do |game|
  puts ">>>>>>>>>>>"
  game.each do |turn|
    puts turn.players[:Lil].map(&:to_s).join(" ")
  end
end

