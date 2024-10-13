---@class Player
local Player, super = Class("Player", true)

local socket = Game.socket
local json = JSON

local function sendToServer(client, message)
    local encodedMessage = json.encode(message)
    client:send(encodedMessage .. "\n")
end

local function receiveFromServer(client)
    local response, err = client:receive()
    if response then
        local decodedResponse = json.decode(response)
        return decodedResponse
    elseif err ~= "timeout" then
        print("Error: ", err)
    end
end

local client = Game.client
client:settimeout(0)

-- Throttle interval (in seconds)
local THROTTLE_INTERVAL = 0.05
local lastUpdateTime = 0
local lastPlayerListTime = 0

function Player:init(...)
    super.init(self, ...)
    self.name = Game.save_name
    Game.world.other_players = nil
    Game.world.other_players = {}  -- Store other players

    -- Register player with username and actor
    local registerMessage = {
        command = "register",
        uuid = Game:getFlag("GCSN_UUID"), -- server will generate this if it's nil
        username = self.name,
        actor = self.actor.id or "kris"  -- Include actor
    }
    sendToServer(client, registerMessage)
end



function Player:update(...)
    super.update(self, ...)

    -- Update the current time
    local currentTime = love.timer.getTime()

    -- Receive data from the server (if any)
    local data = receiveFromServer(client)
    if data then
        if data.command == "register" then
            self.uuid = data.uuid
            Game:setFlag("GCSN_UUID", self.uuid)
        elseif data.command == "update" then
            for _, playerData in ipairs(data.players) do
                if playerData.uuid ~= self.uuid then
                    local other_player = Game.world.other_players[playerData.uuid]

                    if other_player then
                        -- Smoothly interpolate position update
                        other_player.targetX = playerData.x
                        other_player.targetY = playerData.y
                        -- Update facing direction
                        other_player:setFacing(playerData.direction)

                        if other_player.actor.id ~= playerData.actor then
                            
                            local success, result = pcall(Other_Player, playerData.actor, 0, 0, 0)
                            if success then
                                other_player:setActor(playerData.actor)
                            else
                                other_player:setActor("dummy")
                            end
                        end
                        
                        if other_player.sprite.sprite_options[1] ~= playerData.sprite then
                            other_player:setSprite(playerData.sprite)
                        end
                    else
                        local otherplr
                        local success, result = pcall(Other_Player, playerData.actor, playerData.x, playerData.y, playerData.username, playerData.uuid)
                        if success then
                            otherplr = result
                        else
                            otherplr = Other_Player("dummy", playerData.x, playerData.y, playerData.username, playerData.uuid)
                        end
                        -- Create a new player if it doesn't exist
                        other_player = otherplr
                        other_player.layer = Game.world.map.object_layer
                        Game.world:addChild(other_player)
                        Game.world.other_players[playerData.uuid] = other_player
                        -- Set initial facing direction
                        other_player:setFacing(playerData.direction)
                    end
                end
            end
        elseif data.command == "RemoveOtherPlayersFromMap" then
            for _, username in ipairs(data.players) do
                if Game.world.other_players[uuid] then
                    Game.world.other_players[uuid]:remove()
                    Game.world.other_players[uuid] = nil
                end
            end
        end
    end

    -- Throttle player position update packets
    if currentTime - lastUpdateTime >= THROTTLE_INTERVAL then
        local updateMessage = {
            command = "world",
            subCommand = "update",
            username = self.name,
            uuid = self.uuid,
            x = self.x,
            y = self.y,
            map = Game.world.map.id or "null",
            direction = self.facing,
            actor = self.actor.id,
            sprite = self.sprite.sprite_options[1]
        }
        sendToServer(client, updateMessage)
        lastUpdateTime = currentTime
    end

    -- Throttle current players list packets
    if currentTime - lastPlayerListTime >= THROTTLE_INTERVAL then
        local playersList = {}
        for uuid, _ in pairs(Game.world.other_players) do
            table.insert(playersList, uuid)
        end

        local currentPlayersMessage = {
            command = "world",
            subCommand = "inMap",
            uuid = self.uuid,
            username = self.name,
            players = playersList
        }
        sendToServer(client, currentPlayersMessage)
        lastPlayerListTime = currentTime
    end
end

return Player
