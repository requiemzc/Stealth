-- [[ Universal ESP | Stealth script ]]
-- Works in any game. Replace this placeholder with your real ESP implementation.

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Stealth | Universal ESP",
    LoadingTitle = "Universal ESP",
    LoadingSubtitle = "by Stealth",
    ConfigurationSaving = { Enabled = true, FolderName = "Stealth", FileName = "UniversalESP" },
})

local Tab = Window:CreateTab("ESP", "eye")
Tab:CreateSection("Players")
Tab:CreateToggle({
    Name = "Player ESP",
    CurrentValue = false,
    Flag = "PlayerESP",
    Callback = function(v)
        print("[Universal] Player ESP:", v)
    end,
})
Tab:CreateToggle({
    Name = "Name Tags",
    CurrentValue = false,
    Flag = "NameTags",
    Callback = function(v)
        print("[Universal] Name Tags:", v)
    end,
})

Rayfield:LoadConfiguration()
Rayfield:Notify({ Title = "Universal ESP", Content = "Script loaded!", Duration = 3 })
