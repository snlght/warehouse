defmodule WMS.IdempotencyStorage do
  def key(:service_order, command_id) do
    "wms:idempotency:service_order:" <> command_id
  end

  def get(:service_order, command_id) do
    db = :kvs_rocks.ref()
    key = key(:service_order, command_id)

    case :rocksdb.get(db, key, []) do
      {:ok, value} ->
        {:ok, :erlang.binary_to_term(value)}

      :not_found ->
        {:error, :not_found}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def put(:service_order, command_id, business_number) do
    db = :kvs_rocks.ref()
    key = key(:service_order, command_id)
    value = :erlang.term_to_binary(business_number)

    :rocksdb.put(db, key, value, [{:sync, true}])
  end
end
