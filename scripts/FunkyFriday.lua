-- [[ Stealth | Funky Friday — WindUI edition ]]
--
-- Converted from the original Fluent UI version of "Uni Hub | Funky Friday".
-- Auto Player logic (note hitting via VirtualInputManager) is preserved
-- verbatim — only the UI layer was swapped to WindUI to match the rest
-- of the Stealth hub.
--
-- End-user entrypoint:
--   Loaded on demand by Stealth Main.lua when the user clicks
--   "Load: Funky Friday" in the launcher.
--
-- Original credit:
--   -- Funky Friday
--   -- 1xyzz

------------------------------------------------------------
-- 0. Identity elevation (WindUI requires identity 8 to create
--    Font objects and access certain Instance APIs. Without
--    this, WindUI's Notify() and font loading crash with
--    "lacking capability Plugin".)
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

-- Approach 1: unfreeze `task` table and patch directly.
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

-- Approach 2: hookfunction fallback (executor-supported).
if not _taskPatched and hookfunction then
    pcall(function()
        local _origSpawn = task.spawn
        local _origDefer  = task.defer
        local _origDelay  = task.delay

        hookfunction(_origSpawn, newcclosure(function(fn, ...)
            local args = { ... }
            return _origSpawn(function()
                _elevateIdentity()
                if type(fn) == "function" then
                    return fn(table.unpack or unpack, args)
                end
            end)
        end))

        hookfunction(_origDefer, newcclosure(function(fn, ...)
            local args = { ... }
            return _origDefer(function()
                _elevateIdentity()
                if type(fn) == "function" then
                    return fn(table.unpack or unpack, args)
                end
            end)
        end))

        hookfunction(_origDelay, newcclosure(function(time, fn, ...)
            local args = { ... }
            return _origDelay(time, function()
                _elevateIdentity()
                if type(fn) == "function" then
                    return fn(table.unpack or unpack, args)
                end
            end)
        end))

        _taskPatched = true
    end)
end

------------------------------------------------------------
-- 1. Load WindUI
------------------------------------------------------------
local WindUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"
))()

-- Re-assert after loadstring (it may reset identity).
_elevateIdentity()

------------------------------------------------------------
-- 2. Game info / player refs
------------------------------------------------------------
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local gamename = "Funky Friday"
pcall(function()
    local info = MarketplaceService:GetProductInfo(game.PlaceId)
    if info and info.Name then gamename = info.Name end
end)

local player = Players.LocalPlayer

------------------------------------------------------------
-- 3. Auto Player state
------------------------------------------------------------
-- _G.auto    -> true while Auto Player is active
-- _G.Delay   -> user-controlled note delay (default 0.03)
-- _G.Mode    -> "Static" | "Random"
_G.auto = false
_G.Delay = 0.03
_G.Mode = "Static"

local Side = nil

-- keymap is populated by the keymap polling loop below.
local key1, key2, key3, key4, key5, key6, key7, key8, key9
local keymap = { key1, key2, key3, key4, key5, key6, key7, key8, key9 }

------------------------------------------------------------
-- 4. Window
------------------------------------------------------------
local Window = WindUI:CreateWindow({
    Title = "Stealth Funky Friday",
    Folder = "Stealth",
    Icon = "solar:music-note-bold-duotone",
    NewElements = true,
    HideSearchBar = false,
    OpenButton = {
        Title = "Open Stealth Funky Friday",
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
    Topbar = { Height = 44, ButtonsType = "Mac" },
})

------------------------------------------------------------
-- 5. Tabs
------------------------------------------------------------
local MainSection = Window:Section({ Title = "Main" })
local MainTab = MainSection:Tab({
    Title = "Main",
    Icon = "solar:play-bold",
    IconShape = "Square",
    Border = true,
})

local HomeSection = Window:Section({ Title = "Home" })
local HomeTab = HomeSection:Tab({
    Title = "Home",
    Icon = "solar:home-2-bold",
    IconShape = "Square",
    Border = true,
})

------------------------------------------------------------
-- 6. Main tab — Auto Player + Adjustments
------------------------------------------------------------
MainTab:Section({ Title = gamename, TextTransparency = 0.35 })
MainTab:Space({ Columns = 1 })

-- Auto Player toggle.
local AutoToggle = MainTab:Toggle({
    Title = "Auto Player",
    Desc = "Automatically Hit Notes (toggle while in song)",
    Value = false,
    Callback = function(value)
        if value then
            _G.auto = true
            _G.Delay = _G.Delay or 0

            local function setupColumns(side)
                local columns = {}
                pcall(function()
                    local ap = Players.LocalPlayer.PlayerGui.Window.Game.Fields[side].Inner
                    for i = 1, 9 do
                        pcall(function()
                            local lane = ap["Lane"..i]
                            if lane then
                                columns[i] = lane.Notes
                            end
                        end)
                    end
                end)
                return columns
            end

            local function autoplay()
                while _G.auto do
                    pcall(function()
                        local columns = setupColumns(Side)
                        local trackedChildren = {}
                        local activationThreshold = 0.4 + 1e-9 + _G.Delay

                        for columnNum, column in pairs(columns) do
                            pcall(function()
                                trackedChildren[columnNum] = {}
                                for _, child in ipairs(column:GetChildren()) do
                                    pcall(function()
                                        if child:IsA("GuiObject") and child.Position.Y.Scale > activationThreshold then
                                            trackedChildren[columnNum][child] = true
                                            VirtualInputManager:SendKeyEvent(true, keymap[columnNum], false, game)
                                        end
                                    end)
                                end
                            end)
                        end

                        while _G.auto do
                            pcall(function()
                                for columnNum, column in pairs(columns) do
                                    pcall(function()
                                        for _, child in ipairs(column:GetChildren()) do
                                            pcall(function()
                                                if child:IsA("GuiObject") and not trackedChildren[columnNum][child] and child.Position.Y.Scale > activationThreshold then
                                                    trackedChildren[columnNum][child] = true
                                                    VirtualInputManager:SendKeyEvent(true, keymap[columnNum], false, game)

                                                    if #child:GetChildren() == 2 then
                                                        coroutine.wrap(function()
                                                            pcall(function()
                                                                while child.Parent and child.Position.Y.Scale > activationThreshold and _G.auto do
                                                                    RunService.Heartbeat:Wait()
                                                                end
                                                                VirtualInputManager:SendKeyEvent(false, keymap[columnNum], false, game)
                                                                trackedChildren[columnNum][child] = nil
                                                            end)
                                                        end)()
                                                    end
                                                end
                                            end)
                                        end

                                        for child in pairs(trackedChildren[columnNum]) do
                                            pcall(function()
                                                if not child:IsDescendantOf(column) or
                                                   (child:IsA("GuiObject") and child.Position.Y.Scale <= activationThreshold) then
                                                    if trackedChildren[columnNum][child] then
                                                        VirtualInputManager:SendKeyEvent(false, keymap[columnNum], false, game)
                                                    end
                                                    trackedChildren[columnNum][child] = nil
                                                end
                                            end)
                                        end
                                    end)
                                end
                                RunService.Heartbeat:Wait()
                            end)
                        end
                    end)
                end
            end

            coroutine.wrap(autoplay)()
        else
            _G.auto = false
        end
    end,
})

MainTab:Space({ Columns = 1 })

-- Auto Player keybind (default Insert).
-- WindUI Keybind fires its callback on key change. To preserve the
-- "press Insert to toggle Auto Player" behavior from the original
-- Fluent script, we listen to UserInputService directly with the
-- currently bound key.
local currentKeybind = Enum.KeyCode.Insert

MainTab:Keybind({
    Title = "Auto Player Keybind",
    Desc = "Press this key to toggle Auto Player.",
    Value = "Insert",
    Callback = function(newKey)
        -- newKey may arrive as string ("Insert") or Enum.KeyCode.
        if typeof(newKey) == "EnumItem" then
            currentKeybind = newKey
        elseif type(newKey) == "string" then
            currentKeybind = Enum.KeyCode[newKey] or currentKeybind
        end
    end,
})

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == currentKeybind then
        -- Toggle the Auto Player.
        if AutoToggle and AutoToggle.Value ~= nil then
            -- WindUI Toggle element exposes its state via :Set(); we mirror
            -- the original Fluent logic by flipping the stored state.
            local newState = not _G.auto
            -- Use the toggle's own callback path so the autoplay loop
            -- starts/stops correctly.
            if AutoToggle.Set then
                AutoToggle:Set(newState)
            else
                -- Fallback: invoke the callback directly via the toggle.
                _G.auto = newState
                if AutoToggle.Value ~= nil then AutoToggle.Value = newState end
            end
        end
    end
end)

MainTab:Space({ Columns = 1 })

MainTab:Paragraph({
    Title = "Use DownScroll",
    Content = "If your notes scroll downward instead of upward, set the slider to a positive value to compensate. The script auto-detects downscroll/upscroll direction.",
})

MainTab:Space({ Columns = 1 })

MainTab:Section({ Title = "Adjustments" })

------------------------------------------------------------
-- 6b. Delay Mode dropdown (Static / Random)
------------------------------------------------------------
local DelayModeDropdown = MainTab:Dropdown({
    Title = "Delay Mode",
    Desc = "Static = always use the slider value. Random = use a random value up to the slider value each frame.",
    Values = { "Static", "Random" },
    Value = 1,
    Multi = false,
    Callback = function(selected)
        _G.Mode = selected or "Static"
    end,
})

_G.Mode = "Static"

MainTab:Space({ Columns = 1 })

------------------------------------------------------------
-- 6c. Note ms Delay slider (default 0.03, range -0.4 to 0.4)
------------------------------------------------------------
local DelaySlider = MainTab:Slider({
    Title = "Note ms Delay",
    Desc = "More = Later. Default 0.03.",
    Step = 0.01,
    Value = {
        Min = -0.4,
        Max = 0.4,
        Default = 0.03,
    },
    Callback = function(value)
        pcall(function()
            if _G.Mode == "Static" then
                _G.Delay = value
                local p = game.Players.LocalPlayer
                -- Detect downscroll/upscroll direction from the game's
                -- settings UI (same logic as the original Fluent script).
                local downOn, ok2 = pcall(function()
                    return p.PlayerGui.GameGui.Windows.Configuration.Frame.Body.Content.Settings.Entries.ScrollingFrame.DownScroll.Toggle.Inner.BackgroundColor3
                end)
                if ok2 and downOn == Color3.fromRGB(85, 255, 85) then
                    _G.Delay = _G.Delay - _G.Delay - _G.Delay
                else
                    _G.Delay = _G.Delay - _G.Delay - _G.Delay
                end
            else
                task.spawn(function()
                    while _G.Mode == "Random" do
                        _G.Delay = math.floor(math.random() * value * 1000) / 1000
                        task.wait()
                    end
                end)
            end
        end)
    end,
})

------------------------------------------------------------
-- 7. Home tab — Timer + Discord + Infinite Yield
------------------------------------------------------------
HomeTab:Section({ Title = "Session" })

local TimerParagraph = HomeTab:Paragraph({
    Title = "Time: 00:00:00",
    Content = "Time since Stealth Funky Friday loaded.",
})

local st = os.time()
task.spawn(function()
    while true do
        local et = os.difftime(os.time(), st)
        local h = math.floor(et / 3600)
        local m = math.floor((et % 3600) / 60)
        local s = et % 60
        local ft = string.format("Time: %02d:%02d:%02d", h, m, s)
        if TimerParagraph and TimerParagraph.Set then
            pcall(function()
                TimerParagraph:Set({ Title = ft, Content = "Time since Stealth Funky Friday loaded." })
            end)
        end
        task.wait(1)
    end
end)

HomeTab:Space({ Columns = 1 })

HomeTab:Section({ Title = "Links" })

HomeTab:Button({
    Title = "Discord Server",
    Desc = "Copies the Discord invite link to your clipboard.",
    Icon = "solar:chat-round-dots-bold",
    Color = Color3.fromHex("#5865F2"),
    Justify = "Left",
    IconAlign = "Left",
    Callback = function()
        pcall(function() setclipboard("https://discord.gg/hqE5drDHF7") end)
        WindUI:Notify({
            Title = "Stealth Funky Friday",
            Content = "Discord invite copied successfully!",
            Duration = 2,
            Icon = "solar:chat-round-dots-bold",
        })
    end,
})

HomeTab:Space({ Columns = 1 })

HomeTab:Button({
    Title = "Run Infinite Yield",
    Desc = "Loads the Infinite Yield admin script.",
    Icon = "solar:command-bold",
    Color = Color3.fromHex("#30FF6A"),
    Justify = "Left",
    IconAlign = "Left",
    Callback = function()
        pcall(function()
            loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
        end)
        WindUI:Notify({
            Title = "Stealth Funky Friday",
            Content = "Infinite Yield loaded.",
            Duration = 3,
            Icon = "solar:check-circle-bold",
        })
    end,
})

------------------------------------------------------------
-- 8. Pause Auto Player when Roblox menu opens (original behavior)
------------------------------------------------------------
GuiService.MenuOpened:Connect(function()
    if _G.auto then
        _G.Toggled = true
        _G.auto = false
        if AutoToggle and AutoToggle.Set then
            pcall(function() AutoToggle:Set(false) end)
        end
    end
end)

GuiService.MenuClosed:Connect(function()
    if not _G.auto and _G.Toggled then
        _G.Toggled = false
        if AutoToggle and AutoToggle.Set then
            pcall(function() AutoToggle:Set(true) end)
        end
    end
end)

------------------------------------------------------------
-- 9. "Ui" Tool in the backpack — click to toggle the WindUI window
------------------------------------------------------------
local backpack = player:WaitForChild("Backpack")
if backpack:FindFirstChild("Ui") then
    backpack:FindFirstChild("Ui"):Destroy()
end

local tool = Instance.new("Tool")
tool.Name = "Ui"
tool.RequiresHandle = false
tool.TextureId = "rbxassetid://135519282079256"
tool.Parent = backpack

local open = true
tool.Activated:Connect(function()
    -- WindUI exposes :Minimize()/toggle via the OpenButton. Calling
    -- :Destroy() then reloading is overkill, so we just toggle visibility
    -- using the same pattern as the rest of the Stealth scripts.
    pcall(function()
        -- WindUI doesn't expose a public :SetVisible, so we trigger the
        -- OpenButton's behavior. Most WindUI builds expose :Minimize().
        if Window.Minimize then
            Window:Minimize()
        elseif Window.SetVisible then
            open = not open
            Window:SetVisible(open)
        end
    end)
end)

------------------------------------------------------------
-- 10. Anti-AFK
------------------------------------------------------------
local VirtualUser = game:GetService('VirtualUser')
player.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

------------------------------------------------------------
-- 11. Side detection — figure out whether the local player is on
--     the "Left" or "Right" stage so the autoplay loop reads the
--     correct lane container.
------------------------------------------------------------
local function CheckSide()
    pcall(function()
        local p = game.Players.LocalPlayer
        local character = p.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end

        local minDistTo11 = math.huge
        local minDistTo21 = math.huge

        for _, stage in pairs(workspace.Map.Stages:GetChildren()) do
            if stage:FindFirstChild("Teams") then
                local pads = stage.Teams
                local part11 = pads:FindFirstChild("Left")
                local part21 = pads:FindFirstChild("Right")

                if part11 and (rootPart.Position - part11.Position).magnitude <= 5 then
                    local distTo11 = (rootPart.Position - part11.Position).magnitude
                    if distTo11 < minDistTo11 then
                        minDistTo11 = distTo11
                    end
                end

                if part21 and (rootPart.Position - part21.Position).magnitude <= 5 then
                    local distTo21 = (rootPart.Position - part21.Position).magnitude
                    if distTo21 < minDistTo21 then
                        minDistTo21 = distTo21
                    end
                end
            end
        end

        if minDistTo11 < minDistTo21 then
            Side = "Left"
        elseif minDistTo21 < minDistTo11 then
            Side = "Right"
        end
    end)
end

------------------------------------------------------------
-- 12. Keymap polling loop — read Lane1..Lane9 keybind labels from
--     the game UI so VirtualInputManager:SendKeyEvent fires the
--     correct key for each lane.
------------------------------------------------------------
task.spawn(function()
    while true do
        local p = game:GetService("Players").LocalPlayer
        if p.PlayerGui.GameGui.Windows.SongSelector.Visible == true then
            CheckSide()
        end
        pcall(function()
            local km = p.PlayerGui.Window.Game.Fields[Side].Inner
            key1 = Enum.KeyCode[km["Lane1"].Labels.Label.Text.text]
            key2 = Enum.KeyCode[km["Lane2"].Labels.Label.Text.text]
            key3 = Enum.KeyCode[km["Lane3"].Labels.Label.Text.text]
            key4 = Enum.KeyCode[km["Lane4"].Labels.Label.Text.text]
            key5 = Enum.KeyCode[km["Lane5"].Labels.Label.Text.text]
            key6 = Enum.KeyCode[km["Lane6"].Labels.Label.Text.text]
            key7 = Enum.KeyCode[km["Lane7"].Labels.Label.Text.text]
            key8 = Enum.KeyCode[km["Lane8"].Labels.Label.Text.text]
            key9 = Enum.KeyCode[km["Lane9"].Labels.Label.Text.text]
            -- refresh keymap table reference
            keymap = { key1, key2, key3, key4, key5, key6, key7, key8, key9 }
        end)
        task.wait()
    end
end)

------------------------------------------------------------
-- 13. Welcome notification
------------------------------------------------------------
WindUI:Notify({
    Title = "Stealth Funky Friday",
    Content = "Loaded. Toggle Auto Player while in a song.",
    Duration = 5,
    Icon = "solar:music-note-bold",
})
