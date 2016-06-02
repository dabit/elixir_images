defmodule Images.PropertyImage do
  use Ecto.Model

  schema "property_images" do
    field :property_id, :integer
    field :file, :string
    field :position, :integer
  end

  def main_query do
    from i in Images.PropertyImage,
      select: i
  end

  def all do
    Images.Repo.all main_query
  end

  def paged(offset, limit) do
    from i in main_query,
      limit: ^limit,
      offset: ^offset
  end

  def process(image, index) do
    medium   = image.file |> size_name(:small) |> s3_url(image.id)
    response = medium |> HTTPotion.head

    unless response.status_code == 200 do
      IO.puts "#{index} - #{image.id} - #{image.file} Start"
      { _, start_seconds, start_micro } = :os.timestamp
      generate_versions(image.file, image.id)
      { _, end_seconds, end_micro } = :os.timestamp
      IO.puts "#{index} - #{image.id} - #{image.file} End in #{end_seconds - start_seconds}.#{end_micro - start_micro}"
    else
      IO.puts "#{index} - #{image.id} - #{image.file} OK"
    end
  end

  def s3_url(file, id) do
    "#{s3_path}/#{id}/#{file}"
  end

  def s3_path do
    "https://s3.amazonaws.com/#{Application.get_env(:images, :s3_bucket)}/uploads/property_image/file"
  end

  def size_name(name, size) do
    "#{size}_#{name}"
  end

  def generate_versions(filename, id) do
    file        = download_original(filename, id)
    generate_medium(file, filename, id)
    generate_small(file, filename, id)
  end

  def download_original(filename, id) do
    file     = temp_filename(filename, id)
    ibrowse  = [save_response_to_file: String.to_char_list(file)]
    s3_url(filename, id) |> HTTPotion.get([ibrowse: ibrowse])
    file
  end

  def temp_filename(filename, id) do
    Path.join(System.tmp_dir, "#{Integer.to_string(id)}#{filename}")
  end

  def generate_medium(file, filename, id) do
    path = file_path(id)
    result = Path.join(System.tmp_dir, size_name(filename, :medium))

    Mogrify.open(file)
      |> Mogrify.copy
      |> Mogrify.resize_to_fill("450x300")
      |> Mogrify.save(result)

    {_, file} = File.read(result)

    s3_name = s3_full_name(id, filename, :medium)
      |> String.to_char_list

    IO.puts s3_name

    Application.get_env(:images, :s3_bucket)
      |> String.to_char_list
      |> :erlcloud_s3.put_object(s3_name, file, [], [{'x-amz-acl', 'public-read'}])
  end

  def generate_small(file, filename, id) do
    path = file_path(id)
    result = Path.join(System.tmp_dir, size_name(filename, :small))

    Mogrify.open(file)
      |> Mogrify.copy
      |> Mogrify.resize_to_limit("150x100")
      |> Mogrify.save(result)

    {_, file} = File.read(result)

    s3_name = s3_full_name(id, filename, :small)
      |> String.to_char_list

    IO.puts s3_name

    Application.get_env(:images, :s3_bucket)
      |> String.to_char_list
      |> :erlcloud_s3.put_object(s3_name, file, [], [{'x-amz-acl', 'public-read'}])
  end

  def file_path(id) do
    path = "./file/#{id}"
    File.mkdir(path)
    path
  end

  def s3_full_name(id, filename, size) do
    "#{s3_dest}/#{id}/#{size_name(filename, size)}"
  end

  def s3_dest do
    "uploads/property_image/file"
  end
end
