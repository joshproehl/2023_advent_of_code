defmodule CamelCard.Hand do
  # We're going to be cheesy here and just use an integer representation for
  # type, where the strongest (5 of a kind) is 1, and the weakest (high card)
  # is 7.
  # This will allow us to just sort them based on type asc and be done.
  defstruct hand: nil, bid: 0, type: 0

  @order %{
    "A" => 1,
    "K" => 2,
    "Q" => 3,
    "T" => 5,
    "9" => 6,
    "8" => 7,
    "7" => 8,
    "6" => 9,
    "5" => 10,
    "4" => 11,
    "3" => 12,
    "2" => 13,
    "J" => 14,
  }

  def compare(%CamelCard.Hand{type: t1}, %CamelCard.Hand{type: t2}) when t1 < t2, do: :lt
  def compare(%CamelCard.Hand{type: t1}, %CamelCard.Hand{type: t2}) when t1 > t2, do: :gt
  def compare(%CamelCard.Hand{type: t1, hand: h1}, %CamelCard.Hand{type: t2, hand: h2}) when t1 == t2 and h1 == h2, do: :eq
  def compare(%CamelCard.Hand{type: t1, hand: h1}, %CamelCard.Hand{type: t2, hand: h2}) when t1 == t2 do
    # At this point we know that the first cards of the hand are the same,
    # so now we need to _go deeper_...
    Enum.zip(h1, h2)
    |> Enum.drop_while(fn {c1, c2} -> c1 == c2 end)
    |> Enum.at(0)
    |> then(fn {c1_int, c2_int} ->
      # We know they can't be equal, or they would've been dropped.
      c1 = to_string([c1_int])
      c2 = to_string([c2_int])
      case @order[c1] < @order[c2] do
        true -> :lt
        false -> :gt
      end
    end)
  end

  def parse(line) do
    v =
      line
      |> String.split()
    hand =
      v
      |> Enum.at(0)
      |> to_charlist()
    {bid, _rem} =
      v
      |> Enum.at(1)
      |> Integer.parse()
    
    %CamelCard.Hand{hand: hand, bid: bid, type: type(hand)}
  end

  def type(hand) do
    base_freqs = Enum.frequencies(hand)
    j_char = "J" |> to_charlist() |> Enum.at(0)

    freqs =
      base_freqs
      |> Enum.map(&(elem(&1, 1)))
      |> Enum.sort()

    cond do
      freqs == [5] -> 1
      freqs == [1, 4] -> 2
      freqs == [2, 3] -> 3
      freqs == [1, 1, 3] -> 4
      freqs == [1, 2, 2] -> 5
      freqs == [1, 1, 1, 2] -> 6
      freqs == [1, 1, 1, 1, 1] -> 7
      true ->
        IO.puts("ERROR: Invalid hand type! This should never happen! Freqs were: #{inspect(freqs)}")
        -666
    end
    |> upgrade_type(Map.get(base_freqs, j_char, 0))
  end

  # There is a finite list of upgrade paths, defined by what the existing type is, and how many jacks there are.
  # For example, in the case of type 5, [1, 2, 2] means that we can either have a single jack, or two jacks.
  # In which case we can upgrade to a [2, 3] if we have 1, or to a [1, 4] if we have 2. We can also upgrade to
  # a [2, 3] if we have 2, but we wouldn't ever do that as it's less optimal.
  # First we'll check jack count, so we don't have to run the rest of the calculation on cards with no jacks
  # and then we'll just check the map. There is only one case (type 5) where there are two possible outcomes,
  # depending on how many jacks exist. All the others have exactly 1 optimal upgrade, no matter which cards
  # are jacks.
  defp upgrade_type(type, jack_count) do
    if jack_count > 0 do
      case type do
        7 -> 6
        6 -> 4
        5 ->
          case jack_count do
            1 -> 3
            2 -> 2
          end
        4 -> 2
        3 -> 1
        2 -> 1
        1 -> 1
      end
    else
      type
    end
  end
end


defmodule CamelCard do
  defstruct hands: []

  def winnings(sorted_hands) do
    sorted_hands
    |> Enum.reverse()
    |> Enum.with_index(1)
    |> Enum.reduce(0, fn {hand, rank}, acc -> acc + (hand.bid*rank) end)
  end

  def parse(str) do
    str
    |> String.trim()
    |> String.split("\n")
    |> Enum.map(&CamelCard.Hand.parse/1)
    |> Enum.sort(CamelCard.Hand)
    |> then(fn hands -> %CamelCard{hands: hands} end)
  end
end


# DO A QUICK SANITY CHECK
"""
32T3K 765
T55J5 684
KK677 28
KTJJT 220
QQQJA 483
"""
|> CamelCard.parse()
#|> tap(&IO.inspect(&1.hands, label: "TEST Sorted hands:", limit: :infinity))
|> then(&CamelCard.winnings(&1.hands))
|> tap(fn won -> IO.puts("Test passed (#{won} == 5905): #{won == 5905} ") end)


File.read!("input")
|> CamelCard.parse()
#|> tap(&IO.inspect(&1.hands, label: "Sorted hands:", limit: :infinity, ))
|> then(&CamelCard.winnings(&1.hands))
|> IO.inspect(label: "Total Winnings: ")

# Once I figured out all possible upgrade paths it was pretty straightforward.
# The one problem I had was looking up the "J" character to get the value from
# the frequency map. I hadn't realized the map was storing the keys as integers
# and had to debug things a bit to figure that out before the lookup worked.
# Got 250382098, which was right! First try, once I fixed the lookup not working.
