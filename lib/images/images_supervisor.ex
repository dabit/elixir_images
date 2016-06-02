defmodule Images.ImagesSupervisor do
  use Supervisor

  def start_link do
    :supervisor.start_link(__MODULE__, [])
  end

  def init([]) do
    poolboy_config = [
      {:name, {:local, pool_name()}},
      {:worker_module, Images.PropertyImageWorker},
      {:size, 0},
      {:max_overflow, 5}
    ]

    children = [
      :poolboy.child_spec(pool_name(), poolboy_config, []),
      worker(Images.Repo, [])
    ]

    supervise(children, strategy: :one_for_one)
  end

  def pool_name do
    :property_images
  end
end
