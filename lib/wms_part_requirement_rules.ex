defmodule WMS.PartRequirementRules do
  require EXO

  def clean(nil), do: ""

  def clean(value) do
    value
    |> :nitro.to_binary()
    |> String.trim()
  end

  defp normalize_fields(fields) when is_map(fields) do
    normalized_fields = %{
      service_order: clean(Map.get(fields, :service_order, "")),
      diagnosis_result: clean(Map.get(fields, :diagnosis_result, "")),
      part_type: clean(Map.get(fields, :part_type, "")),
      requested_by: clean(Map.get(fields, :requested_by, "")),
      notes: clean(Map.get(fields, :notes, "")),
      requested_at: System.system_time(:millisecond)
    }

    {:ok, normalized_fields}
  end

  defp normalize_fields(_fields) do
    {:error, "Помилка: некоректний формат даних потреби в деталі"}
  end

  defp validate_fields(fields) do
    cond do
      fields.service_order == "" ->
        {:error, "Помилка: сервісний наряд обов'язковий"}

      fields.diagnosis_result == "" ->
        {:error, "Помилка: результат діагностики обов'язковий"}

      fields.part_type == "" ->
        {:error, "Помилка: тип деталі обов'язковий"}

      fields.requested_by == "" ->
        {:error, "Помилка: виконавець запиту обов'язковий"}

      true ->
        :ok
    end
  end

  defp get_diagnosis_result(diagnosis_result_id) do
    id =
      diagnosis_result_id
      |> clean()
      |> String.to_charlist()

    case :kvs.get(~c"/wms/diagnosis_results", id) do
      {:ok, diagnosis_result} ->
        {:ok, diagnosis_result}

      {:error, :not_found} ->
        {:error, "Помилка: результат діагностики не знайдено"}

      {:error, reason} ->
        {:error, "Помилка: не вдалося отримати результат діагностики (#{inspect(reason)})"}
    end
  end

  defp validate_diagnosis_relation(diagnosis_result, service_order, weapon_id) do
    diagnosis_service_order =
      diagnosis_result
      |> EXO.wms_diagnosis_result(:service_order)
      |> clean()

    diagnosis_weapon_id =
      diagnosis_result
      |> EXO.wms_diagnosis_result(:weapon)
      |> clean()

    service_order = clean(service_order)
    weapon_id = clean(weapon_id)

    cond do
      diagnosis_service_order != service_order ->
        {:error, "Помилка: результат діагностики не відповідає сервісному наряду"}

      diagnosis_weapon_id != weapon_id ->
        {:error, "Помилка: результат діагностики не відповідає зброї"}

      true ->
        :ok
    end
  end

  defp append_part_requirement(fields, weapon_id) do
    id = :kvs.seq([], [])

    part_requirement =
      EXO.wms_part_requirement(
        id: id,
        service_order: fields.service_order,
        diagnosis_result: fields.diagnosis_result,
        weapon: weapon_id,
        part_type: fields.part_type,
        status: "requested",
        requested_by: fields.requested_by,
        requested_at: fields.requested_at,
        fulfilled_by_part: "",
        notes: fields.notes
      )

    case :kvs.append(part_requirement, ~c"/wms/part_requirements") do
      ^id ->
        {:ok, part_requirement}

      result ->
        {:error, "Помилка створення потреби в деталі: #{inspect(result)}"}
    end
  end

  defp get_service_order(order_id) do
    id =
      order_id
      |> clean()
      |> String.to_charlist()

    case :kvs.get(~c"/wms/service_orders", id) do
      {:ok, service_order} ->
        {:ok, service_order}

      {:error, :not_found} ->
        {:error, "Помилка: сервісний наряд не знайдено"}

      {:error, reason} ->
        {:error, "Помилка: не вдалося отримати сервісний наряд (#{inspect(reason)})"}
    end
  end

  defp get_service_order_weapon(service_order) do
    weapon_id =
      service_order
      |> EXO.wms_service_order(:weapon)
      |> clean()

    case weapon_id do
      "" ->
        {:error, "Помилка: сервісний наряд не містить інформації про зброю"}

      weapon_id ->
        {:ok, weapon_id}
    end
  end

  defp get_weapon(weapon_id) do
    id =
      weapon_id
      |> clean()
      |> String.to_charlist()

    case :kvs.get(~c"/wms/weapons", id) do
      {:ok, weapon} ->
        {:ok, weapon}

      {:error, :not_found} ->
        {:error, "Помилка: зброю з сервісного наряду не знайдено"}

      {:error, reason} ->
        {:error, "Помилка читання зброї: #{inspect(reason)}"}
    end
  end

  defp validate_diagnosis_outcome(diagnosis_result) do
    outcome =
      diagnosis_result
      |> EXO.wms_diagnosis_result(:outcome)
      |> clean()

    case outcome do
      "repairable" ->
        :ok

      _ ->
        {:error, "Помилка: потребу в деталі можна створити лише для ремонтопридатної зброї"}
    end
  end

  def create(fields) do
    with {:ok, fields} <- normalize_fields(fields),
         :ok <- validate_fields(fields),
         {:ok, service_order} <- get_service_order(fields.service_order),
         {:ok, weapon_id} <- get_service_order_weapon(service_order),
         {:ok, _weapon} <- get_weapon(weapon_id),
         {:ok, diagnosis_result} <- get_diagnosis_result(fields.diagnosis_result),
         :ok <- validate_diagnosis_relation(diagnosis_result, fields.service_order, weapon_id),
         :ok <- validate_diagnosis_outcome(diagnosis_result) do
      append_part_requirement(fields, weapon_id)
    end
  end
end
