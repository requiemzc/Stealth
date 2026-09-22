-- [[ Stealth | Key System (Lumen UI) ]]
--
-- Validates the user's key against https://sstealth.vercel.app/api/validate
-- Keys are issued at https://sstealth.vercel.app/ and rotate every 15 minutes,
-- each locked to a single HWID on first validation. Valid keys last 2 hours.
--
-- After successful validation, Stealth loads Main.lua (from this same repo)
-- which shows a Lumen menu letting the user pick which script to run.
--
-- HOW TO USE (end user):
--   loadstring(game:HttpGet("https://raw.githubusercontent.com/requiemzc/Stealth/main/Stealth.lua"))()

local STEALTH_API = "https://sstealth.vercel.app"
local MAIN_SCRIPT_URL = "https://raw.githubusercontent.com/requiemzc/Stealth/main/Main.lua"

------------------------------------------------------------
-- 1. Load Lumen
------------------------------------------------------------
local Lumen = loadstring(game:HttpGet("https://raw.githubusercontent.com/chromatiks/Lumen/main/Library.lua"))()

------------------------------------------------------------
-- 2. HWID detection
------------------------------------------------------------
local function getHWID()
    local ok, id = pcall(function() return gethwid and gethwid() end)
    if ok and type(id) == "string" and #id > 0 then return id end
    if type(hwid) == "string" and #hwid > 0 then return hwid end
    ok, id = pcall(function()
        return game:GetService("RbxAnalyticsService"):GetClientId()
    end)
    if ok and type(id) == "string" and #id > 0 then return id end
    return "unknown_hwid_" .. tostring(math.random(1e6, 1e7))
end

------------------------------------------------------------
-- 3. Key persistence
------------------------------------------------------------
local function saveKey(key)
    pcall(function() writefile("Stealth_Key.txt", key or "") end)
end

local function clearSavedKey()
    pcall(function() if isfile and isfile("Stealth_Key.txt") then delfile("Stealth_Key.txt") end end)
end

local function loadSavedKey()
    local ok, content = pcall(function()
        if isfile and isfile("Stealth_Key.txt") then return readfile("Stealth_Key.txt") end
        return nil
    end)
    if ok and type(content) == "string" and content:find("^FREE_") then
        return content
    end
    return nil
end

------------------------------------------------------------
-- 4. Key validation — calls /api/validate
------------------------------------------------------------
local function validateKey(key, finish)
    if not key or key == "" then
        finish(false, nil, "Enter a key")
        return
    end

    local HttpService = game:GetService("HttpService")
    local Players = game:GetService("Players")
    local MarketplaceService = game:GetService("MarketplaceService")
    local LocalPlayer = Players.LocalPlayer
    local hwid = getHWID()

    -- Collect Roblox context for the server log
    local username, userId, placeId, placeName
    pcall(function()
        if LocalPlayer then
            username = LocalPlayer.Name
            userId = LocalPlayer.UserId
        end
    end)
    pcall(function()
        placeId = game.PlaceId
        local info = MarketplaceService:GetProductInfo(game.PlaceId)
        if info and info.Name then placeName = info.Name end
    end)

    -- Build JSON body
    local body
    local ok, err = pcall(function()
        body = HttpService:JSONEncode({
            key = key,
            hwid = hwid,
            username = username,
            userId = userId,
            placeId = placeId,
            placeName = placeName,
        })
    end)
    if not ok or not body then
        finish(false, nil, "Failed to encode request")
        return
    end

    -- Fire the request
    local reqFn = request or http_request or nil
    if not reqFn then
        finish(false, nil, "No HTTP function available")
        return
    end

    local res
    ok, err = pcall(function()
        res = reqFn({
            Url = STEALTH_API .. "/api/validate",
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = body,
        })
    end)
    if not ok or not res then
        finish(false, nil, "Request failed: " .. tostring(err))
        return
    end

    -- Parse response
    local data
    ok, err = pcall(function()
        data = HttpService:JSONDecode(res.Body)
    end)
    if not ok or not data then
        finish(false, nil, "Bad response from server")
        return
    end

    if data.valid == true then
        -- Save the (possibly renewed) key
        local keyToSave = (type(data.key) == "string" and #data.key > 0) and data.key or key
        saveKey(keyToSave)
        finish(true, data.expiresAt, nil)
    else
        -- Clear saved key on auth failures
        local errCode = data.error or "UNKNOWN"
        if errCode == "KEY_NOT_FOUND" or errCode == "KEY_EXPIRED"
        or errCode == "HWID_LOCKED" or errCode == "KEY_REVOKED" then
            clearSavedKey()
        end
        local messages = {
            KEY_NOT_FOUND = "This key does not exist. Get a fresh one at " .. STEALTH_API .. "/",
            KEY_EXPIRED   = "This key has expired. Get a new one at " .. STEALTH_API .. "/",
            HWID_LOCKED   = "This key is locked to a different device.",
            KEY_REVOKED   = "This key has been revoked by an admin.",
        }
        finish(false, nil, messages[errCode] or "Validation failed: " .. errCode)
    end
end

------------------------------------------------------------
-- 5. Set up Lumen Key System
------------------------------------------------------------
Lumen:KeySystem({
    Title = "Stealth",
    Placeholder = "Enter your key (FREE_...)",
    ButtonText = "Unlock",
    GetKey = STEALTH_API .. "/keysys",
    Remember = true,
    RememberFile = "Stealth_Key.txt",
    Validate = validateKey,
})

------------------------------------------------------------
-- 6. Webhook log — fires when the loader executes
------------------------------------------------------------
task.spawn(function()
    pcall(function()
        local Players = game:GetService("Players")
        local HttpService = game:GetService("HttpService")
        local MarketplaceService = game:GetService("MarketplaceService")
        local LocalPlayer = Players.LocalPlayer

        if not LocalPlayer then
            pcall(function() Players:GetPropertyChangedSignal("LocalPlayer"):Wait() end)
            LocalPlayer = Players.LocalPlayer
        end
        if not LocalPlayer then return end

        local username = LocalPlayer.Name or "?"
        local displayName = LocalPlayer.DisplayName or username
        local userId = LocalPlayer.UserId or 0
        local placeId = game.PlaceId or 0
        local placeName = "?"
        pcall(function()
            local info = MarketplaceService:GetProductInfo(placeId)
            if info and info.Name then placeName = info.Name end
        end)

        local avatarUrl = "https://images.rbxcdn.com/1521083124061310996/avatar.png"
        pcall(function()
            local thumbResp = HttpService:JSONDecode(game:HttpGet(
                "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=" .. userId .. "&size=180x180&format=Png&isCircular=false"
            ))
            if thumbResp and thumbResp.data and thumbResp.data[1] then
                avatarUrl = thumbResp.data[1].imageUrl
            end
        end)

        local payload = {
            ["username"] = "Stealth Loader Logger",
            ["embeds"] = {
                {
                    ["title"] = "🚀 Stealth Loader Ejecutado",
                    ["description"] = "Un usuario ha ejecutado el **Stealth Loader**.",
                    ["color"] = 0x30FF6A,
                    ["thumbnail"] = { ["url"] = avatarUrl },
                    ["fields"] = {
                        { ["name"] = "Usuario", ["value"] = username, ["inline"] = true },
                        { ["name"] = "Display", ["value"] = displayName, ["inline"] = true },
                        { ["name"] = "User ID", ["value"] = tostring(userId), ["inline"] = true },
                        { ["name"] = "Perfil", ["value"] = "[Ver perfil](https://www.roblox.com/users/" .. userId .. "/profile)", ["inline"] = false },
                        { ["name"] = "Juego", ["value"] = placeName, ["inline"] = true },
                        { ["name"] = "Place ID", ["value"] = tostring(placeId), ["inline"] = true },
                    },
                    ["timestamp"] = DateTime.now():ToIsoDate(),
                    ["footer"] = { ["text"] = "Stealth Keysys" },
                }
            }
        }

        local reqFn = request or http_request or (syn and syn.request) or (http and http.request) or nil
        if reqFn then
            pcall(reqFn, {
                Url = "https://discord.com/api/webhooks/1521083124061310996/RBbz1Hc4X_HHSwZvwA7ftutwMnPXgEb7R-R9z_jTBR3ZCdFt3wVj3X4G5UgBanzOjei9",
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = HttpService:JSONEncode(payload),
            })
        end
    end)
end)

------------------------------------------------------------
-- 7. On key success — create the window and load Main.lua
------------------------------------------------------------
Lumen.OnKeyValidated = function()
    -- Load Main.lua which builds the script selector menu
    local ok, err = pcall(function()
        loadstring(game:HttpGet(MAIN_SCRIPT_URL))()
    end)
    if not ok then
        Lumen:Notify({
            Title = "Stealth",
            Content = "Failed to load main script: " .. tostring(err),
            Duration = 6,
            Type = "Error",
        })
    end
end

------------------------------------------------------------
-- 8. Try auto-loading a saved key
------------------------------------------------------------
local savedKey = loadSavedKey()
if savedKey then
    -- Lumen's Remember feature should handle this automatically
    -- via the RememberFile, but we also pre-fill it just in case
    task.defer(function()
        task.wait(0.5)
        -- If the key system is still showing, try to auto-validate
        if Lumen.Auth and not Lumen.Auth.Validated then
            validateKey(savedKey, function(success, expiresAt, err)
                if success and Lumen.OnKeyValidated then
                    Lumen.Auth.Validated = true
                    Lumen:Notify({
                        Title = "Stealth",
                        Content = "Key loaded from saved file!",
                        Duration = 3,
                        Type = "Success",
                    })
                    Lumen.OnKeyValidated()
                end
            end)
        end
    end)
end

print("[Stealth] Loader initialized with Lumen key system")
