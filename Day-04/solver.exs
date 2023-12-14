defmodule Card do
  defstruct number: 0, winning_numbers: [], have_numbers: []

  def parse(line) do
    s1 = String.split(line, ":")
    s2 = String.split(Enum.at(s1, 1), "|")
    
    %Card{
      number: parse_card_number(Enum.at(s1, 0)),
      winning_numbers: parse_to_int_list(Enum.at(s2, 0)) |> Enum.sort(),
      have_numbers: parse_to_int_list(Enum.at(s2, 1)) |> Enum.sort(),
    }
  end

  # To get the score you figure out how many of the winning numbers you
  # have, and then score 1 point for the first, and double the score for
  # each successive winning number you have. (So 2 numbers is 2 points,
  # 3 is 4 points, 4 is 8 points, etc...
  def score(card) do
    card
      |> calculate_won_numbers()
      |> Enum.reduce(0, fn
        _, 0 -> 1
        _, acc -> acc * 2
      end)
  end
  #
  # Ideally we'd do a set intersection thing here... but I'm on an airplane
  # and don't know of such a function off the top of my head. So we iterate.
  def calculate_won_numbers(%Card{have_numbers: have, winning_numbers: winning}) do
    have
    |> Enum.uniq() # Once again didn't verify that there are ever duplicate have_numbers, but it worked before...
    |> Enum.reduce([], fn x, acc ->
      case Enum.any?(winning, fn wn -> wn == x end) do
        true -> [x | acc]
        false -> acc
      end
    end)
  end


  @doc """
  Returns a list of won cards for list of cards.
  Returns the cards passed in, and any cards they won. (So given a list of cards
  with no winning matching numbers, will return just the original list.)

  NOTE: That this depends on the card list being sorted! We're not looking up
  card IDs, we're just grabbing the next n elements off the head, so any
  list of cards not sorted by card number won't get the correct duplicates.
  """
  def get_won_cards(cards, base_card, sub_card, take \\ :all, level \\ 1)
  def get_won_cards([], _, _, _, _), do: []
  def get_won_cards(_, _, _, t, _) when t <= 0, do: []
  def get_won_cards([card|remaining_cards], base_card, sub_card, take, level) do
    number_of_cards_this_card_won = 
      calculate_won_numbers(card)
      |> Enum.count()

    #IO.puts("#{Enum.map(0..level, fn _ -> " " end) |> Enum.join("")} #{level}: Card \##{card.number} starting, won #{number_of_cards_this_card_won}, taking #{take} more of #{Enum.count(remaining_cards)}")
    won_cards =
      case number_of_cards_this_card_won do
        0 -> []
        c -> 
          #IO.puts(" -- Card \##{card.number} won #{c}, iterating...")
          # Because we're iterating through the list here, for each iteration we have to trim a bit off the front off the list
          # and then recursively go get the won cards.
          # Stupid 1-indexed count...
          # Don't iterate more times than there are remaining cards or we'll end up with duplicates.
          iter_count = min(c-1, Enum.count(remaining_cards))
          for i <- (0..iter_count) do
            iter_remaining = Enum.drop(remaining_cards, i)
            get_won_cards(iter_remaining, base_card, card, c-i, level+1)
          end
          |> List.flatten()
      end

    # Now that we've grabbed the children we can move on down the remaining_cards
    # but only if we're at the top-level where we're trying to iterate the entire
    # list.
    res = case take do
      :all -> [card] ++ won_cards ++ get_won_cards(remaining_cards, Enum.at(remaining_cards, 0), Enum.at(remaining_cards, 0), :all, level+1)
      c when is_integer(c) -> [card] ++ won_cards
    end

    #IO.puts("[\##{card.number}] (take level #{take}) returning #{Enum.count(res)} total cards: #{inspect(res)}")
    #IO.puts("#{Enum.map(0..level, fn _ -> " " end) |> Enum.join("")} #{level}: === Done with \##{card.number}, got #{inspect(res)} won cards list")

    if take == :all do
      IO.puts("Final return for \##{card.number}: #{inspect(res)}")
      IO.puts("")
    end

    IO.write("\rInitial Card: #{base_card.number}, sub_card: #{sub_card.number}, card: #{card.number}, take: #{take}, level: #{level}")

    res
  end

  #####
  # Since we're getting what appears to be an infinite loop in the first recursion attempt we're going to try a total rewrite.
  # NOTE: This one took a minute or two to run, but resulted in 7185540, which was the correct total number.
  # Sometime when I'm at home I'll run the other version on the big computer and let it run all day and see if it actually worked
  # but was just taking an insanely long time on the laptop.
  def results_for_card(nil, _), do: []
  def results_for_card(card, full_card_list) do
    won_card_numbers =
      Card.calculate_won_numbers(card)
      |> Enum.with_index(fn _x, i -> card.number + (i+1) end)
      |> Enum.map(fn wn ->
        results_for_card(Enum.at(full_card_list, wn-1), full_card_list)
      end)

    [card.number] ++ won_card_numbers |> List.flatten
  end

  defp parse_card_number(str) do
    digit_str = Enum.at(String.split(str), -1)
    {num, _rem} = Integer.parse(digit_str)
    num
  end

  defp parse_to_int_list(str) do
    str
    |> String.trim()
    |> String.split()
    |> Enum.map(fn x ->
      {num, _rem} = Integer.parse(x)
      num
    end)
  end

end

defimpl Inspect, for: Card do
  def inspect(card, %Inspect.Opts{custom_options: [detailed: true]}) do
    """
    Card #{card.number}, score: #{Card.score(card)}
    -------------|---------------------
    Have Numbers : #{Kernel.inspect(card.have_numbers, charlists: :as_lists)}
    -------------|---------------------
    Win Numbers  : #{Kernel.inspect(card.winning_numbers, charlists: :as_lists)}
    -------------|---------------------
    Won Cards    : #{Kernel.inspect(Card.calculate_won_numbers(card) |> Enum.sort, charlists: :as_lists)}
    -------------|---------------------

    """
  end

  def inspect(card, _opts) do
    "\##{card.number}"
  end
end

input_file_name = System.argv() |> Enum.at(0) || "input"
IO.puts("Using input file named: #{input_file_name}")


File.stream!(input_file_name)
|> Enum.map(&Card.parse/1)
|> Enum.map(&Card.score/1)
|> Enum.sum()
|> IO.inspect

# First pass got 42256, with a few line spot checks to confirm plausibility.
# Once I'm off this plane I guess we'll see what weird edge cases exist...
# Nope, that is too high. I can't believe I'm doing this on vacation...
# Oh, yeah, my sleep deprived flying-for-24-hours brain used pow! to do the
# score for any count of winning numbers higher than 1, whic his not right.
#
# Re-did with proper scoring rules and got 21138, which was right!

IO.puts("\nRe-doing with proper rules since silly elves can't be bothered to read...")

#File.stream!(input_file_name)
#|> Enum.map(&Card.parse/1)
#|> Enum.map(fn x -> IO.puts("#{x.number} : #{Card.calculate_won_numbers(x) |> Enum.count}") end)
#IO.puts("")

cards = 
  File.stream!(input_file_name)
  |> Enum.map(&Card.parse/1)

#Enum.each(cards, fn c -> IO.inspect(c, custom_options: [detailed: true]) end)

#won_cards = Card.get_won_cards(cards, Enum.at(cards, 0), Enum.at(cards, 0))
won_cards = Enum.map(cards, fn c -> Card.results_for_card(c, cards) end) |> List.flatten

IO.puts("------------")
IO.puts("All won cards:")
IO.inspect(Enum.map(Enum.sort(won_cards), fn x -> "\##{x}" end))

if(input_file_name == "test_input") do
  expected = [1, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 6]

  IO.puts("")
  IO.puts("TEST SHOULD BE: 30 cards, (14 copies of 5)")
  IO.inspect(expected)
  IO.puts("Actual results (sorted):")
  IO.inspect(won_cards |> Enum.sort)
  IO.puts("Expected matches actual: #{expected == won_cards}")
  IO.puts("")
end

IO.puts("The elf now has #{Enum.count(won_cards)} scratchcards in total...")
