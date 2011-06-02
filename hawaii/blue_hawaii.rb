require 'rubygems'
require 'json'
require 'ruby-debug'

module BlueHawaii

  # This class emulates Ruby Time class, but ignoring year
  # because we are only interested in month & day calculations
  class SeasonDate

    SECONDS_IN_A_DAY = 60 * 60 * 24

    attr_reader :time

    class << self
      def last_day_of_year
        SeasonDate.new(12, 31)
      end

      def first_day_of_year
        SeasonDate.new(1, 1)
      end

      def new_from_json(string)
        SeasonDate.new(*string.scan(/\d\d/))
      end
    end

    def initialize(month, day)
      @time = Time.local(Time.now.year, month, day)
    end

    # Return the difference between SeasonDate in days
    def -(other)
      ((@time - other.time) / SECONDS_IN_A_DAY).to_i
    end

    def next
      if last_day_of_year?
        SeasonDate.last_day_of_year
      else
        time = @time + SECONDS_IN_A_DAY
        SeasonDate.new(time.month, time.day)
      end
    end

    def <=>(other)
      @time <=> other.time
    end

    def method_missing(method, *args, &block)
      local_args = args.map { |a| a.is_a?(SeasonDate) ? a.time : a }
      return @time.send(method, *local_args, &block)
    end

    def respond_to?(symbol, include_private = false)
      super(symbol, include_private) || @time.respond_to?(symbol, include_private)
    end

    private

    def last_day_of_year?
      self.time == SeasonDate.last_day_of_year.time
    end
  end

  class Season
    attr_accessor :start
    attr_accessor :end
    attr_reader   :rate

    def initialize(input)
      if input.is_a?(Hash)
        @start   = SeasonDate.new_from_json(input['start'])
        @end     = SeasonDate.new_from_json(input['end'])
        rate_str = input['rate']
      elsif input.is_a?(String)
        @start   = SeasonDate.first_day_of_year
        @end     = SeasonDate.last_day_of_year
        rate_str = input
      elsif input.is_a?(Season)
        @start   = input.start
        @end     = input.end
        @rate    = input.rate
      end

      @rate = rate_str.scan(/\d+/).first.to_i if rate_str
    end

    def reservation_cost(reservation)
      overlap_start = [@start, reservation.start].max
      overlap_end   = [@end.next, reservation.end].min

      days = overlap_end - overlap_start
      days > 0 ? @rate * days : 0
    end
  end

  class Reservation
    attr_reader :start
    attr_reader :end

    def initialize(string)
      @start, @end = string.scan(/[\d\/]+/).map do |date|
        year, month, day = date.scan(/\d+/)
        SeasonDate.new(month, day)
      end
    end
  end

  class VacationRental

    SALES_TAX = 1.0411416

    attr_reader :name
    attr_reader :seasons
    attr_reader :cleaning_fee

    def initialize(json)
      @name = json['name']

      if json['cleaning fee']
        @cleaning_fee = json['cleaning fee'].scan(/\d+/).first.to_f
      end

      if json['seasons']
        @seasons = json['seasons'].map {|s| Season.new(s.values.first)}
        acommodate_seasons unless @seasons.empty?
      else
        @seasons = [ Season.new(json['rate']) ]
      end
    end

    def reservation_cost(reservation)
      partial_cost = @seasons.inject(0) do |cost, season|
        cost + season.reservation_cost(reservation)
      end
      (partial_cost + @cleaning_fee.to_f) * SALES_TAX
    end

    private

    # Look for the season which contains the new year day and
    # split in two different season (with the same rate price)
    def acommodate_seasons
      new_year_season = @seasons.select{|season| season.end < season.start}.first

      first_seasion = Season.new(new_year_season)
      new_year_season.end = SeasonDate.last_day_of_year

      @seasons.push(first_seasion)
    end
  end

  class Hawaii
    attr_reader :vacation_rentals
    def initialize
      file  = File.new('vacation_rentals.json', 'r')
      input = file.gets

      @vacation_rentals = JSON.parse(input).map do |rental_json|
        VacationRental.new(rental_json)
      end
    end
  end
end


include BlueHawaii

hawaii = Hawaii.new
input = File.open('input.txt', 'r')
reservation_period = input.gets
output = File.open('output.txt', 'w')
hawaii.vacation_rentals.each do |rental|
  output.puts format("#{rental.name}: $%.2f", rental.reservation_cost(Reservation.new(reservation_period)))
end
