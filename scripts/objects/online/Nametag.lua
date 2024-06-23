---@class Nametag : Object
---@overload fun(...) : Nametag
local Nametag, super = Class(Object)

function Nametag:init(pc, name)
    super.init(self)

    self.pc = pc

    self.name = name
    self.length = string.len(self.name)


    self.font = Assets.getFont("main")
    self.connected = false


end

function Nametag:pc_force_move(x, y, room)

    if not room == false then

    end

    self.pc.x = x
    self.pc.y = y
end

function Nametag:update()
    super.update(self)

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

function Nametag:draw()
    love.graphics.setFont(self.font)

    if self.connected == 1 then
        Draw.setColor(0, 0, 1, 1)
    end

    if self.connected == 2 then
        Draw.setColor(0, 1, 0, 1)
    end

    if self.connected == 3 then
        Draw.setColor(1, 0, 0, 1)
    end

    love.graphics.scale(0.5, 0.5)
    love.graphics.print(self.name, self.length *-self.length/2, -self.pc.actor.height/2 *2)

    Draw.setColor(1, 1, 1, 1)
    super.draw(self)
end
return Nametag