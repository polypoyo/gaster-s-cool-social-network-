---@class Game

Game.socket = require("socket")

Game.client = assert(
    Game.socket.connect(
        Kristal.getLibConfig("gasterscoolsocialnetwork", "domain"),
        Kristal.getLibConfig("gasterscoolsocialnetwork", "port")
    )
)

--Utils.hook(Game, "update", function(orig, self)

--end)


return Game