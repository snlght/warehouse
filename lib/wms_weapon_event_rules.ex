defmodule WMS.WeaponEventRules do
  require EXO

  @allowed_event_types [
    "registered",
    "status_changed",
    "transferred",
    "service_order_created",
    "service_started",
    "service_completed",
    "part_removed",
    "part_installed",
    "part_replaced",
    "issued",
    "returned",
    "decommissioned"
  ]

  @allowed_source_types [
    "weapon",
    "transfer",
    "storage",
    "service_order",
    "service_event",
    "part"
  ]

  def clean(nil), do: ""

  def clean(value) do
    value
    |> :nitro.to_binary()
    |> String.trim()
  end

  def create(fields) do
    with {:ok, fields} <- normalize_fields(fields),
         :ok <- validate_fields(fields),
         {:ok, _weapon} <- get_weapon(fields.weapon) do
      append_event(fields)
    end
  end

  defp normalize_fields(fields) when is_map(fields) do
    now = System.system_time(:millisecond)

    normalized_fields = %{
      weapon: clean(Map.get(fields, :weapon, "")),
      event_type: clean(Map.get(fields, :event_type, "")),
      event_status: clean(Map.get(fields, :event_status, "")),
      actor: clean(Map.get(fields, :actor, "")),
      source_type: clean(Map.get(fields, :source_type, "")),
      source_id: clean(Map.get(fields, :source_id, "")),
      from_storage: clean(Map.get(fields, :from_storage, "")),
      to_storage: clean(Map.get(fields, :to_storage, "")),
      related_service_order: clean(Map.get(fields, :related_service_order, "")),
      related_part: clean(Map.get(fields, :related_part, "")),
      occurred_at: normalize_timestamp(Map.get(fields, :occurred_at, now), now),
      recorded_at: now,
      description: clean(Map.get(fields, :description, ""))
    }

    {:ok, normalized_fields}
  end

  defp normalize_fields(_fields) do
    {:error, "Помилка: некоректний формат події зброї"}
  end

  defp normalize_timestamp(nil, now), do: now
  defp normalize_timestamp("", now), do: now
  defp normalize_timestamp(value, _now) when is_integer(value), do: value
  defp normalize_timestamp(_value, _now), do: :invalid

  defp validate_fields(fields) do
    cond do
      fields.weapon == "" ->
        {:error, "Помилка: ID зброї обов'язковий"}

      fields.event_type == "" ->
        {:error, "Помилка: тип події обов'язковий"}

      fields.event_type not in @allowed_event_types ->
        {:error, "Помилка: невідомий тип події зброї"}

      fields.source_type == "" ->
        {:error, "Помилка: тип джерела події обов'язковий"}

      fields.source_type not in @allowed_source_types ->
        {:error, "Помилка: невідомий тип джерела події зброї"}

      fields.source_id == "" ->
        {:error, "Помилка: ID джерела події обов'язковий"}

      fields.occurred_at == :invalid ->
        {:error, "Помилка: некоректний час події"}

      true ->
        :ok
    end
  end

  defp get_weapon(weapon_id) do
    key =
      weapon_id
      |> clean()
      |> String.to_charlist()

    case :kvs.get(~c"/wms/weapons", key) do
      {:ok, weapon} -> {:ok, weapon}
      {:error, :not_found} -> {:error, "Помилка: зброї з таким ID не існує"}
      {:error, reason} -> {:error, "Помилка читання зброї (#{inspect(reason)})"}
    end
  end

  defp append_event(fields) do
    id = :kvs.seq([], [])

    event =
      EXO.wms_weapon_event(
        id: id,
        weapon: fields.weapon,
        event_type: fields.event_type,
        event_status: fields.event_status,
        actor: fields.actor,
        source_type: fields.source_type,
        source_id: fields.source_id,
        from_storage: fields.from_storage,
        to_storage: fields.to_storage,
        related_service_order: fields.related_service_order,
        related_part: fields.related_part,
        occurred_at: fields.occurred_at,
        recorded_at: fields.recorded_at,
        description: fields.description
      )

    case :kvs.append(event, ~c"/wms/weapon_events") do
      ^id ->
        {:ok, event}

      result ->
        {:error, "Помилка створення події зброї: #{inspect(result)}"}
    end
  end
end
