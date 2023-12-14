defmodule Almanac.MapLine do
  defstruct destination_range_start: nil,
    source_range_start: nil,
    length: nil

  def parse(line) do
    values = 
      line
      |> String.split(" ")
      |> Enum.map(&Integer.parse/1)
      |> Enum.map(fn {i, _rem} -> i end)

    %Almanac.MapLine{
      destination_range_start: Enum.at(values, 0),
      source_range_start: Enum.at(values, 1),
      length: Enum.at(values, 2),
    }
  end
end

defmodule Almanac.Map do
  defstruct name: nil,
    lines: []

  def parse(str) do
    if String.starts_with?(str, "seeds:") do
      %Almanac.Map{
        name: "seeds",
        lines: 
          str
          |> String.split("seeds: ")
          |> Enum.at(1)
          |> String.trim()
          |> String.split(" ")
          |> Enum.map(&Integer.parse/1)
          |> Enum.map(fn {i, _rem} -> i end)
      }
    else
      str
      |> String.trim()
      |> String.split("\n")
      |> build()
    end
  end

  def destination(source, map) do
    lines_containing_source =
      Enum.filter(map.lines, fn l ->
        source >= l.source_range_start && source < (l.source_range_start + l.length)
      end)

    case Enum.count(lines_containing_source) do
      c when c > 1 ->
        IO.puts("ERROR: Found multiple ranges containing source #{source}: #{inspect lines_containing_source}")
        :error
      c when c == 1 ->
        l = Enum.at(lines_containing_source, 0)
        offset = source - l.source_range_start
        l.destination_range_start + offset
      _ -> source
    end


  end

  defp build([name | lines]) do
    %Almanac.Map{
      name: name 
            |> String.split(" ")
            |> Enum.at(0),
      lines: Enum.map(lines, fn l -> Almanac.MapLine.parse(l) end),
    }
  end
end

defmodule Almanac do
  defstruct seeds: [],
    seedToSoil: %Almanac.Map{},
    soilToFertilizer: %Almanac.Map{},
    fertilizerToWater: %Almanac.Map{},
    waterToLight: %Almanac.Map{},
    lightToTemperature: %Almanac.Map{},
    temperatureToHumidity: %Almanac.Map{},
    humidityToLocation: %Almanac.Map{}

  def from_file(filename) do
    File.read!(filename)
    |> parse()
  end

  def parse(str) do
    str
    |> String.split("\n\n")
    |> Enum.map(&Almanac.Map.parse/1)
    |> build()
  end

  def location_for_seed(seed, almanac) do
    Almanac.Map.destination(seed, almanac.seedToSoil)
    |> Almanac.Map.destination(almanac.soilToFertilizer)
    |> Almanac.Map.destination(almanac.fertilizerToWater)
    |> Almanac.Map.destination(almanac.waterToLight)
    |> Almanac.Map.destination(almanac.lightToTemperature)
    |> Almanac.Map.destination(almanac.temperatureToHumidity)
    |> Almanac.Map.destination(almanac.humidityToLocation)
  end

  defp build(sections) do
    %Almanac{
      seeds: Enum.find(sections, fn s -> s.name == "seeds" end),
      seedToSoil: Enum.find(sections, fn s -> s.name == "seed-to-soil" end),
      soilToFertilizer: Enum.find(sections, fn s -> s.name == "soil-to-fertilizer" end),
      fertilizerToWater: Enum.find(sections, fn s -> s.name == "fertilizer-to-water" end),
      waterToLight: Enum.find(sections, fn s -> s.name == "water-to-light" end),
      lightToTemperature: Enum.find(sections, fn s -> s.name == "light-to-temperature" end),
      temperatureToHumidity: Enum.find(sections, fn s -> s.name == "temperature-to-humidity" end),
      humidityToLocation: Enum.find(sections, fn s -> s.name == "humidity-to-location" end),
    }
  end

end

input_file = System.argv |> Enum.at(0) || "input"
IO.puts("Parsing almanac file #{input_file}...")
almanac = Almanac.from_file(input_file)

#IO.puts("TESTS:")
#IO.puts("#{Almanac.Map.destination(0, almanac.soilToFertilizer)} should == 1026018636")
#IO.puts("#{Almanac.Map.destination(2547368955, almanac.soilToFertilizer)} should == 0")

IO.puts("Lowest available location is:")
almanac.seeds.lines
|> Enum.map(fn s -> Almanac.location_for_seed(s, almanac) end)
|> Enum.sort()
|> List.first()
|> IO.inspect()

# Got 111627841, which was correct! First try!


