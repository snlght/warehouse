defmodule EXO.Boot do
  require EXO
  require Logger

  def clients() do
    case :kvs.all(~c"/exo/clients") do
      [] ->
        date = :calendar.now_to_datetime(:erlang.timestamp())
        ids = :lists.map(fn _ -> :timer.sleep(1) ; :kvs.seq([],[]) end, :lists.seq(1,6))
        sample = [
          EXO.client(
            id: :lists.nth(1,ids),
            names: "Максим",
            phone: "1",
            surnames: "Сохацький",
            type: :admin,
            status: :online,
            date: date
          ),
          EXO.client(
            id: :lists.nth(2,ids),
            names: "Антон",
            phone: "2",
            surnames: "Волошко",
            type: :admin,
            status: :online,
            date: date
          ),
          EXO.client(
            id: :lists.nth(3,ids),
            names: "МВС",
            phone: "3",
            surnames: "",
            type: :consumer,
            status: :online,
            date: date
          ),
          EXO.client(
            id: :lists.nth(4,ids),
            names: "ГСЦ",
            phone: "4",
            surnames: "",
            type: :consumer,
            status: :online,
            date: date
          ),
          EXO.client(
            id: :lists.nth(5,ids),
            names: "ЦІТ",
            phone: "5",
            surnames: "",
            type: :consumer,
            status: :online,
            date: date
          ),
          EXO.client(
            id: :lists.nth(6,ids),
            names: "ДНДІ",
            phone: "6",
            surnames: "",
            type: :consumer,
            status: :online,
            date: date
          )
        ]

        :lists.map(fn x -> :kvs.append(x, ~c"/exo/clients") end, sample)
      _ ->
        :ok
    end
  end

  def programs() do
    current_programs = :kvs.all(~c"/exo/tariffs")
    has_gas_or_oil = Enum.any?(current_programs, fn p -> EXO.program(p, :type) in [:gas, :oil] end)
    if current_programs == [] or has_gas_or_oil do
      if current_programs != [] do
        Enum.each(current_programs, fn p -> :kvs.delete(~c"/exo/tariffs", EXO.program(p, :id)) end)
        :kvs.delete(:writer, ~c"/exo/tariffs")
      end

      date = :calendar.now_to_datetime(:erlang.timestamp())
      ids = :lists.map(fn _ -> :timer.sleep(1) ; :kvs.seq([],[]) end, :lists.seq(1,12))

      sample = [
          EXO.program(id: :lists.nth(1, ids), name: "БАЗОВИЙ", type: :internet, date: date),
          EXO.program(id: :lists.nth(2, ids), name: "СТАНДАРТ", type: :internet, date: date),
          EXO.program(id: :lists.nth(3, ids), name: "БАЗОВИЙ", type: :electricity, date: date),
          EXO.program(id: :lists.nth(4, ids), name: "СТАНДАРТ", type: :electricity, date: date),
          EXO.program(id: :lists.nth(5, ids), name: "БАЗОВИЙ", type: :bankruptcy, date: date),
          EXO.program(id: :lists.nth(6, ids), name: "СТАНДАРТ", type: :bankruptcy, date: date),
          EXO.program(id: :lists.nth(7, ids), name: "БАЗОВИЙ", type: :court_decisions_images, date: date),
          EXO.program(id: :lists.nth(8, ids), name: "СТАНДАРТ", type: :court_decisions_images, date: date),
          EXO.program(id: :lists.nth(9, ids), name: "БАЗОВИЙ", type: :court_cases_scheduled, date: date),
          EXO.program(id: :lists.nth(10, ids), name: "СТАНДАРТ", type: :court_cases_scheduled, date: date),
          EXO.program(id: :lists.nth(11, ids), name: "БАЗОВИЙ", type: :court_decisions_hyperlinks, date: date),
          EXO.program(id: :lists.nth(12, ids), name: "СТАНДАРТ", type: :court_decisions_hyperlinks, date: date)
        ]

        :lists.map(fn x -> :kvs.append(x, ~c"/exo/tariffs") end, sample)
        :ok
      else
        :ok
      end
  end

  def accounts() do
    case :kvs.all(~c"/exo/accounts") do
      [] ->
        date = :calendar.now_to_datetime(:erlang.timestamp())
        clients = :kvs.all(~c"/exo/clients")
        programs = :kvs.all(~c"/exo/tariffs")

        internet_prog = Enum.find(programs, fn p -> EXO.program(p, :type) == :internet end)

        Enum.each(clients, fn client ->
          phone = EXO.client(client, :phone)
          if phone in ["3", "5", "6"] do
            client_id = EXO.client(client, :id)
            acc_id = :kvs.seq([], [])
            acc = EXO.account(
              id: acc_id,
              client: client_id,
              type: :internet,
              iban: "UA" <> to_string(:rand.uniform(10_000_000_000_000_000_000_000)),
              program: if(internet_prog, do: EXO.program(internet_prog, :id), else: []),
              amount: 5000,
              state: :open,
              date: date
            )
            :kvs.append(acc, ~c"/exo/accounts")
            Logger.info("Seeded account for client phone #{phone} (id: #{client_id}) with balance 5000 UAH")
          end
        end)
      _ ->
        :ok
    end
  end

  def wms() do
    if :kvs.all(EXO.wms_weapon_model()) == [] do
      models = [
        EXO.wms_weapon_model(id: "ak74", weapon_type: "rifle", caliber: "5.45x39", country: "USSR", category: "assault", status: "active", manufacturer: "izhmash"),
        EXO.wms_weapon_model(id: "m4a1", weapon_type: "rifle", caliber: "5.56x45", country: "USA", category: "assault", status: "active", manufacturer: "colt")
      ]
      :lists.map(fn x -> :kvs.append(x, ~c"/wms/weapon_models") end, models)
      Logger.info("Seeded initial weapon models.")

      weapons = [
        EXO.wms_weapon(id: "WPN-001", weapon_model: "ak74", serial_number: "AK-12345", owner: "A1234", status: "active", storage_location: "Kyiv"),
        EXO.wms_weapon(id: "WPN-002", weapon_model: "m4a1", serial_number: "M4-98765", owner: "B5678", status: "repair", storage_location: "Lviv"),
        EXO.wms_weapon(id: "WPN-003", weapon_model: "ak74", serial_number: "AK-11111", owner: "A1234", status: "destroyed", storage_location: "Kharkiv")
      ]
      :lists.map(fn x -> :kvs.append(x, ~c"/wms/weapons") end, weapons)
      Logger.info("Seeded initial weapons.")

      orders = [
        EXO.wms_service_order(id: "SO-101", weapon: "WPN-002", reason: "Заклинює затвор", service_status: "Init", result: "", received_by: "Tech1"),
        EXO.wms_service_order(id: "SO-102", weapon: "WPN-003", reason: "Утилізація (знищено)", service_status: "Diagnostic", result: "Списання", received_by: "Tech2")
      ]
      :lists.map(fn x -> :kvs.append(x, ~c"/wms/service_orders") end, orders)
      Logger.info("Seeded initial service orders.")

      transfers = [
        EXO.wms_transfer(id: "TO-101", weapon: "WPN-001", from_storage: "Kyiv", to_storage: "Lviv", transfer_status: "Transit"),
        EXO.wms_transfer(id: "TO-102", weapon: "WPN-002", from_storage: "Lviv", to_storage: "Kharkiv", transfer_status: "Init")
      ]
      :lists.map(fn x -> :kvs.append(x, ~c"/wms/transfers") end, transfers)
      Logger.info("Seeded initial transfer orders.")
    end
    :ok
  end
end
