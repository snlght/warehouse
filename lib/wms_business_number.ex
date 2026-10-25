defmodule WMS.BusinessNumber do
  def service_order_candidate() do
    case WMS.BusinessNumberStorage.current(:service_order) do
      {:ok, current} ->
        number = current + 1

        formatted =
          number
          |> Integer.to_string()
          |> String.pad_leading(3, "0")

        business_number = "SO-" <> formatted

        case service_order_exists?(business_number) do
          {:ok, false} ->
            {:ok, number, business_number}

          {:ok, true} ->
            case WMS.BusinessNumberStorage.put_current(:service_order, number) do
              :ok -> service_order_candidate()
              {:error, reason} -> {:error, reason}
            end

          {:error, reason} ->
            {:error, reason}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp service_order_exists?(number) do
    id = String.to_charlist(number)

    case :kvs.get(~c"/wms/service_orders", id) do
      {:ok, _order} ->
        {:ok, true}

      {:error, :not_found} ->
        {:ok, false}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
