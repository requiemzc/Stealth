-- [[ Pet Sim 99 | Stealth script ]]
-- Replace this placeholder with your real Pet Sim 99 hub.

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Stealth | Pet Sim 99",
    LoadingTitle = "Pet Sim 99",
    LoadingSubtitle = "by Stealth",
    ConfigurationSaving = { Enabled = true, FolderName = "Stealth", FileName = "PetSim99" },
})

local Tab = Window:CreateTab("Main", "paw-print")
Tab:CreateSection("Auto")
Tab:CreateToggle({
    Name = "Auto Hatch",
    CurrentValue = false,
    Flag = "AutoHatch",
    Callback = function(v)
        print("[PetSim99] Auto Hatch:", v)
    end,
})
Tab:CreateToggle({
    Name = "Auto Sell",
    CurrentValue = false,
    Flag = "AutoSell",
    Callback = function(v)
        print("[PetSim99] Auto Sell:", v)
    end,
})

Rayfield:LoadConfiguration()
Rayfield:Notify({ Title = "Pet Sim 99", Content = "Script loaded!", Duration = 3 })
