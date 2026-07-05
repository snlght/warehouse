defmodule WMS.Part.Toolbar do
  require NITRO

  def list_mode() do
    NITRO.panel(
      class: :part_create_button,
      body: [
        NITRO.link(
          id: :creator,
          body: "Додати деталь",
          postback: :create,
          class: [:button, :sgreen]
        )
      ]
    )
  end

  def form_mode() do
    NITRO.panel(
      class: :part_toolbar,
      body: []
    )
  end
end
