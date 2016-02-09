defmodule Gutenex.Mixfile do
  use Mix.Project

  def project do
    [
      app: :gutenex,
      name: "Gutenex",
      version: "0.1.0",
      source_url: "https://github.com/SenecaSystems/gutenex",
      elixir: "~> 1.0",
      deps: deps,
      description: description,
      package: package
   ]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [
      {:imagineer, "~> 0.1.0" },
      {:apex, "~>0.3.0" },
      {:earmark, "~> 0.1", only: :dev},
      {:ex_doc, "~> 0.6", only: :dev }
    ]
  end

  defp description do
    """
    PDF Generation in Elixir
    """
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{github: "https://github.com/SenecaSystems/gutenex"},
      contributors: ["Chris Maddox"]
    ]
  end
end
