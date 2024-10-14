---@class ChatBubble: Object
local ChatBubble, super = Class(Object)
local function str_split(self, delimiter)
    local result = { }
    local from  = 1
    local delim_from, delim_to = string.find( self, delimiter, from  )
    while delim_from do
      table.insert( result, string.sub( self, from , delim_from-1 ) )
      from  = delim_to + 1
      delim_from, delim_to = string.find( self, delimiter, from  )
    end
    table.insert( result, string.sub( self, from  ) )
    return result
  end
  
function ChatBubble:init(actor, text, x, y)
    super.init(self,x,y)
    local split_text = str_split(text, "\n")
    local longest_line = 0
    for _, v in ipairs(split_text) do
        longest_line = math.max(longest_line, #v)
    end
    self.origin_x = 0.5 -- * longest_line
    self.width = (16 * longest_line) + 4
    self.height = 32 * #(split_text)
    self.x_offset = actor.width
    self.y_offset = -actor.height
    self.text = Text(text, self.x_offset, self.y_offset, self.width, self.height, {
        align = "center",
        font = "main_mono"
    })
    self.lifetime = 11
    self:addChild(self.text)
end

function ChatBubble:update()
    self.lifetime = self.lifetime - DT
    if self.lifetime < 0 then return self:remove() end
    if self.lifetime < 1 then
        self.alpha = self.lifetime
        self.text.alpha = self.lifetime
    end
end

function ChatBubble:draw()
    love.graphics.push("all")
    love.graphics.setColor(0.3,0.3,0.3,0.5 * self.alpha)
    love.graphics.rectangle("fill", self.x_offset, self.y_offset, self.width, self.height)
    love.graphics.pop()
    super.draw(self)
end

return ChatBubble