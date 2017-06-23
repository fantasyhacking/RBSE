require 'rubygems'
require 'json'

class XTParser
	
	def handleLoadPackets
		packet_file = File.read(__dir__ + '/PACKETS.json')
		packets = JSON.parse(packet_file)
		@xtPackets = packets
	end
	
	def parseData(data)
		if data.respond_to?(:to_str)
			packets = data.split('%')
			if packets.count < 3
				@parent.logger.warn('Client is trying to send a packet with very less arguments')
				return false
			end
			if @xtPackets.has_key?(packets[1]) != true
				@parent.logger.warn('Client is trying to send an invalid packet')
				return false
			end
			if @xtPackets[packets[1]][0].include?(packets[2]) != true
				@parent.logger.warn('Client is trying to send invalid packet type')
				return false
			end
			gamePacket = packets[3]
			existsDelimeter = @xtPackets[packets[1]][0][packets[2]][0]['delimeter']
			if gamePacket !~ /#{existsDelimeter}/
				@parent.logger.warn('Client is trying to use an invalid delimeter')
				return false
			end
			if @xtPackets[packets[1]][0][packets[2]][0].include?(gamePacket) != true
				@parent.logger.warn('Client is trying to send an invalid game packet')
				return false
			end
			packets.each do |packet|
				if packet.include?('|') && @xtPackets[packets[1]][0][packets[2]][0][gamePacket][0]['hasException'] != true
					@parent.logger.warn('Client is trying to send a malformed packet')
					return false
				end
			end
			realArgs = packets.drop(5)
			if realArgs.empty? != true && realArgs.count < @xtPackets[packets[1]][0][packets[2]][0][gamePacket][0]['length'].to_i
				@parent.logger.warn('Client is sending invalid amount of Arguments')
				return false
			end
			if @xtPackets[packets[1]][0][packets[2]][0][gamePacket][0]['length'].to_i < 0	
				if gamePacket == 'st#ssbcd' || gamePacket == 'g#ur' || gamePacket == 'm#sm' #because stampbook cover is a pain
					handlingInfo = ['handler' => @xtPackets[packets[1]][0][packets[2]][0][gamePacket][0]['method'], 'arguments' => realArgs]
					return handlingInfo
				end
				handlingInfo = ['handler' => @xtPackets[packets[1]][0][packets[2]][0][gamePacket][0]['method'], 'arguments' => realArgs]
				return handlingInfo
			elsif @xtPackets[packets[1]][0][packets[2]][0][gamePacket][0]['length'].to_i >= 0
				packLength = @xtPackets[packets[1]][0][packets[2]][0][gamePacket][0]['length'].to_i
				newArgs = Array.new
				(0..packLength).each do |pack_index|
					type = @xtPackets[packets[1]][0][packets[2]][0][gamePacket][0]['type'][pack_index]
					item = realArgs[pack_index]
					item_type = ''
					if @parent.is_num?(item) == true
						item_type = 'Fixnum'
						item = item.to_i
					else
						item_type = 'String'
						item = item.to_s
					end
					if item_type != type
						@parent.logger.warn('Client is sending invalid Arguments')
						return false
					end
					newArgs.push(item)
				end
				handlingInfo = ['handler' => @xtPackets[packets[1]][0][packets[2]][0][gamePacket][0]['method'], 'arguments' => newArgs]
				return handlingInfo
			end
		end
	end
	
end
