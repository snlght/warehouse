defmodule BPE.Pass do
  require FORM
  require EXO

  def doc(), do: "Форма одноразового OTP паролю для 2FA"

  def id(), do: EXO.phone()

  def new(name, _, _) do
    FORM.document(
      name: :form.atom([:otp, name]),
      sections: [FORM.sec(name: ["Аутентифікуйтесь: "])],
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
          title: "Далі",
          class: [:button, :sgreen],
          sources: [:number_phone_none, :auth_phone_none],
          postback: {:Next, :form.atom([:otp, :otp, name])}
        )
      ],
      fields: [
        FORM.field(
          id: :number,
          name: :number,
          type: :string,
          title: "Логін:",
          labelClass: :label
        ),
        FORM.field(id: :auth, name: :auth, type: :password, title: "Пароль:", labelClass: :label)
      ]
    )
  end
end
