if CLIENT then

  surface.CreateFont("Default:20", {
    font = "Arial",
    size = 20,
    weight = 800
  })  
-- ==========================
-- CONFIG & CONSTANTES
-- ==========================
local HUD_COLOR     = ix.config.Get("color")
local HEART_ICON    = Material("hud/hearth.png")
local FOOD_ICON     = Material("hud/food.png")
local STAMINA_ICON  = Material("hud/stamina.png")
local AMMO_ICON     = Material("hud/ammo.png")
local STAR_ICON     = Material("hud/star.png")
local JAIL_ICON     = Material("hud/jail.png")

-- ==========================
-- VARIABLES TEMPORAIRES
-- ==========================
local SmoothClipRatio   = 0
local SmoothAmplitude   = 0
local SmoothFrequency   = 0
local SmoothEndX        = nil
local SmoothWantedRatio = 0
local SmoothFood        = 0
local SmoothJail        = 0
local SmoothHealth = 0
local lastHealth = nil -- valeur précédente

HLXRPHUD_WantedTime = HLXRPHUD_WantedTime or 0
HLXRPHUD_TotalWantedTime = HLXRPHUD_TotalWantedTime or 0
HLXRPHUD_WantedLevel = HLXRPHUD_WantedLevel or 0
HLXRPHUD_JailTime = HLXRPHUD_JailTime or 0
HLXRPHUD_TotalJailTime = HLXRPHUD_TotalJailTime or 0

local hungermod = ix.plugin.list["hungermod"]

-- ==========================
-- HOOK HUD
-- ==========================
hook.Add("HUDPaint", "HLXRPHUD", function()

    local scrW, scrH = ScrW(), ScrH()
    -- Fonctions utilitaires de mise à l’échelle
    local function ScaleW(px) return scrW * (px / 1920) end
    local function ScaleH(px) return scrH * (px / 1080) end

    -- Positions & tailles principales
    local hudX       = ScaleW(20)
    local hudY       = ScaleH(875)
    local hudWidth   = ScaleW(250)
    local hudHeight  = ScaleH(40)
    local iconSize   = ScaleH(20)
    local barSpacing = ScaleW(5)

    -- ==========================
    -- DONNÉES JOUEUR
    -- ==========================
    local ply  = LocalPlayer()
    local char = ply:GetCharacter()
    if not char then return end

    local health        = ply:Health()
    local food          = char:GetData("food", 0)
    local stamina       = (ix.bar.list[3]["GetValue"]() or 0) * 100
    local characterName = char:GetName()
    local energy = char:GetData("energy", 0)

    if lastHealth == nil then
       lastHealth = health
    end

    local activeWeapon  = ply:GetActiveWeapon()
    local weaponAmmo, reserveAmmo, maxClipSize = 0, 0, 0

    if IsValid(activeWeapon) then
        weaponAmmo  = activeWeapon:Clip1() or 0
        reserveAmmo = ply:GetAmmoCount(activeWeapon:GetPrimaryAmmoType())
        maxClipSize = activeWeapon:GetMaxClip1()

        local clipRatio = (maxClipSize > 0) and (weaponAmmo / maxClipSize) or 0
        SmoothClipRatio = Lerp(10 * FrameTime(), SmoothClipRatio, clipRatio)
    end

    -- ==========================
    -- FONCTIONS DE DESSIN
    -- ==========================
    local function DrawHealthBox(x, y, w, h, value)
        -- Fond
        surface.SetDrawColor(15, 15, 15, 255)
        surface.DrawRect(x, y, w, h)

        -- Icône cœur
        surface.SetDrawColor(255, 255, 255)
        surface.SetMaterial(HEART_ICON)
        surface.DrawTexturedRect(x + ScaleW(15), y + ScaleH(10), iconSize, iconSize)

        local amplitude = 1
        local frequency = 0.15
        local time      = CurTime() * -5

        if ply:IsSprinting() then
          amplitude = amplitude +1
        end
        if energy > 0 then
          amplitude = amplitude +1.5
          time      = CurTime() * -7.5
        end


        if health ~= lastHealth then
            SmoothAmplitude = (50*(lastHealth - health)/100 )+ amplitude
            SmoothFrequency = (lastHealth - health)/100
            lastHealth = health -- mise à jour
        end


        SmoothAmplitude = Lerp(0.05, SmoothAmplitude, amplitude)
        SmoothFrequency = Lerp(0.05, SmoothFrequency, frequency)
        
        local yOffset   = y + ScaleH(20)
        local startX    = x + ScaleW(55)
        local maxLength = w - ScaleW(80)

        SmoothEndX = SmoothEndX or startX
        local targetEndX = startX + maxLength * (value / 100)
        SmoothEndX = Lerp(5 * FrameTime(), SmoothEndX, targetEndX)

        local lastX, lastY = startX, yOffset + math.sin(startX * SmoothFrequency + time) * SmoothAmplitude
        surface.SetDrawColor(255, 255, 255)
        for px = startX, math.floor(SmoothEndX) do
            local py = yOffset + math.sin(px * SmoothFrequency + time) * SmoothAmplitude
            surface.DrawLine(lastX, lastY, px, py+1)
            lastX, lastY = px, py
        end

        -- Contour
        surface.SetDrawColor(14, 14, 14, 255)
        surface.DrawOutlinedRect(x, y, w, h, 3)
    end

    local function DrawMiniBox(x, y, w, h, value, iconMat)
        surface.SetDrawColor(15, 15, 15, 255)
        surface.DrawRect(x, y, w, h)

        -- Icône
        surface.SetDrawColor(255, 255, 255)
        surface.SetMaterial(iconMat)
        surface.DrawTexturedRect(x + ScaleW(15), y + ScaleH(10), iconSize, iconSize)

        -- Barre
        surface.SetDrawColor(255, 255, 255)
        surface.DrawRect(x, y, w * (value / 100), h)

        -- Clipping pour l’effet inverse
        local clipX2 = x + (w * (value / 100))
        render.SetScissorRect(x, y, clipX2, y + h, true)
        surface.SetDrawColor(15, 15, 15)
        surface.SetMaterial(iconMat)
        surface.DrawTexturedRect(x + ScaleW(15), y + ScaleH(10), iconSize, iconSize)
        render.SetScissorRect(0, 0, 0, 0, false)

        -- Contour
        surface.SetDrawColor(14, 14, 14, 255)
        surface.DrawOutlinedRect(x, y, w, h, 3)
    end

    local function DrawCharacterName(x, y, w, h)
        surface.SetFont("Default:20")
        surface.SetDrawColor(15, 15, 15, 255)
        surface.DrawRect(x, y, w, h)

        local nameW, nameH = surface.GetTextSize(characterName)
        surface.SetTextColor(255, 255, 255)
        surface.SetTextPos(x + (w / 2) - (nameW / 2), y + (h / 2) - (nameH / 2))
        surface.DrawText(characterName)

        surface.SetDrawColor(14, 14, 14, 255)
        surface.DrawOutlinedRect(x, y, w, h, 3)
    end

    local function DrawAmmo(x, y, w, h)
        local ammoText = weaponAmmo .. "/" .. reserveAmmo
        surface.SetFont("Default:20")
        surface.SetDrawColor(15, 15, 15, 255)
        surface.DrawRect(x, y, w, h)

        -- Icône
        surface.SetDrawColor(255, 255, 255)
        surface.SetMaterial(AMMO_ICON)
        surface.DrawTexturedRect(x + ScaleW(15), y + ScaleH(10), iconSize, iconSize)

        -- Barre
        surface.SetDrawColor(255, 255, 255)
        surface.DrawRect(x, y, w * SmoothClipRatio, h)

        -- Contour
        surface.SetDrawColor(14, 14, 14, 255)
        surface.DrawOutlinedRect(x, y, w, h, 3)

        -- Texte
        local textW, textH = surface.GetTextSize(ammoText)
        local textX, textY = x + (w / 2) - (textW / 2), y + (h / 2) - (textH / 2)
        surface.SetTextColor(255, 255, 255)
        surface.SetTextPos(textX, textY)
        surface.DrawText(ammoText)

        -- Clipping inverse
        local clipX2 = x + (w * SmoothClipRatio)
        render.SetScissorRect(x, y, clipX2, y + h, true)
        surface.SetTextColor(15, 15, 15)
        surface.SetTextPos(textX, textY)
        surface.DrawText(ammoText)
        surface.SetMaterial(AMMO_ICON)
        surface.DrawTexturedRect(x + ScaleW(15), y + ScaleH(10), iconSize, iconSize)
        render.SetScissorRect(0, 0, 0, 0, false)
    end

    local function DrawWanted(x, y, w, h)
        local starCount = HLXRPHUD_WantedLevel
        local spacing   = ScaleW(25)
        local totalStarsWidth = (starCount * iconSize) + ((starCount - 1) * spacing)
        local startX    = x + (w / 2) - (totalStarsWidth / 2)
        local startY    = y + (h / 2) - (iconSize / 2)
        local timeLeft  = math.max(HLXRPHUD_WantedTime - CurTime(), 0)

        surface.SetDrawColor(15, 15, 15, 255)
        surface.DrawRect(x, y, w, h)

        surface.SetMaterial(STAR_ICON)
        surface.SetDrawColor(255, 255, 255)
        for i = 0, starCount - 1 do
            surface.DrawTexturedRect(startX + i * (iconSize + spacing), startY, iconSize, iconSize)
        end

        local ratio = math.Clamp(timeLeft / HLXRPHUD_TotalWantedTime, 0, 1)
        SmoothWantedRatio = Lerp(5 * FrameTime(), SmoothWantedRatio, ratio)
        surface.DrawRect(x, y, w * SmoothWantedRatio, h)

        surface.SetDrawColor(14, 14, 14)
        surface.DrawOutlinedRect(x, y, w, h, 3)

        -- Clipping inverse
        local clipX2 = x + (w * SmoothWantedRatio)
        render.SetScissorRect(x, y, clipX2, y + h, true)
        surface.SetDrawColor(15, 15, 15)
        for i = 0, starCount - 1 do
            surface.DrawTexturedRect(startX + i * (iconSize + spacing), startY, iconSize, iconSize)
        end
        render.SetScissorRect(0, 0, 0, 0, false)
    end

    local function DrawJail(x, y, w, h)
        local timeLeft = math.max(HLXRPHUD_JailTime - CurTime(), 0)
        local textW, textH = surface.GetTextSize("00:00")
        local textX, textY = x + (w / 2) - (textW / 2), y + (h / 2) - (textH / 2)
        surface.SetFont("Default:20")

        surface.SetDrawColor(15, 15, 15, 255)
        surface.DrawRect(x, y, w, h)

        -- Icône
        surface.SetDrawColor(255, 255, 255)
        surface.SetMaterial(JAIL_ICON)
        surface.DrawTexturedRect(x + ScaleW(15), y + ScaleH(10), iconSize, iconSize)

        -- Barre
        local ratio = math.Clamp(timeLeft / HLXRPHUD_TotalJailTime, 0, 1)
        SmoothJail = Lerp(10 * FrameTime(), SmoothJail, ratio)
        surface.SetDrawColor(255, 255, 255)
        surface.DrawRect(x, y, w * SmoothJail, h)

        -- Texte
        surface.SetTextColor(255, 255, 255)
        surface.SetTextPos(textX, textY)
        surface.DrawText(string.ToMinutesSeconds(timeLeft))

        -- Contour
        surface.SetDrawColor(14, 14, 14, 255)
        surface.DrawOutlinedRect(x, y, w, h, 3)

        -- Clipping inverse
        local clipX2 = x + (w * SmoothJail)

        render.SetScissorRect(x, y, clipX2, y + h, true)
        surface.SetTextColor(15, 15, 15)
        surface.SetTextPos(textX, textY)
        surface.DrawText(string.ToMinutesSeconds(timeLeft))
        surface.SetMaterial(JAIL_ICON)
        surface.DrawTexturedRect(x + ScaleW(15), y + ScaleH(10), iconSize, iconSize)
        render.SetScissorRect(0, 0, 0, 0, false)
    end

    -- ==========================
    -- DESSIN FINAL
    -- ==========================
    local wantedTimeLeft = math.max(HLXRPHUD_WantedTime - CurTime(), 0)
    local jailTimeLeft   = math.max(HLXRPHUD_JailTime - CurTime(), 0)
    SmoothFood = Lerp(10 * FrameTime(), SmoothFood, food)
    SmoothHealth = Lerp(10 * FrameTime(), SmoothHealth, health)
    if !ix.config.Get("basicHealthBar") then
    DrawHealthBox(hudX, hudY, hudWidth, hudHeight, health)
    else
    DrawMiniBox(hudX , hudY, hudWidth , hudHeight, SmoothHealth, HEART_ICON)
    end

    if hungermod then 
    DrawMiniBox(hudX, hudY + ScaleH(50), hudWidth / 2 - barSpacing, hudHeight, SmoothFood, FOOD_ICON)
    DrawMiniBox(hudX + hudWidth / 2 + barSpacing, hudY + ScaleH(50), hudWidth / 2 - barSpacing, hudHeight, stamina, STAMINA_ICON)
    else
    DrawMiniBox(hudX , hudY + ScaleH(50), hudWidth , hudHeight, stamina, STAMINA_ICON)
    end
    if jailTimeLeft > 0 then
        DrawJail(hudX, ScaleH(975), hudWidth, hudHeight)
        return
    end

    if weaponAmmo >= 0 then
        DrawAmmo(hudX, ScaleH(975), hudWidth, hudHeight)
        return
    end

    if wantedTimeLeft > 0 then
        DrawWanted(hudX, ScaleH(975), hudWidth, hudHeight)
        return
    end

    DrawCharacterName(hudX, ScaleH(975), hudWidth, hudHeight)

end)

end
