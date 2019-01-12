defmodule Exdeath.MixProject do
  use Mix.Project

  def project do
    [
      app: :exdeath,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      description: "Your Library's Description", # ライブラリの概要
      package: [
        maintainers: ["Your Name"],             # メンテナ(以前は :contributors でしたが deprecated になりました。)
        licenses: ["MIT"],                       # ライセンス名、ここでは MIT にしてみました
        links: %{"GitHub" => "https://github.com/ma2gedev/hex_sample"} # リンク集
      ],
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
    ]
  end
end
