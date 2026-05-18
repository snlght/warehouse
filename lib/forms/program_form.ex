defmodule Program.Form do
  require EXO
  require NITRO
  require FORM
  require BPE

  def doc(), do: "Форма вводу тарифної програми"
  def id, do: EXO.program()

  def new(name, _program, _) do
    :erlang.put(:type_program_none, :type)

    FORM.document(
      name: :form.atom([:progran, name]),
      sections: [FORM.sec(name: ["Створення тарифної моделі: "])],
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
            :name_program_none,
            :type_program_none,
            :date_program_none,
            :formula_program_none
          ],
          postback: {:CreateTariff, :form.atom([:program, name])}
        )
      ],
      fields: [
        FORM.field(
          id: :name,
          name: :name,
          type: :string,
          title: "Ім'я тарифу",
          labelClass: :label
        ),
        FORM.field(
          id: :type,
          name: :type,
          title: "Тип:",
          type: :select,
          default: :internet,
          options: [
            FORM.opt(name: :internet, checked: true, title: "Інтернет"),
            FORM.opt(name: :oil, title: "Нафта"),
            FORM.opt(name: :gas, title: "Газ"),
            FORM.opt(name: :electricity, title: " Електроенергія")
          ]
        ),
        FORM.field(
          id: :date,
          name: :date,
          type: :calendar,
          title: "Дата",
          labelClass: :label
        ),
        FORM.field(
          id: :formula,
          name: :formula,
          type: :string,
          title: "Формула:",
          labelClass: :label
        )
      ]
    )
  end
end
