-- [[ Stealth | Jump for Animals ]]
--
-- Original: Ouroboros Hub @hidevin (ObsidianUltra)
-- Converted to WindUI for Stealth Hub.
-- Discord: discord.gg/hqE5drDHF7
--
-- Game: Jump for Animals

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
-- 3. State tables (mirror ObsidianUltra Toggles/Options pattern)
------------------------------------------------------------
local Toggles = {}
local Options = {}
local Library = {
    Toggles = Toggles,
    Options = Options,
    Unloaded = false,
    ShowCustomCursor = true,
}

function Library:Notify(opts)
    WindUI:Notify({
        Title = opts.Title or "Stealth",
        Content = opts.Description or "",
        Duration = opts.Time or 3,
        Icon = "solar:info-circle-bold",
    })
end

function Library:Unload()
    if self.Unloaded then return end
    self.Unloaded = true
    if self._onUnload then self._onUnload() end
    pcall(function() self._window:Destroy() end)
end

function Library:OnUnload(fn)
    self._onUnload = fn
end

------------------------------------------------------------
-- 4. Services & game refs
------------------------------------------------------------
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local gameName = "Jump for Animals"

local Remotes = ReplicatedStorage:WaitForChild("Remotes", 15)
if not Remotes then
    WindUI:Notify({
        Title = "Stealth",
        Content = "Remotes folder not found. Join the game first.",
        Duration = 6,
        Icon = "solar:danger-circle-bold",
    })
    return
end

local function waitRemote(name, parent)
    local success, instance = pcall(function()
        return (parent or Remotes):WaitForChild(name, 10)
    end)
    if success then
        return instance
    end
    return nil
end

local PlaceEggRequest = waitRemote("PlaceEggRequest")
local DropEggRequest = waitRemote("DropEggRequest")
local SellRemote = waitRemote("Sell")
local CoilsRemote = waitRemote("Coils")
local TrailsRemote = waitRemote("Trails")
local SquatTrainingRequest = waitRemote("SquatTrainingRequest")
local StopSquattingRequest = waitRemote("StopSquattingRequest")
local SquatBonusRequest = waitRemote("SquatBonusRequest")
local OfflineRewardsRemote = waitRemote("OfflineRewards")
local IndexRewardRemote = waitRemote("ClaimAnimalIndexReward")

local Settings = ReplicatedStorage:FindFirstChild("Settings")
local function requireSetting(name)
    local module = Settings and Settings:FindFirstChild(name)
    if not module then
        return nil
    end
    local success, result = pcall(require, module)
    if success then
        return result
    end
    return nil
end

local Rarities = requireSetting("Rarities")
local SpeedUpgrades = requireSetting("SpeedUpgrades")
local TrailSettings = requireSetting("Trails")
local BarbellUpgrades = requireSetting("BarbellUpgrades")
local RecommendedJumps = requireSetting("RecommendedJumps")

local ZoneJumpRequirements = { Meadow = 25 }
if RecommendedJumps and type(RecommendedJumps.List) == "table" then
    for key, value in pairs(RecommendedJumps.List) do
        local zone = string.gsub(tostring(key), "%d+$", "")
        local jump = tonumber(value)
        if jump and (ZoneJumpRequirements[zone] == nil or jump < ZoneJumpRequirements[zone]) then
            ZoneJumpRequirements[zone] = jump
        end
    end
end

local StartedAt = os.clock()

------------------------------------------------------------
-- 5. Helper functions (from original, unchanged)
------------------------------------------------------------
local function getCharacter()
    return LocalPlayer.Character
end

local function getHumanoid()
    local character = getCharacter()
    return character and character:FindFirstChildOfClass("Humanoid")
end

local function getRoot()
    local character = getCharacter()
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function teleportTo(position)
    local root = getRoot()
    if root and position then
        root.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
        return true
    end
    return false
end

local function holderPosition(holder)
    if not holder then
        return nil
    end
    if holder:IsA("BasePart") then
        return holder.Position
    end
    if holder:IsA("Attachment") then
        return holder.WorldPosition
    end
    return nil
end

local function getPlot()
    local plot = LocalPlayer:FindFirstChild("Plot")
    return plot and plot.Value or nil
end

local function getSquatDetector()
    local plot = getPlot()
    local zone = plot and plot:FindFirstChild("SquatZone")
    local floor = zone and zone:FindFirstChild("Floor")
    return floor and floor:FindFirstChild("Detector") or nil
end

local function getPlacementDetector()
    local plot = getPlot()
    return plot and plot:FindFirstChild("Detector", true) or nil
end

local function getCash()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    local cash = leaderstats and leaderstats:FindFirstChild("Cash")
    local value = cash and cash:FindFirstChild("V")
    return value and tonumber(value.Value) or 0
end

local function getLevel()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    local level = leaderstats and leaderstats:FindFirstChild("Level")
    local value = level and level:FindFirstChild("V")
    return value and tonumber(value.Value) or 0
end

local function isPetTool(tool)
    return tool:IsA("Tool") and tool:GetAttribute("IsPetInventoryTool") == true
end

local function isEggTool(tool)
    return tool:IsA("Tool") and tool:GetAttribute("IsEggTool") == true
end

local function forEachContainer(fn)
    local character = getCharacter()
    if LocalPlayer.Backpack then
        fn(LocalPlayer.Backpack)
    end
    if character then
        fn(character)
    end
end

local function findTool(predicate)
    local found
    forEachContainer(function(container)
        if found then
            return
        end
        for _, child in ipairs(container:GetChildren()) do
            if child:IsA("Tool") and predicate(child) then
                found = child
                return
            end
        end
    end)
    return found
end

local function countEggTools()
    local count = 0
    forEachContainer(function(container)
        for _, child in ipairs(container:GetChildren()) do
            if isEggTool(child) then
                count += 1
            end
        end
    end)
    return count
end

local function countPlacedEggs()
    local plot = getPlot()
    local placed = plot and plot:FindFirstChild("PlacedEggs")
    return placed and #placed:GetChildren() or 0
end

local function countReadyEggs()
    local plot = getPlot()
    local placed = plot and plot:FindFirstChild("PlacedEggs")
    if not placed then
        return 0
    end
    local ready = 0
    for _, egg in ipairs(placed:GetChildren()) do
        if egg:GetAttribute("HatchReady") == true then
            ready += 1
        end
    end
    return ready
end

local function uniqueAnimalNames()
    local names = {}
    local seen = {}
    forEachContainer(function(container)
        for _, child in ipairs(container:GetChildren()) do
            if isPetTool(child) then
                local name = child:GetAttribute("AnimalName") or child.Name
                if not seen[name] then
                    seen[name] = true
                    table.insert(names, name)
                end
            end
        end
    end)
    table.sort(names)
    return names
end

local function abbreviate(value)
    value = tonumber(value) or 0
    local units = { "", "K", "M", "B", "T", "Qa", "Qi" }
    local index = 1
    while value >= 1000 and index < #units do
        value /= 1000
        index += 1
    end
    if index == 1 then
        return tostring(math.floor(value))
    end
    return string.format("%.2f%s", value, units[index])
end

local function formatClock(seconds)
    seconds = math.max(math.floor(seconds), 0)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    return string.format("%02d:%02d:%02d", hours, minutes, secs)
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

Library._window = Window

------------------------------------------------------------
-- 7. Helper to register toggle/slider/dropdown into Toggles/Options
------------------------------------------------------------
local function registerToggle(id, default)
    Toggles[id] = { Value = default }
end

local function registerOption(id, default)
    Options[id] = { Value = default }
end

------------------------------------------------------------
-- 8. Tabs
------------------------------------------------------------
local MainSection = Window:Section({ Title = "Main" })
local MainTab = MainSection:Tab({
    Title = "Dashboard",
    Icon = "solar:widget-bold",
    IconShape = "Square",
    Border = true,
})

local FarmingSection = Window:Section({ Title = "Farming" })
local TrainingTab = FarmingSection:Tab({
    Title = "Training",
    Icon = "solar:dumbbell-bold",
    IconShape = "Square",
    Border = true,
})
local EggTab = FarmingSection:Tab({
    Title = "Eggs",
    Icon = "solar:egg-bold",
    IconShape = "Square",
    Border = true,
})
local SellingTab = FarmingSection:Tab({
    Title = "Selling",
    Icon = "solar:hand-money-bold",
    IconShape = "Square",
    Border = true,
})
local RewardsTab = FarmingSection:Tab({
    Title = "Rewards",
    Icon = "solar:gift-bold",
    IconShape = "Square",
    Border = true,
})

local InvSection = Window:Section({ Title = "Inventory" })
local ShopsTab = InvSection:Tab({
    Title = "Shops",
    Icon = "solar:cart-large-bold",
    IconShape = "Square",
    Border = true,
})
local UpgradesTab = InvSection:Tab({
    Title = "Upgrades",
    Icon = "solar:graph-up-bold",
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
-- 9. Build options data
------------------------------------------------------------
local AnimalNames = uniqueAnimalNames()
if #AnimalNames == 0 then
    AnimalNames = { "None" }
end

local RarityNames = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Divine", "Celestial", "Eternal" }
local ZoneNames = {}
do
    local map = workspace:FindFirstChild("Map")
    local stages = map and map:FindFirstChild("Stages")
    if stages then
        for _, stage in ipairs(stages:GetChildren()) do
            if stage:FindFirstChild("SpawnedEggs") then
                table.insert(ZoneNames, stage.Name)
            end
        end
    end
end
if #ZoneNames == 0 then
    ZoneNames = { "Meadow", "Coral Reef", "Winter", "Desert", "Crystal Mines", "Jungle", "Mystic Isles", "Prehistoric", "Celestial Heights", "Savannah" }
end

local function notify(title, description, kind)
    WindUI:Notify({
        Title = title,
        Content = description or "",
        Duration = 5,
        Icon = kind == "Error" and "solar:danger-circle-bold" or "solar:info-circle-bold",
    })
end

------------------------------------------------------------
-- 10. Dashboard tab
------------------------------------------------------------
local MainBox = MainTab:Paragraph({ Title = "Game: " .. gameName, DoesWrap = true })
local StatusSession = MainTab:Paragraph({ Title = "Session: 00:00:00", DoesWrap = true })
local StatusCash = MainTab:Paragraph({ Title = "Cash: 0", DoesWrap = true })
local StatusLevel = MainTab:Paragraph({ Title = "Level: 0", DoesWrap = true })
local StatusEggs = MainTab:Paragraph({ Title = "Carried eggs: 0 | Placed: 0", DoesWrap = true })
local StatusSquat = MainTab:Paragraph({ Title = "Squatting: false", DoesWrap = true })

------------------------------------------------------------
-- 11. Training tab
------------------------------------------------------------
local TrainingBox = TrainingTab:AddLeftGroupbox and TrainingTab:AddLeftGroupbox("Squats") or TrainingTab
-- WindUI doesn't have AddLeftGroupbox; use the tab directly

registerToggle("AutoTrain", false)
TrainingTab:Toggle({
    Title = "Auto Train Squats",
    Description = "Teleports to your squat pad and trains jump XP forever",
    Default = false,
    Callback = function(state) Toggles.AutoTrain.Value = state end,
})

registerToggle("AutoSquatBonus", false)
TrainingTab:Toggle({
    Title = "Auto Claim Squat Bonus",
    Description = "Instantly claims the pink squat bonus popup",
    Default = false,
    Callback = function(state) Toggles.AutoSquatBonus.Value = state end,
})

TrainingTab:Paragraph({ Title = "Squatting is server controlled; training pauses while you carry an egg.", DoesWrap = true })

------------------------------------------------------------
-- 12. Eggs tab
------------------------------------------------------------
registerToggle("AutoSteal", false)
EggTab:Toggle({
    Title = "Auto Steal Eggs",
    Description = "Grabs an egg, returns to base to bank it, then places it",
    Default = false,
    Callback = function(state) Toggles.AutoSteal.Value = state end,
})

registerOption("StealMode", "Best Egg")
EggTab:Dropdown({
    Title = "Target",
    Values = { "Best Egg", "Nearest Egg", "Highest Rarity" },
    Default = "Best Egg",
    Callback = function(state) Options.StealMode.Value = state end,
})

registerOption("StealZones", {})
EggTab:Dropdown({
    Title = "Zones",
    Values = ZoneNames,
    Multi = true,
    Searchable = true,
    Description = "Only steal eggs from these zones",
    Callback = function(state) Options.StealZones.Value = state end,
})

registerOption("StealRarities", {})
EggTab:Dropdown({
    Title = "Rarities",
    Values = RarityNames,
    Multi = true,
    Searchable = true,
    Description = "Only steal eggs of these rarities",
    Callback = function(state) Options.StealRarities.Value = state end,
})

registerOption("StealDelay", 5)
local StealDelaySlider = EggTab:Slider({
    Title = "Train Between Steals",
    Default = 5,
    Min = 0,
    Max = 60,
    Rounding = 0,
    Suffix = "s",
    Description = "After each egg is placed, train squats for this long before stealing again",
    Callback = function(state) Options.StealDelay.Value = state end,
})

registerToggle("AutoPlace", false)
EggTab:Toggle({
    Title = "Auto Place Stolen Eggs",
    Description = "Places carried eggs on your plot",
    Default = false,
    Callback = function(state) Toggles.AutoPlace.Value = state end,
})

registerToggle("AutoHatch", false)
EggTab:Toggle({
    Title = "Auto Hatch Ready Eggs",
    Description = "Opens every egg whose hatch timer finished, never uses Robux skip",
    Default = false,
    Callback = function(state) Toggles.AutoHatch.Value = state end,
})

EggTab:Paragraph({ Title = "Carrying an egg disables jumping. Auto Place moves it to your plot so the loop continues.", DoesWrap = true })

------------------------------------------------------------
-- 13. Selling tab
------------------------------------------------------------
registerToggle("AutoSell", false)
SellingTab:Toggle({
    Title = "Auto Sell Junk Pets",
    Description = "Equips a pet, walks to the animal seller and sells it",
    Default = false,
    Callback = function(state) Toggles.AutoSell.Value = state end,
})

registerOption("SellMode", "Lowest CPS First")
SellingTab:Dropdown({
    Title = "Mode",
    Values = { "Lowest CPS First", "Chosen Pet" },
    Default = "Lowest CPS First",
    Callback = function(state) Options.SellMode.Value = state end,
})

registerOption("AutoSellPet", AnimalNames[1] or "None")
SellingTab:Dropdown({
    Title = "Chosen Pet",
    Values = AnimalNames,
    Default = AnimalNames[1] or "None",
    Searchable = true,
    Description = "Only used when Mode is Chosen Pet",
    Callback = function(state) Options.AutoSellPet.Value = state end,
})

registerOption("SellMaxCps", "1000")
SellingTab:Input({
    Title = "Max CPS To Sell",
    Default = "1000",
    Placeholder = "1000",
    Numeric = true,
    Description = "Lowest CPS First mode never sells pets above this value",
    Callback = function(state) Options.SellMaxCps.Value = state end,
})

SellingTab:Paragraph({ Title = "Sell value scales with pet CPS. Raise Max CPS only when you really want to sell better pets.", DoesWrap = true })

------------------------------------------------------------
-- 14. Rewards tab
------------------------------------------------------------
registerToggle("AutoOffline", false)
RewardsTab:Toggle({
    Title = "Auto Claim Offline Cash",
    Description = "Claims pending offline earnings whenever ready",
    Default = false,
    Callback = function(state) Toggles.AutoOffline.Value = state end,
})

registerToggle("AutoIndex", false)
RewardsTab:Toggle({
    Title = "Auto Claim Animal Index Rewards",
    Description = "Claims every finished Animal Index reward",
    Default = false,
    Callback = function(state) Toggles.AutoIndex.Value = state end,
})

RewardsTab:Paragraph({ Title = "Index rewards are claimed with a single claim-all request. Offline cash is claimed whenever a balance is waiting.", DoesWrap = true })

------------------------------------------------------------
-- 15. Shops tab
------------------------------------------------------------
registerToggle("AutoBuyCoils", false)
ShopsTab:Toggle({
    Title = "Auto Buy Coils",
    Description = "Buys selected speed coils when affordable",
    Default = false,
    Callback = function(state) Toggles.AutoBuyCoils.Value = state end,
})

registerOption("BuyCoilList", {})
ShopsTab:Dropdown({
    Title = "Coils",
    Values = { "Red Coil", "Candy Coil", "Yellow Coil", "Chocolate Coil" },
    Multi = true,
    Searchable = true,
    Callback = function(state) Options.BuyCoilList.Value = state end,
})

registerToggle("AutoEquipCoil", false)
ShopsTab:Toggle({
    Title = "Auto Equip Best Coil",
    Description = "Equips the highest tier coil you own",
    Default = false,
    Callback = function(state) Toggles.AutoEquipCoil.Value = state end,
})

registerToggle("AutoBuyTrails", false)
ShopsTab:Toggle({
    Title = "Auto Buy Trails",
    Description = "Buys selected jump trails when affordable",
    Default = false,
    Callback = function(state) Toggles.AutoBuyTrails.Value = state end,
})

registerOption("BuyTrailList", {})
ShopsTab:Dropdown({
    Title = "Trails",
    Values = { "Blue Trail", "Red Trail", "Green Trail", "Yellow Trail", "Purple Trail", "White Trail", "Black Trail", "Galaxy Trail", "Crimson Star Trail", "Rainbow Trail" },
    Multi = true,
    Searchable = true,
    Callback = function(state) Options.BuyTrailList.Value = state end,
})

registerToggle("AutoEquipTrail", false)
ShopsTab:Toggle({
    Title = "Auto Equip Best Trail",
    Description = "Equips the highest jump multiplier trail you own",
    Default = false,
    Callback = function(state) Toggles.AutoEquipTrail.Value = state end,
})

------------------------------------------------------------
-- 16. Upgrades tab
------------------------------------------------------------
registerToggle("AutoBarbell", false)
UpgradesTab:Toggle({
    Title = "Auto Upgrade Barbell",
    Description = "Buys the next barbell level whenever you can afford it",
    Default = false,
    Callback = function(state) Toggles.AutoBarbell.Value = state end,
})

registerToggle("AutoAddMutation", false)
UpgradesTab:Toggle({
    Title = "Auto Add Pets To Mutation Machine",
    Description = "Feeds five matching pets into the machine",
    Default = false,
    Callback = function(state) Toggles.AutoAddMutation.Value = state end,
})

registerOption("MutationMode", "Auto Select")
UpgradesTab:Dropdown({
    Title = "Pet Choice",
    Values = { "Auto Select", "Chosen Animal" },
    Default = "Auto Select",
    Callback = function(state) Options.MutationMode.Value = state end,
})

registerOption("MutationAnimal", AnimalNames[1] or "None")
UpgradesTab:Dropdown({
    Title = "Chosen Animal",
    Values = AnimalNames,
    Default = AnimalNames[1] or "None",
    Searchable = true,
    Callback = function(state) Options.MutationAnimal.Value = state end,
})

registerToggle("AutoClaimMutation", false)
UpgradesTab:Toggle({
    Title = "Auto Claim Gold Mutation",
    Description = "Claims the finished gold pet",
    Default = false,
    Callback = function(state) Toggles.AutoClaimMutation.Value = state end,
})

registerToggle("AutoReturnMutation", false)
UpgradesTab:Toggle({
    Title = "Auto Return Mutation Pets",
    Description = "Returns stored pets when the machine allows it",
    Default = false,
    Callback = function(state) Toggles.AutoReturnMutation.Value = state end,
})

------------------------------------------------------------
-- 17. Settings tab
------------------------------------------------------------
registerToggle("AntiAFK", true)
SettingsTab:Toggle({
    Title = "Anti-AFK",
    Description = "Jumps every 5 minutes so Roblox never kicks you",
    Default = true,
    Callback = function(state) Toggles.AntiAFK.Value = state end,
})

SettingsTab:Button({
    Title = "Unload Stealth",
    Description = "Removes the menu and stops all automation",
    Callback = function()
        Library:Unload()
    end,
})

------------------------------------------------------------
-- 18. Automation logic (from original, unchanged)
------------------------------------------------------------
local function isSelected(selection, value)
    if type(selection) ~= "table" then
        return true
    end
    local count = 0
    for _ in pairs(selection) do
        count += 1
    end
    if count == 0 then
        return true
    end
    return selection[value] == true
end

local function zoneReachable(zone)
    local required = ZoneJumpRequirements[zone]
    if required == nil then
        return true
    end
    local jumpPower = LocalPlayer:FindFirstChild("JumpPower")
    jumpPower = jumpPower and tonumber(jumpPower.Value) or 0
    return jumpPower >= required
end

local function findEggPrompt(mode)
    local map = workspace:FindFirstChild("Map")
    local stages = map and map:FindFirstChild("Stages")
    if not stages then
        return nil, nil
    end
    local root = getRoot()
    local origin = root and root.Position or Vector3.zero
    local zoneFilter = Options.StealZones and Options.StealZones.Value or nil
    local rarityFilter = Options.StealRarities and Options.StealRarities.Value or nil
    local bestPrompt, bestScore, bestPosition
    for _, stage in ipairs(stages:GetChildren()) do
        local spawned = stage:FindFirstChild("SpawnedEggs")
        if spawned and isSelected(zoneFilter, stage.Name) then
            for _, egg in ipairs(spawned:GetChildren()) do
                local rarity = egg:GetAttribute("Rarity")
                if isSelected(rarityFilter, rarity) then
                    local prompt = egg:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt and prompt.Enabled then
                        local worldPosition = holderPosition(prompt.Parent)
                        if worldPosition then
                            local distance = (worldPosition - origin).Magnitude
                            local rarityIndex = 0
                            if Rarities and Rarities.GetIndex then
                                rarityIndex = Rarities.GetIndex(rarity) or 0
                            end
                            local score
                            if mode == "Nearest Egg" then
                                score = -distance
                            elseif mode == "Best Egg" then
                                if not zoneReachable(stage.Name) then
                                    continue
                                end
                                score = rarityIndex * 1000000 - distance * 0.001
                            else
                                score = rarityIndex * 1000000 - distance * 0.001
                            end
                            if not bestScore or score > bestScore then
                                bestPrompt, bestScore, bestPosition = prompt, score, worldPosition
                            end
                        end
                    end
                end
            end
        end
    end
    return bestPrompt, bestPosition
end

local LastIndexClaim = 0
local LastBarbellAction = 0
local CarryWatchSince = nil
local NextStealAt = 0
local NextPlaceAttempt = 0
local PlaceRotation = 0

local function doCarryRecovery()
    if not Toggles.AutoSteal.Value and not Toggles.AutoPlace.Value then
        CarryWatchSince = nil
        return
    end
    local carried = (tonumber(LocalPlayer:GetAttribute("CarriedEggCount")) or 0) > 0
    local tool = findTool(isEggTool)
    if carried and not tool then
        local base = getPlacementDetector()
        local root = getRoot()
        if base and root and (root.Position - base.Position).Magnitude > 40 then
            teleportTo(base.Position)
            task.wait(0.4)
        end
        if not CarryWatchSince then
            CarryWatchSince = os.clock()
        elseif os.clock() - CarryWatchSince > 30 and DropEggRequest then
            DropEggRequest:FireServer()
            CarryWatchSince = os.clock()
            task.wait(0.5)
        end
    else
        CarryWatchSince = nil
    end
end

local function doAutoTrain()
    if not Toggles.AutoTrain.Value then
        return
    end
    if Toggles.AutoHatch.Value and countReadyEggs() > 0 then
        if LocalPlayer:GetAttribute("IsSquatting") == true and StopSquattingRequest then
            StopSquattingRequest:FireServer()
        end
        return
    end
    if Toggles.AutoSteal.Value and (tonumber(LocalPlayer:GetAttribute("CarriedEggCount")) or 0) > 0 then
        return
    end
    local detector = getSquatDetector()
    local root = getRoot()
    if not detector or not root then
        return
    end
    if (root.Position - detector.Position).Magnitude > 10 then
        teleportTo(detector.Position)
        task.wait(0.3)
    end
    if LocalPlayer:GetAttribute("IsSquatting") ~= true and SquatTrainingRequest then
        SquatTrainingRequest:FireServer(detector)
        task.wait(0.25)
    end
end

local LastBonusClaim = 0
local function doAutoSquatBonus()
    if not Toggles.AutoSquatBonus.Value or not SquatBonusRequest then
        return
    end
    if LocalPlayer:GetAttribute("SquatBonusAvailable") ~= true then
        return
    end
    if os.clock() - LastBonusClaim < 0.4 then
        return
    end
    LastBonusClaim = os.clock()
    local version = math.floor(tonumber(LocalPlayer:GetAttribute("SquatBonusVersion")) or 0)
    SquatBonusRequest:FireServer(version)
end

local function doAutoPlace()
    if not Toggles.AutoPlace.Value or not PlaceEggRequest then
        return
    end
    if os.clock() < NextPlaceAttempt then
        return
    end
    local list = {}
    forEachContainer(function(container)
        for _, child in ipairs(container:GetChildren()) do
            if isEggTool(child) then
                table.insert(list, child)
            end
        end
    end)
    if #list == 0 then
        return
    end
    PlaceRotation += 1
    local carrying = list[(PlaceRotation % #list) + 1]
    local humanoid = getHumanoid()
    local detector = getPlacementDetector()
    if not humanoid or not detector then
        return
    end
    NextPlaceAttempt = os.clock() + 2
    pcall(function()
        humanoid:EquipTool(carrying)
    end)
    task.wait(0.2)
    PlaceEggRequest:FireServer(carrying:GetAttribute("EggId"), detector.Position + Vector3.new(0, 2, 0))
    task.wait(0.35)
    if not carrying.Parent then
        local delay = StealDelaySlider and tonumber(StealDelaySlider.Value) or 5
        NextStealAt = os.clock() + math.max(delay, 0)
    end
end

local function doAutoSteal()
    if not Toggles.AutoSteal.Value then
        return
    end
    if os.clock() < NextStealAt then
        return
    end
    if countEggTools() >= 3 then
        return
    end
    if (tonumber(LocalPlayer:GetAttribute("CarriedEggCount")) or 0) > 0 then
        return
    end
    local prompt, position = findEggPrompt(Options.StealMode.Value)
    if not prompt or not position then
        return
    end
    if LocalPlayer:GetAttribute("IsSquatting") == true and StopSquattingRequest then
        StopSquattingRequest:FireServer()
        local deadline = os.clock() + 1.5
        while LocalPlayer:GetAttribute("IsSquatting") == true and os.clock() < deadline do
            task.wait(0.15)
        end
    end
    teleportTo(position)
    task.wait(0.35)
    if prompt.Enabled then
        fireproximityprompt(prompt)
    end
    task.wait(0.4)
    local base = getPlacementDetector()
    if base then
        teleportTo(base.Position)
        task.wait(0.6)
    end
end

local function doAutoHatch()
    if not Toggles.AutoHatch.Value then
        return
    end
    local plot = getPlot()
    local placed = plot and plot:FindFirstChild("PlacedEggs")
    if not placed then
        return
    end
    for _, egg in ipairs(placed:GetChildren()) do
        if egg:GetAttribute("HatchReady") == true then
            local prompt = egg:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt and prompt.Enabled then
                local position = holderPosition(prompt.Parent)
                if position then
                    teleportTo(position)
                    task.wait(0.25)
                end
                fireproximityprompt(prompt)
                task.wait(0.35)
                return
            end
        end
    end
end

local function findSellTarget()
    local mode = Options.SellMode.Value
    local chosen = Options.AutoSellPet.Value
    local maxCps = tonumber(Options.SellMaxCps.Value) or 1000
    local bestTool, bestCps
    forEachContainer(function(container)
        for _, child in ipairs(container:GetChildren()) do
            if isPetTool(child) then
                local name = child:GetAttribute("AnimalName") or child.Name
                local cps = tonumber(child:GetAttribute("CashPerSecond")) or math.huge
                if mode == "Chosen Pet" then
                    if name == chosen and (not bestCps or cps < bestCps) then
                        bestTool, bestCps = child, cps
                    end
                elseif cps <= maxCps and (not bestCps or cps < bestCps) then
                    bestTool, bestCps = child, cps
                end
            end
        end
    end)
    return bestTool
end

local function doAutoSell()
    if not Toggles.AutoSell.Value then
        return
    end
    if findTool(isEggTool) then
        return
    end
    local tool = findSellTarget()
    if not tool then
        return
    end
    local humanoid = getHumanoid()
    if not humanoid then
        return
    end
    pcall(function()
        humanoid:EquipTool(tool)
    end)
    local sellRoot = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Sell")
    local detector = sellRoot and sellRoot:FindFirstChild("Detector", true)
    if detector and detector:IsA("BasePart") then
        teleportTo(detector.Position)
        task.wait(0.3)
    end
    local prompt = detector and detector:FindFirstChild("SellAnimalPrompt", true)
    if prompt and prompt.Enabled then
        fireproximityprompt(prompt)
    elseif SellRemote then
        SellRemote:FireServer()
    end
    task.wait(0.4)
end

local function doAutoOffline()
    if not Toggles.AutoOffline.Value or not OfflineRewardsRemote then
        return
    end
    local pending = tonumber(LocalPlayer:GetAttribute("OfflineCashPending")) or 0
    if pending > 0 then
        OfflineRewardsRemote:FireServer("Claim")
        task.wait(0.25)
    end
end

local function doAutoIndex()
    if not Toggles.AutoIndex.Value or not IndexRewardRemote then
        return
    end
    if os.clock() - LastIndexClaim < 15 then
        return
    end
    LastIndexClaim = os.clock()
    IndexRewardRemote:FireServer("__ALL__")
end

local function ownedValue(folder, name)
    local entry = folder and folder:FindFirstChild(name)
    return entry and entry.Value == true
end

local function doAutoCoils()
    local coilData = LocalPlayer:FindFirstChild("CoilData")
    if not coilData or not CoilsRemote then
        return
    end
    local owned = coilData:FindFirstChild("Owned")
    local equipped = coilData:FindFirstChild("Equipped")
    if Toggles.AutoBuyCoils.Value and SpeedUpgrades then
        local selected = Options.BuyCoilList.Value
        if type(selected) == "table" then
            for name in pairs(selected) do
                local config = SpeedUpgrades.Get(name)
                if config and not ownedValue(owned, name) and getCash() >= config.Cost then
                    CoilsRemote:FireServer("Select", name)
                    task.wait(0.25)
                end
            end
        end
    end
    if Toggles.AutoEquipCoil.Value and SpeedUpgrades and equipped then
        local bestName, bestOrder = nil, -1
        if owned then
            for _, entry in ipairs(owned:GetChildren()) do
                if entry.Value == true then
                    local config = SpeedUpgrades.Get(entry.Name)
                    local order = config and config.Order or 0
                    if order > bestOrder then
                        bestName, bestOrder = entry.Name, order
                    end
                end
            end
        end
        if bestName and equipped.Value ~= bestName then
            CoilsRemote:FireServer("Select", bestName)
            task.wait(0.2)
        end
    end
end

local function doAutoTrails()
    local trailData = LocalPlayer:FindFirstChild("TrailData")
    if not trailData or not TrailsRemote then
        return
    end
    local owned = trailData:FindFirstChild("Owned")
    local equipped = trailData:FindFirstChild("Equipped")
    if Toggles.AutoBuyTrails.Value and TrailSettings then
        local selected = Options.BuyTrailList.Value
        if type(selected) == "table" then
            for name in pairs(selected) do
                local config = TrailSettings.Get(name)
                if config and not ownedValue(owned, name) and getCash() >= config.Cost then
                    TrailsRemote:FireServer("Select", name)
                    task.wait(0.25)
                end
            end
        end
    end
    if Toggles.AutoEquipTrail.Value and TrailSettings and equipped then
        local bestName, bestOrder = nil, -1
        if owned then
            for _, entry in ipairs(owned:GetChildren()) do
                if entry.Value == true then
                    local config = TrailSettings.Get(entry.Name)
                    local order = config and config.Order or 0
                    if order > bestOrder then
                        bestName, bestOrder = entry.Name, order
                    end
                end
            end
        end
        if bestName and equipped.Value ~= bestName then
            TrailsRemote:FireServer("Select", bestName)
            task.wait(0.2)
        end
    end
end

local function doAutoBarbell()
    if not Toggles.AutoBarbell.Value or not BarbellUpgrades or not BarbellUpgrades.GetNext then
        return
    end
    if os.clock() - LastBarbellAction < 3 then
        return
    end
    LastBarbellAction = os.clock()
    local level = LocalPlayer:FindFirstChild("BarbellLevel")
    if not level then
        return
    end
    local nextUpgrade = BarbellUpgrades.GetNext(math.max(math.floor(tonumber(level.Value) or 1), 1))
    if not nextUpgrade then
        return
    end
    local price = tonumber(nextUpgrade.CashPrice) or 0
    if getCash() < price then
        return
    end
    local plot = getPlot()
    local zone = plot and plot:FindFirstChild("SquatZone")
    local upgradeB = zone and zone:FindFirstChild("UpgradeB")
    local prompt = upgradeB and upgradeB:FindFirstChild("BarbellUpgradePrompt", true)
    if not prompt or not prompt.Enabled then
        return
    end
    local position = holderPosition(prompt.Parent)
    if position then
        teleportTo(position)
        task.wait(0.25)
    end
    fireproximityprompt(prompt)
    task.wait(0.4)
end

local function findMutationPet(targetName)
    local candidate, candidateCps
    forEachContainer(function(container)
        for _, child in ipairs(container:GetChildren()) do
            if isPetTool(child) then
                local name = child:GetAttribute("AnimalName") or child.Name
                local cps = tonumber(child:GetAttribute("CashPerSecond")) or math.huge
                if name == targetName and (not candidateCps or cps < candidateCps) then
                    candidate, candidateCps = child, cps
                end
            end
        end
    end)
    return candidate
end

local function findDuplicateAnimal()
    local counts, lowest = {}, {}
    forEachContainer(function(container)
        for _, child in ipairs(container:GetChildren()) do
            if isPetTool(child) then
                local name = child:GetAttribute("AnimalName") or child.Name
                local cps = tonumber(child:GetAttribute("CashPerSecond")) or math.huge
                counts[name] = (counts[name] or 0) + 1
                if not lowest[name] or cps < lowest[name] then
                    lowest[name] = cps
                end
            end
        end
    end)
    local bestName, bestCps
    for name, count in pairs(counts) do
        if count >= 2 and (not bestCps or lowest[name] < bestCps) then
            bestName, bestCps = name, lowest[name]
        end
    end
    return bestName
end

local function mutationPromptByName(name)
    local map = workspace:FindFirstChild("Map")
    local mutations = map and map:FindFirstChild("Mutations")
    local detector = mutations and mutations:FindFirstChild("Detector")
    local prompt = detector and detector:FindFirstChild(name, true)
    return prompt, detector
end

local function fireMutation(name, detector)
    local prompt = detector and detector:FindFirstChild(name, true)
    if not prompt or not prompt.Enabled then
        return false
    end
    local position = holderPosition(prompt.Parent)
    if position then
        teleportTo(position)
        task.wait(0.2)
    end
    fireproximityprompt(prompt)
    task.wait(0.35)
    return true
end

local function doAutoMutation()
    local active = LocalPlayer:GetAttribute("MutationCraftActive") == true
    local ready = LocalPlayer:GetAttribute("MutationCraftReady") == true
    local canRemove = LocalPlayer:GetAttribute("MutationCanRemove") == true
    local _, detector = mutationPromptByName("MutationPrompt")
    if Toggles.AutoClaimMutation.Value and active and ready then
        fireMutation("MutationPrompt", detector)
        return
    end
    if Toggles.AutoReturnMutation.Value and active and canRemove then
        fireMutation("MutationRemovePrompt", detector)
        return
    end
    if not Toggles.AutoAddMutation.Value or active then
        return
    end
    local target = LocalPlayer:GetAttribute("MutationCraftAnimalName")
    if type(target) ~= "string" or target == "" then
        if Options.MutationMode.Value == "Chosen Animal" then
            target = Options.MutationAnimal.Value
        else
            target = findDuplicateAnimal()
        end
    end
    if not target or target == "None" then
        return
    end
    local tool = findMutationPet(target)
    if not tool then
        return
    end
    local humanoid = getHumanoid()
    if not humanoid then
        return
    end
    pcall(function()
        humanoid:EquipTool(tool)
    end)
    task.wait(0.2)
    fireMutation("MutationPrompt", detector)
end

------------------------------------------------------------
-- 19. Feature loops (from original, unchanged)
------------------------------------------------------------
task.spawn(function()
    while true do
        local success, err = pcall(function()
            doCarryRecovery()
            doAutoPlace()
            doAutoSteal()
            doAutoSell()
            doAutoTrain()
            doAutoSquatBonus()
            doAutoHatch()
            doAutoBarbell()
        end)
        if not success then
            warn("[Stealth] " .. tostring(err))
        end
        task.wait(0.5)
    end
end)

task.spawn(function()
    while true do
        local success, err = pcall(function()
            doAutoOffline()
            doAutoIndex()
            doAutoCoils()
            doAutoTrails()
        end)
        if not success then
            warn("[Stealth] " .. tostring(err))
        end
        task.wait(0.5)
    end
end)

task.spawn(function()
    while true do
        local success, err = pcall(doAutoMutation)
        if not success then
            warn("[Stealth] " .. tostring(err))
        end
        task.wait(6)
    end
end)

task.spawn(function()
    while true do
        task.wait(300)
        if Toggles.AntiAFK.Value then
            pcall(function()
                local humanoid = getHumanoid()
                if humanoid then
                    humanoid.Jump = true
                end
                local virtualUser = game:GetService("VirtualUser")
                virtualUser:CaptureController()
                virtualUser:ClickButton2(Vector2.new())
            end)
        end
    end
end)

task.spawn(function()
    while true do
        pcall(function()
            StatusSession:SetTitle("Session: " .. formatClock(os.clock() - StartedAt))
            StatusCash:SetTitle("Cash: " .. abbreviate(getCash()))
            StatusLevel:SetTitle("Level: " .. tostring(getLevel()))
            StatusEggs:SetTitle(string.format("Carried eggs: %d | Placed: %d", countEggTools(), countPlacedEggs()))
            StatusSquat:SetTitle("Squatting: " .. tostring(LocalPlayer:GetAttribute("IsSquatting") == true))
        end)
        task.wait(1)
    end
end)

notify("Stealth", "Loaded for " .. gameName .. ". RightShift toggles the menu.")
print("[Stealth] Loaded " .. gameName .. " via WindUI")
