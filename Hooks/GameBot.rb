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
			'botName' => 'Bot',
			'botClothing' => {
				'color' => 14,
				'head' => 413,
				'face' => 410,
				'neck' => 161,
				'body' => 0,
				'hand' => 0,
				'feet' => 0,
				'flag' => 0,
				'photo' => 0
			}
		}
	end
	
	def buildBotString
		clientInfo = [
			@botInfo['botID'],
			@botInfo['botName'], 1,
			@botInfo['botClothing']['color'],
			@botInfo['botClothing']['head'],
			@botInfo['botClothing']['face'],
			@botInfo['botClothing']['neck'],
			@botInfo['botClothing']['body'],
			@botInfo['botClothing']['hand'],
			@botInfo['botClothing']['feet'],
			@botInfo['botClothing']['flag'],
			@botInfo['botClothing']['photo'], 0, 0, 0, 1, 876		
		]
		return clientInfo.join('|')
	end
	
	def handleJoinRoom(data, client)
		client.sendRoom('%xt%ap%-1%' + self.buildBotString + '%')
	end
	
	def handleJoinServer(data, client)
		client.sendRoom('%xt%ap%-1%' + self.buildBotString + '%')
	end

end
