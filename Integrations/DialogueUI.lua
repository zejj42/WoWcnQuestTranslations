local _, ns = ...

ns.RegisterIntegration({
    id                = "DialogueUI",
    label             = "Dialogue UI",
    addonDependency   = "DialogueUI",
    defaultLanguage   = "dual",
    options           = { "english", "dual", "chinese" },

    activate = function(language)
        if language == "english" then return end

        -- Register Chinese quest data with DialogueUI's translator API
        if DialogueUIAPI and DialogueUIAPI.SetTranslator then
            DialogueUIAPI.SetTranslator({
                name            = "DialogueUI-CN",
                font            = ns.FONT_PATH,
                questDataGetter = ns.GetQuestData,
                ttsGetter       = function(questID)
                    local data = ns.GetQuestData(questID)
                    if not data then return end
                    return {
                        title     = data.title,
                        body      = data.description,
                        objective = data.objective,
                    }
                end,
            })
        end

        -- Override the H1 header title with our Chinese translation.
        -- UpdateQuestTitle uses GetQuestTitle() (raw WoW API) and never calls the translator,
        -- so the header stays in English without this hook.
        if DUIQuestFrame and DUIQuestFrame.UpdateQuestTitle then
            hooksecurefunc(DUIQuestFrame, "UpdateQuestTitle", function(self)
                local questID = self.questID
                if not questID then return end
                local data = ns.GetQuestData(questID)
                if not (data and data.title ~= "") then return end
                local header = self.FrontFrame and self.FrontFrame.Header
                if not (header and header.Title) then return end
                local titleStr = header.Title
                local _, size = titleStr:GetFont()
                titleStr:SetFont(ns.FONT_PATH, size or 18)
                titleStr:SetText(data.title)
            end)
        end

        -- Suppress the title paragraph that FormatQuestText inserts via GetQuestTextExternal.
        -- Now that we show the title in the H1 header, the body copy is redundant.
        -- hooksecurefunc can't undo an already-inserted paragraph, so we swap InsertParagraph
        -- on the frame for the duration of the call to intercept and drop the title line.
        if DUIQuestFrame and DUIQuestFrame.FormatQuestText then
            local orig = DUIQuestFrame.FormatQuestText
            DUIQuestFrame.FormatQuestText = function(self, offsetY, method)
                local questID = self.questID
                local data = questID and ns.GetQuestData(questID)
                local cnTitle = data and data.title ~= "" and data.title
                if cnTitle then
                    local origInsert = self.InsertParagraph
                    self.InsertParagraph = function(s, y, text, font)
                        if text == cnTitle then return y end
                        return origInsert(s, y, text, font)
                    end
                    local newOffsetY, translatedObjective = orig(self, offsetY, method)
                    self.InsertParagraph = origInsert
                    return newOffsetY, translatedObjective
                end
                return orig(self, offsetY, method)
            end
        end

        -- Chinese-only: suppress the English paragraph in dual-language renders
        if language == "chinese" and DUIQuestFrame then
            DUIQuestFrame.FormatDualParagraph = function(self, offsetY, _, chineseText, ...)
                return self:FormatParagraph(offsetY, chineseText, ...)
            end
        end
    end,
})
