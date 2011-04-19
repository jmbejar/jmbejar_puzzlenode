module Tourist

  # Constants

  INFINITY = 1.0 / 0
  BASE_TIME = Time.utc(2011,1,1)

  # Classes

  class Flight
    attr_accessor :to
    attr_accessor :departure
    attr_accessor :arrive
    attr_accessor :price

    def initialize(to, departure, arrive, price)
      @to = to
      @departure = departure
      @arrive = arrive
      @price = price
    end
  end

  class City
    attr_accessor :name
    attr_accessor :flights

    def initialize(name)
      @name = name
      @flights = []
    end

    def add_flight(to, departure, arrive, price)
      flight = Flight.new(to, departure, arrive, price)
      @flights << flight
    end
  end

  class Path
    attr_accessor :departure
    attr_accessor :arrive
    attr_accessor :price

    def initialize(departure, arrive, price, log)
      @departure = departure
      @arrive = arrive
      @price = price
    end
  end

  class JenniferPath < Path
    def cost
      @arrive - @departure
    end

    def <=>(other)
      cost == other.cost ? @price <=> other.price : cost <=> other.cost
    end
  end

  class StevePath < Path
    def cost
      @price
    end

    def <=>(other)
      price <=> other.price
    end
  end

  # Global functions

  def make_time(hour, minutes)
    BASE_TIME + 60 * 60 * hour + 60 * minutes
  end

  def calculate_valid_paths(from, to, current_time, path_type, first = false)
    paths = []
    from.flights.each do |f|
      if f.departure >= current_time
        if f.to == to
          paths << path_type.send(:new, first ? f.departure : current_time, f.arrive, f.price, f.to_s)
        else
          local_paths = calculate_valid_paths(f.to, to, f.arrive, path_type)
          local_paths.each do |p|
            p.price += f.price
            p.departure = first ? f.departure : current_time
          end
          paths += local_paths
        end
      end
    end
    paths
  end

  def process_line(data, cities)
    departure_str = data[2].split(':')
    departure = make_time(departure_str[0].to_i, departure_str[1].to_i)
    arrive_str = data[3].split(':')
    arrive = make_time(arrive_str[0].to_i, arrive_str[1].to_i)
    cities[data[0]].add_flight(cities[data[1]], departure, arrive, data[4].to_f)
  end

  def solution_output(path_type, cities)
    valid_paths = calculate_valid_paths(cities['A'], cities['Z'], make_time(0,0), path_type, true)
    sorted_valid_paths = valid_paths.sort { |x,y| x <=> y }
    solution = sorted_valid_paths.first
    format("#{solution.departure.strftime('%H:%M')} #{solution.arrive.strftime('%H:%M')} %.2f", solution.price)
  end
end
