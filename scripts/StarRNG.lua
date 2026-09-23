-- [[ Stealth | Star RNG ]]
--
-- Original: Star RNG by @hidevin (ObsidianUltra / Linoria-based)
-- Converted to Library for Stealth Hub.
-- Discord: discord.gg/hqE5drDHF7
--
-- Game: Star RNG
------------------------------------------------------------
-- 1. Identity elevation (Library needs executor-level identity)
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
------------------------------------------------------------
-- 2. Load Library
------------------------------------------------------------
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Naellx/ObsidianUltra/main/Library.lua"))()
end
if not Library then warn("[Stealth] Failed to load Library UI") return end
_elevateIdentity()
------------------------------------------------------------
-- 3. Services & state
------------------------------------------------------------
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer
local gameName = "Star RNG"
pcall(function()
    local info = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
    if info and info.Name then gameName = info.Name end
end)
local Unloaded = false
local Toggles = {}
local Options = {}
------------------------------------------------------------
-- 4. Data
------------------------------------------------------------
local RARITIES = {"Common","Uncommon","Rare","Epic","Legendary","Mythic","Exotic","Radiant","Secret","Exalted","Divine","Eternal","Transcendent","Absolute"}
local RARITY_ORDER = {}
for i, r in ipairs(RARITIES) do RARITY_ORDER[r] = i end
local MUTATION_IDS = {"SyringeNeedle","MoonNeedle","CometNeedle","PlanetNeedle","AlienNeedle","GalaxyNeedle","BlackholeNeedle"}
local EGG_NAMES = {"Starlight Egg","Orbit Egg","Nebula Egg","Cosmic Egg","Eclipse Egg","Celestial Egg","Mythic Egg","Apex Egg"}
local GEAR_IDS = {"Energizer","Overloader","Supercharger","Turbocharger"}
------------------------------------------------------------
-- 5. Helper functions (from original)
------------------------------------------------------------
local function GetOwnArea()
    local map = Workspace:FindFirstChild("RollForStarsMap")
    if not map then return nil end
    for _, v in ipairs(map:GetChildren()) do
        if v.Name:match("^PlayerArea_%d+$") then
            local o = v:FindFirstChild("Owner")
            if o and o.Value == LocalPlayer then return v end
        end
    end
    return nil
end
local function GetRollPrompt()
    local area = GetOwnArea()
    if not area then return nil end
    local roller = area:FindFirstChild("Roller")
    local lever = roller and roller:FindFirstChild("LeverAssembly")
    local anchor = lever and lever:FindFirstChild("RollPromptAnchor")
    local p = anchor and anchor:FindFirstChildOfClass("ProximityPrompt")
    return p
end
local function GetTrashPrompt()
    local area = GetOwnArea()
    if not area then return nil end
    local d = area:FindFirstChild("Dumpster")
    d = d and d:FindFirstChild("Dumpster")
    if d then return d:FindFirstChild("TrashPrompt") end
    return nil
end
local function GetCollectTrigger()
    local area = GetOwnArea()
    if not area then return nil end
    local c = area:FindFirstChild("Collector")
    if c then return c:FindFirstChild("CollectTrigger") end
    return nil
end
local function GetOwnRollingStars()
    local out = {}
    local area = GetOwnArea()
    if not area then return out end
    for _, d in ipairs(area:GetDescendants()) do
        if d:IsA("ProximityPrompt") and d.Parent and d.Parent.Name == "RollingStar" then
            table.insert(out, {Prompt = d, Star = d.Parent})
        end
    end
    return out
end
local function GetEmptyAltars()
    local out = {}
    local area = GetOwnArea()
    if not area then return out end
    local rm = area:FindFirstChild("RegionMarker")
    local altars = rm and rm:FindFirstChild("Altars")
    if not altars then return out end
    for _, a in ipairs(altars:GetChildren()) do
        if a:IsA("Model") and a:FindFirstChild("DepositedStar", true) == nil then
            table.insert(out, a)
        end
    end
    return out
end
local function FireRemote(name, a, b)
    local r
    local ok = pcall(function() r = ReplicatedStorage:WaitForChild(name, 5) end)
    if not ok or not r then return end
    if a == nil then
        pcall(function() r:FireServer() end)
    elseif b == nil then
        pcall(function() r:FireServer(a) end)
    else
        pcall(function() r:FireServer(a, b) end)
    end
end
local function FirePrompt(p)
    if p ~= nil and p.Parent ~= nil then
        pcall(function() fireproximityprompt(p) end)
    end
end
local function DoPromptNear(prompt, holdWait)
    if prompt == nil or prompt.Parent == nil then return false end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then FirePrompt(prompt) return false end
    local part = prompt.Parent
    while part and not part:IsA("BasePart") do part = part.Parent end
    if not part then FirePrompt(prompt) return false end
    local maxD = prompt.MaxActivationDistance or 10
    if (hrp.Position - part.Position).Magnitude <= (maxD - 1) then
        FirePrompt(prompt)
        return true
    end
    local orig = hrp.CFrame
    pcall(function() hrp.CFrame = part.CFrame + Vector3.new(0, 3, 0) end)
    task.wait(0.35)
    FirePrompt(prompt)
    task.wait(holdWait or 0.8)
    pcall(function() hrp.CFrame = orig end)
    return true
end
local function FindStarTool()
    local places = {LocalPlayer.Character, LocalPlayer:FindFirstChild("Backpack")}
    for _, c in ipairs(places) do
        if c then
            for _, t in ipairs(c:GetChildren()) do
                if t:IsA("Tool") and (t:GetAttribute("StarName") or t:GetAttribute("StarAsset") or t:GetAttribute("StarIncome")) then
                    return t
                end
            end
        end
    end
    return nil
end
local function IsSelected(idx, key)
    local o = Options[idx]
    if not o then return false end
    local v = o
    if type(v) ~= "table" then return false end
    if v[key] ~= nil then return v[key] == true end
    for _, k in pairs(v) do if k == key then return true end end
    return false
end
local function FindTrashTool()
    local places = {LocalPlayer.Character, LocalPlayer:FindFirstChild("Backpack")}
    for _, c in ipairs(places) do
        if c then
            for _, t in ipairs(c:GetChildren()) do
                if t:IsA("Tool") and t:GetAttribute("StarAsset") then
                    local r = t:GetAttribute("StarRarity")
                    if r and IsSelected("TrashRarities", r) then return t end
                end
            end
        end
    end
    return nil
end
------------------------------------------------------------
-- 6. Create Library window
------------------------------------------------------------
local Window = Library:CreateWindow({ Title = "Stealth", Footer = "discord.gg/hqE5drDHF7", AutoLoad = true })

------------------------------------------------------------
-- 7. Tabs
------------------------------------------------------------
local MainTab = Window:AddTab({ Name = "Dashboard" })
local FarmingTab = Window:AddTab({ Name = "Farming" })
local RollBuyTab = Window:AddTab({ Name = "Roll & Buy" })
local UpgradesTab = Window:AddTab({ Name = "Upgrades" })
local ShopsTab = Window:AddTab({ Name = "Shops" })
local SettingsTab = Window:AddTab({ Name = "Config" })
------------------------------------------------------------
-- 8. Dashboard tab
------------------------------------------------------------
MainTab:AddLabel("Game: ")
MainTab:AddLabel("Hub: Stealth (Library):  ", true)
MainTab:AddLabel("Press RightShift to toggle UI:  ", true)
local StatusLabel = MainTab:AddLabel("Status: loading...:  ", true)
local AreaLabel = MainTab:AddLabel("Plot: ...:  ", true)
local SessionLabel = MainTab:AddLabel("Session: 0s:  ", true)
MainTab:AddButton({ Text = "Teleport: Base",
    Callback = function() FireRemote("TeleportToBase") end

MainTab:AddButton({ Text = "Teleport: Market",
    Callback = function() FireRemote("TeleportToMarket") end

local CashLabel = MainTab:AddLabel("Cash: ...:  ", true)
local AltarLabel = MainTab:AddLabel("Altars: ...:  ", true)
local PedestalLabel = MainTab:AddLabel("Rolling stars: ...:  ", true)
------------------------------------------------------------
-- 9. Farming tab
------------------------------------------------------------
Toggles.AutoPlace = false
FarmingTab:AddToggle("AutoPlaceBestStars", {  Text = "Auto Place Best Stars", Default = false,
    Callback = function(v) Toggles.AutoPlace = v end
 })
Toggles.AutoUnlock = false
FarmingTab:AddToggle("AutoUnlockAltars", {  Text = "Auto Unlock Altars", Default = false,
    Callback = function(v) Toggles.AutoUnlock = v end
 })
Toggles.AutoCollect = false
FarmingTab:AddToggle("AutoCollectIncome", {  Text = "Auto Collect Income", Default = false,
    Callback = function(v) Toggles.AutoCollect = v end
 })
Toggles.AutoTrash = false
FarmingTab:AddToggle("AutoTrashStars", {  Text = "Auto Trash Stars", Default = false,
    Callback = function(v) Toggles.AutoTrash = v end
 })
OPTIONS = OPTIONS or {}
Options.TrashRarities = {"Common"}
FarmingTab:AddDropdown("RaritiesToTrash", { 
    Text = "Rarities To Trash",
    Options = RARITIES,
    Multi = true,
    Callback = function(state) Options.TrashRarities = state end

------------------------------------------------------------
-- 10. Roll & Buy tab
------------------------------------------------------------
Toggles.AutoRoll = false
RollBuyTab:AddToggle("AutoRollStars", {  Text = "Auto Roll Stars", Default = false,
    Callback = function(v) Toggles.AutoRoll = v end
 })
Options.RollStopRarity = "Legendary"
RollBuyTab:AddDropdown("StopOnRarity", { 
    Text = "Stop On Rarity",
    Options = RARITIES,
    Callback = function(state) Options.RollStopRarity = state end

Toggles.RollStopEnabled = false
RollBuyTab:AddToggle("StopRollingOnTarget", {  Text = "Stop Rolling On Target+", Default = false,
    Callback = function(v) Toggles.RollStopEnabled = v end
 })
Toggles.AutoBuyStars = false
RollBuyTab:AddToggle("AutoBuyStars", {  Text = "Auto Buy Stars", Default = false,
    Callback = function(v) Toggles.AutoBuyStars = v end
 })
Options.BuyStarRarities = RARITIES
RollBuyTab:AddDropdown("RaritiesToBuy", { 
    Text = "Rarities To Buy",
    Options = RARITIES,
    Multi = true,
    Callback = function(state) Options.BuyStarRarities = state end

------------------------------------------------------------
-- 11. Upgrades tab
------------------------------------------------------------
Toggles.AutoLuck = false
UpgradesTab:AddToggle("AutoUpgradeStarLuck", {  Text = "Auto Upgrade Star Luck", Default = false,
    Callback = function(v) Toggles.AutoLuck = v end
 })
Toggles.AutoPedestal = false
UpgradesTab:AddToggle("AutoAddPedestals", {  Text = "Auto Add Pedestals", Default = false,
    Callback = function(v) Toggles.AutoPedestal = v end
 })
------------------------------------------------------------
-- 12. Shops tab
------------------------------------------------------------
Toggles.AutoMut = false
ShopsTab:AddToggle("AutoBuyMutationItems", {  Text = "Auto Buy Mutation Items", Default = false,
    Callback = function(v) Toggles.AutoMut = v end
 })
Options.MutItems = MUTATION_IDS
ShopsTab:AddDropdown("MutationItems", { 
    Text = "Mutation Items",
    Options = MUTATION_IDS,
    Multi = true,
    Callback = function(state) Options.MutItems = state end

Toggles.AutoEgg = false
ShopsTab:AddToggle("AutoBuyPetEggs", {  Text = "Auto Buy Pet Eggs", Default = false,
    Callback = function(v) Toggles.AutoEgg = v end
 })
Options.EggItems = EGG_NAMES
ShopsTab:AddDropdown("PetEggs", { 
    Text = "Pet Eggs",
    Options = EGG_NAMES,
    Multi = true,
    Callback = function(state) Options.EggItems = state end

Toggles.AutoGear = false
ShopsTab:AddToggle("AutoBuyGear", {  Text = "Auto Buy Gear", Default = false,
    Callback = function(v) Toggles.AutoGear = v end
 })
Options.GearItems = GEAR_IDS
ShopsTab:AddDropdown("Gear", { 
    Text = "Gear",
    Options = GEAR_IDS,
    Multi = true,
    Callback = function(state) Options.GearItems = state end

Options.GearQty = "1"
ShopsTab:CreateDropdown({
    Name = "Quantity",
    Options = {"1", "10"},
    Callback = function(state) Options.GearQty = state end

------------------------------------------------------------
-- 13. Settings tab
------------------------------------------------------------
Toggles.AntiAFK = true
SettingsTab:AddToggle("AntiAFK", {  Text = "Anti-AFK", Default = true,
    Callback = function(v) Toggles.AntiAFK = v end
 })
SettingsTab:AddButton({ Text = "Unload Stealth",
    Description = "Removes the menu and stops all automation",
    Callback = function()
        Unloaded = true
        pcall(function() Window:Destroy() end)
    end

------------------------------------------------------------
-- 14. Automation loops (from original, unchanged)
------------------------------------------------------------
task.spawn(function()
    while not Unloaded do
        if Toggles.AutoRoll then
            local skip = false
            if Toggles.RollStopEnabled and Options.RollStopRarity then
                local target = Options.RollStopRarity
                local ti = RARITY_ORDER[target] or 0
                for _, e in ipairs(GetOwnRollingStars()) do
                    local r = e.Star:GetAttribute("StarRarity")
                    if r and (RARITY_ORDER[r] or 0) >= ti then skip = true break end
                end
            end
            if not skip then FirePrompt(GetRollPrompt()) end
        end
        task.wait(1)
    end
end)
task.spawn(function()
    while not Unloaded do
        if Toggles.AutoBuyStars then
            for _, e in ipairs(GetOwnRollingStars()) do
                local r = e.Star:GetAttribute("StarRarity")
                if r and IsSelected("BuyStarRarities", r) then FirePrompt(e.Prompt) task.wait(0.2) end
            end
        end
        task.wait(1)
    end
end)
task.spawn(function()
    while not Unloaded do
        if Toggles.AutoPlace then
            FireRemote("EquipBestStarsEvent")
        end
        task.wait(1)
    end
end)
task.spawn(function()
    while not Unloaded do
        if Toggles.AutoUnlock then FireRemote("UpgradeAltarEvent") end
        if Toggles.AutoLuck then FireRemote("UpgradeBoardEvent", "Luck") end
        if Toggles.AutoPedestal then FireRemote("UpgradeBoardEvent", "Pedestal") end
        if Toggles.AutoCollect then
            local trig = GetCollectTrigger()
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if trig and hrp then
                pcall(function()
                    firetouchinterest(hrp, trig, 0)
                    task.wait(0.3)
                    firetouchinterest(hrp, trig, 1)
                end)
            end
        end
        task.wait(1)
    end
end)
task.spawn(function()
    while not Unloaded do
        if Toggles.AutoMut then
            for _, id in ipairs(MUTATION_IDS) do
                if IsSelected("MutItems", id) then FireRemote("MutationShopPurchaseEvent", id) task.wait(0.2) end
            end
        end
        if Toggles.AutoEgg then
            for i, name in ipairs(EGG_NAMES) do
                if IsSelected("EggItems", name) then FireRemote("PurchaseEggEvent", i) task.wait(0.2) end
            end
        end
        if Toggles.AutoGear then
            local q = 1
            if Options.GearQty then q = tonumber(Options.GearQty) or 1 end
            for _, id in ipairs(GEAR_IDS) do
                if IsSelected("GearItems", id) then FireRemote("ShopPurchaseEvent", id, q) task.wait(0.2) end
            end
        end
        task.wait(1)
    end
end)
task.spawn(function()
    while not Unloaded do
        if Toggles.AutoTrash then
            local tool = FindTrashTool()
            if tool then
                if tool.Parent ~= LocalPlayer.Character then
                    pcall(function()
                        local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                        if h then h:EquipTool(tool) end
                    end)
                    task.wait(0.4)
                end
                local held = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
                if held and held:GetAttribute("StarAsset") then
                    DoPromptNear(GetTrashPrompt(), 0.8)
                end
            end
        end
        task.wait(1)
    end
end)
-- Anti-AFK
pcall(function()
    LocalPlayer.Idled:Connect(function()
        if Toggles.AntiAFK then
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end
    end)
end)
task.spawn(function()
    while not Unloaded do
        if Toggles.AntiAFK then FireRemote("AFKActivity") end
        task.wait(30)
    end
end)
-- Status updater
local t0 = os.clock()
task.spawn(function()
    while not Unloaded do
        local dt = math.floor(os.clock() - t0)
        pcall(function()
            local area = GetOwnArea()
            local ls = LocalPlayer:FindFirstChild("leaderstats")
            local cash = ls and ls:FindFirstChild("Cash")
            StatusLabel:Set("Status: " .. tostring(#GetEmptyAltars()) .. " empty altar(s), " .. tostring(#GetOwnRollingStars()) .. " star(s) on pedestals")
            AreaLabel:Set("Plot: " .. tostring(area and area.Name or "?") .. " | Unlocked: " .. tostring(area and area:GetAttribute("UnlockedAltarCount") or "?"))
            SessionLabel:Set(string.format("Session: %dm %ds", math.floor(dt/60), dt%60))
            CashLabel:Set("Cash: " .. tostring(cash and cash.Value or "?"))
            local a2 = GetOwnArea()
            local rm = a2 and a2:FindFirstChild("RegionMarker")
            local alt = rm and rm:FindFirstChild("Altars")
            AltarLabel:Set("Altars total: " .. tostring(alt and #alt:GetChildren() or "?"))
            PedestalLabel:Set("Rolling stars: " .. tostring(#GetOwnRollingStars()))
        end)
        task.wait(1)
    end
end)
Library:Notify({
    Name = "Stealth",
    Content = gameName .. " loaded! Press RightShift",
    Duration = 4

print("[Stealth] Loaded " .. gameName .. " via Library")
