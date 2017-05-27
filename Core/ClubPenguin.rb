require 'rubygems'
require 'log4r'
require 'time'
require 'nokogiri'

class ClubPenguin

	attr_accessor :logger, :crumbs, :server_config, :mysql, :sock, :login_sys, :game_sys, :crypto

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
	end
	
	def startEmulator
		self.displayASCII
		@crumbs.loadCrumbs
		@mysql.connectMySQL(@server_config['database_user'], @server_config['database_pass'], @server_config['database_host'], @server_config['database_name'])
		@sock.connectServer
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
