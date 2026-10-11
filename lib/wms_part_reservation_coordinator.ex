defmodule WMS.PartReservationCoordinator do
 use GenServer

 def start_link(opts \\ []) do
  GenServer.start_link(__MODULE__, opts, name: __MODULE__)
 end

 @impl true
 def init(_opts) do
  {:ok, %{}}
 end

 def reserve(requirement_id, part_id, reserved_by) do
  GenServer.call(
    __MODULE__,
    {:reserve, requirement_id, part_id, reserved_by}
  )
 end

 @impl true
 def handle_call(
    {:reserve, requirement_id, part_id, reserved_by},
    _from,
    state
 ) do
  case WMS.PartReservationRules.reserve(
  requirement_id,
   part_id,
   reserved_by
   ) do
    {:ok, reservation, reserved_requirement} ->
      case WMS.PartReservationStorage.persist_reservation(reservation, reserved_requirement) do
        :ok ->
          {:reply, {:ok, reservation}, state}

        {:error, reason} ->
          {:reply, {:error, reason}, state}
      end

    {:error, reason} ->
      {:reply, {:error, reason}, state}
    end
  end

 end
