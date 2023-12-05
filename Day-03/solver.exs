# Checks:
#   - line 1, digits 2, 999, 840 should not be adjacent
#   - line 136: digit 594 is not adjacent.

defmodule Schematic.Symbol do
  defstruct value: "", line_num: -1, char_num: -1

end

defmodule Schematic.Digit do
  defstruct value: -1, line_num: -1, char_num: -1, len: -1, is_part_number: false

  @doc """
  Returns a list of {x,y} coordinates that are considered adjacenct to the given
  digit. Note that these coordinates may be outside of the actually existing
  lines. We're computing on a hypothetical plane here, not the actual one.
  """
  def get_adjacency_coordinates(digit) do
    Enum.map((digit.line_num-1)..(digit.line_num+1), fn x ->
      Enum.map((digit.char_num-1)..(digit.char_num-1+digit.len+1), fn y ->
        {x,y}
      end)
    end)
    |> List.flatten()
  end

  @doc """
  Returns if any of the given digit's adjacency coordinates are taken up by the
  given digit. 
  """
  def is_adjacent_to?(digit, %Schematic.Symbol{line_num: t_line, char_num: t_char}) do
    target = {t_line, t_char}

    get_adjacency_coordinates(digit)
    |> Enum.any?(fn tc -> tc == target end)
  end
end

defmodule Schematic do
  @moduledoc """
  Takes a flat file schematic and turns it into the data structure we need.
  symbols is a list of all found symbols.
  digits is a list of all found digits.
  symbol_map is a 2d map keyed on the x and y coordinates of each symbol.
  """
  defstruct symbols: [], digits: [], symbol_map: %{}

  @digits ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]

  def debug_line(schematic, target_line_num) do
    IO.puts("Digits for line #{target_line_num}:")
    schematic.digits
    |> Enum.reduce([], fn x, acc -> 
      case x.line_num do
        l when l == target_line_num -> acc ++ [x]
        _ -> acc
      end
    end)
    |> IO.inspect()

    IO.puts("Symbol map for line #{target_line_num}:")
    IO.inspect(schematic.symbol_map[target_line_num])
  end

  def digits_from_line(schematic, target_line_num) do
    schematic.digits
    |> Enum.reduce([], fn x, acc -> 
      case x.line_num do
        l when l == target_line_num -> acc ++ [x]
        _ -> acc
      end
    end)
  end

  def parse_file(path) do
    File.stream!(path)
    |> Enum.with_index(fn line, index -> {index, line} end)
    |> Enum.map(&parse_line/1)
    |> Enum.reduce(%{symbols: [], digits: [], symbol_map: %{}}, fn {_line_num, symbols, digits}, acc ->
      %{acc|
        symbols: acc.symbols ++ symbols,
        digits: acc.digits ++ digits,
        symbol_map: update_symbol_map(acc.symbol_map, symbols),
      }
    end)
    |> update_part_number_flags()
  end

  # Returns a list of all parsed symbols and digits on the line
  defp parse_line({line_num, line_string}) do
    %{symbols: symbols, digits: digits} =
      line_string
      |> String.graphemes()
      |> Enum.with_index(fn c, index -> {index, c} end)
      |> Enum.reduce(%{symbols: [], digits: [], cur_digit: ""}, fn c, acc ->
        case c do
          {_char_num, c} when c in @digits -> %{acc| cur_digit: "#{acc.cur_digit}#{c}"}
          {char_num, c} when c == "." -> parse_accumulated_digit(acc, line_num, char_num)
          {char_num, c} ->
            # A digit, INCLUDING an end-of-line, means stop parsing a digit.
            acc_with_digit = parse_accumulated_digit(acc, line_num, char_num)
            # However, if it is end of line then we don't add it to the symbol list
            case c do
              c when c == "\n" -> acc_with_digit
              c -> 
                symbol = %Schematic.Symbol{
                  value: c,
                  line_num: line_num,
                  char_num: char_num,
                }
                %{acc_with_digit|
                  symbols: acc_with_digit.symbols ++ [symbol],
                }
            end
        end
      end)
      {line_num, symbols, digits}
  end

  # Takes the acc map from parse_line and inserts a new char 
  defp parse_accumulated_digit(%{cur_digit: ""} = acc, _, _), do: acc
  defp parse_accumulated_digit(acc_map, line_num, ending_char_num) do
    {parsed_int, _rem} = Integer.parse(acc_map.cur_digit)
    digit_str_len = String.length(acc_map.cur_digit)
    digit = %Schematic.Digit{
      value: parsed_int,
      line_num: line_num,
      char_num: ending_char_num - digit_str_len,
      len: digit_str_len,
    }

    %{acc_map|
      digits: acc_map.digits ++ [digit],
      cur_digit: "",
    }
  end

  defp update_part_number_flags(%{digits: digits, symbol_map: digit_map} = parsed) do
    digits_with_updated_part_number_flags = Enum.reduce(digits, [], fn d, acc -> 
      has_adjacent_symbol = Schematic.Digit.get_adjacency_coordinates(d)
                            |> Enum.map(fn {x,y} ->
                              symbol = 
                                Map.get(digit_map, x, %{})
                                |> Map.get(y)
                              case symbol do
                                nil -> false
                                _ -> true
                              end
                            end)
                            |> Enum.any?(fn n -> n == true end)

      acc ++ [%{d| is_part_number: has_adjacent_symbol}]
    end)
    
    %{parsed| digits: digits_with_updated_part_number_flags}
  end

  defp update_symbol_map(cur, symbol_list) do
    symbol_list
    |> Enum.reduce(cur, fn s, acc -> 
      acc
      |> Map.put_new(s.line_num, %{})
      |> put_in([s.line_num, s.char_num], s)
    end)
  end

end

IO.puts("Considering the schematic for a moment...")
parsed_input = Schematic.parse_file("input")

# Some manual checks to make sure that the parser is doing what we expect
# with the various cases:
# - part number at beginning of line
# - part number at end of line
# - non-part-number at beginning of line
# - non-part-number at end of line
# - (There are no single digit digits at beginning or end of any line, not tested)
# - single digit part number in middle of line
# - non-part-number in middle of line
# - checked the line-8 case to make sure we're not taking any additional columns on the right side
%{value: 823, is_part_number: true} = Schematic.digits_from_line(parsed_input, 15) |> Enum.at(0)
%{value: 277, is_part_number: true} = Schematic.digits_from_line(parsed_input, 25) |> Enum.at(-1)
%{value: 665, is_part_number: false} = Schematic.digits_from_line(parsed_input, 71) |> Enum.at(0)
%{value: 206, is_part_number: false} = Schematic.digits_from_line(parsed_input, 73) |> Enum.at(-1)
%{value: 3, is_part_number: true} = Schematic.digits_from_line(parsed_input, 125) |> Enum.at(4)
%{value: 54, is_part_number: false} = Schematic.digits_from_line(parsed_input, 27) |> Enum.at(-2)
%{value: 791, is_part_number: false} = Schematic.digits_from_line(parsed_input, 8) |> Enum.at(0)

#Schematic.debug_line(parsed_input, 8)
#Schematic.digits_from_line(parsed_input, 8) |> Enum.at(0) |> Schematic.Digit.get_adjacency_coordinates() |> IO.inspect()
#Schematic.digits_from_line(parsed_input, 8) |> Enum.at(1) |> Schematic.Digit.get_adjacency_coordinates() |> IO.inspect()
#IO.inspect(Map.get(parsed_input.symbol_map, 7))
#IO.inspect(Map.get(parsed_input.symbol_map, 8))
#IO.inspect(Map.get(parsed_input.symbol_map, 9))

IO.puts("Adding up all the part numbers from the schematic gives us:")
parsed_input.digits
|> Enum.reject(fn d -> d.is_part_number == false end)
|> Enum.map(fn d -> d.value end)
|> Enum.sort()
#|> Enum.uniq()
|> Enum.sum()
|> IO.inspect(limit: :infinity)

# Initial pass at this returns 538010, which is too high.
# Debugging shows that,
# - the accumulater is workng
# - random sample of parsed digits shows their is_part_number to be correct
#
# Okay, I gave up and went to reddit again... Duplicate part numbers may be
# the issue, so I need to de-dupe the digits first.
#
# After adding the uniq_by to the addition chain, the answer is 312568, which
# is now too low.
#
# Re-doing the addition chain to do uniq_by |> value |> sort|> sum() returned
# 352506
# Which is different than the other chain somehow, but also still too low.
#
# I discovered a bug that was causing the adjacency to be calculated wrong.
# Getting the digit.char_num + digit.len + 1 was getting an additional column
# on the right side. So we fixed that, and got 323710 as the latest sum.
#
# The only thing I could think of was that Reddit's advice about uniq'ing the
# part numbers was wrong, so I removed the uniq, and got 532428, which is
# finally correct! 

IO.puts("Finding all gears...")

gear_symbols = Enum.reject(parsed_input.symbols, fn s -> s.value != "*" end)
IO.puts("Found #{Enum.count(gear_symbols)} gear symbols, checking them...")

empty_gear_map =
  parsed_input.symbols
  |> Enum.reject(fn s -> s.value != "*" end)
  # Turn our list of gear symbols into a map keyed on the Symbol object, containing a list
  |> Enum.into(%{}, fn x -> {x, []} end)

#IO.inspect(empty_gear_map, limit: :infinity)

gear_map = parsed_input.digits
           |> Enum.reduce(empty_gear_map, fn d, gear_map_acc -> 
           # This reduce walks across all digits, and for each digit it gets 
           # it's adjacencies, and checks to see if any of those coordinates
           # contain a gear symbol, using the 2D map of all symbols by coord.
             Schematic.Digit.get_adjacency_coordinates(d)
             |> Enum.reduce([], fn {line, char}, acc ->
             # This reduce  walks all adjacency coordinates, and returns a
             # List containing all of the gear symbols adjacenct to the
             # current digit (d)
               case parsed_input.symbol_map[line][char] do
                 s when s.value == "*" -> [s | acc]
                 _ -> acc
               end
             end)
             # Now we take that list of gear symbols adjacent to d,
             # and we find each one in the empty gear map, and add
             # this digit to it's list.
             |> Enum.reduce(gear_map_acc, fn s, acc -> 
                current_adjacent_digits = acc[s]
                Map.put(acc, s, [d | current_adjacent_digits])
             end)
           end) 
           # Now we have a map of all the gear symbols that have adjacent
           # digits, so we want to reject it down to only symbols that have
           # exactly two adjacent digits to find our actual gears.
           |> Enum.reject(fn {symbol, digit_list} -> Enum.count(digit_list) != 2 end)

# And now we can do things with our completed gear map...
IO.puts("Calculating gear ratios...")

gear_map
|> Enum.map(fn {_s, digits} -> Enum.at(digits, 0).value * Enum.at(digits, 1).value end)
|> Enum.sum()
|> IO.inspect

# Got sum of all gear ratios to be: 84051670, which was the correct answer!
