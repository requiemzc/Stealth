-- [[ Stealth | Key System (Airflow UI) ]]
--
-- Validates the user's key against https://sstealth.vercel.app/api/validate
-- Keys are issued at https://sstealth.vercel.app/ and rotate every 15 minutes,
-- each locked to a single HWID on first validation. Valid keys last 2 hours.
--
-- HOW TO USE:
--   loadstring(game:HttpGet("https://raw.githubusercontent.com/requiemzc/Stealth/main/Stealth.lua"))()

local STEALTH_API = "https://sstealth.vercel.app"
local MAIN_SCRIPT_URL = "https://raw.githubusercontent.com/requiemzc/Stealth/main/Main.lua"

------------------------------------------------------------
-- 1. Load Airflow UI
------------------------------------------------------------
local Airflow = loadstring(game:HttpGet("https://raw.githubusercontent.com/requiemzc/Stealth/main/Airflow.lua"))()
getgenv().StealthAirflow = Airflow

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
    pcall(function()
        if isfile and isfile("Stealth_Key.txt") then delfile("Stealth_Key.txt") end
    end)
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
local keyValidated = false
local keyWindow = nil

local function validateKey(key, finish)
    if not key or key == "" then
        if finish then finish(false, "Enter a key") end
        return
    end

    local HttpService = game:GetService("HttpService")
    local Players = game:GetService("Players")
    local MarketplaceService = game:GetService("MarketplaceService")
    local LocalPlayer = Players.LocalPlayer
    local hwid = getHWID()

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
        if finish then finish(false, "Failed to encode request") end
        return
    end

    local reqFn = request or http_request or nil
    if not reqFn then
        if finish then finish(false, "No HTTP function available") end
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
        if finish then finish(false, "Request failed: " .. tostring(err)) end
        return
    end

    local data
    ok, err = pcall(function()
        data = HttpService:JSONDecode(res.Body)
    end)
    if not ok or not data then
        if finish then finish(false, "Bad response from server") end
        return
    end

    if data.valid == true then
        local keyToSave = (type(data.key) == "string" and #data.key > 0) and data.key or key
        saveKey(keyToSave)
        if finish then finish(true, nil) end
    else
        local errCode = data.error or "UNKNOWN"
        if errCode == "KEY_NOT_FOUND" or errCode == "KEY_EXPIRED"
        or errCode == "HWID_LOCKED" or errCode == "KEY_REVOKED" then
            clearSavedKey()
        end
        local messages = {
            KEY_NOT_FOUND = "Key does not exist. Get one at " .. STEALTH_API .. "/",
            KEY_EXPIRED   = "Key expired. Get a new one at " .. STEALTH_API .. "/",
            HWID_LOCKED   = "Key locked to another device.",
            KEY_REVOKED   = "Key revoked by admin.",
        }
        if finish then finish(false, messages[errCode] or "Validation failed: " .. errCode) end
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
            ["embeds"] = {{
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
            }}
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
-- 6. Create key window with Airflow UI
------------------------------------------------------------
local function showKeyPrompt()
    keyWindow = Airflow:CreateWindow({
        Name = "Stealth",
        LoadingSubtitle = "Key System",
        Icon = "shield-keyhole",
        ToggleUIKeybind = "RightShift",
        Size = UDim2.fromOffset(500, 340),
        MinSize = Vector2.new(360, 280),
        Loading = false,
        ConfigurationSaving = { Enabled = false },
    })

    local Tab = keyWindow:CreateTab({ Name = "Key", Icon = "key-round" })
    local Section = Tab:CreateSection("Enter your key")

    local keyInput = Tab:CreateInput({
        Name = "Key",
        PlaceholderText = "FREE_...",
        CurrentValue = "",
        Flag = "StealthKey",
        Callback = function(text) end,
    })

    local statusLabel = Tab:CreateLabel({ Text = "Enter your key and click Unlock", Color = Airflow.Theme.Muted })

    Tab:CreateButton({
        Name = "Unlock",
        Style = "Primary",
        Callback = function()
            local key = keyInput:Get()
            if not key or key == "" then
                statusLabel:Set("Please enter a key")
                return
            end
            statusLabel:Set("Validating...")
            task.spawn(function()
                validateKey(key, function(success, err)
                    if success then
                        keyValidated = true
                        statusLabel:Set("Key valid! Loading hub...")
                        pcall(function()
                            Airflow:Notify({ Title = "Stealth", Content = "Key validated!", Duration = 2, Type = "Success" })
                        end)
                        task.wait(1)
                        -- Destroy key window and load Main.lua
                        pcall(function() keyWindow:Destroy() end)
                        pcall(function()
                            loadstring(game:HttpGet(MAIN_SCRIPT_URL))()
                        end)
                    else
                        statusLabel:Set(err or "Validation failed")
                    end
                end)
            end)
        end,
    })

    Tab:CreateDivider()
    Tab:CreateParagraph({ Title = "Get a key", Content = "Go to " .. STEALTH_API .. "/keysys to get a free key." })
    Tab:CreateButton({
        Name = "Copy key link",
        Callback = function()
            pcall(function()
                if setclipboard then
                    setclipboard(STEALTH_API .. "/keysys")
                    Airflow:Notify({ Title = "Stealth", Content = "Link copied!", Duration = 2, Type = "Success" })
                end
            end)
        end,
    })
end

------------------------------------------------------------
-- 7. Try auto-loading saved key
------------------------------------------------------------
local savedKey = loadSavedKey()
if savedKey then
    task.spawn(function()
        task.wait(1)
        validateKey(savedKey, function(success, err)
            if success then
                keyValidated = true
                -- Load Main.lua directly without showing key prompt
                pcall(function()
                    loadstring(game:HttpGet(MAIN_SCRIPT_URL))()
                end)
            else
                -- Key invalid, show prompt
                showKeyPrompt()
            end
        end)
    end)
else
    showKeyPrompt()
end

print("[Stealth] Loader initialized with Airflow UI")
