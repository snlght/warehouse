defmodule WMS.ServiceEventRules do
  require EXO

  @removed_part_status "removed"
  @installed_part_status "installed"
  @installable_part_statuses ["spare", "removed"]
  @required_fields [
    :service_order,
    :event_type,
    :actor,
    :event_status
  ]
  @optional_fields [
    :condition,
    :required_action,
    :result,
    :old_part,
    :new_part
  ]

  def clean(value) do
    value
    |> :nitro.to_binary()
    |> String.trim()
  end

  defp normalize_fields(fields) when is_map(fields) do
    normalized =
      (@required_fields ++ @optional_fields)
      |> Map.new(fn key ->
        {key, fields |> Map.get(key, "") |> clean()}
      end)

    validate_required_fields(normalized)
  end

  defp normalize_fields(_fields) do
    {:error, "Помилка: некоректний формат даних"}
  end

  defp validate_required_fields(fields) do
    cond do
      fields.service_order == "" ->
        {:error, "Помилка: сервісний наряд обов'язковий"}

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

  defp validate_references(
         fields,
         %{
           old_part: old_part,
           new_part: new_part,
           weapon: weapon,
           weapon_id: weapon_id,
           service_order: service_order
         }
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

      not is_nil(old_part) and
          part_weapon_id(old_part) != weapon_id ->
        {:error, "Помилка: стара деталь не належить цій зброї"}

      not is_nil(new_part) and
          part_weapon_id(new_part) == weapon_id ->
        {:error, "Помилка: нова деталь вже встановлена в цій зброї"}

      not is_nil(new_part) and
        part_weapon_id(new_part) != "" and
          part_weapon_id(new_part) != weapon_id ->
        {:error, "Помилка: нова деталь вже встановлена в іншій зброї"}

      not is_nil(new_part) and
          not part_installable_record?(new_part) ->
        {:error, "Помилка: нову деталь з таким статусом не можна встановити"}

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
          {:ok, event} <- append_service_event(fields, context),
          :ok <- update_parts(context.old_part, context.new_part, context.weapon_id) do
        {:ok, event}
      end
  end

  defp append_service_event(fields, context) do
    id = :kvs.seq([], [])

      event =
        EXO.wms_service_event(
          id: id,
          service_order: fields.service_order,
          weapon: context.weapon_id,
          event_type: fields.event_type,
          actor: fields.actor,
          event_status: fields.event_status,
          condition: fields.condition,
          required_action: fields.required_action,
          result: fields.result,
          old_part: fields.old_part,
          new_part: fields.new_part
        )

      case :kvs.append(event, ~c"/wms/service_events") do
        ^id -> {:ok, event}
        result -> {:error, "Помилка створення події: #{inspect(result)}"}
      end
    end

  defp remove_part_from_weapon(part) do
    updated_part =
      EXO.wms_part(
        part,
        installed_in_weapon: "",
        part_status: @removed_part_status
      )

    replace_part(part, updated_part)
  end

  defp install_part_on_weapon(part, weapon_id) do
    updated_part =
      EXO.wms_part(
        part,
        installed_in_weapon: weapon_id,
        part_status: @installed_part_status
      )

    replace_part(part, updated_part)
  end

  defp update_parts(nil, nil, _weapon_id), do: :ok

  defp update_parts(old_part, nil, _weapon_id) do
    remove_part_from_weapon(old_part)
  end

  defp update_parts(nil, new_part, weapon_id) do
    install_part_on_weapon(new_part, weapon_id)
  end

  defp update_parts(old_part, new_part, weapon_id) do
    with :ok <- remove_part_from_weapon(old_part),
         :ok <- install_part_on_weapon(new_part, weapon_id) do
      :ok
    end
  end

  defp load_context(fields) do
    with {:ok, service_order} <- get_service_order(fields.service_order) do
      weapon_id = service_order_weapon_id(service_order)

      with {:ok, weapon} <- get_from_feed(~c"/wms/weapons", weapon_id),
           {:ok, old_part} <- get_from_feed(~c"/wms/parts", fields.old_part),
           {:ok, new_part} <- get_from_feed(~c"/wms/parts", fields.new_part) do
        {:ok,
         %{
           service_order: service_order,
           weapon_id: weapon_id,
           weapon: weapon,
           old_part: old_part,
           new_part: new_part
         }}
      end
    end
  end

  def get_service_order(order_id) do
    normalized_id = clean(order_id)

    case normalized_id do
      "" ->
        {:error, "Помилка: введіть ID сервісного наряду"}

      id ->
        case :kvs.get(~c"/wms/service_orders", String.to_charlist(id)) do
          {:ok, service_order} ->
            {:ok, service_order}

          {:error, :not_found} ->
            {:error, "Помилка: сервісний наряд не знайдено"}

          {:error, reason} ->
            {:error, "Помилка: не вдалося отримати сервісний наряд (#{inspect(reason)})"}
        end
    end
  end

  defp service_order_weapon_id(service_order) do
    service_order
    |> EXO.wms_service_order(:weapon)
    |> clean()
  end

  defp get_from_feed(_feed, ""), do: {:ok, nil}

  defp get_from_feed(feed, id) do
    key =
      id
      |> clean()
      |> String.to_charlist()

    case :kvs.get(feed, key) do
      {:ok, record} ->
        {:ok, record}

      {:error, :not_found} ->
        {:ok, nil}

      {:error, reason} ->
        {:error, "Помилка читання даних: #{inspect(reason)}"}
    end
  end

  defp replace_part(old_part, updated_part) do
    expected_part_id = EXO.wms_part(updated_part, :id)

    :kvs.remove(old_part, ~c"/wms/parts")

    case :kvs.append(updated_part, ~c"/wms/parts") do
      ^expected_part_id ->
        :ok

      result ->
        {:error, "Помилка оновлення деталі: #{inspect(result)}"}
    end
  end
end
