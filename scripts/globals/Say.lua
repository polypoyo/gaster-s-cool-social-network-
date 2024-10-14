return function(text)
    Game.client:send(JSON.encode({
        command = "world",
        subCommand = "chat",
        uuid = Mod.libs.gasterscoolsocialnetwork.uuid,
        message = text
    }).."\n")
end