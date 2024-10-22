---@class ChatBubble: Object
local ChatBubble, super = Class(Object)

function ChatBubble:init(actor, text, x, y)
    super.init(self,x,y)
    self.origin_x = 0.5
    local x_offset = actor.width * 2
    local y_offset = -actor.height
    self.text = Text(text, x_offset, y_offset, SCREEN_WIDTH * 2, nil, {
        align = "center",
        font = "main_mono"
    })
    self.width, self.height = self.text:getSize()
    self.text.width, self.text.height = self.text:getSize() -- Freeze!
    self.text:setText(text)
    self.lifetime = 11
    self.rectangle = Rectangle(x_offset, y_offset, self.text:getSize())
    self:addChild(self.rectangle)
    self:addChild(self.text)
    self.rectangle.alpha = 0.5
    self.rectangle.color = {0.2,0.2,0.2}
end

function ChatBubble:update()
    super.update(self)
    self.lifetime = self.lifetime - DT
    if self.lifetime < 0 then return self:remove() end
    if self.lifetime < 1 then
        self.alpha = self.lifetime
        self.text.alpha = self.lifetime
        self.rectangle.alpha = self.lifetime * 0.5
    end
end


return ChatBubble