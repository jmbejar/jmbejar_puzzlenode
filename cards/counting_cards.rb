module CountingCards
  require 'set'
  class Card

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

    attr_accessor :passes

    def initialize
      @players = Hash[ PLAYER_NAMES.map { |p| [p, []] } ]
      @discard_pile = []
      @passes = []
    end

    def clone
      turn = GameTurn.new
      turn.discard_pile = @discard_pile.map(&:clone)
      @players.each { |k,v| turn.players[k] = v.clone }
      @passes.each { |a| turn.passes << [a[0], a[1], a[2].clone]}
      turn
    end

    def apply_moves(moves)
      # TODO after every move check if the card *is* still on someelse's hand
      moves.actions.each do |action|
        raise "The card #{action.card} is in the discard pile, player #{moves.player}" if !action.card.unknown? && discard_pile.include?(action.card)
        case action.type
        when :pass
          raise "The player #{moves.player} is trying to pass the card #{action.card} " unless action.card.unknown? || players[moves.player].count { |c| c.unknown? } > 0 || players[moves.player].include?(action.card)
          raise "pass dsfdsf #{action.card}" if !action.card.unknown? && players.reject{ |k,v| k == moves.player }.values.flatten.include?(action.card)
          @passes << [moves.player, action.partner, action.card]
          players[moves.player].delete(action.card)
        when :receive
          raise "The sender player, #{action.partner}, has not the given card #{action.card}" unless action.card.unknown? || players[action.partner].count { |c| c.unknown? } > 0 || players[action.partner].include?(action.card) || @passes.include?([action.partner, moves.player, action.card])
          raise "receive dsfdsf #{action.card}" if !action.card.unknown? && players.reject{ |k,v| k == action.partner }.values.flatten.include?(action.card)
          players[moves.player] << action.card
          @passes.delete([action.partner, moves.player, action.card])
          #players[action.partner].delete(action.card)
        when :discard
          raise "The player #{moves.player} is trying to discard the card #{action.card}" unless players[moves.player].count { |c| c.unknown? } > 0 || players[moves.player].include?(action.card)
          discard_pile << action.card
          players[moves.player].delete(action.card)
        when :draw
          raise "The card drawn #{action.card} is already in the hand #{moves.player}" if !action.card.unknown? && players[moves.player].include?(action.card)
          raise "asdsadas #{action.card}" if !action.card.unknown? && players.values.flatten.include?(action.card)
          players[moves.player] << action.card
        end
      end
    end
  end
end

include CountingCards

require 'rubygems'
require 'ruby-debug'

def hhh
  
end

games = [[]]
initial_turn = GameTurn.new

input_file = File.new("input.txt", "r")
first_move = true
line = nil
while line || line = input_file.gets do

  #puts "::::::" + line

  games_to_delete = []
  moves = Moves.new(line.chop)
  if moves.player == :Lil
    if first_move
      first_move = false
      initial_turn.apply_moves(moves)
      games.first << initial_turn
      #games.first << initial_turn.clone
      line = nil
    else
      # Read signals
      signed_moves_set = []
      while (line = input_file.gets) && line =~ /^\* / do
        puts "???????" + line
        signed_moves_set << Moves.new(line.chop.sub!('* ', 'Lil '))
      end

      # Remove invalid signals
      signed_moves_set.delete_if { |m| m.actions.count != moves.unknown_cards_count }

      new_games = []
      games.each do |game|
        turn = game.last

        success = 0
        signed_moves_set.map(&:clone).each do |signed|
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
            turn_backup.apply_moves(moves)
            success = success.succ
            if success == 1
              game << turn_backup
            else
              new_game = game.map(&:clone)
              new_game.pop
              new_game << turn_backup
              new_games << new_game
            end
          rescue
            puts $!.to_s + " {{ #{moves.player} }}"
          ensure
            #turn = turn_backup
            moves = moves_backup
          end
        end
        games_to_delete << game if success == 0
      end
      games = games + new_games
    end

  else
    if first_move
      initial_turn.apply_moves(moves)
    else
      games.each do |game|
        begin
          game.last.apply_moves(moves)
        rescue
          puts $!.to_s + " {{ #{moves.player} }}"
          games_to_delete << game
        end
      end
    end
    line = nil
  end
  # debugger unless games_to_delete.empty?
  games = games - games_to_delete
end

games.each do |game|
  puts ">>>>>>>>>>>"
  game.each do |turn|
    puts turn.players[:Lil].map(&:to_s).join(" ")
  end
end

output = File.open('output.txt', 'w')
games.first.each do |turn|
  output.puts turn.players[:Lil].map(&:to_s).join(" ")
end
output.close

