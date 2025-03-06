-- Save this as main.lua in a folder, then drag the folder onto love.exe to run
-- or run from terminal with: love path/to/folder

-- Game variables
local snake = {}
local food = {}
local direction = 'right'
local timer = 0
local moveDelay = 0.2
local gridSize = 20
local screenWidth = 800
local screenHeight = 600
local gameOver = false

function love.load()
    love.window.setMode(screenWidth, screenHeight)
    love.window.setTitle("Snake Game")

    -- Initialize snake
    table.insert(snake, {x = 400, y = 300})  -- Start in middle

    -- Spawn first food
    spawnFood()
end

function spawnFood()
    food.x = math.random(0, screenWidth / gridSize - 1) * gridSize
    food.y = math.random(0, screenHeight / gridSize - 1) * gridSize
end

function love.update(dt)
    if gameOver then return end

    timer = timer + dt

    -- Move snake
    if timer >= moveDelay then
        timer = 0

        -- Calculate new head position
        local head = {x = snake[1].x, y = snake[1].y}
        if direction == 'right' then head.x = head.x + gridSize
        elseif direction == 'left' then head.x = head.x - gridSize
        elseif direction == 'up' then head.y = head.y - gridSize
        elseif direction == 'down' then head.y = head.y + gridSize end

        -- Check boundaries
        if head.x < 0 or head.x >= screenWidth or
           head.y < 0 or head.y >= screenHeight then
            gameOver = true
            return
        end

        -- Check self collision
        for i, segment in ipairs(snake) do
            if segment.x == head.x and segment.y == head.y then
                gameOver = true
                return
            end
        end

        -- Insert new head
        table.insert(snake, 1, head)

        -- Check food collision
        if head.x == food.x and head.y == food.y then
            spawnFood()
            moveDelay = math.max(0.05, moveDelay - 0.01)  -- Increase speed
        else
            table.remove(snake)  -- Remove tail if no food eaten
        end
    end
end

function love.keypressed(key)
    if key == 'right' and direction ~= 'left' then
        direction = 'right'
    elseif key == 'left' and direction ~= 'right' then
        direction = 'left'
    elseif key == 'up' and direction ~= 'down' then
        direction = 'up'
    elseif key == 'down' and direction ~= 'up' then
        direction = 'down'
    elseif key == 'r' and gameOver then
        -- Restart game
        snake = {{x = 400, y = 300}}
        direction = 'right'
        timer = 0
        moveDelay = 0.2
        gameOver = false
        spawnFood()
    end
end

function love.draw()
    -- Draw snake
    love.graphics.setColor(0, 1, 0)  -- Green
    for i, segment in ipairs(snake) do
        love.graphics.rectangle('fill', segment.x, segment.y, gridSize - 2, gridSize - 2)
    end

    -- Draw food
    love.graphics.setColor(1, 0, 0)  -- Red
    love.graphics.rectangle('fill', food.x, food.y, gridSize - 2, gridSize - 2)

    -- Draw score
    love.graphics.setColor(1, 1, 1)  -- White
    love.graphics.print("Score: " .. #snake - 1, 10, 10)

    -- Draw game over
    if gameOver then
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.printf("Game Over!\nScore: " .. #snake - 1 .. "\nPress R to restart",
            0, screenHeight/2 - 30, screenWidth, 'center')
    end
end