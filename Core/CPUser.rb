require 'rubygems'
require 'date'
require 'json'

class CPUser

	attr_accessor :sock, :ID, :username, :lkey, :coins, :joindate, :clothes, :ranking, :astatus, :clothes, :ranking, :inventory, :buddies, :ignored, :buddyRequests, :room, :xaxis, :yaxis, :frame

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
		@inventory = Array.new
		@buddies = Hash.new
		@ignored = Hash.new
		@buddyRequests = Array.new
	end
	
	def sendData(data)
		if @sock.closed? != true
			data = data.concat(0)
			@sock.send(data, 0)
			@parent.logger.debug('Outgoing Data: ' + data)
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
						items = value.split('%')
						items.each do |item|
							@inventory.push(item)
						end
					when 'buddies'
						buddies = value.split(',')
						buddies.each do |buddy|
							buddyID, buddyName = buddy.split('|')
							@buddies.store(:buddyID, buddyName)
						end
					when 'ignored'
						ignoreds = value.split(',')
						ignoreds.each do |ignored|
							ignoredID, ignoredName = ignored.split('|')
							@ignored.store(:ignoredID, ignoredName)
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
								@ranking[rankType] = rankValue
							end
						end
					when 'clothing'
						if value != ''
							clothingData = JSON.parse(value)
							clothingData.each do |itemType, itemValue|
								@clothes[itemType] = itemValue
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
	
	def buildClientString
		clientInfo = [
			@ID,
			@username, 1,
			@clothes['color'],
			@clothes['head'],
			@clothes['face'],
			@clothes['neck'],
			@clothes['body'],
			@clothes['hand'],
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
	
	def getClientByID(userID)
		@parent.sock.clients.each_with_index do |client, key|
			if @parent.sock.clients[key].ID == userID
				return client
			end
		end
	end
	
	def saveClientInformation			
		self.updateCurrentInventory
		self.updateCurrentClothing
		self.updateCurrentModStatus
	end
	
	def updateCurrentClothing
		newClothing = @clothes.to_json
		@parent.mysql.updatePenguinClothing(newClothing, @ID)
	end
	
	def updateCurrentModeratingStatus
		newModStatus = @astatus.to_json
		@parent.mysql.updatePenguinModStatus(newModStatus, @ID)
	end
	
	def updateCurrentInventory
		newInventory = @inventory.join('%')
		@parent.mysql.updatePenguinInventory(newInventory, @ID)
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
		self.loadUserInfo
	end

	def removePlayerFromRoom
		self.sendData('%xt%rp%-1%' + @ID.to_s + '%')
	end
end
