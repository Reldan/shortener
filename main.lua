-- main.lua for LÖVE
-- Lunar Lander Game

local lander = {
    x = 400,           -- Center of screen
    y = 100,           -- Near top
    velocityY = 0,     -- Vertical speed
    fuel = 100,        -- Fuel for thrusting
    width = 20,
    height = 20
}
local gravity = 0.1    -- Lunar gravity
local thrust = -0.3    -- Thrust power (negative to counter gravity)
local groundY = 550    -- Landing surface height
local gameState = "playing"  -- "playing", "landed", "crashed"
local score = 0        -- Based on remaining fuel

function love.load()
    love.window.setMode(800, 600)
    love.window.setTitle("Lunar Lander")
end

function love.update(dt)
    if gameState ~= "playing" then return end

    -- Apply gravity
    lander.velocityY = lander.velocityY + gravity

    -- Apply thrust if space pressed and fuel remains
    if love.keyboard.isDown("space") and lander.fuel > 0 then
        lander.velocityY = lander.velocityY + thrust
        lander.fuel = lander.fuel - 1
    end

    -- Update position
    lander.y = lander.y + lander.velocityY

    -- Check landing or crash
    if lander.y + lander.height/2 >= groundY then
        if lander.velocityY > 2 then
            gameState = "crashed"
        else
            gameState = "landed"
            score = math.floor(lander.fuel)  -- Score is remaining fuel
        end
        lander.y = groundY - lander.height/2  -- Stick to ground
        lander.velocityY = 0
    end
end

function love.keypressed(key)
    if gameState ~= "playing" and key == "r" then
        -- Restart game
        lander.x = 400
        lander.y = 100
        lander.velocityY = 0
        lander.fuel = 100
        gameState = "playing"
        score = 0
    end
end

function love.draw()
    -- Draw starry background
    love.graphics.setColor(1, 1, 1)
    for i = 1, 50 do
        love.graphics.points(math.random(800), math.random(600))
    end

    -- Draw ground
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.rectangle("fill", 0, groundY, 800, 600 - groundY)

    -- Draw landing pad
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.rectangle("fill", 350, groundY, 100, 10)

    -- Draw lander
    love.graphics.setColor(0, 1, 0)
    love.graphics.rectangle("fill", lander.x - lander.width/2,
                          lander.y - lander.height/2,
                          lander.width, lander.height)

    -- Draw thrust flame if active
    if love.keyboard.isDown("space") and lander.fuel > 0 then
        love.graphics.setColor(1, 0.5, 0)
        love.graphics.polygon("fill",
            lander.x, lander.y + lander.height/2,
            lander.x - 5, lander.y + lander.height/2 + 10,
            lander.x + 5, lander.y + lander.height/2 + 10)
    end

    -- Draw HUD
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Fuel: " .. math.floor(lander.fuel), 10, 10)
    love.graphics.print("Velocity: " .. string.format("%.1f", lander.velocityY), 10, 30)
    love.graphics.print("Altitude: " .. math.floor(groundY - lander.y - lander.height/2), 10, 50)

    -- Game state messages
    if gameState == "landed" then
        love.graphics.printf("Landed Successfully!\nScore: " .. score .. "\nPress R to restart",
            0, 200, 800, "center")
    elseif gameState == "crashed" then
        love.graphics.printf("Crashed!\nPress R to restart",
            0, 200, 800, "center")
    end
end