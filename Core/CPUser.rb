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
			'rank' => 1
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
		@parent.sock.clients.each do |oclient|
			if oclient.room == @room
				oclient.sendData(data)
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
										self.instance_variable_set("@astatus#{modType}", modValue)
								end
						end
					when 'ranking'
						if value != ''
							rankData = JSON.parse(value)
								rankData.each do |rankType, rankValue|
										self.instance_variable_set("@ranking#{rankType}", rankValue)
								end
						end
					when 'clothing'
						if value != ''
							clothingData = JSON.parse(value)
								clothingData.each do |itemType, itemValue|
										self.instance_variable_set("@clothing#{itemType}", itemValue)
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
			(@ranking['rank'] * 146)		
		]
		return clientInfo.join('|')
	end
	
	def buildRoomString
		room_string = self.buildClientString + '%'
		@parent.sock.clients.each do |client|
			if client.room == @room && client.ID != @ID && client.username != ''
				room_string.concat(client.buildClientString + '%')
			end
		end
		return room_string
	end
	
	def joinRoom(room = 100, xaxis = 0, yaxis = 0)
		self.removePlayerFromRoom
		@frame = 0
		if room == 999
			@room = room
			@xaxis = xaxis
			@yaxis = yaxis
			return self.sendData('%xt%jx%-1%' + room.to_s + '%')
		end
		if @parent.crumbs.game_room_crumbs.has_key?(room) == true
			@room = room
			return self.sendData('%xt%jg%-1%' + room.to_s + '%')
		elsif @parent.crumbs.room_crumbs.has_key?(room) == true || room > 1000
			@room = room
			@xaxis = xaxis
			@yaxis = yaxis
			if room < 899 && self.getCurrentRoomCount >= @parent.crumbs.room_crumbs[room][0]['max']
				return self.sendError(210)
			end
			self.sendData('%xt%jr%-1%'  + room.to_s + '%' + self.buildRoomString)  
			self.sendRoom('%xt%ap%-1%' + self.buildClientString + '%')
		end
	end
	
	def getCurrentRoomCount
		count = 0
		@parent.sock.clients.each do |client|
			if client.room = @room
				count += 1
			end
		end
		return count
	end

	def removePlayerFromRoom
		self.sendData('%xt%rp%-1%' + @ID.to_s + '%')
	end
end
