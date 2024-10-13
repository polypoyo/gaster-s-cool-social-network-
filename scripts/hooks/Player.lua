---@class Player
local Player, super = Class("Player", true)

local socket = require("socket")
local json = JSON

local function sendToServer(client, message)
    local encodedMessage = json.encode(message)
    client:send(encodedMessage .. "\n")
end

local client = assert(socket.connect("serveo.net", 25574))
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

    if Input.pressed("e") then
        self:setAnimation("battle/idle", 0.25, true)
    end
    if Input.pressed("q") then
        self:resetSprite()
    end
    
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
        elseif data.command == "anim_sync" then
            if data.subCommand == "sprite" then
                for _, username in ipairs(data.players) do
                    if self.other_players[username] then
                        self.other_players[username]:setSprite(data.animationData)
                    end
                end
            elseif data.subCommand == "anim" then
                for _, username in ipairs(data.players) do
                    if self.other_players[username] then
                        self.other_players[username]:setAnimation(data.animationData)
                    end
                end
            elseif data.subCommand == "reset" then
                for _, username in ipairs(data.players) do
                    if self.other_players[username] then
                        self.other_players[username]:resetSprite()
                    end
                end
            end
        end
    end

    -- Send client's own update
    local updateMessage = {
        command = "world",
        subCommand = "update",
        username = self.name,
        x = self.x,
        y = self.y,
        actor = self.actor.id or "kris",
        map = Game.world.map.id or "null",
        direction = self.facing
    }

    sendToServer(client, updateMessage)

    if self.sprite.sprite ~= "walk" and self.animation_off ~= false then
        self.animation_off = false
        if self.sprite.anim then
            msg = {
                command = "anim_sync",
                subCommand = "anim",
                username = self.name,
                animationData = self.sprite.anim
            }
        else
            msg = {
                command = "anim_sync",
                subCommand = "sprite",
                username = self.name,
                animationData = self.sprite.sprite
            }
        
        end
        sendToServer(client, msg)
    elseif self.animation_off == false and self.sprite.sprite == "walk" then
        self.animation_off = true
        local msg = {
            command = "anim_sync",
            subCommand = "reset",
            username = self.name
        }
        sendToServer(client, msg)
    end

    if self.other_players then
        local playersList = {}
        for username, _ in pairs(self.other_players) do
            playersList[username] = true
        end

        local inMapMessage = {
            command = "world",
            subCommand = "inMap",
            username = self.name,
            players = playersList
        }

        sendToServer(client, inMapMessage)
    end
end

return Player
