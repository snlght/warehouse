defmodule WMS.WeaponEvent.Details do
  require EXO
  require NITRO

  def new(event) do
    id =
      event
      |> EXO.wms_weapon_event(:id)
      |> :nitro.to_binary()

    weapon =
      event
      |> EXO.wms_weapon_event(:weapon)
      |> :nitro.to_binary()

    event_type =
      event
      |> EXO.wms_weapon_event(:event_type)
      |> :nitro.to_binary()
      |> WMS.WeaponEventView.event_type_title()

    event_status =
      event
      |> EXO.wms_weapon_event(:event_status)
      |> :nitro.to_binary()
      |> WMS.WeaponEventView.event_status_title()

    actor =
      event
      |> EXO.wms_weapon_event(:actor)
      |> :nitro.to_binary()

    source_type =
      event
      |> EXO.wms_weapon_event(:source_type)
      |> :nitro.to_binary()
      |> WMS.WeaponEventView.source_type_title()

    source_id =
      event
      |> EXO.wms_weapon_event(:source_id)
      |> :nitro.to_binary()

    from_storage =
      event
      |> EXO.wms_weapon_event(:from_storage)
      |> :nitro.to_binary()

    to_storage =
      event
      |> EXO.wms_weapon_event(:to_storage)
      |> :nitro.to_binary()

    related_service_order =
      event
      |> EXO.wms_weapon_event(:related_service_order)
      |> :nitro.to_binary()

    related_part =
      event
      |> EXO.wms_weapon_event(:related_part)
      |> :nitro.to_binary()

    occurred_at =
      event
      |> EXO.wms_weapon_event(:occurred_at)
      |> WMS.WeaponEventView.format_timestamp()

    recorded_at =
      event
      |> EXO.wms_weapon_event(:recorded_at)
      |> WMS.WeaponEventView.format_timestamp()

    description =
      event
      |> EXO.wms_weapon_event(:description)
      |> :nitro.to_binary()

    NITRO.panel(
      class: :weapon_event_details,
      body: [
        detail_row("ID", id),
        detail_row("Зброя", weapon),
        detail_row("Тип події", event_type),
        detail_row("Статус", event_status),
        detail_row("Виконавець", actor),
        detail_row("Джерело", source_type),
        detail_row("ID джерела", source_id),
        detail_row("Звідки", from_storage),
        detail_row("Куди", to_storage),
        detail_row("Сервісний наряд", related_service_order),
        detail_row("Деталь", related_part),
        detail_row("Час події", occurred_at),
        detail_row("Записано в систему", recorded_at),
        detail_row("Опис", description),
        NITRO.link(
          body: "Закрити",
          postback: :close_weapon_event_details,
          class: [:button, :sgreen]
        )
      ]
    )
  end

  defp detail_row(label, value) do
    value =
      value
      |> :nitro.to_binary()
      |> String.trim()

    if value == "" do
      []
    else
      NITRO.panel(
        class: :weapon_event_detail_row,
        body: [
          NITRO.span(
            class: :weapon_event_detail_label,
            body: "#{label}:"
          ),
          NITRO.span(
            class: :weapon_event_detail_value,
            body: value
          )
        ]
      )
    end
  end
end
