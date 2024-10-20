---@class ChatInputBox : Object
---@overload fun(...) : ChatInputBox
local ChatInputBox, super = Class(Object)
function ChatInputBox:init(x,y)
    super.init(self, x, y, SCREEN_WIDTH, 16)
    self.is_open = false
    self.layer = 10000000 - 1

    self.font_size = 16
    self.font_name = "main_mono"

    self.font = Assets.getFont(self.font_name, self.font_size)
    self.input = {""}
end

function ChatInputBox:onRemoveFromStage()
    TextInput.endInput()
end

function ChatInputBox:draw()
    if self.is_open then
        TextInput.draw({
            prefix_width = self.font:getWidth("> "),
            get_prefix = function(place)
                if place == "start"  then return "┌ " end
                if place == "middle" then return "├ " end
                if place == "end"    then return "└ " end
                if place == "single" then return "─ " end
                return "  "
            end,
            x = -4,
            y = input_pos,
            print = function (text, x, y)
                love.graphics.setFont(self.font)
                love.graphics.print(text, x, y)
            end,
            font = self.font
        })
    end
    super.draw(self)
end

function ChatInputBox:close()
    self.is_open = false
    TextInput.endInput()
end

function ChatInputBox:onAdd(parent)
    super.onAdd(self, parent)
end

function ChatInputBox:open()
    self.is_open = true
    TextInput.attachInput(self.input, {
        multiline = true,
        enter_submits = true,
    })
    TextInput.submit_callback = function() self:onSubmit() end
end

function ChatInputBox:onSubmit()
    Say(table.concat(self.input, "\n"))
    self:close()
end

return ChatInputBox