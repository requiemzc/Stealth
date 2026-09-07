-- [[ Blox Fruits | Stealth script ]]
-- Replace this placeholder with your real Blox Fruits hub.

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Stealth | Blox Fruits",
    LoadingTitle = "Blox Fruits",
    LoadingSubtitle = "by Stealth",
    ConfigurationSaving = { Enabled = true, FolderName = "Stealth", FileName = "BloxFruits" },
})

local Tab = Window:CreateTab("Main", "sword")
Tab:CreateSection("Auto Farm")
Tab:CreateToggle({
    Name = "Auto Farm Level",
    CurrentValue = false,
    Flag = "AutoFarmLevel",
    Callback = function(v)
        print("[BloxFruits] Auto Farm:", v)
    end,
})
Tab:CreateToggle({
    Name = "Auto Raid",
    CurrentValue = false,
    Flag = "AutoRaid",
    Callback = function(v)
        print("[BloxFruits] Auto Raid:", v)
    end,
})

Rayfield:LoadConfiguration()
Rayfield:Notify({ Title = "Blox Fruits", Content = "Script loaded!", Duration = 3 })
