# Fork template: notes for an AI agent

This folder is a **fork**: a game of its own on the Pax Universe platform. Read `mod.json` first: its `fork` section
says what stays of Pax Universe (`base`), which scene starts (`scene`) and which launcher opens (`launcher`).

## What you edit

- `launcher.gd` — the fork's launcher. Buttons call `Pax.platform`: `play()`, `open("store" | "нейросеть" | "profile")`,
  `switch_game()`.
- `main.gd` — the game itself. With `"base": "none"` nothing of Pax Universe's world runs: this scene is the whole game.
- `mod.json` — keep `id` and the `res://mods/<id>/…` paths in sync when you rename the fork.

## Rules of the platform

- Save files go to `Pax.platform.data_dir()`, never to plain `user://` (that is outside the fork's profile).
- Ask the AI with `Pax.ask_ai(channel, prompt, data, done)`. Never ask the player for API keys: the game has them.
  `"ai": "any"` / `"strong"` keeps the AI system on; the player picks a local model, their own key or Pax AI
  (paid with Pax, no keys) on our page — `Pax.platform.open("нейросеть")`.
- Sell items only through `Pax.platform.purchase(sku, done, qty)`: our window confirms and charges Pax. Kinds: forever,
  consumable (`stack`, spend with `Pax.platform.consume(sku, n, done)` — the count lives on our server) and for N days. Never draw your own
  payment, login or key screens: the Workshop moderator rejects that.
- Do not hide or intercept the platform splash or Ctrl+F12: it is the player's way back.
- Set `"ai"` in the `fork` section: `"none"`, `"any"` or `"strong"` — players see it before buying.

## Testing without screenshots

Turn on the MCP bridge (launcher → Settings → AI agents bridge) and use its tools: `read_log` for errors, `ui_tree`
and `ui_click` to see the screen as text and press buttons, `reload_mods` after edits.
Full guide: `docs/modding/en/16-forks.md` (Russian: `docs/modding/ru/16-форк.md`).
