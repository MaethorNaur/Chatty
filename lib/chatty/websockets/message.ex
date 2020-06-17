defmodule Chatty.Websockets.Message do
  @moduledoc false
  @derive Jason.Encoder
  defstruct [:date, :from, :to, :message]

  @type t :: %__MODULE__{
          from: String.t(),
          to: String.t(),
          message: String.t(),
          date: DateTime.t()
        }
end
