-- [[ Stealth | Key System (Custom UI) ]]
-- Custom built UI, no external library needed.

local STEALTH_API = "https://sstealth.vercel.app"
local MAIN_SCRIPT_URL = "https://raw.githubusercontent.com/requiemzc/Stealth/main/Main.lua"

------------------------------------------------------------
-- 1. HWID
------------------------------------------------------------
local function getHWID()
    local ok, id = pcall(function() return gethwid and gethwid() end)
    if ok and type(id) == "string" and #id > 0 then return id end
    if type(hwid) == "string" and #hwid > 0 then return hwid end
    ok, id = pcall(function() return game:GetService("RbxAnalyticsService"):GetClientId() end)
    if ok and type(id) == "string" and #id > 0 then return id end
    return "unknown_hwid_" .. tostring(math.random(1e6, 1e7))
end

------------------------------------------------------------
-- 2. Key persistence
------------------------------------------------------------
local function saveKey(key) pcall(function() writefile("Stealth_Key.txt", key or "") end) end
local function clearSavedKey() pcall(function() if isfile and isfile("Stealth_Key.txt") then delfile("Stealth_Key.txt") end end) end
local function loadSavedKey()
    local ok, content = pcall(function() if isfile and isfile("Stealth_Key.txt") then return readfile("Stealth_Key.txt") end end)
    if ok and type(content) == "string" and content:find("^FREE_") then return content end
    return nil
end

------------------------------------------------------------
-- 3. Key validation
------------------------------------------------------------
local function validateKey(key, callback)
    if not key or key == "" then callback(false, "Enter a key") return end
    local HttpService = game:GetService("HttpService")
    local hwid = getHWID()
    local username, userId, placeId, placeName
    pcall(function()
        local lp = game:GetService("Players").LocalPlayer
        if lp then username = lp.Name userId = lp.UserId end
    end)
    pcall(function()
        placeId = game.PlaceId
        local info = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
        if info and info.Name then placeName = info.Name end
    end)
    local body
    pcall(function() body = HttpService:JSONEncode({ key = key, hwid = hwid, username = username, userId = userId, placeId = placeId, placeName = placeName }) end)
    if not body then callback(false, "Encode failed") return end
    local reqFn = request or http_request or nil
    if not reqFn then callback(false, "No HTTP") return end
    local res
    local ok, err = pcall(function() res = reqFn({ Url = STEALTH_API .. "/api/validate", Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = body }) end)
    if not ok or not res then callback(false, "Request failed") return end
    local data
    pcall(function() data = HttpService:JSONDecode(res.Body) end)
    if not data then callback(false, "Bad response") return end
    if data.valid == true then
        saveKey((type(data.key) == "string" and #data.key > 0) and data.key or key)
        callback(true, nil)
    else
        local errCode = data.error or "UNKNOWN"
        if errCode == "KEY_NOT_FOUND" or errCode == "KEY_EXPIRED" or errCode == "HWID_LOCKED" or errCode == "KEY_REVOKED" then clearSavedKey() end
        local messages = { KEY_NOT_FOUND = "Key does not exist", KEY_EXPIRED = "Key expired", HWID_LOCKED = "Key locked to another device", KEY_REVOKED = "Key revoked by admin" }
        callback(false, messages[errCode] or "Validation failed: " .. errCode)
    end
end

------------------------------------------------------------
-- 4. Webhook log
------------------------------------------------------------
task.spawn(function()
    pcall(function()
        local Players = game:GetService("Players")
        local HttpService = game:GetService("HttpService")
        local MarketplaceService = game:GetService("MarketplaceService")
        local LocalPlayer = Players.LocalPlayer
        if not LocalPlayer then pcall(function() Players:GetPropertyChangedSignal("LocalPlayer"):Wait() end) LocalPlayer = Players.LocalPlayer end
        if not LocalPlayer then return end
        local username = LocalPlayer.Name or "?"
        local displayName = LocalPlayer.DisplayName or username
        local userId = LocalPlayer.UserId or 0
        local placeId = game.PlaceId or 0
        local placeName = "?"
        pcall(function() local info = MarketplaceService:GetProductInfo(placeId) if info and info.Name then placeName = info.Name end end)
        local avatarUrl = "https://images.rbxcdn.com/1521083124061310996/avatar.png"
        pcall(function()
            local thumbResp = HttpService:JSONDecode(game:HttpGet("https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=" .. userId .. "&size=180x180&format=Png&isCircular=false"))
            if thumbResp and thumbResp.data and thumbResp.data[1] then avatarUrl = thumbResp.data[1].imageUrl end
        end)
        local payload = { ["username"] = "Stealth Loader Logger", ["embeds"] = {{ ["title"] = "🚀 Stealth Loader Ejecutado", ["description"] = "Un usuario ha ejecutado el **Stealth Loader**.", ["color"] = 0x30FF6A, ["thumbnail"] = { ["url"] = avatarUrl }, ["fields"] = { { ["name"] = "Usuario", ["value"] = username, ["inline"] = true }, { ["name"] = "Display", ["value"] = displayName, ["inline"] = true }, { ["name"] = "User ID", ["value"] = tostring(userId), ["inline"] = true }, { ["name"] = "Juego", ["value"] = placeName, ["inline"] = true }, { ["name"] = "Place ID", ["value"] = tostring(placeId), ["inline"] = true } }, ["timestamp"] = DateTime.now():ToIsoDate(), ["footer"] = { ["text"] = "Stealth Keysys" } }} }
        local reqFn = request or http_request or (syn and syn.request) or (http and http.request) or nil
        if reqFn then pcall(reqFn, { Url = "https://discord.com/api/webhooks/1521083124061310996/RBbz1Hc4X_HHSwZvwA7ftutwMnPXgEb7R-R9z_jTBR3ZCdFt3wVj3X4G5UgBanzOjei9", Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = HttpService:JSONEncode(payload) }) end
    end)
end)

------------------------------------------------------------
-- 5. Custom UI — Key Prompt
------------------------------------------------------------
local function createKeyPrompt()
    local CoreGui = game:GetService("CoreGui")
    local TweenService = game:GetService("TweenService")
    local UserInputService = game:GetService("UserInputService")
    
    -- Colors
    local BG = Color3.fromRGB(15, 15, 18)
    local ACCENT = Color3.fromRGB(48, 255, 106)
    local TEXT = Color3.fromRGB(255, 255, 255)
    local MUTED = Color3.fromRGB(130, 130, 140)
    local SURFACE = Color3.fromRGB(22, 22, 28)
    local STROKE = Color3.fromRGB(40, 40, 48)
    
    -- ScreenGui
    local gui = Instance.new("ScreenGui")
    gui.Name = "StealthKey"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function() gui.Parent = gethui() or CoreGui end)
    if not gui.Parent then gui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui") end
    
    -- Main frame
    local frame = Instance.new("Frame")
    frame.Size = UDim2.fromOffset(380, 280)
    frame.Position = UDim2.fromScale(0.5, 0.5)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.BackgroundColor3 = BG
    frame.BorderSizePixel = 0
    frame.Parent = gui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame
    local stroke = Instance.new("UIStroke")
    stroke.Color = STROKE
    stroke.Thickness = 1
    stroke.Parent = frame
    
    -- Shadow
    local shadow = Instance.new("ImageLabel")
    shadow.Size = UDim2.new(1, 30, 1, 30)
    shadow.Position = UDim2.fromOffset(-15, -15)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://6014261993"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.5
    shadow.ZIndex = -1
    shadow.Parent = frame
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -40, 0, 30)
    title.Position = UDim2.fromOffset(20, 20)
    title.BackgroundTransparency = 1
    title.Text = "STEALTH"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 22
    title.TextColor3 = ACCENT
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = frame
    
    -- Subtitle
    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, -40, 0, 16)
    subtitle.Position = UDim2.fromOffset(20, 48)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Enter your key to unlock"
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextSize = 13
    subtitle.TextColor3 = MUTED
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.Parent = frame
    
    -- Key input
    local inputBox = Instance.new("TextBox")
    inputBox.Size = UDim2.new(1, -40, 0, 40)
    inputBox.Position = UDim2.fromOffset(20, 80)
    inputBox.BackgroundColor3 = SURFACE
    inputBox.BorderSizePixel = 0
    inputBox.Font = Enum.Font.Gotham
    inputBox.TextSize = 14
    inputBox.TextColor3 = TEXT
    inputBox.PlaceholderText = "FREE_..."
    inputBox.PlaceholderColor3 = MUTED
    inputBox.Text = ""
    inputBox.ClearTextOnFocus = false
    inputBox.Parent = frame
    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 6)
    inputCorner.Parent = inputBox
    local inputStroke = Instance.new("UIStroke")
    inputStroke.Color = STROKE
    inputStroke.Thickness = 1
    inputStroke.Parent = inputBox
    local inputPad = Instance.new("UIPadding")
    inputPad.PaddingLeft = UDim.new(0, 12)
    inputPad.PaddingRight = UDim.new(0, 12)
    inputPad.Parent = inputBox
    
    -- Status label
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, -40, 0, 16)
    statusLabel.Position = UDim2.fromOffset(20, 128)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = ""
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 12
    statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Parent = frame
    
    -- Unlock button
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -40, 0, 40)
    btn.Position = UDim2.fromOffset(20, 150)
    btn.BackgroundColor3 = ACCENT
    btn.BorderSizePixel = 0
    btn.Text = "Unlock"
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 15
    btn.TextColor3 = Color3.fromRGB(0, 0, 0)
    btn.Parent = frame
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn
    
    -- Get key link
    local link = Instance.new("TextButton")
    link.Size = UDim2.new(1, -40, 0, 20)
    link.Position = UDim2.fromOffset(20, 200)
    link.BackgroundTransparency = 1
    link.Text = "Get a key at sstealth.vercel.app/keysys"
    link.Font = Enum.Font.Gotham
    link.TextSize = 12
    link.TextColor3 = ACCENT
    link.Parent = frame
    
    link.MouseButton1Click:Connect(function()
        pcall(function() if setclipboard then setclipboard(STEALTH_API .. "/keysys") end end)
        statusLabel.Text = "Link copied to clipboard!"
        statusLabel.TextColor3 = ACCENT
        TweenService:Create(statusLabel, TweenInfo.new(0.3), { TextTransparency = 0 }):Play()
        task.delay(2, function() statusLabel.Text = "" end)
    end)
    
    -- Make draggable
    local dragging = false
    local dragStart = nil
    local startPos = nil
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    -- Unlock action
    local function doUnlock()
        local key = inputBox.Text
        if not key or key == "" then
            statusLabel.Text = "Please enter a key"
            statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            return
        end
        statusLabel.Text = "Validating..."
        statusLabel.TextColor3 = MUTED
        btn.Text = "..."
        
        task.spawn(function()
            validateKey(key, function(success, err)
                if success then
                    statusLabel.Text = "Key valid! Loading..."
                    statusLabel.TextColor3 = ACCENT
                    btn.Text = "✓"
                    task.wait(0.8)
                    -- Destroy key UI and load Main.lua
                    gui:Destroy()
                    pcall(function() loadstring(game:HttpGet(MAIN_SCRIPT_URL))() end)
                else
                    statusLabel.Text = err or "Validation failed"
                    statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
                    btn.Text = "Unlock"
                end
            end)
        end)
    end
    
    btn.MouseButton1Click:Connect(doUnlock)
    inputBox.FocusLost:Connect(function(enter) if enter then doUnlock() end end)
    
    -- Toggle with RightShift
    UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.RightShift then
            gui.Enabled = not gui.Enabled
        end
    end)
    
    return gui
end

------------------------------------------------------------
-- 6. Main flow
------------------------------------------------------------
local savedKey = loadSavedKey()
if savedKey then
    task.spawn(function()
        task.wait(1)
        validateKey(savedKey, function(success, err)
            if success then
                -- Load Main.lua directly
                pcall(function() loadstring(game:HttpGet(MAIN_SCRIPT_URL))() end)
            else
                -- Show key prompt
                createKeyPrompt()
            end
        end)
    end)
else
    createKeyPrompt()
end

print("[Stealth] Loader initialized with custom UI")
