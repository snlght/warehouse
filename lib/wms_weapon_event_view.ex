defmodule WMS.WeaponEventView do
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

  def format_timestamp(timestamp) when is_integer(timestamp) do
    timestamp
    |> DateTime.from_unix!(:millisecond)
    |> Calendar.strftime("%Y-%m-%d %H:%M:%S")
  end

  def format_timestamp(_), do: ""

  def source_type_title("weapon"), do: "Зброя"
  def source_type_title("transfer"), do: "Переміщення"
  def source_type_title("storage"), do: "Склад"
  def source_type_title("service_order"), do: "Сервісний наряд"
  def source_type_title("service_event"), do: "Сервісна подія"
  def source_type_title("part"), do: "Деталь"
  def source_type_title(value), do: value
end
