require 'rubygems'
require 'bcrypt'
require 'htmlentities'
require 'to_bool'
require 'time'
require 'time_difference'

class Game < XTParser

	attr_accessor :iglooMap

	def initialize(main_class)
		@parent = main_class
		@xtPackets = Hash.new
		@iglooMap = Hash.new
		@gamePuck = '0%0%0%0%'
		@findFourRooms = [220, 221]
		@findFourTables = [200, 201, 202, 203, 204, 205, 206, 207]
		@mancalaTables = [100, 101, 102, 103, 104]
		@mancalaRoom = 111
		@tables = [@findFourTables, @mancalaTables].reduce([], :concat)
		@tablePopulationByID = Hash[@tables.map {|tableID| [tableID, Hash.new]}]
		@playersByTableID = Hash[@tables.map {|tableID| [tableID, Array.new]}]
		@gamesByTableID = Hash[@tables.map {|tableID| [tableID, nil]}]
		@waddlesByID = [
			103 => ['', ''], 
			102 => ['', ''], 
			101 => ['', '', ''], 
			100 => ['', '', '', '']
		]
		@sledRacing = [100, 101, 102, 103]
		@waddleRoom = 0
		@waddleUsers = Hash[@waddlesByID[0].keys.map {|waddleID| [waddleID, Hash.new]}]
		self.handleLoadPackets
	end
	
	def loadIglooMap
		igloo_map = ''
		@iglooMap.each do |userID, username|
			igloo_map << userID.to_s + '|' + username + '%'
		end
		return igloo_map
	end
	
	def handleData(data, client)
		handlingInfo = self.parseData(data)
		if handlingInfo == false
			return @parent.sock.handleRemoveClient(client.sock)
		end
		gameHandler = handlingInfo[0]['handler']
		gameHandlerArgs = handlingInfo[0]['arguments']
		@parent.hooks.each do |hook, hookClass|
			if @parent.hooks[hook].dependencies['hook_type'].downcase == 'game'
				if @parent.hooks[hook].respond_to?(gameHandler) == true && @parent.hooks[hook].callBefore == true && @parent.hooks[hook].callAfter == false
					hookClass.send(gameHandler, gameHandlerArgs, client)
				end
			end
		end
		if self.respond_to?(gameHandler) != true
			return @parent.logger.error('Unfortunately doesn\'t seem like the game method exists')
		end
		if client.username == '' || client.username.nil? != false
			@parent.logger.error('Client is trying to send an undefined bot')
			return @parent.sock.handleRemoveClient(client.sock)
		end
		self.send(gameHandler, gameHandlerArgs, client)
		@parent.hooks.each do |hook, hookClass|
			if @parent.hooks[hook].dependencies['hook_type'].downcase == 'game'
				if @parent.hooks[hook].respond_to?(gameHandler) == true && @parent.hooks[hook].callAfter == true && @parent.hooks[hook].callBefore == false
					hookClass.send(gameHandler, gameHandlerArgs, client)
				end
			end
		end
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
		client.sendData('%xt%gps%-1%' + client.ID.to_s + '%' + client.stamps.join('|') + '%')
		@parent.mysql.updateLoginKey("", client.username)
		client.checkPuffleStats
		client.joinRoom(100)
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
		if userID != 0
			userDetails = @parent.mysql.getPlayerString(userID)
			client.sendData('%xt%gp%-1%' + (userDetails ? userDetails : '') + '%')
		end
	end
	
	def handleGetLatestRevision(gameHandlerArgs, client)
		client.sendData('%xt%glr%-1%3555%')
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
		walkingPuffleIDS = @parent.mysql.getWalkingPuffleIDS(client.ID)
		if itemID == 0 && walkingPuffleIDS != nil
			walkingPuffleIDS.each do |walkingPuffID|
				@parent.mysql.updateWalkingPuffle(0, client.ID, walkingPuffID)
			end
		end
		client.sendRoom('%xt%upa%-1%' + client.ID.to_s + '%' + itemID.to_s + '%')
		client.clothes['hands'] = itemID
		client.updateCurrentClothing
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
		if userID != 0
			client.sendData('%xt%rt%-1%' + userID.to_s + '%')
		end
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
		client.updateCurrentInventory
		client.sendData('%xt%ai%-1%' + itemID.to_s + '%' + client.coins.to_s + '%')
	end
	
	def handleQueryPlayerPins(gameHandlerArgs, client)
		userID = gameHandlerArgs[0]
		if userID != 0
			userPins = Array.new
			userDetails = @parent.mysql.getPenguinInventoryByID(userID)
			userItems = userDetails.split('%')
			userItems.each do |item|
				item = item.to_i
				if @parent.crumbs.item_crumbs.has_key?(item) == true && @parent.crumbs.item_crumbs[item][0]['type'] == 'flag'
					userPins.push(item)
				end
			end
			pins = ''
			if userPins.count > 0
				userPins.each do |pin|
					pins << pin.to_s + '|' + (Time.now.to_i).to_s + '%'
				end
			else
				pins = ''
			end
			if pins != ''
				client.sendData('%xt%qpp%-1%' + pins.to_s + '%')
			else
				client.sendData('%xt%qpp%-1%')
			end
		end
	end
	
	def handleQueryPlayerAwards(gameHandlerArgs, client)
		userID = gameHandlerArgs[0]
		if userID != 0
			userAwards = Array.new
			userDetails = @parent.mysql.getPenguinInventoryByID(userID)
			userItems = userDetails.split('%')
			userItems.each do |item|
				item = item.to_i
				if @parent.crumbs.item_crumbs.has_key?(item) && @parent.crumbs.item_crumbs[item][0]['type'] == 'other'
					userAwards.push(item)
				end
			end
			awards = userAwards.join('|')
			client.sendData('%xt%qpa%-1%' + client.ID.to_s + '%' + awards.to_s + '%')
		end
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
		if userMessage.include?('|') != false
			@parent.logger.warn("#{client.username} is trying perform some sort of exploit")
			return
		end
		decodedMessage = HTMLEntities.new.decode(userMessage)
		commandChar = decodedMessage[0,1]
		if commandChar == '!'
			return
		end
		if client.astatus['isMuted'].to_bool != true
			client.sendRoom('%xt%sm%-1%' + userID.to_s + '%' + decodedMessage + '%') 
		else
			client.sendRoom('%xt%mm%-1%' + userID.to_s + '%' + decodedMessage + '%')
		end
	end
	
	def handleKickButton(gameHandlerArgs, client)
		userID = gameHandlerArgs[0]
		if userID != 0
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
	end
	
	def handleMuteButton(gameHandlerArgs, client)
		userID = gameHandlerArgs[0]
		if userID != 0
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
	end
	
	def handleBanButton(gameHandlerArgs, client)
		userID = gameHandlerArgs[0]
		userReason = gameHandlerArgs[1]
		if userID != 0
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
	end
	
	def handleEPFAddItem(gameHandlerArgs, client)
		epfItemID = gameHandlerArgs[0]
		if @parent.crumbs.epf_item_crumbs.has_key?(epfItemID) != true
			return client.sendError(402)
		elsif client.inventory.include?(epfItemID) != false
			return client.sendError(400)
		elsif @parent.crumbs.epf_item_crumbs[epfItemID][0]['points'] > client.currentpoints
			return client.sendError(405)
		end
		client.inventory.push(epfItemID)
		client.updateCurrentInventory
		client.deductEPFPoints(@parent.crumbs.epf_item_crumbs[epfItemID][0]['points'])
		client.sendData('%xt%epfai%-1%' + client.currentpoints.to_s + '%')
	end
	
	def handleEPFGetAgent(gameHandlerArgs, client)
		client.sendData('%xt%epfga%-1%' + client.status.to_s + '%')
	end
	
	def handleEPFSetAgent(gameHandlerArgs, client)
		client.sendData('%xt%epfsa%-1%' + client.status.to_s + '%')
	end
	
	def handleEPFGetRevisions(gameHandlerArgs, client)
		client.sendData('%xt%epfgr%-1%' + client.totalpoints.to_s + '%' + client.currentpoints.to_s + '%')
	end
	
	def handleEPFGetField(gameHandlerArgs, client)
		client.sendData('%xt%epfgf%-1%1%')
		client.sendData('%xt%epfgr%-1%' + client.totalpoints.to_s + '%' + client.currentpoints.to_s + '%')
	end
	
	def handleEPFSetField(gameHandlerArgs, client)
		client.sendData('%xt%epfsf%-1%1%')
	end
	
	def handleEPFGetComMessages(gameHandlerArgs, client)
		client.sendData('%xt%epfgm%-1%0%Powered by RBSE|' + (Time.now.to_i).to_s + '|10%')
	end
	
	def handleAddFurniture(gameHandlerArgs, client)
		furnID = gameHandlerArgs[0]
		if @parent.crumbs.furniture_crumbs.has_key?(furnID) != true
			return client.sendError(402)
		elsif @parent.crumbs.furniture_crumbs[furnID][0]['price'] > client.coins
			return client.sendError(401)
		end
		furnQuantity = 1
		if client.ownedFurns.has_key?(furnID) != false
			furnQuantity += client.ownedFurns[furnID]
		end
		if furnQuantity > 99
			return client.sendError(403)
		end
		client.ownedFurns[furnID] = furnQuantity
		client.updateCurrentFurnInventory
		client.deductCoins(@parent.crumbs.furniture_crumbs[furnID][0]['price'])
		client.sendData('%xt%af%-1%' + furnID.to_s + '%' + client.coins.to_s + '%')
	end
	
	def handleUpdateIgloo(gameHandlerArgs, client)
		iglooID = gameHandlerArgs[0]
		client.igloo = iglooID
		@parent.mysql.updateIglooType(iglooID, client.ID)
		@parent.mysql.updateFloorType(0, client.ID)
		@parent.mysql.updateIglooFurniture('', client.ID)
		client.sendData('%xt%ao%-1%' + iglooID.to_s + '%' + client.coins.to_s + '%')
	end
	
	def handleAddIgloo(gameHandlerArgs, client)
		iglooID = gameHandlerArgs[0]
		if @parent.crumbs.igloo_crumbs.has_key?(iglooID) != true
			return client.sendError(402)
		elsif client.ownedIgloos.include?(iglooID) != false
			return client.sendError(500)
		elsif @parent.crumbs.igloo_crumbs[iglooID][0]['price'] > client.coins
			return client.sendError(401)
		end
		client.ownedIgloos.push(iglooID)
		client.deductCoins(@parent.crumbs.igloo_crumbs[iglooID][0]['price'])
		client.updateCurrentIglooInventory
		client.sendData('%xt%au%-1%' + iglooID.to_s + '%' + client.coins.to_s + '%')
	end
	
	def handleUpdateFloor(gameHandlerArgs, client)
		floorID = gameHandlerArgs[0]
		if @parent.crumbs.floors_crumbs.has_key?(floorID) != true
			return client.sendError(402)
		elsif @parent.crumbs.floors_crumbs[floorID][0]['price'] > client.coins
			return client.sendError(401)
		end
		client.floor = floorID
		@parent.mysql.updateFloorType(floorID, client.ID)
		client.deductCoins(@parent.crumbs.floors_crumbs[floorID][0]['price'])
		client.sendData('%xt%ag%-1%' + floorID.to_s + '%' + client.coins.to_s + '%')
	end
	
	def handleUpdateMusic(gameHandlerArgs, client)
		musicID = gameHandlerArgs[0]
		client.music = musicID
		@parent.mysql.updateIglooMusic(musicID, client.ID)
		client.sendData('%xt%um%-1%' + musicID.to_s + '%')
	end
	
	def handleGetIglooDetails(gameHandlerArgs, client)
		userID = gameHandlerArgs[0]
		if userID != 0
			iglooID = ''
			musicID = ''
			floorID = ''
			furniture = ''
			iglooData = @parent.mysql.getIglooDetails(userID)
			iglooData.each do |iglooInfo|
				iglooID = iglooInfo['igloo'].to_s
				musicID = iglooInfo['music'].to_s
				floorID = iglooInfo['floor'].to_s
				furniture = iglooInfo['furniture'].to_s
			end
			client.sendData('%xt%gm%-1%' + userID.to_s + '%' + (iglooID ? iglooID : 1) + '%' + (musicID ? musicID : 0) + '%' + (floorID ? floorID : 0) + '%' +  (furniture ? furniture : '') + '%')
		end
	end
	
	def handleGetOwnedIgloos(gameHandlerArgs, client)
		igloos = client.ownedIgloos.join('|')
		igloos ? client.sendData('%xt%go%-1%' + igloos + '%') : client.sendData('%xt%go%-1%1%')
	end
	
	def handleOpenIgloo(gameHandlerArgs, client)
		@iglooMap.store(client.ID.to_i, client.username)
	end
	
	def handleCloseIgloo(gameHandlerArgs, client)
		@iglooMap.delete(client.ID.to_i)
	end
	
	def handleGetOwnedFurniture(gameHandlerArgs, client)
		furnitures = ''
		client.ownedFurns.each do |furnQuantity, furnID|
			furnitures << furnQuantity.to_s + '|' + furnID.to_s + '%'
		end
		client.sendData('%xt%gf%-1%' + furnitures)
	end
	
	def handleGetFurnitureRevision(gameHandlerArgs, client)
		furnitures = ''
		gameHandlerArgs.each do |furniture|
			furnitureInfo = furniture.split('|')
			if furnitureInfo.count > 5 || furnitureInfo.count < 5
				@parent.logger.warn('Client is trying to send invalid furniture arguments')
				return false
			end
			furnitureInfo.each do |info|
				if @parent.is_num?(info) != true
					@parent.logger.warn('Client is trying to send an invalid Furniture')
					return false
				end
			end
			furnitures << furniture + ','
		end
		@parent.mysql.updateIglooFurniture(furnitures, client.ID)
	end
	
	def handleGetOpenedIgloos(gameHandlerArgs, client)
		igloos = self.loadIglooMap;
		if igloos != ''
			client.sendData('%xt%gr%-1%' + igloos)
		else 
			client.sendData('%xt%gr%-1%')
		end
	end
	
	def handleSendStampEarned(gameHandlerArgs, client)
		stampID = gameHandlerArgs[0]
		if @parent.crumbs.stamps_crumbs.has_key?(stampID) != true
			@parent.logger.warn("#{client.username} is trying to send an invalid stamp")
			return false
		end
		if client.stamps.include?(stampID) != false
			@parent.logger.warn("#{client.username} is trying to add an existing stamp")
			return false
		end
		client.stamps.push(stampID)
		client.restamps.push(stampID)
		client.updateCurrentStamps
		client.sendData('%xt%aabs%-1%' + stampID.to_s + '%')
	end
	
	def handleGetPlayersStamps(gameHandlerArgs, client)
		userID = gameHandlerArgs[0]
		if userID != 0
			userStamps = @parent.mysql.getStampsByID(userID)
			client.sendData('%xt%gps%-1%' + userID.to_s + '%' + userStamps + '%')
		end
	end
	
	def handleGetMyRecentlyEarnedStamps(gameHandlerArgs, client)
		currstamps = client.stamps.join('|')
		currrestamps = client.restamps.join('|')
		client.sendData('%xt%gmres%-1%' + currrestamps + '%')
		@parent.mysql.updatePenguinStamps(currstamps, '', client.ID)
	end
	
	def handleGetStampBookCoverDetails(gameHandlerArgs, client)
		stampbook_cover = @parent.mysql.getStampbookCoverByID(client.ID)
		if stampbook_cover != ''
			client.sendData('%xt%gsbcd%-1%' + stampbook_cover + '%')
		else
			client.sendData('%xt%gsbcd%-1%1%1%1%1%')
		end
	end
	
	def handleSetStampBookCoverDetails(gameHandlerArgs, client)
		gameHandlerArgs.each do |argument|
			if argument.include?('|') != false
				exceptionArguments = argument.split('|')
				if exceptionArguments.count > 6 || exceptionArguments.count < 6
					@parent.logger.warn('Client is trying to send invalid amount of stampbook cover arguments')
					return false
				end
				exceptionArguments.each do |exceptionArg|
					if @parent.is_num?(exceptionArg) != true
						@parent.logger.warn('Client is trying to send invalid cover arguments')
						return false
					end
				end
			else
				if @parent.is_num?(argument) != true
					@parent.logger.warn('Client is trying to send invalid cover style arguments')
					return false
				end
			end
		end
		stampbook_cover = gameHandlerArgs.join('%')
		@parent.mysql.updateStampbookCover(stampbook_cover, client.ID)
		client.sendData('%xt%ssbcd%-1%' + (stampbook_cover ? stampbook_cover : '1%1%1%1%'))
	end
	
	def handleBuddyRequest(gameHandlerArgs, client)
		buddyID = gameHandlerArgs[0]
		if buddyID != 0
			if buddyID == client.ID.to_i
				return @parent.logger.warn("#{client.username} is trying to add themselves, wtf?")
			end
			oclient = client.getClientByID(buddyID)
			oclient.sendData('%xt%br%-1%' + client.ID.to_s + '%' + client.username + '%')
		end
	end
	
	def handleGetBuddies(gameHandlerArgs, client)
		buddyString = ''
		client.buddies.each do |buddyID, buddyName|
			buddyString << buddyID.to_s + '|' + buddyName + '|' + client.getOnline(buddyID).to_s + '%'
		end
		if buddyString != ''
			client.sendData('%xt%gb%-1%' + buddyString + '%')
		else
			client.sendData('%xt%gb%-1%%')
		end
	end
	
	def handleBuddyAccept(gameHandlerArgs, client)
		buddyID = gameHandlerArgs[0]
		if buddyID != 0
			if buddyID == client.ID.to_i
				return @parent.logger.warn("#{client.username} is trying to add themselves, wtf?")
			end
			if client.buddies.has_key?(buddyID) != false
				return @parent.logger.warn("#{client.username} is trying to add a buddy that already exists!")
			end
			oclient = client.getClientByID(buddyID)
			client.buddies[buddyID] = oclient.username
			oclient.buddies[client.ID.to_i] = client.username
			oclient.updateCurrentBuddies
			client.updateCurrentBuddies
			oclient.sendData('%xt%ba%-1%' + client.ID.to_s + '%' + client.username + '%')
		end
	end

	def handleRemoveBuddy(gameHandlerArgs, client)
		buddyID = gameHandlerArgs[0]
		if buddyID != 0
			if buddyID == client.ID.to_i
				return @parent.logger.warn("#{client.username} is trying to remove themselves, wtf?")
			end
			if client.buddies.has_key?(buddyID) != true
				return @parent.logger.warn("#{client.username} is trying to remove a buddy that doesn\'t exist!")
			end
			client.buddies.delete(buddyID)
			client.updateCurrentBuddies
			oclientBuddies = @parent.mysql.getClientBuddiesByID(buddyID)
			buddies = oclientBuddies.split(',')
			buddyString = ''
			buddies.each do |buddy|
				budDetails = buddy.split('|')
				budID = budDetails[0]
				budName = budDetails[1]
				if budID.to_i != client.ID.to_i
					buddyString << budID.to_s + '|' + budName + ','
				end
			end
			@parent.mysql.updateBuddies(buddyString, buddyID)
			if client.getOnline(buddyID) == 1
				oclient = client.getClientByID(buddyID)
				oclient.sendData('%xt%rb%-1%' + client.ID.to_s + '%' + client.username + '%')
			end
		end
	end
	
	def handleBuddyFind(gameHandlerArgs, client)
		buddyID = gameHandlerArgs[0]
		if buddyID != 0
			oclient = client.getClientByID(buddyID)
			if client.getOnline(buddyID) == 1
				return client.sendData('%xt%bf%-1%' + oclient.room.to_s + '%')
			end
		end
	end
	
	def handleGetIgnored(gameHandlerArgs, client)
		buddyString = ''
		client.ignored.each do |buddyID, buddyName|
			buddyString << buddyID.to_s + '|' + buddyName + '%'
		end
		if buddyString != ''
			client.sendData('%xt%gn%-1%' + buddyString + '%')
		else
			client.sendData('%xt%gn%-1%%')
		end
	end
	
	def handleAddIgnore(gameHandlerArgs, client)
		buddyID = gameHandlerArgs[0]
		if buddyID != 0
			if buddyID == client.ID.to_i
				return @parent.logger.warn("#{client.username} is trying to ignore themselves, wtf?")
			end
			if client.ignored.has_key?(buddyID) != false
				return @parent.logger.warn("#{client.username} is trying to ignore a buddy that\'s already ignored!")
			end
			oclient = client.getClientByID(buddyID)
			client.ignored[oclient.ID.to_i] = oclient.username
			client.updateCurrentIgnoredBuddies
			client.sendData('%xt%an%' + client.room.to_s + '%' + oclient.ID.to_s + '%')
		end
	end
	
	def handleRemoveIgnore(gameHandlerArgs, client)
		buddyID = gameHandlerArgs[0]
		if buddyID != 0
			if buddyID == client.ID.to_i
				return @parent.logger.warn("#{client.username} is trying to remove themselves from being ignored, wtf?")
			end
			if client.ignored.has_key?(buddyID) != true
				return @parent.logger.warn("#{client.username} is trying to remove an ignored buddy that doesn\'t exist!")
			end
			client.ignored.delete(buddyID)
			client.updateCurrentIgnoredBuddies
			client.sendData('%xt%rn%' + client.room.to_s + '%' + buddyID.to_s + '%')
		end
	end
	
	def handleMailStart(gameHandlerArgs, client)
		unreadPostcards = @parent.mysql.getUnreadPostcardCount(client.ID)
		receivedPostcards = @parent.mysql.getReceivedPostcardCount(client.ID)
		client.sendData('%xt%mst%-1%' + unreadPostcards.to_s + '%' + receivedPostcards.to_s + '%')
	end
	
	def handleMailGet(gameHandlerArgs, client)
		postcards = @parent.mysql.getUserPostcards(client.ID)
		if postcards != ''
			client.sendData('%xt%mg%-1%' + postcards + '%')
		else
			client.sendData('%xt%mg%-1%%')
		end
	end
	
	def handleMailSend(gameHandlerArgs, client)
		recepientID = gameHandlerArgs[0]
		postcardType = gameHandlerArgs[1]
		postcardNotes = HTMLEntities.new.decode((gameHandlerArgs[2] ? gameHandlerArgs[2] : ''))
		if recepientID != 0
			if @parent.crumbs.postcard_crumbs.has_key?(postcardType) != true
				return @parent.logger.warn("#{client.username} is trying to send an invalid postcard")
			end
			if @parent.crumbs.postcard_crumbs[postcardType][0]['cost'] > client.coins
				client.sendData('%xt%ms%-1%' + client.coins.to_s + '%2%')
			else
				receiver = client.getClientByID(recepientID)
				receivedPostcards = @parent.mysql.getReceivedPostcardCount(recepientID)
				if receivedPostcards > 92
					return client.sendData('%xt%ms%-1%' + client.coins.to_s + '%0%')
				end
				currTimestamp = Time.now.to_i
				postcardID = @parent.mysql.addPostcard(recepientID, client.username, client.ID, postcardNotes, postcardType, currTimestamp)
				if client.getOnline(recepientID) == 1
				   receiver.sendData('%xt%mr%-1%' + client.username + '%' + client.ID.to_s + '%' + postcardType.to_s + '%' + currTimestamp.to_s + '%' + postcardID.to_s + '%')
				   client.sendData('%xt%ms%-1%' + client.coins.to_s + '%1%')
				else
					client.sendData('%xt%ms%-1%' + client.coins.to_s + '%1%')
				end
				client.deductCoins(@parent.crumbs.postcard_crumbs[postcardType][0]['cost'])
			end
		end
	end
	
	def handleMailDelete(gameHandlerArgs, client)
		postcardID = gameHandlerArgs[0]
		@parent.mysql.deletePostcardByRecepient(postcardID, client.ID)
		client.sendData('%xt%md%-1%' + postcardID.to_s + '%')
	end
	
	def handleMailDeletePlayer(gameHandlerArgs, client)
		userID = gameHandlerArgs[0]
		if userID != 0
			@parent.mysql.deletePostcardsByMailer(client.ID, userID)
			receivedPostcards = @parent.mysql.getReceivedPostcardCount(client.ID)
			client.sendData('%xt%mdp%-1%' + receivedPostcards.to_s + '%')
		end
	end
	
	def handleMailChecked(gameHandlerArgs, client)
		unreadPostcards = @parent.mysql.getUnreadPostcardCount(client.ID)
		if unreadPostcards > 0
			@parent.mysql.updatePostcardRead(client.ID)
			client.sendData('%xt%mc%-1%1%')
		end
	end
	
	def handleSendPuffleFrame(gameHandlerArgs, client)
		puffleID = gameHandlerArgs[0]
		puffleFrame = gameHandlerArgs[1]
		realPuffID = @parent.mysql.getPuffleIDByOwner(client.ID, puffleID)
		if realPuffID == puffleID
			client.sendRoom('%xt%ps%-1%' + puffleID.to_s + '%' + puffleFrame.to_s + '%')
		end
	end
	
	def handleGetPuffle(gameHandlerArgs, client)
		userID = gameHandlerArgs[0]
		if userID != 0
			userPuffles = @parent.mysql.getNonWalkingPuffles(userID)
			client.sendData('%xt%pg%-1%' + userPuffles)
		end
	end
	
	def handlePufflePip(gameHandlerArgs, client)
		puffleID = gameHandlerArgs[0]
		argOne = gameHandlerArgs[1]
		argTwo = gameHandlerArgs[2]
		realPuffID = @parent.mysql.getPuffleIDByOwner(client.ID, puffleID)
		if realPuffID == puffleID
			client.sendRoom('%xt%pip%-1%' + realPuffID.to_s + '%' + argOne.to_s + '%' + argTwo.to_s + '%')
		end
	end
	
	def handlePufflePir(gameHandlerArgs, client)
		puffleID = gameHandlerArgs[0]
		argOne = gameHandlerArgs[1]
		argTwo = gameHandlerArgs[2]
		realPuffID = @parent.mysql.getPuffleIDByOwner(client.ID, puffleID)
		if realPuffID == puffleID
			client.sendRoom('%xt%pir%-1%' + realPuffID.to_s + '%' + argOne.to_s + '%' + argTwo.to_s + '%')
		end
	end
	
	def handlePuffleIsResting(gameHandlerArgs, client)
		puffleID = gameHandlerArgs[0]
		argOne = gameHandlerArgs[1]
		argTwo = gameHandlerArgs[2]
		puffle = @parent.mysql.getPuffleByOwner(client.ID, puffleID)
		if puffle != ''
			client.sendRoom('%xt%ir%-1%' + puffle + '%' + argOne.to_s + '%' + argTwo.to_s + '%')
		end
	end
	
	def handlePuffleIsPlaying(gameHandlerArgs, client)
		puffleID = gameHandlerArgs[0]
		argOne = gameHandlerArgs[1]
		argTwo = gameHandlerArgs[2]
		puffle = @parent.mysql.getPuffleByOwner(client.ID, puffleID)
		if puffle != ''
			client.sendRoom('%xt%ip%-1%' + puffle + '%' + argOne.to_s + '%' + argTwo.to_s + '%')
		end
	end
	
	def handlePuffleIsFeeding(gameHandlerArgs, client)
		puffleID = gameHandlerArgs[0]
		argOne = gameHandlerArgs[1]
		argTwo = gameHandlerArgs[2]
		puffle = @parent.mysql.getPuffleByOwner(client.ID, puffleID)
		if puffle != ''
			client.sendRoom('%xt%if%-1%' + client.coins.to_s + '%' + puffle + '%' + argOne.to_s + '%' + argTwo.to_s + '%')
		end
	end
	
	def handlePuffleWalk(gameHandlerArgs, client)
		puffleID = gameHandlerArgs[0]
		isWalking = gameHandlerArgs[1]
		walkingPuffleIDS = @parent.mysql.getWalkingPuffleIDS(client.ID)
		walkingPuffleIDS.each do |walkingPuffID|
			@parent.mysql.updateWalkingPuffle(0, client.ID, walkingPuffID)
		end
		puffleDetails = @parent.mysql.getPuffleDetailsByOwner(client.ID, puffleID)
		if puffleDetails != nil
			walkingPuffle = puffleDetails['puffleID'].to_s + '|' + puffleDetails['puffleName'].to_s + '|' + puffleDetails['puffleType'].to_s + '|' + puffleDetails['puffleHealth'].to_s + '|' + puffleDetails['puffleEnergy'].to_s + '|' + puffleDetails['puffleRest'].to_s + '|0|0|0|0|0|0'
			if isWalking.to_bool == true
				argsToSend = []
				puffleHandItem = (75 + puffleDetails['puffleType']).to_i
				argsToSend.push(puffleHandItem)
				self.handleUpdatePlayerHand(argsToSend, client)
				@parent.mysql.updateWalkingPuffle(1, client.ID, puffleDetails['puffleID'])
				client.sendRoom('%xt%pw%-1%' + client.ID.to_s + '%' + walkingPuffle + '|1%')
			else
				argsToSend = []
				puffleHandItem = 0
				argsToSend.push(puffleHandItem)
				self.handleUpdatePlayerHand(argsToSend, client)
				@parent.mysql.updateWalkingPuffle(0, client.ID, puffleDetails['puffleID'])
				client.sendRoom('%xt%pw%-1%' + client.ID.to_s + '%' + walkingPuffle + '|0%')
			end
		end
	end
	
	def handlePuffleGetUser(gameHandlerArgs, client)
		puffles = @parent.mysql.getNonWalkingPuffles(client.ID)
		if puffles != ''
			client.sendData('%xt%pgu%-1%' + puffles + '%')
		else
			client.sendData('%xt%pgu%-1%%')
		end
	end
	
	def handlePuffleFeedFood(gameHandlerArgs, client)
		puffleID = gameHandlerArgs[0]
		realPuffID = @parent.mysql.getPuffleIDByOwner(client.ID, puffleID)
		if realPuffID == puffleID
			if client.coins.to_i < 10
				return client.sendError(401)
			end
			currentPuffleStats = @parent.mysql.getPuffleDetailsByOwner(client.ID, puffleID)
			randHealth = rand(3..10)
			randEnergy = rand(7..12)
			randRest = rand(1..7)
			newPuffleHealth = currentPuffleStats['puffleHealth'].to_i + randHealth
			newPuffleEnergy = currentPuffleStats['puffleEnergy'].to_i + randEnergy
			newPuffleRest = currentPuffleStats['puffleRest'].to_i - randRest
			@parent.mysql.updatePuffleStatByType('puffleHealth', newPuffleHealth, puffleID, client.ID)
			@parent.mysql.updatePuffleStatByType('puffleEnergy', newPuffleEnergy, puffleID, client.ID)
			@parent.mysql.updatePuffleStatByType('puffleRest', newPuffleRest, puffleID, client.ID)
			client.deductCoins(10)
			puffle = @parent.mysql.getPuffleByOwner(client.ID, puffleID)
			if puffle != ''
				client.sendRoom('%xt%pf%-1%' + client.coins.to_s + '%' + puffle)
			end
		end
	end
	
	def handleAdoptPuffle(gameHandlerArgs, client)
		puffleID = gameHandlerArgs[0]
		puffleName = HTMLEntities.new.decode(gameHandlerArgs[1])
		if (puffleName =~ /^[A-Za-z0-9]+$/)
			if client.coins.to_i < 800
				return client.sendError(401)
			end
			client.deductCoins(800)
			adoptTime = Time.now.to_i
			postcardType = 111
			puffle = @parent.mysql.addPuffle(puffleID, puffleName, client.ID)
			postcardID = @parent.mysql.addPostcard(client.ID, 'sys', 0, puffleName, postcardType, adoptTime)
			client.sendData('%xt%mr%-1%sys%0%' + postcardType.to_s + '%' + puffleName.to_s + '%' + adoptTime.to_s + '%' + postcardID.to_s + '%')
			client.sendData('%xt%pn%-1%' + client.coins.to_s + '%' + puffle + '%')
		end
	end
	
	def handlePuffleRest(gameHandlerArgs, client)
		puffleID = gameHandlerArgs[0]
		realPuffID = @parent.mysql.getPuffleIDByOwner(client.ID, puffleID)
		if realPuffID == puffleID
			currentPuffleStats = @parent.mysql.getPuffleDetailsByOwner(client.ID, puffleID)
			randHealth = rand(6..14)
			randRest = rand(14..19)
			randEnergy = rand(7..15)
			newPuffleHealth = currentPuffleStats['puffleHealth'].to_i - randHealth
			newPuffleEnergy = currentPuffleStats['puffleEnergy'].to_i + randEnergy
			newPuffleRest = currentPuffleStats['puffleRest'].to_i + randRest
			@parent.mysql.updatePuffleStatByType('puffleHealth', newPuffleHealth, puffleID, client.ID)
			@parent.mysql.updatePuffleStatByType('puffleEnergy', newPuffleEnergy, puffleID, client.ID)
			@parent.mysql.updatePuffleStatByType('puffleRest', newPuffleRest, puffleID, client.ID)
			puffle = @parent.mysql.getPuffleByOwner(client.ID, puffleID)
			if puffle != ''
				client.sendRoom('%xt%pr%-1%' + puffle)
			end
		end
	end
	
	def handlePufflePlay(gameHandlerArgs, client)
		puffleID = gameHandlerArgs[0]
		realPuffID = @parent.mysql.getPuffleIDByOwner(client.ID, puffleID)
		if realPuffID == puffleID
			currentPuffleStats = @parent.mysql.getPuffleDetailsByOwner(client.ID, puffleID)
			randHealth = rand(4..10)
			randRest = rand(5..12)
			randEnergy = rand(5..10)
			newPuffleHealth = currentPuffleStats['puffleHealth'].to_i + randHealth
			newPuffleEnergy = currentPuffleStats['puffleEnergy'].to_i - randEnergy
			newPuffleRest = currentPuffleStats['puffleRest'].to_i - randRest
			@parent.mysql.updatePuffleStatByType('puffleHealth', newPuffleHealth, puffleID, client.ID)
			@parent.mysql.updatePuffleStatByType('puffleEnergy', newPuffleEnergy, puffleID, client.ID)
			@parent.mysql.updatePuffleStatByType('puffleRest', newPuffleRest, puffleID, client.ID)
			puffle = @parent.mysql.getPuffleByOwner(client.ID, puffleID)
			if puffle != ''
				client.sendRoom('%xt%pp%-1%' + puffle + (rand(2).to_s) + '%')
			end
		end
	end
	
	def handlePuffleFeed(gameHandlerArgs, client)
		puffleID = gameHandlerArgs[0]
		puffleAction = gameHandlerArgs[1]
		if client.coins.to_i < 5
			return client.sendError(401)
		end
		currentPuffleStats = @parent.mysql.getPuffleDetailsByOwner(client.ID, puffleID)
		randHealth = rand(3..10)
		randEnergy = rand(7..12)
		randRest = rand(1..7)
		newPuffleHealth = currentPuffleStats['puffleHealth'].to_i - randHealth
		newPuffleEnergy = currentPuffleStats['puffleEnergy'].to_i - randEnergy
		newPuffleRest = currentPuffleStats['puffleRest'].to_i - randRest
		@parent.mysql.updatePuffleStatByType('puffleHealth', newPuffleHealth, puffleID, client.ID)
		@parent.mysql.updatePuffleStatByType('puffleEnergy', newPuffleEnergy, puffleID, client.ID)
		@parent.mysql.updatePuffleStatByType('puffleRest', newPuffleRest, puffleID, client.ID)
		client.deductCoins(5)
		puffle = @parent.mysql.getPuffleByOwner(client.ID, puffleID)
		if puffle != ''
			client.sendRoom('%xt%pt%-1%' + client.coins.to_s + '%' + puffle + puffleAction.to_s + '%')
		end
	end
	
	def handlePuffleMove(gameHandlerArgs, client)
		puffleID = gameHandlerArgs[0]
		xpos = gameHandlerArgs[1]
		ypos = gameHandlerArgs[1]
		realPuffID = @parent.mysql.getPuffleIDByOwner(client.ID, puffleID)
		if realPuffID == puffleID
			client.sendRoom('%xt%pm%-1%' + puffleID.to_s + '%' + xpos.to_s + '%' + ypos.to_s + '%')
		end
	end
	
	def handlePuffleBath(gameHandlerArgs, client)
		puffleID = gameHandlerArgs[0]
		if client.coins.to_i < 5
			return client.sendError(401)
		end
		currentPuffleStats = @parent.mysql.getPuffleDetailsByOwner(client.ID, puffleID)
		randHealth = rand(8..13)
		randEnergy = rand(7..12)
		randRest = rand(13..20)
		newPuffleHealth = currentPuffleStats['puffleHealth'].to_i + randHealth
		newPuffleEnergy = currentPuffleStats['puffleEnergy'].to_i + randEnergy
		newPuffleRest = currentPuffleStats['puffleRest'].to_i + randRest
		@parent.mysql.updatePuffleStatByType('puffleHealth', newPuffleHealth, puffleID, client.ID)
		@parent.mysql.updatePuffleStatByType('puffleEnergy', newPuffleEnergy, puffleID, client.ID)
		@parent.mysql.updatePuffleStatByType('puffleRest', newPuffleRest, puffleID, client.ID)
		client.deductCoins(5)
		puffle = @parent.mysql.getPuffleByOwner(client.ID, puffleID)
		if puffle != ''
			client.sendRoom('%xt%pb%-1%' + client.coins.to_s + '%' + puffle)
		end
	end
	
	def handleGameOver(gameHandlerArgs, client)
		score = gameHandlerArgs[0]
		if score < 0
			return @parent.logger.warn("#{client.username} is trying to add an invalid score")
		end
		if client.room == 999
			winAmount = 0
			case score
				when 1
					winAmount = 20
				when 2
					winAmount = 10
				when 3
					winAmount = 5
				else
					winAmount = 0
			end
			client.addCoins(winAmount)
			return client.sendData('%xt%zo%-1%' + client.coins.to_s + '%%0%0%0%')
		end
		if client.room < 900
			return client.sendData('%xt%zo%-1%' + client.coins.to_s + '%%0%0%0%')
		end
		coins = (score / 10).round
		if score < 99999
			client.addCoins(coins)
			client.sendData('%xt%zo%-1%' + client.coins.to_s + '%%0%0%0%')
		end
	end
	
	def handleDonateCoins(gameHandlerArgs, client)
		amount = gameHandlerArgs[1]
		if amount > client.coins
			return client.sendError(401)
		end
		amountTypes = [100, 500, 1000, 5000, 10000]
		if amountTypes.include?(amount)
			client.deductCoins(amount)
		end
	end
	
	def handleSignIglooContest(gameHandlerArgs, client)
		isSignedUp = @parent.mysql.checkIfSignedIglooContest(client.ID)
		if isSignedUp == false
			return @parent.mysql.signupIglooContest(client.ID, client.username)
		end
		lastSignUpTime = @parent.mysql.getLastIglooContestSignUpTime(client.ID)
		lastSignUpDifference = (TimeDifference.between(Time.parse(lastSignUpTime.to_s), Time.now).in_minutes).round
		if lastSignUpDifference.to_i >= 1
			@parent.mysql.deleteExistingSignUpDetails(client.ID)
			@parent.mysql.signupIglooContest(client.ID, client.username)
		else
			client.sendError(913)
		end
	end
	
	def handleGetTables(gameHandlerArgs, client)
		if @findFourRooms.include?(client.room) != false || @mancalaRoom == client.room
			tablesPopulation = ''
			gameHandlerArgs.each do |gameTable|
				if @parent.is_num?(gameTable) != false && @findFourTables.include?(gameTable) || @mancalaTables.include?(gameTable) && @tablePopulationByID.has_key?(gameTable)
					tablesPopulation << gameTable.to_s + '|' + @tablePopulationByID[gameTable].count.to_s + '%'
				end
			end
			client.sendData('%xt%gt%-1%' + tablesPopulation)
		end
	end
	
	def handleJoinTable(gameHandlerArgs, client)
		tableID = gameHandlerArgs[0]
		if @findFourRooms.include?(client.room) != false || @mancalaRoom == client.room
			if @tablePopulationByID.has_key?(tableID)
				if @tablePopulationByID[tableID].count < 3
					seatID = @tablePopulationByID[tableID].count
					if @findFourTables.include?(tableID) != false
						if @gamesByTableID[tableID] == nil
							findFourGame = FindFour.new
							@gamesByTableID[tableID] = findFourGame
						end
					end
					if @mancalaTables.include?(tableID) != false
						if @gamesByTableID[tableID] == nil
							mancalaGame = Mancala.new
							@gamesByTableID[tableID] = mancalaGame
						end
					end
					seatID += 1
					client.sendData('%xt%jt%-1%' + tableID.to_s + '%' + seatID.to_s + '%')
					client.sendRoom('%xt%ut%-1%' + tableID.to_s + '%' + seatID.to_s + '%')
					@tablePopulationByID[tableID][client.username] = client
					@playersByTableID[tableID].push(client.username)
					client.tableID = tableID
				end
			end
		end
	end
	
	def handleLeaveTable(gameHandlerArgs, client)
		tableID = client.tableID
		if tableID != nil
			seatID = @playersByTableID[tableID].index(client.username)
			if @playersByTableID[tableID].index(client.username) < 2
				@playersByTableID[tableID].each_with_index do |username, key|
					oclient = client.getClientByName(username)
					oclient.sendData('%xt%cz%-1%' + client.username + '%')
				end
			end
			@playersByTableID[tableID].delete(client.username)
			@tablePopulationByID[tableID].delete(client.username)
			client.sendRoom('%xt%ut%-1%' + tableID.to_s + '%' + seatID.to_s + '%')
			client.tableID = nil
			if @playersByTableID[tableID].count == 0
				@playersByTableID[tableID].clear
				@gamesByTableID[tableID] = nil
			end
		end
	end
	
	def handleQuitGame(gameHandlerArgs, client)
	
	end
	
	def handleGetGame(gameHandlerArgs, client)
		if client.room == 802
			return client.sendData('%xt%gz%-1%' + @gamePuck + '%')
		end
		if @findFourRooms.include?(client.room) != false || @mancalaRoom == client.room
			tableID = client.tableID
			if tableID != nil
				players = @tablePopulationByID[tableID].keys
				firstPlayer = players[0]
				secondPlayer = players[1]
				board = @gamesByTableID[tableID].convertToString
				client.sendData('%xt%gz%-1%' + (firstPlayer ? firstPlayer : '') + '%' + (secondPlayer ? secondPlayer : '') + '%' + board + '%')
			end
		end
	end
	
	def handleStartGame(gameHandlerArgs, client) 
		waddleID = client.waddleID
		if client.waddleRoom != nil && @sledRacing.include?(waddleID) != false
			waddleUsers = Array.new
			@parent.sock.clients.each_with_index do |oclient, key|
				if @parent.sock.clients[key].room == client.room
					waddleUsers.push(sprintf("%s|%d|%d|%s", @parent.sock.clients[key].username, @parent.sock.clients[key].clothes['color'], @parent.sock.clients[key].clothes['hands'], @parent.sock.clients[key].username))
				end
			end
			return client.sendData('%xt%uz%-1%' + waddleUsers.count.to_s + '%' + waddleUsers.join('%') + '%')
		end
		tableID = client.tableID
		if tableID != nil 
			if @playersByTableID[tableID].include?(client.username) != false
				index = @tablePopulationByID[tableID].count - 1
				client.sendData('%xt%jz%-1%' + index.to_s + '%')
				if index == 0
					client.sendData('%xt%uz%-1%' + index.to_s + '%' + client.username + '%')
				else		
					@tablePopulationByID[tableID][@tablePopulationByID[tableID].keys.first].sendData('%xt%uz%-1%' + index.to_s + '%' + client.username + '%')
					@tablePopulationByID[tableID].each do |username, oclient|
						if @tablePopulationByID[tableID].keys.first.downcase != username.downcase
							@tablePopulationByID[tableID][username].sendData('%xt%uz%-1%' + index.to_s + '%' + username + '%')
						end
					end
				end
				if index == 1
					@tablePopulationByID[tableID].each do |username, oclient|
						@tablePopulationByID[tableID][username].sendData('%xt%sz%-1%0%')
					end
				end
			end
		end
	end
	
	def handleMovePuck(gameHandlerArgs, client)
		if client.room == 802
			rinkPuck = gameHandlerArgs.join('%')
			@gamePuck = rinkPuck
			client.sendRoom('%xt%zm%-1%' + client.ID.to_s + '%' + rinkPuck + '%')
		end
	end
	
	def handleSendMove(gameHandlerArgs, client)
		waddleID = client.waddleID
		if @sledRacing.include?(waddleID) != false
			return client.sendRoom('%xt%zm%' + gameHandlerArgs.join('%') + '%')
		end
		tableID = client.tableID
		if tableID != nil
			if @playersByTableID[tableID].index(client.username) < 2 && @playersByTableID[tableID].count >= 2
				if @findFourTables.include?(tableID) != false
					chipColumn = gameHandlerArgs[0]
					chipRow = gameHandlerArgs[1]
					if @parent.is_num?(chipColumn) != false && @parent.is_num?(chipRow) != false
						seatID = @playersByTableID[tableID].index(client.username)
						libID = seatID + 1
						if @gamesByTableID[tableID].currPlayer == libID
							gameStatus = @gamesByTableID[tableID].placeChip(chipColumn.to_i, chipRow.to_i).to_i
							@playersByTableID[tableID].each_with_index do |username, key|
								oclient = client.getClientByName(username)
								oclient.sendData('%xt%zm%-1%' + seatID.to_s + '%' + chipColumn.to_s + '%' + chipRow.to_s + '%')
							end
							if gameStatus == 1
								@playersByTableID[tableID].each_with_index do |username, key|
									if username.downcase != client.username.downcase
										oclient = client.getClientByName(username)
										oclient.addCoins(5)
										oclient.sendData('%xt%zo%-1%' + oclient.coins.to_s + '%')
									end
								end
								client.addCoins(10)
								client.sendData('%xt%zo%-1%' + client.coins.to_s + '%')
							elsif gameStatus == 2
								@playersByTableID[tableID].each_with_index do |username, key|
									if username.downcase != client.username.downcase
										oclient = client.getClientByName(username)
										oclient.addCoins(10)
										oclient.sendData('%xt%zo%-1%' + oclient.coins.to_s + '%')
									end
								end
								client.addCoins(10)
								client.sendData('%xt%zo%-1%' + client.coins.to_s + '%')
							end
						end
					end
				elsif @mancalaTables.include?(tableID) != false
					potIndex = gameHandlerArgs[0]
					if @parent.is_num?(potIndex) != false
						seatID = @playersByTableID[tableID].index(client.username)
						libID = seatID + 1
						if @gamesByTableID[tableID].currPlayer == libID
							gameStatus = @gamesByTableID[tableID].makeMove(potIndex.to_i)
							@playersByTableID[tableID].each_with_index do |username, key|
								oclient = client.getClientByName(username)
								if gameStatus == 'f' || gameStatus == 'c'
									oclient.sendData('%xt%zm%-1%' + seatID.to_s + '%' + potIndex.to_s + '%' + gameStatus.to_s + '%')
								else
									oclient.sendData('%xt%zm%-1%' + seatID.to_s + '%' + potIndex.to_s + '%')
								end
								if gameStatus == 1
									winnerID = @gamesByTableID[tableID].winner - 1
									oclient_name = @playersByTableID[tableID][winnerID]
									oclient = client.getClientByName(oclient_name)
									oclient.addCoins(10)
									oclient.sendData('%xt%zo%-1%' + oclient.coins.to_s + '%')				
									looserSeatID = winnerID == 0 ? 1 : 0
									client_name = @playersByTableID[tableID][looserSeatID]
									iclient = client.getClientByName(client_name)
									iclient.addCoins(5)
									iclient.sendData('%xt%zo%-1%' + iclient.coins.to_s + '%')
								elsif gameStatus == 2
									@playersByTableID[tableID].each_with_index do |username, key|
										if username.downcase != client.username.downcase
											oclient = client.getClientByName(username)
											oclient.addCoins(10)
											oclient.sendData('%xt%zo%-1%' + oclient.coins.to_s + '%')
										end
									end
									client.addCoins(10)
									client.sendData('%xt%zo%-1%' + client.coins.to_s + '%')
								end
							end
						end
					end
				end
			end
		end
	end
	
	def handleGetWaddlesPopulationById(gameHandlerArgs, client)
		if client.room == 230
			waddlePopulation = @waddlesByID[0].keys.map { |waddleID| waddleID.to_s + '|' + @waddlesByID[0][waddleID].join(',') }.join('%')
			client.sendData('%xt%gw%-1%' + waddlePopulation + '%')
		end
	end
	
	def handleJoinWaddle(gameHandlerArgs, client)
		self.leaveWaddle(client)
		waddleID = gameHandlerArgs[0]
		playerSeat = @waddleUsers.has_key?(waddleID) == true ? @waddleUsers[waddleID].count : 0
		@waddleUsers[waddleID][playerSeat] = client
		client.sendData('%xt%jw%-1%' + playerSeat.to_s + '%')
		waddleCount = @waddlesByID[0][waddleID].count - 1
		if playerSeat == waddleCount
			self.startWaddle(waddleID)
		end
		client.sendRoom('%xt%uw%-1%' + waddleID.to_s + '%' + playerSeat.to_s + '%' + client.username + '%')
	end
	
	def startWaddle(waddleID)
	      waddleRoomID = (@waddleRoom + 1) % 16384
		  userCount = @waddleUsers.count
		  @waddleUsers[waddleID].each do |playerSeat, waddlePenguin|
				waddlePenguin.waddleRoom = waddleRoomID
				waddlePenguin.waddleID = waddleID
				waddlePenguin.sendData('%xt%sw%-1%999%' + waddleRoomID.to_s + '%' + userCount.to_s + '%')
		  end
		  @waddleUsers[waddleID].clear
	end
	
	def leaveWaddle(client)
		@waddleUsers.each do |waddleID, waddle|
			waddle.each do |playerSeat, waddlePenguin|
				if waddlePenguin == client && waddlePenguin.room == client.room
					 client.sendRoom('%xt%uw%-1%' + waddleID.to_s + '%' + playerSeat.to_s + '%')
					 @waddlesByID[0][waddleID][playerSeat] = ''
					 @waddleUsers[waddleID].delete(playerSeat)
					 if client.waddleRoom != nil
						client.removePlayerFromRoom
						client.waddleRoom = nil
						client.waddleID = nil
					 end
				end
			end
		end
	end
	
	def handleLeaveWaddle(gameHandlerArgs, client)
		self.leaveWaddle(client)
	end
	
	def handleSendWaddle(gameHandlerArgs, client)
		roomID = gameHandlerArgs[0]
		xpos = gameHandlerArgs[1]
		ypos = gameHandlerArgs[2]
		client.joinRoom(roomID, xpos, ypos)
	end
	
end
