defmodule EXO.WMS.Operator do
  require EXO
  require NITRO

  def event(:init) do
    :nitro.clear(:tableHead)
    :nitro.clear(:tableRow)
    :nitro.clear(:ctrl)
    :nitro.clear(:frms)

    :nitro.insert_top(:tableHead, header())

    :nitro.insert_bottom(
      :ctrl,
      NITRO.link(
        id: :create_service_order,
        body: "Заявка на ремонт",
        postback: :create_service_order,
        class: [:button, :sgreen]
      )
    )

    :nitro.insert_bottom(
      :ctrl,
      NITRO.link(
        id: :create_transfer_order,
        body: "Заявка на переміщення",
        postback: :create_transfer_order,
        class: [:button, :sgreen]
      )
    )

    :nitro.insert_bottom(
      :ctrl,
      NITRO.link(
        id: :add_weapon,
        body: "Додати зброю",
        postback: :add_weapon,
        class: [:button, :sgreen]

      )
    )

    records = :kvs.all(~c"/wms/weapons")

    Enum.each(records, fn weapon ->
      id = EXO.wms_weapon(weapon, :id)
      :nitro.insert_bottom(:tableRow, WMS.Weapon.Row.new(id, weapon, []))
    end)
  end


def event({:SaveWeapon, form}) do
  EXO.WMS.Weapons.event({:SaveWeapon, form})
  event(:init)
end

def event({:Close, data}) do
  EXO.WMS.Weapons.event({:Close, data})
  event(:init)
end


def event(:add_weapon) do
  :nitro.hide(:ctrl)
  :nitro.clear(:frms)

  mod = WMS.Weapon.Form
  form = mod.new(:none, mod.id(), [])

  :nitro.insert_bottom(:frms, :form.new(form, mod.id(), []))
  :nitro.show(:frms)
end

  def event(:create_service_order) do
    :nitro.redirect("repair.htm")
  end

  def event(:create_transfer_order) do
    :nitro.redirect("logistics.htm")
  end

  def event(_), do: :ok

  def header() do
    NITRO.panel(
      id: :header,
      class: :th,
      body: [
        NITRO.panel(class: :column10, body: "ID"),
        NITRO.panel(class: :column20, body: "Серійний номер"),
        NITRO.panel(class: :column20, body: "Модель"),
        NITRO.panel(class: :column20, body: "Власник"),
        NITRO.panel(class: :column10, body: "Ліцензія"),
        NITRO.panel(class: :column20, body: "Локація"),
        NITRO.panel(class: :column20, body: "Статус")
      ]
    )
  end
end
