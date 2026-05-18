defmodule Client.Form do
  require EXO
  require NITRO
  require FORM
  require BPE
  def doc(), do: "Форма вводу користувача системи"
  def id, do: EXO.client()
  def new([], _, _), do: []

  def new(name, _client, _) do
    :erlang.put(:type_client_none, :consumer)

    FORM.document(
      name: :form.atom([:client, name]),
      sections: [FORM.sec(name: ["Створити користувача: "])],
      buttons: [
        FORM.but(
          id: :decline,
          name: :decline,
          title: "Відміна",
          class: [:cancel],
          postback: {:Close, []}
        ),
        FORM.but(
          id: :proceed,
          name: :proceed,
          title: "Створити",
          class: [:button, :sgreen],
          sources: [
            :surnames_client_none,
            :names_client_none,
            :phone_client_none,
            :type_client_none
          ],
          postback: {:CreateClient, :form.atom([:client, name])}
        )
      ],
      fields: [
        FORM.field(
          id: :surnames,
          name: :surnames,
          type: :string,
          title: "Прізвища:",
          labelClass: :label
        ),
        FORM.field(
          id: :names,
          name: :names,
          type: :string,
          title: "Імена",
          labelClass: :label
        ),
        FORM.field(
          id: :phone,
          name: :phone,
          type: :string,
          title: "Телефон",
          labelClass: :label
        ),
        FORM.field(
          id: :type,
          name: :type,
          title: "Тип:",
          type: :select,
          default: :consumer,
          options: [
            FORM.opt(name: :consumer, checked: true, title: "Споживач"),
            FORM.opt(name: :admin, title: "Адміністратор")
          ]
        )
      ]
    )
  end
end
