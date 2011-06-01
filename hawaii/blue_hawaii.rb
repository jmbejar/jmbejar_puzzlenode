require 'rubygems'
require 'json'
require 'ruby-debug'

module BlueHawaii

  class SeasonDate < Time
    def initialize(month, day)
      super(Time.now.year, month, day)
    end

    def -(other_season_date)
      (super(other_season_date) / (60.0 * 60.0 * 24.0)).to_i
    end

    def +(days)
      time = super(days * 60.0 * 60.0 * 24.0)
      SeasonDate.new(time.month, time.day)
    end
  end

  class VacationRental
    attr_accessor :name
    attr_accessor :seasons
    attr_accessor :cleaning_fee

    def initialize(json)
      @name = json['name']
      @cleaning_fee = json['cleaning fee'].scan(/\d+/).first.to_f if json['cleaning fee']

      if json['seasons']
        @seasons = json['seasons'].map { |s| Season.new(s.values.first) }
        if @seasons.count > 1
          end_year_season = @seasons.select { |season| season.end < season.start }.first
          first_seasion = Season.new(end_year_season.rate.to_s)
          first_seasion.end = end_year_season.end
          end_year_season.end = SeasonDate.new(12, 30)
          @seasons.push(first_seasion)
        end
      else
        @seasons = [ Season.new(json['rate']) ]
      end
    end

    def reservation_cost(reservation)
      (@seasons.inject(0) { |cost, season| cost + season.reservation_cost(reservation) } + @cleaning_fee.to_f) * 1.0411416
    end
  end

  class Season
    attr_accessor :start
    attr_accessor :end
    attr_accessor :rate

    def initialize(json_or_rate)
      if json_or_rate.is_a?(Hash)
        @start = SeasonDate.new(*(json_or_rate['start'].scan(/\d\d/)))
        @end = SeasonDate.new(*(json_or_rate['end'].scan(/\d\d/)))
        rate_str = json_or_rate['rate']
      elsif json_or_rate.is_a?(String)
        @start = SeasonDate.new(1, 1)
        @end = SeasonDate.new(12, 30)
        rate_str = json_or_rate
      end
      @rate = rate_str.scan(/\d+/).first.to_i
    end

    def reservation_cost(reservation)
      #days = @end - @start
      #days -= reservation.start - @start if @start < reservation.start
      #days -= @end - reservation.end if reservation.end < @end
      #days = 0 if days < 0
      #puts daysy
      #@rate * days

      s = [@start, reservation.start].max
      e = [@end + 1, reservation.end].min
      days = e - s

      puts "#{@start} #{@end} #{days}"

      days > 0 ? @rate * days : 0
    end
  end

  class Reservation
    attr_reader :start
    attr_reader :end

    def initialize(string)
      @start, @end = string.scan(/\d+\/\d+\/\d+/).map do |date|
        year, month, day = date.scan(/\d+/)
        SeasonDate.new(month, day)
      end
    end
  end

  class Hawaii
    attr_reader :vacation_rentals
    def initialize
      vacation_rentals_file = File.new('vacation_rentals.json', 'r')
      @vacation_rentals = JSON.parse(vacation_rentals_file.gets).map { |rental_json| VacationRental.new(rental_json) }
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
