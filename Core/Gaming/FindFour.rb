class FindFour

	attr_accessor :currPlayer, :gameOver

	INVALID_CHIP_PLACEMENT = -1
	CHIP_PLACED = 0
	FOUND_FOUR = 1
	TIE = 2
	FOUR_NOT_FOUND = 3
	
	def initialize	
		@boardMap = [
			[0, 0, 0, 0, 0, 0, 0],
			[0, 0, 0, 0, 0, 0, 0],
			[0, 0, 0, 0, 0, 0, 0],
			[0, 0, 0, 0, 0, 0, 0],
			[0, 0, 0, 0, 0, 0, 0],
			[0, 0, 0, 0, 0, 0, 0]
		]
		@currPlayer = 1
		self.reset
	end
	
	def reset
		@boardMap = [
			[0, 0, 0, 0, 0, 0, 0],
			[0, 0, 0, 0, 0, 0, 0],
			[0, 0, 0, 0, 0, 0, 0],
			[0, 0, 0, 0, 0, 0, 0],
			[0, 0, 0, 0, 0, 0, 0],
			[0, 0, 0, 0, 0, 0, 0]
		]
		@currPlayer = 1
		@gameOver = false
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
	
	def chipPlacement(column, row)
		if @boardMap[row][column] == 0
			@boardMap[row][column] = @currPlayer
			return true
		end
		return false
	end
	
	def isBoardFull
		@boardMap.each_with_index do |row, rowIndex|
			if row.include?(0) != false
				return false
			end
		end
		return true
	end
	
	def determineColumnWin(column)
		column_counter = 0
		for row in 0...@boardMap.length
			if @boardMap[row][column] === @currPlayer
				column_counter += 1
				if column_counter === 4
					return FOUND_FOUR
				end
			end
		end
		return FOUR_NOT_FOUND
	end
	
	def determineVerticalWin
		for column in 0...@boardMap.length
			foundFour = self.determineColumnWin(column)
			if foundFour == FOUND_FOUR
				return FOUND_FOUR
			end
		end
		return FOUR_NOT_FOUND
	end
	
	def determineHorizontalWin
		for row_index in 0...@boardMap.length
			row = @boardMap[row_index]
			row_counter = 0
			for column in 0...row.length
				if row[column] === @currPlayer
					row_counter += 1
					if row_counter === 4
						return FOUND_FOUR
					end
				else
					row_counter = 0
				end
			end
		end
		return FOUR_NOT_FOUND
	end
	
	def determineDiagonalWin
		for diagonal_sum in 0..11
			diagonal_counter = 0
			for x in 0..diagonal_sum
				y = diagonal_sum - x
				if (defined?(@boardMap[x][y])).nil?
					next
				end
				if @boardMap[x][y] === @currPlayer
					diagonal_counter += 1
					if diagonal_counter == 4
						return FOUND_FOUR
					end
				else
					diagonal_counter = 0
				end
			end
		end
		for diagonal_diff in (6).downto(-5)
			y = 0
			other_diagonal_counter = 0
			for x in 0...7
				y = diagonal_diff + x
				if (defined?(@boardMap[x][y])).nil?
					next
				end
				if y < 7
					if @boardMap[x][y] === @currPlayer
						other_diagonal_counter += 1
						if other_diagonal_counter == 4
							return FOUND_FOUR
						end
					else
						other_diagonal_counter = 0
					end
				else
					break
				end
			end
		end
		return FOUR_NOT_FOUND
	end

	def processBoard
		fullBoard = self.isBoardFull
		if fullBoard == true
			return TIE
		end
		horizontalWin = self.determineHorizontalWin
		if horizontalWin == FOUND_FOUR
			return horizontalWin
		end
		verticalWin = self.determineVerticalWin
		if verticalWin == FOUND_FOUR
			return verticalWin
		end
		diagonalWin = self.determineDiagonalWin
		if diagonalWin == FOUND_FOUR
			return diagonalWin
		end
		return CHIP_PLACED
	end
	
	def placeChip(column, row)
		if self.chipPlacement(column, row) != false		
			gameStatus = self.processBoard
			if gameStatus == CHIP_PLACED
				self.changePlayer
			end
			return gameStatus
		else
			return INVALID_CHIP_PLACEMENT
		end
	end

end
