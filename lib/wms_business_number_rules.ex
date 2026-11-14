defmodule WMS.BusinessNumberRules do
  require EXO

  def build_pending(type, number, business_number, command_id) do
    EXO.wms_business_number(
      id: :kvs.seq([], []),
      type: type,
      number: number,
      business_number: business_number,
      command_id: command_id,
      status: "pending",
      issued_at: System.system_time(:millisecond)
    )
  end

  def commit(record, target_id) do
    case EXO.wms_business_number(record, :status) do
      "pending" ->
        {
          :ok,
          EXO.wms_business_number(
            record,
            status: "committed",
            target_id: target_id
          )
        }

      status ->
        {:error, {:invalid_transition, status, "committed"}}
    end
  end

  def void(record, reason, actor) do
    case EXO.wms_business_number(record, :status) do
      "pending" ->
        {
          :ok,
          EXO.wms_business_number(
            record,
            status: "void",
            void_reason: reason,
            voided_by: actor,
            voided_at: System.system_time(:millisecond)
          )
        }

      status ->
        {:error, {:invalid_transition, status, "void"}}
    end
  end
end
