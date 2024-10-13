---@class Server
local Server = {}
local TIMEOUT_THRESHOLD = 20

function Server:init()
    self.socket = require("socket")
    self.json = require("json")
    
    self.server = assert(self.socket.bind("localhost", 25574))
    self.ip, self.port = self.server:getsockname()
    self.server:settimeout(0)
    print("Server started on " .. self.ip .. ":" .. self.port)
    
    self.clients = {}
    self.players = {}
    self.updateInterval = 0.1
    self.lastUpdateTime = self.socket.gettime()
end

local self = Server

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
function Server:removePlayer(client)
    for i, c in ipairs(self.clients) do
        if c == client then
            table.remove(self.clients, i)
            break
        end
    end
    for id, player in pairs(self.players) do
        if player.client == client then
            print("Player " .. self.players[id].username .. " removed due to disconnection.")
            self.players[id] = nil
            break
        end
    end
end

-- Check for inactive players
function Server:checkForInactivePlayers()
    local currentTime = self.socket.gettime()
    for id, player in pairs(self.players) do
        if currentTime - player.lastUpdate >= TIMEOUT_THRESHOLD then
            self:removePlayer(player.client)
        end
    end
end

-- Send updates to clients
function Server:sendUpdatesToClients()
    local updates = {}

    -- Collect updates per map
    for id, player in pairs(self.players) do
        if player.client then
            updates[player.map] = updates[player.map] or {}
            table.insert(updates[player.map], {
                username = player.username,
                uuid = id,
                x = player.x,
                y = player.y,
                actor = player.actor,
                sprite = player.sprite,
                map = player.map,
                direction = player.direction
            })
        end
    end

    -- Send updates only to players on the same map
    for id, player in pairs(self.players) do
        if player.client and updates[player.map] then
            local updateMessage = {
                command = "update",
                players = updates[player.map]
            }
            player.client:send(self.json.encode(updateMessage) .. "\n")
        end
    end
end

-- Handle client messages
function Server:processClientMessage(client, data)
    local message = self.json.decode(data)
    local command = message.command
    local subCommand = message.subCommand

    if command == "register" then
        local id = message.uuid or uuid()
        self.players[id] = {
            username = message.username,
            x = 0, y = 0, actor = message.actor or "dummy",
            sprite = message.sprite or "walk", 
            map = message.map or "default", 
            uuid = id,
            client = client, lastUpdate = self.socket.gettime(), direction = "down"
        }
        print("Player " .. message.username .. "(uuid=" .. id .. ") registered with actor: " .. self.players[id].actor)
        client:send(self.json.encode{
            command = "register",
            uuid = id
        }.. "\n")

    elseif command == "world" then 
        if subCommand == "update" then
            local player = self.players[message.uuid]
            if player then
                player.username = message.username
                player.x = message.x
                player.y = message.y
                player.map = message.map or player.map
                player.direction = message.direction
                player.actor = message.actor
                player.sprite = message.sprite
                player.lastUpdate = self.socket.gettime()
            end
        elseif subCommand == "inMap" then
            local id = message.uuid
            local clientPlayers = message.players
            local player = self.players[id]

            if player then
                local actualMapPlayers = {}
                for otherId, otherPlayer in pairs(self.players) do
                    if otherPlayer.map == player.map then
                        actualMapPlayers[otherId] = true
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
                    player.client:send(self.json.encode(removeMessage) .. "\n")
                end
            end
        end
    elseif command == "disconnect" then
        print("Player " .. self.players[message.id].username .. " disconnected")
        self:removePlayer(client)
    end
end

-- Main server loop
function Server:tick()
    local client = self.server:accept()
    if client then
        client:settimeout(0)
        table.insert(self.clients, client)
        print("New client connected")
    end

    local readable, _, _ = self.socket.select(self.clients, nil, 0)
    for _, client in ipairs(readable) do
        local data, err = client:receive()
        if data then
            self:processClientMessage(client, data)
        elseif err == "closed" then
            self:removePlayer(client)
            print("Client disconnected")
        end
    end

    local currentTime = self.socket.gettime()
    if (currentTime - self.lastUpdateTime) >= self.updateInterval then
        self:sendUpdatesToClients()
        self.lastUpdateTime = currentTime
    end

    -- Check for inactive players
    self:checkForInactivePlayers()
end

Server:init()
return Server