defmodule WMS.PartRules do
  require EXO

  def clean(value) do
    value
    |> :nitro.to_binary()
    |> String.trim()
  end

  def normalize(value) do
    value
    |> clean()
    |> String.downcase()
  end

  def blank?(value), do: clean(value) == ""

  def find_part(id) do
    wanted_id = clean(id)

    :kvs.all(~c"/wms/parts")
    |> Enum.find(fn part ->
      part
      |> EXO.wms_part(:id)
      |> clean()
      |> Kernel.==(wanted_id)
    end)
  end

  def weapon_exists?(weapon_id) do
    target_id = clean(weapon_id)

    :kvs.all(~c"/wms/weapons")
    |> Enum.any?(fn weapon ->
      weapon
      |> EXO.wms_weapon(:id)
      |> clean()
      |> Kernel.==(target_id)
    end)
  end

  def serial_number_exists?(serial_number) do
    wanted_serial_number = clean(serial_number)

    :kvs.all(~c"/wms/parts")
    |> Enum.any?(fn part ->
      part
      |> EXO.wms_part(:serial_number)
      |> clean()
      |> Kernel.==(wanted_serial_number)
    end)
  end

  def serial_number_used_by_another_part?(serial_number, current_part_id) do
    wanted_serial_number = clean(serial_number)
    current_id = clean(current_part_id)

    :kvs.all(~c"/wms/parts")
    |> Enum.any?(fn part ->
      part_id = part |> EXO.wms_part(:id) |> clean()
      part_serial_number = part |> EXO.wms_part(:serial_number) |> clean()

      part_serial_number == wanted_serial_number and part_id != current_id
    end)
  end

  def create_part(fields) do
    with :ok <- validate_create(fields) do
      id = :kvs.seq([], [])

      part =
        EXO.wms_part(
          id: id,
          serial_number: fields.serial_number,
          part_type: fields.part_type,
          part_status: fields.part_status,
          installed_in_weapon: fields.installed_in_weapon,
          storage_location: fields.storage_location,
          manufacturer: fields.manufacturer
        )

      :kvs.append(part, ~c"/wms/parts")
      {:ok, part}
    end
  end

  @spec update_part(any(), any(), any()) :: {:error, <<_::64, _::_*8>>} | {:ok, tuple()}
  def update_part(nil, _fields, _current_part_id) do
    {:error, "Помилка: деталь не знайдена"}
  end

  def update_part(part, fields, current_part_id) do
    with :ok <- validate_update(fields, current_part_id) do
      updated_part =
        EXO.wms_part(
          part,
          serial_number: fields.serial_number,
          part_type: fields.part_type,
          part_status: fields.part_status,
          installed_in_weapon: fields.installed_in_weapon,
          storage_location: fields.storage_location,
          manufacturer: fields.manufacturer
        )

      replace_part(part, updated_part)
    end
  end

  defp replace_part(old_part, updated_part) do
    :kvs.remove(old_part, ~c"/wms/parts")
    :kvs.append(updated_part, ~c"/wms/parts")
    {:ok, updated_part}
  end

  def validate_create(fields) do
    with :ok <- validate_required_part_fields(fields),
         :ok <- validate_installed_in_weapon(fields.installed_in_weapon),
         :ok <- validate_unique_serial_number(fields.serial_number) do
      :ok
    end
  end

  def validate_update(fields, current_part_id) do
    with :ok <- validate_required_part_fields(fields),
         :ok <- validate_installed_in_weapon(fields.installed_in_weapon),
         :ok <- validate_unique_serial_number_for_update(fields.serial_number, current_part_id) do
      :ok
    end
  end

  def validate_required_part_fields(fields) do
    cond do
      blank?(fields.serial_number) -> {:error, "Помилка: серійний номер деталі обов’язковий"}
      blank?(fields.part_type) -> {:error, "Помилка: тип деталі обов’язковий"}
      blank?(fields.part_status) -> {:error, "Помилка: статус деталі обов’язковий"}
      blank?(fields.storage_location) -> {:error, "Помилка: локація зберігання обов’язкова"}
      blank?(fields.manufacturer) -> {:error, "Помилка: виробник обов’язковий"}
      true -> :ok
    end
  end

  def validate_installed_in_weapon(""), do: :ok
  def validate_installed_in_weapon(weapon_id) do
    if weapon_exists?(weapon_id) do
      :ok
    else
      {:error, "Помилка: зброї з таким ID не існує"}
    end
  end

  def validate_unique_serial_number(serial_number) do
    if serial_number_exists?(serial_number) do
      {:error, "Помилка: деталь з таким серійним номером вже існує"}
    else
      :ok
    end
  end

  def validate_unique_serial_number_for_update(serial_number, current_part_id) do
    if serial_number_used_by_another_part?(serial_number, current_part_id) do
      {:error, "Помилка: деталь з таким серійним номером вже існує"}
    else
      :ok
    end
  end

  def status_title("installed"), do: "Встановлена"
  def status_title("spare"), do: "Запасна"
  def status_title("broken"), do: "Несправна"
  def status_title("decommissioned"), do: "Списана"
  def status_title("removed"), do: "Знята"
  def status_title(status), do: status
end
