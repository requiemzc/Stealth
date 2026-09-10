-- [[ Stealth | Ready-to-execute Roblox key system ]]
--
-- Validates the user's key against https://stealthub-sable.vercel.app/api/validate
-- Keys are issued at https://stealthub-sable.vercel.app/ and rotate every 15 minutes,
-- each locked to a single HWID on first validation.
--
-- After successful validation, Stealth loads Main.lua (from this same repo)
-- which shows a Rayfield menu letting the user pick which script to run.
--
-- HOW TO USE (end user):
--   loadstring(game:HttpGet("https://raw.githubusercontent.com/requiemzc/Stealth/main/Stealth.lua"))()
--
-- HOW TO ADD YOUR OWN SCRIPTS (developer):
--   1. Drop your script file in the `scripts/` folder of this repo.
--   2. Add an entry to the SCRIPTS table in Main.lua (name + raw URL).
--   3. Commit + push. Done — users will see the new script in the menu.
--
-- File layout in the repo:
--   Stealth.lua              ← this file (key system, loaded by the user)
--   Main.lua                 ← launcher with script selector menu (loaded after key check)
--   scripts/                 ← your actual script files (loaded on demand by Main.lua)
--     DefeatAnimeRNG.lua
--     BloxFruits.lua
--     Universal.lua
--     ...

------------------------------------------------------------
-- 1. Configuration
------------------------------------------------------------
-- After key validation, Stealth loads Main.lua which shows a Rayfield menu
-- where the user can pick which script to run. Main.lua is hosted in the
-- same repo as this file.
local MAIN_SCRIPT_URL = "https://raw.githubusercontent.com/requiemzc/Stealth/main/Main.lua"

-- The Stealth key system website (issues + validates keys).
local STEALTH_API = "https://stealthub-sable.vercel.app"

------------------------------------------------------------
-- 2. Load Patriot
------------------------------------------------------------
local Patriot = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/SyndromeXph/Patriot-Key-System-Ui-Library/refs/heads/main/PatriotUi.luau"
))()

------------------------------------------------------------
-- 3. Get the HWID (hardware ID) for locking the key
------------------------------------------------------------
-- Each device must have its own unique key. We lock keys to the HWID so
-- a key issued on device A cannot be used on device B.
--
-- Different executors expose the HWID under different names. We try them
-- in order of preference and fall back to Roblox's built-in client ID.
local function getHWID()
    -- 1. gethwid() — most common in modern executors (Synapse, KRNL, Fluxus, etc.)
    local ok, id = pcall(function() return gethwid and gethwid() end)
    if ok and type(id) == "string" and #id > 0 then return id end

    -- 2. global `hwid` variable (some executors)
    if type(hwid) == "string" and #hwid > 0 then return hwid end

    -- 3. RbxAnalyticsService:GetClientId() — Roblox's built-in, always available,
    --    stable per device. This is the most reliable fallback.
    ok, id = pcall(function()
        return game:GetService("RbxAnalyticsService"):GetClientId()
    end)
    if ok and type(id) == "string" and #id > 0 then return id end

    -- 4. Last resort: user ID. NOT a true HWID — two devices on the same
    --    account would share a key. But better than crashing.
    return "uid_" .. tostring(game.Players.LocalPlayer.UserId)
end

------------------------------------------------------------
-- 4. Key validation — calls https://stealthub-sable.vercel.app/api/validate
------------------------------------------------------------
-- Returns true if the key is valid (and locks it to this HWID on first use),
-- false otherwise. Patriot also accepts a detailed table response.
Patriot.Callbacks.OnVerify = function(key)
    if not key or key == "" then return false end

    local HttpService = game:GetService("HttpService")
    local hwid = getHWID()

    -- Build the JSON body.
    local body
    local ok, err = pcall(function()
        body = HttpService:JSONEncode({ key = key, hwid = hwid })
    end)
    if not ok or not body then
        return { valid = false, error = "CLIENT_ERROR", message = "Failed to encode request: " .. tostring(err) }
    end

    -- Fire the request. `request` is the executor's HTTP function (Synapse/KRNL/Fluxus/etc.).
    -- Some executors call it `http_request`, so we fall back to that.
    local reqFn = request or http_request or nil
    if not reqFn then
        return { valid = false, error = "NO_HTTP", message = "Your executor does not expose an HTTP request function." }
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
        return { valid = false, error = "REQUEST_FAILED", message = tostring(err) }
    end

    -- Parse the JSON response.
    local data
    ok, err = pcall(function()
        data = HttpService:JSONDecode(res.Body)
    end)
    if not ok or not data then
        return { valid = false, error = "BAD_RESPONSE", message = "Could not parse server response: " .. tostring(res.Body) }
    end

    if data.valid == true then
        return true
    end

    -- Map server error codes to friendly messages.
    local messages = {
        KEY_NOT_FOUND = "This key does not exist. Get a fresh one at " .. STEALTH_API .. "/",
        KEY_EXPIRED   = "This key has expired (15-minute window). Get a new one at " .. STEALTH_API .. "/",
        HWID_LOCKED   = "This key is locked to a different device. Get your own at " .. STEALTH_API .. "/",
    }
    return {
        valid   = false,
        error   = data.error or "UNKNOWN",
        message = messages[data.error] or "Validation failed.",
    }
end

------------------------------------------------------------
-- 5. Branding — the key UI shows up as "Stealth"
------------------------------------------------------------
Patriot.Appearance = {
    Title    = "Stealth",
    Subtitle = "Verify your key to continue",
    Icon     = "rbxassetid://94734287536234",
    IconSize = UDim2.new(0, 30, 0, 30),
}

------------------------------------------------------------
-- 6. Links
------------------------------------------------------------
Patriot.Links = {
    GetKey  = "https://stealthub-sable.vercel.app/keysys",       -- "Get Key" button opens the key system
    Discord = "https://discord.gg/hqE5drDHF7",
}

------------------------------------------------------------
-- 7. Storage — remember the user's key between sessions
------------------------------------------------------------
Patriot.Storage = {
    FileName = "Stealth_Key",
    Remember = true,
    AutoLoad = false,
}

------------------------------------------------------------
-- 8. Options
------------------------------------------------------------
Patriot.Options = {
    Keyless  = false,
    Blur     = true,
    Draggable= true,
}

------------------------------------------------------------
-- 9. Theme — dark + crimson "Stealth" look
------------------------------------------------------------
Patriot.Theme = {
    Accent       = Color3.fromRGB(220, 20, 60),
    AccentHover  = Color3.fromRGB(255, 30, 80),
    Background   = Color3.fromRGB(0, 0, 0),
    Header       = Color3.fromRGB(10, 10, 10),
    Input        = Color3.fromRGB(20, 20, 20),
    Text         = Color3.fromRGB(255, 255, 255),
    TextDim      = Color3.fromRGB(150, 150, 150),
    Success      = Color3.fromRGB(50, 255, 50),
    Error        = Color3.fromRGB(255, 30, 80),
    Warning      = Color3.fromRGB(255, 255, 0),
    StatusIdle   = Color3.fromRGB(180, 40, 60),
    Discord      = Color3.fromRGB(220, 20, 60),
    DiscordHover = Color3.fromRGB(255, 30, 80),
    Divider      = Color3.fromRGB(30, 30, 30),
    Pending      = Color3.fromRGB(40, 40, 40),
}

------------------------------------------------------------
-- 10. Changelog
------------------------------------------------------------
Patriot.Changelog = {
    {Version = "v1.0.0", Date = "Sep 7, 2026", Changes = {
        "Initial Stealth release",
        "Key validation against linkunlocker",
        "15-minute key rotation with HWID locking",
    }},
}

------------------------------------------------------------
-- 11. Shop (disabled by default)
------------------------------------------------------------
Patriot.Shop = {
    Enabled    = false,
    Icon       = "",
    Title      = "Get Premium Access",
    Subtitle   = "Instant delivery - 24/7 support",
    ButtonText = "Buy",
    Link       = "",
}

------------------------------------------------------------
-- 12. Callbacks
------------------------------------------------------------
-- OnSuccess runs AFTER OnVerify returns true.
-- This is where you load your main script.
Patriot.Callbacks.OnSuccess = function()
    print("[Stealth] Key validated! Loading main script...")
    Patriot:Notify("Stealth", "Key validated! Loading...", 2, "success")

    -- Load the main script. Wrap in pcall so a network error doesn't kill the executor.
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
-- 13. Launch the key UI
------------------------------------------------------------
Patriot:Launch()

--[[
------------------------------------------------------------
REPOSITORY LAYOUT
------------------------------------------------------------

  Stealth.lua              ← this file (key system). User runs this.
       │
       │  after key validation
       ▼
  Main.lua                 ← launcher with Rayfield script selector menu
       │
       │  user clicks "Load: <script name>"
       ▼
  scripts/                 ← your actual script files
    DefeatAnimeRNG.lua
    BloxFruits.lua
    Universal.lua
    ...

ADDING A NEW SCRIPT:
  1. Drop your script file in the `scripts/` folder.
  2. Add an entry to the SCRIPTS table at the top of Main.lua:
       { name = "My New Script", url = "https://raw.githubusercontent.com/requiemzc/Stealth/main/scripts/MyNewScript.lua" }
  3. Commit + push.
  4. Users will see the new entry in the menu on next load.

IMPORTANT:
  - Always use raw.githubusercontent.com URLs (not github.com/.../blob/...).
  - Keep Stealth.lua and Main.lua separate — don't merge them.
  - Stealth.lua changes rarely (key system, branding).
  - Main.lua changes when you add/remove scripts.
  - The scripts/ folder changes when you update individual hubs.
]]
