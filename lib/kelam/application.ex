defmodule Kelam.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      KelamWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:kelam, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Kelam.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Kelam.Finch},
      # Start a worker by calling: Kelam.Worker.start_link(arg)
      # {Kelam.Worker, arg},
      # Start to serve requests, typically the last entry
      KelamWeb.Presence,
      KelamWeb.Endpoint,
      {Cachex, name: :kelam_lobby}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Kelam.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    KelamWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
