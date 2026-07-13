defmodule EXO.WMS.Parts do
  require EXO
  require NITRO

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

  def event(:clear_part_search) do
    render_toolbar(:list)

    records = :kvs.all(~c"/wms/parts")
    render_parts(records)
  end

  def event(:search_part) do
    query =
      :part_search
      |> :nitro.q()
      |> WMS.PartRules.normalize()

    status_filter =
      :part_status_filter
      |> :nitro.q()
      |> WMS.PartRules.normalize()

    records =
      :kvs.all(~c"/wms/parts")
      |> Enum.filter(fn part ->
        matches_part_query?(part, query) and
          matches_part_status?(part, status_filter)
      end)

    render_parts(records)
  end

  defp matches_part_query?(_part, ""), do: true

  defp matches_part_query?(part, query) do
    [
      EXO.wms_part(part, :id),
      EXO.wms_part(part, :serial_number),
      EXO.wms_part(part, :part_type),
      EXO.wms_part(part, :manufacturer)
    ]
    |> Enum.any?(fn value ->
      value
      |> WMS.PartRules.normalize()
      |> String.contains?(query)
    end)
  end

  defp matches_part_status?(_part, ""), do: true
  defp matches_part_status?(_part, "all"), do: true

  defp matches_part_status?(part, status_filter) do
    part
    |> EXO.wms_part(:part_status)
    |> WMS.PartRules.normalize()
    |> Kernel.==(status_filter)
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

  defp read_part_fields(:create) do
    read_part_fields(%{
      serial_number: :serial_number_wms_part_none,
      part_type: :part_type_wms_part_none,
      part_status: :part_status_wms_part_none,
      installed_in_weapon: :installed_in_weapon_wms_part_none,
      storage_location: :storage_location_wms_part_none,
      manufacturer: :manufacturer_wms_part_none
    })
  end

  defp read_part_fields(:update) do
    read_part_fields(%{
      serial_number: :serial_number_wms_part_create,
      part_type: :part_type_wms_part_create,
      part_status: :part_status_wms_part_create,
      installed_in_weapon: :installed_in_weapon_wms_part_create,
      storage_location: :storage_location_wms_part_create,
      manufacturer: :manufacturer_wms_part_create
    })
  end

  defp read_part_fields(input_ids) do
    Map.new(input_ids, fn {field, input_id} ->
      value =
        input_id
        |> :nitro.q()
        |> WMS.PartRules.clean()

      {field, value}
    end)
  end


def event({:SavePart, _data}) do
  :create
    |> read_part_fields()
    |> WMS.PartRules.create_part()
    |> handle_part_result()
end

def event({:Close, _data}) do
  :nitro.clear(:frms)
  :nitro.hide(:frms)
  render_toolbar(:list)
end

def event({:EditPart, id}) do
  id
  |> WMS.PartRules.find_part()
  |> open_edit_form(id)
end

defp open_edit_form(nil, _id) do
  WMS.UI.show_error(:part_error, "Помилка: деталь не знайдена")
end

defp open_edit_form(part, _id) do
  :nitro.clear(:frms)
  render_toolbar(:form)

  :nitro.insert_bottom(
    :frms,
    NITRO.panel(id: :part_error, body: [])
  )

  mod = WMS.Part.EditForm
  form = mod.new(:none, part, [])

  :nitro.insert_bottom(:frms, :form.new(form, part, create: true))
  :nitro.show(:frms)
end

def event({:UpdatePart, id}) do
  part = WMS.PartRules.find_part(id)

  fields = read_part_fields(:update)

  part
  |> WMS.PartRules.update_part(fields, id)
  |> handle_part_result()

end

defp handle_part_result({:ok, _part}) do
  event(:init)
end

defp handle_part_result({:error, message}) do
  WMS.UI.show_error(:part_error, message)
end


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
      NITRO.panel(class: :column20, body: "Виробник"),
      NITRO.panel(class: :column20, body: "Дія")
    ]
  )
end
end
