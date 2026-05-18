defmodule EXOSCULAT do
  use Application
  use Supervisor

  def stop(_), do: :ok
  def init([]), do: {:ok, { {:one_for_one, 5, 10}, []} }

  def start(_, _) do
      children = [ { Bandit, scheme: :http, port: 8051, plug: Sample.WS },
                   { Bandit, scheme: :http, port: 8004, plug: Sample.Static } ]
      Supervisor.start_link(children, strategy: :one_for_one, name: Sample.Supervisor)
  end
end

