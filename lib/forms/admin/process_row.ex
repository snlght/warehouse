defmodule BPE.Row do
  require BPE
  require NITRO

  def doc(), do: "Форма-рядок для відображення табличної репрезентації процесу."
  def id(), do: BPE.process()

  def current(proc) do
    {_, t} = :bpe.current_task(proc)
    t
  end

  def new(name, proc, _) do
    pid = :nitro.to_binary(BPE.process(proc, :id))
    docs = BPE.process(proc, :docs)

    NITRO.panel(
      id: :form.atom([:tr, name]),
      class: :td,
      body: [
        NITRO.panel(class: :column6, body: NITRO.link(href: "process.htm?p=" <> pid, body: pid)),
        NITRO.panel(class: :column6, body: :nitro.to_list(BPE.process(proc, :name))),
        NITRO.panel(class: :column6, body: :nitro.to_list(current(proc))),
        NITRO.panel(class: :column20, body: :nitro.to_list(current(proc))),
        NITRO.panel(
          class: :column20,
          body:
            :string.join(
              :lists.map(fn x -> :nitro.to_list([:erlang.element(1, x)]) end, docs),
              ~c", "
            )
        ),
        NITRO.panel(
          class: :column10,
          body:
            case current(proc) do
              ~c"Final" ->
                []

              _ ->
                [
                  NITRO.link(
                    postback: {:complete, BPE.process(proc, :id)},
                    class: [:button, :sgreen],
                    body: "Go"
                  )
                ]
            end
        )
      ]
    )
  end
end
