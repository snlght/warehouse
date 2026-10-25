defmodule WMS.BusinessNumberStorage do
  def key(:service_order) do
    "wms:business_number:service_order"
  end

  def current(:service_order) do
    db = :kvs_rocks.ref()
    key = key(:service_order)

    case :rocksdb.get(db, key, []) do
      {:ok, value} ->
        {:ok, :erlang.binary_to_term(value)}

      :not_found ->
        {:ok, 0}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def put_current(:service_order, number) do
    db = :kvs_rocks.ref()
    key = key(:service_order)
    value = :erlang.term_to_binary(number)

    :rocksdb.put(db, key, value, [])
  end

  def record_key(:service_order, business_number) do
    "wms:business_number:service_order:" <> business_number
  end

  def get_record(:service_order, business_number) do
    db = :kvs_rocks.ref()
    key = record_key(:service_order, business_number)

    case :rocksdb.get(db, key, []) do
      {:ok, value} ->
        {:ok, :erlang.binary_to_term(value)}

      :not_found ->
        {:error, :not_found}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def put_record(:service_order, business_number, record) do
    db = :kvs_rocks.ref()
    key = record_key(:service_order, business_number)
    value = :erlang.term_to_binary(record)

    :rocksdb.put(db, key, value, [{:sync, true}])
  end
end
