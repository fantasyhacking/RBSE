require 'rubygems'
require 'bcrypt'

class Game < XTParser

	def initialize(main_class)
		@parent = main_class
	end
	
	def handleData(data, client)
		handlingInfo = self.parseData(data)
		if handlingInfo == false
			return
		end
		gameHandler = handlingInfo[0]['handler']
		gameHandlerArgs = handlingInfo[0]['arguments']
		if self.respond_to?(gameHandler) != true
			return @parent.logger.error('Unfortunately doesn\'t seem like the game method exists')
		end
		self.send(gameHandler, gameHandlerArgs, client)
	end
	
	def handleJoinServer(gameHandlerArgs, client)
		loginKey = gameHandlerArgs[1]
		if loginKey.length < 64
			return client.sendError(101)
		end
		validKey = @parent.mysql.getLoginKey(client.username)
		cryptedKey = BCrypt::Password.new(validKey)
		if cryptedKey != loginKey
			currInvalidAttempts = @parent.mysql.getInvalidLogins(client.username)
			currInvalidAttempts += 1
			@parent.mysql.updateInvalidLogins(client.username, currInvalidAttempts)
			return client.sendError(101)
		end
		client.sendData('%xt%js%-1%0%1%' + client.ranking['isStaff'].to_s + '%0%')
		client.sendData('%xt%lp%-1%' + client.buildClientString + '%' + client.coins.to_s + '%0%1440%100%' + client.joindate.to_s + '%4%' + client.joindate.to_s + '%%7%')
		@parent.mysql.updateLoginKey("", client.username)
		client.joinRoom(110)
	end
	
	def handleJoinPlayer(gameHandlerArgs, client)
		room = gameHandlerArgs[0]
		if room < 1000
			room += 1000
		end
		client.sendData('%xt%jp%-%' + room.to_s + '%')
		client.joinRoom(room)
	end
	
	def handleJoinGame(gameHandlerArgs, client)
		room = gameHandlerArgs[0]
		client.joinRoom(room)
	end
	
	def handleGetRoomSynced(gameHandlerArgs, client)
		client.sendData('%xt%grs%-1%' + client.room.to_s + '%' + client.buildClientString + '%')
	end
	
	def handleJoinRoom(gameHandlerArgs, client)
		room = gameHandlerArgs[0]
		room_x = gameHandlerArgs[1]
		room_y = gameHandlerArgs[2]
		client.joinRoom(room, room_x, room_y)
	end
	
	def handleEPFGetField(gameHandlerArgs, client)
		client.sendData('%xt%epfgf%-1%1%')
	end
	
	def handleGetInventory(gameHandlerArgs, client)
		items = client.inventory.join('%')
		client.sendData('%xt%gi%-1%' + items.to_s + '%')
	end
	
	def handleEPFGetField(gameHandlerArgs, client)
	
	end
	
	def handleGetFurnitureRevision(gameHandlerArgs, client)
	
	end
	
	def handleSendMessage(gameHandlerArgs, client)
	
	end
	
	def handleSetStampBookCoverDetails(gameHandlerArgs, client)
	
	end
	
	def handleGetBuddies(gameHandlerArgs, client)
	
	end
	
	def handleGetIgnored(gameHandlerArgs, client)
	
	end
	
	def handleMailStart(gameHandlerArgs, client)
	
	end
	
	def handleMailGet(gameHandlerArgs, client)
	
	end
	
	def handlePuffleGetUser(gameHandlerArgs, client)
	
	end
	
	def handleGetLatestRevision(gameHandlerArgs, client)
	
	end
	
	def handleEPFGetAgent(gameHandlerArgs, client)
	
	end
	
	def handleEPFGetRevision(gameHandlerArgs, client)
	
	end
	
	def handleUserHeartbeat(gameHandlerArgs, client)
		client.sendData('%xt%h%-1%')
	end
	
	def handleSendPosition(gameHandlerArgs, client)
		xpos = gameHandlerArgs[0]
		ypos = gameHandlerArgs[1]
		client.sendRoom('%xt%sp%-1%' + client.ID.to_s + '%' + xpos.to_s + '%' + ypos.to_s + '%')
		client.xaxis = xpos
		client.yaxis = ypos
	end

end
