local _, ns = ...

local POPUP_KEY = "DUICN_RELOAD"

local OPTION_LABELS = {
    english = "English Only — original behavior, no Chinese text",
    dual    = "Dual Language — show English + Chinese side by side (default)",
    chinese = "Chinese Only — hide English text",
}

local function SetupReloadPopup()
    StaticPopupDialogs[POPUP_KEY] = {
        text         = "Reload UI to apply changes?",
        button1      = "Reload Now",
        button2      = "Later",
        OnAccept     = ReloadUI,
        timeout      = 0,
        whileDead    = true,
        hideOnEscape = true,
    }
end

function ns.CreateOptionsPanel()
    SetupReloadPopup()

    local panel = CreateFrame("Frame")
    panel.name = "Chinese Quest Translations"

    local header = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", 16, -16)
    header:SetText("Chinese Quest Translations")

    local subtext = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subtext:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -6)
    subtext:SetText("Configure per-integration language display options.")

    local cursor = subtext
    local cursorOffsetY = -24

    for _, integration in ipairs(ns.GetIntegrations()) do
        local isLoaded = integration.addonDependency == nil or C_AddOns.IsAddOnLoaded(integration.addonDependency)
        local current  = ns.GetIntegrationLanguage(integration.id, integration.defaultLanguage)

        -- Section label
        local sectionLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        sectionLabel:SetPoint("TOPLEFT", cursor, "BOTTOMLEFT", 0, cursorOffsetY)
        sectionLabel:SetText(integration.label)
        if not isLoaded then
            sectionLabel:SetTextColor(0.5, 0.5, 0.5)
        end
        cursor = sectionLabel
        cursorOffsetY = -10

        -- Not installed notice
        if not isLoaded then
            local notice = panel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
            notice:SetPoint("TOPLEFT", cursor, "BOTTOMLEFT", 12, cursorOffsetY)
            notice:SetText((integration.addonDependency or "addon") .. " is not installed or enabled.")
            cursor = notice
            cursorOffsetY = -20
        end

        -- Radio buttons
        local radios = {}
        local firstRadio = true
        for _, option in ipairs(integration.options) do
            local radio = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
            local xIndent = firstRadio and 12 or 0
            radio:SetPoint("TOPLEFT", cursor, "BOTTOMLEFT", xIndent, cursorOffsetY)
            radio.text:SetText(OPTION_LABELS[option] or option)
            radio:SetChecked(current == option)
            radio.optionKey = option

            if not isLoaded then
                radio:Disable()
                radio.text:SetTextColor(0.5, 0.5, 0.5)
            end

            radios[#radios + 1] = radio
            cursor = radio
            cursorOffsetY = -6
            firstRadio = false
        end

        -- Enforce single-select within this group
        for _, radio in ipairs(radios) do
            radio:SetScript("OnClick", function(self)
                if not isLoaded then self:SetChecked(false) return end
                for _, r in ipairs(radios) do r:SetChecked(r == self) end
            end)
        end

        -- Confirm button
        local confirm = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        confirm:SetSize(100, 26)
        confirm:SetPoint("TOPLEFT", cursor, "BOTTOMLEFT", 0, -14)
        confirm:SetText("Confirm")
        if not isLoaded then confirm:Disable() end

        local integrationID = integration.id
        confirm:SetScript("OnClick", function()
            local chosen = integration.defaultLanguage
            for _, radio in ipairs(radios) do
                if radio:GetChecked() then chosen = radio.optionKey end
            end
            ns.SetIntegrationLanguage(integrationID, chosen)
            StaticPopup_Show(POPUP_KEY)
        end)

        cursor = confirm
        cursorOffsetY = -28
    end

    local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
    Settings.RegisterAddOnCategory(category)
end
