-- [[ Stealth | Chapter 1 (FARMHOUSE) ]]
--
-- Original: Ouroboros Hub @hidevin (ObsidianUltra)
-- Converted to Airflow for Stealth Hub.
-- Discord: discord.gg/hqE5drDHF7
--
-- GameId 10756011174 | PlaceId 108628039999641
------------------------------------------------------------
-- 1. Identity elevation (Airflow needs executor-level identity)
------------------------------------------------------------
local function _elevateIdentity()
    pcall(function() if setthreadidentity then setthreadidentity(8) end end)
    pcall(function() if setidentity then setidentity(8) end end)
    pcall(function() if syn and syn.set_thread_identity then syn.set_thread_identity(8) end end)
    pcall(function() if set_thread_context then set_thread_context(8) end end)
    pcall(function() if setcontext then setcontext(8) end end)
end
_elevateIdentity()
local _taskPatched = false
if not _taskPatched then
    pcall(function()
        if setreadonly then setreadonly(task, false) end
        if not isreadonly or not isreadonly(task) then
            local _origSpawn = task.spawn
            local _origDefer  = task.defer
            local _origDelay  = task.delay
            task.spawn = function(fn, ...)
                local args = { ... }
                return _origSpawn(function()
                    _elevateIdentity()
                    if type(fn) == "function" then
                        return fn(table.unpack or unpack, args)
                    end
                end)
            end
            task.defer = function(fn, ...)
                local args = { ... }
                return _origDefer(function()
                    _elevateIdentity()
                    if type(fn) == "function" then
                        return fn(table.unpack or unpack, args)
                    end
                end)
            end
            task.delay = function(time, fn, ...)
                local args = { ... }
                return _origDelay(time, function()
                    _elevateIdentity()
                    if type(fn) == "function" then
                        return fn(table.unpack or unpack, args)
                    end
                end)
            end
            _taskPatched = true
        end
    end)
end
if not _taskPatched and hookfunction then
    pcall(function()
        local _origSpawn = task.spawn
        local _origDefer  = task.defer
        local _origDelay  = task.delay
        hookfunction(_origSpawn, newcclosure(function(fn, ...)
            local args = { ... }
            return _origSpawn(function()
                _elevateIdentity()
                if type(fn) == "function" then
                    return fn(table.unpack or unpack, args)
                end
            end)
        end))
        hookfunction(_origDefer, newcclosure(function(fn, ...)
            local args = { ... }
            return _origDefer(function()
                _elevateIdentity()
                if type(fn) == "function" then
                    return fn(table.unpack or unpack, args)
                end
            end)
        end))
        hookfunction(_origDelay, newcclosure(function(time, fn, ...)
            local args = { ... }
            return _origDelay(time, function()
                _elevateIdentity()
                if type(fn) == "function" then
                    return fn(table.unpack or unpack, args)
                end
            end)
        end))
        _taskPatched = true
    end)
end
------------------------------------------------------------
-- 2. Load Airflow
------------------------------------------------------------
local Airflow = loadstring(game:HttpGet("https://raw.githubusercontent.com/PookiePepelsss/Airflow-UI/refs/heads/main/Source.luau"))()
_elevateIdentity()
------------------------------------------------------------
-- 3. State tables (mirror ObsidianUltra Toggles/Options pattern
--    so the automation logic reads Toggles.X.Value / Options.X.Value)
------------------------------------------------------------
Toggles = Airflow.Flags
local Options = {}
------------------------------------------------------------
-- 4. Services & game refs
------------------------------------------------------------
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer
local gameName = "Chapter 1 (FARMHOUSE)"
-- Replicated refs
local NeedleHaystack = ReplicatedStorage:WaitForChild("NeedleHaystack")
local Config = require(NeedleHaystack:WaitForChild("Config"))
local UpgradeConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Configs"):WaitForChild("UpgradeConfig"))
local BuyUpgrade = NeedleHaystack:WaitForChild("BuyUpgrade")
local BuyShopItem = NeedleHaystack:WaitForChild("BuyShopItem")
local PickHay = NeedleHaystack:WaitForChild("PickHay")
local PickDroppedHay = NeedleHaystack:WaitForChild("PickDroppedHay")
local SellHay = NeedleHaystack:WaitForChild("SellHay")
local CollectGem = NeedleHaystack:WaitForChild("CollectGem")
local DeployDrone = NeedleHaystack:WaitForChild("DeployDrone")
local PitchforkDig = NeedleHaystack:WaitForChild("PitchforkDig")
local TntAction = NeedleHaystack:WaitForChild("TntAction")
local VacuumAction = NeedleHaystack:WaitForChild("VacuumAction")
local NeedleHandIn = NeedleHaystack:WaitForChild("NeedleHandIn")
local BarnShop = Workspace:WaitForChild("BarnShop")
local DroppedHayFolder = Workspace:FindFirstChild("DroppedHay")
local GemsClientFolder = Workspace:FindFirstChild("GemsClient")
------------------------------------------------------------
-- 5. Create Airflow window
------------------------------------------------------------
local Window = Airflow:CreateWindow({
    Name = "Stealth",
    ConfigurationSaving = { Enabled = true, FolderName = "Stealth", FileName = "default" },
    Icon = "solar:shield-keyhole-bold-duotone",
    ToggleUIKeybind = "RightShift",
})

Airflow._window = Window
------------------------------------------------------------
-- 6. Helper to register toggle/slider/dropdown into Toggles/Options
------------------------------------------------------------
local function registerToggle(id, default)
    Toggles[id] = { Value = default }
end
local function registerOption(id, default)
    Options[id] = { Value = default }
end
------------------------------------------------------------
-- 7. Tabs
------------------------------------------------------------
local MainTab = Window:CreateTab({ Name = "Dashboard", Icon = "solar:widget-bold" })
local CollectingTab = Window:CreateTab({ Name = "Collecting", Icon = "solar:widget-bold" })
local SellingTab = Window:CreateTab({ Name = "Selling", Icon = "solar:widget-bold" })
local ToolsTab = Window:CreateTab({ Name = "Tools", Icon = "solar:widget-bold" })
local NeedleTab = Window:CreateTab({ Name = "Needle", Icon = "solar:widget-bold" })
local ShopTab = Window:CreateTab({ Name = "Shop", Icon = "solar:widget-bold" })
local UpgradesTab = Window:CreateTab({ Name = "Upgrades", Icon = "solar:widget-bold" })
local SettingsTab = Window:CreateTab({ Name = "Config", Icon = "solar:widget-bold" })
------------------------------------------------------------
-- 8. Helpers (from original script, unchanged)
------------------------------------------------------------
local function getCash()
    local ls = LocalPlayer:FindFirstChild("leaderstats")
    local cash = ls and ls:FindFirstChild("Cash")
    return cash and cash.Value or 0
end
local function getGems()
    return tonumber(LocalPlayer:GetAttribute("Gems")) or 0
end
local function getHayHeld()
    local v = LocalPlayer:GetAttribute("HayHeld")
    if v ~= nil then return tonumber(v) or 0 end
    return 0
end
local function getHayCapacity()
    return tonumber(LocalPlayer:GetAttribute("HayCapacity")) or 25
end
local function owns(attr) return LocalPlayer:GetAttribute(attr) == true end
local function findClosestHay()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local best, bestDist = nil, math.huge
    for _, inst in ipairs(Workspace:GetDescendants()) do
        if inst:GetAttribute("HayId") and inst:IsA("BasePart") and inst.Parent then
            local d = (inst.Position - hrp.Position).Magnitude
            if d < bestDist and d < 30 then
                bestDist = d
                best = inst
            end
        end
    end
    return best
end
local function getGrabCandidates(centerPart)
    local radius = tonumber(LocalPlayer:GetAttribute("HayGrabRadius")) or 0
    if radius <= 0 then return {} end
    local out = {}
    if not centerPart then return out end
    local cp = centerPart.Position
    for _, inst in ipairs(Workspace:GetDescendants()) do
        if inst ~= centerPart and inst:GetAttribute("HayId") and inst:IsA("BasePart") then
            if (inst.Position - cp).Magnitude <= radius + 1 then
                table.insert(out, inst:GetAttribute("HayId"))
                if #out >= 6 then break end
            end
        end
    end
    return out
end
local function findClosestDropped()
    if not DroppedHayFolder then DroppedHayFolder = Workspace:FindFirstChild("DroppedHay") end
    if not DroppedHayFolder then return nil end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local best, bestDist = nil, 28
    for _, m in ipairs(DroppedHayFolder:GetChildren()) do
        local part = m:IsA("BasePart") and m or m:FindFirstChildWhichIsA("BasePart")
        if part then
            local d = (part.Position - hrp.Position).Magnitude
            if d < bestDist then
                bestDist = d
                best = part.Parent:IsA("BasePart") and part.Parent or m
            end
        end
    end
    return best
end
local function findClosestGem()
    if not GemsClientFolder then GemsClientFolder = Workspace:FindFirstChild("GemsClient") end
    local root = GemsClientFolder or Workspace
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local best, bestDist, bestId = nil, 35, nil
    for _, mdl in ipairs(root:GetDescendants()) do
        if mdl:IsA("BasePart") and mdl:GetAttribute("GemId") then
            local d = (mdl.Position - hrp.Position).Magnitude
            if d < bestDist then
                bestDist = d
                best = mdl
                bestId = mdl:GetAttribute("GemId")
            end
        end
    end
    if best and bestId then return best, bestId end
    for _, mdl in ipairs(Workspace:GetDescendants()) do
        if mdl:GetAttribute("GemId") and mdl:IsA("BasePart") then
            local d = (mdl.Position - hrp.Position).Magnitude
            if d < bestDist then
                bestDist = d
                best = mdl
                bestId = mdl:GetAttribute("GemId")
            end
        end
    end
    if best then return best, bestId end
    return nil, nil
end
local function isBagFull()
    return getHayHeld() >= getHayCapacity()
end
local function getNearestSellPart()
    local CollectionService = game:GetService("CollectionService")
    local camPos = workspace.CurrentCamera and workspace.CurrentCamera.CFrame.Position or (LocalPlayer.Character and LocalPlayer.Character:GetPivot().Position or Vector3.new(0,0,0))
    local best, bestDist = nil, math.huge
    for _, part in ipairs(CollectionService:GetTagged(Config.SELL_PART_NAME)) do
        if part:IsA("BasePart") and part:IsDescendantOf(workspace) then
            local d = (part.Position - camPos).Magnitude
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local cd = (part.Position - hrp.Position).Magnitude
                d = math.min(d, cd)
            end
            if d < bestDist then
                bestDist = d
                best = part
            end
        end
    end
    if not best then
        for _, inst in ipairs(workspace.SellModel:GetDescendants()) do
            if inst.Name == "SellPart" and inst:IsA("BasePart") then
                return inst
            end
        end
    end
    return best
end
local function trySell()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local sellPart = getNearestSellPart()
    if hrp and sellPart then
        local dist = (hrp.Position - sellPart.Position).Magnitude
        if dist > 14 then
            local target = sellPart.CFrame + Vector3.new(0, 3, 2)
            hrp.CFrame = target
            if workspace.CurrentCamera then
                workspace.CurrentCamera.CFrame = CFrame.lookAt(workspace.CurrentCamera.CFrame.Position, sellPart.Position)
            end
            task.wait(0.25)
        else
            if workspace.CurrentCamera then
                pcall(function()
                    workspace.CurrentCamera.CFrame = CFrame.lookAt(workspace.CurrentCamera.CFrame.Position, sellPart.Position)
                end)
            end
            task.wait(0.05)
        end
    end
    local ok, err = pcall(function() SellHay:FireServer() end)
    if not ok then
        Airflow:Notify({Title="Sell Failed", Description=tostring(err), Time=2,
    Type = "Success"
})
    end
    task.spawn(function()
        local before = getHayHeld()
        task.wait(0.6)
        if before > 0 and getHayHeld() == before and hrp and sellPart then
            hrp.CFrame = sellPart.CFrame + Vector3.new(0, 4, 0)
            task.wait(0.2)
            pcall(function() SellHay:FireServer() end)
        end
    end)
    task.spawn(function()
        task.wait(1.0)
        local needReturn = false
        if Toggles.AutoPickHay and Toggles.AutoPickHay.Value and Toggles.AutoPickHay.Value then needReturn = true end
        if Toggles.AutoCollectDroppedHay and Toggles.AutoCollectDroppedHay.Value and Toggles.AutoCollectDroppedHay.Value then needReturn = true end
        if Toggles.AutoCollectGems and Toggles.AutoCollectGems.Value and Toggles.AutoCollectGems.Value then needReturn = true end
        if Toggles.AutoVacuumCollect and Toggles.AutoVacuumCollect.Value and Toggles.AutoVacuumCollect.Value then needReturn = true end
        if Toggles.AutoVacuum and Toggles.AutoVacuum.Value and Toggles.AutoVacuum.Value then needReturn = true end
        if Toggles.AutoUsePitchfork and Toggles.AutoUsePitchfork.Value and Toggles.AutoUsePitchfork.Value then needReturn = true end
        if Toggles.AutoFindNeedle and Toggles.AutoFindNeedle.Value and Toggles.AutoFindNeedle.Value then needReturn = true end
        if needReturn and getHayHeld() == 0 then
            local pile = Config.PILE_CENTER
            local hrp2 = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp2 and (hrp2.Position - pile).Magnitude > 22 then
                hrp2.CFrame = CFrame.new(pile + Vector3.new(math.random(-2,2), 5, math.random(-2,2)))
                if workspace.CurrentCamera then
                    workspace.CurrentCamera.CFrame = CFrame.new(hrp2.Position + Vector3.new(0,4,0), pile)
                end
            end
        end
    end)
end
------------------------------------------------------------
-- 9. MAIN TAB
------------------------------------------------------------
MainTab:CreateSection("Dashboard")
MainTab:CreateSection("Game: ")
MainTab:CreateSection("Hub: Stealth")
MainTab:CreateSection("Toggle UI: RightShift or floating button")
MainTab:CreateSection("Session")
local sessionLabel
MainTab:CreateSection("0s elapsed")
task.spawn(function()
    local s=0
    while true do
        task.wait(1)
        if Airflow.Unloaded then break end
        s+=1
        -- Airflow sections are static; we can't update text in place easily.
        -- Skip live session update (would need a label element with :SetText).
    end
end)
MainTab:CreateSection("Discord")
MainTab:CreateButton({ Name = "Copy Discord",
    Desc = "discord.gg/hqE5drDHF7",
    Color = Color3.fromHex("#5865F2"),
    Justify = "Left",
    IconAlign = "Left",
    Callback = function()
        pcall(function() setclipboard("https://discord.gg/hqE5drDHF7") end)
        Airflow:Notify({
            Title = "Discord",
            Content = "Invite copied to clipboard!",
            Duration = 3,
    Type = "Success"
})
    end
})

MainTab:CreateSection("Status")
MainTab:CreateSection("Farming & Inventory tabs hold all automation.")
MainTab:CreateSection("Settings holds Config & Anti-AFK.")
------------------------------------------------------------
-- 10. COLLECTING TAB
------------------------------------------------------------
CollectingTab:CreateSection("Resource Collecting")
registerToggle("AutoPickHay", false)
CollectingTab:CreateToggle({ Name = "Auto Pick Hay", Desc = "Pick hay from stack continuously",
    CurrentValue = false,
    Callback = function(v) Toggles.AutoPickHay.Value = v end
 })
registerToggle("AutoCollectDroppedHay", false)
CollectingTab:CreateToggle({ Name = "Auto Collect Dropped Hay", CurrentValue = false,
    Callback = function(v) Toggles.AutoCollectDroppedHay.Value = v end
 })
registerToggle("AutoCollectGems", false)
CollectingTab:CreateToggle({ Name = "Auto Collect Gems", CurrentValue = false,
    Callback = function(v) Toggles.AutoCollectGems.Value = v end
 })
registerToggle("AutoVacuumCollect", false)
CollectingTab:CreateToggle({ Name = "Auto Vacuum Collect", Desc = "Uses Vacuum Start/Stop (requires Vacuum tool)",
    CurrentValue = false,
    Callback = function(v) Toggles.AutoVacuumCollect.Value = v end
 })
registerOption("CollectInterval", 1)
CollectingTab:CreateSlider({ 
    Name = "Loop Interval",
    Range = { 0.1, 3 },
    CurrentValue = 1,
    Rounding = 1,
    Suffix = "s",
    Callback = function(v) Options.CollectInterval.CurrentValue = v end
})

CollectingTab:CreateSection("Vacuum needs VacuumOwned. Gems within 35 studs.")
------------------------------------------------------------
-- 11. SELLING TAB
------------------------------------------------------------
SellingTab:CreateSection("Selling")
registerToggle("AutoSellHay", false)
SellingTab:CreateToggle({ Name = "Auto Sell Hay", CurrentValue = false,
    Callback = function(v) Toggles.AutoSellHay.Value = v end
 })
registerOption("SellThreshold", 25)
SellingTab:CreateSlider({
    Name = "Sell When Hay >=",
    Range = { 1, 250 }, CurrentValue = 25,
    Rounding = 0,
    Callback = function(v) Options.SellThreshold.Value = v end

})
registerToggle("SellOnlyIfFull", false)
SellingTab:CreateToggle({ Name = "Only Sell If Full", CurrentValue = false,
    Callback = function(v) Toggles.SellOnlyIfFull.Value = v end
 })
SellingTab:CreateSection("Fires SellHay:FireServer() near cow.")
SellingTab:CreateSection("VacuumLoad also counts as held.")
------------------------------------------------------------
-- 12. TOOLS TAB
------------------------------------------------------------
ToolsTab:CreateSection("Auto Tool Usage")
registerToggle("AutoUseTNT", false)
ToolsTab:CreateToggle({ Name = "Auto Use TNT", Desc = "Light & throw TNT on cooldown",
    CurrentValue = false,
    Callback = function(v) Toggles.AutoUseTNT.Value = v end
 })
registerToggle("AutoUsePitchfork", false)
ToolsTab:CreateToggle({ Name = "Auto Use Pitchfork", CurrentValue = false,
    Callback = function(v) Toggles.AutoUsePitchfork.Value = v end
 })
registerToggle("AutoDeployDrone", false)
ToolsTab:CreateToggle({ Name = "Auto Deploy Drone", CurrentValue = false,
    Callback = function(v) Toggles.AutoDeployDrone.Value = v end
 })
registerToggle("AutoVacuum", false)
ToolsTab:CreateToggle({ Name = "Auto Vacuum (Loop)", CurrentValue = false,
    Callback = function(v) Toggles.AutoVacuum.Value = v end
 })
registerOption("ToolInterval", 1)
ToolsTab:CreateSlider({ 
    Name = "Tool Interval",
    Range = { 0.2, 5 },
    CurrentValue = 1,
    Rounding = 1,
    Suffix = "s",
    Callback = function(v) Options.ToolInterval.CurrentValue = v end

})
ToolsTab:CreateSection("Requirements")
ToolsTab:CreateSection("PitchforkOwned, TntOwned, DroneOwned, VacuumOwned required per tool.")
ToolsTab:CreateSection("TNT cooldown & vacuum heat managed by server.")
------------------------------------------------------------
-- 13. NEEDLE TAB
------------------------------------------------------------
NeedleTab:CreateSection("Needle")
registerToggle("AutoFindNeedle", false)
NeedleTab:CreateToggle({ Name = "Auto Find Needle", Desc = "Continuously pick around pile center to reveal needle",
    CurrentValue = false,
    Callback = function(v) Toggles.AutoFindNeedle.Value = v end
 })
registerToggle("AutoHandInNeedle", false)
NeedleTab:CreateToggle({ Name = "Auto Hand In Needle", Desc = "Fires NeedleHandIn when near NPC",
    CurrentValue = false,
    Callback = function(v) Toggles.AutoHandInNeedle.Value = v end
 })
registerOption("NeedleInterval", 1)
NeedleTab:CreateSlider({ 
    Name = "Needle Interval",
    Range = { 0.2, 3 },
    CurrentValue = 1,
    Rounding = 1,
    Suffix = "s",
    Callback = function(v) Options.NeedleInterval.CurrentValue = v end

})
NeedleTab:CreateSection("How Needle Works")
NeedleTab:CreateSection("Needle spawns under hay. Removing hay reveals it.")
NeedleTab:CreateSection("Pile center from Config.PILE_CENTER used for automation.")
------------------------------------------------------------
-- 14. SHOP TAB
------------------------------------------------------------
ShopTab:CreateSection("Purchasing")
registerOption("BuyToolsList", {})
ShopTab:CreateDropdown({
    Name = "Buy Tools Selection",
    Options = { "Pitchfork", "TNT", "Drone", "Vacuum", "Infinite Bag", "Capacity Bag" },
    MultipleOptions = true,
    Default = {},
    Callback = function(v)
        -- Airflow returns a table for multi-select
        Options.BuyToolsList.Value = v or {}
    end

})
registerToggle("AutoBuyTools", false)
ShopTab:CreateToggle({ Name = "Auto Buy Selected Tools", CurrentValue = false,
    Callback = function(v) Toggles.AutoBuyTools.Value = v end
 })
registerOption("BuyInterval", 1)
ShopTab:CreateSlider({ 
    Name = "Buy Interval",
    Range = { 0.5, 5 },
    CurrentValue = 1,
    Rounding = 1,
    Suffix = "s",
    Callback = function(v) Options.BuyInterval.CurrentValue = v end

})
ShopTab:CreateSection("Ownership")
ShopTab:CreateSection("Attributes: PitchforkOwned, TntOwned, DroneOwned, VacuumOwned, InfiniteBagOwned")
ShopTab:CreateButton({ Name = "Check Ownership",
    Color = Color3.fromHex("#30FF6A"),
    Justify = "Left",
    IconAlign = "Left",
    Callback = function()
        local t = {}
        for _,k in ipairs({"PitchforkOwned","TntOwned","DroneOwned","VacuumOwned","InfiniteBagOwned","HayUpgradeCapacity"}) do
            table.insert(t, k..": "..tostring(LocalPlayer:GetAttribute(k)))
        end
        Airflow:Notify({Title ="Ownership", Description=table.concat(t,"\n"), Time=4,
    Type = "Success"
})
    end

------------------------------------------------------------
-- 15. UPGRADES TAB
------------------------------------------------------------
})
UpgradesTab:CreateSection("Permanent (Gems)")
registerToggle("UpgBagSize", false)
UpgradesTab:CreateToggle({ Name = "Auto Upgrade Bag Size", Desc = "ExtraHoldAmount -> Gems 25,50,75,100,150,450",
    CurrentValue = false,
    Callback = function(v) Toggles.UpgBagSize.Value = v end
 })
registerToggle("UpgExtraTake", false)
UpgradesTab:CreateToggle({ Name = "Auto Upgrade Hand Grab Amount", CurrentValue = false,
    Callback = function(v) Toggles.UpgExtraTake.Value = v end
 })
registerToggle("UpgGemValue", false)
UpgradesTab:CreateToggle({ Name = "Auto Upgrade Gem Value", CurrentValue = false,
    Callback = function(v) Toggles.UpgGemValue.Value = v end
 })
registerToggle("UpgHayValue", false)
UpgradesTab:CreateToggle({ Name = "Auto Upgrade Hay Value", CurrentValue = false,
    Callback = function(v) Toggles.UpgHayValue.Value = v end
 })
registerOption("PermInterval", 1)
UpgradesTab:CreateSlider({ 
    Name = "Permanent Loop",
    Range = { 0.5, 5 },
    CurrentValue = 1,
    Rounding = 1,
    Suffix = "s",
    Callback = function(v) Options.PermInterval.CurrentValue = v end

})
UpgradesTab:CreateSection("Hand Upgrades (Cash)")
registerToggle("UpgHandSpeed", false)
UpgradesTab:CreateToggle({ Name = "Auto Hand Speed", Desc = "Speed track 0.55->0.3", CurrentValue = false, Callback = function(v) Toggles.UpgHandSpeed.Value = v end })
registerToggle("UpgHandGrab", false)
UpgradesTab:CreateToggle({ Name = "Auto Hand Grasp", CurrentValue = false, Callback = function(v) Toggles.UpgHandGrab.Value = v end })
registerToggle("UpgHandHold", false)
UpgradesTab:CreateToggle({ Name = "Auto Hand Hold", CurrentValue = false, Callback = function(v) Toggles.UpgHandHold.Value = v end })
UpgradesTab:CreateSection("TNT Upgrades")
registerToggle("UpgTntLuck", false)
UpgradesTab:CreateToggle({ Name = "Auto TNT Lucky Blast", CurrentValue = false, Callback = function(v) Toggles.UpgTntLuck.Value = v end })
registerToggle("UpgTntCooldown", false)
UpgradesTab:CreateToggle({ Name = "Auto TNT Cooldown", CurrentValue = false, Callback = function(v) Toggles.UpgTntCooldown.Value = v end })
registerToggle("UpgTntPower", false)
UpgradesTab:CreateToggle({ Name = "Auto TNT Power", CurrentValue = false, Callback = function(v) Toggles.UpgTntPower.Value = v end })
UpgradesTab:CreateSection("Pitchfork Upgrades")
registerToggle("UpgPitchCooldown", false)
UpgradesTab:CreateToggle({ Name = "Auto Pitchfork Cooldown", CurrentValue = false, Callback = function(v) Toggles.UpgPitchCooldown.Value = v end })
registerToggle("UpgPitchHold", false)
UpgradesTab:CreateToggle({ Name = "Auto Pitchfork Hold", CurrentValue = false, Callback = function(v) Toggles.UpgPitchHold.Value = v end })
registerToggle("UpgPitchSweep", false)
UpgradesTab:CreateToggle({ Name = "Auto Pitchfork Sweep", CurrentValue = false, Callback = function(v) Toggles.UpgPitchSweep.Value = v end })
UpgradesTab:CreateSection("Drone Upgrades")
registerToggle("UpgDroneSpeed", false)
UpgradesTab:CreateToggle({ Name = "Auto Drone Speed", CurrentValue = false, Callback = function(v) Toggles.UpgDroneSpeed.Value = v end })
registerToggle("UpgDroneGrab", false)
UpgradesTab:CreateToggle({ Name = "Auto Drone Grasp", CurrentValue = false, Callback = function(v) Toggles.UpgDroneGrab.Value = v end })
registerToggle("UpgDroneCapacity", false)
UpgradesTab:CreateToggle({ Name = "Auto Drone Capacity", CurrentValue = false, Callback = function(v) Toggles.UpgDroneCapacity.Value = v end })
UpgradesTab:CreateSection("Vacuum Upgrades")
registerToggle("UpgVacPower", false)
UpgradesTab:CreateToggle({ Name = "Auto Vacuum Power", CurrentValue = false, Callback = function(v) Toggles.UpgVacPower.Value = v end })
registerToggle("UpgVacCooling", false)
UpgradesTab:CreateToggle({ Name = "Auto Vacuum Cooling", CurrentValue = false, Callback = function(v) Toggles.UpgVacCooling.Value = v end })
registerToggle("UpgVacRuntime", false)
UpgradesTab:CreateToggle({ Name = "Auto Vacuum Runtime", CurrentValue = false, Callback = function(v) Toggles.UpgVacRuntime.Value = v end })
UpgradesTab:CreateSection("Capacity")
registerToggle("UpgCapacity", false)
UpgradesTab:CreateToggle({ Name = "Auto Upgrade Carry Capacity", Desc = "25->250 cash upgrades",
    CurrentValue = false,
    Callback = function(v) Toggles.UpgCapacity.Value = v end
 })
UpgradesTab:CreateSection("Cash upgrades use BuyUpgrade with track names.")
------------------------------------------------------------
-- 16. SETTINGS TAB
------------------------------------------------------------
SettingsTab:CreateSection("Menu")
SettingsTab:CreateButton({ Name = "Unload Stealth",
    Desc = "Closes the UI and stops all automation.",
    Color = Color3.fromHex("#ff4830"),
    Justify = "Left",
    IconAlign = "Left",
    Callback = function()
        Window:Destroy()
    end

})
SettingsTab:CreateSection("System")
registerToggle("AntiAFK", true)
SettingsTab:CreateToggle({ Name = "Anti-AFK (jump every 5m)", Desc = "Enabled by default. Uses jump to keep alive.",
    CurrentValue = true,
    Callback = function(v) Toggles.AntiAFK.Value = v end
 })
------------------------------------------------------------
-- 17. Automation Logic (unchanged from original)
------------------------------------------------------------
local function waitInterval(optName, fallback)
    local v = Options[optName] and Options[optName].Value or fallback
    return tonumber(v) or fallback
end
local function ensureNearPileForPick()
    local pile = Config.PILE_CENTER
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local distToPile = (hrp.Position - pile).Magnitude
    if distToPile > 28 then
        hrp.CFrame = CFrame.new(pile + Vector3.new(math.random(-3,3), 5, math.random(-3,3)))
        if workspace.CurrentCamera then
            workspace.CurrentCamera.CFrame = CFrame.new(hrp.Position + Vector3.new(0,4,0), pile)
        end
        task.wait(0.25)
    end
end
local function teleportToPart(part, yOffset)
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp or not part then return end
    local dist = (hrp.Position - part.Position).Magnitude
    if dist > 15 then
        hrp.CFrame = part.CFrame + Vector3.new(0, yOffset or 4, 1.5)
        if workspace.CurrentCamera then
            pcall(function() workspace.CurrentCamera.CFrame = CFrame.lookAt(workspace.CurrentCamera.CFrame.Position, part.Position) end)
        end
        task.wait(0.18)
    else
        if workspace.CurrentCamera then
            pcall(function() workspace.CurrentCamera.CFrame = CFrame.lookAt(workspace.CurrentCamera.CFrame.Position, part.Position) end)
        end
    end
end
-- Auto Pick Hay
task.spawn(function()
    while true do
        task.wait(waitInterval("CollectInterval",1))
        if Airflow.Unloaded then break end
        if Toggles.AutoPickHay and Toggles.AutoPickHay.Value and Toggles.AutoPickHay.Value then
            if not isBagFull() then
                local hay = findClosestHay()
                if not hay then
                    ensureNearPileForPick()
                    hay = findClosestHay()
                end
                if hay then
                    teleportToPart(hay, 4)
                    local id = hay:GetAttribute("HayId")
                    if id then
                        local candidates = getGrabCandidates(hay)
                        pcall(function() PickHay:FireServer(id, candidates) end)
                    else
                        pcall(function() PickDroppedHay:FireServer(hay) end)
                    end
                else
                    ensureNearPileForPick()
                end
            end
        end
    end
end)
-- Auto Collect Dropped Hay
task.spawn(function()
    while true do
        task.wait(waitInterval("CollectInterval",1))
        if Airflow.Unloaded then break end
        if Toggles.AutoCollectDroppedHay and Toggles.AutoCollectDroppedHay.Value and Toggles.AutoCollectDroppedHay.Value then
            if not isBagFull() then
                local d = findClosestDropped()
                if not d then
                    ensureNearPileForPick()
                    d = findClosestDropped()
                end
                if d then
                    local part = d:IsA("BasePart") and d or d:FindFirstChildWhichIsA("BasePart")
                    if part then teleportToPart(part, 3) end
                    pcall(function() PickDroppedHay:FireServer(d) end)
                end
            end
        end
    end
end)
-- Auto Collect Gems
task.spawn(function()
    while true do
        task.wait(waitInterval("CollectInterval",1))
        if Airflow.Unloaded then break end
        if Toggles.AutoCollectGems and Toggles.AutoCollectGems.Value and Toggles.AutoCollectGems.Value then
            local gemPart, id = findClosestGem()
            if not gemPart then
                ensureNearPileForPick()
                gemPart, id = findClosestGem()
            end
            if gemPart and id then
                teleportToPart(gemPart, 3)
                pcall(function() CollectGem:FireServer(id) end)
            end
        end
    end
end)
-- Auto Sell
task.spawn(function()
    while true do
        task.wait(1)
        if Airflow.Unloaded then break end
        if Toggles.AutoSellHay and Toggles.AutoSellHay.Value and Toggles.AutoSellHay.Value then
            local held = getHayHeld()
            local thresh = Options.SellThreshold and Options.SellThreshold.Value or 25
            local onlyFull = Toggles.SellOnlyIfFull and Toggles.SellOnlyIfFull.Value and Toggles.SellOnlyIfFull.Value
            local should = false
            if onlyFull then should = isBagFull()
            else should = held >= thresh end
            if should and held > 0 then trySell() end
        end
    end
end)
-- Vacuum collect loop
do
    local vacActive = false
    task.spawn(function()
        while true do
            task.wait(waitInterval("CollectInterval",1))
            if Airflow.Unloaded then break end
            local want = Toggles.AutoVacuumCollect and Toggles.AutoVacuumCollect.Value and Toggles.AutoVacuumCollect.Value
            local want2 = Toggles.AutoVacuum and Toggles.AutoVacuum.Value and Toggles.AutoVacuum.Value
            local should = want or want2
            if should and owns("VacuumOwned") then
                if not vacActive and not isBagFull() then
                    local hay = findClosestHay()
                    if not hay then ensureNearPileForPick() hay = findClosestHay() end
                    if hay then teleportToPart(hay, 5) end
                    pcall(function() VacuumAction:FireServer("Start") end)
                    vacActive = true
                elseif isBagFull() and vacActive then
                    pcall(function() VacuumAction:FireServer("Stop") end)
                    vacActive = false
                    trySell()
                end
            else
                if vacActive then pcall(function() VacuumAction:FireServer("Stop") end) vacActive=false end
            end
            if vacActive and LocalPlayer:GetAttribute("VacuumOverheated") then
                pcall(function() VacuumAction:FireServer("Stop") end) vacActive=false
                task.wait(0.5)
                ensureNearPileForPick()
            end
        end
    end)
end
-- Auto Use TNT
task.spawn(function()
    while true do
        task.wait(waitInterval("ToolInterval",1))
        if Airflow.Unloaded then break end
        if Toggles.AutoUseTNT and Toggles.AutoUseTNT.Value and Toggles.AutoUseTNT.Value and owns("TntOwned") then
            local ok = not LocalPlayer:GetAttribute("NeedleInputLocked")
            if ok then
                pcall(function() TntAction:FireServer("light") end)
                task.wait(0.4)
                local cam = Workspace.CurrentCamera
                if cam then
                    local dir = cam.CFrame.LookVector * 40 + Vector3.new(0,8,0)
                    local cf = cam.CFrame
                    pcall(function() TntAction:FireServer("throw", cf, dir) end)
                end
            end
        end
    end
end)
-- Auto Use Pitchfork
task.spawn(function()
    while true do
        task.wait(waitInterval("ToolInterval",1))
        if Airflow.Unloaded then break end
        if Toggles.AutoUsePitchfork and Toggles.AutoUsePitchfork.Value and Toggles.AutoUsePitchfork.Value and owns("PitchforkOwned") then
            local hay = findClosestHay()
            if not hay then ensureNearPileForPick() hay = findClosestHay() end
            if hay then teleportToPart(hay, 4) end
            local id = hay and hay:GetAttribute("HayId")
            if id then
                pcall(function() PitchforkDig:FireServer(id) end)
            else
                local fakeId = LocalPlayer:GetAttribute("HoveredHayId")
                if fakeId then
                    ensureNearPileForPick()
                    pcall(function() PitchforkDig:FireServer(fakeId) end)
                end
            end
        end
    end
end)
-- Auto Deploy Drone
task.spawn(function()
    while true do
        task.wait(waitInterval("ToolInterval",1))
        if Airflow.Unloaded then break end
        if Toggles.AutoDeployDrone and Toggles.AutoDeployDrone.Value and Toggles.AutoDeployDrone.Value and owns("DroneOwned") then
            if not LocalPlayer:GetAttribute("DroneDeployed") then
                pcall(function() DeployDrone:FireServer() end)
            end
        end
    end
end)
-- Needle loops
task.spawn(function()
    while true do
        task.wait(waitInterval("NeedleInterval",1))
        if Airflow.Unloaded then break end
        if Toggles.AutoFindNeedle and Toggles.AutoFindNeedle.Value and Toggles.AutoFindNeedle.Value then
            if not LocalPlayer:GetAttribute("NeedleRoundComplete") then
                local hay = findClosestHay()
                if not hay then ensureNearPileForPick() hay = findClosestHay() end
                if hay then
                    teleportToPart(hay, 4)
                    local id = hay:GetAttribute("HayId")
                    if id and not isBagFull() then
                        pcall(function() PickHay:FireServer(id, getGrabCandidates(hay)) end)
                    elseif isBagFull() then
                        trySell()
                    end
                else
                    ensureNearPileForPick()
                end
            end
        end
        if Toggles.AutoHandInNeedle and Toggles.AutoHandInNeedle.Value and Toggles.AutoHandInNeedle.Value then
            local farmer = workspace:FindFirstChild("NPC") and workspace.NPC:FindFirstChild("Farmer_NPC")
            if farmer and farmer:GetPivot() then
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp and (hrp.Position - farmer:GetPivot().Position).Magnitude > 20 then
                    hrp.CFrame = farmer:GetPivot() * CFrame.new(0,0,4)
                    task.wait(0.2)
                end
            end
            pcall(function() NeedleHandIn:FireServer() end)
        end
    end
end)
-- Auto Buy Tools
task.spawn(function()
    while true do
        task.wait(waitInterval("BuyInterval",1))
        if Airflow.Unloaded then break end
        if Toggles.AutoBuyTools and Toggles.AutoBuyTools.Value and Toggles.AutoBuyTools.Value then
            local sel = Options.BuyToolsList and Options.BuyToolsList.Value or {}
            local list = {}
            if typeof(sel) == "table" then
                for k,v in pairs(sel) do if v then table.insert(list, k) end end
                if #list==0 then for _,v in ipairs(sel) do table.insert(list, v) end end
            end
            for _, name in ipairs(list) do
                if name == "Pitchfork" and not owns("PitchforkOwned") then pcall(function() BuyShopItem:FireServer("Pitchfork") end)
                elseif name == "TNT" and not owns("TntOwned") then pcall(function() BuyShopItem:FireServer("Tnt") end)
                elseif name == "Drone" and not owns("DroneOwned") then pcall(function() BuyShopItem:FireServer("Drone") end)
                elseif name == "Vacuum" and not owns("VacuumOwned") then pcall(function() BuyShopItem:FireServer("Vacuum") end)
                elseif name == "Infinite Bag" and not owns("InfiniteBagOwned") then pcall(function() BuyShopItem:FireServer("InfiniteBag") end)
                elseif name == "Capacity Bag" then
                    local st = tonumber(LocalPlayer:GetAttribute("HayUpgradeCapacity")) or 1
                    local track = Config.UPGRADE_TRACKS["Capacity"]
                    if track and st < #track.Levels then
                        local cost = track.Levels[st+1].Cost
                        if getCash() >= (cost or 0) then pcall(function() BuyUpgrade:FireServer("Capacity") end) end
                    end
                end
            end
        end
    end
end)
-- Upgrade helpers
local function tryBuyTrack(trackName)
    local track = Config.UPGRADE_TRACKS[trackName]
    if not track then return end
    local cur = tonumber(LocalPlayer:GetAttribute("HayUpgrade"..trackName)) or 1
    if cur >= #track.Levels then return end
    local nxt = track.Levels[cur+1]
    if not nxt then return end
    local cost = nxt.Cost or 0
    if getCash() >= cost then
        pcall(function() BuyUpgrade:FireServer(trackName) end)
    end
end
local function tryBuyPermanent(id)
    local u = UpgradeConfig.getUpgrade(id)
    if not u then return end
    local cur = tonumber(LocalPlayer:GetAttribute("Upgrade"..id)) or 0
    local max = UpgradeConfig.getMaxLevel(u)
    if cur >= max then return end
    local price = UpgradeConfig.getPrice(u, cur)
    if price and getGems() >= price then
        pcall(function() BuyUpgrade:FireServer(id) end)
    end
end
-- Permanent upgrades loop
task.spawn(function()
    while true do
        task.wait(waitInterval("PermInterval",1))
        if Airflow.Unloaded then break end
        if Toggles.UpgBagSize and Toggles.UpgBagSize.Value and Toggles.UpgBagSize.Value then tryBuyPermanent("ExtraHoldAmount") end
        if Toggles.UpgExtraTake and Toggles.UpgExtraTake.Value and Toggles.UpgExtraTake.Value then tryBuyPermanent("ExtraTakeAmount") end
        if Toggles.UpgGemValue and Toggles.UpgGemValue.Value and Toggles.UpgGemValue.Value then tryBuyPermanent("GemValue") end
        if Toggles.UpgHayValue and Toggles.UpgHayValue.Value and Toggles.UpgHayValue.Value then tryBuyPermanent("ExtraHayValuePercentage") end
    end
end)
-- Session upgrades loop
task.spawn(function()
    while true do
        task.wait(1.2)
        if Airflow.Unloaded then break end
        if Toggles.UpgCapacity and Toggles.UpgCapacity.Value and Toggles.UpgCapacity.Value then tryBuyTrack("Capacity") end
        if Toggles.UpgHandSpeed and Toggles.UpgHandSpeed.Value and Toggles.UpgHandSpeed.Value then tryBuyTrack("Speed") end
        if Toggles["UpgHandGrab"] and Toggles["UpgHandGrab"].Value then
            tryBuyTrack("Grab")
        end
        if Toggles.UpgHandHold and Toggles.UpgHandHold.Value and Toggles.UpgHandHold.Value then tryBuyTrack("HandHold") end
        if Toggles.UpgTntLuck and Toggles.UpgTntLuck.Value and Toggles.UpgTntLuck.Value then tryBuyTrack("TntLuck") end
        if Toggles.UpgTntCooldown and Toggles.UpgTntCooldown.Value and Toggles.UpgTntCooldown.Value then tryBuyTrack("TntCooldown") end
        if Toggles.UpgTntPower and Toggles.UpgTntPower.Value and Toggles.UpgTntPower.Value then tryBuyTrack("TntPower") end
        if Toggles.UpgPitchCooldown and Toggles.UpgPitchCooldown.Value and Toggles.UpgPitchCooldown.Value then tryBuyTrack("PitchforkCooldown") end
        if Toggles.UpgPitchHold and Toggles.UpgPitchHold.Value and Toggles.UpgPitchHold.Value then tryBuyTrack("PitchforkHold") end
        if Toggles.UpgPitchSweep and Toggles.UpgPitchSweep.Value and Toggles.UpgPitchSweep.Value then tryBuyTrack("Pitchfork") end
        if Toggles.UpgDroneSpeed and Toggles.UpgDroneSpeed.Value and Toggles.UpgDroneSpeed.Value then tryBuyTrack("DroneSpeed") end
        if Toggles.UpgDroneGrab and Toggles.UpgDroneGrab.Value and Toggles.UpgDroneGrab.Value then tryBuyTrack("DroneGrab") end
        if Toggles.UpgDroneCapacity and Toggles.UpgDroneCapacity.Value and Toggles.UpgDroneCapacity.Value then tryBuyTrack("DroneCapacity") end
        if Toggles.UpgVacPower and Toggles.UpgVacPower.Value and Toggles.UpgVacPower.Value then tryBuyTrack("VacuumPower") end
        if Toggles.UpgVacCooling and Toggles.UpgVacCooling.Value and Toggles.UpgVacCooling.Value then tryBuyTrack("VacuumCooling") end
        if Toggles.UpgVacRuntime and Toggles.UpgVacRuntime.Value and Toggles.UpgVacRuntime.Value then tryBuyTrack("VacuumRuntime") end
    end
end)
-- Anti-AFK
task.spawn(function()
    while true do
        task.wait(300)
        if Airflow.Unloaded then break end
        if Toggles.AntiAFK and Toggles.AntiAFK.Value and Toggles.AntiAFK.Value then
            pcall(function()
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) hum.Jump = true end
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end
    end
end)
-- Safety: unload clean
Airflow:OnUnload(function()
    pcall(function() VacuumAction:FireServer("Stop") end)
    print("[Stealth] Unloaded - "..gameName)
end)
Airflow:Notify({
    Title = "Stealth",
    Description = gameName .. " loaded. Farming=collect/sell/tools | Inventory=shop/upgrades",
    Time = 5,
    Type = "Success"
})
print("[Stealth] Loaded "..gameName.." via Airflow")
