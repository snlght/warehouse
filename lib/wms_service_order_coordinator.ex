defmodule WMS.ServiceOrderCoordinator do
  require EXO
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts), do: {:ok, %{}}

  def create(command_id, fields) do
    GenServer.call(__MODULE__, {:create, command_id, fields})
  end

  def void(command_id, reason, actor) do
    GenServer.call(__MODULE__, {:void, command_id, reason, actor})
  end

  @impl true
  def handle_call({:void, command_id, reason, actor}, _from, state) do
    case WMS.IdempotencyStorage.get(:service_order, command_id) do
      {:ok, business_number} ->
        case WMS.ServiceEventRules.get_service_order(business_number) do
          {:ok, _order} ->
            {:reply, {:error, {:service_order_exists, business_number}}, state}
          {:error, _reason} ->
            case void_number(business_number, reason, actor) do
              :ok ->
                {:reply, {:ok, business_number}, state}

              {:error, reason} ->
                {:reply, {:error, reason}, state}
            end
        end
        {:error, reason} ->
          {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:create, command_id, fields}, _from, state) do
    case WMS.IdempotencyStorage.get(:service_order, command_id) do
      {:ok, business_number} ->
        case WMS.ServiceEventRules.get_service_order(business_number) do
          {:ok, order} ->
            {:reply, {:ok, :existing, order}, state}

          {:error, _reason} ->
            case WMS.BusinessNumberStorage.get_record(:service_order, business_number) do
              {:ok, record} ->
                case EXO.wms_business_number(record, :status) do
                  "pending" ->
                    case create_reserved_order(business_number, fields) do
                      {:ok, order} ->
                        {:reply, {:ok, :created, order}, state}

                      {:error, reason} ->
                        {:reply, {:error, reason}, state}
                    end

                  "committed" ->
                    {:reply, {:error, {:committed_order_missing, business_number}}, state}

                  "void" ->
                    {:reply, {:error, {:void_business_number, business_number}}, state}

                  status ->
                    {:reply, {:error, {:unknown_number_status, status}}, state}
                end

              {:error, reason} ->
                {:reply, {:error, reason}, state}
            end
        end

      {:error, :not_found} ->
        case WMS.BusinessNumber.service_order_candidate() do
          {:ok, number, business_number} ->
            case reserve_number(command_id, number, business_number) do
              :ok ->
                case create_reserved_order(business_number, fields) do
                  {:ok, order} ->
                    {:reply, {:ok, :created, order}, state}

                  {:error, reason} ->
                    {:reply, {:error, reason}, state}
                end

              {:error, reason} ->
                {:reply, {:error, reason}, state}
            end

          {:error, reason} ->
            {:reply, {:error, reason}, state}
        end

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  defp build_order(business_number, fields) do
    EXO.wms_service_order(
      id: business_number,
      weapon: fields.weapon,
      reason: fields.reason,
      received_by: fields.received_by,
      service_status: "Init",
      result: ""
    )
  end

  defp reserve_number(command_id, number, business_number) do
    {:ok, batch} = :rocksdb.batch()
    db = :kvs_rocks.ref()

    try do
      idempotency_key = WMS.IdempotencyStorage.key(:service_order, command_id)

      idempotency_value = :erlang.term_to_binary(business_number)

      :rocksdb.batch_put(
        batch,
        idempotency_key,
        idempotency_value
      )

      record =
        WMS.BusinessNumberRules.build_pending(
          "service_order",
          number,
          business_number,
          command_id
        )

      record_key =
        WMS.BusinessNumberStorage.record_key(
          :service_order,
          business_number
        )

      record_value = :erlang.term_to_binary(record)

      :rocksdb.batch_put(
        batch,
        record_key,
        record_value
      )

      counter_key = WMS.BusinessNumberStorage.key(:service_order)

      counter_value = :erlang.term_to_binary(number)

      :rocksdb.batch_put(
        batch,
        counter_key,
        counter_value
      )

      :rocksdb.write_batch(db, batch, [{:sync, true}])
    after
      :rocksdb.release_batch(batch)
    end
  end

  defp commit_number(business_number, target_id) do
    with {:ok, record} <-
           WMS.BusinessNumberStorage.get_record(:service_order, business_number),
         {:ok, committed} <-
           WMS.BusinessNumberRules.commit(record, target_id),
         :ok <-
           WMS.BusinessNumberStorage.put_record(
             :service_order,
             business_number,
             committed
           ) do
      :ok
    end
  end

  defp void_number(business_number, reason, actor) do
    with {:ok, record} <-
           WMS.BusinessNumberStorage.get_record(:service_order, business_number),
         {:ok, voided} <-
           WMS.BusinessNumberRules.void(record, reason, actor),
         :ok <-
           WMS.BusinessNumberStorage.put_record(
             :service_order,
             business_number,
             voided
           ) do
      :ok
    end
  end

  defp persist_order(order) do
    business_number = EXO.wms_service_order(order, :id)

    case :kvs.append(order, ~c"/wms/service_orders") do
      ^business_number ->
        :ok

      result ->
        {:error, {:service_order_write_failed, result}}
    end
  end

  defp create_reserved_order(business_number, fields) do
    order = build_order(business_number, fields)

    with :ok <- persist_order(order),
         :ok <- commit_number(business_number, business_number) do
      {:ok, order}
    end
  end
end
