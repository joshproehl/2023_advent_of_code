defmodule CubeGameSet do
  @moduledoc """
  Represent a single "set" of dice used. Each game contains 1 or more sets.
  """

  defstruct red: 0, blue: 0, green: 0

  def new(r, g, b), do: %CubeGameSet{red: r, green: g, blue: b}

  @doc """
  In the text description of a game the sets are written as
  red: 1, blue: 1, green: 1
  and we'll convert this into a struct representing the set.
  """
  def parse(string) do
    string
    |> String.split(",")
    |> Enum.reduce(%CubeGameSet{}, &parse_single_color/2)
  end

  @doc """
  Returns the "power" of the set as defined by the instructions.
  """
  def power(set) do
    set.red * set.green * set.blue
  end

  # At this step we'll have something like " 3 blue", and we need to put the
  # parsed integer 3 into the struct for key :blue.
  defp parse_single_color(string, accumulator_set) do
    [val_str, color_str] = string
                           |> String.trim()
                           |> String.split(" ")

    {int_val, _} = Integer.parse(val_str)

    case color_str do
      "red" -> %{accumulator_set| red: int_val}
      "green" -> %{accumulator_set| green: int_val}
      "blue" -> %{accumulator_set| blue: int_val}
    end
  end
end


defmodule CubeGame do
  @moduledoc """
  Represent a single "game", or one line from our input data.
  """

  defstruct id: 0, sets: []

  @doc """
  Parses a single line from our input file into a game struct.
  """
  def parse(line) do
    line
    |> String.split(":")
    |> build_struct_from_split()
  end

  @doc """
  We want to determine if a game *could* have been played using a known set
  of dice or not. To do this we'll take the game, and the target_set, and check
  if any of the sets used in the game exceed the number of dice available in
  the target_set
  """
  def is_valid_for_set(game, target_set) do
    game.sets
    |> Enum.map(&(set_valid_for_target_set(&1, target_set)))
    |> Enum.all?() # Simple check to see if every set validity mapped to "true"
  end

  @doc """
  Create a %CubeGameSet{} representing the minimum required set to have
  successfully played this game
  """
  def minimum_set(game) do
    game.sets
    |> Enum.reduce(%CubeGameSet{}, &take_greater_vals/2)
  end

  defp take_greater_vals(set, res) do
    %{res|
      red: [set.red, res.red] |> Enum.sort |> Enum.at(-1),
      green: [set.green, res.green] |> Enum.sort |> Enum.at(-1),
      blue: [set.blue, res.blue] |> Enum.sort |> Enum.at(-1),
    }
  end

  defp build_struct_from_split([game_string, sets_string]) do
    %CubeGame{
      id: extract_id_integer(game_string),
      sets: extract_sets(sets_string),
    }
  end

  defp extract_id_integer(game_string) do
    {id, _} = game_string
              |> String.split(" ")
              |> Enum.at(-1)
              |> Integer.parse()

    id
  end

  defp extract_sets(sets_string) do
    sets_string
    |> String.split(";")
    |> Enum.map(&CubeGameSet.parse/1)
  end

  # Returns "true" if the given set could have been obtained using the target set
  defp set_valid_for_target_set(set, target) do
    if set.red <= target.red &&
       set.green <= target.green &&
       set.blue <= target.blue do
        true
    else
      false
    end
  end
end

# The Elf would first like to know which games would have been possible if the
# bag contained only 12 red cubes, 13 green cubes, and 14 blue cubes
part1_target = CubeGameSet.new(12, 13, 14)

IO.puts("Calulating the sum of all games that are valid using the set of cubes:")
IO.inspect(part1_target)
File.stream!("input")
|> Enum.map(&CubeGame.parse/1)
|> Enum.map(fn g -> 
  {g.id, CubeGame.is_valid_for_set(g, part1_target)}
end)
|> Enum.reduce(0, fn {id, valid}, acc ->
  case valid do
    true -> acc + id
    false -> acc
  end
end)
|> IO.inspect()

# Got 2716, which is the correct answer.

IO.puts("Now calculating sum of the power of the minimum set for each game...")
File.stream!("input")
|> Enum.map(&CubeGame.parse/1)
|> Enum.map(&CubeGame.minimum_set/1)
|> Enum.map(&CubeGameSet.power/1)
|> Enum.sum()
|> IO.inspect()

# Got 72227, which is the correct answer!

# This one was a lot simpler, no weird undocumented edge cases.
# The structure I used made it easy to add the minimum_set and power functions
# needed to accomplish part 2.
#
# The only part that I had to stop and think about was how to get the minimum
# set. The solution that was easiest was the sort-and-take-last-element inside
# the reduce. I think I'd like to look at a better/more-elegant way to do this,
# but I'm still suffering some PTSD from yesterday's assignment and I just
# wanted it over with. :-D
