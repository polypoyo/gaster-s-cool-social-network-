---@type Server
local server = require("server")

function love.update(dt)
    local success, value = pcall(server.tick, server) -- Call the main server function once per update
    if not success then
        print(value)
        for i, client in pairs(server.clients) do
            server:removePlayer(client)
        end
        server = require("server")
    end
end

function love.draw()
    love.graphics.setColor(1, 1, 1)  -- Set color to white
    love.graphics.printf("Connected Players:\n", 10, 10, love.graphics.getWidth(), "left")
    
    local yOffset = 30
    for _, player in pairs(server.players) do
        if player.username and player.uuid and player.map and player.actor and player.x and player.y and player.direction then
            love.graphics.printf("Player: " .. player.username ..
                                 "\nUUID: " .. player.uuid ..
                                 "\nActor: " .. player.actor ..
                                 "\nSprite: " .. player.sprite ..
                                 "\nMap: " .. player.map ..
                                 "\nX: " .. player.x .. ", Y: " .. player.y ..
                                 "\nDirection: " .. player.direction, 10, yOffset, love.graphics.getWidth(), "left")
            yOffset = yOffset + 100
        end
    end
end