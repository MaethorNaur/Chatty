defmodule Chatty.Websockets.Handler do
  @behaviour :cowboy_websocket
  @moduledoc false

  @all {:room, "all"}
  @timeout 60_000

  alias Chatty.Websockets.Message
  require Logger

  @impl true
  def init(req, state),
    do: :cowboy_req.match_qs([:user], req) |> get_username() |> init(req, state)

  @spec init({:ok, String.t()} | :error, any(), any()) :: any()
  def init({:ok, user}, req, _state),
    do: {:cowboy_websocket, req, user, %{:idle_timeout => @timeout}}

  def init(:error, req, state), do: {:ok, :cowboy_req.reply(400, req), state}

  defp get_username(%{:user => user}) when user != "", do: {:ok, user}
  defp get_username(_), do: :error

  defp join(user) do
    group = {:ws, user}
    :ok = :pg2.create(@all)
    :ok = :pg2.create(group)

    case :pg2.get_members(group) do
      {:error, _} -> sent_joined(user)
      [] -> sent_joined(user)
      _ -> nil
    end

    _ = :pg2.join(@all, self())
    _ = :pg2.join(group, self())
    send(self(), :list_rooms_with_users)
  end

  @spec sent_joined(user :: String.t()) :: no_return
  defp sent_joined(user), do: get_pids(@all) |> Enum.each(&send(&1, {:joined, "all", user}))

  @spec all() :: {:room, String.t()}
  def all, do: @all

  @spec list_rooms_with_users() :: map()
  defp list_rooms_with_users do
    %{room: rooms, ws: users} = :pg2.which_groups() |> Enum.group_by(&elem(&1, 0))

    rooms
    |> Enum.map(fn room = {_, room_name} ->
      users_list =
        get_pids(room)
        |> Enum.flat_map(&find_user_from_pid(users, &1))
        |> Enum.uniq()

      {room_name, users_list}
    end)
    |> Enum.into(%{})
  end

  @spec find_user_from_pid(tuple :: {:ws, String.t()} | [{:ws, String.t()}], pid()) :: [
          String.t()
        ]
  defp find_user_from_pid(users, pid) when is_list(users),
    do: users |> Enum.flat_map(&find_user_from_pid(&1, pid))

  defp find_user_from_pid(tuple = {_, user}, pid) do
    exists? = tuple |> get_pids() |> Enum.find(&(&1 == pid))

    case exists? do
      nil ->
        []

      _ ->
        [user]
    end
  end

  defp quit(user), do: {:ws, user} |> :pg2.get_members() |> delete(user)

  defp delete([], user), do: :pg2.delete({:ws, user})
  defp delete({:error, {:no_such_group, _}}, _user), do: :error
  defp delete(_pids, _user), do: :error

  defp send_to(message = %Message{to: to}),
    do: to |> get_pids() |> Enum.each(&send(&1, message))

  defp get_pids(tuple = {atom, _}) when is_atom(atom) do
    case :pg2.get_members(tuple) do
      {:error, _} -> []
      pids -> pids
    end
  end

  defp get_pids(user_or_room) do
    case get_pids({:ws, user_or_room}) do
      [] ->
        get_pids({:room, user_or_room})

      pids ->
        pids
    end
  end

  @impl true
  def websocket_init(state) do
    join(state)
    Logger.info("connected", user: state)
    {:ok, state, :hibernate}
  end

  @impl true
  def websocket_handle({:ping, message}, state), do: {:reply, {:pong, message}, state, :hibernate}

  @impl true
  def websocket_handle(:ping, state), do: {:reply, :pong, state, :hibernate}

  @impl true
  def websocket_handle({:text, "ping"}, state), do: {:reply, :pong, state, :hibernate}

  def websocket_handle({:text, raw_message}, state) do
    Logger.debug(raw_message, user: state)

    case Jason.decode(raw_message) do
      {:ok, %{"message" => message, "to" => to}} ->
        send_to(%Message{from: state, date: DateTime.utc_now(), to: to, message: message})
        {:ok, state, :hibernate}

      {:error, error} ->
        {:reply, {:text, Jason.encode!(%{error: error})}, state, :hibernate}
    end
  end

  @impl true
  def websocket_info(:list_rooms_with_users, state),
    do:
      {:reply, {:text, Jason.encode!(%{type: "list", data: %{rooms: list_rooms_with_users()}})},
       state, :hibernate}

  def websocket_info({:joined, room, user}, state),
    do:
      {:reply, {:text, Jason.encode!(%{type: "join", data: %{user: user, room: room}})}, state,
       :hibernate}

  def websocket_info({:left, room, user}, state),
    do:
      {:reply, {:text, Jason.encode!(%{type: "left", data: %{user: user, room: room}})}, state,
       :hibernate}

  @impl true
  def websocket_info(message = %Message{to: to}, state) when to != state,
    do: {:reply, {:text, Jason.encode!(%{type: "message", data: message})}, state, :hibernate}

  def websocket_info(_, state),
    do: {:ok, state, :hibernate}

  @impl true
  def terminate(_reason, _req, state) do
    Logger.info("disconnected", user: state)
    get_pids(@all) |> Enum.each(&send(&1, {:left, "all", state}))

    case quit(state) do
      :ok ->
        Logger.debug("group destroy", user: state)

      :error ->
        Logger.debug("No deleted", user: state)
    end

    :ok
  end
end
