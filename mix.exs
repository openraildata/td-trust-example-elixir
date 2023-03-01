defmodule NetworkRailExample.MixProject do
  use Mix.Project

  def project do
    [
      app: :networkrailexample,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: [main_module: NetworkRailExample]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {NetworkRailExample.Application, []}
    ]
  end

  defp deps do
    [
      {:mammoth, "~> 0.5.3"},
      {:jason, "~> 1.3"},
      {:tzdata, "~> 1.1"}
    ]
  end
end
