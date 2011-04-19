require 'spelling'
include Spelling

spelling_suggestions = SpellingSuggestions.new
input = File.open('input', 'r')
output = File.open('output', 'w')
cases = input.gets.to_i
cases.times do
  input.gets
  provided_word = input.gets.gsub("\n", "")
  2.times { spelling_suggestions.add_word_to_dictionary input.gets.gsub("\n", "") }
  output.puts spelling_suggestions.suggestion_for(provided_word)
end
