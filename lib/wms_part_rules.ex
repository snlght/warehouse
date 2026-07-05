defmodule WMS.PartRules do
  require EXO

  def weapon_exists(weapon_id) do
    :kvs.all(~c"/wms/weapons")
    |> Enum.any?(fn weapon ->
      :nitro.to_binary(EXO.wms_weapon(weapon, :id)) == :nitro.to_binary(weapon_id)
    end)
  end

    def clean(value) do
      value
      |> :nitro.to_binary()
      |> String.trim()
    end

    def blank?(value), do: clean(value) == ""

    def weapon_exists?(weapon_id) do
      :kvs.all(~c"/wms/weapons")
      |> Enum.any?(fn weapon ->
        EXO.wms_weapon(weapon, :id)
        |> clean()
        |> Kernel.==(clean(weapon_id))
      end)
    end

    def validate_required_part_fields(fields) do
      cond do
        blank?(fields.serial_number) ->
          {:error, "Помилка: серійний номер деталі обов’язковий"}

        blank?(fields.part_type) ->
          {:error, "Помилка: тип деталі обов’язковий"}

        blank?(fields.part_status) ->
          {:error, "Помилка: статус деталі обов’язковий"}

        blank?(fields.storage_location) ->
          {:error, "Помилка: локація зберігання обов’язкова"}

        blank?(fields.manufacturer) ->
          {:error, "Помилка: виробник обов’язковий"}

        true ->
          :ok
      end
    end
  end
