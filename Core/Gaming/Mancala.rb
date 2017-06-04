class Mancala

	attr_accessor :currPlayer, :winner

	INVALID_HOLLOW = -1
	MOVE_COMPLETE = 0
	WON = 1
	TIE = 2
	NO_SIDES_EMPTY = 3
	FREE_TURN = "f"
	CAPTURE = "c"

	def initialize
		@boardMap = [
			4, 4, 4, 4, 4, 4, 0,
			4, 4, 4, 4, 4, 4, 0
		]
		@currPlayer = 1
		self.reset
		@winner = 0
	end
	
	def reset
		@boardMap = [
			4, 4, 4, 4, 4, 4, 0,
			4, 4, 4, 4, 4, 4, 0
		]
		@currPlayer = 1
		@winner = 0
	end
	
	def convertToString
		return @boardMap.join(',')
	end
	
	def changePlayer
		if @currPlayer == 1
			@currPlayer = 2
		else
			@currPlayer = 1
		end
	end
	
	def validMove(hollow)
		if @currPlayer == 1 && hollow.between?(0, 5) == false || @currPlayer == 2 && hollow.between?(7, 12) == false
			return false
		end
		return true
	end
	
	def determineTie
		if @boardMap[0, 6].sum == 0 || @boardMap[7, 6].sum == 0 
			if @boardMap[0, 6].sum == @boardMap[7, 6].sum
				return TIE
			end
		end
		return NO_SIDES_EMPTY
	end
	
	def determineWin
		if @boardMap[0, 6].sum == 0 || @boardMap[7, 6].sum == 0 
			if @boardMap[0, 6].sum > @boardMap[7, 6].sum
				@winner = 1
			else
				@winner = 2
			end
			return WON
		end
		return NO_SIDES_EMPTY
	end
	
	def processBoard
		match_tie = self.determineTie
		if match_tie == TIE
			return match_tie
		end
		match_win = self.determineWin
		if match_win == WON
			return match_win
		end
		return MOVE_COMPLETE
	end
	
	def makeMove(hollow)
		if self.validMove(hollow) != false
			capture = false
			hand = @boardMap[hollow]
			@boardMap[hollow] = 0
			while hand > 0
				hollow += 1
				if @boardMap.include?(hollow) != true
					hollow = 0
				end
				myMancala = @currPlayer == 1 ? 6 : 13
				opponentMancala = @currPlayer == 1 ? 13 : 6
				if hollow == opponentMancala
					next
				end
				oppositeHollow = 12 - hollow
				if @currPlayer == 1 && hollow.between?(0, 5) == true && hand == 1 && @boardMap[hollow] == 0
					@boardMap[myMancala] = @boardMap[myMancala] + @boardMap[oppositeHollow] + 1
					@boardMap[oppositeHollow] = 0
					capture = true
					break
				end
				if @currPlayer == 2 && hollow.between?(7, 12) == true && hand == 1 && @boardMap[hollow] == 0
					@boardMap[myMancala] = @boardMap[myMancala] + @boardMap[oppositeHollow] + 1
					@boardMap[oppositeHollow] = 0
					capture = true
					break
				end
				@boardMap[hollow] += 1
				hand -= 1
			end
			gameStatus = self.processBoard
			if gameStatus == MOVE_COMPLETE
				if @currPlayer == 1 && hollow != 6 || @currPlayer == 2 && hollow != 13
					self.changePlayer
					if capture == true
						return CAPTURE
					end
				else
					return FREE_TURN
				end
			end
			return gameStatus
		else
			return INVALID_HOLLOW
		end
	end

end
