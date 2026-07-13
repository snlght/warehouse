defmodule WMS.Part.EditForm do
  require EXO
  require FORM

  def id(), do: EXO.wms_part()

  def new(name, part, _) do
    FORM.document(
      name: :form.atom([:wms_part_edit, name]),
      sections: [
        FORM.sec(name: ["Редагування деталі: ", EXO.wms_part(part, :id)])
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
            :serial_number_wms_part_create,
            :part_type_wms_part_create,
            :part_status_wms_part_create,
            :installed_in_weapon_wms_part_create,
            :storage_location_wms_part_create,
            :manufacturer_wms_part_create
          ],
          postback: {:UpdatePart, EXO.wms_part(part, :id)}
        )
      ],
      fields: [
        FORM.field(
          id: :serial_number,
          name: :serial_number,
          type: :string,
          title: "Серійний номер",
          labelClass: :label,
          default: EXO.wms_part(part, :serial_number)
        ),
        FORM.field(
          id: :part_type,
          name: :part_type,
          type: :string,
          title: "Тип",
          labelClass: :label,
          default: EXO.wms_part(part, :part_type)
        ),
        FORM.field(
          id: :part_status,
          name: :part_status,
          type: :string,
          title: "Статус",
          labelClass: :label,
          default: EXO.wms_part(part, :part_status)
        ),
        FORM.field(
          id: :installed_in_weapon,
          name: :installed_in_weapon,
          type: :string,
          title: "ID зброї",
          labelClass: :label,
          default: EXO.wms_part(part, :installed_in_weapon)
        ),
        FORM.field(
          id: :storage_location,
          name: :storage_location,
          type: :string,
          title: "Локація зберігання",
          labelClass: :label,
          default: EXO.wms_part(part, :storage_location)
        ),
        FORM.field(
          id: :manufacturer,
          name: :manufacturer,
          type: :string,
          title: "Виробник",
          labelClass: :label,
          default: EXO.wms_part(part, :manufacturer)
        )
      ]
    )
  end
end
