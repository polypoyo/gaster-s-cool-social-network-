---@class Nametag : Object
---@overload fun(...) : Nametag
local UserNametag, super = Class(Object)

function UserNametag:init(pc, name)
    super.init(self)

    self.pc = pc

    self.name = name
    self.length = string.len(self.name)


    self.font = Assets.getFont("main")
    self.smallfont = Assets.getFont("main",16)
    self.connected = false


end

function UserNametag:pc_force_move(x, y, room)

    if not room == false then

    end

    self.pc.x = x
    self.pc.y = y
end

function UserNametag:update()
    super.update(self)
    self.name = self.pc.name

    if Input.pressed("1") then
        self.connected = 1
        self.pc.x = 300
        self.pc.y = 260
    end

    if Input.pressed("2") then
        self.connected = 2
    end

    if Input.pressed("3") then
        self.connected = 3
    end



end

function UserNametag:draw()
    love.graphics.setFont(self.font)

    love.graphics.scale(0.5, 0.5)
Draw.setColor(0, 0, 0, 1)
for x=-1, 1 do
for y=-1, 1 do
love.graphics.print(self.name, self.length *-self.length/2 + (x*2), -self.pc.actor.height/2 *2 + (y*2))
end
end

    if self.connected == 1 then
        Draw.setColor(0, 0, 1, 1)
    elseif self.connected == 2 then
        Draw.setColor(0, 1, 0, 1)
    elseif self.connected == 3 then
        Draw.setColor(1, 0, 0, 1)
else
Draw.setColor(1, 1, 1, 1)
    end

    love.graphics.print(self.name, self.length *-self.length/2, -self.pc.actor.height/2 *2)
    if DEBUG_RENDER and self.pc.uuid then
        love.graphics.setFont(self.smallfont)
        love.graphics.print(self.pc.uuid, -105, (-self.pc.actor.height/2 *2) + 32)
    end

    Draw.setColor(1, 1, 1, 1)
    super.draw(self)
end
return UserNametag
