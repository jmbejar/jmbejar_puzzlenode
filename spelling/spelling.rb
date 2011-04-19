module Spelling
  class CommonCharSecuences

    attr_reader :word1
    attr_reader :word2

    def initialize(word1, word2)
      @word1 = word1
      @word2 = word2
    end

    def longest_common_char_secuence
      @longest_common_char_secuence ||= calculate_longest_common_char_secuence
    end

    private

    def calculate_longest_common_char_secuence
      # We will use this instance variable as an early stopping condition, to reduce the computing time as much as possible for very long words
      @lenght_reached = 0;
      longest_common_char_secuence_recursive(@word1, @word2, 0)
    end

    def longest_common_char_secuence_recursive(word1, word2, matches)
      if word1.empty? || word2.empty?
        ''
      elsif (word1.length + matches < @lenght_reached) || (word2.length + matches < @lenght_reached)
        # Note that it does not mean the solution is actually an empty secuence for the params in this recursion,
        # but at this point we know this is not a valid backtrack for the original terms
        ''
      else
        letter1 = word1[0..0]
        letter2 = word2[0..0]
        if letter1 != letter2
          # Strings start with different letters
          # Let's say the words are aXXXbX and bYYaYY, we will calculate three candidates in the following lines
          candidates = []

          # 1) First, try removing the first letter from the first word, and calculate with the longest substring starting with this letter from the second string
          # candidate1 = common_secuence (XXXX, YY)
          new_word2 = word2[Regexp.new("#{letter1}(.*)")]
          if new_word2
            candidates << longest_common_char_secuence_recursive(word1, new_word2, matches)
          end

          # 2) Then, try removing the first letter from the second word, and calculate with the longest substring starting with this letter from the first string
          # candidate2 = common_secuence (X, YYYY)
          new_word1 = word1[Regexp.new("#{letter2}(.*)")]
          if new_word1
            candidates << longest_common_char_secuence_recursive(new_word1, word2, matches)
          end

          # 3) Finally, try removing the first letter from both words
          # candidate3 = common_secuence (XXXX, YYYY)
          new_word1 = word1[1..word1.length-1]
          new_word2 = word2[1..word2.length-1]
          candidates << longest_common_char_secuence_recursive(new_word1, new_word2, matches)

          # The longest candidate is the best solution
          result = candidates.sort { |x,y| x.length <=> y.length }.last
        else
          # If both strings start with the same letter, let's include it to the common secuence and calculate with the tail of each word
          # common_secuence (aXXXX , aYYYY) => a + common_secuence (XXXX, YYYY)
          new_word1 = word1[1..word1.length-1]
          new_word2 = word2[1..word2.length-1]
          result = letter1 + longest_common_char_secuence_recursive(new_word1, new_word2, matches + 1)
        end

        # Updating the stopping condition variable in order to save unnecessary recursive calls
        if @lenght_reached < result.length
          @lenght_reached = result.length
        end

        result
      end
    end
  end

  class Dictionary
    attr_reader :words

    def initialize
      @words = []
    end

    def add_word(word)
      @words << word
    end
  end

  class SpellingSuggestions
    def initialize
      @dictionary = Dictionary.new
    end

    def add_word_to_dictionary(word)
      @dictionary.add_word(word)
    end

    def suggestion_for(provided_word)
      longest_common_substring_for_words = {}
      @dictionary.words.each do |word|
        CommonCharSecuences.new(word, provided_word).longest_common_char_secuence
        longest_common_substring_for_words[word] = CommonCharSecuences.new(word, provided_word).longest_common_char_secuence
      end
      (longest_common_substring_for_words.sort{ |w1,w2| w1[1].length <=> w2[1].length}).last[0]
    end
  end
end
