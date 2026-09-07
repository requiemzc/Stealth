-- [[ Universal ESP | Stealth script (WindUI) ]]
-- Works in any game. Replace this placeholder with your real ESP implementation.

local WindUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"
))()

local Window = WindUI:CreateWindow({
    Title = "Stealth | Universal ESP",
    Folder = "Stealth",
    Icon = "solar:eye-bold-duotone",
    NewElements = true,
    Topbar = { Height = 44, ButtonsType = "Mac" },
})

local Section = Window:Section({ Title = "ESP" })
local Tab = Section:Tab({
    Title = "Players",
    Icon = "solar:users-group-rounded-bold",
    IconShape = "Square",
    Border = true,
})

Tab:Section({ Title = "Player ESP" })

Tab:Toggle({
    Title = "Player ESP",
    Desc = "Draw boxes around all players.",
    Callback = function(v)
        print("[Universal] Player ESP:", v)
    end,
})
Tab:Space({ Columns = 1 })

Tab:Toggle({
    Title = "Name Tags",
    Desc = "Show player names above their heads.",
    Callback = function(v)
        print("[Universal] Name Tags:", v)
    end,
})
Tab:Space({ Columns = 1 })

Tab:Toggle({
    Title = "Distance",
    Desc = "Show distance to each player.",
    Callback = function(v)
        print("[Universal] Distance:", v)
    end,
})
Tab:Space({ Columns = 1 })

Tab:Toggle({
    Title = "Tracers",
    Desc = "Draw lines from screen center to each player.",
    Callback = function(v)
        print("[Universal] Tracers:", v)
    end,
})

WindUI:Notify({
    Title = "Universal ESP",
    Content = "Script loaded!",
    Duration = 3,
    Icon = "solar:check-circle-bold",
})
