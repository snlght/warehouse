defmodule EXO do
  require KVS
  require FORM
  require Record

  Module.register_attribute(__MODULE__, :exo_fields_accum, accumulate: true)

  @schema [
    :account,
    :client,
    :card,
    :transaction,
    :currency,
    :field,
    :program,
    :phone,
    :wms_weapon_model,
    :wms_weapon,
    :wms_manufacturer,
    :wms_owner,
    :wms_license,
    :wms_storage_location,
    :wms_transfer,
    :wms_weapon_event,
    :wms_service_order,
    :wms_service_event,
    :wms_service_act,
    :wms_part,
    :wms_audit_event,
    :wms_weapon_type,
    :wms_caliber,
    :wms_country,
    :wms_category,
    :wms_status
  ]

  Enum.each(
    @schema,
    fn t ->
      Enum.each(
        Record.extract_all(
          from_lib:
            "warehouse/include/" <> :erlang.list_to_binary(:erlang.atom_to_list(t)) <> ".hrl"
        ),
        fn {name, definition} ->
          Record.defrecord(name, definition)
          Module.put_attribute(__MODULE__, :exo_fields_accum, {name, definition})
        end
      )
    end
  )

  def exo_fields(), do: @exo_fields_accum

  def boot() do
    try do
      EXO.Boot.clients()
      EXO.Boot.programs()
      EXO.Boot.accounts()
      EXO.Boot.wms()
    rescue
      _ -> :skip
    end
  end

  def metainfo(), do: KVS.schema(name: :exo, tables: exo())

  def table(name) do
    {a, b} = :lists.unzip(:proplists.get_value(name, exo_fields(), []))
    KVS.table(name: name, fields: a, instance: b)
  end

  def exo(), do: :lists.map(fn x -> table(x) end, @schema)
end
