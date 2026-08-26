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
            NITRO.link(
              body: "Пошук",
              postback: :search_weapon_event,
              class: [:button, :sgreen],
              source: [:weapon_event_search]
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
