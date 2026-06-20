defmodule WMS.WeaponEvent.Row do
  require EXO
  require NITRO

  @spec id() ::
          {:wms_weapon_event, [48 | 49 | 51 | 52 | 53 | 54 | 55 | 56, ...], [], [], <<>>, <<>>,
           <<>>, <<>>, <<>>, <<>>, <<>>, <<>>, <<>>, <<>>}
  def id(), do: EXO.wms_weapon_event()
  def doc(), do: "Історія подій зброї"

  def event_type_title("SERVICE_ORDER_CREATED"), do: "Створено сервісний наряд"
  def event_type_title("REPAIR_STARTED"), do: "Ремонт розпочато"
  def event_type_title("REPAIR_COMPLETED"), do: "Ремонт завершено"
  def event_type_title("TRANSFER_ORDER_CREATED"), do: "Створено наряд на переміщення"
  def event_type_title("TRANSFER_COMPLETED"), do: "Переміщення завершено"
  def event_type_title(value), do: value

  def event_status_title("created"), do: "Створено"
  def event_status_title("started"), do: "Розпочато"
  def event_status_title("completed"), do: "Завершено"
  def event_status_title(value), do: value

  def new(name, event, _) do
    id = EXO.wms_weapon_event(event, :id)
    weapon = EXO.wms_weapon_event(event, :weapon)
    event_type = EXO.wms_weapon_event(event, :event_type)
    actor = EXO.wms_weapon_event(event, :actor)
    event_status = EXO.wms_weapon_event(event, :event_status)
    from_storage = EXO.wms_weapon_event(event, :from_storage)
    to_storage = EXO.wms_weapon_event(event, :to_storage)
    related_service_order = EXO.wms_weapon_event(event, :related_service_order)
    related_part = EXO.wms_weapon_event(event, :related_part)
    created_at = EXO.wms_weapon_event(event, :created_at)

    NITRO.panel(
      id: :form.atom([:tr, name]),
      class: :td,
      body: [
        NITRO.panel(class: :column10, body: :nitro.to_binary(id)),
        NITRO.panel(class: :column10, body: :nitro.to_binary(weapon)),
        event_type |> :nitro.to_binary() |> event_type_title(),
        NITRO.panel(class: :column10, body: :nitro.to_binary(actor)),
        event_status |> :nitro.to_binary() |> event_status_title(),
        NITRO.panel(class: :column10, body: :nitro.to_binary(from_storage)),
        NITRO.panel(class: :column10, body: :nitro.to_binary(to_storage)),
        NITRO.panel(class: :column10, body: :nitro.to_binary(related_service_order)),
        NITRO.panel(class: :column10, body: :nitro.to_binary(related_part)),
        NITRO.panel(class: :column20, body: :nitro.to_binary(created_at))
      ]
    )
  end
end
