defmodule NetworkRailExample.Application do
  @moduledoc false

  use Application

  defp get_queue_names(names) do
    case names do
      :td -> ["/topic/TD_ALL_SIG_AREA"]
      :trust -> ["/topic/TRAIN_MVT_ALL_TOC"]
      names when is_list(names) -> names |> Enum.map(&get_queue_names/1) |> List.flatten()
    end
  end

  @impl true
  def start(_type, _args) do
    username = Application.fetch_env!(:networkrailexample, :username)
    password = Application.fetch_env!(:networkrailexample, :password)
    mode = Application.fetch_env!(:networkrailexample, :mode)

    queues = get_queue_names(mode)

    children = [
      {NetworkRailExample.BackoffManager, opts: %{}},
      {NetworkRailExample.CallbackHandler,
       [
         id: "td-test",
         host: 'publicdatafeeds.networkrail.co.uk',
         port: 61618,
         user: username,
         pass: password,
         queues: queues
       ]}
    ]

    opts = [strategy: :one_for_one, name: NetworkRailExample.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
