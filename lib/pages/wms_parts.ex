defmodule EXO.WMS.Parts do
  require EXO
  require NITRO
  # require Logger

  def event(:init) do
    :nitro.clear(:tableHead)
    :nitro.clear(:tableRow)
    :nitro.insert_top(:tableHead, header())
    :nitro.clear(:frms)
    :nitro.clear(:ctrl)

    build_form()

    render_toolbar(:list)

    :nitro.hide(:frms)

    records = :kvs.all(~c"/wms/parts")
    render_parts(records)
  end

  def render_parts(records) do
    :nitro.clear(:tableRow)

    Enum.each(records, fn part ->
      id = EXO.wms_part(part, :id)

      :nitro.insert_bottom(
        :tableRow,
        WMS.Part.Row.new(:form.atom([:row, id]), part, [])
      )
    end)
  end

  def render_toolbar(:list) do
    :nitro.clear(:ctrl)
    :nitro.insert_bottom(:ctrl, WMS.Part.Toolbar.list_mode())
  end

  def render_toolbar(:form) do
    :nitro.clear(:ctrl)
    :nitro.insert_bottom(:ctrl, WMS.Part.Toolbar.form_mode())
  end

  def build_form() do
    :nitro.clear(:frms)

    :nitro.insert_bottom(
      :frms,
      NITRO.panel(id: :part_error, body: [])
    )

    mod = WMS.Part.Form
    form = :form.new(mod.new(:none, mod.id(), []), mod.id(), [])
    :nitro.insert_bottom(:frms, form)
  end

  def event(:create) do
    render_toolbar(:form)
    build_form()
    :nitro.show(:frms)
  end

  def event({:SavePart, _}) do
    :nitro.clear(:part_error)

    fields = %{
      serial_number: :serial_number_wms_part_none |> :nitro.q() |> WMS.PartRules.clean(),
      part_type: :part_type_wms_part_none |> :nitro.q() |> WMS.PartRules.clean(),
      part_status: :part_status_wms_part_none |> :nitro.q() |> WMS.PartRules.clean(),
      installed_in_weapon:
        :installed_in_weapon_wms_part_none |> :nitro.q() |> WMS.PartRules.clean(),
      storage_location: :storage_location_wms_part_none |> :nitro.q() |> WMS.PartRules.clean(),
      manufacturer: :manufacturer_wms_part_none |> :nitro.q() |> WMS.PartRules.clean()
    }

    case WMS.PartRules.validate_required_part_fields(fields) do
      {:error, message} ->
        WMS.UI.show_error(:part_error, message)

      :ok ->
        cond do
          fields.installed_in_weapon != "" and
              not WMS.PartRules.weapon_exists?(fields.installed_in_weapon) ->
            WMS.UI.show_error(:part_error, "Помилка: зброї з таким ID не існує")

          true ->
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
            event(:init)
        end
    end
  end

  def event({:Close, []}) do
    build_form()
    :nitro.hide(:frms)
    render_toolbar(:list)
  end

  # def event(x) do
  #   Logger.info("Parts event: #{inspect(x)}")
  # end

  def header() do
    NITRO.panel(
      id: :header,
      class: :th,
      body: [
        NITRO.panel(class: :column10, body: "ID"),
        NITRO.panel(class: :column20, body: "Серійний номер"),
        NITRO.panel(class: :column20, body: "Тип"),
        NITRO.panel(class: :column20, body: "Статус"),
        NITRO.panel(class: :column20, body: "ID зброї"),
        NITRO.panel(class: :column20, body: "Локація"),
        NITRO.panel(class: :column20, body: "Виробник")
      ]
    )
  end
end
