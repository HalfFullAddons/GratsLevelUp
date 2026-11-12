# Changelog

## 1.3.0-beta6
- Fixed: when the panel opened during combat, its first page showed solid instead of faded.
- The panel's opening slide-in now works: it glides in from the right while fading up (to its faded level in combat).

## 1.3.0-beta5
- Levelling up in combat now opens the full panel straight away, faded, instead of the small strip. It turns solid and plays through when combat ends. Replays in combat do the same.
- The strip remains as the "Strip only" celebration style and for battlegrounds; left-clicking it now opens the full review in that style too.

## 1.3.0-beta4
- Buttons keep working while the panel is faded in combat: Skip, Back and Next can be clicked; the rest of the faded panel still lets clicks through to the game.
- The first page's button now says "Next" instead of "Continue".

## 1.3.0-beta3
- Buttons and the title plate now match each theme: every race frame and the Dark theme has its own colour (blue for Human, purple for Night Elf, teal for Troll, iron grey for Dark, and so on). Gold trim is unchanged.
- Corner gems come in ten colours, one per race frame (sapphire, amber, pink, amethyst, diamond, ruby, emerald, turquoise, lime, cyan). Classic themes keep red or blue by faction.

## 1.3.0-beta2
- Race themes for Tauren, Undead and Windshaper: all ten races now have their own frame, page and atmosphere.
- The Dark theme has its own dark steel frame and near-black page (it no longer reuses the gold frame).
- New art for the minimap button, the options title bar and the combat strip's lock/unlock icon.
- If the game reports both Skyborne peoples simply as "Skyborne", "My race" picks High Order for Alliance and Windshaper for Horde.

## 1.3.0-beta1
First public Beta.
- Training data refreshed for all nine classes from the current What's Training? WoW: Forever set (1,520 entries, levels 1-60). Priest race-spell prices corrected.
- Spells taught by class quests (Defensive Stance, Bear Form, totems, demons and the like) now appear at the level their quest opens, marked "Class quest" instead of a price. They are never counted in the training total.
- Published by HalfFull Addons. The version shown in game now comes from the release tag.

## 1.2.1
- New option: Level-up sound. Choose the WoW level-up "ding" (default), the WoW quest-complete sound, or None. Grats! fanfares are listed (greyed out) until they ship.
- The level-up sound now plays on real level-ups too: it starts a moment after the game's own level-up effects instead of under them.
- Replay (minimap left-click, the strip, /gratz replay) now plays the latest level-up of the character you're on. Other characters' level-ups are under "Other characters" in the minimap menu.
- History keeps 5 level-ups per character. Older saves are claimed by the character they fit (same class and race).

## 1.2.0
- Race themes: full custom frames, pages and drifting atmosphere for Human, Dwarf, Gnome, Night Elf, High Order, Orc and Troll.
- New default theme "My race" picks your character's race; any race can be chosen in Options > Theme (an Orc can use the Night Elf frame).
- Options shows a live preview of the theme; hovering a choice in the list previews it before you pick.
- Text is inked to suit each page, kept inside each frame's writing area; Night Elf, Troll and Gnome frames draw a little larger so the text keeps its size.
- New option: Race atmosphere (off in combat and while see-through).
- Races whose art isn't ready yet (Tauren, Undead, Windshaper) stay hidden from the menu and use the classic frame until then.
- Players on the old default (Parchment) move to "My race" once; a deliberate choice is kept.

## 1.1.7
- Back / Skip / Next are now one group centred on the panel, with equal widths that shrink to fit narrow frames.
- Page dots are centred above the buttons for any page count (2-page reviews were off-centre).
- The Bar Check button is centred above the group.

## 1.1.6
- Training data now comes from What's Training?'s WoW: Forever set (Forever's new and changed spells and race/class combinations, including Skyborne), instead of its Classic Era set. Paladins, for example, now get all four level 6 spells.

## 1.1.5
- Replays are rebuilt with the current version: training, places and milestone are refreshed (stat gains stay as recorded), so older saved level-ups show what they should have. Spells you've learned since are listed as "Learned" in grey and left out of the total.

## 1.1.4
- Fixed: new training didn't show on newer clients (WoW: Forever). Those clients only know an unlearned spell's name once its details are loaded, and Grats! was dropping unnamed spells. It now loads your class's trainer spells at login, never drops a spell, shows "Loading..." for any still arriving, and fills them in when they load.
- New option: Use What's Training? data. Available when that addon is installed (ignore list, discounted prices); greyed out with a note when it isn't. Grats! lists your training either way.

## 1.1.3
- Fixed: after a level-up from a kill, the review could open as a faint 25% watermark and stay that way (the game's combat flag lags behind its combat-ended event). The watermark now clears itself within a second of leaving combat.

## 1.1.2
- Level-ups are detected from any of the client's signals (PLAYER_LEVEL_UP, PLAYER_LEVEL_CHANGED, UNIT_LEVEL or the "Congratulations" line), once per level. When the client doesn't send stat gains, Grats! measures them from your stats before and after.
- If building a review ever fails, Grats! still shows a simple review, says so once in chat, and keeps the error for /gratz error.

## 1.1.1
- Fixed: a level-up from a killing blow could leave the review waiting forever (the game ends combat a moment before it reports the level-up). Grats! now uses the strict combat check and also checks once a second, so the review always plays once you're out of combat.
- The game's big level-up text is now hidden wherever the client draws it (level-up display, event toast or centre-screen message frames), only in the moments after a level-up.

## 1.1.0
- New original art: ornate gold frame with carved wood, aged parchment (and a dark version), red title plaque, faction gems set in the corner sockets, red lacquer buttons (normal, hover, pressed, disabled), matching combat strip, ornamental dividers, golden glow behind GRATS!, and page pips.
- The frame tints for Dark, Class and Faction themes; gems follow your faction.
- Falls back to the game's own textures if the art files are missing.

## 1.0.6
- The review fades away on its own 8 s after the last page finishes animating (or after you stop paging by hand). Hovering it, or a combat watermark, holds it open. Option: Fade out after (0 = never).
- Replays started in combat (or in a battleground / strip-only mode) behave like a real level-up there: combat strip and chime now, full review when combat ends.

## 1.0.5
- Fixed: Back, Skip, Next and Done could stop responding for good after combat started while a review was open and it was closed before combat ended.
- Fixed: Preview in the options window now closes the options window first, so the review isn't hidden behind it.
- New: "Still at your trainer" lists spells from earlier levels you haven't learned yet (lower ranks you've already outgrown are left out). On levels with no new spells, the Training page shows these instead of being skipped. The total includes them.

## 1.0.4
- Back button to revisit earlier pages (going back pauses auto-advance for that review).
- Intro opens with a big GRATS! headline and golden flash, then "You have reached", the level and your race/class; the title plate is hidden on the intro.
- Page dots centred above the buttons; intro holds 4 s (7 s at milestones).

## 1.0.3
- Presentation-style text: each line fades in and rises into place one after another; stat gains and the training total count up; the big level number gets a golden flash on the intro. Option: Animate text.

## 1.0.2
- Minimap button rides the minimap's real rim (half its width + 5) instead of a fixed 80 px radius, and follows it if the minimap is resized.

## 1.0.1
- Framing matches the mockup: parchment fills the whole page (cropped to clean paper), dark wood band with an inner edge, larger faction-coloured corner gems, title plate sits inside the frame.
- Right-side placement matches Jim's layout: docks 27 px left of the quest tracker, top 7 px below it (same spot by screen proportion when no tracker is shown).
- Combat strip uses the same framing.

## 1.0.0
- First release: intro, stats, training and where-to-next pages; combat strip; four themes; quick and strip-only modes; right-docked placement beside the quest tracker; replay history (last 5); minimap button; options panel; keybindings.
- Built-in training data for all 9 classes; optional What's Training? integration; optional Bar Check link.
