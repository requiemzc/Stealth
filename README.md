# Stealth

Key system UI for Roblox executors, built on the [Patriot Key System UI Library](https://github.com/SyndromeXph/Patriot-Key-System-Ui-Library).

## Usage

Load the script with your executor:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/requiemzc/Stealth/main/Stealth.lua"))()
```

The window opens branded as **Stealth** with the logo decal `94734287536234`. Enter the key to verify; on success, the `OnSuccess` callback runs your main script.

## Configuration

Edit `Stealth.lua` to customize:

| Field | Description |
|-------|-------------|
| `VALID_KEY` | The key users must enter (replace with your own) |
| `Patriot.Appearance.Icon` | Logo asset ID (`rbxassetid://94734287536234`) |
| `Patriot.Appearance.Title` | Window title (`"Stealth"`) |
| `Patriot.Links.GetKey` | URL the "Get Key" button opens |
| `Patriot.Links.Discord` | Discord invite URL |
| `Patriot.Theme` | Color palette |
| `Patriot.Callbacks.OnSuccess` | The main script to run after verification |
| `Patriot.Callbacks.OnVerify` | Validation logic (simple / Luarmor / Panda Auth / Junkie / HTTP API) |

## Integrations

The script includes commented examples for:

- **Luarmor** — `Patriot:LaunchLuarmor({ scriptId = "..." })`
- **Panda Auth (Wilkins)** — `Patriot:LaunchWilkins({ serviceId = "..." })`
- **Junkie SDK** — `Patriot:LaunchJunkie({ Service = "...", Identifier = "...", Provider = "..." })`
- **HTTP API** — `Patriot.Callbacks.OnVerify = function(key) ... end`
- **Keyless mode** — `Patriot.Options.Keyless = true`

## License

See [Patriot Key System UI Library](https://github.com/SyndromeXph/Patriot-Key-System-Ui-Library) for upstream licensing.
