defmodule WMS.ServiceOrder.Row do
  require EXO
  require NITRO

  def id(), do: EXO.wms_service_order()
  def doc(), do: "Форма реєстрації сервісного замовлення (таблична частина)"
  def new(name, service_order, _) do
    id = EXO.wms_service_order(service_order, :id)
    weapon = EXO.wms_service_order(service_order, :weapon)
    reason = EXO.wms_service_order(service_order, :reason)
    status = EXO.wms_service_order(service_order, :service_status)
    result = EXO.wms_service_order(service_order, :result)

    NITRO.panel(
      id: :form.atom([:tr, name]),
      class: :td,
      body: [
        NITRO.panel(class: :column10, body: :nitro.to_binary(id)),
        NITRO.panel(class: :column20, body: :nitro.to_binary(weapon)),
        NITRO.panel(class: :column30, body: :nitro.to_binary(reason)),
        NITRO.panel(class: :column20, body: :nitro.to_binary(status)),
        NITRO.panel(class: :column20, body: :nitro.to_binary(result))
      ]
    )
  end
end
