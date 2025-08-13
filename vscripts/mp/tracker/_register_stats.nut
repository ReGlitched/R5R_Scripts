untyped																			
globalize_all_functions
#if TRACKER && HAS_TRACKER_DLL

const bool STORE_STAT = true 

struct StatResetData
{
	string uid
	string statKey
	var savedValue
}

struct 
{
	array< StatResetData > shouldResetData
	bool RegisterCoreStats 	= true
	bool bStatsIs1v1Type 	= false

} file

void function SetRegisterCoreStats( bool b )
{
	file.RegisterCoreStats = b	
}

void function Tracker_Internal_Init()
{
	file.bStatsIs1v1Type = false
	
	bool bRegisterCoreStats = !GetCurrentPlaylistVarBool( "disable_core_stats", false )
	SetRegisterCoreStats( bRegisterCoreStats )
	
	Stats__InternalInit()
}

void function Tracker_SetShouldResetStatOnShip( string uid, string statKey, var origValue, bool bShouldReset = true )
{
	if( bShouldReset )
	{
		StatResetData statData
		
		statData.uid		= uid
		statData.statKey 	= statKey
		statData.savedValue = origValue
		
		file.shouldResetData.append( statData )
	}
	else 
	{
		int maxIter = file.shouldResetData.len() - 1
		if( maxIter == 0 )
			return
			
		for( int i = maxIter; i >= 0; i-- )
		{
			if( file.shouldResetData[ i ].uid == uid && file.shouldResetData[ i ].statKey == statKey )
				file.shouldResetData.remove( i )
		}
	}
}

void function Tracker_RunStatResets()
{
	foreach( int idx, StatResetData statData in file.shouldResetData )
		Stats__RawSetStat( statData.uid, statData.statKey, statData.savedValue )
}

void function Tracker_ResyncAllForPlayer( entity playerToSync )
{
	foreach( player in GetPlayerArray() )
		Remote_CallFunction_NonReplay( player, "Tracker_ResyncAllForPlayer", playerToSync )
}

void function Tracker_ResyncStatForPlayer( entity playerToSync, string statKey )
{
	int statKeyLen = statKey.len()
	mAssert( statKeyLen <= 9, "Cannot transmit statkey len > 9 chars for resync" )
	
	foreach( player in GetPlayerArray() )
	{
		array transmit = [ this, player, "Tracker_ResyncStatForPlayer", playerToSync.GetEncodedEHandle() ]	
		for( int i = 0; i < statKeyLen; i++ )
			transmit.append( statKey[ i ] )
	
		Remote_CallFunction_NonReplay.acall( transmit )
	}
}

void function Script_RegisterAllStats()
{
	Tracker_RegisterStat( "settings" )
	Tracker_RegisterStat( "isDev" )
	
	if( Chat_GlobalMuteEnabled() )
		Tracker_RegisterStat( "globally_muted", Chat_CheckGlobalMute )

	if( file.RegisterCoreStats )
	{
		Tracker_RegisterStat( "kills", null, Tracker_ReturnKills )
		Tracker_RegisterStat( "deaths", null, Tracker_ReturnDeaths )
		Tracker_RegisterStat( "superglides", null, Tracker_ReturnSuperglides )
		Tracker_RegisterStat( "total_time_played" )
		Tracker_RegisterStat( "total_matches" )
		Tracker_RegisterStat( "score" )
		Tracker_RegisterStat( "previous_champion", null, Tracker_ReturnChampion )
		Tracker_RegisterStat( "previous_kills", null, Tracker_ReturnKills )
		Tracker_RegisterStat( "previous_damage", null, Tracker_ReturnDamage )
		//Tracker_RegisterStat( "previous_survival_time", null,  )	
		
		AddCallback_PlayerDataFullyLoaded( Callback_CoreStatInit )
	}
	
	Tracker_RegisterStat( "unlocked_badges" )
	Tracker_RegisterStat( "badge_1", null, Tracker_Badge1 )
	Tracker_RegisterStat( "badge_2", null, Tracker_Badge2 )
	Tracker_RegisterStat( "badge_3", null, Tracker_Badge3 )
	AddCallback_PlayerDataFullyLoaded( Callback_CheckBadges )
	
	#if DEVELOPER 
		//Tracker_RegisterStat( "test_array", null, TrackerStats_TestStringArray )
		//Tracker_RegisterStat( "test_bool_array", null, TrackerStats_TestBoolArray )
		//Tracker_RegisterStat( "test_int_array", null, TrackerStats_TestIntArray, STORE_STAT )
		//Tracker_RegisterStat( "test_float_array", null, TrackerStats_TestFloatArray )
	#endif 

	if( Flowstate_EnableReporting() )
	{	
		Tracker_RegisterStat( "cringe_reports", null, TrackerStats_CringeReports, STORE_STAT )
		Tracker_RegisterStat( "was_reported_cringe", null, TrackerStats_WasReportedCringe, STORE_STAT  )
	}
		
	switch( Playlist() )
	{
		default:
			break
		
		//case :
	}
}

void function Callback_CoreStatInit( entity player )
{
	string uid = player.p.UID
	
	int player_season_kills = GetPlayerStatInt( uid, "kills" )
	player.p.season_kills = player_season_kills
	player.SetPlayerNetInt( "SeasonKills", player_season_kills )

	int player_season_deaths = GetPlayerStatInt( uid, "deaths" )
	player.p.season_deaths = player_season_deaths
	player.SetPlayerNetInt( "SeasonDeaths", player_season_deaths )

	player.p.season_glides = GetPlayerStatInt( uid, "superglides" )

	int player_season_playtime = GetPlayerStatInt( uid, "total_time_played" )	
	player.p.season_playtime = player_season_playtime
	player.SetPlayerNetInt( "SeasonPlaytime", player_season_playtime )

	int player_season_gamesplayed = GetPlayerStatInt( uid, "total_matches" )	
	player.p.season_gamesplayed = player_season_gamesplayed
	player.SetPlayerNetInt( "SeasonGamesplayed", player_season_gamesplayed )

	int player_season_score = GetPlayerStatInt( uid, "score" )
	player.p.season_score = player_season_score
	player.SetPlayerNetInt( "SeasonScore", player_season_score )
}

void function Callback_HandleScenariosStats( entity player )
{
	string uid = player.p.UID
		
	const string strSlice = "scenarios_"
	foreach( string statKey, var statValue in Stats__GetPlayerStatsTable( uid ) ) //TODO: register by script name group ( set in backend )
	{
		#if DEVELOPER
			//printw( "found statKey =", statKey, "statValue =", statValue )
		#endif 
		
		if( statKey.find( strSlice ) != -1 )
			ScenariosPersistence_SetUpOnlineData( player, statKey, statValue )
	}
}

var function TrackerStats_FSDMShots( string uid )
{
	entity player = GetPlayerEntityByUID( uid )	
	return player.p.shotsfired
}

var function TrackerStats_FSDMRailjumps( string uid )
{
	entity player = GetPlayerEntityByUID( uid )
	return player.p.railjumptimes 
}

var function TrackerStats_GamesCompleted( string uid ) //TODO: Handle accumulation from rejoins
{
	entity player = GetPlayerEntityByUID( uid ) 
	if( !IsValid( player ) )
		return 0
	
	int roundTime = fsGlobal.EndlessFFAorTDM ? 600 : FlowState_RoundTime()
	if( ( Time() - player.p.connectTime ) < ( roundTime / 2 )  )
		return 0
		
	return 1
}

var function TrackerStats_FSDMWins( string uid )
{	
	entity player = GetPlayerEntityByUID( uid )
	if( !IsValid( player ) )
		return 0
		
	return player == GetBestPlayer() ? 1 : 0
}

var function TrackerStats_OddballHeldTime( string uid )
{
	entity player = GetPlayerEntityByUID( uid )
	return player.GetPlayerNetInt( "oddball_ballHeldTime" )
}

var function TrackerStats_CtfFlagsCaptured( string uid )
{
	entity player = GetPlayerEntityByUID( uid )
	return player.GetPlayerNetInt( "captures" )
}

var function TrackerStats_CtfFlagsReturned( string uid )
{
	entity player = GetPlayerEntityByUID( uid )
	return player.GetPlayerNetInt( "returns" )
}

var function TrackerStats_CtfWins( string uid )
{
	entity ent = GetPlayerEntityByUID( uid )
	return ent.p.wonctf ? 1 : 0
}

var function Tracker_Badge1( string uid )
{
	return GetPlayerStatInt( uid, "badge_1" )
}

var function Tracker_Badge2( string uid )
{
	return GetPlayerStatInt( uid, "badge_2" )
}

var function Tracker_Badge3( string uid )
{
	return GetPlayerStatInt( uid, "badge_3" )
}

// var function TrackerStats_TestStringArray( string uid )
// {
	// return ["test", "test2", "test3"]
// }

// var function TrackerStats_TestBoolArray( string uid )
// {
	// return [ true, false, false, true ]
// }

// var function TrackerStats_TestFloatArray( string uid )
// {
	// return [ 1.0, 3.5188494 ]
// }

// var function TrackerStats_TestIntArray( string uid )
// {
	// return MakeVarArrayInt( GetPlayerEntityByUID( uid ).p.testarray )
// }

var function TrackerStats_GetPortalPlacements( string uid )
{
	entity ent = GetPlayerEntityByUID( uid )
	return ent.p.portalPlacements
}

var function TrackerStats_GetPortalKidnaps( string uid )
{
	entity ent = GetPlayerEntityByUID( uid )
	return ent.p.portalKidnaps
}

var function TrackerStats_CringeReports( string uid )
{
	entity ent = GetPlayerEntityByUID( uid )		
	return ent.p.submitCringeCount
}

var function TrackerStats_WasReportedCringe( string uid )
{
	entity ent = GetPlayerEntityByUID( uid )
	return ent.p.cringedCount
}

void function Callback_CheckBadges( entity player )
{
	string uid = player.p.UID
	
	int badge_1 = GetPlayerStatInt( uid, "badge_1" )
	if( !Tracker_IsValidBadge( badge_1, uid ) )
	{
		Tracker_SetShouldResetStatOnShip( uid, "badge_1", badge_1 ) 
		
		SetPlayerStatInt( uid, "badge_1", 0 )
	}
		
	int badge_2 = GetPlayerStatInt( uid, "badge_2" )
	if( !Tracker_IsValidBadge( badge_2, uid ) )
	{
		Tracker_SetShouldResetStatOnShip( uid, "badge_2", badge_2 )
		SetPlayerStatInt( uid, "badge_2", 0 )
	}
		
	int badge_3 = GetPlayerStatInt( uid, "badge_3" )
	if( !Tracker_IsValidBadge( badge_3, uid ) )
	{
		Tracker_SetShouldResetStatOnShip( uid, "badge_3", badge_3 )
		SetPlayerStatInt( uid, "badge_3", 0 )
	}
}

void function Script_RegisterAllPlayerDataCallbacks()
{

	// AddCallback_PlayerData( string setting, void functionref( entity player, string data ) callbackFunc )
	// AddCallback_PlayerData( "setting", func ) -- omit second param or use null for no func. AddCallback_PlayerData( "setting" )
	// void function func( entity player, string data )

	// Tracker_FetchPlayerData( uid, setting ) -- string|string
	// Tracker_SavePlayerData( uid, "settingname", value )  -- value: [bool|int|float|string]
	
	Chat_RegisterPlayerData()
		
	switch( Playlist() )
	{
		default:
			break
	}
	
	if( Flowstate_EnableReporting() )
		AddCallback_PlayerData( "cringe_report_data" )
}

void function Script_RegisterAllQueries()
{
	Tracker_QueryInit()
	//CustomGamemodeQueries_Init()
	//Gamemode1v1Queries_Init()
}

void function Script_RegisterAllShipFunctions()
{
	if( Flowstate_EnableReporting() )
		tracker.RegisterShipFunction( OnStatsShipping_Cringe, true )
		
}

void function OnStatsShipping_Cringe( string uid ) //TODO: Deprecate
{
	entity ent = GetPlayerEntityByUID( uid )
	
	if( IsValid( ent ) && ent.p.submitCringeCount > 0 )
	{
		string dataAppend
		foreach( CringeReport report in ent.p.cringeDataReports )
		{
			dataAppend += format
			( 
				"| Reported OID= %s | Reported Name= %s | Reported Reason= %s |\n", 
				report.cringedOID,
				report.cringedName,
				report.reason
			)
		}
		
		string currentData = Tracker_FetchPlayerData( uid, "cringe_report_data" )
		string newData = ( currentData + dataAppend )
		
		if( !empty( dataAppend ) )
			Tracker_SavePlayerData( uid, "cringe_report_data", newData )
	}
}

#else
	void function Tracker_SetShouldResetStatOnShip( string uid, string statKey, var origValue, bool bShouldReset = true ){}
	void function Tracker_ResyncAllForPlayer( entity player ){}
	void function Tracker_ResyncStatForPlayer( entity playerToSync, string statKey ){}
#endif