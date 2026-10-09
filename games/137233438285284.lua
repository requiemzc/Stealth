-- Stealth loading screen
local _sl = Instance.new("ScreenGui")
_sl.Name = "StealthLoading"
_sl.ResetOnSpawn = false
_sl.IgnoreGuiInset = true
_sl.DisplayOrder = 9999
local _sf = Instance.new("Frame")
_sf.Size = UDim2.new(1, 0, 1, 0)
_sf.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
_sf.Parent = _sl
local _st = Instance.new("TextLabel")
_st.Text = "Stealth"
_st.Font = Enum.Font.GothamBold
_st.TextSize = 48
_st.TextColor3 = Color3.fromRGB(255, 255, 255)
_st.BackgroundTransparency = 1
_st.Size = UDim2.new(1, 0, 0, 60)
_st.Position = UDim2.new(0, 0, 0.35, 0)
_st.Parent = _sf
local _ss = Instance.new("TextLabel")
_ss.Text = "Join Discord for dupe"
_ss.Font = Enum.Font.Gotham
_ss.TextSize = 18
_ss.TextColor3 = Color3.fromRGB(120, 120, 140)
_ss.BackgroundTransparency = 1
_ss.Size = UDim2.new(1, 0, 0, 30)
_ss.Position = UDim2.new(0, 0, 0.35, 60)
_ss.Parent = _sf
local _sd = Instance.new("TextLabel")
_sd.Text = "discord.gg/hqE5drDHF7"
_sd.Font = Enum.Font.GothamMedium
_sd.TextSize = 16
_sd.TextColor3 = Color3.fromRGB(88, 101, 242)
_sd.BackgroundTransparency = 1
_sd.Size = UDim2.new(1, 0, 0, 30)
_sd.Position = UDim2.new(0, 0, 0.35, 95)
_sd.Parent = _sf
local _sl2 = Instance.new("TextLabel")
_sl2.Text = "Loading..."
_sl2.Font = Enum.Font.Gotham
_sl2.TextSize = 14
_sl2.TextColor3 = Color3.fromRGB(100, 100, 120)
_sl2.BackgroundTransparency = 1
_sl2.Size = UDim2.new(1, 0, 0, 20)
_sl2.Position = UDim2.new(0, 0, 0.7, 0)
_sl2.Parent = _sf
pcall(function() _sl.Parent = game:GetService("CoreGui") end)
if not _sl.Parent then
    _sl.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
end
task.spawn(function() task.wait(3) _sl:Destroy() end)

local connection
local cy
local cn
local cq
local cB
local Options
local ci
local VirtualUser
local Library
local co
local cz
local cr
local cj
local cu
local Network
local Toggles
local cp
local cA
local LocalPlayer
local ch
local cv
local function fn3()
    for k in co do
        if Library.Unloaded or not Toggles.AutoBuy.Value then
            break
        end
        local dl_1 = cq[k]
        if dl_1 then
            pcall(dl_1)
            task.wait(0.15)
        end
    end
end
local function fn6()
    local Map = workspace:FindFirstChild("Map")
    local dg = Map and Map:FindFirstChild("EggMultiplierPart")
    local df_1 = dg
    if dg then
        dg = df_1:FindFirstChild("UI")
    end
    local df_2 = dg
    if dg then
        dg = df_2:FindFirstChild("Multi")
    end
    local df_3 = dg
    if dg then
        dg = tonumber(df_3.Text:match("%d+%.?%d*"))
    end
    local df_4 = dg
    if not df_4 or df_4 < Options.MinimumEggMultiplier.Value then
        return
    end
    pcall(function()
        Network.InvokeServer("Deposit Eggs")
    end)
end
local function autoCollectEggsLoop()
    while not Library.Unloaded do
        if Toggles.AutoCollectEggs.Value then
            cA()
        end
        task.wait(0.3)
    end
end
local function fn32()
    pcall(function()
        Network.InvokeServer("Merge Chickens")
    end)
end
local function fn33()
    Network.InvokeServer("Claim Group Reward")
end
local function fn42()
    local Eggs = workspace:FindFirstChild("Eggs")
    if not Eggs then
        return
    end
    for i, child in Eggs:GetChildren() do
        if Library.Unloaded or not Toggles.AutoCollectEggs.Value then
            break
        end
        Network.FireServer("Collect Egg", child.Name)
    end
end
local function fn58()
    local Eggs = workspace:FindFirstChild("Eggs")
    if not Eggs then
        return
    end
    for i, child in Eggs:GetChildren() do
        if Library.Unloaded or not Toggles.RemoveEggModels.Value then
            break
        end
        child:Destroy()
    end
end
local function fn64()
    if setclipboard then
        setclipboard(cj)
    elseif toclipboard then
        toclipboard(cj)
    end
    Library:Notify("Copied Discord invite to clipboard")
end
local function onAntiAfk(a2)
    if a2 then
        if not connection then
            connection = LocalPlayer.Idled:Connect(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end
    elseif connection then
        connection:Disconnect()
        connection = nil
    end
end
local function fn140()
    Network.InvokeServer("Merge Chickens")
end
local function fn148(aG)
    local DiscordGroup = aG:AddLeftGroupbox("Discord")
    DiscordGroup:AddButton({ Text = "Join Discord to Make Money", Func = cv })
    DiscordGroup:AddButton({ Text = "Join Discord for Keyless Scripts", Func = cv })
end
local function autoMergeLoop()
    while not Library.Unloaded do
        if Toggles.AutoMerge.Value then
            cr()
        end
        task.wait(0.5)
    end
end
local function autoUpgradeLoop()
    while not Library.Unloaded do
        if Toggles.AutoUpgrade.Value then
            ci()
        end
        task.wait(0.5)
    end
end
local function fn159()
    if connection then
        connection:Disconnect()
        connection = nil
    end
end
local function onUpgrades(aW)
    local dJ = {}
    for k, v in aW do
        if v then
            dJ[k] = true
        end
    end
    ch = dJ
end
local function fn174()
    Network.InvokeServer("Upgrade Buy Tier Level")
end
local function autoCollectCashLoop()
    while not Library.Unloaded do
        if Toggles.AutoCollectCash.Value then
            cn()
        end
        task.wait(0.5)
    end
end
local function autoDepositLoop()
    while not Library.Unloaded do
        if Toggles.AutoDeposit.Value then
            cp()
        end
        task.wait(0.5)
    end
end
local function onUnload()
    Library:Unload()
end
local function fn228()
    pcall(function()
        Network.InvokeServer("Collect Cash")
    end)
end
local function removeEggModelsLoop()
    while not Library.Unloaded do
        if Toggles.RemoveEggModels.Value then
            cu()
        end
        task.wait(0.3)
    end
end
local function autoBuyLoop()
    while not Library.Unloaded do
        if Toggles.AutoBuy.Value then
            cz()
        end
        task.wait(0.5)
    end
end
local function onBuyables(aN)
    local dz = {}
    for k, v in aN do
        if v then
            dz[k] = true
        end
    end
    co = dz
end
local function fn251()
    Network.InvokeServer("Upgrade Process Level")
end
local function fn258()
    Network.InvokeServer("Buy Chickens", cy)
end
local function onBuyChickensAmount(aS)
    if type(aS) == "number" then
        aS = cB[aS]
    end
    local dH = tonumber(aS) or 1
    cy = dH
end
ch = nil
ci = nil
cj = nil
connection = nil
Library = nil
Network = nil
cn = nil
co = nil
cp = nil
cq = nil
cr = nil
LocalPlayer = nil
Options = nil
cu = nil
cv = nil
VirtualUser = nil
Toggles = nil
cy = nil
cz = nil
cA = nil
cB = nil
VirtualUser, LocalPlayer, Library, Toggles, Options, Network, cj, cB, cy, cq, co, ch, cA, cu, cp, cn, cz, cr, ci, cv = nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
VirtualUser = game:GetService("VirtualUser")
LocalPlayer = Players.LocalPlayer
Library = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local ThemeManager = nil
SaveManager = nil
Toggles = Library.Toggles
Options = Library.Options
local Paper = require(ReplicatedStorage.Paper)
Network = Paper.Network
cj = "https://discord.gg/hqE5drDHF7"
cB = { "1", "5", "25", "100" }
cy = 1
local cL = {
    "Buy Chickens",
    "Merge Chickens",
    "Upgrade Process Level",
    "Upgrade Buy Tier Level",
    "Claim Group Reward"
}
cq = {
    ["Buy Chickens"] = fn258,
    ["Merge Chickens"] = fn140,
    ["Upgrade Process Level"] = fn251,
    ["Upgrade Buy Tier Level"] = fn174,
    ["Claim Group Reward"] = fn33
}
co = {}
local cK = { "Upgrade Process Level", "Upgrade Buy Tier Level" }
ch = {}
cA = fn42
cu = fn58
cp = fn6
cn = fn228
cz = fn3
cr = fn32
ci = function()
    for k in ch do
        local dx = k
        if Library.Unloaded or not Toggles.AutoUpgrade.Value then
            break
        end
        pcall(function()
            Network.InvokeServer(dx)
        end)
        task.wait(0.15)
    end
end
cv = fn64
local Window = Library:CreateWindow({
    Title = "Stealth",
    Footer = "Stealth",
    Icon = 18657887261,
    NotifySide = "Right",
    Size = UDim2.fromOffset(900, 640)
})
local cN = { Main = Window:AddTab("Main", "egg"), Settings = Window:AddTab("Settings", "settings") }
for k, v in cN do
    fn148(v)
end
connection = nil
local FarmGroup = cN.Main:AddLeftGroupbox("Farm", "wheat")
FarmGroup:AddToggle("AutoCollectEggs", { Text = "Auto Collect Eggs", Default = false })
FarmGroup:AddLabel("Auto Collect works, but collected eggs stay on the conveyor visually. Enable Remove Egg Models to clear them locally.", true)
FarmGroup:AddToggle("RemoveEggModels", { Text = "Remove Egg Models", Default = false })
FarmGroup:AddToggle("AutoDeposit", { Text = "Auto Deposit", Default = false })
FarmGroup:AddSlider("MinimumEggMultiplier", { Text = "Minimum Egg Multiplier", Default = 1.01, Min = 0.7, Max = 2, Rounding = 2, Suffix = "x" })
FarmGroup:AddToggle("AutoCollectCash", { Text = "Auto Collect Cash", Default = false })
local AutoBuyGroup = cN.Main:AddRightGroupbox("Auto Buy", "shopping-cart")
AutoBuyGroup:AddToggle("AutoBuy", { Text = "Auto Buy", Default = false })
AutoBuyGroup:AddDropdown("Buyables", { Text = "Buyables", Values = cL, Default = {}, Multi = true, Callback = onBuyables })
AutoBuyGroup:AddDropdown("BuyChickensAmount", {
    Text = "Buy Chickens Amount",
    Values = cB,
    Default = 1,
    Multi = false,
    Callback = onBuyChickensAmount
})
local Merge_UpgradeGroup = cN.Main:AddRightGroupbox("Merge & Upgrade", "trending-up")
Merge_UpgradeGroup:AddToggle("AutoMerge", { Text = "Auto Merge", Default = false })
Merge_UpgradeGroup:AddToggle("AutoUpgrade", { Text = "Auto Upgrade", Default = false })
Merge_UpgradeGroup:AddDropdown("Upgrades", { Text = "Upgrades", Values = cK, Default = {}, Multi = true, Callback = onUpgrades })
local MenuGroup = cN.Settings:AddLeftGroupbox("Menu", "wrench")
MenuGroup:AddLabel("UI Keybind"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "UI Keybind" })
MenuGroup:AddToggle("AntiAfk", { Text = "Anti-AFK", Default = true, Callback = onAntiAfk })
MenuGroup:AddButton("Unload", onUnload)
Library.ToggleKeybind = Options.MenuKeybind
Library:OnUnload(fn159)
if ThemeManager then ThemeManager:SetLibrary(Library) end
ThemeManager:SetFolder("Stealth")
ThemeManager:SaveDefault("Mint")
if SaveManager then SaveManager:SetLibrary(Library) end
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
SaveManager:SetFolder("Stealth/ChickenFarm")
SaveManager:BuildConfigSection(cN.Settings)
if ThemeManager then ThemeManager:ApplyToTab() end
ThemeManager:LoadDefault()
if SaveManager then SaveManager:LoadAutoloadConfig() end
task.spawn(autoCollectEggsLoop)
task.spawn(removeEggModelsLoop)
task.spawn(autoDepositLoop)
task.spawn(autoCollectCashLoop)
task.spawn(autoBuyLoop)
task.spawn(autoMergeLoop)
task.spawn(autoUpgradeLoop)
