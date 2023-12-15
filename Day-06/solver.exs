defmodule BoatRace.Run do
  defstruct hold_time: 0, distance: 0

  def build(race_time, hold_time) do
    %BoatRace.Run{
      hold_time: hold_time,
      distance: (race_time - hold_time) * hold_time,
    }
  end
end

defmodule BoatRace do
  defstruct time: 0, distance_record: 0, possible_runs: [], ways_to_win: []

  def parse(lines) do
    lines
    |> String.split("\n")
    |> Enum.map(fn line ->
      line
      |> String.split()
      |> Enum.drop(1)
      |> Enum.map(fn digit_str ->
        digit_str
        |> Integer.parse()
        |> (fn {i, _r} -> i end).()
      end)
    end)
    |> into_races()
  end

  defp into_races(integer_lines) do
    # TODO: Should error-check to make sure the lines are the same length,
    #       but since we have a short simple input, meh...
    Enum.zip(Enum.at(integer_lines, 0), Enum.at(integer_lines, 1))
    |> Enum.map(fn {t, d} -> %BoatRace{time: t, distance_record: d} end)
    |> Enum.map(&calc_runs/1)
  end

  defp calc_runs(race) do
    all = Enum.map(1..race.time, fn hold_time ->
      BoatRace.Run.build(race.time, hold_time)
    end)

    wins = 
      all
      |> Enum.filter(fn r -> r.distance > race.distance_record end)

    %{race| possible_runs: all, ways_to_win: wins}
  end
end

IO.puts("Parsing note...")
races = 
  File.read!("input")
  |> BoatRace.parse()

IO.puts("Calculating ideal times for each race...")

Enum.each(races, fn r -> 
  IO.puts("#{r.time} millisecond race with previous distance record #{r.distance_record}, can be won in the following #{Enum.count(r.ways_to_win)} ways:")
  IO.inspect(r.ways_to_win)
end)

IO.puts("Margin of error is: #{Enum.reduce(races, 1, fn r, acc -> acc * Enum.count(r.ways_to_win) end)}")

# Got 393120 on the first try, which was right! Yay for brute forcing the problem.
