-- [[ Blox Fruits | Stealth script (WindUI) ]]
-- Replace this placeholder with your real Blox Fruits hub.

local WindUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"
))()

local Window = WindUI:CreateWindow({
    Title = "Stealth | Blox Fruits",
    Folder = "Stealth",
    Icon = "solar:sword-bold-duotone",
    NewElements = true,
    Topbar = { Height = 44, ButtonsType = "Mac" },
})

local Section = Window:Section({ Title = "Farming" })
local Tab = Section:Tab({
    Title = "Main",
    Icon = "solar:play-bold",
    IconShape = "Square",
    Border = true,
})

Tab:Section({ Title = "Auto Farm" })

Tab:Toggle({
    Title = "Auto Farm Level",
    Desc = "Auto-attacks the nearest mob for XP.",
    Callback = function(v)
        print("[BloxFruits] Auto Farm Level:", v)
    end,
})
Tab:Space({ Columns = 1 })

Tab:Toggle({
    Title = "Auto Raid",
    Desc = "Joins and completes raids automatically.",
    Callback = function(v)
        print("[BloxFruits] Auto Raid:", v)
    end,
})
Tab:Space({ Columns = 1 })

Tab:Toggle({
    Title = "Auto Buy Fragment",
    Desc = "Buys fragments when enough Beli.",
    Callback = function(v)
        print("[BloxFruits] Auto Buy Fragment:", v)
    end,
})

WindUI:Notify({
    Title = "Blox Fruits",
    Content = "Script loaded!",
    Duration = 3,
    Icon = "solar:check-circle-bold",
})
