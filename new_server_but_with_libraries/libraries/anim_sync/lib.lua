local Lib = {}

function Lib.processCommand(client, message)
    if message.subCommand == "sprite" then
        -- Start animation logic here
        local username = message.username
        --local animation = message.animationType
        local animationData = message.animationData
        
        -- Example: Broadcast animation data to all clients
        local animationMessage = {
            command = "anim_sync",
            subCommand = "sprite",
            players = {username},
            animationData = animationData
        }
        --print(animationData)

        for _, otherClient in ipairs(clients) do
            if otherClient ~= client then
                otherClient:send(json.encode(animationMessage) .. "\n")
            end
        end
    elseif message.subCommand == "anim" then
        local username = message.username
        local animationData = message.animationData
        local animationMessage = {
            command = "anim_sync",
            subCommand = "anim",
            players = {username},
            animationData = animationData
        }
        for _, otherClient in ipairs(clients) do
            if otherClient ~= client then
                otherClient:send(json.encode(animationMessage) .. "\n")
            end
        end
    elseif message.subCommand == "reset" then
        local username = message.username
        local animationMessage = {
            command = "anim_sync",
            subCommand = "reset",
            players = {username}
        }
        for _, otherClient in ipairs(clients) do
            if otherClient ~= client then
                otherClient:send(json.encode(animationMessage) .. "\n")
            end
        end
    end
    -- Add more commands as needed
end

return Lib
