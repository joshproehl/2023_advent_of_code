defmodule Solver do
  @digit_strs ["0","1","2","3","4","5","6","7","8","9"]

  def line_to_calibration_number(line) do
    digits = line
             |> String.graphemes
             |> Enum.filter(fn x -> Enum.member?(@digit_strs, x) end)


    {parsed, _rem} = case Enum.count(digits) do
      c when c > 1 -> 
        Integer.parse("#{Enum.at(digits, 0)}#{Enum.at(digits, -1)}")
      c when c == 1 ->
        # This is the "treb7uchet -> 77" edge case.
        Integer.parse("#{Enum.at(digits, 0)}#{Enum.at(digits, 0)}")
      _ -> 
        {0, 0}
    end

    #IO.puts("#{line} converts to calibration number #{parsed}")

    parsed
  end

end

IO.puts("The sum of all calibration values is...")

File.stream!("input")
|> Enum.map(&Solver.line_to_calibration_number/1)
|> Enum.sum()
|> IO.puts


# Final answer was 54940, which was "correct".
# Why did I do it this way? Honestly because it was the first thing that
# came to mind.
# I knew I wanted first and last characters that were digits, so the
# obvious solution was to remove everything that WASN'T a digit and just
# grab the elements.
#
# The only problem I had that I had to figure out after first run was that 
# I'd forgotten that Integer.parse() returned a {int, remainder} tuple instead
# of just the integer value.
#
# But then a wild Part 2 appeared.


##################
##### Part 2 #####

defmodule Part2 do
  @word_digits ["one", "two", "three", "four", "five", "six", "seven", "eight", "nine"]
  @digit_strs ["1", "2", "3", "4", "5", "6", "7", "8", "9"]

  # DEPRECATED: First attempt didn't work due to the oneight problem.
  def words_to_digits(line) do
    replacement_map = Enum.zip(@word_digits, @digit_strs)
    res = Enum.reduce(replacement_map, line, fn {str, digi}, ln -> String.replace(ln, str, digi) end)

    IO.puts("#{String.trim(line)} --> #{res}")
    res
  end

  # We only actually need the first and last digit-word we find to be replaced
  # since all digits in the middle would be thrown away in the next step anyway.
  # This is ugly, but I'm tired of dealing with it after spending so much time
  # just trying to figure out that the oneight problem EXISTED, so we're gonna
  # go straight brutal.
  def first_and_last_word_to_digit(line) do
    last_index_positions = Enum.map(@word_digits, fn w -> 
      case Enum.at(:binary.matches(line, w), -1) do
        nil -> :nomatch
        p -> p
      end
    end)
    first_index_positions = Enum.map(@word_digits, fn w -> :binary.match(line, w) end)

    replacement_map = Enum.zip([@word_digits, @digit_strs, first_index_positions, last_index_positions])

    # Get the very last word-digit in the string by sorting the replacement map
    # and just extracting the last element.
    # Since we're mapping across all the digit-words, if any specific one doesn't
    # exist in the string, then we set it's pos to {-1, -1} so we can filter it out
    # in the putting-it-back-together step.
    {_last_word, last_digit, _first_occurrence, {last_word_pos, last_word_len}} =
      replacement_map
      |> Enum.sort_by(&(elem(&1, 3)))
      |> Enum.at(-1)
      |> case do
        {w, d, f, :nomatch} -> {w, d, f, {-1, -1}}
        e -> e
      end

    # Same as above, but for first digit-word on the line.
    # What's happening here is all the :nomatch was sorting to the top, but
    # if we sort :desc then we don't pull the right word. 
    # So what we need is a custom sorting function that sorts :nomatch to the bottom
    {_first_word, first_digit, {first_word_pos, _first_word_len}, _last_occurrence} = 
      replacement_map
      |> Enum.sort_by(fn
        {_w, _d, f, _l} when is_atom(f) -> "ZZZ"
        {_w, _d, {fp, _fl}, _l} -> fp
      end)
      |> Enum.at(0)
      |> case do
        {w, d, :nomatch, l} -> {w, d, {-1, -1}, l}
        e -> e
      end

    # To put it back together we'll turn the string into a list and do some
    # splitting and concatentaion.
    line_list = String.graphemes(line)
    line_with_last_replaced = case last_word_pos do
      p when p >= 0 ->
        {last_head, last_tail} = Enum.split(line_list, p+last_word_len)
        last_head ++ [last_digit] ++ last_tail
      _ -> line_list
    end

    # This should work fine because the first pos HAS to have been
    # in the last_head (if it exists at all), so the pos should be the same.
    # The edge case is if there is only one word in the string. 
    #   For example: 7six441. It needs to be 7six6441, NOT 76six6441.
    line_with_both_replaced = case first_word_pos do
      p when p == last_word_pos -> line_with_last_replaced
      p when p >= 0 ->
        {first_head, first_tail} = Enum.split(line_with_last_replaced, p)
        first_head ++ [first_digit] ++ first_tail
      _ -> line_with_last_replaced
    end

    #IO.puts("#{line |> String.trim()} --> #{line_with_both_replaced |> to_string() |> String.trim()}")

    # And back to a string, the format we got it in.
    to_string(line_with_both_replaced)
  end
end

IO.puts("\nBut Wait, There's More!\nRe-parsing using words as digits results in...")

File.stream!("input")
|> Enum.map(&Part2.first_and_last_word_to_digit/1)
|> Enum.map(&Solver.line_to_calibration_number/1)
#|> Enum.with_index(fn element, index -> {index+1, element} end) #Debugging by showing line number so we can compare against input
#|> IO.inspect(limit: :infinity)
|> Enum.sum()
|> IO.inspect


# So I dislike this method, but it was easy enough to implement. It's not, you
# know, *elegant*, but it allowed code re-use and since we're not going to 
# prematurely optimize for 10-billion-line inputs, whatever. 
#
# Technically I think the inclusion of 0 in the digits is incorrect, since the
# string versions doesn't include zero, but since there aren't any 0 digits in 
# the input it ended up being a non-issue.
#
# The only problem I had was that I had reversed the order of lists into the
# Zip, which was actually converting all digits to the word versions, exactly
# backwards...
#
# the first answer, 53595, was not correct. An edge-case appeared, where there
# WEREN'T two digits in the final of digits, causing a string with only a
# single 4 in it to return as "44" because we were taking Enum.at of both 0
# and -1, both of which returned 4.
# To solve this I re-wrote the original line_to_calibration_number to handle
# 0, 1, or >1 digits in the final list.
#
# This obviously changed the value in of the original calculation as well.
# Part 1 is now 38120, and Part 2 is 50595, which is still apparently wrong...
# The final list is a thousand numbers long, and randomly sampling of them
# indicates that they're correct.
#
# Okay, it turns out that in this, as in most things, poor documentation is
# the root of all evil. According to the subreddit "oneeight" is both a 1
# AND and 8....
# So the first offending line I found from the bottom up was:
# three49oneightf --> 3491ightf
# Which SHOULD convert to 34918f, and therefore be 38, rather that 31.
#
# So that required a re-do of the algorithm. Instead of straight up string 
# replacement of "one" to "1", what we want is for "oneight" to become
# "1oneeight8", and we actually don't care even a tiny bit about the
# oneigthree edge case, because the end result we care about is "13".
#
# The result after the refactor is 51208, but that's also apparently the
# wrong answer... I have checked manually from a random sampling, as well
# as checked as many specific edge cases as I could find, and they all
# convert to calibration numbers correctly...
# Cases validated:
#   1) Line has only single digit
#   2) Line has only single word, no digits
#   3) Line starts with word
#   4) Line ends with word
#   4) Line starts with word and ends with digits
#   5) Line starts with digit and ends with word
#   6) Line Starts and ends with word
#   7) Line starts and ends with digit
#   8) Line made up of entirely digits
#   9) Line made of of entirely overlapping words (oneight -> 18)
#   
# Gave up and looked on reddit for edge cases again... APPARENTLY
# a single digit can be both the first and the last. This is, in fact
# in the docs. "treb7uchet" converts to 77.
# Fortunately that's a simple refactor of line_to_calibration_number's existing
# case for there being only a single number, and with that change we get the 
# right answer: 54208
