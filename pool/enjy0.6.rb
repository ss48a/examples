# encoding: UTF-8

# In future in plan develop load balance several scripts
# sh line:# screen -dmSL enjy2111 ruby enjy0.6.rb  '127.0.0.1' 2111 

require 'socket'
require 'json'

if ARGV[1]
  # For Production
  host, port = ARGV
else
  # For Dev
  host, port = '127.0.0.1', '2111' # for load balance 2112, 2113, ..
end

$console_log = false

class Enjy
  def initialize(host,port)
    @host = host
    @port = port
  end
  
  def init_server
    @connections_array    = []
    @connection           = TCPServer.open(@host,@port) # need tuning options
    @connections_array[0] = @connection
    
    @i = 0

    @users_sockets = Hash.new {|h,k| h[k]=[]}
    @guids_sockets = Hash.new {|h,k| h[k]=[]}

    @minds_guids = Hash.new {|h,k| h[k]=[]}

    @guid_eq_mind = {}

    @max_connection_one_user = 3

    @test_sockets = Array.new()
  end
  
  def init_onliner
    @thread = Thread.new do
      loop do
        @mind_client_id = Hash.new {|h,k| h[k]=[]}
        sleep 300
      end
    end
  end

  def start
    loop do
      init_onliner
      init_server
      loop do
        reads,writes = select(@connections_array,nil,nil)
        # console "ENJY(#{@i})#{'='*75}" # bad idea *75 - do every repeat
        unless reads.nil?
          reads.each do |client|
          begin
            if client == @connection then
              accept_new
            elsif client.eof?
              terminate(client)
            else
              # Two pass
              #   1-pass get main content 
              #   2-pass get slave content - technical information
              str = client.gets()
              str = str.force_encoding("UTF-8")
              datasend(str,client)
            end
          rescue => ex
            # console "ENJY(#{@i}): WARNING!!! error pass data on socket - #{ex}"
          end
          end
        end
        @i += 1
      end
    end
  end

  def accept_new
    @connections_array << @connection.accept_nonblock
  end
  def terminate(client)
    # console "ENJY(#{@i}): Finish client connection: #{client.peeraddr[2]}|#{client.peeraddr[1]}"
    client.close
    @connections_array.delete client
  end

  def datasend(str,client)
    begin
      data = JSON.parse(str.chomp!)
    rescue => ex
      # console "ENJY(#{@i}): WARNING!!! error parsing received data from client #{client} on port #{client.peeraddr} str - #{str} ex => #{ex}"
      return
    end

    # console "ENJY(#{@i}): received data from client #{data['client_id']} - #{data}"

    mindid    = data['mindid']
    client_id = data['client_id']

    case data['action']
     when 'whois'
      guid = data['guid']
      
      @test_sockets << client

      @users_sockets[client_id] << client
      @guids_sockets[guid] << client
      @minds_guids[mindid] << guid unless @minds_guids[mindid].include? guid

      @guid_eq_mind[guid] = { :mindid => mindid, :client_id => client_id }

      # For only list active users in current mind
      @mind_client_id[mindid] << client_id unless @mind_client_id[mindid].include? client_id

    when 'vkauth'
      send_to( @guids_sockets, data['destination'], str, client_id )

    when 'lp_send'
      destination = data['destination']

      @minds_guids[mindid].each do |tmp_guid|
        send_to( @guids_sockets, tmp_guid, str, client_id ) if @guid_eq_mind[tmp_guid][:mindid] == mindid unless @guid_eq_mind[tmp_guid][:client_id] == client_id unless mindid == 'all'
      end

      # Send main host by destination
      send_to( @users_sockets, destination, str, client_id )
    
    when 'online'
      data = { :action => 'online', :message => {
        :action => 'online',
        :mindid => mindid,
        :users  => @mind_client_id[mindid]
      }}
      
      # console "ONLINE: #{data} to client: #{client.peeraddr[2]}|#{client.peeraddr[1]}"

      client.console data.to_json.to_s
    end
  end
  
  def send_to( sockets, destination, str, client_id )
    return if destination == client_id
    sockets[destination].each do |socket|
      begin
        socket.console str
      rescue => ex
        # console "ENJY(#{@i}): WARNING!!! error sending data - #{ex}"
      end
    end
    # Remove used guid
    sockets.delete destination
  end

  # For design))
  private
    # Uncomment on Dev
    def console text
      # console text if $console_log
    end

end

Enjy.new(host,port).start