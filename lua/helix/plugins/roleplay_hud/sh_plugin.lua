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
PLUGIN.description = "Add roleplay hud (health , stamina, food , ammo , wanted, jail ) ."
PLUGIN.requires = {}

ix.config.Add("basicHealthBar", false, "Replace the health bar by a simple one.", nil, {
    category = "Roleplay HUD"
})
ix.config.Add("skinHud", "basic", "Choose a skin (basic/translucent)", nil, {
    category = "Roleplay HUD"
})

if SERVER then
    AddCSLuaFile("skins/basic.lua")
    AddCSLuaFile("skins/translucent.lua")
else 
    include("skins/basic.lua")
    include("skins/translucent.lua")

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

function PLUGIN:ShouldHideBars() return true end
function PLUGIN:CanDrawAmmoHUD() return false end







end
