# Set up sniffr for me

You are setting up **sniffr** on my machine — a CLI that, pointed at a GitHub PR,
opens it in my terminal reviewer and has an AI agent drop **local-draft** review
comments on the risky lines before I read them. Work through the steps below.
Only ask me when there's a real choice; otherwise detect and proceed. Show me
each command before running anything that installs software.

**Ground rules**
- sniffr's comments are LOCAL DRAFTS — it never posts to GitHub. Don't do
  anything that would push code or post to a PR.
- Don't install system packages without showing me the command first.
- Anything interactive that needs my credentials (e.g. `gh auth login`), hand to
  me to run — don't attempt it yourself.

## 1. Install sniffr (if missing)

Run `command -v sniffr`. If absent:

```bash
curl -fsSL https://raw.githubusercontent.com/tomasvarga/herdr-sniffr/main/install.sh | bash
```

Confirm `~/.local/bin` is on my `PATH` (the installer warns if not).

## 2. Assess with `sniffr doctor`

Run `sniffr doctor` and resolve each ✗ line:

- **core deps** (`gh`, `jq`, `python3`, `herdr`) — install any missing (Homebrew
  on macOS; my distro's package manager on Linux). `herdr` is from herdr.dev.
- **gh not authenticated** → tell me to run `gh auth login` myself.
- **not inside herdr** → sniffr must be run from inside a herdr pane; note this,
  it's expected if you're not currently in one.

## 3. Choose the backend (where comments land)

sniffr auto-detects an installed reviewer (tuicr → hunk). Check what I have:

- **tuicr** (tuicr.dev) — full review, can submit to the forge. sniffr's default.
- **hunk** (`brew install modem-dev/tap/hunk`) — fast diff viewer.

If neither is installed, ask which I prefer and install it. If I want the
non-default, write it to `~/.config/sniffr/config.toml`:

```toml
backend = "hunk"
```

(A `config.example.toml` ships in the repo with all options, including a custom
`prompt` to focus the review and custom backends.)

## 4. Choose the review agent

sniffr needs one agent CLI. Detect which of these is installed and authenticated:
`codex`, `claude`, `cursor-agent`, `grok`, `opencode`, `ollama`. Set my default:

```bash
sniffr --set-agent <name>
```

If none is installed, tell me which you'd recommend and how to install it. (Any
other tool works too via `SNIFFR_CMD` — mention it only if I ask.)

## 5. (Optional) wire it into my workflow

Ask if I want either:
- a **herdr keybind** to sniff a PR URL from my clipboard, or
- a **herdr-pickr** backend entry (`run = "sniffr {url}"`) so Ctrl+click offers it.

Only add these if I say yes; show me the config diff first.

## 6. Verify

Run `sniffr doctor` — everything should be ✓. Then ask me for a real PR I care
about and run `sniffr <owner/repo#N>` from inside a herdr pane; confirm the
reviewer opens and draft comments appear a few seconds later. Remind me they're
local drafts I prune (`dd`) and submit myself.
