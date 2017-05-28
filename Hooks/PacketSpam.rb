class PacketSpam

	attr_accessor :enabled, :callAfter, :callBefore, :dependencies
	
	def initialize(mother)
		@parent = mother
		@enabled = true
		@callAfter = false
		@callBefore = true
		@dependencies = {
			'author' => 'Lynx',
			'version' => '1.0',
			'hook_type' => 'game'
		}
		@packets = [
			'u#sp', 's#upc', 's#uph', 's#upf', 's#upn', 
			's#upb', 's#upa', 's#upe', 's#upp', 's#upl', 
			'l#ms', 'b#br', 'j#jr', 'u#se', 'u#sa', 'u#sg',
			'sma', 'u#sb', 'u#gp',  'u#ss', 'u#sq', 
			'u#sj', 'u#sl', 'u#sg', 'm#sm', 'u#sf'
		]
	end
	
	def handleSendJoke(data, client)
		self.checkPacketSpam(client, 'u#sj')
	end
	
	def handleJoinRoom(data, client)
		self.checkPacketSpam(client, 'j#jr')
	end
	
	def handleUserHeartbeat(data, client)
		self.checkPacketSpam(client, 'u#h')
	end
	
	def handleSendPosition(data, client)
		self.checkPacketSpam(client, 'u#sp')
	end
	
	def handleSendFrame(data, client)
		self.checkPacketSpam(client, 'u#sf')
	end
	
	def handleSendEmote(data, client)
		self.checkPacketSpam(client, 'u#se')
	end
	
	def handleSendQuickMessage(data, client)
		self.checkPacketSpam(client, 'u#sq')
	end
	
	def handleSendAction(data, client)
		self.checkPacketSpam(client, 'u#sa')
	end
	
	def handleSendSafeMessage(data, client)
		self.checkPacketSpam(client, 'u#ss')
	end
	
	def handleSendGuideMessage(data, client)
		self.checkPacketSpam(client, 'u#sg')
	end
	
	def handleSendMascotMessage(data, client)
		self.checkPacketSpam(client, 'u#sma')
	end
	
	def handleUpdatePlayerColor(data, client)
		self.checkPacketSpam(client, 's#upc')
	end
	
	def handleUpdatePlayerHead(data, client)
		self.checkPacketSpam(client, 's#uph')
	end
	
	def handleUpdatePlayerFace(data, client)
		self.checkPacketSpam(client, 's#upf')
	end
	
	def handleUpdatePlayerNeck(data, client)
		self.checkPacketSpam(client, 's#upn')
	end
	
	def handleUpdatePlayerBody(data, client)
		self.checkPacketSpam(client, 's#upb')
	end
	
	def handleUpdatePlayerHand(data, client)
		self.checkPacketSpam(client, 's#upa')
	end
	
	def handleUpdatePlayerFeet(data, client)
		self.checkPacketSpam(client, 's#upe')
	end
	
	def handleUpdatePlayerPhoto(data, client)
		self.checkPacketSpam(client, 's#upp')
	end
	
	def handleUpdatePlayerPin(data, client)
		self.checkPacketSpam(client, 's#upl')
	end
	
	def handleSendMessage(data, client)
		self.checkPacketSpam(client, 'm#sm')
	end
	
	def handleMailSend(data, client)
		self.checkPacketSpam(client, 'l#ms')
	end
	
	def handleBuddyRequest(data, client)
		self.checkPacketSpam(client, 'b#br')
	end
	
	def handleGetPlayer(data, client)
		self.checkPacketSpam(client, 'u#gp')
	end
	
	def checkPacketSpam(client, packetType)
		if @packets.include?(packetType) != false
			if client.spamFilter.has_key?(packetType) != true
				client.spamFilter[packetType] = 0
			end
			currTime = Time.now
			timeStamp = currTime
			if client.lastPacket.has_key?(packetType) != true
				client.lastPacket[packetType] = timeStamp
			end
			timeDiff = (TimeDifference.between(Time.parse(client.lastPacket[packetType].to_s), Time.now).in_seconds).round
			if timeDiff < 6
				if client.spamFilter[packetType] < 10
					client.spamFilter[packetType] += 1
				end
				if client.spamFilter[packetType] >= 10
					return @parent.sock.handleRemoveClient(client.sock)
				end
			else
				client.spamFilter[packetType] = 1
			end
			client.lastPacket[packetType] = timeStamp
		end
	end

end
