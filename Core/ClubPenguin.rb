require 'rubygems'
require 'log4r'
require 'time'
require 'nokogiri'

class ClubPenguin
	
	attr_accessor :logger, :crumbs, :server_config, :mysql, :sock, :login_sys, :game_sys, :crypto, :hooks

	def initialize(config_info)
		@server_config = config_info
		@logger = Log4r::Logger.new('>>> [' + Time.now.strftime("%I:%M%p")  + '] ')
		@logger.outputters << Log4r::Outputter.stdout
		@logger.outputters << Log4r::FileOutputter.new('log', :filename =>  'log.log')
		@crumbs = Crumbs.new(self)
		@mysql = Database.new(self)
		@sock = TCP.new(self)
		@login_sys = Login.new(self)
		@game_sys = Game.new(self)
		@hooks = Hash.new
	end
	
	def startEmulator
		self.displayASCII
		@crumbs.loadCrumbs
		@mysql.connectMySQL(@server_config['database_user'], @server_config['database_pass'], @server_config['database_host'], @server_config['database_name'])
		@sock.connectServer
		self.loadHooks
	end

	def displayASCII
		puts "\n\r$-----------------------$"
		puts "|*****|*****|*****|*****|"
		puts "|**R**|**B**|**S**|**E**|"
		puts "|*****|*****|*****|*****|" 
		puts "$-----------------------$\n\r"
		@logger.info('Thanks for using RBSE! The most comprehensive CPSE :-)')
		@logger.info('Created by: Lynx')
		@logger.info('Protocol: Actionscript 2.0')
		@logger.info("LICENSE: MIT\n")
	end
	
	def loadHooks
		Dir[Dir.pwd + "/Hooks/*.rb"].each { |hook_file| require hook_file }
		Dir[Dir.pwd + "/Hooks/*.rb"].each do |hook|
			hookName = File.basename(hook, ".rb")
			hookClass =  hookName.constantize
			@hooks[hookName] = hookClass.new(self)
		end
		@hooks.each do |hookName, hookClass|
			if hookClass.enabled == false
				@hooks.delete(hookName)
			end
			if hookClass.dependencies.empty? == true
				return @logger.info("Dependencies for hook: #{hookName} is empty!")
			elsif hookClass.dependencies.count < 3
				return @logger.info("Missing dependencies in hook: #{hookName}")
			elsif hookClass.dependencies.count > 3
				return @logger.info("Too many dependencies in hook: #{hookName}")
			elsif hookClass.dependencies['author'] == '' || hookClass.dependencies['version'] == '' || hookClass.dependencies['plugin_type'] == ''
				return @logger.info("One of the dependencies is not defined for hook: #{hookName}")
			end
		end
		hooksLoaded = @hooks.count
		if hooksLoaded == 0
			@logger.info('No hooks loaded at the moment')
		else
			@logger.info("Successfully loaded #{hooksLoaded} hooks")
		end
	end
	
	def parseXML(data)
		doc = Nokogiri::XML(data)
		if (doc != nil)
			return Hash.from_xml(doc.to_s)
		end
		return false
	end
	
	def is_num?(str)
		!!Integer(str)
			rescue ArgumentError, TypeError
		false
	end
	
	def genRandString(length)
		stringTypes = [*'0'..'9', *'a'..'z', *'A'..'Z']
		randString = Array.new(length){stringTypes.sample}.join
		return randString
	end
	
	
end
\
