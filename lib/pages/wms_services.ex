defmodule EXO.WMS.Services do
  require EXO
  require NITRO
  require FORM

  def event(:init) do
    :nitro.clear(:tableHead)
    :nitro.clear(:tableRow)
    :nitro.clear(:ctrl)
    :nitro.clear(:frms)

    :nitro.insert_top(
      :tableHead,
      NITRO.panel(
        id: :header,
        class: :th,
        body: [
          NITRO.panel(class: :column10, body: "ID"),
          NITRO.panel(class: :column10, body: "ID зброї"),
          NITRO.panel(class: :column20, body: "Причина"),
          NITRO.panel(class: :column10, body: "Статус"),
          NITRO.panel(class: :column20, body: "Результат"),
          NITRO.panel(class: :column20, body: "Прийняв"),
          NITRO.panel(class: :column10, body: "Дія")
        ]
      )
    )

    :nitro.insert_bottom(
      :ctrl,
      NITRO.link(
        id: :new_order,
        body: "Новий наряд",
        postback: :new_order,
        class: [:button, :sgreen]
      )
    )

    :nitro.hide(:frms)

    records = :kvs.all(~c"/wms/service_orders")

    Enum.each(records, fn order ->
      id = EXO.wms_service_order(order, :id)
      :nitro.insert_bottom(:tableRow, WMS.ServiceOrder.Row.new(id, order, []))
    end)
  end

  def event(:new_order) do
    :nitro.hide(:ctrl)
    build_form()
    :nitro.show(:frms)
  end

  def event({:Close, _}) do
    :nitro.hide(:frms)
    :nitro.show(:ctrl)
  end

  def event({:OpenRepair, id}) do
    case WMS.ServiceEventRules.get_service_order(id) do
      {:ok, order} ->
        render_repair(order)

      {:error, reason} ->
        IO.inspect(reason, label: "error opening repair")
    end
  end

  def event({:CreateSO, _form}) do
    id = WMS.BusinessNumber.service_order()
    weapon = :nitro.to_binary(:nitro.q(:weapon_wms_service_order_none))
    reason = :nitro.to_binary(:nitro.q(:reason_wms_service_order_none))
    received_by = :nitro.to_binary(:nitro.q(:received_by_wms_service_order_none))

    cond do
      weapon != [] and not WMS.WeaponRules.weapon_exists?(weapon) ->
        WMS.UI.show_error(:service_order_error, "Помилка: зброї з таким ID не існує")

      weapon != [] and not WMS.WeaponRules.available_for_service?(weapon) ->
        WMS.UI.show_error(
          :service_order_error,
          "Помилка: сервісний наряд можна створити тільки для зброї зі статусом 'На озброєнні'"
        )

      true ->
        order =
          EXO.wms_service_order(
            id: id,
            weapon: weapon,
            reason: reason,
            received_by: received_by,
            service_status: "Init",
            result: ""
          )

        :kvs.append(order, ~c"/wms/service_orders")
        create_weapon_event_from_service_order(order, "Init")
        :nitro.insert_bottom(:tableRow, WMS.ServiceOrder.Row.new(id, order, []))

        :bpe.start(WMS.BPE.ServiceOrder.def(), [])

        build_form()

        :nitro.hide(:frms)
        :nitro.show(:ctrl)
    end
  end

  def event({:NextStatus, id}) do
    order =
      :kvs.all(~c"/wms/service_orders")
      |> Enum.find(fn order ->
        normalize_id(EXO.wms_service_order(order, :id)) == normalize_id(id)
      end)

    if order != nil do
      current_status = EXO.wms_service_order(order, :service_status)
      new_status = next_status(:nitro.to_binary(current_status))

      weapon_id = EXO.wms_service_order(order, :weapon)
      updated_order = EXO.wms_service_order(order, service_status: new_status)

      case new_status do
        "Repair" ->
          update_weapon_status(weapon_id, "repair")

        "Ready" ->
          update_weapon_status(weapon_id, "active")

        _ ->
          :ok
      end

      create_weapon_event_from_service_order(order, new_status)

      :kvs.remove(order, ~c"/wms/service_orders")
      :kvs.append(updated_order, ~c"/wms/service_orders")

      event(:init)
    end
  end

  def event({:ChoosePart, requirement_id}) do
    case WMS.PartRequirementRules.get_part_requirement(requirement_id) do
      {:ok, requirement} ->
        render_part_choices(requirement)

      {:error, reason} ->
        IO.inspect(reason, label: "error fetching requirement for ChoosePart")
    end
  end

  def event({:ReservePart, requirement_id, part_id}) do
    case WMS.PartReservationCoordinator.reserve(
           requirement_id,
           part_id,
           "TEST_USER"
         ) do
      {:ok, _reservation} ->
        {:ok, requirement} =
          WMS.PartRequirementRules.get_part_requirement(requirement_id)

        service_order_id =
          requirement
          |> EXO.wms_part_requirement(:service_order)
          |> normalize_id()

        {:ok, order} =
          WMS.ServiceEventRules.get_service_order(service_order_id)

        render_repair(order)

      {:error, reason} ->
        IO.inspect(reason, label: "error reserving part")
    end
  end

  def event(_), do: :ok

  defp render_part_choices(requirement) do
    req_id =
      requirement
      |> EXO.wms_part_requirement(:id)
      |> normalize_id()

    part_type =
      requirement
      |> EXO.wms_part_requirement(:part_type)
      |> normalize_id()

    parts = WMS.PartRules.list_reservable_by_type(part_type)

    parts_body =
      case parts do
        [] ->
          NITRO.panel(body: "Доступних деталей немає")

        items ->
          Enum.map(items, fn part ->
            part_id =
              part
              |> EXO.wms_part(:id)
              |> normalize_id()

            NITRO.panel(
              body: [
                NITRO.panel(body: "ID: #{part_id}"),
                NITRO.link(
                  body: "Зарезервувати",
                  postback: {:ReservePart, req_id, part_id},
                  class: [:button, :sgreen]
                )
              ]
            )
          end)
      end

    :nitro.clear(:ctrl)

    :nitro.insert_bottom(
      :ctrl,
      NITRO.panel(
        body: [
          NITRO.panel(body: "Вибір деталі: #{part_type}"),
          parts_body
        ]
      )
    )
  end

  def normalize_id(value) do
    value
    |> :nitro.to_binary()
    |> String.trim()
  end

  def weapon_exists(weapon_id) do
    wanted_id = normalize_id(weapon_id)

    :kvs.all(~c"/wms/weapons")
    |> Enum.any?(fn weapon ->
      current_id =
        weapon
        |> EXO.wms_weapon(:id)
        |> normalize_id()

      current_id == wanted_id
    end)
  end

  def update_weapon_status(weapon_id, new_status) do
    weapon =
      :kvs.all(~c"/wms/weapons")
      |> Enum.find(fn weapon ->
        normalize_id(EXO.wms_weapon(weapon, :id)) == normalize_id(weapon_id)
      end)

    if weapon != nil do
      updated_weapon = EXO.wms_weapon(weapon, status: new_status)

      WMS.WeaponRules.update_weapon(updated_weapon)
    end
  end

  def create_weapon_event_from_service_order(order, new_status) do
    weapon =
      order
      |> EXO.wms_service_order(:weapon)
      |> normalize_id()

    order_id =
      order
      |> EXO.wms_service_order(:id)
      |> normalize_id()

    actor =
      order
      |> EXO.wms_service_order(:received_by)
      |> normalize_id()

    case new_status do
      "Init" ->
        WMS.WeaponEventRules.create(%{
          weapon: weapon,
          event_type: "service_order_created",
          event_status: "created",
          actor: actor,
          source_type: "service_order",
          source_id: order_id,
          related_service_order: order_id
        })

      "Repair" ->
        WMS.WeaponEventRules.create(%{
          weapon: weapon,
          event_type: "service_started",
          event_status: "started",
          actor: actor,
          source_type: "service_order",
          source_id: order_id,
          related_service_order: order_id
        })

      "Ready" ->
        WMS.WeaponEventRules.create(%{
          weapon: weapon,
          event_type: "service_completed",
          event_status: "completed",
          actor: actor,
          source_type: "service_order",
          source_id: order_id,
          related_service_order: order_id
        })

      _ ->
        :ok
    end
  end

  def build_form() do
    :nitro.clear(:frms)

    :nitro.insert_bottom(
      :frms,
      NITRO.panel(id: :service_order_error, body: [])
    )

    mod = WMS.ServiceOrder.Form
    form = mod.new(:none, mod.id(), [])
    :nitro.insert_bottom(:frms, :form.new(form, mod.id(), []))
  end

  def next_status("Init"), do: "Diagnostic"
  def next_status("Diagnostic"), do: "Repair"
  def next_status("Repair"), do: "Testing"
  def next_status("Testing"), do: "Ready"
  def next_status("Ready"), do: "Ready"
  def next_status(_), do: "Init"

  defp render_repair(order) do
    id =
      order
      |> EXO.wms_service_order(:id)
      |> normalize_id()

    requirements = WMS.PartRequirementRules.list_by_service_order(id)

    requirements_body =
      case requirements do
        [] ->
          NITRO.panel(body: "Потреби в деталях ще немає")

        items ->
          Enum.map(items, fn {:ok, requirement} ->
            requirement_id =
              requirement
              |> EXO.wms_part_requirement(:id)
              |> normalize_id()

            part_type =
              requirement
              |> EXO.wms_part_requirement(:part_type)
              |> normalize_id()

            status =
              requirement
              |> EXO.wms_part_requirement(:status)
              |> normalize_id()

            action =
              case status do
                "requested" ->
                  NITRO.link(
                    body: "Обрати деталь",
                    postback: {:ChoosePart, requirement_id},
                    class: [:button, :sgreen]
                  )

                _ ->
                  []
              end

            NITRO.panel(
              body: [
                NITRO.panel(body: part_type),
                NITRO.panel(body: "Статус: #{status}"),
                NITRO.panel(body: "ID #{requirement_id}"),
                action
              ]
            )
          end)
      end

    IO.inspect(requirements, label: "requirements for service order #{id}")

    weapon =
      order
      |> EXO.wms_service_order(:weapon)
      |> normalize_id()

    reason =
      order
      |> EXO.wms_service_order(:reason)
      |> normalize_id()

    :nitro.clear(:tableHead)
    :nitro.clear(:tableRow)
    :nitro.clear(:ctrl)
    :nitro.clear(:frms)

    :nitro.insert_bottom(
      :ctrl,
      NITRO.panel(
        body: [
          NITRO.panel(body: "Ремонт #{id}"),
          NITRO.panel(body: "Зброя: #{weapon}"),
          NITRO.panel(body: "Причина: #{reason}"),
          NITRO.panel(body: "Необхідні деталі:"),
          requirements_body
        ]
      )
    )
  end
end
