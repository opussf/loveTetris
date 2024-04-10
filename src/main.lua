tetris = {}
tetris.isRunning = true
tetris.width, tetris.height = 0
tetris.x = 10
tetris.y = 20
tetris.squareSize = 30
tetris.movementVectors = {
		["down"]  = {0,1},
		["left"]  = {-1,0},
		["right"] = {1,0}
}
tetris.field = {}
tetris.score = 0
tetris.gameTimer = 0
tetris.highScores = {}
tetris.highScoreFile = "highscore"
tetris.maxHighScores = 10
tetris.maxScoreSize = 0
tetris.scoreByLinesCleared = { 40, 100, 300, 1200 }  -- https://tetris.wiki/Scoring (Original BPS)
tetris.gameoverbanner = require "gameoverbanner"
require "pieces"

local sumTime = 0

function love.load()
	math.randomseed( os.time() )
	tetris.width, tetris.height = love.graphics.getDimensions()
	tetris.fieldX, tetris.fieldY = (tetris.width/2.25), tetris.height-(tetris.squareSize*(tetris.y+1))

	tetris.background = love.graphics.newCanvas( tetris.width, tetris.height )
	love.graphics.setCanvas( tetris.background  )
		love.graphics.clear( 0, 0, 0, 0 )
		love.graphics.setBlendMode( "alpha" )
		tetris.backgroundImg = love.graphics.newImage( "IMG_7608.jpg" )
		love.graphics.draw( tetris.backgroundImg, 0, 0 )
	love.graphics.setCanvas()

	tetris.loadHighscore()
	tetris.initField()
	tetris.newPiece()
	tetris.font = love.graphics.getFont()
end
function tetris.loadHighscore()
	fileInfo = love.filesystem.getInfo( tetris.highScoreFile )
	if fileInfo then
		for line in love.filesystem.lines( tetris.highScoreFile ) do
			_, _, hs, t =string.find( line, "^(%d+) *(%d*)$")
			table.insert( tetris.highScores, { tonumber(hs), tonumber(t)} )
			tetris.maxScoreSize = math.max( tetris.maxScoreSize, math.ceil( math.log10(hs) ) )
		end
		table.sort( tetris.highScores, function(a,b) return a[1]>b[1] end )
	end
	if #tetris.highScores == 0 then tetris.highScores = {{0,0}} end
	while #tetris.highScores > tetris.maxHighScores do
		table.remove( tetris.highScores )
	end
end
function love.update( dt )  -- delta time
	if tetris.isRunning and love.window.hasFocus() then
		sumTime = sumTime + dt
		tetris.gameTimer = tetris.gameTimer + dt
		if sumTime >= 0.5 then
			sumTime = 0
			if tetris.piece then
				moved = tetris.movePiece( tetris.movementVectors.down )
				if not moved then  -- this is grounded
					tetris.pieceToField()
					tetris.updateField()
				end
			else
				tetris.newPiece()
			end
		end
	end
end
function love.draw()
	-- love.graphics.setBlendMode( "alpha", "premultiplied" )
	love.graphics.setColor( 1, 1, 1, 1 )
	love.graphics.draw( tetris.background, 0,0 )
	love.graphics.setColor( 0, 0, 0, 1 )
	love.graphics.rectangle( "fill", tetris.fieldX,tetris.fieldY, tetris.squareSize*tetris.x,tetris.squareSize*tetris.y )
	tetris.drawField()
	tetris.drawScore()
	tetris.drawTime()
	if tetris.piece then
		tetris.drawPiece()
	end
	if not tetris.isRunning then
		tetris.drawGameOver()
	end
end
function love.keypressed( key, scancode, isrepeat )
	if tetris.movementVectors[key] then
		tetris.movePiece( tetris.movementVectors[key] )
	end
	if key == "up" and tetris.isRunning and tetris.piece then
		while( tetris.movePiece( tetris.movementVectors.down ) ) do
		end
	end
	if key == "space" then
		if tetris.isRunning then
			tetris.rotatePiece()
		else
			tetris.initField()
			tetris.gameTimer = 0
			tetris.score = 0
			tetris.piece = nil
			tetris.isRunning = true
		end
	end
end
function tetris.initField()
	-- init field
	for y = 1,tetris.y do
		tetris.field[y] = {}
		for x = 1,tetris.x do
			tetris.field[y][x] = nil
		end
	end
end
function tetris.drawField()
	for y = 1, tetris.y do
		for x = 1, tetris.x do
			if tetris.field[y][x] then
				love.graphics.setColor( tetris.field[y][x] )
				xx = tetris.fieldX+((x-1)*tetris.squareSize)
				yy = tetris.fieldY+((y-1)*tetris.squareSize)
				love.graphics.rectangle( "fill", xx,yy, tetris.squareSize,tetris.squareSize)
				love.graphics.setColor( 1, 1, 1, 1 )
				love.graphics.rectangle( "line", xx,yy, tetris.squareSize,tetris.squareSize)
			end
		end
	end
end
function tetris.timeFromSec( secIn )
	return ( secIn and string.format( "%02i:%02i.%02i", math.floor( secIn / 3600 ), math.floor( secIn / 60 ) % 60, math.floor( secIn % 60 ) ) or "" )
end
function tetris.drawScore()
	local scoreText = string.format( "Score: %i", tetris.score )

	scoreWidth = tetris.font:getWidth( scoreText )
	scoreHeight = tetris.font:getHeight()
	love.graphics.setColor( {0, 0, 0, 1} )
	love.graphics.rectangle( "fill", tetris.fieldX, tetris.fieldY-(scoreHeight*3), scoreWidth*2,scoreHeight*2 )
	love.graphics.setColor( {1, 1, 1, 1} )
	love.graphics.print( scoreText, tetris.fieldX,tetris.fieldY-(scoreHeight*3), 0, 2,2 )

	local highScoreText = "HighScores:\n" --..table.concat( tetris.highScores, "\n" )
	local scoreFormat = string.format( "%%0%id\t%%s", tetris.maxScoreSize )
	for i, hs in ipairs( tetris.highScores ) do
		highScoreText = highScoreText..string.format( scoreFormat, hs[1], tetris.timeFromSec( hs[2] ) )..(i < #tetris.highScores and "\n" or "")
	end
	highWidth = tetris.font:getWidth( highScoreText )
	highHeight = tetris.font:getHeight( highScoreText )
	love.graphics.setColor( {0, 0, 0, 1} )
	love.graphics.rectangle( "fill", tetris.fieldX+(tetris.squareSize*(tetris.x+1)), tetris.fieldY, highWidth*2,(highHeight*(tetris.maxHighScores*2+2) ) )
	love.graphics.setColor( {1, 1, 1, 1} )
	love.graphics.print( highScoreText, tetris.fieldX+(tetris.squareSize*(tetris.x+1)), tetris.fieldY, 0, 2,2 )
end

function tetris.drawTime()
	local timeText = tetris.timeFromSec( tetris.gameTimer )

	timeWidth = tetris.font:getWidth( timeText )
	timeHeight = tetris.font:getHeight()
	timeX = tetris.fieldX+(tetris.squareSize*tetris.x)-(timeWidth*2)

	love.graphics.setColor( {0, 0, 0, 1} )
	love.graphics.rectangle( "fill", timeX,tetris.fieldY-(timeHeight*3), timeWidth*2,timeHeight*2)
	love.graphics.setColor( {1, 1, 1, 1} )
	love.graphics.print( timeText, timeX,tetris.fieldY-(timeHeight*3), 0, 2,2 )
end
function tetris.drawPiece()
	-- love.graphics.setColor( tetris.piece.color )
	for _, segment in pairs( tetris.piece.shape ) do
		xx = tetris.fieldX + ((tetris.piece.x+segment[1]-1)*tetris.squareSize)
		yy = tetris.fieldY + ((tetris.piece.y+segment[2]-1)*tetris.squareSize)
		love.graphics.setColor( tetris.piece.color )
		love.graphics.rectangle( "fill", xx, yy, tetris.squareSize, tetris.squareSize )
		love.graphics.setColor( 1, 1, 1, 1 )
		love.graphics.rectangle( "line", xx, yy, tetris.squareSize, tetris.squareSize )
	end
end
function tetris.movePiece( vector )
	if not tetris.piece then
		return
	end
	-- test movement in field
	for _, segment in pairs( tetris.piece.shape ) do
		-- convert to field coords
		xx = tetris.piece.x + vector[1] + segment[1]
		yy = tetris.piece.y + vector[2] + segment[2]

		-- test against field limits
		if ( xx > tetris.x or xx < 1 or yy > tetris.y ) then  -- not moving up, so no need to test that
			return
		end
		-- test field collisions
		if tetris.field[yy][xx] then
			return
		end
	end
	-- if ( tetris.piece.x + vector[1] >=
	tetris.piece.x = tetris.piece.x + vector[1]
	tetris.piece.y = tetris.piece.y + vector[2]
	return true
end
function tetris.rotatePiece()
	-- rotate 90 degrees clockwise
	-- use x(real), y(img) complex numbers and multiply by -i
	if not tetris.piece then
		return
	end
	newShape = {}
	for _, segment in ipairs( tetris.piece.shape ) do
		yy = segment[1]*1
		xx = segment[2]*-1
		-- convert xx, yy to field coords for testing
		fx = tetris.piece.x + xx
		fy = tetris.piece.y + yy
		-- test against field limits
		if ( fx > tetris.x or fx < 1 or fy > tetris.y or fy < 1 ) then
			return
		end
		-- test a collision
		if tetris.field[fy][fx] then
			return
		end
		table.insert( newShape, {xx,yy} )
	end
	tetris.piece.shape = newShape
end
function tetris.pieceToField()
	for _, segment in pairs( tetris.piece.shape ) do
		xx = tetris.piece.x + segment[1]
		yy = tetris.piece.y + segment[2]
		tetris.field[yy][xx] = tetris.piece.color
	end
	tetris.piece = nil
end
function tetris.newPiece( name, color )
	if not name then
		a = {}
		for k,_ in pairs( tetris.pieces ) do
			table.insert( a, k )
		end
		name = a[math.random( #a )]
	end
	if not color then
		z = 0.08
		color = { math.random()+z, math.random()+z, math.random()+z, 1 }  -- colors over 1 get rounded down to 1
	end

	tetris.piece = {}
	tetris.piece.shape = tetris.pieces[name]
	tetris.piece.color = color
	tetris.piece.x = 5
	tetris.piece.y = 1

	for _, segment in pairs( tetris.piece.shape ) do
		xx = tetris.piece.x + segment[1]
		yy = tetris.piece.y + segment[2]
		if tetris.field[yy][xx] then
			tetris.gameOver()
		end
	end
end
function tetris.updateField()
	linesFull = 0
	for yy = 1, tetris.y do
		lineFull = true
		for xx = 1, tetris.x do
			if not tetris.field[yy][xx] then
				lineFull = false
			end
		end
		if lineFull then
			linesFull = linesFull + 1
			--print( linesFull.." cleared line '"..yy.."' or "..tetris.y-yy )
			table.remove( tetris.field, yy )  -- pop line
			table.insert( tetris.field, 1, {} ) -- add line
		end
	end
	if linesFull > 0 then
		tetris.score = tetris.score + tetris.scoreByLinesCleared[ linesFull ]
		-- tetris.highScore = math.max( tetris.score, tetris.highScore )
	end
end
function tetris.updateHighScores()
	if ( #tetris.highScores < tetris.maxHighScores and tetris.score > 0 ) or tetris.score > tetris.highScores[#tetris.highScores][1] then
		table.insert( tetris.highScores, {tetris.score, tetris.gameTimer} )
		table.sort( tetris.highScores, function(a,b) return a[1]>b[1] end )
	end
	for k,v in ipairs( tetris.highScores ) do   -- prune duplicates - seems to happen because of updates
		tetris.maxScoreSize = math.max( tetris.maxScoreSize, math.ceil( math.log10(v[1]) ) )
		if k>1 and v[1] == tetris.highScores[k-1][1] then
			table.remove( tetris.highScores, k )
		end
	end
	if #tetris.highScores > tetris.maxHighScores then
		table.remove( tetris.highScores )
	end
end
function tetris.gameOver()
	tetris.isRunning = false
	tetris.updateHighScores()
	tetris.drawScore()
end
function tetris.drawGameOver()
	-- @TODO: Set the square size as a variable, precalc the offsets
	squareSize = 10
	offsetX = tetris.fieldX - (gameoverbanner.width + 5) * squareSize
	offsetY = tetris.fieldY
	for _, segment in ipairs( tetris.gameoverbanner ) do
		love.graphics.setColor( 1, 0, 0, 1 )
		love.graphics.rectangle( "fill", (segment[1]*squareSize)+offsetX,(segment[2]*squareSize)+offsetY, squareSize,squareSize )
		love.graphics.setColor( 0, 0, 0, 1 )
		love.graphics.rectangle( "line", (segment[1]*squareSize)+offsetX,(segment[2]*squareSize)+offsetY, squareSize,squareSize )
	end
end
function love.quit()
	tetris.updateHighScores()
	hs = love.filesystem.newFile( tetris.highScoreFile )
	hs:open('w')
	for i = 1, math.min( tetris.maxHighScores, #tetris.highScores ) do
		hs:write( tetris.highScores[i][1].." "..math.floor( tetris.highScores[i][2] or 0 ).."\n" )
	end
	hs:close()
end
