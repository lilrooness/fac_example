defmodule ChatClient do
  def start(client_connection) do
    spawn(fn -> client_loop(client_connection) end)
  end

  defp client_loop(client_connection) do
    receive do
      {:message_from_connection, message} ->
        IO.inspect("CLIENT: SENDING MESSAGE TO SERVER")
        send(:global.whereis_name(ChatServer), {:message, message})

      {:message_from_server, message} ->
        IO.inspect("CLIENT: RECEIVING MESSAGE FROM SERVER")
        send(client_connection, message)

      {:connect, server_pid} ->
        send(server_pid, {:new_client, self()})
    end

    client_loop(client_connection)
  end

  def send_msg(client, msg) do
    send(client, {:message_from_connection, msg})
  end

  def connect_to_server(client) do
    case :global.whereis_name(ChatServer) do
      :undefined ->
        IO.inspect("ERROR: Could not find server pid")

      server_address ->
        send(client, {:connect, server_address})
    end
  end
end
