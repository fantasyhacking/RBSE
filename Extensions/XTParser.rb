class XTParser

	XTPACKETS = Hash[
		'xt' => [
			's' => [
				'delimeter' => '#',
				'j#js' => [
					'method' => 'handleJoinServer', 
					'args' => ['id', 'loginkey', 'lang'], 
					'type' => ['Fixnum', 'String', 'String'], 
					'length' => 2, 
					'hasException' => false
				],
				'j#jp' => [
					'method' => 'handleJoinPlayer', 
					'args' => ['room_id'], 
					'type' => ['Fixnum'], 
					'length' => 1, 
					'hasException' => false
				],
				'j#jg' => [
					'method' => 'handleJoinGame', 
					'args' => ['room_id'], 
					'type' => ['Fixnum'], 
					'length' => 0, 
					'hasException' => false
				],
				'j#grs' => [
					'method' => 'handleGetRoomSynced', 
					'args' => [], 
					'type' => [],
					'length' => 0, 
					'hasException' => false
				],
				'j#jr' => [
					'method' => 'handleJoinRoom', 
					'args' => ['room_id', 'x', 'y'], 
					'type' => ['Fixnum', 'Fixnum', 'Fixnum'], 
					'length' => 2, 
					'hasException' => false
				],
				'i#gi' => [
					'method' => 'handleGetInventory', 
					'args' => [], 
					'type' => [],
					'length' => 0, 
					'hasException' => false
				],
				'f#epfgf' => [
					'method' => 'handleEPFGetField', 
					'args' => [], 
					'type' => [], 
					'length' => 0, 
					'hasException' => false
				],
				'g#ur' => [
					'method' => 'handleGetFurnitureRevision', 
					'args' => [], 
					'type' => [], 
					'length' => 0, 
					'hasException' => true
				],
				'm#sm' => [
					'method' => 'handleSendMessage', 
					'args' => ['message'], 
					'type' => ['String'], 
					'length' => 1, 
					'hasException' => true
				],
				'st#ssbcd' => [
					'method' => 'handleSetStampBookCoverDetails', 
					'args' => [],
					'type' => [], 
					'length' => 4, 
					'hasException' => true
				],
				'b#gb' => [
					'method' => 'handleGetBuddies',
					'args' => [],
					'type' => [],
					'length' => 0,
					'hasException' => false
				],
				'n#gn' => [
					'method' => 'handleGetIgnored',
					'args' => [],
					'type' => [],
					'length' => 0,
					'hasException' => false
				],
				'l#mst' => [
					'method' => 'handleMailStart',
					'args' => [],
					'type' => [],
					'length' => 0,
					'hasException' => false
				],
				'l#mg' => [
					'method' => 'handleMailGet',
					'args' => [],
					'type' => [],
					'length' => 0,
					'hasException' => false
				],
				'p#pgu' => [
					'method' => 'handlePuffleGetUser',
					'args' => [],
					'type' => [],
					'length' => 0,
					'hasException' => false
				],
				'u#glr' => [
					'method' => 'handleGetLatestRevision',
					'args' => [],
					'type' => [],
					'length' => 0,
					'hasException' => false
				],
				'f#efpga' => [
					'method' => 'handleEPFGetAgent',
					'args' => [],
					'type' => [],
					'length' => 0,
					'hasException' => false
				],
				'f#efpgr' => [
					'method' => 'handleEPFGetRevision',
					'args' => [],
					'type' => [],
					'length' => 0,
					'hasException' => false
				],
				'u#h' => [
					'method' => 'handleUserHeartbeat',
					'args' => [],
					'type' => [],
					'length' => 0,
					'hasException' => false
				]
			],
			'z' => [
				'jw' => [
					'method' => [
						'handleJoinWaddle', 
						'args' => ['waddle_id'], 
						'type' => ['Fixnum'], 
						'length' => 1, 
						'hasException' => false
					]
				]
			]
		]
	]
	
	def parseData(data) #add a check to see if 
		if data.respond_to?(:to_str)
			packets = data.split('%')
			if XTPACKETS.has_key?(packets[1]) != true
				@parent.logger.warn('Client is trying to send an invalid packet')
				return false
			end
			if XTPACKETS[packets[1]][0].include?(packets[2]) != true
				@parent.logger.warn('Client is trying to send invalid packet type')
				return false
			end
			gamePacket = packets[3]
			existsDelimeter = XTPACKETS[packets[1]][0][packets[2]][0]['delimeter']
			if gamePacket !~ /#{existsDelimeter}/
				@parent.logger.warn('Client is trying to use an invalid delimeter')
				return false
			end
			if XTPACKETS[packets[1]][0][packets[2]][0].include?(gamePacket) != true
				@parent.logger.warn('Client is trying to send an invalid game packet')
				return false
			end
			packets.each do |packet|
				if packet.include?('|') && XTPACKETS[packets[1]][0][packets[2]][0][gamePacket][0]['hasException'] != true
					@parent.logger.warn('Client is trying to send a malformed packet')
					return false
				end
			end
			realArgs = packets.drop(5)
			if realArgs.length < (XTPACKETS[packets[1]][0][packets[2]][0][gamePacket][0]['length'] - 1)
				@parent.logger.warn('Client is sending invalid amount of Arguments')
				return false
			end
			if XTPACKETS[packets[1]][0][packets[2]][0][gamePacket][0]['length'] <= 0
				handlingInfo = ['handler' => XTPACKETS[packets[1]][0][packets[2]][0][gamePacket][0]['method'], 'arguments' => realArgs]
				return handlingInfo
			elsif XTPACKETS[packets[1]][0][packets[2]][0][gamePacket][0]['length'] >= 1
				packLength = XTPACKETS[packets[1]][0][packets[2]][0][gamePacket][0]['length']
				newArgs = Array.new
				(0..packLength).each do |pack_index|
					name = XTPACKETS[packets[1]][0][packets[2]][0][gamePacket][0]['args'][pack_index]
					type = XTPACKETS[packets[1]][0][packets[2]][0][gamePacket][0]['type'][pack_index]
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
				handlingInfo = ['handler' => XTPACKETS[packets[1]][0][packets[2]][0][gamePacket][0]['method'], 'arguments' => newArgs]
				return handlingInfo
			end
		end
	end
	
end
