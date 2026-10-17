defmodule WMS.BusinessNumber do
  def service_order() do
    service_order_id =
      :kvs.seq(:wms_service_order_number, 1)
      |> to_string()

    "SO-" <> service_order_id
  end
end
