

# Spawn example

spawn(fn() -> IO.inspect(5 * 5) end)


# Spawn extended example

a = fn(x) ->

	spawn(fn() -> 
		:timer.sleep(1000) # Send this process to sleep for 1 second
		IO.inspect("I'm done!") # Print "I'm done to the console"
	end)

	x * x # return x squared
end

a.(5)

# Spawn in a list

square_me = fn(x) -> IO.inspect(x * x) end

for n <- [1,2,3,4,5], do: spawn(fn() -> square_me.(n) end)

# Messages

# Sending Messages

p_id = spawn(fn() ...... end)
send(p_id, {:data, "some message ..."})

# Receiving Messages

receive do
	{:data, data} ->
		IO.inspect(data, label: "I received a message!")
end 


# All Together
receiver = spawn(fn() ->
	receive do
		{:data, data} ->
			IO.inspect(data, label: "I received a message!")
	end	
end)

send(receiver, {:data, "something!!!"})

# square me with messages



a = fn(x) ->
	requester = self()

	pid = spawn(fn() -> 
		answer = x * x
		send(requester, {:answer, answer})
	end)
end

a.(5)

y = receive do
	{:answer, answer} ->
		IO.inspect("It came back!!!")
		answer
end

IO.inspect(y)


# Simple Chat Server

defmodule ChatServer do

	def start(clients) do
		spawn(fn ->
			Process.register(self(), ChatServer)
			server_loop(clients)
		end)
	end

	defp server_loop(clients) do
		receive do
			{:message, message} ->
				IO.inspect("SERVER: FORWARDING MESSAGE")
				for client <- clients, do: send(client, {:message_from_server, message})
		end

		server_loop(clients)
	end
end





defmodule ChatClient do
	
	def start(client_connection) do
		spawn(fn -> client_loop(client_connection) end)
	end

	defp client_loop(client_connection) do
		receive do
			{:message_from_connection, message} ->
				IO.inspect("CLIENT: SENDING MESSAGE TO SERVER")
				send(ChatServer, {:message, message})
			{:message_from_server, message} ->
				IO.inspect("CLIENT: RECEIVING MESSAGE FROM SERVER")
				send(client_connection, message)
		end

		client_loop(client_connection)
	end

	def send_msg(client, msg) do
		send(client, {:message_from_connection, msg})
	end

end

#  Chat Server Demo

my_client = ChatClient.start(self())
ChatServer.start([my_client])

# me = self()
# spawn(fn() -> ChatServer.start([me]) end)
# send(ChatServer, {:message, {"Joe", "I really hope this works"}})

# receive do
#  {:message, {sender, message}} ->
#   IO.inspect(message, label: "I received - #{message} - from #{sender}")
# end


# DISTRIBUTED EXAMPLE

defmodule ChatServer do

	def start() do
		spawn(fn ->
			:global.register_name(ChatServer, self())
			server_loop([])
		end)
	end

	defp server_loop(clients) do
		clients = receive do
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
end

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
		end

		client_loop(client_connection)
	end

	def send_msg(client, msg) do
		send(client, {:message_from_connection, msg})
	end

	def connect_to_server() do
		
		case :global.whereis_name(ChatServer) do
			:undefined ->
				IO.inspect("ERROR: Could not find server pid")

			server_address ->
				send(server_address, {:new_client, self()})
		end
	end

end

# HERE BE DRAGONS

iex --sname server
iex --sname c1
iex --sname c2
iex --sname c3

Node.connect(:server@JoeF)


{module, bin, file} = :code.get_object_code(ChatClient)
:rpc.multicall(Node.list, :code, :load_binary, [module, file, bin])

my_client = ChatClient.start(self())
ChatClient.connect_to_server(my_client)
ChatClient.send_msg(my_client, "Hello everyone!")


