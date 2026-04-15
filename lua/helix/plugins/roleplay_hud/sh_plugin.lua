--[[
 ________  ___  ___  ________   ________  ___  ___  ___     
|\   ____\|\  \|\  \|\   ___  \|\   ____\|\  \|\  \|\  \    
\ \  \___|\ \  \\\  \ \  \\ \  \ \  \___|\ \  \\\  \ \  \   
 \ \_____  \ \  \\\  \ \  \\ \  \ \_____  \ \   __  \ \  \  
  \|____|\  \ \  \\\  \ \  \\ \  \|____|\  \ \  \ \  \ \  \ 
    ____\_\  \ \_______\ \__\\ \__\____\_\  \ \__\ \__\ \__\
   |\_________\|_______|\|__| \|__|\_________\|__|\|__|\|__|
   \|_________|                   \|_________|              
]]--

local PLUGIN = PLUGIN

PLUGIN.name = "Roleplay HUD"
PLUGIN.author = "Sunshi"
PLUGIN.description = "Add roleplay hud (health , stamina, ammo ) ."
PLUGIN.requires = {}

ix.config.Add("basicHealthBar", false, "Replace the health bar by a simple one.", nil, {
    category = "Roleplay HUD"
})


if CLIENT then
  surface.CreateFont("Default:20", {
    font = "Arial",
    size = 20,
    weight = 800
  })  


HLXRPHUD_HungerMod = ix.plugin.list["hungermod"]
HLXRPHUD_HEART_ICON    = Material("hud/hearth.png")
HLXRPHUD_FOOD_ICON     = Material("hud/food.png")
HLXRPHUD_STAMINA_ICON  = Material("hud/stamina.png")
HLXRPHUD_AMMO_ICON     = Material("hud/ammo.png")
HLXRPHUD_STAR_ICON     = Material("hud/star.png")
HLXRPHUD_JAIL_ICON     = Material("hud/jail.png")
HLXRPHUD_XP_ICON       = Material("hud/xp.png")
HLXRPHUD_WantedTime = 0
HLXRPHUD_PoliceXP = 0
HLXRPHUD_PoliceNextLevel = 0
HLXRPHUD_JailTime = 0

function PLUGIN:ShouldHideBars() return true end
function PLUGIN:CanDrawAmmoHUD() return false end

    --[[VARIABLES]]--
local SmoothClipRatio   = 0
local SmoothAmplitude   = 0
local SmoothFrequency   = 0
local SmoothEndX        = nil
local SmoothWantedRatio = 0
local SmoothFood        = 0
local SmoothJail        = 0
local SmoothArmorRatio  = 0
local SmoothHealth = 0
local SmoothPoliceXP = 0
local lastHealth = nil
local policelevel = 1

    --[[Libs]]--
local function DrawRoundedOutlineAdjusted(x, y, w, h, radius, thickness, color)

    surface.SetDrawColor(color)

    surface.DrawRect(x + radius, y, w - 2 * radius, thickness) -- haut
    surface.DrawRect(x + radius, y + h - thickness + 1, w - 1.8 * radius, thickness) -- bas ajusté
    surface.DrawRect(x, y + radius, thickness, h - 1.8 * radius) -- gauche
    surface.DrawRect(x + w - thickness+1, y + radius, thickness, h - 2 * radius) -- droite

    local function DrawArc(cx, cy, r, startAng, endAng)
        local poly = {}
        table.insert(poly, { x = cx, y = cy })

        for i = startAng, endAng do
            local rad = math.rad(i)
            table.insert(poly, {
                x = cx + math.cos(rad) * r,
                y = cy + math.sin(rad) * r
            })
        end

        surface.DrawPoly(poly)
    end

    DrawArc(x + radius, y + radius, radius, 180, 270) -- haut gauche
    DrawArc(x + w - radius, y + radius, radius, 270, 360) -- haut droite
    DrawArc(x + w - radius, y + h - radius, radius, 0, 90) -- bas droite
    DrawArc(x + radius, y + h - radius, radius, 90, 180) -- bas gauche
end
local function DrawRoundedCorners(x, y, w, h, radius, color, segments)
    surface.SetDrawColor(color)
    segments = segments or 20

    local function DrawArc(cx, cy, r, startAng, endAng)
        local step = (endAng - startAng) / segments

        for i = 0, segments - 1 do
            local a1 = math.rad(startAng + step * i)
            local a2 = math.rad(startAng + step * (i + 1))

            surface.DrawLine(
                cx + math.cos(a1) * r,
                cy + math.sin(a1) * r,
                cx + math.cos(a2) * r,
                cy + math.sin(a2) * r
            )
        end
    end

    -- 4 coins
    DrawArc(x + radius, y + radius, radius, 180, 270) -- haut gauche
    DrawArc(x + w - radius, y + radius, radius, 270, 360) -- haut droite
    DrawArc(x + w - radius, y + h - radius, radius, 0, 90) -- bas droite
    DrawArc(x + radius, y + h - radius, radius, 90, 180) -- bas gauche
end

    --[[Main]]--

hook.Add("HUDPaint", "HLXRPHUD", function()
    HLXRPHUD_HUD_COLOR     = ix.config.Get("color")

    if IsValid(ix.gui.menu) && (ix.gui.menu.currentAlpha > 200)  then return end
    if IsValid(ix.gui.characterMenu) && (ix.gui.characterMenu.currentAlpha > 200)  then return end
    

    local scrW, scrH = ScrW(), ScrH()
    local function ScaleW(px) return scrW * (px / 1920) end
    local function ScaleH(px) return scrH * (px / 1080) end
    local hudX       = ScaleW(20)
    local hudY       = ScaleH(875)
    local hudWidth   = ScaleW(250)
    local hudHeight  = ScaleH(40)
    local iconSize   = ScaleH(20)
    local barSpacing = ScaleW(5)

    local ply  = LocalPlayer()
    local char = ply:GetCharacter()
    if not char then return end

    local health        = ply:Health()
    local armor         = math.Clamp(ply:Armor() or 0, 0, 100)
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
        SmoothClipRatio = math.Clamp(  Lerp(10 * FrameTime(), SmoothClipRatio, clipRatio) , 0 , 1)
    end


local function DrawHealthBox(x, y, w, h, value, armor)


        draw.RoundedBox(8,x, y, w, h,Color(15, 15, 15, 100))

        if armor > 0 then
            SmoothArmorRatio = Lerp(10 * FrameTime(), SmoothArmorRatio, math.Clamp(armor / 100, 0, 1))
            draw.RoundedBox(8, x, y, w * SmoothArmorRatio, h, Color(HLXRPHUD_HUD_COLOR.r * 0.7, HLXRPHUD_HUD_COLOR.g * 0.7, HLXRPHUD_HUD_COLOR.b * 0.7, HLXRPHUD_HUD_COLOR.a))
        else
            SmoothArmorRatio = Lerp(10 * FrameTime(), SmoothArmorRatio, 0)
        end

        surface.SetDrawColor(255, 255, 255)
        surface.SetMaterial(HLXRPHUD_HEART_ICON)
        surface.DrawTexturedRect(x + ScaleW(15), y + ScaleH(10), iconSize, iconSize)

        
        local amplitude = 0
        local frequency = 0
        local time      = CurTime() * -5

        if health ~= lastHealth then
            SmoothAmplitude = (50 * (lastHealth - health) / 100) + amplitude
            SmoothFrequency = (lastHealth - health) / 100
            lastHealth = health 
        end

        SmoothAmplitude = Lerp(0.05, SmoothAmplitude, amplitude)
        SmoothFrequency = Lerp(0.05, SmoothFrequency, frequency)

        local yOffset   = y + ScaleH(19)
        local startX    = x + ScaleW(50)
        local maxLength = w - ScaleW(72)

        SmoothEndX = SmoothEndX or startX
        local targetEndX = startX + maxLength * (value / 100)
        SmoothEndX = Lerp(5 * FrameTime(), SmoothEndX, targetEndX)

        local thickness = 0.5 

        local lastX, lastY = startX, yOffset + math.sin(startX * SmoothFrequency + time) * SmoothAmplitude
        surface.SetDrawColor(100, 100, 100)
        surface.DrawLine(lastX, lastY, ScaleW(245), lastY)
        surface.SetDrawColor(255, 255, 255)

        for px = startX, math.floor(SmoothEndX) do
            local py = yOffset + math.sin(px * SmoothFrequency + time) * SmoothAmplitude

            for i = -thickness, thickness do
                surface.DrawLine(lastX, lastY + i, px, py + i)
            end

            lastX, lastY = px, py
        end




        DrawRoundedCorners(x, y, w, h, 8, HLXRPHUD_HUD_COLOR, 30)
        DrawRoundedOutlineAdjusted(x, y, w, h, 8, 1, HLXRPHUD_HUD_COLOR, -1)

end

local function DrawSimpleHealh(x, y, w, h, value, iconMat)
        draw.RoundedBox(8,x, y, w, h,Color(15, 15, 15, 100))

        surface.SetDrawColor(255, 255, 255)
        surface.SetMaterial(iconMat)
        surface.DrawTexturedRect(x + ScaleW(15), y + ScaleH(10), iconSize, iconSize)

        surface.SetDrawColor(150, 150, 150,200)
        surface.DrawRect(x+w*0.2, y+h*0.45, (w*0.7) , h*0.1)
        surface.SetDrawColor(255, 255, 255)
        surface.DrawRect(x+w*0.2, y+h*0.45, (w*0.7) * (value / 100), h*0.1)

        DrawRoundedCorners(x, y, w, h, 8, HLXRPHUD_HUD_COLOR, 30)
        DrawRoundedOutlineAdjusted(x, y, w, h, 8, 1, HLXRPHUD_HUD_COLOR, -1)
end

local function DrawMiniBox(x, y, w, h, value, iconMat)
        draw.RoundedBox(8,x, y, w, h,Color(15, 15, 15, 100))

        surface.SetDrawColor(255, 255, 255)
        surface.SetMaterial(iconMat)
        surface.DrawTexturedRect(x + ScaleW(15), y + ScaleH(10), iconSize, iconSize)

        surface.SetDrawColor(150, 150, 150,200)
        surface.DrawRect(x+w*0.4, y+h*0.45, (w*0.4) , h*0.1)
        surface.SetDrawColor(255, 255, 255)
        surface.DrawRect(x+w*0.4, y+h*0.45, (w*0.4) * (value / 100), h*0.1)

        DrawRoundedCorners(x, y, w, h, 8, HLXRPHUD_HUD_COLOR, 30)
        DrawRoundedOutlineAdjusted(x, y, w, h, 8, 1, HLXRPHUD_HUD_COLOR, -1)
end

local function DrawLargeBox(x, y, w, h, value, iconMat)
        draw.RoundedBox(8,x, y, w, h,Color(15, 15, 15, 100))

        surface.SetDrawColor(255, 255, 255)
        surface.SetMaterial(iconMat)
        surface.DrawTexturedRect(x + ScaleW(15), y + ScaleH(10), iconSize, iconSize)

        surface.SetDrawColor(150, 150, 150,200)
        surface.DrawRect(x+w*0.2, y+h*0.45, (w*0.7) , h*0.1)
        surface.SetDrawColor(255, 255, 255)
        surface.DrawRect(x+w*0.2, y+h*0.45, (w*0.7) * (value / 100), h*0.1)

        DrawRoundedCorners(x, y, w, h, 8, HLXRPHUD_HUD_COLOR, 30)
        DrawRoundedOutlineAdjusted(x, y, w, h, 8, 1, HLXRPHUD_HUD_COLOR, -1)
end

local function DrawCharacterName(x, y, w, h)
        draw.RoundedBox(8,x, y, w, h,Color(15, 15, 15, 100))
        surface.SetFont("Default:20")
        surface.SetDrawColor(15, 15, 15, 75)
        surface.DrawRect(x, y, w, h)

        local nameW, nameH = surface.GetTextSize(characterName)
        surface.SetTextColor(255, 255, 255)
        surface.SetTextPos(x + (w / 2) - (nameW / 2), y + (h / 2) - (nameH / 2))
        surface.DrawText(characterName)

        DrawRoundedCorners(x, y, w, h, 8, HLXRPHUD_HUD_COLOR, 30)
        DrawRoundedOutlineAdjusted(x, y, w, h, 8, 1, HLXRPHUD_HUD_COLOR, -1)
end


local function DrawAmmo(x, y, w, h)
        draw.RoundedBox(8,x, y, w, h,Color(15, 15, 15, 100))
        local ammoText = weaponAmmo .. "/" .. reserveAmmo
        surface.SetFont("Default:20")
        surface.SetDrawColor(15, 15, 15, 75)
        surface.DrawRect(x, y, w, h)

        draw.RoundedBox(8,x, y, w * SmoothClipRatio, h,Color(HLXRPHUD_HUD_COLOR.r * 0.7, HLXRPHUD_HUD_COLOR.g * 0.7, HLXRPHUD_HUD_COLOR.b * 0.7, HLXRPHUD_HUD_COLOR.a))

        DrawRoundedCorners(x, y, w, h, 8, HLXRPHUD_HUD_COLOR, 30)
        DrawRoundedOutlineAdjusted(x, y, w, h, 8, 1, HLXRPHUD_HUD_COLOR, -1)

        surface.SetDrawColor(255, 255, 255)
        surface.SetMaterial(HLXRPHUD_AMMO_ICON)
        surface.DrawTexturedRect(x + ScaleW(15), y + ScaleH(10), iconSize, iconSize)

        local textW, textH = surface.GetTextSize(ammoText)
        local textX, textY = x + (w / 2) - (textW / 2), y + (h / 2) - (textH / 2)
        surface.SetTextColor(255, 255, 255)
        surface.SetTextPos(textX, textY)
        surface.DrawText(ammoText)

end

local function DrawWanted(x, y, w, h)
        local starCount = HLXRPHUD_WantedLevel
        local spacing   = ScaleW(25)
        local totalStarsWidth = (starCount * iconSize) + ((starCount - 1) * spacing)
        local startX    = x + (w / 2) - (totalStarsWidth / 2)
        local startY    = y + (h / 2) - (iconSize / 2)
        local timeLeft  = math.max(HLXRPHUD_WantedTime - CurTime(), 0)

        draw.RoundedBox(8,x, y, w, h,Color(15, 15, 15, 100))

        surface.SetDrawColor(15, 15, 15, 75)
        surface.DrawRect(x, y, w, h)

        local ratio = math.Clamp(timeLeft / HLXRPHUD_TotalWantedTime, 0, 1)
        SmoothWantedRatio = Lerp(5 * FrameTime(), SmoothWantedRatio, ratio)
        draw.RoundedBox(8,x, y, w * SmoothWantedRatio, h,Color(HLXRPHUD_HUD_COLOR.r * 0.7, HLXRPHUD_HUD_COLOR.g * 0.7, HLXRPHUD_HUD_COLOR.b * 0.7, HLXRPHUD_HUD_COLOR.a))

        surface.SetMaterial(HLXRPHUD_STAR_ICON)
        surface.SetDrawColor(255, 255, 255)
        for i = 0, starCount - 1 do
            surface.DrawTexturedRect(startX + i * (iconSize + spacing), startY, iconSize, iconSize)
        end

        DrawRoundedCorners(x, y, w, h, 8, HLXRPHUD_HUD_COLOR, 30)
        DrawRoundedOutlineAdjusted(x, y, w, h, 8, 1, HLXRPHUD_HUD_COLOR, -1)
end


local function DrawJail(x, y, w, h)
        surface.SetFont("Default:20")

        draw.RoundedBox(8,x, y, w, h,Color(15, 15, 15, 100))

        local timeLeft = math.max(HLXRPHUD_JailTime - CurTime(), 0)
        local textW, textH = surface.GetTextSize("00:00")
        local textX, textY = x + (w / 2) - (textW / 2), y + (h / 2) - (textH / 2)

        surface.SetDrawColor(15, 15, 15, 75)
        surface.DrawRect(x, y, w, h)



        local ratio = math.Clamp(timeLeft / HLXRPHUD_TotalJailTime, 0, 1)
        SmoothJail = Lerp(10 * FrameTime(), SmoothJail, ratio)
        draw.RoundedBox(8,x, y, w * SmoothJail, h,Color(HLXRPHUD_HUD_COLOR.r * 0.7, HLXRPHUD_HUD_COLOR.g * 0.7, HLXRPHUD_HUD_COLOR.b * 0.7, HLXRPHUD_HUD_COLOR.a))

        surface.SetTextColor(255, 255, 255)
        surface.SetTextPos(textX, textY)
        surface.DrawText(string.ToMinutesSeconds(timeLeft))

        surface.SetDrawColor(255, 255, 255)
        surface.SetMaterial(HLXRPHUD_JAIL_ICON)
        surface.DrawTexturedRect(x + ScaleW(15), y + ScaleH(10), iconSize, iconSize)

        DrawRoundedCorners(x, y, w, h, 8, HLXRPHUD_HUD_COLOR, 30)
        DrawRoundedOutlineAdjusted(x, y, w, h, 8, 1, HLXRPHUD_HUD_COLOR, -1)


end

local function DrawPoliceXP(x, y, w, h)
        local policexp = HLXRPHUD_PoliceXP
        local currentlevel = HLXRPHUD_PoliceNextLevel-1 or 0
        local currentlevelxp = Police_Level[HLXRPHUD_PoliceNextLevel-1] or 0

        local nextlevel = HLXRPHUD_PoliceNextLevel
        local nextlevelxp = Police_Level[HLXRPHUD_PoliceNextLevel]

        local ratioxp = policexp - currentlevelxp / nextlevelxp - currentlevelxp

        SmoothPoliceXP = Lerp(5 * FrameTime(), SmoothPoliceXP, policexp)
        if math.Round(SmoothPoliceXP,7) >= (Police_Level[policelevel] or 0) then policelevel = HLXRPHUD_PoliceNextLevel end
        local SmoothVar = (SmoothPoliceXP - (Police_Level[policelevel-1] or 0)) / ((Police_Level[policelevel] or 1) - (Police_Level[policelevel-1] or 0))
        SmoothVar = math.Clamp(SmoothVar, 0, 1)

        surface.SetDrawColor(15, 15, 15, 75)
        surface.DrawRect(x, y, w, h)

        draw.RoundedBox(8,x, y, w * SmoothVar, h,Color(HLXRPHUD_HUD_COLOR.r * 0.7, HLXRPHUD_HUD_COLOR.g * 0.7, HLXRPHUD_HUD_COLOR.b * 0.7, HLXRPHUD_HUD_COLOR.a))

        surface.SetDrawColor(255, 255, 255)
        surface.SetMaterial(HLXRPHUD_XP_ICON)
        surface.DrawTexturedRect(x + ScaleW(15), y + ScaleH(10), iconSize, iconSize)

        DrawRoundedCorners(x, y, w, h, 8, HLXRPHUD_HUD_COLOR, 30)
        DrawRoundedOutlineAdjusted(x, y, w, h, 8, 1, HLXRPHUD_HUD_COLOR, -1)
        
        if math.Round(SmoothPoliceXP,7) == math.Round(policexp,7) then HLXRPHUD_ShowPoliceXP = false end

end 


local wantedTimeLeft = math.max(HLXRPHUD_WantedTime - CurTime(), 0)
    local jailTimeLeft   = math.max(HLXRPHUD_JailTime - CurTime(), 0)
    SmoothFood = Lerp(10 * FrameTime(), SmoothFood, food)
    SmoothHealth = Lerp(10 * FrameTime(), SmoothHealth, health)
    if !ix.config.Get("basicHealthBar") then
    DrawHealthBox(hudX, hudY, hudWidth, hudHeight, health, armor)
    else
    DrawSimpleHealh(hudX , hudY, hudWidth , hudHeight, SmoothHealth, HLXRPHUD_HEART_ICON)
    end

    if HLXRPHUD_HungerMod then 
    DrawMiniBox(hudX, hudY + ScaleH(50), hudWidth / 2 - barSpacing, hudHeight, SmoothFood, HLXRPHUD_FOOD_ICON)
    DrawMiniBox(hudX + hudWidth / 2 + barSpacing, hudY + ScaleH(50), hudWidth / 2 - barSpacing, hudHeight, stamina, HLXRPHUD_STAMINA_ICON)
    else
    DrawLargeBox(hudX , hudY + ScaleH(50), hudWidth , hudHeight, stamina, HLXRPHUD_STAMINA_ICON)
    end

    if HLXRPHUD_ShowPoliceXP == true then 
    DrawPoliceXP(hudX, ScaleH(975), hudWidth, hudHeight)
       return
    else
    SmoothPoliceXP = HLXRPHUD_PoliceXP
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
