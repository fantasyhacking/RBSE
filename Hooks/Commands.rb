require 'htmlentities'

class Commands

	attr_accessor :enabled, :callAfter, :callBefore, :dependencies
	
	def initialize(mother)
		@parent = mother
		@enabled = true
		@callAfter = true
		@callBefore = false
		@dependencies = {
			'author' => 'Lynx',
			'version' => '1.0',
			'hook_type' => 'game'
		}
		@commands = {
			'ping' => 'handlePong',
			'global' => 'handleGlobalMessage',
			'users' => 'handleUserCount',
			'ai' => 'handleAddItem',
			'ac' => 'handleAddCoins',
			'addall' => 'handleAddAllItems',
			'summon' => 'handleSummonPenguin',
			'teleport' => 'handleTeleportPenguin',
			'find' => 'handleFindPenguin',
			'jr' => 'handleJoinRoom'
		}
		@prefix = '!'
	end
	
	def handleSendMessage(data, client)
		userID = data[0]
		userMessage = data[1]
		decodedMessage = HTMLEntities.new.decode(userMessage)
		cmdPrefix = decodedMessage[0,1]
		if cmdPrefix == @prefix
			messageArgs = decodedMessage[1..-1]
			msgArgs = messageArgs.split(' ', 2)
			userCMD = msgArgs[0].downcase
			cmdArgs = msgArgs[1]
			if @commands.has_key?(userCMD)
				cmdHandler = @commands[userCMD]
				self.send(cmdHandler, cmdArgs, client)
			end
		end
	end
	
	def handlePong(cmdArgs, client)
		client.sendData('%xt%sm%-1%0%Pong%') 
	end
	
	def handleGlobalMessage(cmdArgs, client)
		@parent.sock.clients.each_with_index do |client, key|
			@parent.sock.clients[key].sendData('%xt%sm%-1%0%' + cmdArgs + '%')
		end
	end
	
	def handleUserCount(cmdArgs, client)
		userCount = @parent.sock.clients.count
		if userCount == 1
			client.sendRoom('%xt%sm%-1%0%I guess its just you and me baby ;)%')
		else
			client.sendRoom("%xt%sm%-1%0%Currently there are " + userCount.to_s + " users online%")
		end
	end
	
	def handleAddCoins(cmdArgs, client)
		msgArgs = cmdArgs.split(' ')
		amount = msgArgs[0]
		if @parent.is_num?(amount) == true && amount.to_i < 5000
			client.addCoins(amount.to_i)
		end
	end
	
	def handleAddAllItems(cmdArgs, client)
		allItems = @parent.crumbs.item_crumbs.keys
		items = allItems.join('|')
		@parent.mysql.updatePenguinInventory(items, client.ID)
		client.sendData('%xt%sm%-1%0%Kindly re-login to the server to get all your items%')
	end
	
	def handleAddItem(cmdArgs, client)
		argsToSend = []
		msgArgs = cmdArgs.split(' ')
		item = msgArgs[0]
		if @parent.is_num?(item) == true
			argsToSend.push(item.to_i)
		end
		@parent.game_sys.handleAddInventory(argsToSend, client)
	end
	
	def handleSummonPenguin(cmdArgs, client)
		if client.ranking['isStaff'] == 1
			msgArgs = cmdArgs.split(' ')
			name = msgArgs[0]
			if @parent.is_num?(name) != true && name != client.username
				oclient = client.getClientByName(name)
				oclient.joinRoom(client.room)
				@parent.hooks['GameBot'].handleJoinRoom([client.room], client)
			end
		end
	end
	
	def handleTeleportPenguin(cmdArgs, client)
		msgArgs = cmdArgs.split(' ')
		name = msgArgs[0]
		if @parent.is_num?(name) != true && name != client.username
			oclient = client.getClientByName(name)
			client.joinRoom(oclient.room)
			@parent.hooks['GameBot'].handleJoinRoom([oclient.room], client)
		end
	end
	
	def handleFindPenguin(cmdArgs, client)
		msgArgs = cmdArgs.split(' ')
		name = msgArgs[0]
		if @parent.is_num?(name) != true && name != client.username
			oclient = client.getClientByName(name)
			room_name = @parent.crumbs.room_crumbs[oclient.room][0]['name']
			client.sendData('%xt%sm%-1%0%' + oclient.username + ' is at the ' + room_name + '%')
		end
	end
	
	def handleJoinRoom(cmdArgs, client)
		msgArgs = cmdArgs.split(' ')
		room = msgArgs[0]
		if @parent.is_num?(room) != false
			room = room.to_i
			if room > 0 && room < 1000
				client.joinRoom(room)
				@parent.hooks['GameBot'].handleJoinRoom([room], client)
			end
		end
	end

end
