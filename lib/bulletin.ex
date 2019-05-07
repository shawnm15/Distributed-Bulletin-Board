defmodule User do
  #User module receiver to handle API call
  def user_receiver(replicate) do
    replicate = receive do                                                       #replicate nodes to keep state
        {:user_subscribe, user_name,topic_name} ->
          topic_pid = :global.whereis_name(topic_name)
          if (topic_pid != :undefined) do                                          # when topic is subscribed already, it is secondary topic manager
            topic_pid = :global.whereis_name(topic_name)
            send(topic_pid,{:topic_subscribe,user_name})
            replicate
          else                                                                     #when topic is subscribed for first time
            topic_pid = TopicManager.start(topic_name)
            send(topic_pid,{:topic_subscribe,user_name})
            replicate
          end
       {:user_post, user_name, topic_name, content} ->
         send(topic_name,{:user_post, user_name,topic_name, content})
         replicate
       {:user_unsubscribe, user_name,topic_name} ->
         topic_pid = :global.whereis_name(topic_name)
         if (topic_pid != :undefined) do                                         #send a message to topic manager that we are ready to unsubscribe
           topic_pid = :global.whereis_name(topic_name)
           send(topic_pid,{:topic_unsubscribe,user_name})
           replicate
         else
           IO.puts("Something unexpected occured")                               #not possible, meaning error occured
         end
      {:message,topic_name,content} ->
        replicate = update_in(replicate,[:received], fn(store) -> store ++ [{topic_name,content}]end)           #store incoming messages in map
        replicate
      {:fetch_news} ->
        Enum.each replicate.received, fn {_,msg} ->                                     #output all stored messages to console.
          IO.puts "The contents of the post: #{inspect msg}"
        end
    end
    user_receiver(replicate)
  end

  def start(user_name) do
    user_store = %{ user: user_name, received: []}
    user_pid = spawn( User,:user_receiver,[user_store] )
    :global.register_name(user_name,user_pid)
  end

  def subscribe(user_name,topic_name) do
    user_pid = :global.whereis_name(user_name)
    send(user_pid, {:user_subscribe, user_pid, topic_name})
  end

  def unsubscribe(user_name,topic_name) do
    user_pid = :global.whereis_name(user_name)
    send(user_pid, {:user_unsubscribe, user_pid, topic_name})
  end

  def post(user_name,topic_name,content) do
    user_pid = :global.whereis_name(user_name)
    topic_pid = :global.whereis_name(topic_name)
    send(user_pid, {:user_post, user_pid, topic_pid, content})
  end

  def fetch_news(user_name) do
    user_pid = :global.whereis_name(user_name)
    send(user_pid,{:fetch_news})
  end

end

defmodule TopicManager do

  def topic_receiver(replicate) do
    replicate = receive do
      {:topic_subscribe,user_name} ->
        replicate = update_in(replicate,[:currently_subscribed],fn(store) ->store ++ [{user_name}] end)     #store user in the map
        replicate
      {:topic_unsubscribe,user_name} ->
        replicate = update_in(replicate,[:currently_subscribed],fn(store) -> List.delete(store,{user_name}) end)  #delete user from the map
        replicate
      {:user_post, user_name,topic_name,content} ->
        replicate= update_in(replicate,[:stored_messages],fn(store) ->store ++ [{user_name,topic_name,content}] end)   #store messages in map
        Enum.each replicate.currently_subscribed, fn {user} -> send(user,{:message,topic_name,content}) end            #send messages to all subscribed users
        replicate
    end
    topic_receiver(replicate)
  end

  def start(topic_name) do
    topic_store = %{topic_name: topic_name, stored_messages: [], currently_subscribed: []}            #initializer for map data structure
    pid = spawn(TopicManager,:topic_receiver,[topic_store] )                                              #spawn process topic manager
    :global.register_name(topic_name,pid)
    pid
  end

end


defmodule Monitor do

  def start(leader_pid) do
    node_store = %{current_leader: leader_pid, secondary_nodes: []}                     #intialize a map to hold leader and secondary manager
    pid = spawn(Monitor,:monitor_receiver,[node_store] )
    :global.register_name("leader",pid)                                                 #register in global registry
    pid
  end

  def monitor_receiver(module_name,method_name,params) do
    res = spawn_monitor(module_name, method_name, params)                                #spawn a monitor instance to monitor the current leader
    IO.puts "the raw response is " <> inspect res

    message_response = receive do                                                     #store the result of receive for later handling
     msg ->
        msg
      after 1000 ->
        IO.puts "No error occured"
    end

    {:DOWN, ref, :process, pid, msg_result} = message_response                       #pattern match on the message response.

    if (msg_result != :ok || msg_result != :normal) do
      #handle good case
    end

    IO.puts "result is #{msg_result}"
    IO.puts "ref is #{inspect ref}"
    IO.puts "pid is #{inspect pid}"

  end
end
