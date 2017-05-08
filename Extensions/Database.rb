require 'rubygems'
require 'mysql2-cs-bind'
require 'json'

class Database

	def initialize(main_class)
		@parent = main_class
		@connection
	end

	def connectMySQL(db_user, db_pass, db_host, db_name)
		@connection = Mysql2::Client.new(:host => db_host, :username => db_user, :password => db_pass, :database => db_name, :reconnect => true)
		if @connection == nil
			@parent.logger.info('Failed to connect to the MySQL server')
		else
			@parent.logger.info('Successfully connected to the MySQL server')
		end
	end
	
	def checkUserExists(username)
		results = @connection.xquery("SELECT * FROM users WHERE username = ?", username)
		return results.count
	end
	
	def getCurrentPassword(username)
		results = @connection.xquery("SELECT * FROM users WHERE username = ?", username)
		results.each do |result|
			return result['password']
		end
	end
	
	def getBannedStatus(username)
		results = @connection.xquery("SELECT * FROM users WHERE username = ?", username)
		results.each do |result|
			moderation_status = result['moderation']
			decoded_status = JSON.parse(moderation_status)
			return decoded_status['isBanned']
		end
	end
	
	def getInvalidLogins(username)
		results = @connection.xquery("SELECT * FROM users WHERE username = ?", username)
		results.each do |result|
			return result['invalid_logins']
		end
	end
	
	def updateInvalidLogins(username, times)
		@connection.xquery("UPDATE users SET invalid_logins = ? WHERE username = ?", times, username)
	end
	
	def updateLoginKey(key, username)
		@connection.xquery("UPDATE users SET lkey = ? WHERE username = ?", key, username)
	end
	
	def updatePenguinClothing(newClothing, userID)
		@connection.xquery("UPDATE users SET clothing = ? WHERE ID = ?", newClothing, userID)
	end
	
	def updatePenguinInventory(newInventory, userID)
		@connection.xquery("UPDATE users SET inventory = ? WHERE ID = ?", newInventory, userID)
	end
	
	def updateCurrentCoins(newCoins, userID)
		@connection.xquery("UPDATE users SET coins = ? WHERE ID = ?", newCoins, userID)
	end
	
	def updatePenguinModStatus(newModStatus, userID)
		@connection.xquery("UPDATE users SET moderation = ? WHERE ID = ?", newModStatus, userID)
	end
	
	def updateFurnitureInventory(newInventory, userID)
		@connection.xquery("UPDATE igloos SET ownedFurns = ? WHERE ID = ?", newInventory, userID)
	end
	
	def updateIglooInventory(newInventory, userID)
		@connection.xquery("UPDATE igloos SET ownedIgloos = ? WHERE ID = ?", newInventory, userID)
	end
	
	def updateIglooType(iglooID, userID)
		@connection.xquery("UPDATE igloos SET igloo = ? WHERE ID = ?", iglooID, userID)
	end
	
	def updateFloorType(floorID, userID)
		@connection.xquery("UPDATE igloos SET floor = ? WHERE ID = ?", floorID, userID)
	end
	
	def updateIglooFurniture(furniture, userID)
		@connection.xquery("UPDATE igloos SET furniture = ? WHERE ID = ?", furniture, userID)
	end
	
	def updateIglooMusic(musicID, userID)
		@connection.xquery("UPDATE igloos SET music = ? WHERE ID = ?", musicID, userID)
	end
	
	def updatePenguinStamps(stamps, restamps, userID)
		@connection.xquery("UPDATE stamps SET stamps = ?, restamps = ? WHERE ID = ?", stamps, restamps, userID)
	end
	
	def updateStampbookCover(cover, userID)
		@connection.xquery("UPDATE stamps SET stampbook_cover = ? WHERE ID = ?", cover, userID)
	end
	
	def getPenguinInventoryByID(userID)
		results = @connection.xquery("SELECT * FROM users WHERE ID = ?", userID)
		results.each do |result|
			return result['inventory']
		end
	end
	
	def getStampsByID(userID)
		results = @connection.xquery("SELECT * FROM stamps WHERE ID = ?", userID)
		results.each do |result|
			return result['stamps']
		end
	end
	
	def getStampbookCoverByID(userID)
		results = @connection.xquery("SELECT * FROM stamps WHERE ID = ?", userID)
		results.each do |result|
			return result['stampbook_cover']
		end
	end
	
	def getLoginKey(username)
		results = @connection.xquery("SELECT * FROM users WHERE username = ?", username)
		results.each do |result|
			return result['lkey']
		end
	end
	
	def getClientIDByUsername(username)
		results = @connection.xquery("SELECT * FROM users WHERE username = ?", username)
		results.each do |result|
			return result['ID']
		end
	end
	
	def getUserDetails(userID)
		results = @connection.xquery("SELECT * FROM users WHERE ID = ?", userID)
		return results
	end
	
	def getIglooDetails(userID)
		results = @connection.xquery("SELECT * FROM igloos WHERE ID = ?", userID)
		return results
	end
	
	def getStampsInfo(userID)
		results = @connection.xquery("SELECT * FROM stamps WHERE ID = ?", userID)
		return results
	end
	
	def getPlayerString(userID)
		userDetails = self.getUserDetails(userID)
		userDetails.each do |detail|
			username = detail['username']
			clothing = JSON.parse(detail['clothing'])
			ranking = JSON.parse(detail['ranking'])
			requiredDetails = [
				userID,
				username, 1,
				clothing['color'],
				clothing['head'],
				clothing['face'],
				clothing['neck'],
				clothing['body'],
				clothing['hand'],
				clothing['feet'],
				clothing['flag'],
				clothing['photo'], 0, 0, 0,
				(ranking['rank'].to_i * 146)
			]
			userString = requiredDetails.join('|')
			return userString
		end
	end

end
