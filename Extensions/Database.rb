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

end
