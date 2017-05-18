class LoginNotice

	attr_accessor :enabled, :callAfter, :callBefore, :dependencies
	
	def initialize(mother)
		@parent = mother
		@enabled = true
		@callAfter = false
		@callBefore = true
		@dependencies = {
			'author' => 'Lynx',
			'version' => '0.1',
			'hook_type' => 'login'
		}
	end

	def handleGameLogin(data, client)
		username = data['msg']['body']['login']['nick']
		@parent.logger.info("#{username.upcase_first} is attempting to log in to the server")
	end
	
end
