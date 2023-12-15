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
  defstruct time: 0, distance_record: 0, ways_to_win: 0

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
    win_count = Enum.reduce(1..race.time, 0, fn hold_time, acc ->
      r = BoatRace.Run.build(race.time, hold_time)

      case r.distance > race.distance_record do
        true -> acc + 1
        false -> acc
      end
    end)

    %{race| ways_to_win: win_count}
  end
end

IO.puts("Parsing note...")
races = 
  File.read!("input")
  |> BoatRace.parse()

IO.puts("Calculating ideal times for each race...")

Enum.each(races, fn r -> 
  IO.puts("#{r.time} millisecond race with previous distance record #{r.distance_record}, can be won in the following #{r.ways_to_win} ways:")
end)

IO.puts("Margin of error is: #{Enum.reduce(races, 1, fn r, acc -> acc * r.ways_to_win end)}")

# Got 393120 on the first try, which was right! Yay for brute forcing the problem.

# Okay, so part 2 is just another attempt to run my laptop out of ram, or force
# me to actually not brute-force the problem...
# But guess what?! We're gonna brute force it anyway! Suck it laptop!
# What I *should* do is at least minimize the number of attempts by calculating
# the minimum hold-down time required, and only calculating races from that
# to the first hold-down time that fails to beat the record...

# First we'll just rewrite the input file to be the single race.
one_race = File.read!("input")
           |> String.split("\n")
           |> Enum.map(fn l -> 
             split_line = String.split(l)
             prefix = Enum.at(split_line, 0)

             val = 
               split_line
               |> Enum.drop(1)
               |> Enum.join()

             "#{prefix}  #{val}"
           end)
           |> Enum.join("\n")

IO.puts("Re-running, because elves continue to be impossible to read, with the following data:")
IO.puts(one_race)

big_race = one_race
           |> BoatRace.parse()
           |> List.first()

IO.puts("This race can be won in #{big_race.ways_to_win} ways.")

# Which was 36872656, which was correct.... And it only took a about a second to run.
# Huzzah for not wasting time on premature optimization.
