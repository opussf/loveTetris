tetris = {}
tetris.running = true
tetris.width, tetris.height = 0
tetris.x = 10
tetris.y = 20
tetris.squareSize = 20
tetris.movementVectors = {
        ["down"]  = {0,1},
        ["left"]  = {-1,0},
        ["right"] = {1,0}
}
tetris.field = {}

local sumTime = 0

require "pieces"

function love.load()
    math.randomseed( os.time() )
    tetris.width, tetris.height = love.graphics.getDimensions()
    tetris.fieldX, tetris.fieldY = tetris.width/2, tetris.height-(tetris.squareSize*(tetris.y+1))
    -- init field
    for y = 1,tetris.y do
        tetris.field[y] = {}
        for x = 1,tetris.x do
            tetris.field[y][x] = nil
        end
    end
    -- test data
    tetris.field[20][1] = { 1, 0, 0, 1 } -- red
    tetris.field[20][5] = { 0, 1, 0, 1 } -- green
    tetris.field[20][10] = { 0, 0, 1, 1 } -- blue
    tetris.field[20][2] = { 1, 1, 0, 1}
    tetris.field[20][3] = { 1, 1, 0, 1}
    tetris.field[20][4] = { 1, 1, 0, 1}

    tetris.newPiece( "tee", { 1, 0, 1, 1 } )
end

function love.update( dt )  -- delta time
    if tetris.running then 
        sumTime = sumTime + dt
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
    love.graphics.setColor( 1, 1, 1, 1 )
    love.graphics.line( tetris.fieldX,tetris.fieldY,
                        tetris.fieldX,tetris.fieldY+(tetris.squareSize*tetris.y),
                        tetris.fieldX+(tetris.squareSize*tetris.x),tetris.fieldY+(tetris.squareSize*tetris.y),
                        tetris.fieldX+(tetris.squareSize*tetris.x),tetris.fieldY )
    tetris.drawField()
    if tetris.piece then 
        tetris.drawPiece()
    end
end

function love.keypressed( key, scancode, isrepeat )
    if tetris.movementVectors[key] then
        tetris.movePiece( tetris.movementVectors[key] )
    end
    if key == "space" then
        tetris.rotatePiece()
    end
end

function tetris.drawField()
    for y = 1, tetris.y do
        for x = 1, tetris.x do
            if tetris.field[y][x] then
                love.graphics.setColor( tetris.field[y][x] )
                xx = tetris.fieldX+((x-1)*tetris.squareSize)
                yy = tetris.fieldY+((y-1)*tetris.squareSize)
                -- print( x, y, xx, yy, xx+tetris.squareSize, yy+tetris.squareSize )
                love.graphics.rectangle( "fill", xx,yy, tetris.squareSize,tetris.squareSize)
            end
        end
    end
end

function tetris.drawPiece()
    love.graphics.setColor( tetris.piece.color )
    for _, segment in pairs( tetris.piece.shape ) do
        xx = tetris.fieldX + ((tetris.piece.x+segment[1]-1)*tetris.squareSize)
        yy = tetris.fieldY + ((tetris.piece.y+segment[2]-1)*tetris.squareSize)
        love.graphics.rectangle( "fill", xx, yy, tetris.squareSize, tetris.squareSize )
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
        color = { math.random(), math.random(), math.random(), 1 }
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
    for yy = 1, tetris.y do
        lineFull = true
        for xx = 1, tetris.x do
            if not tetris.field[yy][xx] then
                lineFull = false
            end
        end
        if lineFull then
            table.remove( tetris.field, yy )  -- pop line
            table.insert( tetris.field, 1, {} ) -- add line
        end
    end
end

function tetris.gameOver()
    tetris.running = false
end