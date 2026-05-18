defmodule ADM.BPE do
  require BPE
  require NITRO

  def event(:init) do
    :nitro.clear(:tableHead)
    :nitro.clear(:tableRow)
    :nitro.insert_top(:tableHead, header())
    :nitro.clear(:frms)
    :nitro.clear(:ctrl)
    mod = BPE.Create

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
          BPE.Row.new(:form.atom([:row, BPE.process(x, :id)]), x, [])
        )
      end,
      :kvs.all(~c"/bpe/proc")
    )
  end

  def event({:complete, id}) do
    proc = :bpe.load(id)
    :bpe.start(proc, [])
    :bpe.next(id)

    :nitro.update(
      :form.atom([:tr, :row, id]),
      BPE.Row.new(:form.atom([:row, id]), proc, [])
    )
  end

  def event(:create) do
    :nitro.hide(:ctrl)
    :nitro.show(:frms)
  end

  def event({:Spawn, _}) do
    atom = :nitro.to_atom(:nitro.q(:process_type_pi_none))

    id =
      case :bpe.start(atom.def(), []) do
        {:error, i} -> i
        {:ok, i} -> i
      end

    :nitro.insert_after(:header, BPE.Row.new(:form.atom([:row, id]), :bpe.proc(id), []))
    :nitro.hide(:frms)
    :nitro.show(:ctrl)
  end

  def event({:Discard, []}) do
    :nitro.hide(:frms)
    :nitro.show(:ctrl)
  end

  def event(_), do: :ok

  def header() do
    NITRO.panel(
      id: :header,
      class: :th,
      body: [
        NITRO.panel(class: :column6, body: "Номер"),
        NITRO.panel(class: :column10, body: "Ім'я"),
        NITRO.panel(class: :column6, body: "Модуль"),
        NITRO.panel(class: :column20, body: "Стан"),
        NITRO.panel(class: :column20, body: "Документи"),
        NITRO.panel(class: :column20, body: "Управління")
      ]
    )
  end
end
