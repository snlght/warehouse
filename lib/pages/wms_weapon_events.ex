defmodule EXO.WMS.WeaponEvents do
  require EXO
  require NITRO

  def event(:init) do
    :nitro.clear(:tableHead)
    :nitro.clear(:tableRow)
    :nitro.clear(:ctrl)
    :nitro.clear(:frms)

    :nitro.insert_top(:tableHead, header())

    :kvs.all(~c"/wms/weapon_events")
    |> Enum.each(fn event ->
      id = EXO.wms_weapon_event(event, :id)

      :nitro.insert_bottom(
        :tableRow,
        WMS.WeaponEvent.Row.new(:form.atom([:row, id]), event, [])
      )
    end)
  end

  def event(_), do: :ok

  def header() do
    NITRO.panel(
      id: :header,
      class: :th,
      body: [
        NITRO.panel(class: :column10, body: "ID"),
        NITRO.panel(class: :column10, body: "Зброя"),
        NITRO.panel(class: :column20, body: "Тип події"),
        NITRO.panel(class: :column10, body: "Виконавець"),
        NITRO.panel(class: :column10, body: "Статус"),
        NITRO.panel(class: :column10, body: "Звідки"),
        NITRO.panel(class: :column10, body: "Куди"),
        NITRO.panel(class: :column10, body: "Наряд"),
        NITRO.panel(class: :column10, body: "Деталь"),
        NITRO.panel(class: :column20, body: "Час")
      ]
    )
  end
end
