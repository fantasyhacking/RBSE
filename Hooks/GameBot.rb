require 'rubygems'

class GameBot

	attr_accessor :enabled, :callAfter, :callBefore, :dependencies
	
	def initialize(mother)
		@parent = mother
		@enabled = true
		@callAfter = true
		@callBefore = false
		@dependencies = {
			'author' => 'Lynx',
			'version' => '0.1',
			'hook_type' => 'game'
		}
		@botInfo = {
			'botID' => 0,
			'botName' => 'Bot'
		}
	end
	
	def generateClothing(type)
		@randItems = Array.new
		@parent.crumbs.item_crumbs.keys.each do |itemID|
			item_type = @parent.crumbs.item_crumbs[itemID][0]['type']
			if item_type.downcase == type
				@randItems.push(itemID)
			end	
		end
		return @randItems.sample
	end
	
	def buildBotString
		clientInfo = [
			@botInfo['botID'],
			@botInfo['botName'], 1,
			self.generateClothing('color'),
			self.generateClothing('head'),
			self.generateClothing('face'),
			self.generateClothing('neck'),
			self.generateClothing('body'),
			self.generateClothing('hand'),
			self.generateClothing('feet'),
			self.generateClothing('flag'),
			self.generateClothing('photo'), 0, 0, 0, 1, 876		
		]
		return clientInfo.join('|')
	end
	
	def handleJoinRoom(data, client)
		roomID = data[0]
		if @parent.crumbs.game_room_crumbs.has_key?(roomID) != true
			client.sendRoom('%xt%ap%-1%' + self.buildBotString + '%')
		end
	end
	
	def handleJoinServer(data, client)
		client.sendRoom('%xt%ap%-1%' + self.buildBotString + '%')
	end
	
	def handleJoinPlayer(data, client)
		roomID = data[0]
		if @parent.crumbs.game_room_crumbs.has_key?(roomID) != true
			client.sendRoom('%xt%ap%-1%' + self.buildBotString + '%')
		end
	end

end
