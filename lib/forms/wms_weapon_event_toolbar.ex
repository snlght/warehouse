defmodule WMS.WeaponEvent.Toolbar do
  require NITRO

  def list_mode() do
    NITRO.panel(
      class: :wms_toolbar,
      body: [
        NITRO.panel(
          class: :toolbar_filters,
          body: [
            NITRO.input(
              id: :weapon_event_search,
              placeholder: "ID зброї"
            ),
            NITRO.select(
              id: :weapon_event_type_filter,
              body: [
                NITRO.option(value: "all", body: "Усі типи подій"),
                NITRO.option(value: "registered", body: "Реєстрація"),
                NITRO.option(value: "transferred", body: "Переміщення"),
                NITRO.option(value: "service_order_created", body: "Сервісний наряд"),
                NITRO.option(value: "service_started", body: "Початок сервісу"),
                NITRO.option(value: "service_completed", body: "Завершення сервісу"),
              ]
            ),

            NITRO.link(
              body: "Пошук",
              postback: :search_weapon_event,
              class: [:button, :sgreen],
              source: [
                :weapon_event_search,
                :weapon_event_type_filter
              ]
            ),
            NITRO.link(
              body: "Очистити",
              postback: :clear_weapon_event_search,
              class: [:button, :sgreen]
            )
          ]
        )
      ]
    )
  end

  def form_mode() do
    NITRO.panel(
      class: :wms_toolbar,
      body: []
    )
  end
end
