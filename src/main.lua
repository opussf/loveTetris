tetris = {}
tetris.width, tetris.height = 0
tetris.x = 10
tetris.y = 20
tetris.squareSize = 20
tetris.field = {}

function love.load()
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
    for y = 1, tetris.y do
        tetris.field[y][2] = { 0, 1, 1, 1 }
    end
end

function love.update( dt )
end

function love.draw()
    love.graphics.setColor( 1, 1, 1, 1 )
    love.graphics.line( tetris.fieldX,tetris.fieldY,
                        tetris.fieldX,tetris.fieldY+(tetris.squareSize*tetris.y),
                        tetris.fieldX+(tetris.squareSize*tetris.x),tetris.fieldY+(tetris.squareSize*tetris.y),
                        tetris.fieldX+(tetris.squareSize*tetris.x),tetris.fieldY )
    print( tetris.fieldX+(tetris.squareSize*tetris.x),tetris.fieldY+(tetris.squareSize*tetris.y) )
    tetris.drawField()
end

function tetris.drawField()
    for y = 1, tetris.y do
        for x = 1, tetris.x do
            if tetris.field[y][x] then
                love.graphics.setColor( tetris.field[y][x] )
                xx = tetris.fieldX+((x-1)*tetris.squareSize)
                yy = tetris.fieldY+((y-1)*tetris.squareSize)
                print( x, y, xx, yy, xx+tetris.squareSize, yy+tetris.squareSize )
                love.graphics.rectangle( "fill", xx,yy, tetris.squareSize,tetris.squareSize)
            end
        end
    end
end
