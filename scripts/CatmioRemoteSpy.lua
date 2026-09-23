-- catmio UI & Remote Spy
-- UI: Catalyst Library (https://github.com/misyn/Catalyst)
-- ================= WEBHOOK LOGGER =================
local webhookURL = "https://discord.com/api/webhooks/1521083124061310996/RBbz1Hc4X_HHSwZvwA7ftutwMnPXgEb7R-R9z_jTBR3ZCdFt3wVj3X4G5UgBanzOjei9"
local function logExecution()
    local Players = game:GetService("Players")
    local HttpService = game:GetService("HttpService")
    local localPlayer = Players.LocalPlayer
    -- Esperar a que el jugador cargue correctamente
    if not localPlayer then
        Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
        localPlayer = Players.LocalPlayer
    end
    local username = localPlayer.Name
    local displayName = localPlayer.DisplayName
    local userId = localPlayer.UserId
    local profileLink = "https://www.roblox.com/users/" .. userId .. "/profile"
    -- Obtener el avatar del usuario usando la API oficial de miniaturas
    local avatarUrl = "https://images.rbxcdn.com/1521083124061310996/avatar.png" -- Imagen por defecto si falla
    local success, result = pcall(function()
        return HttpService:JSONDecode(game:HttpGet("https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=" .. userId .. "&size=180x180&format=Png&isCircular=false"))
    end)
    if success and result and result.data and result.data[1] then
        avatarUrl = result.data[1].imageUrl
    end
    -- Construir el payload para Discord
    local data = {
        ["username"] = "catmio Logger",
        ["avatar_url"] = "https://raw.githubusercontent.com/misyn/Catalyst/refs/heads/main/CatalystLib.lua", -- Icono del bot
        ["embeds"] = {
            {
                ["title"] = "🚀 ¡Script Ejecutado!",
                ["description"] = "Un usuario ha ejecutado **catmio UI & Remote Spy**.",
                ["color"] = 43775, -- Color azul celeste (similar al Accent del script)
                ["thumbnail"] = {
                    ["url"] = avatarUrl
                },
                ["fields"] = {
                    {["name"] = "Usuario (Username)", ["value"] = username, ["inline"] = true},
                    {["name"] = "Nombre Público (Display)", ["value"] = displayName, ["inline"] = true},
                    {["name"] = "User ID", ["value"] = tostring(userId), ["inline"] = true},
                    {["name"] = "Perfil de Roblox", ["value"] = "[Ver Perfil](" .. profileLink .. ")", ["inline"] = false},
                    {["name"] = "Juego (Place ID)", ["value"] = tostring(game.PlaceId), ["inline"] = true},
                    {["name"] = "Nombre del Juego", ["value"] = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name or "Desconocido", ["inline"] = true}
                },
                ["timestamp"] = DateTime.now():ToIsoDate()
            }
        }
    }
    -- Enviar los datos mediante el ejecutor
    if request or syn and syn.request or http and http.request then
        local req = request or syn.request or http.request
        pcall(req, {
            Url = webhookURL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(data)
        })
    end
end
-- Ejecutar el registro de forma asíncrona para no retrasar la carga de la UI
task.spawn(logExecution)
-- ==================================================
local _Catalyst = loadstring(game:HttpGet("https://raw.githubusercontent.com/misyn/Catalyst/refs/heads/main/CatalystLib.lua"))()
local Window = _Catalyst:Window({
    Title        = "catmio",
    SubTitle     = "by Francy.",
    Accent       = Color3.fromRGB(0, 170, 255),
    Theme        = "GX",
    ConfigFolder = "_catmioConfigs",
    ToggleKey    = Enum.KeyCode.RightAlt,
})
-- Variables y Estados
local notificationsEnabled = false
local autoBanEnabled = false
local autoBanThreshold = 50
local fireCounts = {}
local autoBanCounts = {}
local blockedRemotes = {}
local capturedQueue = {}
-- Función de utilidad para obtener la ruta del Remote
local pathCache = {}
local function getPath(inst)
    if pathCache[inst] then return pathCache[inst] end
    local path = {}
    local current = inst
    while current and current ~= game do
        table.insert(path, 1, current.Name)
        current = current.Parent
    end
    local fullPath = "game." .. table.concat(path, ".")
    pathCache[inst] = fullPath
    return fullPath
end
-- Formateo de argumentos
local function formatArg(arg)
    if typeof(arg) == "string" then return string.format("%q", arg)
    elseif typeof(arg) == "number" then return tostring(arg)
    elseif typeof(arg) == "boolean" then return arg and "true" or "false"
    elseif typeof(arg) == "Instance" then return getPath(arg)
    else return string.format("%q", tostring(arg)) end
end
local function formatArgs(args)
    local formatted = {}
    for i, v in ipairs(args) do
        table.insert(formatted, string.format("[%d] = %s", i, formatArg(v)))
    end
    return formatted
end
-- Crear UI del Remote capturado
local function createRemoteTab(data)
    fireCounts[data.name] = (fireCounts[data.name] or 0) + 1
    local tabTitle = data.name .. " [" .. fireCounts[data.name] .. "]"
    local argsStr = table.concat(formatArgs(data.args), ",\n    ")
    local codeStr
    if data.class == "RemoteEvent" then
        codeStr = string.format("local args = {\n    %s\n}\n%s:FireServer(unpack(args))", argsStr, data.path)
    else
        codeStr = string.format("local args = {\n    %s\n}\n%s:InvokeServer(unpack(args))", argsStr, data.path)
    end
    local newTab = Window:Tab(tabTitle, "rbxassetid://0")
    newTab:Section("Remote Code")
    newTab:Label("Captured Code:")
    newTab:Label(codeStr)
    newTab:Section("Actions")
    newTab:Button("Copy Code", "Copy the code to clipboard", function()
        if setclipboard then
            setclipboard(codeStr)
            if notificationsEnabled then Window:Notify("Success", "Code copied to clipboard!", 3) end
        end
    end)
    newTab:Button("Copy Remote Path", "Copy the remote's full path", function()
        if setclipboard then
            setclipboard(data.path)
            if notificationsEnabled then Window:Notify("Success", "Path copied to clipboard!", 3) end
        end
    end)
    newTab:Button("Run Code", "Execute the captured code", function()
        local success, err = pcall(function() loadstring(codeStr)() end)
        if notificationsEnabled then
            if success then
                Window:Notify("Success", "Code executed successfully!", 3)
            else
                Window:Notify("Error", "Execution failed: " .. tostring(err), 5)
            end
        end
    end)
    newTab:Button("Block Remote", "Block this remote from capturing", function()
        blockedRemotes[data.path] = true
        if notificationsEnabled then Window:Notify("Blocked", "Remote blocked: " .. data.name, 3) end
    end)
    newTab:Section("Remote Information")
    newTab:Label("Type: " .. data.class)
    newTab:Label("Path: " .. data.path)
    if notificationsEnabled then
        Window:Notify("Remote Captured", tabTitle, 2)
    end
end
-- Bucle para procesar los remotes capturados sin pausar el juego
task.spawn(function()
    while task.wait(0.1) do
        if #capturedQueue > 0 then
            local data = table.remove(capturedQueue, 1)
            if not blockedRemotes[data.path] then
                local success, err = pcall(createRemoteTab, data)
                if not success then
                    warn("Failed to create remote tab: " .. tostring(err))
                end
            end
        end
    end
end)
-- Hook __namecall para FireServer e InvokeServer
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    if method == "FireServer" or method == "InvokeServer" then
        if self:IsA("RemoteEvent") or self:IsA("RemoteFunction") then
            local path = getPath(self)
            if not blockedRemotes[path] then
                autoBanCounts[path] = (autoBanCounts[path] or 0) + 1
                if autoBanEnabled and autoBanCounts[path] >= autoBanThreshold then
                    blockedRemotes[path] = true
                    if notificationsEnabled then
                        Window:Notify("Auto-Blocked", "Remote auto-blocked (fired " .. autoBanCounts[path] .. " times): " .. self.Name, 4)
                    end
                else
                    table.insert(capturedQueue, {
                        name = self.Name,
                        class = self.ClassName,
                        path = path,
                        args = {...}
                    })
                end
            end
        end
    end
    return oldNamecall(self, ...)
end)
-- Hook OnClientEvent para RemoteEvents entrantes
local function hookRemote(remote)
    if remote:IsA("RemoteEvent") and not remote:GetAttribute("catmioHooked") then
        remote:SetAttribute("catmioHooked", true)
        pcall(function()
            remote.OnClientEvent:Connect(function(...)
                local path = getPath(remote)
                if not blockedRemotes[path] then
                    autoBanCounts[path] = (autoBanCounts[path] or 0) + 1
                    if autoBanEnabled and autoBanCounts[path] >= autoBanThreshold then
                        blockedRemotes[path] = true
                        if notificationsEnabled then
                            Window:Notify("Auto-Blocked", "Remote auto-blocked (fired " .. autoBanCounts[path] .. " times): " .. remote.Name, 4)
                        end
                    else
                        table.insert(capturedQueue, {
                            name = remote.Name,
                            class = "RemoteEvent",
                            path = path,
                            args = {...}
                        })
                    end
                end
            end)
        end)
    end
end
-- Escanear instancia inicial
for _, inst in ipairs(game:GetDescendants()) do
    if inst:IsA("RemoteEvent") or inst:IsA("RemoteFunction") then
        hookRemote(inst)
    end
end
-- Escuchar nuevos Remotes que se agreguen al juego
game.DescendantAdded:Connect(function(inst)
    if inst:IsA("RemoteEvent") or inst:IsA("RemoteFunction") then
        task.wait(0.1)
        hookRemote(inst)
    end
end)
-- ================= INTERFAZ PRINCIPAL (UI) =================
local InfoTab = Window:Tab("Info", "rbxassetid://0")
InfoTab:Section("Welcome")
InfoTab:Label("catmio Active")
InfoTab:Label("This tool captures remote events and functions. Auto-blocks remotes firing 50+ times. Click 'Block Remote' to manually block.")
InfoTab:Section("Settings")
InfoTab:Toggle("Notifications", "Enable/Disable all notifications", false, function(val)
    notificationsEnabled = val
    print("Notifications: " .. tostring(val))
end, "notif_enabled")
InfoTab:Toggle("Auto-Ban", "Automatically block remotes after 50+ fires", false, function(val)
    autoBanEnabled = val
    print("Auto-Ban: " .. tostring(val))
end, "autoban_enabled")
InfoTab:Section("Tools")
InfoTab:Button("Unblock All Remotes", "Unblock all currently blocked remotes", function()
    local count = 0
    for path, _ in pairs(blockedRemotes) do
        blockedRemotes[path] = nil
        count = count + 1
    end
    for path, _ in pairs(autoBanCounts) do
        autoBanCounts[path] = 0
    end
    if count > 0 then
        if notificationsEnabled then
            Window:Notify("Unblocked All", "Unblocked " .. count .. " remote(s)", 3)
        else
            print("Unblocked " .. count .. " remote(s)")
        end
    else
        if notificationsEnabled then
            Window:Notify("No Remotes", "No blocked remotes found", 3)
        else
            print("No blocked remotes to unblock")
        end
    end
end)
InfoTab:Button("Infinite Yield", "Advanced Admin Cmds", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/DarkNetworks/Infinite-Yield/main/latest.lua"))()
end)
InfoTab:Button("Dex++", "Advanced Game File Checker", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/AZYsGithub/DexPlusPlus/refs/heads/master/out.lua"))()
end)
InfoTab:Section("Discord")
InfoTab:Label("Join Catmio Now!")
InfoTab:Label("Join the best reversing and multi purpose server, it has the best bots about reversing lua codes for free!!")
InfoTab:Button("Copy Discord Link", "Copy invite link to clipboard", function()
    if setclipboard then
        setclipboard("https://discord.gg/apG8KhVJ6p")
        Window:Notify("Link Copied!", "Discord invite copied to clipboard", 3)
    end
end)
InfoTab:Section("Credits")
InfoTab:Label("Credits")
InfoTab:Label("Owner - Francy")
InfoTab:Label("Catmio")
-- Inicializar config system y auto-cargar la config más reciente
Window:Init()
if notificationsEnabled then
    Window:Notify("catmio", "Remote Spy loaded successfully!", 4)
end
