-- [[ Stealth | Star RNG ]]
--
-- Original: Star RNG by @hidevin (ObsidianUltra / Linoria-based)
-- Converted to WindUI for Stealth Hub.
-- Discord: discord.gg/hqE5drDHF7
--
-- Game: Star RNG

------------------------------------------------------------
-- 1. Identity elevation (WindUI needs executor-level identity)
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
-- 2. Load WindUI
------------------------------------------------------------
local WindUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"
))()

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
-- 6. Create WindUI window
------------------------------------------------------------
local Window = WindUI:CreateWindow({
    Title = "Stealth",
    Folder = "Stealth",
    Icon = "solar:shield-keyhole-bold-duotone",
    NewElements = true,
    HideSearchBar = false,
    OpenButton = {
        Title = "Open Stealth",
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
local MainSection = Window:Section({ Title = "Main" })
local MainTab = MainSection:Tab({
    Title = "Dashboard",
    Icon = "solar:widget-bold",
    IconShape = "Square",
    Border = true,
})

local FarmingSection = Window:Section({ Title = "Farming" })
local FarmingTab = FarmingSection:Tab({
    Title = "Farming",
    Icon = "solar:sprout-bold",
    IconShape = "Square",
    Border = true,
})

local InvSection = Window:Section({ Title = "Inventory" })
local RollBuyTab = InvSection:Tab({
    Title = "Roll & Buy",
    Icon = "solar:box-bold",
    IconShape = "Square",
    Border = true,
})
local UpgradesTab = InvSection:Tab({
    Title = "Upgrades",
    Icon = "solar:graph-up-bold",
    IconShape = "Square",
    Border = true,
})
local ShopsTab = InvSection:Tab({
    Title = "Shops",
    Icon = "solar:cart-large-bold",
    IconShape = "Square",
    Border = true,
})

local SettingsSection = Window:Section({ Title = "Settings" })
local SettingsTab = SettingsSection:Tab({
    Title = "Config",
    Icon = "solar:settings-bold",
    IconShape = "Square",
    Border = true,
})

------------------------------------------------------------
-- 8. Dashboard tab
------------------------------------------------------------
MainTab:Paragraph({ Title = "Game: " .. gameName, DoesWrap = true })
MainTab:Paragraph({ Title = "Hub: Stealth (WindUI)", DoesWrap = true })
MainTab:Paragraph({ Title = "Press RightShift to toggle UI", DoesWrap = true })

local StatusLabel = MainTab:Paragraph({ Title = "Status: loading...", DoesWrap = true })
local AreaLabel = MainTab:Paragraph({ Title = "Plot: ...", DoesWrap = true })
local SessionLabel = MainTab:Paragraph({ Title = "Session: 0s", DoesWrap = true })

MainTab:Space()

MainTab:Button({
    Title = "Teleport: Base",
    Callback = function() FireRemote("TeleportToBase") end,
})

MainTab:Button({
    Title = "Teleport: Market",
    Callback = function() FireRemote("TeleportToMarket") end,
})

MainTab:Space()

local CashLabel = MainTab:Paragraph({ Title = "Cash: ...", DoesWrap = true })
local AltarLabel = MainTab:Paragraph({ Title = "Altars: ...", DoesWrap = true })
local PedestalLabel = MainTab:Paragraph({ Title = "Rolling stars: ...", DoesWrap = true })

------------------------------------------------------------
-- 9. Farming tab
------------------------------------------------------------
Toggles.AutoPlace = false
FarmingTab:Toggle({
    Title = "Auto Place Best Stars",
    Description = "Hits Equip Best (EquipBestStarsEvent). 1s loop.",
    Default = false,
    Callback = function(v) Toggles.AutoPlace = v end,
})

Toggles.AutoUnlock = false
FarmingTab:Toggle({
    Title = "Auto Unlock Altars",
    Description = "Fires UpgradeAltarEvent. 1s loop.",
    Default = false,
    Callback = function(v) Toggles.AutoUnlock = v end,
})

Toggles.AutoCollect = false
FarmingTab:Toggle({
    Title = "Auto Collect Income",
    Description = "Touches your Collector via firetouchinterest. Works at range. 1s loop.",
    Default = false,
    Callback = function(v) Toggles.AutoCollect = v end,
})

FarmingTab:Space()

Toggles.AutoTrash = false
FarmingTab:Toggle({
    Title = "Auto Trash Stars",
    Description = "Equips a matching star, teleports to Dumpster, trashes, returns. 1s loop.",
    Default = false,
    Callback = function(v) Toggles.AutoTrash = v end,
})

OPTIONS = OPTIONS or {}
Options.TrashRarities = {"Common"}
FarmingTab:Dropdown({
    Title = "Rarities To Trash",
    Values = RARITIES,
    Multi = true,
    Searchable = true,
    Callback = function(state) Options.TrashRarities = state end,
})

------------------------------------------------------------
-- 10. Roll & Buy tab
------------------------------------------------------------
Toggles.AutoRoll = false
RollBuyTab:Toggle({
    Title = "Auto Roll Stars",
    Description = "Fires Roll prompt. Park near your roller. 1s loop.",
    Default = false,
    Callback = function(v) Toggles.AutoRoll = v end,
})

Options.RollStopRarity = "Legendary"
RollBuyTab:Dropdown({
    Title = "Stop On Rarity",
    Values = RARITIES,
    Callback = function(state) Options.RollStopRarity = state end,
})

Toggles.RollStopEnabled = false
RollBuyTab:Toggle({
    Title = "Stop Rolling On Target+",
    Description = "Pause rolling when a pedestal star meets/exceeds target rarity.",
    Default = false,
    Callback = function(v) Toggles.RollStopEnabled = v end,
})

RollBuyTab:Space()

Toggles.AutoBuyStars = false
RollBuyTab:Toggle({
    Title = "Auto Buy Stars",
    Description = "Buys pedestal stars matching rarities. 1s loop.",
    Default = false,
    Callback = function(v) Toggles.AutoBuyStars = v end,
})

Options.BuyStarRarities = RARITIES
RollBuyTab:Dropdown({
    Title = "Rarities To Buy",
    Values = RARITIES,
    Multi = true,
    Searchable = true,
    Callback = function(state) Options.BuyStarRarities = state end,
})

------------------------------------------------------------
-- 11. Upgrades tab
------------------------------------------------------------
Toggles.AutoLuck = false
UpgradesTab:Toggle({
    Title = "Auto Upgrade Star Luck",
    Description = "UpgradeBoardEvent Luck. 1s loop.",
    Default = false,
    Callback = function(v) Toggles.AutoLuck = v end,
})

Toggles.AutoPedestal = false
UpgradesTab:Toggle({
    Title = "Auto Add Pedestals",
    Description = "UpgradeBoardEvent Pedestal. 1s loop.",
    Default = false,
    Callback = function(v) Toggles.AutoPedestal = v end,
})

------------------------------------------------------------
-- 12. Shops tab
------------------------------------------------------------
Toggles.AutoMut = false
ShopsTab:Toggle({
    Title = "Auto Buy Mutation Items",
    Default = false,
    Callback = function(v) Toggles.AutoMut = v end,
})

Options.MutItems = MUTATION_IDS
ShopsTab:Dropdown({
    Title = "Mutation Items",
    Values = MUTATION_IDS,
    Multi = true,
    Searchable = true,
    Callback = function(state) Options.MutItems = state end,
})

ShopsTab:Space()

Toggles.AutoEgg = false
ShopsTab:Toggle({
    Title = "Auto Buy Pet Eggs",
    Default = false,
    Callback = function(v) Toggles.AutoEgg = v end,
})

Options.EggItems = EGG_NAMES
ShopsTab:Dropdown({
    Title = "Pet Eggs",
    Values = EGG_NAMES,
    Multi = true,
    Searchable = true,
    Callback = function(state) Options.EggItems = state end,
})

ShopsTab:Space()

Toggles.AutoGear = false
ShopsTab:Toggle({
    Title = "Auto Buy Gear",
    Default = false,
    Callback = function(v) Toggles.AutoGear = v end,
})

Options.GearItems = GEAR_IDS
ShopsTab:Dropdown({
    Title = "Gear",
    Values = GEAR_IDS,
    Multi = true,
    Searchable = true,
    Callback = function(state) Options.GearItems = state end,
})

Options.GearQty = "1"
ShopsTab:Dropdown({
    Title = "Quantity",
    Values = {"1", "10"},
    Callback = function(state) Options.GearQty = state end,
})

------------------------------------------------------------
-- 13. Settings tab
------------------------------------------------------------
Toggles.AntiAFK = true
SettingsTab:Toggle({
    Title = "Anti-AFK",
    Description = "Fires AFKActivity + anti-idle. Enabled by default.",
    Default = true,
    Callback = function(v) Toggles.AntiAFK = v end,
})

SettingsTab:Space()

SettingsTab:Button({
    Title = "Unload Stealth",
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

WindUI:Notify({
    Title = "Stealth",
    Content = gameName .. " loaded! Press RightShift",
    Duration = 4,
    Icon = "solar:info-circle-bold",
})

print("[Stealth] Loaded " .. gameName .. " via WindUI")
