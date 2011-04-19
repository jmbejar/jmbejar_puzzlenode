require 'rubygems'
gem 'minitest'
require 'minitest/autorun'

require 'spelling'

class TestSpelling < MiniTest::Unit::TestCase
  include Spelling

  def test_dictionary
    dictionary = Dictionary.new
    assert_empty dictionary.words

    dictionary.add_word("test1")
    refute_empty dictionary.words
    assert_includes dictionary.words, "test1"

    dictionary.add_word("test2")
    assert_includes dictionary.words, "test1"
    assert_includes dictionary.words, "test2"
    assert_equal dictionary.words.count, 2
  end

  def test_common_char_secuence
    common_char_sec = CommonCharSecuences.new("test1", "the_test_2")
    assert_equal common_char_sec.word1, "test1"
    assert_equal common_char_sec.word2, "the_test_2"
    assert_equal common_char_sec.longest_common_char_secuence, "test"

    common_char_sec = CommonCharSecuences.new("abcdabcdabcd123456", "apoiopboojcjpjao1ghabcdfgh2")
    assert_equal common_char_sec.longest_common_char_secuence, "abcaabcd2"

    common_char_sec = CommonCharSecuences.new("test", "")
    assert_equal common_char_sec.longest_common_char_secuence, ""
    common_char_sec = CommonCharSecuences.new("", "test")
    assert_equal common_char_sec.longest_common_char_secuence, ""
    common_char_sec = CommonCharSecuences.new("", "")
    assert_equal common_char_sec.longest_common_char_secuence, ""
    common_char_sec = CommonCharSecuences.new("test", "card")
    assert_equal common_char_sec.longest_common_char_secuence, ""
  end

  def test_spelling_suggestions
    spelling = SpellingSuggestions.new
    spelling.add_word_to_dictionary "abcdef"
    spelling.add_word_to_dictionary "abc123"

    # the following cases have only one valid solution
    assert_equal spelling.suggestion_for("abcd"), "abcdef"
    assert_equal spelling.suggestion_for("123"), "abc123"
    assert_equal spelling.suggestion_for("b1"), "abc123"
    assert_equal spelling.suggestion_for("ac1df"), "abcdef"
    assert_equal spelling.suggestion_for("ac1d23f"), "abc123"

    # the following cases will result in a tie, both words are a valid solution
    assert_includes ["abcdef", "abc123"], spelling.suggestion_for("abc")
    assert_includes ["abcdef", "abc123"], spelling.suggestion_for("ac1d2f")
  end
end
