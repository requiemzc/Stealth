-- [[ Stealth | Example using Patriot Key System UI Library ]]
-- Repository: https://github.com/SyndromeXph/Patriot-Key-System-Ui-Library
--
-- This example shows you how to:
--   1. Load the Patriot library
--   2. Brand the key UI as "Stealth"
--   3. Validate a key (simple in-script check — replace with your own/API/Luarmor/etc.)
--   4. Run your main script when the key is valid
--   5. Show notifications, customize the theme, configure storage, etc.
--
-- USAGE:
--   - Set `VALID_KEY` below to whatever you want users to type.
--   - Replace the body of `OnSuccess` with your real script (or a loadstring call).
--   - (Optional) Replace the simple OnVerify with Luarmor / Panda Auth / Junkie / HTTP API.

------------------------------------------------------------
-- 1. Load Patriot
------------------------------------------------------------
local Patriot = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/SyndromeXph/Patriot-Key-System-Ui-Library/refs/heads/main/PatriotUi.luau"
))()

------------------------------------------------------------
-- 2. Key validation
------------------------------------------------------------
-- Replace this with your own key (or wire up Luarmor / Panda Auth / Junkie / HTTP API).
local VALID_KEY = "STEALTH-1234-ABCD"

-- Simple validation: return true if the key matches.
-- For a detailed error response, return a table instead:
--   return { valid = false, error = "KEY_EXPIRED", message = "Your key has expired" }
Patriot.Callbacks.OnVerify = function(key)
    return key == VALID_KEY
end

------------------------------------------------------------
-- 3. Branding — this is where the UI gets the name "Stealth"
------------------------------------------------------------
Patriot.Appearance = {
    Title    = "Stealth",
    Subtitle = "Verify your key to continue",
    -- Logo decal ID: 94734287536234
    Icon     = "rbxassetid://94734287536234",
    IconSize = UDim2.new(0, 30, 0, 30),
}

------------------------------------------------------------
-- 4. Links
------------------------------------------------------------
Patriot.Links = {
    GetKey  = "https://your-link-to-get-key.example",  -- Replace with your key-get link
    Discord = "https://discord.gg/yourserver",         -- Replace with your Discord invite
}

------------------------------------------------------------
-- 5. Storage — remember the user's key between sessions
------------------------------------------------------------
Patriot.Storage = {
    FileName = "Stealth_Key",
    Remember = true,   -- Save the key after a successful verify
    AutoLoad = false,  -- If true, tries to log in with the saved key automatically
}

------------------------------------------------------------
-- 6. Options
------------------------------------------------------------
Patriot.Options = {
    Keyless  = false,  -- true  -> skip the key system entirely (good for free scripts)
    Blur     = true,   -- Background blur while the key UI is open
    Draggable= true,   -- Let the user drag the window
}

------------------------------------------------------------
-- 7. Theme — dark + crimson "Stealth" look (tweak freely)
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
-- 8. Changelog (only shows if entries exist)
------------------------------------------------------------
Patriot.Changelog = {
    {Version = "v1.0.0", Date = "Sep 7, 2026", Changes = {"Initial Stealth release", "Patriot key system integration"}},
}

------------------------------------------------------------
-- 9. Optional Shop section (disabled by default)
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
-- 10. Callbacks — what happens after the key UI
------------------------------------------------------------
-- Called when the user submits a key and OnVerify returned true.
Patriot.Callbacks.OnSuccess = function()
    print("[Stealth] Verification successful, loading main script...")
    Patriot:Notify("Stealth", "Key validated! Loading...", 2, "success")

    -- Replace this block with your real script, e.g.:
    --   loadstring(game:HttpGet("https://your-host/stealth_main.lua"))()

    -- Demo: a tiny "main" so you can see something happen.
    task.wait(1)
    Patriot:Notify("Stealth", "Welcome! Main script loaded.", 4, "shield")
end

-- Called when the user submits an invalid key.
Patriot.Callbacks.OnFail = function(errorMsg)
    print("[Stealth] Verification failed:", errorMsg)
end

-- Called when the user closes the window without verifying.
Patriot.Callbacks.OnClose = function()
    print("[Stealth] User closed the verification window")
end

------------------------------------------------------------
-- 11. (Optional) Integration examples — uncomment one to use
------------------------------------------------------------
-- Luarmor:
-- Patriot:LaunchLuarmor({ scriptId = "YOUR_LUARMOR_SCRIPT_ID" })

-- Panda Auth (Wilkins):
-- Patriot:LaunchWilkins({
--     serviceId         = "your-service-id",
--     debug             = false,
--     kickOnDetect      = false,
--     openDashboard     = true,
--     validationTimeout = 600,
--     onTamper          = function(flags) warn("Tamper detected:", table.concat(flags, ",")) end,
--     onSessionEnd      = function(reason, msg) warn("Session ended:", reason, msg) end,
-- })

-- Junkie SDK:
-- Patriot:LaunchJunkie({
--     Service   = "YOUR_SERVICE_NAME",
--     Identifier= "YOUR_IDENTIFIER",
--     Provider  = "YOUR_PROVIDER_NAME",
-- })

-- HTTP API validation (replaces the simple OnVerify above):
-- local HttpService = game:GetService("HttpService")
-- Patriot.Callbacks.OnVerify = function(key)
--     local ok, response = pcall(function()
--         return game:HttpGet("https://api.yoursite.com/validate?key=" .. key)
--     end)
--     if not ok then return false end
--     local data = HttpService:JSONDecode(response)
--     return {
--         valid   = data.valid,
--         error   = data.error or "UNKNOWN",
--         message = data.message or "Invalid key",
--     }
-- end

------------------------------------------------------------
-- 12. Launch the key UI
------------------------------------------------------------
Patriot:Launch()

-- Quick reference -------------------------------------------------------------
-- Patriot:Notify(title, message, duration, iconType)
--   iconType: "info" | "success" | "error" | "warning" | "shield" | "key" | "copy" | "discord" | "close"
--
-- local savedKey = Patriot:GetSavedKey()   -- returns saved key or nil
-- Patriot:ClearSavedKey()                  -- deletes the saved key
