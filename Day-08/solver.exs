defmodule NetMap do
  defstruct instructions: [], map: %{}

  def count_walk_length(m) do
    Stream.cycle(m.instructions)
    |> Enum.reduce_while({"AAA", 0}, fn i, {cur_step, count} ->
      if(cur_step == "ZZZ") do
        {:halt, count}
      else
        {n_left, n_right} = m.map[cur_step] 
        next_step = case i do
          "L" -> n_left
          "R" -> n_right
        end
        {:cont, {next_step, count+1}}
      end
    end)
  end

  def from_file(filename) do
    File.read!(filename)
    |> String.trim()
    |> String.split("\n")
    |> parse_map()
  end

  defp parse_map(file_string_array) do
    %NetMap{
      instructions: Enum.at(file_string_array, 0) |> String.graphemes(),
      map: map_from_lines(Enum.drop(file_string_array, 2))
    }
  end

  defp map_from_lines(lines) do
    Map.new(lines, fn line ->
      parsed = line
               |> String.trim()
               |> String.split()

      {Enum.at(parsed, 0),
        {
          Enum.at(parsed, 2) |> String.graphemes() |> Enum.slice(1,3) |> Enum.join(),
          Enum.at(parsed, 3) |> String.graphemes() |> Enum.slice(0,3) |> Enum.join()
        }
      }
    end)
  end
end

IO.puts("Parsing NetMap")
m = NetMap.from_file("input")

IO.puts("Calculating number of steps to get to ZZZ:")
NetMap.count_walk_length(m)
|> IO.inspect

# Got 19637, which was right!
# The valuable thing I learned from this one was Stream.cycle. Hadn't used that
# before, and it was exactly what I needed to easily loop the instruction set.
