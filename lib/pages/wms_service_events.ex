defmodule EXO.WMS.ServiceEvents do
  require EXO
  require NITRO

  def event(:init) do
    :nitro.clear(:tableHead)
    :nitro.clear(:tableRow)
    :nitro.insert_top(:tableHead, header())

    :nitro.clear(:ctrl)

    build_form()

    :nitro.insert_bottom(
      :ctrl,
      NITRO.link(
        id: :creator,
        body: "Додати сервісну подію",
        postback: :create,
        class: [:button, :sgreen]
      )
    )

    :nitro.hide(:frms)

    :lists.map(
      fn x ->
        :nitro.insert_top(
          :tableRow,
          WMS.ServiceEvent.Row.new(:form.atom([:row, EXO.wms_service_event(x, :id)]), x, [])
        )
      end,
      :kvs.all(~c"/wms/service_events")
    )
  end

  def build_form() do
    :nitro.clear(:frms)

    :nitro.insert_bottom(
      :frms,
      NITRO.panel(id: :service_event_error, body: [])
    )

    :nitro.insert_bottom(
      :frms,
      service_order_lookup()
    )

    :nitro.insert_bottom(
      :frms,
      NITRO.panel(
        id: :service_event_form_container,
        body: []
      )
    )
  end

  defp service_order_lookup do
    NITRO.panel(
      id: :service_order_lookup,
      class: :service_order_lookup,
      body: [
        NITRO.panel(
          class: :service_order_lookup_title,
          body: "Вибір сервісного наряду"
        ),
        NITRO.panel(
          class: :wms_toolbar,
          body: [
            NITRO.panel(
              class: :toolbar_filters,
              body: [
                NITRO.input(
                  id: :service_order_search,
                  placeholder: "ID сервісного наряду"
                ),
                NITRO.link(
                  body: "Знайти",
                  postback: {:FindServiceOrder, []},
                  source: [:service_order_search],
                  class: [:button, :sgreen]
                )
              ]
            ),
            NITRO.panel(
              id: :service_order_info,
              body: []
            )
          ]
        )
      ]
    )
  end

  def event(:create) do
    build_form()
    :nitro.hide(:ctrl)
    :nitro.show(:frms)
  end

  def event({:SaveServiceEvent, service_order_id}) do
    fields = %{
      service_order: service_order_id,
      event_type: :nitro.q(:event_type_wms_service_event_none),
      actor: :nitro.q(:actor_wms_service_event_none),
      event_status: :nitro.q(:event_status_wms_service_event_none),
      condition: :nitro.q(:condition_wms_service_event_none),
      required_action: :nitro.q(:required_action_wms_service_event_none),
      result: :nitro.q(:result_wms_service_event_none),
      old_part: :nitro.q(:old_part_wms_service_event_none),
      new_part: :nitro.q(:new_part_wms_service_event_none)
    }

    case WMS.ServiceEventRules.create_service_event(fields) do
      {:ok, service_event} ->
        id = EXO.wms_service_event(service_event, :id)

        :nitro.insert_top(
          :tableRow,
          WMS.ServiceEvent.Row.new(:form.atom([:row, id]), service_event, [])
        )

        build_form()
        :nitro.hide(:frms)
        :nitro.show(:ctrl)

      {:error, message} ->
        WMS.UI.show_error(:service_event_error, message)
    end
  end

  def event({:FindServiceOrder, _}) do
    order_id = :nitro.q(:service_order_search)

    case WMS.ServiceEventRules.get_service_order(order_id) do
      {:ok, service_order} ->
        :nitro.clear(:service_event_error)
        :nitro.clear(:service_event_form_container)
        render_service_order_info(service_order)
        render_service_event_form(service_order)

      {:error, message} ->
        :nitro.clear(:service_order_info)
        :nitro.clear(:service_event_form_container)
        WMS.UI.show_error(:service_event_error, message)
    end
  end

  defp render_service_event_form(service_order) do
    order_id =
      service_order
      |> EXO.wms_service_order(:id)
      |> WMS.ServiceEventRules.clean()

    mod = WMS.ServiceEvent.Form

    form =
      :form.new(
        mod.new(:none, mod.id(), order_id),
        mod.id(),
        []
      )

    :nitro.clear(:service_event_form_container)

    :nitro.insert_bottom(:service_event_form_container, form)
  end

  defp render_service_order_info(service_order) do
    order_id =
      service_order
      |> EXO.wms_service_order(:id)
      |> WMS.ServiceEventRules.clean()

    weapon_id =
      service_order
      |> EXO.wms_service_order(:weapon)
      |> WMS.ServiceEventRules.clean()

    reason =
      service_order
      |> EXO.wms_service_order(:reason)
      |> WMS.ServiceEventRules.clean()

    status =
      service_order
      |> EXO.wms_service_order(:service_status)
      |> WMS.ServiceEventRules.status_title()

    :nitro.clear(:service_order_info)

    :nitro.insert_bottom(
      :service_order_info,
      NITRO.panel(
        class: :service_order_card,
        body: [
          NITRO.panel(
            class: :service_order_card_title,
            body: "Інформація про сервісний наряд"
          ),
          NITRO.panel(
            class: :service_order_card_row,
            body: "Наряд: #{order_id}"
          ),
          NITRO.panel(
            class: :service_order_card_row,
            body: "Зброя: #{weapon_id}"
          ),
          NITRO.panel(
            class: :service_order_card_row,
            body: "Причина: #{reason}"
          ),
          NITRO.panel(
            class: :service_order_card_row,
            body: "Статус: #{status}"
          )
        ]
      )
    )
  end

  def event({:Close, _}) do
    build_form()
    :nitro.hide(:frms)
    :nitro.show(:ctrl)
  end

  def header() do
    NITRO.panel(
      id: :header,
      class: :th,
      body: [
        NITRO.panel(class: :column10, body: "ID"),
        NITRO.panel(class: :column20, body: "Сервісний наряд"),
        NITRO.panel(class: :column20, body: "ID зброї"),
        NITRO.panel(class: :column20, body: "Тип події"),
        NITRO.panel(class: :column20, body: "Виконавець"),
        NITRO.panel(class: :column20, body: "Статус події"),
        NITRO.panel(class: :column20, body: "Стан"),
        NITRO.panel(class: :column20, body: "Необхідна дія"),
        NITRO.panel(class: :column20, body: "Результат"),
        NITRO.panel(class: :column20, body: "Стара деталь"),
        NITRO.panel(class: :column20, body: "Нова деталь")
      ]
    )
  end
end
