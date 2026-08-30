defmodule WMS.WeaponEvent.Row do
  require EXO
  require NITRO

  def id(), do: EXO.wms_weapon_event()
  def doc(), do: "Історія подій зброї"


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
    occurred_at = EXO.wms_weapon_event(event, :occurred_at)

    NITRO.panel(
      id: :form.atom([:tr, name]),
      class: :td,
      body: [
        NITRO.panel(class: :column10, body: :nitro.to_binary(id)),
        NITRO.panel(class: :column10, body: :nitro.to_binary(weapon)),
        NITRO.panel(
          class: :column20,
          body: event_type |> :nitro.to_binary() |> WMS.WeaponEventView.event_type_title()
        ),
        NITRO.panel(class: :column10, body: :nitro.to_binary(actor)),
        NITRO.panel(
          class: :column20,
          body: event_status |> :nitro.to_binary() |> WMS.WeaponEventView.event_status_title()
        ),
        NITRO.panel(class: :column10, body: :nitro.to_binary(from_storage)),
        NITRO.panel(class: :column10, body: :nitro.to_binary(to_storage)),
        NITRO.panel(class: :column10, body: :nitro.to_binary(related_service_order)),
        NITRO.panel(class: :column10, body: :nitro.to_binary(related_part)),
        NITRO.panel(
          class: :column20,
          body: occurred_at |> WMS.WeaponEventView.format_timestamp()
        ),
        NITRO.panel(
          class: :column10,
          body: NITRO.link(
            body: "Деталі",
            postback: {:show_weapon_event, id},
            class: [:button, :sgreen]
          )

        )
      ]
    )
  end
end
