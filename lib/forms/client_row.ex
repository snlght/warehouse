defmodule Client.Row do
  require EXO
  require NITRO
  def doc(), do: "Форма-рядок для відображення користувача системи."
  def id(), do: EXO.client()

  def new(name, client, _) do
    phone = EXO.client(client, :phone)
    names = EXO.client(client, :names)
    surnames = EXO.client(client, :surnames)
    type = EXO.client(client, :type)
    status = EXO.client(client, :status)
    date = EXO.client(client, :date)

    NITRO.panel(
      id: :form.atom([:tr, name]),
      class: :td,
      body: [
        NITRO.panel(
          class: :column20,
          body:
            NITRO.link(
              href: "user.htm?p=" <> :nitro.to_binary(phone),
              body: names <> " " <> surnames
            )
        ),
        NITRO.panel(class: :column20, body: :nitro.to_binary(type)),
        NITRO.panel(class: :column20, body: :nitro.compact(date)),
        NITRO.panel(class: :column20, body: :nitro.compact(phone)),
        NITRO.panel(class: :column10, body: :nitro.to_binary(status))
      ]
    )
  end
end
