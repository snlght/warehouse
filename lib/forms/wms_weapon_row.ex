defmodule WMS.Weapon.Row do
  require EXO
  require NITRO
  require FORM

  def id(), do: EXO.wms_weapon()
  def doc(), do: "Форма реєстрації зброї (таблична частина)"
  def new(name, weapon, _) do
    id = EXO.wms_weapon(weapon, :id)
    serial_number = EXO.wms_weapon(weapon, :serial_number)
    model = EXO.wms_weapon(weapon, :weapon_model)
    owner = EXO.wms_weapon(weapon, :owner)
    status = EXO.wms_weapon(weapon, :status)

    NITRO.panel(
      id: :form.atom([:tr, name]),
      class: :td,
      body: [
        NITRO.panel(class: :column10, body: :nitro.to_binary(id)),
        NITRO.panel(class: :column20, body: :nitro.to_binary(serial_number)),
        NITRO.panel(class: :column20, body: :nitro.to_binary(model)),
        NITRO.panel(class: :column30, body: :nitro.to_binary(owner)),
        NITRO.panel(class: :column20, body: :nitro.to_binary(status))
      ]
    )
  end
end
