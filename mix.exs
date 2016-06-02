defmodule Images.Mixfile do
  use Mix.Project

  def project do
    [app: :images,
     version: "0.0.1",
     elixir: "~> 1.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [
      mod: {Images, []},
      applications: [:logger, :mariaex, :ecto, :httpotion, :ssl, :erlcloud]
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [
      {:ecto, "~> 1.0"},
      {:mariaex, "~> 0.4.2"},
      {:ibrowse, github: "cmullaparthi/ibrowse", tag: "v4.1.2"},
      {:httpotion, "~> 2.1.0"},
      {:mogrify, github: "dabit/mogrify", tag: "elixir_1_1"},
      {:erlcloud, github: "gleber/erlcloud"}
    ]
  end
end
