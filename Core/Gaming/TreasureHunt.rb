class TreasureHunt

	attr_accessor :coinAmount, :gemAmount, :gemLocations
	
	GAME_ID = -1
    USER_ONE =  0
    USER_TWO =  1
    MAP_WIDTH = 2
    MAP_HEIGHT =  3
    COIN_AMOUNT = 4
    GEM_AMOUNT = 5
    TURN_AMOUNT = 6
    GEM_VALUE = 7
    COIN_VALUE = 8
    GEM_LOCATIONS = 9
    TREASURE_MAP = 10
    GEMS_FOUND = 11
    COINS_FOUND = 12
    RARE_GEM_FOUND = 13
    RECORD_NAMES = 14
    RECORD_DIRECTIONS = 15
    RECORD_NUMBERS = 16
    TURN_OFFSET = 17
    
    NONE = 0
    COIN = 1
    GEM = 2
    GEM_PIECE = 3
    RARE_GEM = 4
    
    def initialize
		@currentTurnOffset = TURN_OFFSET
		@boardMap = [
				[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
				[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
				[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
				[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
				[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
				[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
				[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
				[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
				[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
				[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
				[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
		]
		@coinAmount = 0
		@gemAmount = 0
		@gemLocations = ''
		self.generateTreasuresToMap
    end
    
    def generateTreasuresToMap
		(0..10).each do |xpos|
			(0..10).each do |ypos|
				if @boardMap[xpos][ypos] == GEM_PIECE
					next
				end
				if rand(0..26) == 13 && xpos < 9 && ypos < 9
				    @gemAmount += 1
				    @gemLocations << "#{xpos},#{ypos},"
					@boardMap[xpos][ypos] = rand(0..10) == 1 ? RARE_GEM : GEM
					@boardMap[xpos][ypos + 1] = @boardMap[xpos + 1][ypos] = @boardMap[xpos + 1][ypos + 1] = GEM_PIECE
				elsif rand(0..2) == 1 
					@coinAmount += 1
					@boardMap[xpos][ypos] = COIN
				else
					@boardMap[xpos][ypos] = NONE
				end
			end
		end
    end
    
    def convertToString
		return @boardMap.map {|tableIndex, tableValue| @boardMap[tableIndex].join(',')}.join(',')
    end

end
