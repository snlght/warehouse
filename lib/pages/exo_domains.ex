defmodule EXO.Domains do
  require EXO
  require BPE
  require NITRO

  def event(:init) do
    :nitro.clear(:tableHead)
    :nitro.clear(:tableRow)
    :nitro.insert_top(:tableHead, header())
    :nitro.clear(:frms)
    :nitro.clear(:ctrl)
    mod = Client.Form

    :nitro.insert_bottom(
      :frms,
      :form.new(mod.new(mod, mod.id(), []), mod.id(), [])
    )

    :nitro.insert_bottom(
      :ctrl,
      NITRO.link(id: :creator, body: "Новий", postback: :create, class: [:button, :sgreen])
    )

    :nitro.hide(:frms)

    :lists.map(
      fn x ->
        :nitro.insert_top(
          :tableRow,
          Client.Row.new(:form.atom([:row, EXO.client(x, :id)]), x, [])
        )
      end,
      :kvs.all(~c"/exo/clients")
    )
  end

  def event(:create) do
    :nitro.hide(:ctrl)
    :nitro.show(:frms)
  end

  def event({:CreateClient, _}) do
    date = :calendar.now_to_datetime(:erlang.timestamp())
    type = :nitro.q(:type_client_none)
    names = :nitro.q(:names_client_none)
    phone = :nitro.q(:phone_client_none)
    surnames = :nitro.q(:surnames_client_none)
    id = :kvs.seq([], [])

    client =
      EXO.client(
        id: id,
        phone: phone,
        names: names,
        surnames: surnames,
        status: :online,
        type: type,
        date: date
      )

    nitro = :form.new(Client.Row.new(:form.atom([:row, id]), client, []), client, [])
    :kvs.append(client, ~c"/exo/clients")
    :nitro.insert_top(:tableRow, nitro)
    :nitro.hide(:frms)
    :nitro.show(:ctrl)
  end

  def event({:Close, []}) do
    :nitro.hide(:frms)
    :nitro.show(:ctrl)
  end

  def event(_), do: :ok

  def header() do
    NITRO.panel(
      id: :header,
      class: :th,
      body: [
        NITRO.panel(class: :column20, body: "ПІБ"),
        NITRO.panel(class: :column20, body: "Тип"),
        NITRO.panel(class: :column20, body: "Дата"),
        NITRO.panel(class: :column20, body: "Телефон"),
        NITRO.panel(class: :column10, body: "Статус")
      ]
    )
  end
end
