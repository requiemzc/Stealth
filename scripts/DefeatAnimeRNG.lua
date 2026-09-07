-- [[ Defeat Anime RNG | Stealth script (WindUI) ]]
-- Replace this placeholder with your real Defeat Anime RNG hub.

local WindUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"
))()

local Window = WindUI:CreateWindow({
    Title = "Stealth | Defeat Anime RNG",
    Folder = "Stealth",
    Icon = "solar:sprout-bold-duotone",
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
    Title = "Auto Roll",
    Desc = "Roll at your station and buy wanted rarities.",
    Callback = function(v)
        print("[DefeatAnimeRNG] Auto Roll:", v)
    end,
})
Tab:Space({ Columns = 1 })

Tab:Toggle({
    Title = "Auto Collect Cash",
    Desc = "Fires CollectCashEvent every second.",
    Callback = function(v)
        print("[DefeatAnimeRNG] Auto Cash:", v)
    end,
})
Tab:Space({ Columns = 1 })

Tab:Toggle({
    Title = "Auto Farm Waves",
    Desc = "Fires PlayerAttackEvent every second.",
    Callback = function(v)
        print("[DefeatAnimeRNG] Auto Farm Waves:", v)
    end,
})

WindUI:Notify({
    Title = "Defeat Anime RNG",
    Content = "Script loaded!",
    Duration = 3,
    Icon = "solar:check-circle-bold",
})
