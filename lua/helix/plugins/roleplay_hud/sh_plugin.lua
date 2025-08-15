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

if SERVER then
    AddCSLuaFile("ui/cl_hud.lua")
else 
    include("ui/cl_hud.lua")
end
