defmodule NetworkRailExample.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    username = Application.fetch_env!(:networkrailexample, :username)
    password = Application.fetch_env!(:networkrailexample, :password)
    mode = Application.fetch_env!(:networkrailexample, :mode)

    queue =
      case mode do
        :td -> "/topic/TD_ALL_SIG_AREA"
        :trust -> "/topic/TRAIN_MVT_ALL_TOC"
      end

    children = [
      {NetworkRailExample.BackoffManager, opts: %{}},
      {NetworkRailExample.CallbackHandler,
       [
         id: "td-test",
         host: 'publicdatafeeds.networkrail.co.uk',
         port: 61618,
         user: username,
         pass: password,
         queue: queue
       ]}
    ]

    opts = [strategy: :one_for_one, name: NetworkRailExample.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
