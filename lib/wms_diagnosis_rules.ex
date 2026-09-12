defmodule WMS.DiagnosisRules do
  require EXO

  @allowed_outcomes [
    "repairable",
    "no_fault_found",
    "unrepairable"
  ]

  @required_fields [
    :service_order,
    :outcome,
    :diagnosed_by
  ]

  @optional_fields [
    :faults,
    :notes
  ]

  def clean(nil), do: ""

  def clean(value) do
    value
    |> :nitro.to_binary()
    |> String.trim()
  end

  defp normalize_faults(nil), do: []
  defp normalize_faults(faults) when is_list(faults), do: faults
  defp normalize_faults(_), do: []

  defp normalize_fields(fields) when is_map(fields) do
    normalized_fields = %{
      service_order: clean(Map.get(fields, :service_order, "")),
      outcome: clean(Map.get(fields, :outcome, "")),
      faults: normalize_faults(Map.get(fields, :faults, [])),
      diagnosed_by: clean(Map.get(fields, :diagnosed_by, "")),
      diagnosed_at: System.system_time(:millisecond),
      notes: clean(Map.get(fields, :notes, ""))
    }

    {:ok, normalized_fields}
  end

  defp normalize_fields(_fields) do
    {:error, "Помилка: некоректний формат даних діагностики"}
  end

  defp validate_fields(fields) do
    cond do
      fields.service_order == "" ->
        {:error, "Помилка: сервісний наряд обов'язковий"}

      fields.outcome == "" ->
        {:error, "Помилка: результат обов'язковий"}

      fields.outcome not in @allowed_outcomes ->
        {:error, "Помилка: вказано некоректний результат"}

      fields.diagnosed_by == "" ->
        {:error, "Помилка: виконавець діагностики обов'язковий"}

      true ->
        :ok
    end
  end

  defp append_diagnosis_result(fields, weapon_id) do
    id = :kvs.seq([], [])

    diagnosis_result =
      EXO.wms_diagnosis_result(
        id: id,
        service_order: fields.service_order,
        weapon: weapon_id,
        outcome: fields.outcome,
        faults: fields.faults,
        diagnosed_by: fields.diagnosed_by,
        diagnosed_at: fields.diagnosed_at,
        notes: fields.notes
      )

    case :kvs.append(diagnosis_result, ~c"/wms/diagnosis_results") do
      ^id ->
        {:ok, diagnosis_result}

      result ->
        {:error, "Помилка створення результату діагностики: #{inspect(result)}"}
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
        {:error, "Помилка читання сервісного наряду: #{inspect(reason)}"}
    end
  end

  defp get_service_order_weapon(service_order) do
    weapon_id =
      service_order
      |> EXO.wms_service_order(:weapon)
      |> clean()

    case weapon_id do
      "" ->
        {:error, "Помилка: у сервісному наряді не вказано зброю"}

      id ->
        {:ok, id}
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

  def create(fields) do
    with {:ok, fields} <- normalize_fields(fields),
         :ok <- validate_fields(fields),
         {:ok, service_order} <- get_service_order(fields.service_order),
         {:ok, weapon_id} <- get_service_order_weapon(service_order),
         {:ok, _weapon} <- get_weapon(weapon_id) do
      append_diagnosis_result(fields, weapon_id)
    end
  end
end
