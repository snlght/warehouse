defmodule WMS.ServiceEventRules do
  require EXO

  @removed_part_status "removed"
  @installed_part_status "installed"
  @installable_part_statuses ["spare", "removed"]
  @required_fields [
    :service_order,
    :weapon,
    :event_type,
    :actor,
    :event_status
  ]
  @optional_fields [
    :old_part,
    :new_part
  ]

  def clean(value) do
    value
    |> :nitro.to_binary()
    |> String.trim()
  end

  def blank?(value), do: clean(value) == ""

  def normalize_fields(fields) when is_map(fields) do
    normalized =
      (@required_fields ++ @optional_fields)
      |> Map.new(fn key ->
        {key, fields |> Map.get(key, "") |> clean()}
      end)

    validate_required_fields(normalized)
  end

  def normalize_fields(_fields) do
    {:error, "Помилка: некоректний формат даних"}
  end

  def validate_required_fields(fields) do
    cond do
      fields.service_order == "" ->
        {:error, "Помилка: сервісний наряд обов'язковий"}

      fields.weapon == "" ->
        {:error, "Помилка: ID зброї обов'язковий"}

      fields.event_type == "" ->
        {:error, "Помилка: тип події обов'язковий"}

      fields.actor == "" ->
        {:error, "Помилка: виконавець обов'язковий"}

      fields.event_status == "" ->
        {:error, "Помилка: статус події обов'язковий"}

      true ->
        {:ok, fields}
    end
  end

  def validate_references(
        fields,
        %{old_part: old_part, new_part: new_part, weapon: weapon, service_order: service_order}
      ) do
    cond do
      is_nil(service_order) ->
        {:error, "Помилка: сервісного наряду не існує"}

      is_nil(weapon) ->
        {:error, "Помилка: зброї з таким ID не існує"}

      fields.old_part != "" and is_nil(old_part) ->
        {:error, "Помилка: старої деталі не існує"}

      fields.new_part != "" and is_nil(new_part) ->
        {:error, "Помилка: нової деталі не існує"}

      fields.old_part != "" and
        fields.new_part != "" and
          fields.old_part == fields.new_part ->
        {:error, "Помилка: стара і нова деталі не можуть бути однаковими"}

      not is_nil(new_part) and not part_installable_record?(new_part) ->
        {:error, "Помилка: нову деталь з таким статусом не можна встановити"}

      not is_nil(new_part) and
          part_weapon_id(new_part) == fields.weapon ->
        {:error, "Помилка: нова деталь вже встановлена в цій зброї"}

      not is_nil(old_part) and
          part_weapon_id(old_part) != fields.weapon ->
        {:error, "Помилка: стара деталь не належить цій зброї"}

      not is_nil(new_part) and
        part_weapon_id(new_part) != "" and
          part_weapon_id(new_part) != fields.weapon ->
        {:error, "Помилка: нова деталь вже встановлена в іншій зброї"}

      true ->
        :ok
    end
  end

  defp part_weapon_id(part) do
    part
    |> EXO.wms_part(:installed_in_weapon)
    |> clean()
  end

  defp part_installable_record?(part) do
    part
    |> EXO.wms_part(:part_status)
    |> clean()
    |> then(&(&1 in @installable_part_statuses))
  end

  def validate_create(fields) do
    with {:ok, fields} <- normalize_fields(fields),
         {:ok, context} <- load_context(fields),
         :ok <- validate_references(fields, context) do
      {:ok, fields, context}
    end
  end

  def create_service_event(fields) do
    with {:ok, fields, context} <- validate_create(fields),
         :ok <- update_parts(context.old_part, context.new_part, fields.weapon) do
      id = :kvs.seq([], [])

      event =
        EXO.wms_service_event(
          id: id,
          service_order: fields.service_order,
          weapon: fields.weapon,
          event_type: fields.event_type,
          actor: fields.actor,
          event_status: fields.event_status,
          old_part: fields.old_part,
          new_part: fields.new_part
        )

      :kvs.append(event, ~c"/wms/service_events")
      {:ok, event}
    end
  end

  def remove_part_from_weapon(part) do
    updated_part =
      EXO.wms_part(
        part,
        installed_in_weapon: "",
        part_status: @removed_part_status
      )

    replace_part(part, updated_part)
  end

  def install_part_on_weapon(part, weapon_id) do
    updated_part =
      EXO.wms_part(
        part,
        installed_in_weapon: weapon_id,
        part_status: @installed_part_status
      )

    replace_part(part, updated_part)
  end

  def update_parts(nil, nil, _weapon_id), do: :ok

  def update_parts(old_part, nil, _weapon_id) do
    remove_part_from_weapon(old_part)
  end

  def update_parts(nil, new_part, weapon_id) do
    install_part_on_weapon(new_part, weapon_id)
  end

  def update_parts(old_part, new_part, weapon_id) do
    with :ok <- remove_part_from_weapon(old_part),
         :ok <- install_part_on_weapon(new_part, weapon_id) do
      :ok
    end
  end

  defp load_context(fields) do
    parts = :kvs.all(~c"/wms/parts")
    weapons = :kvs.all(~c"/wms/weapons")
    service_orders = :kvs.all(~c"/wms/service_orders")

    {:ok,
     %{
       weapon: find_weapon_in(weapons, fields.weapon),
       service_order: find_service_order_in(service_orders, fields.service_order),
       old_part: find_part_in(parts, fields.old_part),
       new_part: find_part_in(parts, fields.new_part)
     }}
  end

  defp find_part_in(_parts, ""), do: nil

  defp find_part_in(parts, serial_number) do
    Enum.find(parts, fn part ->
      part_serial =
        part
        |> EXO.wms_part(:serial_number)
        |> clean()

      part_serial == serial_number
    end)
  end

  defp find_weapon_in(weapons, weapon_id) do
    Enum.find(weapons, fn weapon ->
      current_weapon_id =
        weapon
        |> EXO.wms_weapon(:id)
        |> clean()

      current_weapon_id == weapon_id
    end)
  end

  defp find_service_order_in(service_orders, service_order_id) do
    Enum.find(service_orders, fn order ->
      current_service_order_id =
        order
        |> EXO.wms_service_order(:id)
        |> clean()

      current_service_order_id == service_order_id
    end)
  end

  defp replace_part(old_part, updated_part) do
    :kvs.remove(old_part, ~c"/wms/parts")
    :kvs.append(updated_part, ~c"/wms/parts")
    :ok
  end
end
