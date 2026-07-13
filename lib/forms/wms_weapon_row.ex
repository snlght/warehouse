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
    license = EXO.wms_weapon(weapon, :license)
    storage_location = EXO.wms_weapon(weapon, :storage_location)

    status =
      weapon
      |> EXO.wms_weapon(:status)
      |> WMS.WeaponRules.clean()
      |> WMS.WeaponRules.status_title()

    NITRO.panel(
      id: :form.atom([:tr, name]),
      class: :td,
      body: [
        NITRO.panel(class: :column10, body: :nitro.to_binary(id)),
        NITRO.panel(class: :column20, body: :nitro.to_binary(serial_number)),
        NITRO.panel(class: :column20, body: :nitro.to_binary(model)),
        NITRO.panel(class: :column20, body: :nitro.to_binary(owner)),
        NITRO.panel(class: :column10, body: :nitro.to_binary(license)),
        NITRO.panel(class: :column20, body: :nitro.to_binary(storage_location)),
        NITRO.panel(class: :column20, body: :nitro.to_binary(status)),
        NITRO.panel(
          class: :column20,
          body:
            NITRO.link(
              body: "Редагувати",
              postback: {:EditWeapon, id},
              class: [:button, :sgreen]
            )
        )
      ]
    )
  end
end
