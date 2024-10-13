
local socket = require("socket")
local json = require("json")

local server = assert(socket.bind("localhost", 25574))
local ip, port = server:getsockname()
server:settimeout(0)
print("Server started on " .. ip .. ":" .. port)

local clients = {}
local players = {}
local updateInterval = 0.1
local lastUpdateTime = socket.gettime()
local TIMEOUT_THRESHOLD = 20


math.randomseed(os.time())

local random = math.random
local function uuid()
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
        return string.format('%x', v)
    end)
end

--print(uuid())

-- Remove disconnected player
local function removePlayer(client)
    for i, c in ipairs(clients) do
        if c == client then
            table.remove(clients, i)
            break
        end
    end
    for username, player in pairs(players) do
        if player.client == client then
            players[username] = nil
            print("Player " .. username .. " removed due to disconnection.")
            break
        end
    end
end

-- Check for inactive players
local function checkForInactivePlayers()
    local currentTime = socket.gettime()
    for username, player in pairs(players) do
        if currentTime - player.lastUpdate >= TIMEOUT_THRESHOLD then
            removePlayer(player.client)
        end
    end
end

-- Send updates to clients
local function sendUpdatesToClients()
    local updates = {}

    -- Collect updates per map
    for username, player in pairs(players) do
        if player.client then
            updates[player.map] = updates[player.map] or {}
            table.insert(updates[player.map], {
                username = username,
                x = player.x,
                y = player.y,
                actor = player.actor,
                map = player.map,
                direction = player.direction,
                sprite = player.sprite
            })
        end
    end

    -- Send updates only to players on the same map
    for uuid, player in pairs(players) do
        if player.client and updates[player.map] then
            local updateMessage = {
                command = "update",
                players = updates[player.map]
            }
            player.client:send(json.encode(updateMessage) .. "\n")
        end
    end
end

-- Handle client messages
local function processClientMessage(client, data)
    local message = json.decode(data)
    local command = message.command
    local subCommand = message.subCommand

    if command == "register" then
        players[message.username] = {
            username = message.username,
            x = 0, y = 0, actor = message.actor or "dummy",
            map = message.map or "default", 
            sprite = message.sprite or "walk", 
            client = client, lastUpdate = socket.gettime(), direction = "down"
        }
        print("Player " .. message.username .. " registered with actor: " .. players[message.username].actor)

    elseif command == "world" and subCommand == "update" then
        local player = players[message.username]
        if player then
            player.x = message.x
            player.y = message.y
            player.map = message.map or player.map
            player.direction = message.direction
            player.actor = message.actor
            player.sprite = message.sprite
            player.lastUpdate = socket.gettime()
        end
    elseif command == "world" and subCommand == "inMap" then
        local username = message.username
        local clientPlayers = message.players
        local player = players[username]

        if player then
            local actualMapPlayers = {}
            for otherUsername, otherPlayer in pairs(players) do
                if otherPlayer.map == player.map then
                    actualMapPlayers[otherUsername] = true
                end
            end

            -- Determine which players to remove
            local playersToRemove = {}
            for _, clientPlayer in ipairs(clientPlayers) do
                if not actualMapPlayers[clientPlayer] then
                    table.insert(playersToRemove, clientPlayer)
                end
            end

            -- Send removal message if needed
            if #playersToRemove > 0 then
                local removeMessage = {
                    command = "RemoveOtherPlayersFromMap",
                    players = playersToRemove
                }
                player.client:send(json.encode(removeMessage) .. "\n")
            end
        end
    elseif command == "disconnect" then
        removePlayer(client)
        print("Player " .. message.username .. " disconnected")
    end
end

-- Main server loop
local function main()
    local client = server:accept()
    if client then
        client:settimeout(0)
        table.insert(clients, client)
        print("New client connected")
    end

    local readable, _, _ = socket.select(clients, nil, 0)
    for _, client in ipairs(readable) do
        local data, err = client:receive()
        if data then
            processClientMessage(client, data)
        elseif err == "closed" then
            removePlayer(client)
            print("Client disconnected")
        end
    end

    local currentTime = socket.gettime()
    if (currentTime - lastUpdateTime) >= updateInterval then
        sendUpdatesToClients()
        lastUpdateTime = currentTime
    end

    -- Check for inactive players
    checkForInactivePlayers()
end

function love.update(dt)
    main()  -- Call the main server function once per update
end

function love.draw()
    love.graphics.setColor(1, 1, 1)  -- Set color to white
    love.graphics.printf("Connected Players:\n", 10, 10, love.graphics.getWidth(), "left")
    
    local yOffset = 30
    for _, player in pairs(players) do
        if player.username and player.map and player.actor and player.x and player.y and player.direction then
            love.graphics.printf("Player: " .. player.username ..
                                 "\nActor: " .. player.actor ..
                                 "\nSprite: " .. player.sprite ..
                                 "\nMap: " .. player.map ..
                                 "\nX: " .. player.x .. ", Y: " .. player.y ..
                                 "\nDirection: " .. player.direction, 10, yOffset, love.graphics.getWidth(), "left")
            yOffset = yOffset + 80
        end
    end
end
