defmodule WMS.WeaponEvent.Row do
  require EXO
  require NITRO

  def id(), do: EXO.wms_weapon_event()
  def doc(), do: "Історія подій зброї"

  def event_status_title("created"), do: "Створено"
  def event_status_title("started"), do: "Розпочато"
  def event_status_title("completed"), do: "Завершено"
  def event_status_title("planned"), do: "Заплановано"
  def event_status_title("in_progress"), do: "У процесі"
  def event_status_title("cancelled"), do: "Скасовано"
  def event_status_title(value), do: value

  def event_type_title("registered"), do: "Зброю зареєстровано"
  def event_type_title("status_changed"), do: "Статус зброї змінено"
  def event_type_title("transferred"), do: "Переміщення завершено"
  def event_type_title("service_order_created"), do: "Створено сервісний наряд"
  def event_type_title("service_started"), do: "Сервіс розпочато"
  def event_type_title("service_completed"), do: "Сервіс завершено"
  def event_type_title("part_removed"), do: "Деталь знято"
  def event_type_title("part_installed"), do: "Деталь встановлено"
  def event_type_title("part_replaced"), do: "Деталь замінено"
  def event_type_title("issued"), do: "Зброю видано"
  def event_type_title("returned"), do: "Зброю повернуто"
  def event_type_title("decommissioned"), do: "Зброю списано"
  def event_type_title(value), do: value

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
          body: event_type |> :nitro.to_binary() |> event_type_title()
        ),
        NITRO.panel(class: :column10, body: :nitro.to_binary(actor)),
        NITRO.panel(
          class: :column20,
          body: event_status |> :nitro.to_binary() |> event_status_title()
        ),
        NITRO.panel(class: :column10, body: :nitro.to_binary(from_storage)),
        NITRO.panel(class: :column10, body: :nitro.to_binary(to_storage)),
        NITRO.panel(class: :column10, body: :nitro.to_binary(related_service_order)),
        NITRO.panel(class: :column10, body: :nitro.to_binary(related_part)),
        NITRO.panel(
          class: :column20,
          body: format_timestamp(occurred_at)
        )
      ]
    )
  end

  defp format_timestamp(timestamp) when is_integer(timestamp) do
    timestamp
    |> DateTime.from_unix!(:millisecond)
    |> Calendar.strftime("%Y-%m-%d %H:%M:%S")
  end

  defp format_timestamp(_), do: ""
end
