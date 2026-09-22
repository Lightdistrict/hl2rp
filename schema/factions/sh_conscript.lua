FACTION.name = "Conscripts"
FACTION.description = "A human conscripted into service of the Combine Civil Authority, working their way up through the ranks."
FACTION.color = Color(120, 120, 130)
FACTION.pay = 5
FACTION.models = {
	"models/willardnetworks/conscripts/male_01.mdl",
	"models/willardnetworks/conscripts/male_02.mdl",
	"models/willardnetworks/conscripts/male_03.mdl",
	"models/willardnetworks/conscripts/male_04.mdl",
	"models/willardnetworks/conscripts/male_05.mdl",
	"models/willardnetworks/conscripts/male_06.mdl",
	"models/willardnetworks/conscripts/male_07.mdl",
	"models/willardnetworks/conscripts/male_08.mdl",
	"models/willardnetworks/conscripts/male_09.mdl",
	"models/willardnetworks/conscripts/male_10.mdl",
	"models/willardnetworks/conscripts/female_01.mdl",
	"models/willardnetworks/conscripts/female_02.mdl",
	"models/willardnetworks/conscripts/female_03.mdl",
	"models/willardnetworks/conscripts/female_04.mdl",
	"models/willardnetworks/conscripts/female_05.mdl",
	"models/willardnetworks/conscripts/female_06.mdl"
}
FACTION.isDefault = true
FACTION.isGloballyRecognized = true

function FACTION:OnCharacterCreated(client, character)
	character:SetData("civicPoints", 0)
end

FACTION_CONSCRIPT = FACTION.index
