defmodule WMS.ServiceEventRules do
  require EXO

  @removed_part_status "removed"
  @installed_part_status "installed"
  @installable_part_statuses ["spare", "removed"]
  @allowed_event_statuses ["planned", "in_progress", "completed", "cancelled"]

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

  def clean(nil), do: ""

  def clean(value) do
    value
    |> :nitro.to_binary()
    |> String.trim()
  end

  def validate_create(fields) do
    with {:ok, normalized_fields} <- normalize_fields(fields),
         {:ok, context} <- load_context(normalized_fields),
         :ok <- validate_references(normalized_fields, context) do
      {:ok, normalized_fields, context}
    end
  end

  def create_service_event(fields) do
    with {:ok, normalized_fields, context} <- validate_create(fields),
         {:ok, event} <- append_service_event(normalized_fields, context),
         :ok <- apply_part_changes(normalized_fields, context) do
      {:ok, event}
    end
  end

  def get_service_order(order_id) do
    normalized_id = clean(order_id)

    case normalized_id do
      "" ->
        {:error, "Помилка: введіть ID сервісного наряду"}

      id ->
        get_required_record(
          ~c"/wms/service_orders",
          id,
          "Помилка: сервісний наряд не знайдено"
        )
    end
  end

  defp normalize_fields(fields) when is_map(fields) do
    normalized_fields =
      (@required_fields ++ @optional_fields)
      |> Map.new(fn key ->
        value =
          fields
          |> Map.get(key, "")
          |> clean()

        {key, value}
      end)

    validate_required_fields(normalized_fields)
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

      fields.event_status not in @allowed_event_statuses ->
        {:error, "Помилка: некоректний статус події"}

      true ->
        {:ok, fields}
    end
  end

  defp load_context(fields) do
    with {:ok, service_order} <- get_service_order(fields.service_order),
         weapon_id <- service_order_weapon_id(service_order),
         {:ok, weapon} <-
           get_optional_record(~c"/wms/weapons", weapon_id),
         {:ok, old_part} <-
           get_optional_record(~c"/wms/parts", fields.old_part),
         {:ok, new_part} <-
           get_optional_record(~c"/wms/parts", fields.new_part) do
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

  defp validate_references(
         fields,
         %{
           service_order: service_order,
           weapon: weapon,
           weapon_id: weapon_id,
           old_part: old_part,
           new_part: new_part
         }
       ) do
    old_part_weapon_id = optional_part_weapon_id(old_part)
    new_part_weapon_id = optional_part_weapon_id(new_part)

    cond do
      is_nil(service_order) ->
        {:error, "Помилка: сервісного наряду не існує"}

      weapon_id == "" ->
        {:error, "Помилка: у сервісному наряді не вказано зброю"}

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

      not is_nil(old_part) and old_part_weapon_id != weapon_id ->
        {:error, "Помилка: стара деталь не належить цій зброї"}

      not is_nil(new_part) and new_part_weapon_id == weapon_id ->
        {:error, "Помилка: нова деталь вже встановлена в цій зброї"}

      not is_nil(new_part) and
        new_part_weapon_id != "" and
          new_part_weapon_id != weapon_id ->
        {:error, "Помилка: нова деталь вже встановлена в іншій зброї"}

      not is_nil(new_part) and not part_installable?(new_part) ->
        {:error, "Помилка: нову деталь з таким статусом не можна встановити"}

      true ->
        :ok
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
      ^id ->
        {:ok, event}

      result ->
        {:error, "Помилка створення сервісної події: #{inspect(result)}"}
    end
  end

  defp apply_part_changes(
         %{event_status: "completed"},
         %{
           old_part: old_part,
           new_part: new_part,
           weapon_id: weapon_id
         }
       ) do
    update_parts(old_part, new_part, weapon_id)
  end

  defp apply_part_changes(_fields, _context), do: :ok

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

  defp get_required_record(feed, id, not_found_message) do
    case get_record(feed, id) do
      {:ok, record} ->
        {:ok, record}

      {:error, :not_found} ->
        {:error, not_found_message}

      {:error, reason} ->
        {:error, "Помилка читання даних: #{inspect(reason)}"}
    end
  end

  defp get_optional_record(_feed, ""), do: {:ok, nil}

  defp get_optional_record(feed, id) do
    case get_record(feed, id) do
      {:ok, record} ->
        {:ok, record}

      {:error, :not_found} ->
        {:ok, nil}

      {:error, reason} ->
        {:error, "Помилка читання даних: #{inspect(reason)}"}
    end
  end

  defp get_record(feed, id) do
    key =
      id
      |> clean()
      |> String.to_charlist()

    :kvs.get(feed, key)
  end

  defp service_order_weapon_id(service_order) do
    service_order
    |> EXO.wms_service_order(:weapon)
    |> clean()
  end

  defp optional_part_weapon_id(nil), do: ""

  defp optional_part_weapon_id(part) do
    part
    |> EXO.wms_part(:installed_in_weapon)
    |> clean()
  end

  defp part_installable?(part) do
    part
    |> EXO.wms_part(:part_status)
    |> clean()
    |> then(&(&1 in @installable_part_statuses))
  end

  def status_title(status) do
    case status |> clean() |> String.downcase() do
      "init" -> "Створено"
      "planned" -> "Заплановано"
      "in_progress" -> "У процесі"
      "completed" -> "Завершено"
      "cancelled" -> "Скасовано"
      unknown_status -> unknown_status
    end
  end
end
