-- [[ Stealth | Star RNG ]]
--
-- Original: Star RNG by @hidevin (ObsidianUltra / Linoria-based)
-- Converted to Lumen for Stealth Hub.
-- Discord: discord.gg/hqE5drDHF7
--
-- Game: Star RNG

------------------------------------------------------------
-- 1. Identity elevation (Lumen needs executor-level identity)
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
-- 2. Load Lumen
------------------------------------------------------------
local Lumen = getgenv().StealthLumen
if not Lumen then
    Lumen = loadstring(game:HttpGet("https://raw.githubusercontent.com/requiemzc/Stealth/main/Lumen.lua"))()
    getgenv().StealthLumen = Lumen
end

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
-- 6. Create Lumen window
------------------------------------------------------------
local Window = Lumen:Window({
    Name = "Stealth",
    Folder = "Stealth",
    Icon = "solar:shield-keyhole-bold-duotone",
    NewElements = true,
    HideSearchBar = false,
    OpenButton = {
        Name = "Open Stealth",
        CornerRadius = UDim.new(1, 0),
        StrokeThickness = 3,
        Enabled = true,
        Draggable = true,
        OnlyMobile = false,
        Scale = 0.5,
        Color = ColorSequence.new(
            Color3.fromHex("#30FF6A"),
            Color3.fromHex("#e7ff2f")
        ),
    },
    Topbar = {
        Height = 44,
        ButtonsType = "Mac",
    },
})

------------------------------------------------------------
-- 7. Tabs
------------------------------------------------------------
local MainTab = Window:Page({
    Name = "Dashboard",
    Icon = "solar:widget-bold",
    ,
    ,
})
local MainTabPage = MainTab

local MainTab = MainTabPage:Section({ Name = "MainTab", Side = "Left", Icon = "box" })

local FarmingTab = Window:Page({
    Name = "Farming",
    Icon = "solar:sprout-bold",
    ,
    ,
})
local FarmingTabPage = FarmingTab

local FarmingTab = FarmingTabPage:Section({ Name = "FarmingTab", Side = "Left", Icon = "box" })

local RollBuyTab = Window:Page({
    Name = "Roll & Buy",
    Icon = "solar:box-bold",
    ,
    ,
})
local RollBuyTabPage = RollBuyTab

local RollBuyTab = RollBuyTabPage:Section({ Name = "RollBuyTab", Side = "Left", Icon = "box" })
local UpgradesTab = Window:Page({
    Name = "Upgrades",
    Icon = "solar:graph-up-bold",
    ,
    ,
})
local UpgradesTabPage = UpgradesTab

local UpgradesTab = UpgradesTabPage:Section({ Name = "UpgradesTab", Side = "Left", Icon = "box" })
local ShopsTab = Window:Page({
    Name = "Shops",
    Icon = "solar:cart-large-bold",
    ,
    ,
})
local ShopsTabPage = ShopsTab

local ShopsTab = ShopsTabPage:Section({ Name = "ShopsTab", Side = "Left", Icon = "box" })

local SettingsTab = Window:Page({
    Name = "Config",
    Icon = "solar:settings-bold",
    ,
    ,
})
local SettingsTabPage = SettingsTab

local SettingsTab = SettingsTabPage:Section({ Name = "SettingsTab", Side = "Left", Icon = "box" })

------------------------------------------------------------
-- 8. Dashboard tab
------------------------------------------------------------
MainTab:Label({ Text = "Game: " .. gameName })
MainTab:Label({ Text = "Hub: Stealth (Lumen)" })
MainTab:Label({ Text = "Press RightShift to toggle UI" })

local StatusLabel = MainTab:Label({ Text = "Status: loading..." })
local AreaLabel = MainTab:Label({ Text = "Plot: ..." })
local SessionLabel = MainTab:Label({ Text = "Session: 0s" })


MainTab:Button({
    Name = "Teleport: Base",
    Callback = function() FireRemote("TeleportToBase") end,
})

MainTab:Button({
    Name = "Teleport: Market",
    Callback = function() FireRemote("TeleportToMarket") end,
})


local CashLabel = MainTab:Label({ Text = "Cash: ..." })
local AltarLabel = MainTab:Label({ Text = "Altars: ..." })
local PedestalLabel = MainTab:Label({ Text = "Rolling stars: ..." })

------------------------------------------------------------
-- 9. Farming tab
------------------------------------------------------------
Toggles.AutoPlace = false
local _auto_lbl_1 = FarmingTab:Label({ Text = "Auto Place Best Stars" })
_auto_lbl_1:Toggle({
    State = false,
    Callback = function(v) Toggles.AutoPlace = v end,
})

Toggles.AutoUnlock = false
local _auto_lbl_2 = FarmingTab:Label({ Text = "Auto Unlock Altars" })
_auto_lbl_2:Toggle({
    State = false,
    Callback = function(v) Toggles.AutoUnlock = v end,
})

Toggles.AutoCollect = false
local _auto_lbl_3 = FarmingTab:Label({ Text = "Auto Collect Income" })
_auto_lbl_3:Toggle({
    State = false,
    Callback = function(v) Toggles.AutoCollect = v end,
})


Toggles.AutoTrash = false
local _auto_lbl_4 = FarmingTab:Label({ Text = "Auto Trash Stars" })
_auto_lbl_4:Toggle({
    State = false,
    Callback = function(v) Toggles.AutoTrash = v end,
})

OPTIONS = OPTIONS or {}
Options.TrashRarities = {"Common"}
FarmingTab:Dropdown({
    Name = "Rarities To Trash",
    Options = RARITIES,
    Multi = true,
    Search = true,
    Callback = function(state) Options.TrashRarities = state end,
})

------------------------------------------------------------
-- 10. Roll & Buy tab
------------------------------------------------------------
Toggles.AutoRoll = false
local _auto_lbl_5 = RollBuyTab:Label({ Text = "Auto Roll Stars" })
_auto_lbl_5:Toggle({
    State = false,
    Callback = function(v) Toggles.AutoRoll = v end,
})

Options.RollStopRarity = "Legendary"
RollBuyTab:Dropdown({
    Name = "Stop On Rarity",
    Options = RARITIES,
    Callback = function(state) Options.RollStopRarity = state end,
})

Toggles.RollStopEnabled = false
local _auto_lbl_6 = RollBuyTab:Label({ Text = "Stop Rolling On Target+" })
_auto_lbl_6:Toggle({
    State = false,
    Callback = function(v) Toggles.RollStopEnabled = v end,
})


Toggles.AutoBuyStars = false
local _auto_lbl_7 = RollBuyTab:Label({ Text = "Auto Buy Stars" })
_auto_lbl_7:Toggle({
    State = false,
    Callback = function(v) Toggles.AutoBuyStars = v end,
})

Options.BuyStarRarities = RARITIES
RollBuyTab:Dropdown({
    Name = "Rarities To Buy",
    Options = RARITIES,
    Multi = true,
    Search = true,
    Callback = function(state) Options.BuyStarRarities = state end,
})

------------------------------------------------------------
-- 11. Upgrades tab
------------------------------------------------------------
Toggles.AutoLuck = false
local _auto_lbl_8 = UpgradesTab:Label({ Text = "Auto Upgrade Star Luck" })
_auto_lbl_8:Toggle({
    State = false,
    Callback = function(v) Toggles.AutoLuck = v end,
})

Toggles.AutoPedestal = false
local _auto_lbl_9 = UpgradesTab:Label({ Text = "Auto Add Pedestals" })
_auto_lbl_9:Toggle({
    State = false,
    Callback = function(v) Toggles.AutoPedestal = v end,
})

------------------------------------------------------------
-- 12. Shops tab
------------------------------------------------------------
Toggles.AutoMut = false
local _auto_lbl_10 = ShopsTab:Label({ Text = "Auto Buy Mutation Items" })
_auto_lbl_10:Toggle({
    State = false,
    Callback = function(v) Toggles.AutoMut = v end,
})

Options.MutItems = MUTATION_IDS
ShopsTab:Dropdown({
    Name = "Mutation Items",
    Options = MUTATION_IDS,
    Multi = true,
    Search = true,
    Callback = function(state) Options.MutItems = state end,
})


Toggles.AutoEgg = false
local _auto_lbl_11 = ShopsTab:Label({ Text = "Auto Buy Pet Eggs" })
_auto_lbl_11:Toggle({
    State = false,
    Callback = function(v) Toggles.AutoEgg = v end,
})

Options.EggItems = EGG_NAMES
ShopsTab:Dropdown({
    Name = "Pet Eggs",
    Options = EGG_NAMES,
    Multi = true,
    Search = true,
    Callback = function(state) Options.EggItems = state end,
})


Toggles.AutoGear = false
local _auto_lbl_12 = ShopsTab:Label({ Text = "Auto Buy Gear" })
_auto_lbl_12:Toggle({
    State = false,
    Callback = function(v) Toggles.AutoGear = v end,
})

Options.GearItems = GEAR_IDS
ShopsTab:Dropdown({
    Name = "Gear",
    Options = GEAR_IDS,
    Multi = true,
    Search = true,
    Callback = function(state) Options.GearItems = state end,
})

Options.GearQty = "1"
ShopsTab:Dropdown({
    Name = "Quantity",
    Options = {"1", "10"},
    Callback = function(state) Options.GearQty = state end,
})

------------------------------------------------------------
-- 13. Settings tab
------------------------------------------------------------
Toggles.AntiAFK = true
local _auto_lbl_13 = SettingsTab:Label({ Text = "Anti-AFK" })
_auto_lbl_13:Toggle({
    State = true,
    Callback = function(v) Toggles.AntiAFK = v end,
})


SettingsTab:Button({
    Name = "Unload Stealth",
    Description = "Removes the menu and stops all automation",
    Callback = function()
        Unloaded = true
        pcall(function() Window:Destroy() end)
    end,
})

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
            StatusLabel:SetTitle("Status: " .. tostring(#GetEmptyAltars()) .. " empty altar(s), " .. tostring(#GetOwnRollingStars()) .. " star(s) on pedestals")
            AreaLabel:SetTitle("Plot: " .. tostring(area and area.Name or "?") .. " | Unlocked: " .. tostring(area and area:GetAttribute("UnlockedAltarCount") or "?"))
            SessionLabel:SetTitle(string.format("Session: %dm %ds", math.floor(dt/60), dt%60))
            CashLabel:SetTitle("Cash: " .. tostring(cash and cash.Value or "?"))
            local a2 = GetOwnArea()
            local rm = a2 and a2:FindFirstChild("RegionMarker")
            local alt = rm and rm:FindFirstChild("Altars")
            AltarLabel:SetTitle("Altars total: " .. tostring(alt and #alt:GetChildren() or "?"))
            PedestalLabel:SetTitle("Rolling stars: " .. tostring(#GetOwnRollingStars()))
        end)
        task.wait(1)
    end
end)

Lumen:Notify({
    Name = "Stealth",
    Content = gameName .. " loaded! Press RightShift",
    Duration = 4,
    Icon = "solar:info-circle-bold",
})

print("[Stealth] Loaded " .. gameName .. " via Lumen")
