defmodule WMS.PartReservationRules do
  require EXO

  defp clean(nil), do: ""

  defp clean(value) do
    value
    |> :nitro.to_binary()
    |> String.trim()
  end

  defp validate_part_type(part_requirement, part) do
    requirement_type =
      part_requirement
      |> EXO.wms_part_requirement(:part_type)
      |> clean()

    part_type =
      part
      |> EXO.wms_part(:part_type)
      |> clean()

    cond do
      requirement_type == part_type ->
        :ok

      true ->
        {:error, "Помилка: тип деталі не відповідає потребі"}
    end
  end

  defp validate_part_not_reserved(part_id) do
    WMS.PartReservationStorage.get_active_by_part(part_id)
    |> case do
      {:ok, _} ->
        {:error, "Помилка: деталь вже зарезервована"}

      {:error, :not_found} ->
        :ok

      {:error, reason} ->
        {:error, "Помилка: не вдалося перевірити резервування деталі (#{inspect(reason)})"}
    end
  end

  defp validate_requirement_not_reserved(requirement_id) do
    WMS.PartReservationStorage.get_active_by_requirement(requirement_id)
    |> case do
      {:ok, _} ->
        {:error, "Помилка: потреба вже зарезервована"}

      {:error, :not_found} ->
        :ok

      {:error, reason} ->
        {:error, "Помилка: не вдалося перевірити резервування потреби (#{inspect(reason)})"}
    end
  end

  defp validate_reserved_by(reserved_by) do
    case clean(reserved_by) do
      "" ->
        {:error, "Помилка: не вказано користувача, який резервує деталь"}

      _ ->
        :ok
    end
  end

  defp build_reservation(requirement, part, reserved_by) do
    id = :kvs.seq([], [])

    requirement_id =
      requirement
      |> EXO.wms_part_requirement(:id)
      |> clean()

    part_id =
      part
      |> EXO.wms_part(:id)
      |> clean()

    reservation =
      EXO.wms_part_reservation(
        id: id,
        status: "active",
        part_requirement: requirement_id,
        part: part_id,
        reserved_by: clean(reserved_by),
        reserved_at: System.system_time(:millisecond)
      )

    {:ok, reservation}
  end

  def reserve(requirement_id, part_id, reserved_by) do
    with {:ok, part_requirement} <-
           WMS.PartRequirementRules.get_part_requirement(requirement_id),
         :ok <-
           WMS.PartRequirementRules.validate_reservable(part_requirement),
         {:ok, part} <-
           WMS.PartRules.get_part(part_id),
         :ok <-
           WMS.PartRules.validate_reservable(part),
         :ok <-
           validate_part_type(part_requirement, part),
         :ok <-
           validate_part_not_reserved(part_id),
         :ok <-
           validate_requirement_not_reserved(requirement_id),
         :ok <-
           validate_reserved_by(reserved_by) do
      build_reservation(part_requirement, part, reserved_by)
    end
  end
end
