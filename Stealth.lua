-- [[ Stealth | Key System (Patriot) ]]
-- Key system with Patriot UI, validated against sstealth.vercel.app

local STEALTH_API = "https://sstealth.vercel.app"
local MAIN_SCRIPT_URL = "https://raw.githubusercontent.com/requiemzc/Stealth/main/Main.lua"

------------------------------------------------------------
-- 1. Load Patriot
------------------------------------------------------------
local Patriot = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/SyndromeXph/Patriot-Key-System-Ui-Library/refs/heads/main/PatriotUi.luau"
))()

------------------------------------------------------------
-- 2. HWID
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
-- 3. Key persistence
------------------------------------------------------------
local function saveKey(key) pcall(function() writefile("Stealth_Key.txt", key or "") end) end
local function clearSavedKey() pcall(function() if isfile and isfile("Stealth_Key.txt") then delfile("Stealth_Key.txt") end end) end
local function loadSavedKey()
    local ok, content = pcall(function() if isfile and isfile("Stealth_Key.txt") then return readfile("Stealth_Key.txt") end end)
    if ok and type(content) == "string" and content:find("^FREE_") then return content end
    return nil
end

------------------------------------------------------------
-- 4. Key validation
------------------------------------------------------------
local function validateKey(key)
    if not key or key == "" then return false, "Enter a key" end
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
    if not body then return false, "Encode failed" end
    local reqFn = request or http_request or nil
    if not reqFn then return false, "No HTTP" end
    local res
    local ok, err = pcall(function() res = reqFn({ Url = STEALTH_API .. "/api/validate", Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = body }) end)
    if not ok or not res then return false, "Request failed" end
    local data
    pcall(function() data = HttpService:JSONDecode(res.Body) end)
    if not data then return false, "Bad response" end
    if data.valid == true then
        saveKey((type(data.key) == "string" and #data.key > 0) and data.key or key)
        return true
    else
        local errCode = data.error or "UNKNOWN"
        if errCode == "KEY_NOT_FOUND" or errCode == "KEY_EXPIRED" or errCode == "HWID_LOCKED" or errCode == "KEY_REVOKED" then clearSavedKey() end
        local messages = { KEY_NOT_FOUND = "Key does not exist. Get one at " .. STEALTH_API .. "/", KEY_EXPIRED = "Key expired. Get a new one.", HWID_LOCKED = "Key locked to another device.", KEY_REVOKED = "Key revoked by admin." }
        return false, messages[errCode] or "Validation failed: " .. errCode
    end
end

------------------------------------------------------------
-- 5. Webhook log
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
-- 6. Key save/load from file (Patriot Storage)
------------------------------------------------------------
local KEY_FILE = "Stealth_Key.txt"

local function safeReadFile(name)
    if not readfile then return nil end
    local ok, content = pcall(function() return readfile(name) end)
    if ok and type(content) == "string" and #content > 0 then return content end
    return nil
end

local function safeWriteFile(name, content)
    if not writefile then return false end
    local ok = pcall(function() writefile(name, content) end)
    return ok
end

local function safeDeleteFile(name)
    if not delfile then return end
    pcall(function() delfile(name) end)
end

local function saveKey(key) safeWriteFile(KEY_FILE, key or "") end
local function clearSavedKey() safeDeleteFile(KEY_FILE) end
local function loadSavedKey()
    local content = safeReadFile(KEY_FILE)
    if content then
        content = content:match("^%s*(.-)%s*$") or content
        if content:find("^FREE_") then return content end
    end
    return nil
end

------------------------------------------------------------
-- 7. Patriot setup
------------------------------------------------------------
Patriot.Callbacks.OnVerify = function(key)
    if not key or key == "" then return false end

    local HttpService = game:GetService("HttpService")
    local Players = game:GetService("Players")
    local MarketplaceService = game:GetService("MarketplaceService")
    local hwid = getHWID()

    local username, userId, placeId, placeName
    pcall(function()
        local lp = Players.LocalPlayer
        username = lp.Name
        userId = lp.UserId
    end)
    pcall(function()
        placeId = game.PlaceId
        local info = MarketplaceService:GetProductInfo(game.PlaceId)
        placeName = info and info.Name or nil
    end)

    local body
    local ok, err = pcall(function()
        body = HttpService:JSONEncode({ key = key, hwid = hwid, username = username, userId = userId, placeId = placeId, placeName = placeName })
    end)
    if not ok or not body then
        return { valid = false, error = "CLIENT_ERROR", message = "Failed to encode request" }
    end

    local reqFn = request or http_request or nil
    if not reqFn then
        return { valid = false, error = "NO_HTTP", message = "No HTTP function available" }
    end

    local res
    ok, err = pcall(function()
        res = reqFn({ Url = STEALTH_API .. "/api/validate", Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = body })
    end)
    if not ok or not res then
        return { valid = false, error = "REQUEST_FAILED", message = tostring(err) }
    end

    local data
    ok, err = pcall(function() data = HttpService:JSONDecode(res.Body) end)
    if not ok or not data then
        return { valid = false, error = "BAD_RESPONSE", message = tostring(res.Body) }
    end

    if data.valid == true then
        local keyToSave = (type(data.key) == "string" and #data.key > 0) and data.key or key
        saveKey(keyToSave)
        return true
    end

    if data.error == "KEY_NOT_FOUND" or data.error == "KEY_EXPIRED" or data.error == "HWID_LOCKED" or data.error == "KEY_REVOKED" then
        clearSavedKey()
    end

    local messages = {
        KEY_NOT_FOUND = "This key does not exist. Get a fresh one at " .. STEALTH_API .. "/",
        KEY_EXPIRED   = "This key has expired. Get a new one at " .. STEALTH_API .. "/",
        HWID_LOCKED   = "This key is locked to a different device. Get your own at " .. STEALTH_API .. "/",
        KEY_REVOKED   = "This key has been revoked by an admin.",
    }
    return { valid = false, error = data.error or "UNKNOWN", message = messages[data.error] or "Validation failed." }
end

------------------------------------------------------------
-- 8. Branding
------------------------------------------------------------
Patriot.Appearance = {
    Title    = "Stealth",
    Subtitle = "Verify your key to continue",
    Icon     = "rbxassetid://94734287536234",
    IconSize = UDim2.new(0, 30, 0, 30),
}

------------------------------------------------------------
-- 9. Links
------------------------------------------------------------
local getKeyURL = STEALTH_API .. "/keysys"
do
    local ok, err = pcall(function()
        local lp = game:GetService("Players").LocalPlayer
        if lp then
            local u = tostring(lp.UserId)
            local n = game:GetService("HttpService"):UrlEncode(lp.Name)
            if #u > 0 and #n > 0 then
                getKeyURL = getKeyURL .. "?u=" .. u .. "&n=" .. n
            end
        end
    end)
end

Patriot.Links = {
    GetKey  = getKeyURL,
    Discord = "https://discord.gg/hqE5drDHF7",
}

------------------------------------------------------------
-- 10. Storage
------------------------------------------------------------
Patriot.Storage = {
    FileName = "Stealth_Key",
    Remember = true,
    AutoLoad = true,
}

------------------------------------------------------------
-- 11. Inject saved key
------------------------------------------------------------
local function tryInjectSavedKey(key)
    if not key then return end
    pcall(function() Patriot.SavedKey = key end)
    pcall(function() if Patriot.SetKey then Patriot:SetKey(key) end end)
    pcall(function() if Patriot.AutoLoadKey then Patriot:AutoLoadKey(key) end end)
    pcall(function() if Patriot.LoadKey then Patriot:LoadKey(key) end end)
end

local savedKey = loadSavedKey()
if savedKey then
    print("[Stealth] Found saved key, attempting auto-load...")
    tryInjectSavedKey(savedKey)
end

------------------------------------------------------------
-- 12. Options
------------------------------------------------------------
Patriot.Options = {
    Keyless  = false,
    Blur     = true,
    Draggable= true,
}

------------------------------------------------------------
-- 13. Theme
------------------------------------------------------------
Patriot.Theme = {
    Accent       = Color3.fromRGB(48, 255, 106),
    AccentHover  = Color3.fromRGB(80, 255, 130),
    Background   = Color3.fromRGB(10, 10, 12),
    Header       = Color3.fromRGB(15, 15, 18),
    Input        = Color3.fromRGB(20, 20, 25),
    Text         = Color3.fromRGB(255, 255, 255),
    TextDim      = Color3.fromRGB(130, 130, 140),
    Success      = Color3.fromRGB(48, 255, 106),
    Error        = Color3.fromRGB(255, 50, 80),
    Warning      = Color3.fromRGB(255, 200, 0),
    StatusIdle   = Color3.fromRGB(48, 255, 106),
    Discord      = Color3.fromRGB(48, 255, 106),
    DiscordHover = Color3.fromRGB(80, 255, 130),
    Divider      = Color3.fromRGB(30, 30, 35),
    Pending      = Color3.fromRGB(40, 40, 45),
}

------------------------------------------------------------
-- 14. On success — load Main.lua
------------------------------------------------------------
Patriot.Callbacks.OnSuccess = function()
    print("[Stealth] Key validated! Loading main script...")
    Patriot:Notify("Stealth", "Key validated! Loading...", 2, "success")

    local ok, err = pcall(function()
        loadstring(game:HttpGet(MAIN_SCRIPT_URL))()
    end)
    if not ok then
        warn("[Stealth] Failed to load main script:", err)
        Patriot:Notify("Stealth", "Failed to load main script: " .. tostring(err), 6, "error")
        return
    end

    Patriot:Notify("Stealth", "Main script loaded!", 4, "shield")
end

Patriot.Callbacks.OnFail = function(errorMsg)
    print("[Stealth] Verification failed:", errorMsg)
end

Patriot.Callbacks.OnClose = function()
    print("[Stealth] User closed the verification window")
end

------------------------------------------------------------
-- 15. Launch
------------------------------------------------------------
Patriot:Launch()

print("[Stealth] Loader initialized with Patriot key system")
