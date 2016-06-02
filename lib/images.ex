defmodule Images do
  def start(_type, _args) do
    supervisor = Images.ImagesSupervisor.start_link
    enqueue
    supervisor
  end

  def enqueue do
    step = 1000
    start = 0
    Images.PropertyImage.paged(start, step)
      |> Images.Repo.all
      |> enqueue_batch(start, step)
  end

  def enqueue_batch(_, offset, _) when offset > 200000 do
    IO.puts "Done processing batches"
  end

  def enqueue_batch(batch, _, _) when length(batch) == 0 do
    IO.puts "Done processing batches"
  end

  def enqueue_batch(batch, offset, step) do
    batch
      |> Stream.with_index
      |> Enum.each fn(r) -> spawn(fn() -> pool_image(r) end) end
    #Enum.each batch, fn(i) -> IO.puts(i.id) end

    offset = offset + step
    Images.PropertyImage.paged(offset, step)
      |> Images.Repo.all
      |> enqueue_batch(offset, step)
  end

  def pool_image(image) do
    :poolboy.transaction(
      Images.ImagesSupervisor.pool_name,
      fn(pid) -> :gen_server.call(pid, image) end,
      :infinity
    )
  end
end
