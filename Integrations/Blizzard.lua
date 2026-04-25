local _, ns = ...

local FONT          = ns.FONT_PATH
local SIZE_FALLBACK = 13
local FONT_NORM     = FONT:lower():gsub("\\", "/")

local CN_HEADERS = {
    description = "任务描述",
    objectives  = "任务目标",
    rewards     = "奖励",
    learnSpell  = "学习技能：",
    experience  = "经验：",
    itemChoose  = "你将能够选择以下奖励之一：",
    itemReceive = "你将同时收到：",
}

-- Per-frame state: active = currently showing our text, text = last string we set,
-- origObj = font object the frame inherited before we disconnected it with SetFont,
-- lastSize = font size we last applied (used to detect object-level size changes).
local frameState = {}

local function ResetGuards()
    for _, state in pairs(frameState) do
        state.active = false
    end
end

local function SetCN(frame, text)
    if not frame then return end
    -- Capture the inherited font object BEFORE SetFont disconnects the frame from it.
    -- LTP resizes by calling SetFont on the shared object (e.g. QuestFont), not on frames
    -- directly, so polling origObj lets us follow those changes in real time.
    local origObj = frame:GetFontObject()
    local _, size = frame:GetFont()
    local appliedSize = size or SIZE_FALLBACK
    frame:SetFont(FONT, appliedSize)
    frame:SetText(text)
    frameState[frame] = { active = true, text = text, origObj = origObj, lastSize = appliedSize }
end

-- Each tick: if the original font object's size changed (LTP slider), re-apply our font
-- at the new size so Chinese text tracks LTP in real time.
local function SyncFonts()
    for frame, state in pairs(frameState) do
        if state.active then
            if state.origObj then
                local _, objSize = state.origObj:GetFont()
                if objSize and objSize ~= state.lastSize then
                    frame:SetFont(FONT, objSize)
                    frame:SetText(state.text)
                    state.lastSize = objSize
                end
            else
                -- Fallback for frames with no font object: detect direct SetFont override.
                local font, size = frame:GetFont()
                local norm = font and font:lower():gsub("\\", "/") or ""
                if norm ~= FONT_NORM then
                    frame:SetFont(FONT, size or SIZE_FALLBACK)
                    frame:SetText(state.text)
                end
            end
        end
    end
end

-- Own frame so SetScript("OnUpdate") is guaranteed to fire every tick.
-- Runs always; when frameState is empty or inactive the loop is trivial.
local syncFrame = CreateFrame("Frame")
syncFrame:SetScript("OnUpdate", SyncFonts)

local function GetCurrentQuestID()
    if QuestMapDetailsScrollFrame and QuestMapDetailsScrollFrame:IsVisible() then
        local id = QuestMapFrame and QuestMapFrame.DetailsFrame and QuestMapFrame.DetailsFrame.questID
        if id and id ~= 0 then return id end
    end
    if QuestLogPopupDetailFrame and QuestLogPopupDetailFrame:IsVisible() then
        local id = QuestLogPopupDetailFrame.questID
        if id and id ~= 0 then return id end
    end
    local ok, id = pcall(GetQuestID)
    if ok and id and id ~= 0 then return id end
end

local function Wrap(cnText, frame, language)
    if language ~= "dual" then return cnText end
    local en = frame and frame:GetText() or ""
    if en == "" or en == cnText then return cnText end
    return cnText .. "\n\n|cffaaaaaa" .. en .. "|r"
end

local function ApplyToFrame(language, event)
    ResetGuards()

    local questID = GetCurrentQuestID()
    if not questID then return end
    local data = ns.GetQuestData(questID)
    if not data then return end

    if data.title ~= "" then
        SetCN(QuestInfoTitleHeader,   data.title)
        SetCN(QuestProgressTitleText, data.title)
    end

    SetCN(QuestInfoDescriptionHeader, CN_HEADERS.description)
    SetCN(QuestInfoObjectivesHeader,  CN_HEADERS.objectives)

    if QuestInfoRewardsFrame then
        SetCN(QuestInfoRewardsFrame.Header,          CN_HEADERS.rewards)
        SetCN(QuestInfoRewardsFrame.ItemChooseText,  CN_HEADERS.itemChoose)
        SetCN(QuestInfoRewardsFrame.ItemReceiveText, CN_HEADERS.itemReceive)
    end

    SetCN(QuestInfoSpellObjectiveLearnLabel, CN_HEADERS.learnSpell)

    if QuestInfoXPFrame then
        SetCN(QuestInfoXPFrame.ReceiveText, CN_HEADERS.experience)
    end

    if data.description ~= "" then
        SetCN(QuestInfoDescriptionText, Wrap(data.description, QuestInfoDescriptionText, language))
    end

    if data.objective ~= "" then
        SetCN(QuestInfoObjectivesText, Wrap(data.objective, QuestInfoObjectivesText, language))
    end

    if event == "QUEST_PROGRESS" and data.progress ~= "" then
        SetCN(QuestProgressText, Wrap(data.progress, QuestProgressText, language))
    end

    if event == "QUEST_COMPLETE" and data.completion ~= "" then
        SetCN(QuestInfoRewardText, Wrap(data.completion, QuestInfoRewardText, language))
    end
end

local function UpdateQuestListTitles()
    if not (QuestScrollFrame and QuestScrollFrame.titleFramePool) then return end
    for button in QuestScrollFrame.titleFramePool:EnumerateActive() do
        if button.Text and button.questID then
            local data = ns.GetQuestData(button.questID)
            if data and data.title ~= "" then
                local _, size = button.Text:GetFont()
                button.Text:SetFont(FONT, size or SIZE_FALLBACK)
                button.Text:SetText(data.title)
            end
        end
    end
    if QuestScrollFrame.Contents and QuestScrollFrame.Contents.Layout then
        QuestScrollFrame.Contents:Layout()
    end
end

ns.RegisterIntegration({
    id              = "Blizzard",
    label           = "Blizzard Quest UI",
    addonDependency = nil,
    defaultLanguage = "dual",
    options         = { "english", "dual", "chinese" },

    activate = function(language)
        if language == "english" then return end

        local f = CreateFrame("Frame")
        f:RegisterEvent("QUEST_DETAIL")
        f:RegisterEvent("QUEST_PROGRESS")
        f:RegisterEvent("QUEST_COMPLETE")
        f:SetScript("OnEvent", function(_, event)
            C_Timer.After(0, function() ApplyToFrame(language, event) end)
        end)

        hooksecurefunc("QuestMapFrame_ShowQuestDetails", function()
            C_Timer.After(0, function() ApplyToFrame(language, "QUEST_DETAIL") end)
        end)

        hooksecurefunc("QuestLogQuests_Update", UpdateQuestListTitles)
    end,
})
