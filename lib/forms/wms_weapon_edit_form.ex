defmodule WMS.Weapon.EditForm do
  require EXO
  require FORM

  def id(), do: EXO.wms_weapon()

  def new(name, weapon, _) do
    FORM.document(
      name: :form.atom([:wms_weapon_edit, name]),
      sections: [
        FORM.sec(name: ["Редагування зброї: ", EXO.wms_weapon(weapon, :id)])
      ],
      buttons: [
        FORM.but(
          id: :decline,
          name: :decline,
          title: "Відміна",
          class: [:button, :cancel],
          postback: {:Close, []}
        ),
        FORM.but(
          id: :proceed,
          name: :proceed,
          title: "Зберегти",
          class: [:button, :sgreen],
          sources: [
            :serial_number_wms_weapon_create,
            :weapon_model_wms_weapon_create,
            :owner_wms_weapon_create,
            :storage_location_wms_weapon_create,
            :license_wms_weapon_create


          ],
          postback: {:UpdateWeapon, EXO.wms_weapon(weapon, :id)}
        )
      ],
      fields: [
        FORM.field(
          id: :serial_number,
          name: :serial_number,
          type: :string,
          title: "Серійний номер",
          labelClass: :label,
          default: EXO.wms_weapon(weapon, :serial_number)
        ),
        FORM.field(
          id: :weapon_model,
          name: :weapon_model,
          type: :string,
          title: "Модель зброї(ID)",
          labelClass: :label,
          default: EXO.wms_weapon(weapon, :weapon_model)
        ),
        FORM.field(
          id: :owner,
          name: :owner,
          type: :string,
          title: "Власник",
          labelClass: :label,
          default: EXO.wms_weapon(weapon, :owner)
        ),
        FORM.field(
          id: :storage_location,
          name: :storage_location,
          type: :string,
          title: "Локація зберігання",
          labelClass: :label,
          default: EXO.wms_weapon(weapon, :storage_location)
        ),
        FORM.field(
          id: :license,
          name: :license,
          type: :string,
          title: "Ліцензія/дозвіл",
          labelClass: :label,
          default: EXO.wms_weapon(weapon, :license)
        )
      ]
    )
  end
end
