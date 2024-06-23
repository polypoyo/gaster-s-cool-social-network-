---@class Player
local Player, super = Class("Player", true)

local socket = require("socket")
local json = JSON

local function sendToServer(client, message)
    local encodedMessage = json.encode(message)
    client:send(encodedMessage .. "\n")
end

local client = assert(socket.connect("localhost", 25574))
client:settimeout(0)

function Player:init(...)
    super.init(self, ...)
    self.name = Game.save_name
    --local object = Nametag(self)
    --self:addChild(object)

    if not self.facing then
        self.facing = "down"
    end

    self.other_players = {}

    local registerMessage = {
        command = "register",
        username = self.name
    }
    sendToServer(client, registerMessage)
end

local function receiveFromServer(client)
    local response, err = client:receive()
    if response then
        local decodedResponse = json.decode(response)
        --print("Received from server: ", decodedResponse)  
        return decodedResponse
    elseif err ~= "timeout" then
        print("Error: ", err)
    end
end

function Player:update(...)
    super.update(self, ...)

    local data = receiveFromServer(client)
    if data then
        if data.command == "update" then
            for _, playerData in ipairs(data.players) do
                if playerData.username ~= self.name then
                    if not self.other_players then
                        self.other_players = {}
                    end

                    local other_player = self.other_players[playerData.username]

                    if other_player then
                        -- Smoothly interpolate position update
                        other_player.targetX = playerData.x
                        other_player.targetY = playerData.y
                        -- Update facing direction
                        other_player:setFacing(playerData.direction)
                    else
                        -- Create a new player if it doesn't exist
                        other_player = Other_Player(playerData.actor, playerData.x, playerData.y, playerData.username)
                        other_player.layer = Game.world.map.object_layer
                        Game.world:addChild(other_player)
                        self.other_players[playerData.username] = other_player
                        -- Set initial facing direction
                        other_player:setFacing(playerData.direction)
                    end
                end
            end
        elseif data.command == "RemoveOtherPlayersFromMap" then
            for _, username in ipairs(data.players) do
                if self.other_players[username] then
                    self.other_players[username]:remove()
                    self.other_players[username] = nil
                end
            end
        end
    end

    -- Send client's own update
    local updateMessage = {
        command = "update",
        username = self.name,
        x = self.x,
        y = self.y,
        actor = self.actor.id or "kris",
        map = Game.world.map.id or "null",
        direction = self.facing
    }

    sendToServer(client, updateMessage)

    if self.other_players then
        local playersList = {}
        for username, _ in pairs(self.other_players) do
            playersList[username] = true
        end

        local inMapMessage = {
            command = "inMap",
            username = self.name,
            players = playersList
        }

        sendToServer(client, inMapMessage)
    end
end

return Player
