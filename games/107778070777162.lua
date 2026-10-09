
-- Stealth loading screen
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "StealthLoading"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 9999
local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(1, 0, 1, 0)
Frame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
Frame.Parent = ScreenGui
local Title = Instance.new("TextLabel")
Title.Text = "Stealth"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 48
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.BackgroundTransparency = 1
Title.Size = UDim2.new(1, 0, 0, 60)
Title.Position = UDim2.new(0, 0, 0.35, 0)
Title.Parent = Frame
local Subtitle = Instance.new("TextLabel")
Subtitle.Text = "Join Discord for dupe"
Subtitle.Font = Enum.Font.Gotham
Subtitle.TextSize = 18
Subtitle.TextColor3 = Color3.fromRGB(120, 120, 140)
Subtitle.BackgroundTransparency = 1
Subtitle.Size = UDim2.new(1, 0, 0, 30)
Subtitle.Position = UDim2.new(0, 0, 0.35, 60)
Subtitle.Parent = Frame
local DiscordBtn = Instance.new("TextButton")
DiscordBtn.Text = "discord.gg/hqE5drDHF7"
DiscordBtn.Font = Enum.Font.GothamMedium
DiscordBtn.TextSize = 16
DiscordBtn.TextColor3 = Color3.fromRGB(88, 101, 242)
DiscordBtn.BackgroundTransparency = 1
DiscordBtn.Size = UDim2.new(1, 0, 0, 30)
DiscordBtn.Position = UDim2.new(0, 0, 0.35, 95)
DiscordBtn.Parent = Frame
local Loading = Instance.new("TextLabel")
Loading.Text = "Loading..."
Loading.Font = Enum.Font.Gotham
Loading.TextSize = 14
Loading.TextColor3 = Color3.fromRGB(100, 100, 120)
Loading.BackgroundTransparency = 1
Loading.Size = UDim2.new(1, 0, 0, 20)
Loading.Position = UDim2.new(0, 0, 0.7, 0)
Loading.Parent = Frame
pcall(function()
    ScreenGui.Parent = game:GetService("CoreGui")
end)
if not ScreenGui.Parent then
    ScreenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
end
task.spawn(function()
    task.wait(3)
    ScreenGui:Destroy()
end)

-- Stealth :: Steal an Egg support notice
local Players = game:GetService("Players")

Players.LocalPlayer:Kick(table.concat({
    "Steal an Egg: No Longer Updated/Supported.",
    "\240\159\135\181\240\159\135\173 Hindi na updated/suportado.",
    "\240\159\135\187\240\159\135\179 Kh\195\180ng c\195\178n c\225\186\173p nh\225\186\173t/h\225\187\151 tr\225\187\163.",
    "\240\159\135\174\240\159\135\169 Tidak diperbarui/didukung.",
    "\240\159\135\183\240\159\135\186 \208\145\208\190\208\187\209\140\209\136\208\181 \208\189\208\181 \208\190\208\177\208\189\208\190\208\178\208\187\209\143\208\181\209\130\209\129\209\143/\208\191\208\190\208\180\208\180\208\181\209\128\208\182\208\184\208\178\208\176\208\181\209\130\209\129\209\143.",
    "\240\159\135\169\240\159\135\170 Nicht mehr aktualisiert/unterst\195\188tzt.",
    "\240\159\135\185\240\159\135\173 \224\185\132\224\184\161\224\185\136\224\184\173\224\184\177\224\184\155\224\185\128\224\184\148\224\184\149/\224\184\163\224\184\173\224\184\135\224\184\163\224\184\177\224\184\154\224\185\129\224\184\165\224\185\137\224\184\167",
}, "\n"))
