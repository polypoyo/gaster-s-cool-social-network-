---@class Other_Player : Character
---@overload fun(...) : Other_Player
local Other_Player, super = Class(Character)

function Other_Player:init(chara, x, y, name, uuid)
    super.init(self, chara, x, y)
    self.name = name
    self.targetX = x
    self.targetY = y
    self.uuid = uuid

    local nametag = UserNametag(self, self.name)
    self:addChild(nametag)
end

function Other_Player:getDebugInfo()
    local info = super.getDebugInfo(self)
    table.insert(info, "player: " .. self.name)
    return info
end

function Other_Player:setActor(actor)
    super.setActor(self, actor)
end

function Other_Player:handleMovement()
end


function Other_Player:moveTo(x, y, keep_facing)
    if type(x) == "string" then
        keep_facing = y
        x, y = self.world.map:getMarker(x)
    end
    self:move(x - self.x, y - self.y, 0.5, keep_facing)
end

-- Example of updating sprite animation in Other_Player class
function Other_Player:update(...)
    super.update(self, ...)

    -- Check if this player is moving
    if self.targetX and self.targetY then
        local moved = self:moveTo(self.targetX, self.targetY, true)  -- Assuming moveTo updates movement

        -- Update sprite animation based on movement state
        self.sprite.walking = moved
        self.sprite.walk_speed = moved and 4 or 0  -- Set appropriate walk speed

        -- Optionally, set facing direction based on movement
        if moved then
            self:faceTowards({ x = self.targetX, y = self.targetY })
        end
    end
end


function Other_Player:draw()
    -- Draw the player
    super.draw(self)
end

return Other_Player
