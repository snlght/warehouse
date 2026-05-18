defmodule ADM.ACT do
  require NITRO
  require FORM
  require BPE
  require EXO

  def event(:init) do
    :nitro.clear(:tableHead)
    :nitro.clear(:tableRow)
    bin = :nitro.qc(:p)

    id =
      try do
        :erlang.binary_to_list(bin)
      rescue
        _ -> 0
      end

    case :kvs.get("/bpe/proc", id) do
      {:error, :not_found} ->
        :nitro.update(:n, "ERR")
        :nitro.update(:desc, "No process found.")
        :nitro.update(:num, "ERR")

      _ ->
        :nitro.insert_top(:tableHead, header())
        :nitro.update(:n, bin)
        :nitro.update(:num, bin)
        history = :bpe.hist(id)

        :lists.map(
          fn x ->
            {:step, no, step} = BPE.hist(x, :id)
            name = :nitro.to_list(no) ++ ~c"-" ++ :nitro.to_list(step)
            trace = BPE.Trace.new(:form.atom([:trace, name]), x, [])
            :nitro.insert_bottom(:tableRow, trace)
          end,
          history
        )
    end
  end

  def event(_), do: []

  def header() do
    NITRO.panel(
      id: :header,
      class: :th,
      body: [
        NITRO.panel(class: :column6, body: "Стан"),
        NITRO.panel(class: :column6, body: "Документи")
      ]
    )
  end
end
