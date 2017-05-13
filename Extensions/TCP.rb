require 'rubygems'
require 'socket'

class TCP

	attr_accessor :clients

	def initialize(main_class)
		@parent = main_class
		@clients = Array.new
		@server
	end
	
	def connectServer
		@server = TCPServer.open(@parent.server_config['server_port'])
		if @server != nil
			@parent.logger.info('Successfully connected to the Game server')
		else
			@parent.logger.info('Failed to connect to the Game server')
		end
	end
	
	def listenServer
		Thread.new(@server.accept) do |connection|
			@parent.logger.info("Accepting connection from #{connection.peeraddr[2]}")
			client = CPUser.new(@parent, connection)
			@clients << client
			begin
				while true
				data = connection.recv(65536)
				if data.empty? == true
					if @parent.game_sys.iglooMap.has_key?(client.ID)
						@parent.game_sys.iglooMap.delete(client.ID)
					end
					client.removePlayerFromRoom
					self.handleRemoveClient(connection)
					break
				end
				self.handleIncomingData(data, client)	
				connection.flush
			end
			rescue Exception => e
				@parent.logger.error("#{e} (#{e.class}) - #{e.backtrace.join("\n\t")}")
			ensure
				if @parent.game_sys.iglooMap.has_key?(client.ID)
						@parent.game_sys.iglooMap.delete(client.ID)
				end
				client.removePlayerFromRoom
				self.handleRemoveClient(connection)
			end
        end
	end
	
	def handleIncomingData(data, client)
		packets = data.split("\0")
		packets.each do |packet|
			@parent.logger.debug('Incoming data: ' + packet.to_s)
			packet_type = packet[0,1]
			case packet_type
				when '<'
					self.handleXMLData(packet, client)
				when '%'
					self.handleXTData(packet, client)
				else
					self.handleRemoveClient(client.sock)
			end
		end
	end
	
	def handleXMLData(data, client)
		if data.include?('policy-file-request')
			return @parent.login_sys.handleCrossDomainPolicy(client)
		end
		hash_data = @parent.parseXML(data)
		if hash_data == false
			return self.handleRemoveClient(client.sock)
		end
		if @parent.login_sys.xml_handlers.has_key?('policy-file-request')
			return @parent.login_sys.handleCrossDomainPolicy(client)
		end
		if hash_data['msg']['t'] == 'sys'
			action = hash_data['msg']['body']['action']
			if @parent.login_sys.xml_handlers.has_key?(action)
				handler = @parent.login_sys.xml_handlers[action]
				if @parent.login_sys.respond_to?(handler) == true
					@parent.login_sys.send(handler, hash_data, client)
				end
			end
		end
	end
	
	def handleXTData(data, client)
		@parent.game_sys.handleData(data, client)
	end
	
	def handleRemoveClient(socket)
		@clients.each_with_index do |client, key|
			if @clients[key].sock == socket
				@clients[key].sock.close
				@clients.delete(client)
				@parent.logger.info('A client disconnected from the server')
			end
		end
	end
	
end
