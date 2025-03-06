-- main.lua for LÖVE
-- Simplified Balatro-style game

local deck = {}
local hand = {}
local score = 0
local chips = 100  -- Starting currency
local gameState = "draw"  -- "draw", "play", "gameover"

-- Card values and suits
local values = {"2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"}
local suits = {"♠", "♥", "♦", "♣"}

function love.load()
    love.window.setMode(800, 600)
    love.window.setTitle("Simple Balatro")
    resetDeck()
    drawHand()
end

function resetDeck()
    deck = {}
    for _, suit in ipairs(suits) do
        for _, value in ipairs(values) do
            table.insert(deck, {value = value, suit = suit})
        end
    end
    shuffleDeck()
end

function shuffleDeck()
    for i = #deck, 2, -1 do
        local j = math.random(i)
        deck[i], deck[j] = deck[j], deck[i]
    end
end

function drawHand()
    hand = {}
    for i = 1, 5 do
        if #deck > 0 then
            table.insert(hand, table.remove(deck))
        end
    end
    gameState = "play"
end

function evaluateHand()
    local counts = {}
    local suitsCount = {}
    local valuesInOrder = {}

    -- Count values and suits
    for _, card in ipairs(hand) do
        counts[card.value] = (counts[card.value] or 0) + 1
        suitsCount[card.suit] = (suitsCount[card.suit] or 0) + 1
        table.insert(valuesInOrder, tableIndexOf(values, card.value))
    end

    table.sort(valuesInOrder)
    local isFlush = false
    for _, count in pairs(suitsCount) do
        if count == 5 then isFlush = true end
    end

    local isStraight = true
    for i = 2, 5 do
        if valuesInOrder[i] ~= valuesInOrder[i-1] + 1 then
            isStraight = false
            break
        end
    end

    local valueCounts = {}
    for _, count in pairs(counts) do
        table.insert(valueCounts, count)
    end
    table.sort(valueCounts, function(a, b) return a > b end)

    -- Poker hand evaluation
    if isFlush and isStraight then return "Straight Flush", 100
    elseif valueCounts[1] == 4 then return "Four of a Kind", 80
    elseif valueCounts[1] == 3 and valueCounts[2] == 2 then return "Full House", 60
    elseif isFlush then return "Flush", 50
    elseif isStraight then return "Straight", 40
    elseif valueCounts[1] == 3 then return "Three of a Kind", 30
    elseif valueCounts[1] == 2 and valueCounts[2] == 2 then return "Two Pair", 20
    elseif valueCounts[1] == 2 then return "Pair", 10
    else return "High Card", 5 end
end

function tableIndexOf(t, val)
    for i, v in ipairs(t) do
        if v == val then return i end
    end
    return -1
end

function love.update(dt)
    if gameState == "gameover" then return end
    if chips <= 0 then
        gameState = "gameover"
    end
end

function love.keypressed(key)
    if gameState == "play" and key == "space" then
        local handName, points = evaluateHand()
        score = score + points
        chips = chips - 10  -- Cost to play a hand
        drawHand()
    elseif gameState == "gameover" and key == "r" then
        score = 0
        chips = 100
        resetDeck()
        drawHand()
        gameState = "draw"
    end
end

function love.draw()
    love.graphics.setColor(1, 1, 1)

    -- Draw hand
    for i, card in ipairs(hand) do
        love.graphics.setColor(0.9, 0.9, 0.9)
        love.graphics.rectangle("fill", 150 + (i-1) * 110, 300, 100, 150, 10)
        love.graphics.setColor(0, 0, 0)
        local text = card.value .. card.suit
        love.graphics.print(text, 170 + (i-1) * 110, 350)
    end

    -- Draw UI
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Score: " .. score, 10, 10)
    love.graphics.print("Chips: " .. chips, 10, 30)
    if gameState == "play" then
        love.graphics.print("Press SPACE to play hand (10 chips)", 10, 50)
        local handName, points = evaluateHand()
        love.graphics.print("Current Hand: " .. handName .. " (" .. points .. " points)", 10, 70)
    end

    -- Game over
    if gameState == "gameover" then
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.printf("Game Over!\nFinal Score: " .. score .. "\nPress R to restart",
            0, 200, 800, "center")
    end
end