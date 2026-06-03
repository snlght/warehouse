defmodule EXO.WMS.Logistics do
  # Proxy events to the Transfers component for Logistics transfers
  def event(:init), do: EXO.WMS.Transfers.event(:init)
  def event(e), do: EXO.WMS.Transfers.event(e)
end
