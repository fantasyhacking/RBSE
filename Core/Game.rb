require 'rubygems'
require 'bcrypt'
require 'htmlentities'
require 'to_bool'

class Game < XTParser

	def initialize(main_class)
		@parent = main_class
		@xtPackets = {}
		self.handleLoadPackets
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
		client.joinRoom(111)
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
	
	def handleGetPlayer(gameHandlerArgs, client)
		userID = gameHandlerArgs[0]
		userDetails = @parent.mysql.getPlayerString(userID)
		client.sendData('%xt%gp%-1%' + (userDetails ? userDetails : '') + '%')
	end
	
	def handleGetLatestRevision(gameHandlerArgs, client)
		client.sendData('%xt%glr%-1%3555')
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
	
	def handleSendFrame(gameHandlerArgs, client)
		frameID = gameHandlerArgs[0]
		client.sendRoom('%xt%sf%-1%' + client.ID.to_s + '%' + frameID.to_s + '%')
		client.frame = frameID 
	end
	
	def handleSendEmote(gameHandlerArgs, client)
		emoteID = gameHandlerArgs[0]
		client.sendRoom('%xt%se%-1%' + client.ID.to_s + '%' + emoteID.to_s + '%')
	end
	
	def handleSendQuickMessage(gameHandlerArgs, client)
		messageID = gameHandlerArgs[0]
		client.sendRoom('%xt%sq%-1%' + client.ID.to_s + '%' + messageID.to_s + '%')
	end
	
	def handleSendAction(gameHandlerArgs, client)
		actionID = gameHandlerArgs[0]
		client.sendRoom('%xt%sa%-1%' + client.ID.to_s + '%' + actionID.to_s + '%')
	end
	
	def handleSendSafeMessage(gameHandlerArgs, client)
		messageID = gameHandlerArgs[0]
		client.sendRoom('%xt%ss%-1%' + client.ID.to_s + '%' + messageID.to_s + '%')
	end
	
	def handleSendGuideMessage(gameHandlerArgs, client)
		messageID = gameHandlerArgs[0]
		client.sendRoom('%xt%sg%-1%' + client.ID.to_s + '%' + messageID.to_s + '%')
	end
	
	def handleSendJoke(gameHandlerArgs, client)
		jokeID = gameHandlerArgs[0]
		client.sendRoom('%xt%sj%-1%' + client.ID.to_s + '%' + jokeID.to_s + '%')
	end
	
	def handleSendMascotMessage(gameHandlerArgs, client)
		messageID = gameHandlerArgs[0]
		client.sendRoom('%xt%sma%-1%' + client.ID.to_s + '%' + messageID.to_s + '%')
	end
	
	def handleUpdatePlayerColor(gameHandlerArgs, client)
		itemID = gameHandlerArgs[0]
		client.sendRoom('%xt%upc%-1%' + client.ID.to_s + '%' + itemID.to_s + '%')
		client.clothes['color'] = itemID
		client.updateCurrentClothing
	end
	
	def handleUpdatePlayerHead(gameHandlerArgs, client)
		itemID = gameHandlerArgs[0]
		client.sendRoom('%xt%uph%-1%' + client.ID.to_s + '%' + itemID.to_s + '%')
		client.clothes['head'] = itemID
		client.updateCurrentClothing
	end
	
	def handleUpdatePlayerFace(gameHandlerArgs, client)
		itemID = gameHandlerArgs[0]
		client.sendRoom('%xt%upf%-1%' + client.ID.to_s + '%' + itemID.to_s + '%')
		client.clothes['face'] = itemID
		client.updateCurrentClothing
	end
	
	def handleUpdatePlayerNeck(gameHandlerArgs, client)
		itemID = gameHandlerArgs[0]
		client.sendRoom('%xt%upn%-1%' + client.ID.to_s + '%' + itemID.to_s + '%')
		client.clothes['neck'] = itemID
		client.updateCurrentClothing
	end
	
	def handleUpdatePlayerBody(gameHandlerArgs, client)
		itemID = gameHandlerArgs[0]
		client.sendRoom('%xt%upb%-1%' + client.ID.to_s + '%' + itemID.to_s + '%')
		client.clothes['body'] = itemID
		client.updateCurrentClothing
	end
	
	def handleUpdatePlayerHand(gameHandlerArgs, client)
		itemID = gameHandlerArgs[0]
		client.sendRoom('%xt%upa%-1%' + client.ID.to_s + '%' + itemID.to_s + '%')
		client.clothes['hand'] = itemID
	end
	
	def handleUpdatePlayerFeet(gameHandlerArgs, client)
		itemID = gameHandlerArgs[0]
		client.sendRoom('%xt%upe%-1%' + client.ID.to_s + '%' + itemID.to_s + '%')
		client.clothes['feet'] = itemID
		client.updateCurrentClothing
	end
	
	def handleUpdatePlayerPhoto(gameHandlerArgs, client)
		itemID = gameHandlerArgs[0]
		client.sendRoom('%xt%upp%-1%' + client.ID.to_s + '%' + itemID.to_s + '%')
		client.clothes['photo'] = itemID
		client.updateCurrentClothing
	end
	
	def handleUpdatePlayerPin(gameHandlerArgs, client)
		itemID = gameHandlerArgs[0]
		client.sendRoom('%xt%upl%-1%' + client.ID.to_s + '%' + itemID.to_s + '%')
		client.clothes['flag'] = itemID
		client.updateCurrentClothing
	end
	
	def handleAddToy(gameHandlerArgs, client)
		toyID = gameHandlerArgs[0]
		client.sendData('%xt%at%-1%' + client.ID.to_s + '%' + toyID.to_s + '%1%')
	end
	
	def handleRemoveToy(gameHandlerArgs, client)
		userID = gameHandlerArgs[0]
		client.sendData('%xt%rt%-1%' + userID.to_s + '%')
	end
	
	def handleGetInventory(gameHandlerArgs, client)
		userItems = client.inventory.join('%')
		client.sendData('%xt%gi%-1%' + userItems + '%')
	end
	
	def handleAddInventory(gameHandlerArgs, client)
		itemID = gameHandlerArgs[0]
		if @parent.crumbs.item_crumbs.has_key?(itemID) != true
			return client.sendError(402)
		elsif client.inventory.include?(itemID) != false
			return client.sendError(400)
		elsif @parent.crumbs.item_crumbs[itemID][0]['price'] > client.coins
			return client.sendError(401)
		end
		client.inventory.push(itemID)
		client.deductCoins(@parent.crumbs.item_crumbs[itemID][0]['price'])
		client.sendData('%xt%ai%-1%' + itemID.to_s + '%' + client.coins.to_s + '%')
		client.updateCurrentInventory
	end
	
	def handleQueryPlayerPins(gameHandlerArgs, client)
		userID = gameHandlerArgs[0]
		userPins = Array.new
		userDetails = @parent.mysql.getUserDetails(userID)
		userItems = userDetails.split('%')
		@parent.crumbs.item_crumbs.all? { |item| 
			if @parent.crumbs.item_crumbs[item]['type'] == 'flag'
				if userItems.include?(item) != false
					userPins.push(item)
				end
			end
		}
		pins = userPins.join('|') + Time.now.to_i + '|0'
		client.sendData('%xt%qpp%-1%' + client.ID.to_s + '%' + pins + '%')
	end
	
	def handleQueryPlayerAwards(gameHandlerArgs, client)
		userID = gameHandlerArgs[0]
		userAwards = Array.new
		userDetails = @parent.mysql.getUserDetails(userID)
		userItems = userDetails.split('%')
		@parent.crumbs.item_crumbs.all? { |item| 
			if @parent.crumbs.item_crumbs[item]['type'] == 'other'
				if userItems.include?(item) != false
					userAwards.push(item)
				end
			end
		}
		awards = userAwards.join('|')
		client.sendData('%xt%qpa%-1%' + client.ID.to_s + '%' + awards + '%')
	end
	
	def handleCoinsDigUpdate(gameHandlerArgs, client)
		randCoins = rand(10..100)
		minedCoins = (randCoins / 2)
		client.addCoins(minedCoins)
		client.sendData('%xt%cdu%-1%' + minedCoins.to_s + '%' + client.coins.to_s + '%')
	end
	
	def handleSendMessage(gameHandlerArgs, client)
		userID = gameHandlerArgs[0]
		userMessage = gameHandlerArgs[1]
		if client.astatus['isMuted'].to_bool != true
			decodedMessage = HTMLEntities.new.decode(userMessage)
			client.sendRoom('%xt%sm%-1%' + userID.to_s + '%' + decodedMessage + '%') 
		end
	end
	
	def handleKickButton(gameHandlerArgs, client)
		userID = gameHandlerArgs[0]
		oclient = client.getClientByID(userID)
		if oclient.ranking['isStaff'].to_bool == true
			@parent.logger.warn("#{client.username} is trying to kick #{oclient.username} who is a staff member")
			return
		end
		if client.ranking['isStaff'].to_bool == true
			@parent.logger.warn("Staff: #{client.username} has kicked #{oclient.username}")
			oclient.sendError('610%You have been kicked. THIS IS NOT A BAN!')
		end
	end
	
	def handleMuteButton(gameHandlerArgs, client)
		userID = gameHandlerArgs[0]
		oclient = client.getClientByID(userID)
		if oclient.ranking['isStaff'].to_bool == true
			@parent.logger.warn("#{client.username} is trying to mute #{oclient.username} who is a staff member")
			return
		end
		if client.ranking['isStaff'].to_bool == true
			if oclient.astatus['isMuted'].to_bool == false
				oclient.astatus['isMuted'] = 1
				@parent.logger.warn("Staff: #{client.username} has muted #{oclient.username}")
			else
				oclient.astatus['isMuted'] = 0
				@parent.logger.warn("Staff: #{client.username} has unmuted #{oclient.username}")
			end
			oclient.updateCurrentModStatus
		end
	end
	
	def handleBanButton(gameHandlerArgs, client)
		userID = gameHandlerArgs[0]
		userReason = gameHandlerArgs[1]
		oclient = client.getClientByID(userID)
		if oclient.ranking['isStaff'].to_bool == true
			@parent.logger.warn("#{client.username} is trying to ban #{oclient.username} who is a staff member")
			return
		end
		if client.ranking['isStaff'].to_bool == true
			if oclient.astatus['isBanned'].to_i == 0
				oclient.astatus['isBanned'] = 'PERMABANNED'
				oclient.updateCurrentModStatus
				oclient.sendError("610%#{userReason}")
			end
		end
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
	
	def handleEPFGetAgent(gameHandlerArgs, client)
	
	end
	
	def handleEPFGetRevisions(gameHandlerArgs, client)
	
	end
	
	def handleEPFGetField(gameHandlerArgs, client)
	
	end
	
	def handleSetStampBookCoverDetails(gameHandlerArgs, client)
	
	end
	
	def handleSetStampbookEnums(gameHandlerArgs, client)
	
	end
	
	def handleGetFurnitureRevision(gameHandlerArgs, client)
	
	end

end
