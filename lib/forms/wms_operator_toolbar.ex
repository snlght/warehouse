defmodule WMS.Operator.Toolbar do
  require NITRO

  def new() do
    NITRO.panel(
      class: :operator_toolbar,
      body: [
        NITRO.panel(
          class: :toolbar_actions,
          body: [
            NITRO.link(
              id: :create_service_order,
              body: "Заявка на ремонт",
              postback: :create_service_order,
              class: [:button, :sgreen]
            ),
            NITRO.link(
              id: :create_transfer_order,
              body: "Заявка на переміщення",
              postback: :create_transfer_order,
              class: [:button, :sgreen]
            ),
            NITRO.link(
              id: :add_weapon,
              body: "Додати зброю",
              postback: :add_weapon,
              class: [:button, :sgreen]
            )
          ]
        ),
        NITRO.panel(
          class: :toolbar_filters,
          body: [
            NITRO.input(
              id: :weapon_search,
              placeholder: "Пошук: ID, серійний номер, модель, власник"
            ),
            NITRO.select(
              id: :weapon_status_filter,
              body: [
                NITRO.option(value: "all", body: "Усі статуси"),
                NITRO.option(value: "active", body: "На озброєнні"),
                NITRO.option(value: "repair", body: "На ремонті"),
                NITRO.option(value: "maintenance", body: "На обслуговуванні"),
                NITRO.option(value: "transfer", body: "У дорозі"),
                NITRO.option(value: "decommissioned", body: "Списана"),
                NITRO.option(value: "destroyed", body: "Знищено")
              ]
            ),
            NITRO.link(
              body: "Пошук",
              postback: :search_weapon,
              source: [:weapon_search, :weapon_status_filter],
              class: [:button, :sgreen]
            ),
            NITRO.link(
              body: "Очистити",
              postback: :clear_weapon_search,
              class: [:button, :sgreen]
            )
          ]
        )
      ]
    )
  end
end
