require 'rubygems'
require 'bcrypt'
require 'digest'
require 'to_bool'

class Login

	include BCrypt

	attr_accessor :xml_handlers

	def initialize(main_class)
		@parent = main_class
		@xml_handlers = {'verChk' => 'handleVersionCheck', 'login' => 'handleGameLogin'}
	end
	
	def handleCrossDomainPolicy(client)
		client.sendData("<cross-domain-policy><allow-access-from domain='*' to-ports='" + @parent.server_config['server_port'].to_s + "' /></cross-domain-policy>")
	end
	
	def handleVersionCheck(data, client)
		version = data['msg']['body']['ver']['v'].to_i
		return version == 153 ? client.sendData("<msg t='sys'><body action='apiOK' r='0'></body></msg>") : client.sendData("<msg t='sys'><body action='apiKO' r='0'></body></msg>")
	end
	
	def handleGameLogin(data, client)
		username = data['msg']['body']['login']['nick']
		password = data['msg']['body']['login']['pword']
		if (username !~ /^[A-Za-z0-9]+$/)
			client.sendError(100)
		end
		if password.length < 64
			return client.sendError(101)
		end
		userExists = @parent.mysql.checkUserExists(username);
		if userExists == 0
			return client.sendError(100)
		end
		invalidLogins = @parent.mysql.getInvalidLogins(username)
		if invalidLogins >= 5
			return client.sendError(150)
		end
		validPass = @parent.mysql.getCurrentPassword(username)
		cryptedPass = BCrypt::Password.new(validPass)
		if cryptedPass != password.upcase
			currInvalidAttempts = @parent.mysql.getInvalidLogins(username)
			currInvalidAttempts += 1
			@parent.mysql.updateInvalidLogins(username, currInvalidAttempts)
			return client.sendError(101)
		end	
		bannedStatus = @parent.mysql.getBannedStatus(username)
		if @parent.is_num?(bannedStatus) == false && bannedStatus == 'PERMBANNED'
			return client.sendError(603)
		else
			currTime = Time.now.to_i
			if bannedStatus.to_i > currTime
				remainingTime = ((currTime.to_i - bannedStatus.to_i) / 3600).round
				return client.sendError("601%" + remainingTime.to_s)
			end
		end
		encryptedRandKey = Digest::SHA256.hexdigest(@parent.genRandString(12))
		bcryptRandKey = BCrypt::Password.create(encryptedRandKey, cost: 12)
		@parent.mysql.updateLoginKey(bcryptRandKey, username)
		clientID = @parent.mysql.getClientIDByUsername(username)
		client.sendData('%xt%l%-1%' + clientID.to_s + '%' + encryptedRandKey + '%')
		client.ID = clientID
		client.lkey = encryptedRandKey
		client.loadUserInfo
		client.loadIglooInfo
		client.loadStampsInfo
		client.loadEPFInfo
		client.handleBuddyOnline
	end

end
