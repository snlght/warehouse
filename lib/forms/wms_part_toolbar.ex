defmodule WMS.Part.Toolbar do
  require NITRO

  def list_mode() do
    NITRO.panel(
      class: :wms_toolbar,
      body: [
        NITRO.panel(
          class: :toolbar_actions,
          body: [
            NITRO.link(
              id: :add_part,
              body: "Додати деталь",
              postback: :create,
              class: [:button, :sgreen]
            )
          ]
        ),
        NITRO.panel(
          class: :toolbar_filters,
          body: [
            NITRO.input(
              id: :part_search,
              placeholder: "ID, серійний номер, тип, виробник"
            ),
            NITRO.select(
              id: :part_status_filter,
              body: [
                NITRO.option(value: "all", body: "Усі статуси"),
                NITRO.option(value: "installed", body: "Встановлена"),
                NITRO.option(value: "spare", body: "Запасна"),
                NITRO.option(value: "broken", body: "Несправна"),
                NITRO.option(value: "removed", body: "Знята"),
                NITRO.option(value: "decommissioned", body: "Списана")
              ]
            ),
            NITRO.link(
              body: "Пошук",
              postback: :search_part,
              class: [:button, :sgreen],
              source: [:part_search, :part_status_filter]
            ),
            NITRO.link(
              body: "Очистити",
              postback: :clear_part_search,
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
