require 'rubygems'
require 'date'
require 'json'
require 'time'
require 'time_difference'

class CPUser

	attr_accessor :sock, :ID, :username, :lkey, :coins, :joindate, :clothes, :ranking, :astatus, :clothes, :ranking, :inventory, :buddies, :ignored, :room, :xaxis, :yaxis, :frame, :logged_in, :lastPacket, :spamFilter
	attr_accessor :igloo, :floor, :music, :furniture, :ownedFurns, :ownedIgloos
	attr_accessor :stamps, :restamps, :stampbook_cover
	attr_accessor :isagent, :status, :currentpoints, :totalpoints
	attr_accessor :tableID, :waddleRoom

	def initialize(main_class, socket)
		@parent = main_class
		@sock = socket
		@ID = 0
		@username = ''
		@lkey = ''
		@coins = 0
		@joindate = 0
		@clothes = {
			'color' => 0,
			'head' => 0,
			'face' => 0,
			'neck' => 0,
			'body' => 0,
			'hands' => 0,
			'feet' => 0,
			'flag' => 0,
			'photo' => 0
		}
		@ranking = {
			'isStaff' => 0,
			'isMed' => 0,
			'isMod' => 0,
			'isAdmin' => 0,
			'rank' => 0
		}
		@astatus = {
			'isBanned' => '',
			'isMuted' => ''
		}
		@room = 0
		@xaxis = 0
		@yaxis = 0
		@frame = 0
		@igloo = 0
		@floor = 0
		@music = 0
		@furniture = 0
		@ownedFurns = Hash.new
		@ownedIgloos = Array.new
		@inventory = Array.new
		@buddies = Hash.new
		@ignored = Hash.new
		@stamps = Array.new
		@restamps = Array.new
		@stampbook_cover = ''
		@isagent = 0
		@status = 0
		@currentpoints = 0
		@totalpoints = 0
		@logged_in = 0
		@lastPacket = Hash.new
		@spamFilter = Hash.new
		@tableID = nil
		@waddleRoom = nil
	end
	
	def sendData(data)
		if @sock.closed? != true
			data = data.concat(0)
			@sock.send(data, 0)
			@parent.logger.debug('Outgoing data: ' + data)
		end
	end
	
	def sendRoom(data)
		@parent.sock.clients.each_with_index do |client, key|
			if @parent.sock.clients[key].room == @room
				@parent.sock.clients[key].sendData(data)
			end
		end
	end
	
	def sendError(error)
		self.sendData('%xt%e%-1%' + error.to_s + '%')
	end
	
	def loadUserInfo
		clientInfo = @parent.mysql.getUserDetails(@ID)
		clientInfo.each do |info|
			info.each do |key, value|
				case key
					when 'inventory'
						items = value.split('|')
						items.each do |itemID|
							@inventory.push(itemID)
						end
					when 'buddies'
						buddies = value.split(',')
						buddies.each do |buddy|
							buddyID, buddyName = buddy.split('|')
							buddyID = buddyID.to_i
							@buddies[buddyID] = buddyName
						end
					when 'ignored'
						ignoreds = value.split(',')
						ignoreds.each do |ignored|
							ignoredID, ignoredName = ignored.split('|')
							ignoredID = ignoredID.to_i
							@ignored[ignoredID] = ignoredName
						end
					when 'moderation'
						if value != ''
							modData = JSON.parse(value)
							modData.each do |modType, modValue|
								@astatus[modType] = modValue
							end
						end
					when 'ranking'
						if value != ''
							rankData = JSON.parse(value)
							rankData.each do |rankType, rankValue|
								@ranking[rankType] = rankValue.to_i
							end
						end
					when 'clothing'
						if value != ''
							clothingData = JSON.parse(value)
							clothingData.each do |itemType, itemValue|
								@clothes[itemType] = itemValue.to_i
							end
						end
					when 'joindate'
						@joindate = (Time.now.to_date - value.to_date).to_i
					else
						self.instance_variable_set("@#{key}", value)
				end
			end
		end
	end
	
	def loadIglooInfo
		iglooInfo = @parent.mysql.getIglooDetails(@ID)
		iglooInfo.each do |info|
			info.each do |key, value|
				case key
					when 'ownedIgloos'
						igloos = value.split('|')
						igloos.each do |igloo|
							@ownedIgloos.push(igloo)
						end
					when 'ownedFurns'
						furnitures = value.split(',')
						furnitures.each do |furniture|
							furnDetails = furniture.split('|')
							furnQuantity = furnDetails[0]
							furnID = furnDetails[1]
							@ownedFurns[furnID] = furnQuantity
						end
					else
						self.instance_variable_set("@#{key}", value)
				end
			end
		end
	end
	
	def loadStampsInfo
		stampsInfo = @parent.mysql.getStampsInfo(@ID)
		stampsInfo.each do |info|
			info.each do |key, value|
				case key
					when 'stamps'
						stamps = value.split('|')
						stamps.each do |stamp|
							@stamps.push(stamp)
						end
					when 'restamps'
						restamps = value.split('|')
						restamps.each do |stamp|
							@restamps.push(stamp)
						end
					else
						self.instance_variable_set("@#{key}", value)
				end
			end
		end
	end
	
	def loadEPFInfo
		epfInfo = @parent.mysql.getEPFDetails(@ID)
		epfInfo.each do |info|
			info.each do |key, value|
				self.instance_variable_set("@#{key}", value.to_i)
			end
		end
	end
	
	def buildClientString
		clientInfo = [
			@ID,
			@username, 1,
			@clothes['color'],
			@clothes['head'],
			@clothes['face'],
			@clothes['neck'],
			@clothes['body'],
			@clothes['hands'],
			@clothes['feet'],
			@clothes['flag'],
			@clothes['photo'],
			@xaxis,
			@yaxis,
			@frame, 1,
			(@ranking['rank'].to_i * 146)		
		]
		return clientInfo.join('|')
	end
	
	def buildRoomString
		room_string = self.buildClientString + '%'
		@parent.sock.clients.each_with_index do |client, key|
			if @parent.sock.clients[key].room == @room && client.ID != @ID 
					room_string << @parent.sock.clients[key].buildClientString + '%'
			end
		end
		return room_string
	end
	
	def joinRoom(roomID = 100, xpos = 0, ypos = 0)
		self.removePlayerFromRoom
		@frame = 0
		if room == 999
			@room = roomID
			@xaxis = xpos
			@yaxis = ypos
			return self.sendData('%xt%jx%-1%' + roomID.to_s + '%')
		end
		if @parent.crumbs.game_room_crumbs.has_key?(roomID) == true
			@room = roomID
			self.sendRoom('%xt%ap%-1%' + self.buildClientString + '%')
			return self.sendData('%xt%jg%-1%' + roomID.to_s + '%')
		elsif @parent.crumbs.room_crumbs.has_key?(roomID) == true || roomID > 1000
			@room = roomID
			@xaxis = xpos
			@yaxis = ypos
			if roomID < 899 && self.getCurrentRoomCount >= @parent.crumbs.room_crumbs[roomID][0]['max']
				return self.sendError(210)
			end
			self.sendData('%xt%jr%-1%'  + @room.to_s + '%' + self.buildRoomString)  
			self.sendRoom('%xt%ap%-1%' + self.buildClientString + '%')
		end
	end
	
	def getCurrentRoomCount
		count = 0
		@parent.sock.clients.each_with_index do |client, key|
			if @parent.sock.clients[key].room == @room
				count += 1
			end
		end
		return count
	end
	
	def getOnline(userID)
		@parent.sock.clients.each_with_index do |client, key|
			if @parent.sock.clients[key].ID.to_i == userID.to_i
				return 1
			end
		end
		return 0
	end
	
	def getClientByID(userID)
		@parent.sock.clients.each_with_index do |client, key|
			if @parent.sock.clients[key].ID.to_i == userID.to_i
				return client
			end
		end
	end
	
	def getClientByName(username)
		@parent.sock.clients.each_with_index do |client, key|
			if @parent.sock.clients[key].username == username
				return client
			end
		end
	end
	
	def updateCurrentClothing
		newClothing = @clothes.to_json
		@parent.mysql.updatePenguinClothing(newClothing, @ID)
	end
	
	def updateCurrentModStatus
		newModStatus = @astatus.to_json
		@parent.mysql.updatePenguinModStatus(newModStatus, @ID)
	end
	
	def updateCurrentInventory
		newInventory = @inventory.join('|')
		@parent.mysql.updatePenguinInventory(newInventory, @ID)
	end
	
	def updateCurrentFurnInventory
		furnitures = ''
		@ownedFurns.each do |furnitureQuantity, furnitureID|
			furnitures << furnitureID.to_s + '|' + furnitureQuantity.to_s + ','
		end
		@parent.mysql.updateFurnitureInventory(furnitures, @ID)
	end
	
	def updateCurrentIglooInventory
		newInventory = @ownedIgloos.join('|')
		@parent.mysql.updateIglooInventory(newInventory, @ID)
	end
	
	def updateCurrentStamps
		newStamps = @stamps.join('|')
		newRestamps = @restamps.join('|')
		@parent.mysql.updatePenguinStamps(newStamps, newRestamps, @ID)
	end
	
	def updateCurrentBuddies
		buddyString = ''
		@buddies.each do |buddyID, buddyName|
			buddyString << buddyID.to_s + '|' + buddyName + ','
		end
		@parent.mysql.updateBuddies(buddyString, @ID)
	end
	
	def updateCurrentIgnoredBuddies
		buddyString = ''
		@ignored.each do |buddyID, buddyName|
			buddyString << buddyID.to_s + '|' + buddyName + ','
		end
		@parent.mysql.updateIgnoredBuddies(buddyString, @ID)
	end
	
	
	def addCoins(amount)
		newAmount = (@coins + amount)
		@parent.mysql.updateCurrentCoins(newAmount, @ID)
		@coins = newAmount
		self.loadUserInfo
	end
	
	def deductCoins(amount)
		newAmount = (@coins - amount)
		@parent.mysql.updateCurrentCoins(newAmount, @ID)
		@coins = newAmount
	end
	
	def deductEPFPoints(points)
		newPoints = (@currentpoints - points)
		@parent.mysql.updateCurrentEPFPoints(newPoints, @ID)
		@currentpoints = newPoints
	end

	def removePlayerFromRoom
		self.sendData('%xt%rp%-1%' + @ID.to_s + '%')
	end
	
	def handleBuddyOnline
		@buddies.each do |buddyID, buddyName|
			if self.getOnline(buddyID) != 0
				oclient = self.getClientByID(buddyID)
				oclient.sendData('%xt%bon%-1%' + @ID.to_s + '%')
			end
		end
	end
	
	def handleBuddyOffline
		@buddies.each do |buddyID, buddyName|
			if self.getOnline(buddyID) != 0
				oclient = self.getClientByID(buddyID)
				oclient.sendData('%xt%bof%-1%' + @ID.to_s + '%')
			end
		end
	end
	
	def checkPuffleStats
		userPuffles = @parent.mysql.getPufflesByOwner(@ID)
		userPuffles.each do |userPuff|
			puffleID = userPuff['puffleID']
			timeDiff = (TimeDifference.between(Time.parse(userPuff['lastFedTime'].to_s), Time.now).in_hours).round
			energyTimeDiff = (TimeDifference.between(Time.parse(userPuff['lastFedTime'].to_s), Time.now).in_minutes).round
			if timeDiff.to_i >= 1
				randHealth = rand(3..10)
				randEnergy = rand(7..12)
				randRest = rand(1..7)
				newPuffleHealth = userPuff['puffleHealth'].to_i - randHealth
				newPuffleEnergy = userPuff['puffleEnergy'].to_i - randEnergy
				newPuffleRest = userPuff['puffleRest'].to_i - randRest
				@parent.mysql.updatePuffleStatByType('puffleHealth', newPuffleHealth, puffleID, @ID)
				@parent.mysql.updatePuffleStatByType('puffleEnergy', newPuffleEnergy, puffleID, @ID)
				@parent.mysql.updatePuffleStatByType('puffleRest', newPuffleRest, puffleID, @ID)
			end
			if userPuff['puffleHealth'].to_i < 5
				puffType = userPuff['puffleType']
				currTimestamp = Time.now.to_i
				postcardType = 0
				realPuffleType = "75#{puffType}"
				case puffType
					when 0
						postcardType = 100
					when 1
						postcardType = 101
					when 2
						postcardType = 102
					when 3
						postcardType = 103
					when 4
						postcardType = 104
					when 5
						postcardType = 105
					when 6
						postcardType = 106
					when 7
						postcardType = 169
					when 8
						postcardType = 109
				end
				postcardID = @parent.mysql.addPostcard(@ID, 'sys', 0, userPuff['puffleName'], postcardType, currTimestamp)
				self.sendData('%xt%mr%-1%sys%0%' + postcardType.to_s + '%' + userPuff['puffleName'].to_s + '%' + currTimestamp.to_s + '%' + postcardID.to_s + '%')
				if self.clothes['hands'] == realPuffleType.to_i
					self.clothes['hands'] = 0
					self.updateCurrentClothing
				end
				@parent.mysql.deletePuffleByID(@ID, puffleID)
			end
			if userPuff['puffleEnergy'].to_i <= 45 && energyTimeDiff.to_i >= 30
				currTimestamp = Time.now.to_i
				postcardID = @parent.mysql.addPostcard(@ID, 'sys', 0, userPuff['puffleName'], 110, currTimestamp)
				self.sendData('%xt%mr%-1%sys%0%110%' + userPuff['puffleName'].to_s + '%' + currTimestamp.to_s + '%' + postcardID.to_s + '%')
			end
		end
	end
	
end
