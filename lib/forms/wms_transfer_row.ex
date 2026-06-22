defmodule WMS.TransferOrder.Row do
  require EXO
  require NITRO

  def id(), do: EXO.wms_transfer()
  def doc(), do: "Форма наряду на переміщення (таблична частина)"

  def status_title("Init"), do: "Створено"
  def status_title("Transit"), do: "У дорозі"
  def status_title("Delivered"), do: "Доставлено"
  def status_title(value), do: value

  def new(name, transfer_order, _) do
    id = EXO.wms_transfer(transfer_order, :id)
    weapon = EXO.wms_transfer(transfer_order, :weapon)
    from_storage = EXO.wms_transfer(transfer_order, :from_storage)
    to_storage = EXO.wms_transfer(transfer_order, :to_storage)
    status = EXO.wms_transfer(transfer_order, :transfer_status)

    status_value =
      status
      |> :nitro.to_binary()
      |> String.trim()

    action =
      case status_value do
        "Delivered" ->
          NITRO.panel(
            style: "padding:8px 0;color:#6b7280;font-weight:600;",
            body: "✓ Доставлено"
          )

        _ ->
          NITRO.link(
            body: "Далі",
            postback: {:NextStatus, id},
            class: [:button, :sgreen]
          )
      end

    NITRO.panel(
      id: :form.atom([:tr, name]),
      class: :td,
      body: [
        NITRO.panel(class: :column10, body: :nitro.to_binary(id)),
        NITRO.panel(class: :column20, body: :nitro.to_binary(weapon)),
        NITRO.panel(class: :column20, body: :nitro.to_binary(from_storage)),
        NITRO.panel(class: :column20, body: :nitro.to_binary(to_storage)),
        NITRO.panel(class: :column20, body: status_title(status_value)),
        NITRO.panel(class: :column10, body: action)
      ]
    )
  end
end
