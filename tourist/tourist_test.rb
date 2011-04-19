require 'rubygems'
gem 'minitest'
require 'minitest/autorun'

require 'tourist'

class TestTourist < MiniTest::Unit::TestCase
  include Tourist

  def test_reading_input_file_lines
    cities = {}
    ('A'..'C').each { |c| cities[c] = City.new(c) }
    data = "A B 12:00 13:00 100.0"
    process_line(data.split, cities)
    assert_equal cities['A'].flights.count, 1
    flight = cities['A'].flights.first
    assert_equal flight.price, 100.0
    assert_equal flight.to, cities['B']
    assert_equal flight.departure.strftime('%H:%M'), '12:00'
    assert_equal flight.arrive.strftime('%H:%M'), '13:00'
  end

  def test_calculate_when_exists_only_one_path
    cities = {}
    ('A'..'Z').each { |c| cities[c] = City.new(c) }
    data = "A B 12:00 13:00 100.0"
    process_line(data.split, cities)
    data = "B C 16:00 17:00 100.0"
    process_line(data.split, cities)
    data = "C Z 18:00 20:00 100.0"
    process_line(data.split, cities)

    paths_steve = calculate_valid_paths(cities['A'], cities['Z'], make_time(0,0), StevePath, true)
    paths_jennifer = calculate_valid_paths(cities['A'], cities['Z'], make_time(0,0), JenniferPath, true)

    [paths_jennifer, paths_steve].each do |paths|
      assert_equal paths.count, 1
      assert_equal paths.first.departure.strftime('%H:%M'), '12:00'
      assert_equal paths.first.arrive.strftime('%H:%M'), '20:00'
      assert_equal paths.first.price, 300.0
    end
  end

  def test_calculate_with_different_paths_according_criteria
    cities = {}
    ('A'..'Z').each { |c| cities[c] = City.new(c) }
    data = "A B 12:00 13:00 100.0"
    process_line(data.split, cities)
    data = "B C 16:00 17:00 100.0"
    process_line(data.split, cities)
    data = "C Z 18:00 20:00 100.0"
    process_line(data.split, cities)
    data = "B Z 14:00 14:30 2000.0"
    process_line(data.split, cities)

    paths_steve = calculate_valid_paths(cities['A'], cities['Z'], make_time(0,0), StevePath, true)
    paths_jennifer = calculate_valid_paths(cities['A'], cities['Z'], make_time(0,0), JenniferPath, true)

    assert_equal paths_steve.count, 2
    assert_equal paths_jennifer.count, 2

    assert_equal solution_output(StevePath, cities), "12:00 20:00 300.00"
    assert_equal solution_output(JenniferPath, cities), "12:00 14:30 2100.00"
  end
end
