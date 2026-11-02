# EasyPocket

**Spell and equipment pockets for a cleaner OctoWoW interface.**

Group spells into small pockets, place a pocket icon on your action bar, and click it to reveal its contents. Configure pockets in the menu and add spells directly from your spellbook.

**Version:** 0.6.1-octowow-alpha · **Author:** edwinvancleef577

[img]https://raw.githubusercontent.com/edwinvancleef577/EasyPocket/main/docs/images/easypocket-menu.png[/img]


English | [Deutsch](README.de.md)

## Features

- Multiple pockets, with all settings saved per character.
- Custom names and icons; drag pocket icons directly onto action bars.
- Free spell and equipment-shortcut placement with persistent empty cells and duplicate entries.
- No extra hover square on pocket icons; tooltips remain available.
- Independent width and height selectors, each from 2 to 5 slots.
- Movable, fixed, or action-bar-relative pocket windows.
- Three designs: Current, Classic, and a standalone pfUI-inspired style.
- Native WoW menu framing, centered title, icon selector, and dropdowns.
- Pocket selection fills each column from top to bottom before starting the next; the new-pocket icon stays last.
- Minimap button, tooltips, and a separate debug window.
- English, German, French, Spanish, Brazilian Portuguese, Russian, Korean, and Simplified Chinese menus, plus automatic game-language selection.

## Installation

### OctoWoW Launcher

Add this Git URL in the launcher's addon manager:

`https://github.com/edwinvancleef577/EasyPocket.git`

The repository root contains `EasyPocket.toc` and all required Lua files. No other addon is required.

### Manual ZIP installation

1. Choose **Code → Download ZIP** and extract the archive.
2. Rename the extracted folder to **EasyPocket**.
3. Copy it into your game's `Interface/AddOns` directory.
4. Check the path is `Interface/AddOns/EasyPocket/EasyPocket.toc`, without an extra nested folder.
5. Enable EasyPocket on the character-selection screen. Open settings with **`/ep`** or the minimap icon.

Close the game before replacing an existing installation. Keep your WTF / SavedVariables files to retain settings. Earlier pocket configurations migrate automatically; old automatic layouts become fixed grids while preserving visible spell positions.

## Quick start

1. Open the menu and click the **+** icon after the existing pockets.
2. Set a name and icon on the right. Press Enter or leave the name field to save.
3. Choose the window position, design, width, and height from the dropdowns.
4. Click the pocket icon to open its contents and drag spells from the spellbook into any slot.
5. Drag the pocket icon from the menu onto an action-bar slot. Clicking that shortcut toggles the pocket.

The menu contains pocket settings, not a spell list. **Delete pocket**, beside **Choose icon**, requires a second click and removes that pocket and its own macros.

## Custom spells and missing labels

Missing spell names no longer terminate the spellbook scan. When the client exposes spell IDs through its spell links or cursor API, EasyPocket can keep a spell shortcut even if its label or tooltip is missing. These entries use the actual picked spell identity; a missing name is displayed as a spell ID.

On a stock client with neither name nor ID, an icon-backed spell pickup can be used in the current unchanged session. After a reload or spellbook change it must be dragged in again; EasyPocket does not persist a bare slot number that might later cast another spell. Unsupported cursor types and passive entries remain rejected and are now recorded in Debug.

## Equipment shortcuts

Drag equipment from your inventory or character equipment slots into a pocket, just like a spell. The pocket stores an **equip shortcut**, not the physical item. For example, add your fishing pole and your usual weapon to two slots to switch between them with a click.

- Clicking equips the item outside combat. An already equipped item stays equipped; the shortcut does not toggle it off or activate its use effect.
- Items are found again by item ID on each click, so rearranging bags does not break the shortcut. If several copies share an ID, a matching equipped copy or carried copy is used.
- Missing items stay in the pocket as dimmed shortcuts. They become available again when carried or equipped.
- Adding, moving, or deleting a shortcut does not consume or delete the item. Native pickup temporarily puts an item on the cursor; dropping into a pocket or cancelling returns it through the game's normal cursor handling.
- Equipment shortcuts can share a pocket with spells and be swapped or moved between pockets. If an occupied destination cannot be picked up, that destination remains intact.
- This version supports equippable gear, including fishing poles, weapons, armor, and trinkets. Consumables, bags, and quivers are not supported as equipment shortcuts.

The game still enforces level, proficiency, bag-space, and equipment restrictions. No merchant-use action is used to equip items.

## Moving and arranging spells

- Drop onto an empty slot to use that exact position, or onto the background to use the first free slot.
- Dragging a spell out removes its original entry once native pickup succeeds. Other entries stay in place.
- Dropping onto an occupied slot puts the previous spell on the cursor for placement elsewhere.
- Moving between pockets moves the entry. Discarding a dragged spell leaves its source slot empty.
- Right-click a spell slot to remove its entry. Left-click to cast; the pocket stays open.
- A full pocket does not grow automatically. Resize it in the menu. Shrinking is rejected if it would hide occupied cells.

EasyPocket uses the native spell and macro cursor directly, without drawing an additional icon. Macro icons support both the numeric stock API and filename-based clients; changing a pocket icon updates its menu preview, macro, and recognized action-bar buttons immediately. Removing a pocket shortcut from an action bar follows normal WoW behavior and does not delete the pocket definition.

## Window settings

**Free movement** is the default; new windows start at screen center. Drag a border or empty slot to move the window, or Shift-drag a spell. **Fixed** locks the chosen position. **Relative to pocket: left** attaches directly to the left of the recognized action-bar button, aligning the top edges. **Relative to pocket: above** attaches directly above it, aligning the left edges. Both follow the button with a small gap and cannot be dragged separately; select Free movement for manual placement. Without a recognized button, the last saved screen position or screen center is used. The old relative mode migrates to Above and discards its arbitrary offset.

**Current** keeps the previous tooltip-style frame. **Classic**, the default for new pockets, uses WoW dialog textures and framed slots. **pfUI style** uses flat dark surfaces and thin borders without requiring pfUI.

Language and Debug are at the lower right of the menu. Menu-language changes apply immediately and do not translate custom pocket names or game-provided spell names. The game font must support the selected language. Technical diagnostics can retain their original language.

## Compatibility and limits

Targets **OctoWoW / Vanilla-style API, Interface 11200, Lua 5.0**. No dependency on DragonForgeUI, pfUI, ClassicAPI, or SuperWoW. Replaced spellbooks must use native `PickupSpell`; custom action bars need a recognizable action slot to serve as relative anchors.

- Pocket contents support active player spells and equipment shortcuts, not consumables, pet actions, or arbitrary macros.
- Learned spell ranks are refreshed; spell names use the game's language. Changing the game language may require reassignment.
- Each pocket placed on an action bar needs a character macro. If the client's macro limit is reached, the pocket remains accessible from the menu; unrelated macros are never automatically deleted.
- Settings windows close in combat; pocket opening and spell buttons remain available subject to client restrictions.

This is an alpha release. **75 behavior tests pass under Lua 5.0.3 with a simulated Vanilla API**, alongside syntax checks. The 0.6.1 changes have **not been tested in the actual OctoWoW client**; appearance and interactions with particular client/UI modifications still need in-game validation.

## Troubleshooting and development

| Command | Purpose |
| --- | --- |
| `/ep` or `/easypocket` | Open pocket settings |
| `/ep debug` | Open the debug window |
| `/ep status` | Show load status and recent captured errors |

The debug window retains the last ten captured EasyPocket errors and the last twenty drag/drop diagnostics, including rejected drops that do not raise a Lua error. Reproduce a failed drag, then open `/ep debug` before reloading; diagnostics are kept only for the current session. Click the text and use Ctrl+A / Ctrl+C to copy it. When reporting a problem, include the addon version, client version, and reproduction steps. Review reports before sharing; do not upload your entire WTF folder, SavedVariables, or account information.

Run tests from the addon directory with Lua 5.0.3:

```sh
luac -p *.lua tests/*.lua
lua tests/run_vanilla.lua
```

Tests are not loaded by WoW. See [CHANGELOG.md](CHANGELOG.md) for the release notes.

## License

See [LICENSE](LICENSE). You may use, copy, modify, and share EasyPocket while retaining the notice. Use with official Blizzard-operated World of Warcraft services is not permitted; OctoWoW use is welcome. This is an independent fan project, provided without warranty. Game artwork and fonts remain the property of their respective owners.
