require 'rubygems'
require 'bcrypt'
require 'htmlentities'
require 'to_bool'

class Game < XTParser

	attr_accessor :iglooMap

	def initialize(main_class)
		@parent = main_class
		@xtPackets = Hash.new
		@iglooMap = Hash.new
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
		client.sendData('%xt%gps%-1%' + client.ID.to_s + '%' + client.stamps.join('|') + '%')
		@parent.mysql.updateLoginKey("", client.username)
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
		userDetails = @parent.mysql.getPlayerString(userID)
		client.sendData('%xt%gp%-1%' + (userDetails ? userDetails : '') + '%')
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
		client.updateCurrentInventory
		client.sendData('%xt%ai%-1%' + itemID.to_s + '%' + client.coins.to_s + '%')
	end
	
	def handleQueryPlayerPins(gameHandlerArgs, client)
		userID = gameHandlerArgs[0]
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
	
	def handleQueryPlayerAwards(gameHandlerArgs, client)
		userID = gameHandlerArgs[0]
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
		if furnQuantity >= 900
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
			return client.sendError(400)
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
		iglooID = ''
		musicID = ''
		floorID = ''
		furniture = ''
		iglooData = @parent.mysql.getIglooDetails(client.ID)
		iglooData.each do |iglooInfo|
			iglooID = iglooInfo['igloo'].to_s
			musicID = iglooInfo['music'].to_s
			floorID = iglooInfo['floor'].to_s
			furniture = iglooInfo['furniture'].to_s
		end
		client.sendData('%xt%gm%-1%' + client.ID.to_s + '%' + (iglooID ? iglooID : 1) + '%' + (musicID ? musicID : 0) + '%' + (floorID ? floorID : 0) + '%' +  (furniture ? furniture : '') + '%')
	end
	
	def handlePuffleGet(gameHandlerArgs, client)
		client.sendData('%xt%pg%-1%%')
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
		client.sendData('%xt%gf%-1%' + furnitures + '%')
	end
	
	def handleGetFurnitureRevision(gameHandlerArgs, client)
		furnitures = ''
		gameHandlerArgs.each do |furniture|
			furnitureInfo = furniture.split('|')
			if furnitureInfo.count > 5
				@parent.logger.warn('Client is trying to send invalid furniture arguments')
				return false
			end
			furnitureInfo.each do |info|
				if @parent.is_num?(info) != true
					@parent.logger.warn('Client is trying to send an invalid Furniture')
					return false
				end
			end
			furnitures << ',' + furniture
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
		userStamps = @parent.mysql.getStampsByID(userID)
		client.sendData('%xt%gps%-1%' + userID.to_s + '%' + userStamps + '%')
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
		stampbook_cover = gameHandlerArgs.join('%')
		@parent.mysql.updateStampbookCover(stampbook_cover, client.ID)
		client.sendData('%xt%ssbcd%-1%' + (stampbook_cover ? stampbook_cover : '%'))
	end

end
