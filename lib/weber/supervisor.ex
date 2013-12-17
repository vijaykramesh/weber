defmodule Weber.Supervisor do
  use Supervisor.Behaviour

  def start_link(name, opts) do
    :supervisor.start_link({ :local, name }, __MODULE__, opts)
  end

  def start_child(supervisor, name, args, opts // []) do
    :supervisor.start_child(supervisor, worker(name, args, opts))
  end

  def init(_args) do
    supervise([], strategy: :one_for_one)
  end
end