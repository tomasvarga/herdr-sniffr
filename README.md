# sniffr

An AI **sniffs your PR for issues before you review it**. Point `sniffr` at a
GitHub pull request: it opens the PR in [tuicr](https://tuicr.dev), then an AI
agent reviews the diff **in the background** and drops its findings in as draft
review comments — so by the time you start reading, the risky lines are already
flagged. Agent-agnostic (Codex, Claude, Cursor, Grok, opencode, ollama).

Part of a terminal PR-review workflow on [herdr](https://herdr.dev); pairs with
[herdr-pickr](https://github.com/tomasvarga/herdr-pickr) (add it as a `[[backend]]`).

> Status: early (v0.1). macOS + GitHub tested.

## How it works

```
sniffr <pr>
  → tuicr opens the PR (in a herdr split) — you start reading immediately
  → a detached worker runs your agent over the diff
  → findings injected as tuicr LOCAL-DRAFT comments (never pushed)
  → the pane reloads; a notification fires when done
```

## Install

```bash
git clone https://github.com/tomasvarga/sniffr ~/Documents/GitHub/sniffr
~/Documents/GitHub/sniffr/install.sh     # symlinks bin/sniffr into ~/.local/bin
```

## Usage

```bash
sniffr <pr>                 # number | owner/repo#N | URL   (run from a herdr pane)
sniffr <pr> --agent grok    # one-off agent override
sniffr --set-agent grok     # save the default agent (--show-agent prints it)
```

Pick the agent (first match wins): `--agent` flag · `SNIFFR_AGENT` env · saved
default (`~/.config/sniffr/agent`) · `codex`. Built-ins: **codex · claude ·
cursor · grok · opencode · ollama**. Any other tool via `SNIFFR_CMD='<command>'`
(gets the review prompt on stdin, must print a JSON array of findings). Findings
are stamped with the agent name so they're distinct from yours; in tuicr `dd`
drops one, `:clearc` clears all.

## Requirements

**herdr ≥ 0.7.0**, **tuicr**, `gh`, `jq`, `python3`, and an agent CLI. Runs from
inside a herdr pane. GitHub only for now.

## Limitations

- **herdr + tuicr required** (v0.1) — sniffr opens tuicr in a herdr split and
  reloads it. (A herdr-optional mode is a possible future direction.)
- **Line anchoring** relies on the agent reading the diff's `@@` hunks — a comment
  can land a few lines off; findings with no line become file-level comments.
- Comments are **local drafts** — never pushed until you submit them in tuicr.

## License

MIT — see [LICENSE](LICENSE).
