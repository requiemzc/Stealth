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
