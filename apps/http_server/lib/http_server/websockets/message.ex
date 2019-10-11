defmodule HttpServer.Websockets.Message do
  @moduledoc false
  defstruct [:to, :message]
  def parse(string, mode \\ :none)

  def parse(" " <> rest, {:to, to}),
    do: {:ok, %__MODULE__{to: Enum.reverse(to) |> to_string, message: rest}}

  def parse("", {:to, to}),
    do: {:ok, %__MODULE__{to: Enum.reverse(to) |> to_string, message: ""}}

  def parse(" " <> rest, :none), do: parse(rest, :none)
  def parse(">" <> rest, :none), do: parse(rest, {:to, []})

  def parse(<<letter::bytes-size(1)>> <> rest, {:to, user}),
    do: parse(rest, {:to, [letter | user]})

  def parse(">" <> _, _none), do: {:error, "parse error"}
  def parse(_, :none), do: {:error, "parse error"}
end
