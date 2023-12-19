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

  def count_ghost_walk_length(net_map, start_node) do
    Stream.cycle(net_map.instructions)
    |> Enum.reduce_while({start_node, 0}, fn i, {cur_step, count} ->
      if(cur_step |> String.graphemes |> Enum.at(2) == "Z") do
        {:halt, count}
      else
        {n_left, n_right} = net_map.map[cur_step] 
        next_step = case i do
          "L" -> n_left
          "R" -> n_right
        end
        {:cont, {next_step, count+1}}
      end
    end)
  end

  def min_ghost_walk_length(net_map) do
    starting_nodes = 
      net_map.map
      |> Map.keys()
      |> Enum.filter(fn node -> 
        String.graphemes(node) |> Enum.at(2) == "A"
      end)
      |> Enum.map(&Task.async(NetMap, :count_ghost_walk_length, [net_map, &1]))
      |> Enum.map(&Task.await/1)
      |> get_lcm_for_list()

    # Brute force is fun, let's just show an example of it...
    #Stream.cycle(net_map.instructions)
    #|> Enum.reduce_while({starting_nodes, 0}, fn(i, {cur_nodes, count}) ->
      #if all_steps_end_in_z(cur_nodes) do
        #{:halt, count}
      #else
        #next_nodes = Enum.map(cur_nodes, fn c -> get_next_node(net_map.map, c, i) end)

        #IO.write("\r#{count} - #{inspect(next_nodes)}")
        #{:cont, {next_nodes, count+1}}
      #end
    #end)
  end

  def get_lcm_for_list([h | t]) when length(t) == 1, do: lcm(h, Enum.at(t, 0))
  def get_lcm_for_list([h | t]) do
    lcm(h, get_lcm_for_list(t))
  end

  def gcd(a, 0), do: a
	def gcd(0, b), do: b
	def gcd(a, b), do: gcd(b, rem(a,b))
	
	def lcm(0, 0), do: 0
  def lcm(a, b), do: (a*b)/gcd(a,b) |> trunc()

  defp all_steps_end_in_z(node_list) do
    node_list
    |> Enum.map(fn n -> String.graphemes(n) |> List.last() == "Z" end)
    |> Enum.uniq
    == [true]
  end

  defp get_next_node(map, current, instruction) do
    case instruction do
      "L" -> elem(map[current], 0)
      "R" -> elem(map[current], 1)
    end
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
# Combined with a reduce_while it made a super easy way to handle an unknown
# size list.

IO.puts("Okay, so now we'll try it the ghosty way from all nodes ending in A to a place where all nodes end in Z...")
NetMap.min_ghost_walk_length(m)
|> IO.inspect(label: "Number of steps")

# Got 8811050362409, which was right! That's 8_811_050_362_409. That's 8.8 TRILLION.
# For an curiosity, I let the brute-force method run for 9.5 hours on the
# laptop. It only got up to 1_525_227_030, so it would've had to run for 2286 *DAYS*
# to successfully find the result.
# 
# This is why we prefer shortcuts and not having to iterate everything! 
