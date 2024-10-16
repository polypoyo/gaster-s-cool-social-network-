---@class Lib
local Lib = {}

Game.socket = require("socket")

Game.client = assert(
    Game.socket.connect(
        Kristal.getLibConfig("gasterscoolsocialnetwork", "domain"),
        Kristal.getLibConfig("gasterscoolsocialnetwork", "port")
    )
)

local socket = Game.socket
local json = JSON

local function sendToServer(client, message)
    local encodedMessage = json.encode(message)
    -- print("[OUT] "..Utils.dump(encodedMessage))
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
local HEARTBEAT_INTERVAL = 10.0
local lastHearbeatTime = love.timer.getTime()
local lastUpdateTime = 0
local lastPlayerListTime = 0
function Lib:init()
    Utils.hook(World, 'update', function (orig, wld, ...)
        orig(wld,...)
        self:updateWorld()
    end)
    Utils.hook(Game, "update", function (orig, ...)
        orig(...)
        self:update()
    end)
end
function Lib:postInit()
    self.name = Game.save_name
    self.other_players = nil
    self.other_players = {}  -- Store other players
    -- Register player with username and actor
    local registerMessage = {
        command = "register",
        uuid = Game:getFlag("GCSN_UUID"), -- server will generate this if it's nil
        username = self.name,
        actor = Game.party[1].actor.id or "kris"  -- Include actor
    }
    sendToServer(client, registerMessage)
end

function Lib:update()
    local currentTime = love.timer.getTime()
    if currentTime - lastHearbeatTime >= HEARTBEAT_INTERVAL then
        lastHearbeatTime = currentTime
        sendToServer(client, {
            command = "heartbeat",
            uuid = self.uuid,
            gamestate = Game.state
        })
    end
end

function Lib:updateWorld(...)
    local player = Game.world.player
    -- Update the current time
    local currentTime = love.timer.getTime()

    -- Receive data from the server (if any)
    local data = receiveFromServer(client)
    if data then
        -- print("[NET] "..Utils.dump(data))
        if data.command == "register" then
            self.uuid = data.uuid
            Game:setFlag("GCSN_UUID", self.uuid)
        elseif data.command == "update" then
            for _, playerData in ipairs(data.players) do
                if playerData.uuid ~= self.uuid then
                    local other_player = self.other_players[playerData.uuid]

                    if other_player then
                        -- Smoothly interpolate position update
                        other_player.targetX = playerData.x
                        other_player.targetY = playerData.y
                        other_player.name = playerData.username

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

                        if playerData.map == Game.world.map.id then
                            -- Create a new player if it doesn't exist while making sure It's on the right map
                            other_player = otherplr
                            other_player.layer = Game.world.map.object_layer
                            other_player.mapID = playerData.map
                            Game.world:addChild(other_player)
                            self.other_players[playerData.uuid] = other_player
                        end
                    end
                end
            end
        elseif data.command == "chat" then
            local sender = self.other_players[data.uuid] or Game.world.player
            local bubble = ChatBubble(sender.actor, data.message)
            bubble:setScale(0.25)
            sender:addChild(bubble)
        elseif data.command == "RemoveOtherPlayersFromMap" then
            for _, uuid in ipairs(data.players) do
                if self.other_players[uuid] then
                    self.other_players[uuid].fadingOut = true
                    self.other_players[uuid] = nil
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
            x = player.x,
            y = player.y,
            map = Game.world.map.id or "null",
            actor = player.actor.id,
            sprite = player.sprite.sprite_options[1]
        }
        sendToServer(client, updateMessage)
        lastUpdateTime = currentTime
    end

    -- Throttle current players list packets
    if currentTime - lastPlayerListTime >= THROTTLE_INTERVAL then
        local playersList = {}
        for uuid, _ in pairs(self.other_players) do
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

return Lib
