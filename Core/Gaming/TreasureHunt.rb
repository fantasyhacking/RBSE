class TreasureHunt

    attr_accessor :boardMap, :currPlayer, :turnAmount, :gemValue, :rareGemValue, :coinValue, :mapWidth, :mapHeight, :coinAmount, :gemAmount, :gemLocations, :gemsFound, :coinsFound, :rareGemFound, :recordNumbers
    
    NONE = 0
    COIN = 1
    GEM = 2
    GEM_PIECE = 3
    RARE_GEM = 4
    
    def initialize		
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
		
		@currPlayer = 1
		@turnAmount = 12
		@gemValue = 25
		@rareGemValue = 100
		@coinValue = 1
		@mapWidth = 10
		@mapHeight = 10
		@coinAmount = 0
		@gemAmount = 0
		@gemLocations = ''
		@gemsFound = 0
		@coinsFound = 0
		@rareGemFound = 'false'
		@recordNumbers = ''		
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
    
    def changePlayer
		if @currPlayer == 1
			@currPlayer = 2
		else
			@currPlayer = 1
		end
    end
    
    def makeMove(buttonMC, digDirection, buttonNum)		
		@turnAmount -= 1
	
		if @recordNumbers != ''
			@recordNumbers << ','
		end
		
		rcnumbers = buttonNum.to_s	
			
		@recordNumbers << rcnumbers
		
		map = self.convertToString
		xpos = @recordNumbers[-1].to_i
		ypos = buttonNum.to_i
		pos = xpos * 10 + ypos
		some_pos = map[pos]
		
		if some_pos == GEM || some_pos == GEM_PIECE
			 @gemsFound += 0.25
		elsif some_pos == RARE_GEM
			@rareGemFound = 'true'
		elsif some_pos == COIN
			@coinsFound += @coinValue
		end
		
		self.changePlayer
		
		if @turnAmount == 0
			totalAmount = @coinsFound + (@gemsFound.round * @gemValue)
			if @rareGemFound == 'true'
				totalAmount += @rareGemValue
			end
			return ['we_done_bruh', totalAmount]
		else
			return ['not_done_bruh']
		end		
    end

end
