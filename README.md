# Stealth

Multi-script Roblox hub with a key system backed by [sstealth.vercel.app](https://sstealth.vercel.app) and a launcher UI that lets the user pick which script to run.

## End-user usage

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/requiemzc/Stealth/main/Stealth.lua"))()
```

1. The key prompt appears branded as **Stealth**.
2. Go to [sstealth.vercel.app](https://sstealth.vercel.app/) → copy your `FREE_xxx` key.
3. Paste the key into the prompt.
4. The Stealth Hub launcher appears with a **Scripts** tab listing all available scripts.
5. Click "Load: \<script name\>" to run any script you want.

Keys rotate every 15 minutes and are locked to a single HWID on first validation.

## Repository layout

```
Stealth.lua              ← key system (loaded by the user via loadstring)
Main.lua                 ← launcher with Rayfield script selector menu
scripts/                 ← your actual script files
  DefeatAnimeRNG.lua     ← placeholder — replace with your real hub
  BloxFruits.lua         ← placeholder — replace with your real hub
  PetSim99.lua           ← placeholder — replace with your real hub
  Universal.lua          ← placeholder — replace with your real hub
```

### How the pieces fit together

```
User runs Stealth.lua
        │
        ▼
Patriot key prompt (validates against sstealth.vercel.app/api/validate)
        │  (key valid)
        ▼
Main.lua loads → Rayfield UI appears with script selector menu
        │  (user clicks "Load: Blox Fruits")
        ▼
scripts/BloxFruits.lua loads → that game's hub UI appears
```

## Adding a new script

1. Drop your script file in the `scripts/` folder (e.g. `scripts/MyNewScript.lua`).
2. Add an entry to the `SCRIPTS` table at the top of `Main.lua`:

   ```lua
   {
       name = "My New Script",
       desc = "What it does.",
       icon = "package",
       url  = "https://raw.githubusercontent.com/requiemzc/Stealth/main/scripts/MyNewScript.lua",
   },
   ```

3. Commit + push.
4. Users see the new entry in the menu on next load.

## Replacing the placeholders

The files in `scripts/` are minimal placeholders. Replace each one with your real hub implementation. The placeholder for Defeat Anime RNG can be replaced with the full CheixHub conversion (see `download/CheixHub_Rayfield.lua` if you have it locally).

## Configuration

| Field | File | Description |
|-------|------|-------------|
| `MAIN_SCRIPT_URL` | `Stealth.lua` | URL of `Main.lua` (already pointing to this repo) |
| `STEALTH_API` | `Stealth.lua` | Key system API base URL (`https://sstealth.vercel.app`) |
| `Patriot.Links.Discord` | `Stealth.lua` | Your Discord invite |
| `Patriot.Appearance.Icon` | `Stealth.lua` | Logo decal ID (`rbxassetid://94734287536234`) |
| `SCRIPTS` table | `Main.lua` | Catalog of scripts shown in the launcher menu |

## Key system

- Website: [sstealth.vercel.app](https://sstealth.vercel.app/)
- API: `POST https://sstealth.vercel.app/api/validate` with body `{ "key": "FREE_xxx", "hwid": "..." }`
- Keys are random (`FREE_` + 32 hex chars), expire after 15 minutes, and lock to a single HWID on first validation.
- The key system source code is hosted separately from this repo.

## License

See [Patriot Key System UI Library](https://github.com/SyndromeXph/Patriot-Key-System-Ui-Library) and [Rayfield](https://github.com/SiriusSoftwareLtd/Rayfield) for upstream licensing.
