-- Ana Çeviri Fonksiyonu
local function TranslateUnitName(originalName)
    if not originalName or not MobNpcTranslator_Data then return originalName; end
    
    if MobNpcTranslator_Data[originalName] then
        return MobNpcTranslator_Data[originalName]
    end
    return originalName
end

-- [TÜRKÇE KARAKTER FIX] Yazı nesnesine güvenli ve Türkçe destekli font nesnesini basar
local function ApplySafeFont(fontStringObject, size)
    if not fontStringObject then return end
    
    -- Harici font dosyası yüklemek yerine, oyunun kendi içindeki 
    -- en geniş karakter kümesine sahip (Chat/System) font şablonunu referans alıyoruz.
    if ChatFontNormal and fontStringObject.SetFont then
        local fontPath, _, fontFlags = ChatFontNormal:GetFont()
        if fontPath then
            fontStringObject:SetFont(fontPath, size or 13, fontFlags)
            return true
        end
    end
    
    -- Alternatif Fallback (Eğer üstteki başarısız olursa oyun standartına sadık kal)
    if GameFontNormal and fontStringObject.SetFontObject then
        fontStringObject:SetFontObject(GameFontNormal)
    end
    return false
end

-- [AKILLI BÖLGE TARAYICISI] Nesne ismi ne olursa olsun ekranda mob adını basan FontString'i bulur
local function FindNameObject(frame, nameToFind)
    if not frame then return nil end
    
    -- 1. Kademe: Çerçevenin kendi yazı elementlerini (Regions) tara
    if frame.GetRegions then
        local regions = { frame:GetRegions() }
        for i = 1, table.getn(regions) do
            local r = regions[i]
            if r and r.GetText and r:GetText() == nameToFind then
                return r
            end
        end
    end
    
    -- 2. Kademe: Eğer özel bir addon alt kırılıma gizlediyse pencereleri (Children) tara
    if frame.GetChildren then
        local children = { frame:GetChildren() }
        for i = 1, table.getn(children) do
            local c = children[i]
            local found = FindNameObject(c, nameToFind)
            if found then return found end
        end
    end
    
    return nil
end

-- Çeviri Gövdesi
local function DoTargetTranslation()
    if UnitExists("target") then
        local rawName = UnitName("target")
        if rawName then
            -- Öncelik: Standart Blizzard arayüz ismini kontrol et
            local nameFrame = getglobal("TargetFrameName")
            
            -- Eğer bulunamadıysa, TargetFrame içindeki yazıyı dinamik olarak avla
            if not nameFrame then
                local baseFrame = getglobal("TargetFrame")
                if baseFrame then
                    nameFrame = FindNameObject(baseFrame, rawName)
                end
            end
            
            -- Yazı nesnesi yakalandıysa Türkçe karakter ayarını yapıp ismi basıyoruz
            if nameFrame and nameFrame.SetText then
                ApplySafeFont(nameFrame, 13) -- Karakter fix uygulandı
                nameFrame:SetText(TranslateUnitName(rawName))
            end
        end
    end
end

-- Oyunun kendi ismini basmasını bekleyen mikro zamanlayıcı
local function TriggerDelayedTranslation()
    local delayFrame = CreateFrame("Frame")
    delayFrame.t = 0
    delayFrame:SetScript("OnUpdate", function()
        this.t = this.t + arg1
        if this.t >= 0.01 then
            this:SetScript("OnUpdate", nil)
            DoTargetTranslation()
        end
    end)
end

-- ====================================================================
-- EVENT DİNLEYİCİLERİ
-- ====================================================================
local MNT_Frame = CreateFrame("Frame")
MNT_Frame:RegisterEvent("PLAYER_ENTERING_WORLD")
MNT_Frame:RegisterEvent("PLAYER_TARGET_CHANGED")
MNT_Frame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
MNT_Frame:RegisterEvent("GOSSIP_SHOW")
MNT_Frame:RegisterEvent("QUEST_GREETING")
MNT_Frame:RegisterEvent("QUEST_DETAIL")
MNT_Frame:RegisterEvent("QUEST_PROGRESS")
MNT_Frame:RegisterEvent("QUEST_COMPLETE")

MNT_Frame:SetScript("OnEvent", function()
    if event == "PLAYER_ENTERING_WORLD" then
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[MobNpcTranslator] Türkçe Karakter Desteği Aktif Edildi!|r")
        end
    elseif event == "PLAYER_TARGET_CHANGED" then
        TriggerDelayedTranslation()
    elseif event == "UPDATE_MOUSEOVER_UNIT" then
        if UnitExists("mouseover") and GameTooltipTextLeft1 then
            local rawName = UnitName("mouseover")
            if rawName then
                local trName = TranslateUnitName(rawName)
                if GameTooltipTextLeft1:GetText() ~= trName then
                    ApplySafeFont(GameTooltipTextLeft1, 14) -- Karakter fix uygulandı
                    GameTooltipTextLeft1:SetText(trName)
                    GameTooltip:Show()
                end
            end
        end
    else
        local npcName = UnitName("npc") or UnitName("target")
        if npcName then
            local trName = TranslateUnitName(npcName)
            if event == "GOSSIP_SHOW" and GossipFrameNpcNameText then
                ApplySafeFont(GossipFrameNpcNameText, 16) -- Karakter fix uygulandı
                GossipFrameNpcNameText:SetText(trName)
            elseif (event == "QUEST_GREETING" or event == "QUEST_DETAIL" or event == "QUEST_PROGRESS" or event == "QUEST_COMPLETE") and QuestFrameNpcNameText then
                ApplySafeFont(QuestFrameNpcNameText, 16) -- Karakter fix uygulandı
                QuestFrameNpcNameText:SetText(trName)
            end
        end
    end
end)