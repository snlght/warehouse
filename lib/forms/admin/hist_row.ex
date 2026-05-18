defmodule BPE.Trace do
  require BPE
  require NITRO
  def doc(), do: "Форма-рядок для відображення табличної репрезентації історії процесу"
  def id(), do: BPE.hist(task: BPE.sequenceFlow(source: ~c"Init"))

  def new(name, hist, _) do
    task =
      case BPE.hist(hist, :task) do
        [] -> BPE.hist(id(), :task)
        x -> x
      end

    docs = BPE.hist(hist, :docs)

    NITRO.panel(
      id: :form.atom([:tr, :nitro.to_list(name)]),
      class: :td,
      body: [
        NITRO.panel(class: :column6, body: name(task)),
        NITRO.panel(
          class: :column20,
          body:
            :string.join(
              :lists.map(fn x -> :nitro.to_list([:erlang.element(1, x)]) end, docs),
              ~c", "
            )
        )
      ]
    )
  end

  def name(BPE.sequenceFlow() = flow), do: :nitro.to_list(BPE.sequenceFlow(flow, :source))
  def name(_), do: []
end
