# Chinese Quest Translations

A World of Warcraft addon that overlays Simplified Chinese translations onto quest text for players on EU clients. Works with both the native Blizzard quest UI and the DialogueUI addon.

## 先说几句

终于可以正常看中文任务文本了！不管是用游戏自带的任务界面，还是装了DialogueUI插件，任务描述、目标、对话啥的现在都能显示中文。

没什么复杂的——下载下来，把整个文件夹扔进你的 `AddOns` 目录，重新登录就好了。真的就这样。

下面那些英文是给开发者看的技术文档，你们直接无视就行。好好升级，天天向上！

---

## Features

- **39,000+ quests** translated into Simplified Chinese
- **Two UI integrations** — native Blizzard frames and DialogueUI, independently configurable
- **Three display modes** per integration — English only, Dual (Chinese + English side by side), or Chinese only
- **Dynamic text** — `{name}`, `{race}`, `{class}` placeholders and gender variants resolve to your character at runtime
- **Leatrix Plus compatibility** — the font size slider resizes Chinese text in real time
- **CJK font included** — no separate font installation needed

## Compatibility

- World of Warcraft retail (patch 12.x)

## Installation

1. Download or clone this repository
2. Copy the `WoWcnQuestTranslations` folder into:
   ```
   World of Warcraft/_retail_/Interface/AddOns/
   ```
3. Reload or launch the game

## Configuration

Open **Game Menu → Interface → AddOns → Chinese Quest Translations**.

Each integration has its own set of radio buttons:

| Option | Behaviour |
|--------|-----------|
| **English Only** | Addon is inactive for this integration — original text only |
| **Dual Language** *(default)* | Chinese text first, original English below in grey |
| **Chinese Only** | Chinese text only, English suppressed |

Changes take effect after a UI reload (the addon will prompt you).

## How It Works

### Blizzard integration

Hooks the `QUEST_DETAIL`, `QUEST_PROGRESS`, and `QUEST_COMPLETE` events plus `QuestMapFrame_ShowQuestDetails`. On each quest open, it writes the translated text directly onto the standard Blizzard quest frames using the bundled CJK font. An always-running sync loop tracks any external font-size changes (e.g. Leatrix Plus slider) and re-applies the correct size in real time.

### DialogueUI integration

Registers a translator via `DialogueUIAPI.SetTranslator`. DialogueUI calls into the addon to retrieve translated title, description, objectives, progress, and completion text for each quest. The integration also hooks `UpdateQuestTitle` to translate the large H1 header shown next to the NPC portrait.

## Project Structure

```
WoWcnQuestTranslations/
├── WoWcnQuestTranslations.toc        # Addon manifest
├── QuestData.lua             # Translation database (~39k quests)
├── Core.lua                  # Namespace, DB, text expansion, integration registry
├── Settings.lua              # In-game options panel
├── Integrations/
│   ├── Blizzard.lua          # Native Blizzard quest UI integration
│   └── DialogueUI.lua        # DialogueUI addon integration
└── Fonts/
    └── SourceHanSans.ttf     # Bundled CJK font (Adobe Source Han Sans, OFL licensed)
```

## Contributing

Quest data lives in `QuestData.lua` as a flat Lua table keyed by quest ID:

```lua
["12345"] = {
    Title       = "任务标题",
    Description = "任务描述。",
    Objectives  = "任务目标。",
    Progress    = "进行中的文本。",
    Completion  = "完成时的文本。",
    Translator  = "",
},
```

Supported placeholders: `{name}`, `{race}`, `{class}`, `NEW_LINE`, `YOUR_GENDER(male;female)`.

Pull requests for new or corrected translations are welcome.

## Author

**zejj42**

## License

MIT
