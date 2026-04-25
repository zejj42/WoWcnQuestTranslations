local ADDON_NAME, ns = ...

-- ── Constants ─────────────────────────────────────────────────────────────────

ns.FONT_PATH = "Interface/AddOns/WoWcnQuestTranslations/Fonts/woweucn.ttf"

-- ── Integration registry ──────────────────────────────────────────────────────

local integrations = {}

function ns.RegisterIntegration(integration)
    integrations[#integrations + 1] = integration
end

function ns.GetIntegrations()
    return integrations
end

-- ── Database ──────────────────────────────────────────────────────────────────

local function InitDB()
    WoWcnQuestTranslations_DB = WoWcnQuestTranslations_DB or {}
    local db = WoWcnQuestTranslations_DB

    -- migrate flat { language = "..." } → { integrations = { DialogueUI = { language = "..." } } }
    if db.language ~= nil and db.integrations == nil then
        local lang = db.language
        -- also handle the even older { chineseOnly = bool } schema
        if db.chineseOnly ~= nil then
            lang = db.chineseOnly and "chinese" or "dual"
        end
        db.integrations = { DialogueUI = { language = lang } }
        db.language    = nil
        db.chineseOnly = nil
    end

    db.integrations = db.integrations or {}
end

function ns.GetIntegrationDB(id)
    return WoWcnQuestTranslations_DB.integrations[id] or {}
end

function ns.SetIntegrationLanguage(id, language)
    WoWcnQuestTranslations_DB.integrations[id] = WoWcnQuestTranslations_DB.integrations[id] or {}
    WoWcnQuestTranslations_DB.integrations[id].language = language
end

function ns.GetIntegrationLanguage(id, default)
    local entry = WoWcnQuestTranslations_DB.integrations[id]
    return (entry and entry.language) or default or "dual"
end

-- ── Text expansion ────────────────────────────────────────────────────────────

local RACE_NAMES = {
    [1]  = "人类",       [2]  = "兽人",       [3]  = "矮人",
    [4]  = "暗夜精灵",   [5]  = "亡灵",       [6]  = "牛头人",
    [7]  = "侏儒",       [8]  = "巨魔",       [9]  = "地精",
    [10] = "血精灵",     [11] = "德莱尼",     [22] = "狼人",
    [24] = "熊猫人",     [25] = "熊猫人",     [26] = "熊猫人",
    [27] = "夜之子",     [28] = "至高岭牛头人", [29] = "虚空精灵",
    [30] = "光铸德莱尼", [31] = "赞达拉巨魔", [32] = "库尔提拉斯人",
    [34] = "黑铁矮人",   [35] = "狐人",       [36] = "玛格汉兽人",
    [37] = "机械侏儒",   [52] = "龙希尔",     [70] = "龙希尔",
}

local CLASS_NAMES = {
    [1]  = "战士",   [2]  = "圣骑士",   [3]  = "猎人",
    [4]  = "盗贼",   [5]  = "牧师",     [6]  = "死亡骑士",
    [7]  = "萨满",   [8]  = "法师",     [9]  = "术士",
    [10] = "武僧",   [11] = "德鲁伊",   [12] = "恶魔猎手",
    [13] = "唤魔师",
}

local playerName    = UnitName("player")
local playerSex     = UnitSex("player")
local _, _, raceID  = UnitRace("player")
local _, _, classID = UnitClass("player")

local playerRace  = RACE_NAMES[raceID]   or UnitRace("player")
local playerClass = CLASS_NAMES[classID] or UnitClass("player")

function ns.ExpandText(text)
    text = text:gsub("NEW_LINE", "\n")
    text = text:gsub("{name}",  playerName)
    text = text:gsub("{race}",  playerRace)
    text = text:gsub("{class}", playerClass)
    text = text:gsub("YOUR_GENDER%((.-)%;(.-)%)", function(male, female)
        return playerSex == 3 and female or male
    end)
    return text
end

-- ── Quest data ────────────────────────────────────────────────────────────────

function ns.GetQuestData(questID)
    local data = ns.QuestData[tostring(questID)]
    if not data then return end

    return {
        title       = ns.ExpandText(data.Title       or ""),
        description = ns.ExpandText(data.Description or ""),
        objective   = ns.ExpandText(data.Objectives  or ""),
        progress    = ns.ExpandText(data.Progress    or ""),
        completion  = ns.ExpandText(data.Completion  or ""),
    }
end

-- ── Activation ────────────────────────────────────────────────────────────────

local function ActivateIntegrations()
    for _, integration in ipairs(integrations) do
        local loaded = integration.addonDependency == nil or C_AddOns.IsAddOnLoaded(integration.addonDependency)
        if loaded then
            local language = ns.GetIntegrationLanguage(integration.id, integration.defaultLanguage)
            integration.activate(language)
        end
    end
end

-- ── Bootstrap ─────────────────────────────────────────────────────────────────

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        self:UnregisterEvent("ADDON_LOADED")
        InitDB()

    elseif event == "PLAYER_ENTERING_WORLD" then
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
        ActivateIntegrations()
        ns.CreateOptionsPanel()
    end
end)
