-- [[ Stealth | Crystal ESP — Mine a Mountain ]]
--
-- Original: Open Source Full ESP (Mythic, Empyrean, Pulsar, Quasar)
-- Source: rscripts.net
-- Game: Mine a Mountain
-- Integrated into Stealth Hub.
-- Discord: discord.gg/hqE5drDHF7
--
-- Highlights high-value crystals (1B+ value) with tier-colored ESP.
-- Top 5 most valuable crystals get a special green highlight.

------------------------------------------------------------
-- Stealth integration
------------------------------------------------------------
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Webhook log: script loaded
task.spawn(function()
    pcall(function()
        local HttpService = game:GetService("HttpService")
        local MarketplaceService = game:GetService("MarketplaceService")

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
            ["username"] = "Stealth Script Logger",
            ["embeds"] = {
                {
                    ["title"] = "💎 Crystal ESP Cargado",
                    ["description"] = "Un usuario ha cargado **Crystal ESP** desde el Stealth Hub.",
                    ["color"] = 0x30FF6A,
                    ["thumbnail"] = { ["url"] = avatarUrl },
                    ["fields"] = {
                        { ["name"] = "Script", ["value"] = "Crystal ESP", ["inline"] = true },
                        { ["name"] = "Usuario", ["value"] = username, ["inline"] = true },
                        { ["name"] = "Display", ["value"] = displayName, ["inline"] = true },
                        { ["name"] = "User ID", ["value"] = tostring(userId), ["inline"] = true },
                        { ["name"] = "Juego", ["value"] = placeName, ["inline"] = true },
                        { ["name"] = "Place ID", ["value"] = tostring(placeId), ["inline"] = true },
                    },
                    ["timestamp"] = DateTime.now():ToIsoDate(),
                    ["footer"] = { ["text"] = "Stealth Hub" },
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

print("[Stealth] Crystal ESP loaded")

local Workspace = game:GetService("Workspace")

local droppedCrystalsFolder = Workspace:WaitForChild("DroppedCrystals")
local crystalsFolder = Workspace
        :WaitForChild("Things")
        :WaitForChild("Crystals")

local REFRESH_INTERVAL = 1
local MIN_VALUE = 1_000_000_000 -- minimal value to show esp!!!!
local TOP_COUNT = 5

local HIGHLIGHT_NAME = "__CrystalHighlight"
local GUI_NAME = "__CrystalInfoGui"
local LABEL_NAME = "InfoLabel"

local TOP_COLOR = Color3.fromRGB(70, 255, 90)

local rarityData = {
        T6 = {
                Name = "Mythic",
                Color = Color3.fromRGB(255, 70, 70),
        },

        T7 = {
                Name = "Empyrean",
                Color = Color3.fromRGB(255, 170, 0),
        },

        T8 = {
                Name = "Pulsar",
                Color = Color3.fromRGB(0, 200, 255),
        },

        T9 = {
                Name = "Quasar",
                Color = Color3.fromRGB(190, 80, 255),
        },
}

local trackedCrystals = {}
local registrationIndex = 0

local function isCrystalObject(object)
        return object:IsA("Model") or object:IsA("BasePart")
end

local function getTierFromName(name)
        local isCrystalName = string.find(name, "DroppedCrystal", 1, true)
                or string.match(name, "^Crystal")

        if not isCrystalName then
                return nil
        end

        local tierNumber = string.match(name, "T([6-9])")

        if tierNumber then
                return "T" .. tierNumber
        end

        return nil
end

local function getCrystalPart(crystal)
        if crystal:IsA("BasePart") then
                return crystal
        end

        if crystal:IsA("Model") then
                if crystal.PrimaryPart then
                        return crystal.PrimaryPart
                end

                return crystal:FindFirstChildWhichIsA("BasePart", true)
        end

        return nil
end

local function getAttribute(crystal, attributeName)
        local value = crystal:GetAttribute(attributeName)

        if value ~= nil then
                return value
        end

        local crystalPart = getCrystalPart(crystal)

        if crystalPart then
                return crystalPart:GetAttribute(attributeName)
        end

        return nil
end

local function toNumber(value)
        if typeof(value) == "number" then
                if value ~= value then
                        return nil
                end

                return value
        end

        if typeof(value) == "string" then
                local cleanedValue = value
                        :gsub(",", "")
                        :gsub("%$", "")
                        :gsub("%s+", "")

                return tonumber(cleanedValue)
        end

        return nil
end

local function formatCurrency(value)
        local number = toNumber(value)

        if not number then
                return "..."
        end

        local absoluteNumber = math.abs(number)
        local sign = number < 0 and "-" or ""

        if absoluteNumber >= 1_000_000_000_000 then
                return string.format("%.1fT$", number / 1_000_000_000_000)
        elseif absoluteNumber >= 1_000_000_000 then
                return string.format("%.1fB$", number / 1_000_000_000)
        elseif absoluteNumber >= 1_000_000 then
                return string.format("%.1fM$", number / 1_000_000)
        elseif absoluteNumber >= 1_000 then
                return string.format("%.1fK$", number / 1_000)
        end

        return string.format("%s%.0f$", sign, absoluteNumber)
end

local function formatWeight(value)
        local number = toNumber(value)

        if not number then
                return "..."
        end

        return string.format("%.1f kg", number)
end

local function safeDestroy(instance)
        if instance then
                pcall(function()
                        instance:Destroy()
                end)
        end
end

local function removeVisuals(crystal, state)
        if state.Highlight then
                safeDestroy(state.Highlight)
        end

        if state.Gui then
                safeDestroy(state.Gui)
        end

        state.Highlight = nil
        state.Gui = nil
        state.Label = nil
        state.LastText = nil
        state.LastColor = nil
        state.LastTopState = nil

        if crystal and crystal.Parent then
                safeDestroy(crystal:FindFirstChild(HIGHLIGHT_NAME))
                safeDestroy(crystal:FindFirstChild(GUI_NAME, true))
        end
end

local function ensureHighlight(crystal, state)
        local highlight = state.Highlight

        local isValid = highlight
                and highlight:IsA("Highlight")
                and highlight.Parent == crystal

        if not isValid then
                local existing = crystal:FindFirstChild(HIGHLIGHT_NAME)

                if existing and existing:IsA("Highlight") then
                        highlight = existing
                else
                        if existing then
                                safeDestroy(existing)
                        end

                        highlight = Instance.new("Highlight")
                        highlight.Name = HIGHLIGHT_NAME
                        highlight.Parent = crystal
                end

                state.Highlight = highlight
        end

        highlight.Adornee = crystal
        highlight.Enabled = true
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

        highlight.FillColor = Color3.fromRGB(0, 255, 255)
        highlight.FillTransparency = 0.55

        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.OutlineTransparency = 0
end

local function ensureInfoGui(crystal, state, text, textColor)
        local crystalPart = getCrystalPart(crystal)

        if not crystalPart then
                return false
        end

        local gui = state.Gui

        local guiIsValid = gui
                and gui:IsA("BillboardGui")
                and gui.Parent == crystalPart

        if not guiIsValid then
                local existing = crystal:FindFirstChild(GUI_NAME, true)

                if existing and existing:IsA("BillboardGui") then
                        gui = existing
                else
                        if existing then
                                safeDestroy(existing)
                        end

                        gui = Instance.new("BillboardGui")
                        gui.Name = GUI_NAME
                end

                gui.Parent = crystalPart
                state.Gui = gui
        end

        gui.Adornee = crystalPart
        gui.Enabled = true
        gui.AlwaysOnTop = true

        gui.MaxDistance = 0

        gui.Size = UDim2.fromOffset(240, 76)
        gui.StudsOffsetWorldSpace = Vector3.new(0, 4.5, 0)
        gui.LightInfluence = 0

        local label = state.Label

        local labelIsValid = label
                and label:IsA("TextLabel")
                and label.Parent == gui

        if not labelIsValid then
                local existing = gui:FindFirstChild(LABEL_NAME)

                if existing and existing:IsA("TextLabel") then
                        label = existing
                else
                        if existing then
                                safeDestroy(existing)
                        end

                        label = Instance.new("TextLabel")
                        label.Name = LABEL_NAME
                        label.Parent = gui
                end

                state.Label = label
        end

        label.Size = UDim2.fromScale(1, 1)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = textColor
        label.TextSize = 17
        label.TextWrapped = true
        label.TextScaled = false
        label.Font = Enum.Font.GothamBold
        label.TextXAlignment = Enum.TextXAlignment.Center
        label.TextYAlignment = Enum.TextYAlignment.Center

        label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        label.TextStrokeTransparency = 0.1

        return true
end

local function renderCrystal(crystal, state, isTopFive)
        local rarity = rarityData[state.Tier]

        if not rarity then
                return
        end

        local valueText = formatCurrency(state.Value)
        local weightText = formatWeight(state.Weight)

        local infoText = string.format(
                "%s - %s\nValue: %s\nWeight: %s",
                state.Tier,
                rarity.Name,
                valueText,
                weightText
        )

        local textColor = rarity.Color

        if isTopFive then
                textColor = TOP_COLOR
        end

        ensureHighlight(crystal, state)

        local crystalPart = getCrystalPart(crystal)

        local guiIsInvalid = not state.Gui
                or not state.Gui.Parent
                or state.Gui.Parent ~= crystalPart
                or not state.Label
                or state.Label.Parent ~= state.Gui

        local needsUpdate = state.LastText ~= infoText
                or state.LastColor ~= textColor
                or state.LastTopState ~= isTopFive
                or guiIsInvalid

        if needsUpdate then
                local guiCreated = ensureInfoGui(
                        crystal,
                        state,
                        infoText,
                        textColor
                )

                if guiCreated then
                        state.LastText = infoText
                        state.LastColor = textColor
                        state.LastTopState = isTopFive
                end
        end
end

local function cleanupCrystal(crystal, state)
        removeVisuals(crystal, state)
        trackedCrystals[crystal] = nil
end

local function registerCrystal(crystal, folder)
        if not isCrystalObject(crystal) then
                return
        end

        local tier = getTierFromName(crystal.Name)

        if not tier then
                return
        end

        local state = trackedCrystals[crystal]

        if not state then
                registrationIndex += 1

                state = {
                        Folder = folder,
                        Tier = tier,
                        Value = nil,
                        Weight = nil,
                        Highlight = nil,
                        Gui = nil,
                        Label = nil,
                        LastText = nil,
                        LastColor = nil,
                        LastTopState = nil,
                        Order = registrationIndex,
                }

                trackedCrystals[crystal] = state
        else
                state.Folder = folder
                state.Tier = tier
        end
end

local function findCrystalAncestor(object, folder)
        local current = object

        while current and current ~= folder do
                if isCrystalObject(current) and getTierFromName(current.Name) then
                        return current
                end

                current = current.Parent
        end

        return nil
end

local function processFolder(folder)
        for _, object in ipairs(folder:GetDescendants()) do
                if isCrystalObject(object) and getTierFromName(object.Name) then
                        registerCrystal(object, folder)
                end
        end

        folder.DescendantAdded:Connect(function(object)
                local crystal = findCrystalAncestor(object, folder)

                if crystal then
                        task.defer(function()
                                pcall(function()
                                        if crystal.Parent and crystal:IsDescendantOf(folder) then
                                                registerCrystal(crystal, folder)
                                        end
                                end)
                        end)
                end
        end)
end

local function updateAllCrystals()
        local candidates = {}
        local staleCrystals = {}

        for crystal, state in pairs(trackedCrystals) do
                local success = pcall(function()
                        local isStillInFolder = crystal.Parent ~= nil
                                and state.Folder ~= nil
                                and state.Folder.Parent ~= nil
                                and crystal:IsDescendantOf(state.Folder)

                        local tier = getTierFromName(crystal.Name)

                        if not isStillInFolder or not tier then
                                table.insert(staleCrystals, {
                                        Crystal = crystal,
                                        State = state,
                                })

                                return
                        end

                        state.Tier = tier

                        state.Value = toNumber(getAttribute(crystal, "Value"))
                        state.Weight = toNumber(getAttribute(crystal, "WeightKg"))

                        if not state.Value or state.Value < MIN_VALUE then
                                removeVisuals(crystal, state)
                                return
                        end

                        table.insert(candidates, {
                                Crystal = crystal,
                                State = state,
                                Value = state.Value,
                        })
                end)

                if not success then
                        table.insert(staleCrystals, {
                                Crystal = crystal,
                                State = state,
                        })
                end
        end

        for _, item in ipairs(staleCrystals) do
                cleanupCrystal(item.Crystal, item.State)
        end

        table.sort(candidates, function(first, second)
                if first.Value == second.Value then
                        return first.State.Order < second.State.Order
                end

                return first.Value > second.Value
        end)

        for rank, item in ipairs(candidates) do
                local isTopFive = rank <= TOP_COUNT

                pcall(function()
                        renderCrystal(
                                item.Crystal,
                                item.State,
                                isTopFive
                        )
                end)
        end
end

processFolder(droppedCrystalsFolder)
processFolder(crystalsFolder)

updateAllCrystals()

local running = true

script.Destroying:Connect(function()
        running = false

        for crystal, state in pairs(trackedCrystals) do
                removeVisuals(crystal, state)
        end
end)

task.spawn(function()
        while running do
                task.wait(REFRESH_INTERVAL)

                if running then
                        pcall(updateAllCrystals)
                end
        end
end)
