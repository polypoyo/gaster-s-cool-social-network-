Socket = require("socket")
JSON = require("json")
---@type Server
local Server = require("server")

---@type Server
local server = setmetatable({},{__index = Server})
server:start()

function love.update(dt)
    local success, value = xpcall(server.tick, debug.traceback, server) -- Call the main server function once per update
    if not success then
        print(value)
        server:shutdown(value)
        Socket.sleep(5)
        print("restarting...")
        server = setmetatable({},{__index = Server})
        server:start()
    end
end

function love.draw()
    love.graphics.setColor(1, 1, 1)  -- Set color to white
    love.graphics.printf("Connected Players:\n", 10, 10, love.graphics.getWidth(), "left")
    
    local yOffset = 30
    for _, player in pairs(server.players) do
        if player.username and player.uuid and player.map and player.actor and player.x and player.y then
            love.graphics.printf("Player: " .. player.username ..
                                 "\nUUID: " .. player.uuid ..
                                 "\nActor: " .. player.actor ..
                                 "\nSprite: " .. player.sprite ..
                                 "\nMap: " .. player.map ..
                                 "\nX: " .. player.x .. ", Y: " .. player.y)
            yOffset = yOffset + 100
        end
    end
end