local socket = require("socket")
json = require("json")

local server = assert(socket.bind("localhost", 25574))
local ip, port = server:getsockname()

server:settimeout(0)
print("Server started on " .. ip .. ":" .. port)

clients = {}
players = {}
connectedPlayers = {}

local updateInterval = 0.1 -- Send updates every 0.1 seconds
local lastUpdateTime = socket.gettime()

local TIMEOUT_THRESHOLD = 10 -- Timeout threshold in seconds

-- Define a table to hold loaded libraries
local libraries = {}

-- Function to load libraries from the 'libraries' folder
local function loadLibraries()
    local path = "libraries/"
    local files = love.filesystem.getDirectoryItems(path)

    for _, file in ipairs(files) do
        local fullPath = path .. file
        if love.filesystem.getInfo(fullPath .. "/lib.lua", "file") then
            libraries[file] = require(fullPath .. ".lib")
            print("Loaded library: " .. file)
        end
    end
end

-- Call this function to load libraries at the start
loadLibraries()

function removePlayer(client)
    for i, c in ipairs(clients) do
        if c == client then
            table.remove(clients, i)
            break
        end
    end
    for username, player in pairs(players) do
        if player.client == client then
            players[username] = nil
            break
        end
    end
    updateConnectedPlayers()
end

function isPlayerDisconnected(player)
    local currentTime = socket.gettime()
    return (currentTime - player.lastUpdate) > TIMEOUT_THRESHOLD
end

function updateConnectedPlayers()
    connectedPlayers = {}
    for username, player in pairs(players) do
        if player.client and player.map and player.actor then
            table.insert(connectedPlayers, {
                username = username,
                map = player.map,
                actor = player.actor,
                x = player.x,
                y = player.y,
                direction = player.direction
            })
        end
    end
end

function sendUpdatesToClients()
    local updates = {}
    for username, player in pairs(players) do
        if player.client then
            if not updates[player.map] then
                updates[player.map] = {}
            end
            table.insert(updates[player.map], {
                username = username,
                x = player.x,
                y = player.y,
                actor = player.actor,
                map = player.map,
                direction = player.direction
            })
        end
    end

    for username, player in pairs(players) do
        if player.client and updates[player.map] then
            local updateMessage = {
                command = "update",
                players = updates[player.map]
            }
            player.client:send(json.encode(updateMessage) .. "\n")
        end
    end
end

function processClientMessage(client, data)
    local message = json.decode(data)
    local command = message.command
    local subCommand = message.subCommand


    if command == "register" then
        local username = message.username
        players[username] = {
            x = 0, y = 0, actor = "", map = "", client = client, lastUpdate = socket.gettime(), direction = "down"
        }
        print("Player " .. username .. " registered")
        updateConnectedPlayers()
    elseif command == "world" then
        if subCommand == "update" then
            local username = message.username
            if players[username] then
                players[username].x = message.x
                players[username].y = message.y
                players[username].actor = message.actor
                players[username].map = message.map
                players[username].direction = message.direction
                players[username].lastUpdate = socket.gettime()
                updateConnectedPlayers()
            end
        elseif subCommand == "inMap" then
            local username = message.username
            local clientPlayers = message.players
    
            if players[username] then
                local mapPlayers = {}
                for otherUsername, otherPlayer in pairs(players) do
                    if otherPlayer.map == players[username].map then
                        mapPlayers[otherUsername] = true
                    end
                end
    
                local playersToRemove = {}
                for clientPlayer in pairs(clientPlayers) do
                    if not mapPlayers[clientPlayer] then
                        table.insert(playersToRemove, clientPlayer)
                    end
                end
    
                if #playersToRemove > 0 then
                    local removeMessage = {
                        command = "RemoveOtherPlayersFromMap",
                        players = playersToRemove
                    }
                    client:send(json.encode(removeMessage) .. "\n")
                end
            end
        end
        
    elseif libraries[command] then
        libraries[command].processCommand(client, message)
    elseif command == "disconnect" then
        local username = message.username
        removePlayer(client)
        print("Player " .. username .. " disconnected")
    end
    
end

local function main()
        -- Accept new clients
        local client = server:accept()
        if client then
            client:settimeout(0)
            table.insert(clients, client)
            print("New client connected")
        end

        -- Handle client messages
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

        -- Check for player timeouts
        for username, player in pairs(players) do
            if isPlayerDisconnected(player) then
                removePlayer(player.client)
                print("Player " .. username .. " disconnected (timeout)")
            end
        end

        -- Send updates to clients at fixed intervals
        local currentTime = socket.gettime()
        if (currentTime - lastUpdateTime) >= updateInterval then
            sendUpdatesToClients()
            lastUpdateTime = currentTime
        end

        -- Sleep briefly to prevent high CPU usage
        --socket.sleep(0.01)
end




-- Won't do anything sadly :(
-- It looked really cool
-- Trust me

-- Edit: This is a stupid workaround
function love.draw()
    main()
    -- Draw connected players
    love.graphics.setColor(1, 1, 1)  -- Set color to white
    love.graphics.printf("Connected Users:\n", 10, 10, love.graphics.getWidth(), "left")
    local yOffset = 30
    main()
    for _, player in ipairs(connectedPlayers) do
        main()
        love.graphics.printf("Player: * " .. player.username .. " *\nMap: | " .. player.map .. " |\nActor: | " .. player.actor .. " |\nX and Y: [ " .. player.x ..", ".. player.y .. " ]\nFacing: " .. player.direction, 10, yOffset, love.graphics.getWidth(), "left")
        yOffset = yOffset + 80
        main()
    end
    main()
end
