defmodule ChatServer do
  def start() do
    spawn(fn ->
      :global.register_name(ChatServer, self())
      server_loop([])
    end)
  end

  defp server_loop(clients) do
    clients =
      receive do
        {:message, message} ->
          IO.inspect("SERVER: FORWARDING MESSAGE")
          for client <- clients, do: send(client, {:message_from_server, message})
          clients

        {:new_client, client_pid} ->
          IO.inspect("SERVER: NEW CONNECTION")
          [client_pid | clients]
      end

    server_loop(clients)
  end

  def distribute_code() do
    {module, bin, file} = :code.get_object_code(ChatClient)
    :rpc.multicall(Node.list(), :code, :load_binary, [module, file, bin])
  end
end
