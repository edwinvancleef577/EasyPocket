# Changelog

## 0.5.0-octowow-alpha

Initial repository release of EasyPocket for OctoWoW / Vanilla API (11200).

### Menu and appearance

- Use a centered title and native WoW frame matching the Easy addon menus.
- Fill pocket selector columns fully from top to bottom, with the creation icon last.
- Group name, icon selection, and pocket deletion on the right.
- Add dropdowns for position, design, independent width/height (2–5), and language.
- Provide Current, Classic, and standalone pfUI-inspired pocket designs.
- Keep related window controls together when focusing overlapping windows.
- Remove redundant open/drag buttons and the pocket-window collapse control.

### Pocket behavior

- Preserve arbitrary slot positions, gaps, and duplicate spell entries.
- Remove a dragged spell from its source after successful native pickup.
- Support moving between pockets and swapping with occupied slots through the cursor.
- Show a cursor icon alongside native spell and pocket-macro pickup.
- Replace automatic growth with fixed dimensions; reject shrinking over occupied cells.
- Migrate earlier saved layouts while preserving their visible arrangement.
- Keep pocket identities and action-bar macros stable across renaming and deletion.

### Documentation and validation

- Include English and German installation and usage documentation, license, and tests.
- Pass 40 simulated Vanilla behavior tests under Lua 5.0.3 and Lua syntax checks.
- In-client validation of the 0.5.0 changes remains outstanding.
