defmodule WMS.PartReservationStorage do
  require EXO

  defp clean(nil), do: ""

  defp clean(value) do
    value
    |> :nitro.to_binary()
    |> String.trim()
  end

  def get_active_by_part(part_id) do
    key = active_part_key(part_id)
    db = :kvs_rocks.ref()

    case :rocksdb.get(db, key, []) do
      {:ok, reservation_id} ->
        {:ok, reservation_id}

      :not_found ->
        {:error, :not_found}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def get_active_by_requirement(requirement_id) do
    key = active_requirement_key(requirement_id)
    db = :kvs_rocks.ref()

    case :rocksdb.get(db, key, []) do
      {:ok, reservation_id} ->
        {:ok, reservation_id}

      :not_found ->
        {:error, :not_found}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp active_part_key(part_id) do
    part_id = clean(part_id)

    <<"wms:part_reservation:active:part:", part_id::binary>>
  end

  defp active_requirement_key(requirement_id) do
    requirement_id = clean(requirement_id)

    <<"wms:part_reservation:active:requirement:", requirement_id::binary>>
  end

  defp put_active_part(part_id, reservation_id) do
    key = active_part_key(part_id)
    value = clean(reservation_id)
    db = :kvs_rocks.ref()

    case :rocksdb.put(db, key, value, [{:sync, true}]) do
      :ok ->
        :ok

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp put_active_requirement(requirement_id, reservation_id) do
    key = active_requirement_key(requirement_id)
    value = clean(reservation_id)

    db = :kvs_rocks.ref()

    case :rocksdb.put(db, key, value, [{:sync, true}]) do
      :ok ->
        :ok

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp add_active_part_guard(batch, part_id, reservation_id) do
    key = active_part_key(part_id)
    value = clean(reservation_id)

    :rocksdb.batch_put(batch, key, value)
  end

  defp add_active_requirement_guard(batch, requirement_id, reservation_id) do
    key = active_requirement_key(requirement_id)
    value = clean(reservation_id)

    :rocksdb.batch_put(batch, key, value)
  end

  defp add_reserved_requirement(batch, reserved_requirement) do
    requirement_id =
      reserved_requirement
      |> EXO.wms_part_requirement(:id)
      |> clean()

    key =
      :kvs_rocks.key(
        ~c"/wms/part_requirements",
        requirement_id
      )

    value = :erlang.term_to_binary(reserved_requirement)

    :rocksdb.batch_put(batch, key, value)
  end

  defp reservation_key(reservation_id) do
    reservation_id = clean(reservation_id)

    <<"wms:part_reservation:record:", reservation_id::binary>>
  end

  defp add_reservation(batch, reservation) do
    reservation_id =
      reservation
      |> EXO.wms_part_reservation(:id)
      |> clean()

    key = reservation_key(reservation_id)
    value = :erlang.term_to_binary(reservation)

    :rocksdb.batch_put(batch, key, value)
  end

  def persist_reservation(reservation, reserved_requirement) do
    {:ok, batch} = :rocksdb.batch()

    db = :kvs_rocks.ref()

    try do
      result = fill_reservation_batch(batch, reservation, reserved_requirement)

      case result do
        :ok ->
          :rocksdb.write_batch(db, batch, [{:sync, true}])

        {:error, reason} ->
          {:error, reason}
      end
    after
      :rocksdb.release_batch(batch)
    end
  end

  defp fill_reservation_batch(batch, reservation, reserved_requirement) do
    reservation_id =
      reservation
      |> EXO.wms_part_reservation(:id)
      |> clean()

    part_id =
      reservation
      |> EXO.wms_part_reservation(:part)
      |> clean()

    requirement_id =
      reservation
      |> EXO.wms_part_reservation(:part_requirement)
      |> clean()

    with :ok <- add_reservation(batch, reservation),
         :ok <- add_active_part_guard(batch, part_id, reservation_id),
         :ok <- add_active_requirement_guard(batch, requirement_id, reservation_id),
         :ok <- add_reserved_requirement(batch, reserved_requirement) do
      :ok
    end
  end
end
