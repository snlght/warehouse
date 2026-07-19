defmodule WMS.ServiceEventRules do
  require EXO

  def clean(value) do
    value
    |> :nitro.to_binary()
    |> String.trim()
  end

  def blank?(value), do: clean(value) == ""

  def weapon_exists?(weapon_id) do
    wanted_id = clean(weapon_id)

    :kvs.all(~c"/wms/weapons")
    |> Enum.any?(fn weapon ->
      weapon
      |> EXO.wms_weapon(:id)
      |> clean()
      |> Kernel.==(wanted_id)
    end)
  end

  def part_exists?(serial_number) do
    wanted_serial_number = clean(serial_number)

    :kvs.all(~c"/wms/parts")
    |> Enum.any?(fn part ->
      part
      |> EXO.wms_part(:serial_number)
      |> clean()
      |> Kernel.==(wanted_serial_number)
    end)
  end

  def service_order_exists?(order_id) do
    wanted_service_order = clean(order_id)

    :kvs.all(~c"/wms/service_orders")
    |> Enum.any?(fn order ->
      order
      |> EXO.wms_service_order(:id)
      |> clean()
      |> Kernel.==(wanted_service_order)
    end)
  end

  def part_installed_in_weapon?(serial_number, weapon_id) do
    wanted_serial_number = clean(serial_number)
    wanted_weapon_id = clean(weapon_id)

    :kvs.all(~c"/wms/parts")
    |> Enum.any?(fn part ->
      part_serial =
        part
        |> EXO.wms_part(:serial_number)
        |> clean()

      installed_in_weapon =
        part
        |> EXO.wms_part(:installed_in_weapon)
        |> clean()

      part_serial == wanted_serial_number and
        installed_in_weapon == wanted_weapon_id
    end)
  end

  def part_installed_in_another_weapon?(serial_number, weapon_id) do
    wanted_serial_number = clean(serial_number)
    wanted_weapon_id = clean(weapon_id)

    :kvs.all(~c"/wms/parts")
    |> Enum.any?(fn part ->
      part_serial =
        part

        |> EXO.wms_part(:serial_number)
        |> clean()

      installed_in_weapon =
        part
        |> EXO.wms_part(:installed_in_weapon)
        |> clean()


      part_serial == wanted_serial_number and installed_in_weapon != "" and installed_in_weapon != wanted_weapon_id

    end)
  end
end
