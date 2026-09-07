-- [[ Pet Sim 99 | Stealth script (WindUI) ]]
-- Replace this placeholder with your real Pet Sim 99 hub.

local WindUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"
))()

local Window = WindUI:CreateWindow({
    Title = "Stealth | Pet Sim 99",
    Folder = "Stealth",
    Icon = "solar:paw-bold-duotone",
    NewElements = true,
    Topbar = { Height = 44, ButtonsType = "Mac" },
})

local Section = Window:Section({ Title = "Auto" })
local Tab = Section:Tab({
    Title = "Main",
    Icon = "solar:play-bold",
    IconShape = "Square",
    Border = true,
})

Tab:Section({ Title = "Automation" })

Tab:Toggle({
    Title = "Auto Hatch",
    Desc = "Hatches eggs automatically.",
    Callback = function(v)
        print("[PetSim99] Auto Hatch:", v)
    end,
})
Tab:Space({ Columns = 1 })

Tab:Toggle({
    Title = "Auto Sell",
    Desc = "Sells pets that match your filter.",
    Callback = function(v)
        print("[PetSim99] Auto Sell:", v)
    end,
})
Tab:Space({ Columns = 1 })

Tab:Toggle({
    Title = "Auto Upgrade Pets",
    Desc = "Upgrades pets using available coins.",
    Callback = function(v)
        print("[PetSim99] Auto Upgrade:", v)
    end,
})

WindUI:Notify({
    Title = "Pet Sim 99",
    Content = "Script loaded!",
    Duration = 3,
    Icon = "solar:check-circle-bold",
})
