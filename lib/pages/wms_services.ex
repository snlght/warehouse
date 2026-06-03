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
          NITRO.panel(class: :column20, body: "WEAPON"),
          NITRO.panel(class: :column30, body: "REASON"),
          NITRO.panel(class: :column20, body: "STATUS"),
          NITRO.panel(class: :column20, body: "RESULT")
        ]
      )
    )

    :nitro.insert_bottom(:ctrl, NITRO.link(id: :new_order, body: "Новий наряд", postback: :new_order, class: [:button, :sgreen]))
    :nitro.hide(:frms)

    records = :kvs.all(EXO.wms_service_order())
    Enum.each(records, fn order ->
      id = EXO.wms_service_order(order, :id)
      :nitro.insert_bottom(:tableRow, WMS.ServiceOrder.Row.new(id, order, []))
    end)
  end

  def event({:CreateSO, _form}) do
    id = :kvs.seq([], [])
    weapon = :nitro.to_binary(:nitro.q(:weapon_wms_service_order_none))
    reason = :nitro.to_binary(:nitro.q(:reason_wms_service_order_none))
    order = EXO.wms_service_order(
      id: id,
      weapon: weapon,
      reason: reason,
      service_status: "Init",
      result: ""
    )
    :kvs.put(order)
    :nitro.insert_bottom(:tableRow, WMS.ServiceOrder.Row.new(id, order, []))
    # Init BPE Process
    :bpe.start(WMS.BPE.ServiceOrder.def(), [])
    # Here you'd normally link the BPE process to the document and advance the state.
    :nitro.hide(:frms)
    :nitro.show(:ctrl)
  end

  def event(:new_order) do
    :nitro.hide(:ctrl)
    :nitro.clear(:frms)
    form = WMS.ServiceOrder.Form.new(:none, [], [])
    :nitro.insert_bottom(:frms, :form.new(form, :none, []))
    :nitro.show(:frms)
  end

  def event({:Close, _}) do
    :nitro.hide(:frms)
    :nitro.show(:ctrl)
  end
  def event(_), do: :ok
end
