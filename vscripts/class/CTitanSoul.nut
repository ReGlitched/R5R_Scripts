untyped

global function CodeCallback_RegisterClass_CTitanSoul

function CodeCallback_RegisterClass_CTitanSoul()
{
	CTitanSoul.ClassName <- "CTitanSoul"

	CTitanSoul.lastAttackInfo <- null
	CTitanSoul.hijackProgress <- null
	CTitanSoul.lastHijackTime <- null
	CTitanSoul.capturable <- null
	CTitanSoul.followOnly <- null
	CTitanSoul.passives <- null
	CTitanSoul.createTime <- null
	CTitanSoul.rodeoRiderTracker <- null
	CTitanSoul.doomedTime <- null
	CTitanSoul.nextRegenTime <- 0.0
	CTitanSoul.nextHealthRegenTime <- 0.0
	CTitanSoul.rodeoReservedSlots <- null

	function CTitanSoul::constructor()
	{
		CBaseEntity.constructor()

		this.lastAttackInfo = { time = 0 }
		//this.passives = arrayofsize( GetNumPassives(), false )
		this.passives = []
		this.createTime = Time()
		this.doomedTime = null
		this.rodeoRiderTracker = {}
		this.capturable = false
		this.followOnly = false
		this.rodeoReservedSlots = arrayofsize( PROTOTYPE_DEFAULT_TITAN_RODEO_SLOTS, null )
	}


	// function SoulDeath()
	function CTitanSoul::SoulDestroy()
	{
		entity titan = expect entity( this.GetTitan() )
		foreach ( func in svGlobal.soulTransferFuncs )
		{
			func( expect entity( this ), null, titan )
		}
	}
}
