require 'rubygems'
require 'mysql2-cs-bind'
require 'json'
require 'connection_pool'

class Database

	def initialize(main_class)
		@parent = main_class
		@connections
	end

	def connectMySQL(db_user, db_pass, db_host, db_name)
		@connections = ConnectionPool.new(:size => 10) { Mysql2::Client.new(:host => db_host, :username => db_user, :password => db_pass, :database => db_name, :reconnect => true) }
		@connections.with do |connection|
			if connection == nil
				@parent.logger.info('Failed to connect to the MySQL server')
			else
				@parent.logger.info('Successfully connected to the MySQL server')
			end
		end
	end
	
	def checkUserExists(username)
		@connections.with do |connection|
			results = connection.xquery("SELECT * FROM users WHERE username = ?", username)
			return results.count
		end
	end
	
	def getCurrentPassword(username)
		@connections.with do |connection|
			results = connection.xquery("SELECT * FROM users WHERE username = ?", username)
			results.each do |result|
				return result['password']
			end
		end
	end
	
	def getBannedStatus(username)
		@connections.with do |connection|
			results = connection.xquery("SELECT * FROM users WHERE username = ?", username)
			results.each do |result|
				moderation_status = result['moderation']
				decoded_status = JSON.parse(moderation_status)
				return decoded_status['isBanned']
			end
		end
	end
	
	def getInvalidLogins(username)
		@connections.with do |connection|
			results = connection.xquery("SELECT * FROM users WHERE username = ?", username)
			results.each do |result|
				return result['invalid_logins']
			end
		end
	end
	
	def updateInvalidLogins(username, times)
		@connections.with do |connection|
			connection.xquery("UPDATE users SET invalid_logins = ? WHERE username = ?", times, username)
		end
	end
	
	def updateLoginKey(key, username)
		@connections.with do |connection|
			connection.xquery("UPDATE users SET lkey = ? WHERE username = ?", key, username)
		end
	end
	
	def updatePenguinClothing(newClothing, userID)
		@connections.with do |connection|
			connection.xquery("UPDATE users SET clothing = ? WHERE ID = ?", newClothing, userID)
		end
	end
	
	def updatePenguinInventory(newInventory, userID)
		@connections.with do |connection|
			connection.xquery("UPDATE users SET inventory = ? WHERE ID = ?", newInventory, userID)
		end
	end
	
	def updateCurrentCoins(newCoins, userID)
		@connections.with do |connection|
			connection.xquery("UPDATE users SET coins = ? WHERE ID = ?", newCoins, userID)
		end
	end
	
	def updateCurrentEPFPoints(newPoints, userID)
		@connections.with do |connection|
			connection.xquery("UPDATE epf SET currentpoints = ? WHERE ID = ?", newPoints, userID)
		end
	end
	
	def updatePenguinModStatus(newModStatus, userID)
		@connections.with do |connection|
			connection.xquery("UPDATE users SET moderation = ? WHERE ID = ?", newModStatus, userID)
		end
	end
	
	def updateFurnitureInventory(newInventory, userID)
		@connections.with do |connection|
			connection.xquery("UPDATE igloos SET ownedFurns = ? WHERE ID = ?", newInventory, userID)
		end
	end
	
	def updateIglooInventory(newInventory, userID)
		@connections.with do |connection|
			connection.xquery("UPDATE igloos SET ownedIgloos = ? WHERE ID = ?", newInventory, userID)
		end
	end
	
	def updateIglooType(iglooID, userID)
		@connections.with do |connection|
			connection.xquery("UPDATE igloos SET igloo = ? WHERE ID = ?", iglooID, userID)
		end
	end
	
	def updateFloorType(floorID, userID)
		@connections.with do |connection|
			connection.xquery("UPDATE igloos SET floor = ? WHERE ID = ?", floorID, userID)
		end
	end
	
	def updateIglooFurniture(furniture, userID)
		@connections.with do |connection|
			connection.xquery("UPDATE igloos SET furniture = ? WHERE ID = ?", furniture, userID)
		end
	end
	
	def updateIglooMusic(musicID, userID)
		@connections.with do |connection|
			connection.xquery("UPDATE igloos SET music = ? WHERE ID = ?", musicID, userID)
		end
	end
	
	def updatePenguinStamps(stamps, restamps, userID)
		@connections.with do |connection|
			connection.xquery("UPDATE stamps SET stamps = ?, restamps = ? WHERE ID = ?", stamps, restamps, userID)
		end
	end
	
	def updateStampbookCover(cover, userID)
		@connections.with do |connection|
			connection.xquery("UPDATE stamps SET stampbook_cover = ? WHERE ID = ?", cover, userID)
		end
	end
	
	def updateBuddies(buddies, userID)
		@connections.with do |connection|
			connection.xquery("UPDATE users SET buddies = ? WHERE ID = ?", buddies, userID)
		end
	end
	
	def updateIgnoredBuddies(ignored, userID)
		@connections.with do |connection|
			connection.xquery("UPDATE users SET ignored = ? WHERE ID = ?", ignored, userID)
		end
	end
	
	def getPenguinInventoryByID(userID)
		@connections.with do |connection|
			results = connection.xquery("SELECT * FROM users WHERE ID = ?", userID)
			results.each do |result|
				return result['inventory']
			end
		end
	end
	
	def getStampsByID(userID)
		@connections.with do |connection|
			results = connection.xquery("SELECT * FROM stamps WHERE ID = ?", userID)
			results.each do |result|
				return result['stamps']
			end
		end
	end
	
	def getStampbookCoverByID(userID)
		@connections.with do |connection|
			results = connection.xquery("SELECT * FROM stamps WHERE ID = ?", userID)
			results.each do |result|
				return result['stampbook_cover']
			end
		end
	end
	
	def getLoginKey(username)
		@connections.with do |connection|
			results = connection.xquery("SELECT * FROM users WHERE username = ?", username)
			results.each do |result|
				return result['lkey']
			end
		end
	end
	
	def getClientIDByUsername(username)
		@connections.with do |connection|
			results = connection.xquery("SELECT * FROM users WHERE username = ?", username)
			results.each do |result|
				return result['ID']
			end
		end
	end
	
	def getClientBuddiesByID(userID)
		@connections.with do |connection|
			results = connection.xquery("SELECT * FROM users WHERE ID = ?", userID)
			results.each do |result|
				return result['buddies']
			end
		end
	end
	
	def getUserDetails(userID)
		@connections.with do |connection|
			results = connection.xquery("SELECT * FROM users WHERE ID = ?", userID)
			return results
		end
	end
	
	def getIglooDetails(userID)
		@connections.with do |connection|
			results = connection.xquery("SELECT * FROM igloos WHERE ID = ?", userID)
			return results
		end
	end
	
	def getStampsInfo(userID)
		@connections.with do |connection|
			results = connection.xquery("SELECT * FROM stamps WHERE ID = ?", userID)
			return results
		end
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
				clothing['hands'],
				clothing['feet'],
				clothing['flag'],
				clothing['photo'], 0, 0, 0,
				(ranking['rank'].to_i * 146)
			]
			userString = requiredDetails.join('|')
			return userString
		end
	end
	
	def getUnreadPostcardCount(userID)
		@connections.with do |connection|
			results = connection.xquery("SELECT * FROM postcards WHERE recepient = ? AND isRead = ?", userID, 0)
			unread_count = results.count
			return unread_count
		end
	end
	
	def getReceivedPostcardCount(userID)
		@connections.with do |connection|
			results = connection.xquery("SELECT * FROM postcards WHERE recepient = ?", userID)
			postcards_count = results.count
			return postcards_count
		end
	end
	
	def getUserPostcards(userID)
		postcardsString = ''
		@connections.with do |connection|
			results = connection.xquery("SELECT * FROM postcards WHERE recepient = ?", userID)
			results.each do |result|
				postcardsString << result['mailerName'].to_s + '|' + result['mailerID'].to_s + '|' + result['postcardType'].to_s + '|' + result['notes'].to_s + '|' + result['timestamp'].to_s + '|' + result['postcardID'].to_s + '%'
			end
			return postcardsString[0..-1]
		end
	end
	
	def addPostcard(recepient, mailerName  = 'sys', mailerID = 0, postcardNotes = 'RBSE', postcardType = 1, timestamp = 0)
		@connections.with do |connection|
			connection.xquery("INSERT INTO postcards (recepient, mailerName, mailerID, notes, postcardType, timestamp) values (?, ?, ?, ?, ?, ?)", recepient, mailerName, mailerID, postcardNotes, postcardType, timestamp)
			return connection.last_id
		end
	end
	
	def deletePostcardByRecepient(postcard, recepient)
		@connections.with do |connection|
			connection.xquery("DELETE FROM postcards WHERE postcardID = ? AND recepient = ?", postcard, recepient)
		end
	end
	
	def deletePostcardsByMailer(recepient, sender)
		@connections.with do |connection|
			connection.xquery("DELETE FROM postcards WHERE recepient = ? AND mailerID = ?", recepient, sender)
		end
	end
	
	def updatePostcardRead(userID)
		@connections.with do |connection|
			connection.xquery("UPDATE postcards SET isRead = ? WHERE recepient = ?", 1, userID)
		end
	end
	
	def getNonWalkingPuffles(userID)
		pufflesString = ''
		@connections.with do |connection|
			results = connection.xquery("SELECT * FROM puffles WHERE ownerID = ? AND puffleWalking = ?", userID, 0)
			results.each do |result|
				pufflesString << result['puffleID'].to_s + '|' + result['puffleName'].to_s + '|' + result['puffleType'].to_s + '|' + result['puffleHealth'].to_s + '|' + result['puffleEnergy'].to_s + '|' + result['puffleRest'].to_s + '%'
			end
			return pufflesString
		end
	end
	
	def getPuffleIDByOwner(userID, puffleID)
		@connections.with do |connection|
			results  = connection.xquery("SELECT * FROM puffles WHERE ownerID = ? AND puffleID = ?", userID, puffleID)
			results.each do |result|
				return result['puffleID'].to_i
			end
		end
	end
	
	def getPuffleByOwner(userID, puffleID)
		puffleString = ''
		@connections.with do |connection|
			results  = connection.xquery("SELECT * FROM puffles WHERE ownerID = ? AND puffleID = ?", userID, puffleID)
			results.each do |result|
				puffleString << result['puffleID'].to_s + '|' + result['puffleName'].to_s + '|' + result['puffleType'].to_s + '|' + result['puffleHealth'].to_s + '|' + result['puffleEnergy'].to_s + '|' + result['puffleRest'].to_s + '%'
			end
		end
		return puffleString
	end
	
	def getWalkingPuffleIDS(userID)
		puffIDS = []
		@connections.with do |connection|
			results = connection.xquery("SELECT * FROM puffles WHERE ownerID = ? AND puffleWalking = ?", userID, 1)
			results.each do |result|
				puffIDS.push(result['puffleID'])
			end
		end
		return puffIDS
	end
	
	def updateWalkingPuffle(blnWalking, userID, puffleID)
		@connections.with do |connection|
			connection.xquery("UPDATE puffles SET puffleWalking = ? WHERE puffleID = ? AND ownerID = ?", blnWalking, puffleID, userID)
		end
	end
	
	def getPuffleDetailsByOwner(userID, puffleID)
		@connections.with do |connection|
			results  = connection.xquery("SELECT * FROM puffles WHERE ownerID = ? AND puffleID = ?", userID, puffleID)
			results.each do |result|
				return result
			end
		end
	end
	
	def updatePuffleStatByType(statType, newStat, puffleID, userID)
		@connections.with do |connection|
			connection.xquery("UPDATE puffles SET #{statType} = ? WHERE puffleID = ? AND ownerID = ?", newStat, puffleID, userID)
		end
	end
	
	def addPuffle(puffleType, puffleName, ownerID)
		@connections.with do |connection|
			connection.xquery("INSERT INTO puffles (ownerID, puffleName, puffleType) values (?, ?, ?)", ownerID, puffleName, puffleType)
			puffleID = connection.last_id
			puffle = puffleID.to_s + '|' + puffleName.to_s + '|' + puffleType.to_s + '|100|100|100'
			return puffle
		end
	end
	
	def getPufflesByOwner(userID)
		@connections.with do |connection|
			results  = connection.xquery("SELECT * FROM puffles WHERE ownerID = ?", userID)
			return results
		end
	end
	
	def deletePuffleByID(userID, puffleID)
		@connections.with do |connection|
			connection.xquery("DELETE FROM puffles WHERE puffleID = ? AND ownerID = ?", puffleID, userID)
		end
	end
	
	def getEPFDetails(userID)
		@connections.with do |connection|
			results = connection.xquery("SELECT * FROM epf WHERE ID = ?", userID)
			return results
		end
	end
	
	def checkIfSignedIglooContest(userID)
		@connections.with do |connection|
			results = connection.xquery("SELECT * FROM igloo_contest WHERE ID = ?", userID)
			return results.empty ? true : false
		end
	end
	
	def getLastIglooContestSignUpTime(userID)
		@connections.with do |connection|
			results = connection.xquery("SELECT * FROM igloo_contest WHERE ID = ?", userID)
			results.each do |result|
				return result['signup_time']
			end
		end
	end
	
	def deleteExistingSignUpDetails(userID)
		@connections.with do |connection|
			connection.xquery("DELETE FROM igloo_contest WHERE ID = ?", userID)
		end
	end
	
	def signupIglooContest(userID, username)
		@connections.with do |connection|
			connection.xquery("INSERT INTO igloo_contest (ID, username) values (?, ?)", userID, username)
		end
	end
	
	def updateLoggedIn(blnLogin, username)
		@connections.with do |connection|
			connection.xquery("UPDATE users SET logged_in = ? WHERE username = ?", blnLogin, username)
		end
	end
	
	def getLoggedInStatus(username)
		@connections.with do |connection|
			results = connection.xquery("SELECT * FROM users WHERE username = ?", username)
			results.each do |result|
				return result['logged_in']
			end
		end
	end

end
