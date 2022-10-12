defmodule Identicon do
  @moduledoc """
  A module for procedurally generating Identicons, images based on strings to be used for profile pictures until a user uploads their own.
  """
  def main(input) do
    input
    |> hash_input
    |> pick_color
    |> build_grid
    |> filter_odd_squares
    |> build_pixel_map
    |> draw_image
    |> save_image(input)
  end

  @doc """
    Creates an Image struct with hex property equivalent to the list of hashed data from a string.

    ## Examples

      iex> Identicon.hash_input("elixir")
      %Identicon.Image{
        hex: [116, 181, 101, 134, 90, 25, 44, 200, 105, 60, 83, 13, 72, 235, 56, 58],
        color: nil,
        grid: nil,
        pixel_map: nil
      }
  """
  def hash_input(input) do
    hex = :crypto.hash(:md5, input)
    |> :binary.bin_to_list
    %Identicon.Image{hex: hex}
  end

  @doc """
    Returns an updated Image struct with a tuple represnting the RGB values of the color of the Identicon.

    ## Examples

      iex> img = Identicon.hash_input("elixir")
      iex> Identicon.pick_color(img)
      %Identicon.Image{
        hex: [116, 181, 101, 134, 90, 25, 44, 200, 105, 60, 83, 13, 72, 235, 56, 58],
        color: {116, 181, 101},
        grid: nil,
        pixel_map: nil
      }
  """
  def pick_color(%Identicon.Image{hex: [r, g, b | _tail]} = image) do
    %Identicon.Image{image | color: {r, g, b}}
  end

  @doc """
    Returns an updated Image struct with a list of tuples represnting the values and indicies at points of the Identicon.

    ## Examples

      iex> img = Identicon.hash_input("elixir")
      iex> img = Identicon.pick_color(img)
      iex> Identicon.build_grid(img)
      %Identicon.Image{
        hex: [116, 181, 101, 134, 90, 25, 44, 200, 105, 60, 83, 13, 72, 235, 56, 58],
        color: {116, 181, 101},
        grid: [{116, 0}, {181, 1}, {101, 2}, {181, 3}, {116, 4}, {134, 5}, {90, 6}, {25, 7}, {90, 8},
        {134, 9}, {44, 10}, {200, 11}, {105, 12}, {200, 13}, {44, 14}, {60, 15}, {83, 16},
        {13, 17}, {83, 18}, {60, 19}, {72, 20}, {235, 21}, {56, 22}, {235, 23}, {72, 24}],
        pixel_map: nil
      }
  """
  def build_grid(%Identicon.Image{hex: hex} = image) do
    grid =
      hex
      |> Enum.chunk_every(3,3,:discard)
      |> Enum.map(&mirror_row/1)
      |> List.flatten
      |> Enum.with_index
    %Identicon.Image{image | grid: grid }
  end

  @doc """
    Takes a `row` of 3 values and returns a list of 5, mirrored across the last value

    ## Examples

      iex> row = [123, 45, 67]
      iex> Identicon.mirror_row(row)
      [123, 45, 67, 45, 123]

  """
  def mirror_row([first, second | _tail] = row) do
    row ++ [second, first]
  end

  def filter_odd_squares(%Identicon.Image{grid: grid} = image) do
    grid = Enum.filter grid, fn {a, _index} ->
      rem(a, 2) == 0
    end
    %Identicon.Image{image | grid: grid}
  end

  def build_pixel_map(%Identicon.Image{grid: grid} = image) do
    pixel_map =
      grid
      |> Enum.map(fn {_code, index} ->
        {50 * rem(index, 5), 50 * div(index, 5)}
      end)
      |> Enum.map(fn {x,y} = point ->
        {point, {x + 50, y + 50}}
      end)
    %Identicon.Image{image | pixel_map: pixel_map}
  end

  def draw_image(%Identicon.Image{color: color, pixel_map: pixel_map}) do
    image = :egd.create(250,250)
    fill = :egd.color(color)

    Enum.each(pixel_map, fn {start, stop} ->
      :egd.filledRectangle(image, start, stop, fill)
    end)

    :egd.render(image)
  end

  def save_image(image,input) do
    File.write("img/#{input}.png",image)
  end
end
