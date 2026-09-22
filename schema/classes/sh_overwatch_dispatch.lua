CLASS.name = "Dispatch"
CLASS.description = "The disembodied voice of Overwatch, directing Civil Authority personnel over the radio."
CLASS.faction = FACTION_OVERWATCH
CLASS.isDefault = true

function CLASS:CanSwitchTo(client)
	return client:IsSuperAdmin()
end

CLASS_OVERWATCH_DISPATCH = CLASS.index
