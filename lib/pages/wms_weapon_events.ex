defmodule EXO.WMS.WeaponEvents do
  require EXO
  require NITRO

  def event(:init) do
    :nitro.clear(:tableHead)
    :nitro.clear(:tableRow)
    :nitro.clear(:ctrl)
    :nitro.clear(:frms)

    :nitro.insert_top(:tableHead, header())

    render_toolbar(:list)

    render_events("", "all")
  end

  def event(:search_weapon_event) do
    weapon_id =
      :nitro.q(:weapon_event_search)
      |> normalize_filter()

    event_type =
      :nitro.q(:weapon_event_type_filter)
      |> normalize_filter()

    :nitro.clear(:tableRow)

    render_events(weapon_id, event_type)
  end

  def event(:clear_weapon_event_search) do
    render_toolbar(:list)

    :nitro.clear(:tableRow)

    render_events("", "all")
  end

  def event(_), do: :ok

  defp render_toolbar(:list) do
    :nitro.clear(:ctrl)

    :nitro.insert_bottom(
      :ctrl,
      WMS.WeaponEvent.Toolbar.list_mode()
    )
  end

  defp load_events() do
    :kvs.all(~c"/wms/weapon_events")
  end

  defp normalize_filter(value) do
    value
    |> :nitro.to_binary()
    |> String.trim()
  end

  defp filter_events_by_weapon(events, ""), do: events

  defp filter_events_by_weapon(events, weapon_id) do
    Enum.filter(events, fn event ->
      current_weapon =
        event
        |> EXO.wms_weapon_event(:weapon)
        |> normalize_filter()

      current_weapon == weapon_id
    end)
  end

  defp filter_events_by_type(events, "all"), do: events
  defp filter_events_by_type(events, ""), do: events

  defp filter_events_by_type(events, event_type) do
    Enum.filter(events, fn event ->
      current_type =
        event
        |> EXO.wms_weapon_event(:event_type)
        |> normalize_filter()

      current_type == event_type
    end)
  end

  defp sort_events(events) do
    Enum.sort_by(
      events,
      fn event ->
        EXO.wms_weapon_event(event, :occurred_at)
      end,
      :desc
    )
  end

  defp render_rows(events) do
    Enum.each(events, fn event ->
      id = EXO.wms_weapon_event(event, :id)

      :nitro.insert_bottom(
        :tableRow,
        WMS.WeaponEvent.Row.new(:form.atom([:row, id]), event, [])
      )
    end)
  end

  defp render_events(weapon_id, event_type) do
    weapon_id = normalize_filter(weapon_id)
    event_type = normalize_filter(event_type)

    load_events()
    |> filter_events_by_weapon(weapon_id)
    |> filter_events_by_type(event_type)
    |> sort_events()
    |> render_rows()
  end

  def header() do
    NITRO.panel(
      id: :header,
      class: :th,
      body: [
        NITRO.panel(class: :column10, body: "ID"),
        NITRO.panel(class: :column10, body: "Зброя"),
        NITRO.panel(class: :column20, body: "Тип події"),
        NITRO.panel(class: :column10, body: "Виконавець"),
        NITRO.panel(class: :column10, body: "Статус"),
        NITRO.panel(class: :column10, body: "Звідки"),
        NITRO.panel(class: :column10, body: "Куди"),
        NITRO.panel(class: :column10, body: "Наряд"),
        NITRO.panel(class: :column10, body: "Деталь"),
        NITRO.panel(class: :column20, body: "Час")
      ]
    )
  end
end
