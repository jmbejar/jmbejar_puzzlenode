require 'tourist'
include Tourist

input = File.new("input", "r")
output = File.new("output", "w")
cases = input.gets.to_i
cases.times do |i|
  cities = {}
  ('A'..'Z').each { |c| cities[c] = City.new(c) }

  input.gets # blank line
  lines = input.gets.to_i
  lines.times do
    line = input.gets.split
    process_line(line, cities)
  end

  [StevePath, JenniferPath].each { |path_type| output.puts solution_output(path_type, cities) }
  output.puts unless cases == i + 1
end
input.close
output.close
