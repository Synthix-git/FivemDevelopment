-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP:ACTIVE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("vRP:Active")
AddEventHandler("vRP:Active",function(Passport,Name)
	SetDiscordAppId(1343013616806264862)
	SetDiscordRichPresenceAsset("tnrp")
	SetRichPresence("#"..Passport.." "..Name)
	SetDiscordRichPresenceAssetText("Medusa Roleplay")
	SetDiscordRichPresenceAssetSmall("tnrp")
	SetDiscordRichPresenceAssetSmallText("Medusa Roleplay")
	SetDiscordRichPresenceAction(0,"Discord","https://discord.gg/yzuUJTgXfx")
end)