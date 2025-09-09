defmodule Mcpixir.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/ramonlimaramos/mcpixir"

  def project do
    [
      app: :mcpixir,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),

      # Hex
      description: "Elixir library to connect LLMs to MCP servers for tool use capabilities",
      package: package(),

      # Docs
      name: "Mcpixir",
      docs: docs(),

      # Dialyzer
      dialyzer: [
        ignore_warnings: ".dialyzer_ignore.exs",
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
      ],

      # Testing
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Mcpixir.Application, []}
    ]
  end

  defp deps do
    [
      # Core dependencies
      # JSON parsing (equivalent to Python's json)
      {:jason, "~> 1.4"},
      # HTTP client (equivalent to aiohttp)
      {:httpoison, "~> 2.1"},
      # WebSockets client (equivalent to websockets)
      {:websockex, "~> 0.4.3"},
      # Resource pooling
      {:nimble_pool, "~> 1.0"},

      # Schema validation
      # JSON Schema validation (equiv to jsonschema)
      {:ex_json_schema, "~> 0.11.1"},
      # Data validation (similar to pydantic)
      {:ecto, "~> 3.10"},

      # Utility libraries
      # Modern UUID generation with UUIDv7 support
      {:uniq, "~> 0.6"},
      # Process pooling
      {:poolboy, "~> 1.5"},
      # Type definitions (similar to typing-extensions)
      {:typed_struct, "~> 0.3.0"},

      # LLM integrations
      # LangChain integration for LLMs
      {:langchain, "~> 0.3.3"},
      # HTTP client for API calls
      {:req, "~> 0.4"},

      # Documentation
      {:ex_doc, "~> 0.29", only: :dev, runtime: false},

      # Development and testing
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.3", only: [:dev, :test], runtime: false},
      {:mix_test_watch, "~> 1.1", only: [:dev, :test]},
      {:excoveralls, "~> 0.18", only: :test},

      # Testing
      {:mock, "~> 0.3.0", only: :test},
      {:bypass, "~> 2.1", only: :test}
    ]
  end

  defp package do
    [
      name: "mcpixir",
      maintainers: ["Ramon Ramos"],
      licenses: ["MIT"],
      files: ~w(lib .formatter.exs mix.exs README.md CHANGELOG.md LICENSE),
      links: %{
        "GitHub" => @source_url,
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md"
      }
    ]
  end

  defp docs do
    [
      main: "readme",
      source_url: @source_url,
      source_ref: "v#{@version}",
      extras: [
        "README.md",
        "CHANGELOG.md",
        "LICENSE"
      ],
      groups_for_modules: [
        Core: [
          Mcpixir,
          Mcpixir.Client,
          Mcpixir.Session,
          Mcpixir.Config,
          Mcpixir.ServerManager
        ],
        Agents: [
          Mcpixir.Agents.Base,
          Mcpixir.Agents.MCPAgent
        ],
        Connectors: [
          Mcpixir.Connectors.Base,
          Mcpixir.Connectors.HttpConnector,
          Mcpixir.Connectors.WebSocketConnector,
          Mcpixir.Connectors.StdioConnector
        ],
        "Task Managers": [
          Mcpixir.TaskManagers.Base,
          Mcpixir.TaskManagers.StdioManager,
          Mcpixir.TaskManagers.WebSocketManager,
          Mcpixir.TaskManagers.SSEManager
        ],
        Adapters: [
          Mcpixir.Adapters.LangChainAdapter
        ],
        Tools: [
          Mix.Tasks.Mcp,
          Mix.Tasks.Mcp.Chat,
          Mix.Tasks.Mcp.Airbnb,
          Mix.Tasks.Mcp.Blender,
          Mix.Tasks.Mcp.Browser,
          Mix.Tasks.Mcp.Filesystem,
          Mix.Tasks.Mcp.Http,
          Mix.Tasks.Mcp.Multi,
          Mix.Tasks.Mcp.Release
        ]
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
