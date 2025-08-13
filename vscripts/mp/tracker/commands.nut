global function Commands_ReturnBaseCmdForAlias
global function Commands_ReturnBaseArgForAlias

global function Commands_AllArgAliasesContains
global function Commands_AllCmdAliasesContains

global function Commands_ArgAliasPointsTo
global function Commands_CmdAliasPointsTo

global function Commands_RequiresPlayersCommandsEnabled
global function Commands_GetCommandAliases
global function Commands_GetCommandHandler
global function Commands_DoesExist
global function Commands_Register

global function Commands_GetArgAliases
global function Commands_ArgDoesExist
global function Commands_SetupArg					

global typedef CommandCallback void functionref( string, array<string>, entity )

const bool PRINT_REGISTERED = true

struct CommandData
{
	CommandCallback handler
	array<string> aliases
	bool bRequiresCommandsEnabled
	bool isValid
}

struct ArgData
{
	array<string> aliases
}

struct 
{
	table< string, CommandData > commandHandlers
	table< string, string > cmdAliasLookupTable
	
	table< string, ArgData > argTable
	table< string, string > argAliasLookupTable
	
} file

void function Commands_Register( string cmd, CommandCallback ornull handlerFunctionOrNull = null, array<string> aliases = [], bool bRequiresCommandsEnabled = true ) 
{
	mAssert( !empty( cmd ), "Cannot register empty command" )
	
	if ( !Commands_DoesExist( cmd ) )
	{
		CommandCallback handlerFunction = nullreturn
		
		if( handlerFunctionOrNull != null )
			handlerFunction = expect CommandCallback ( handlerFunctionOrNull )
		
		CommandData data
		
		data.handler = handlerFunction
		data.aliases = aliases
		data.bRequiresCommandsEnabled = bRequiresCommandsEnabled
		data.isValid = true
		
		file.commandHandlers[ cmd ] <- data	
		
		#if DEVELOPER && PRINT_REGISTERED
			printt( "== Registered command:", cmd, " handler: " + string( handlerFunction ) + "() ==" )
		#endif
		
		__InsertCmdAliasLookupTable( cmd, aliases )	
    } 
	else
	{
		#if DEVELOPER
			printw( "Command", "\"" + cmd + "\"", "already exists" )
		#endif
	}
}

bool function Commands_DoesExist( string cmd )
{
	return ( cmd in file.commandHandlers )
}

CommandCallback function Commands_GetCommandHandler( string cmd ) 
{
	if ( cmd in file.commandHandlers )
		return file.commandHandlers[ cmd ].handler
		
	return nullreturn
}

bool function Commands_CmdAliasPointsTo( string alias, string cmd )
{
	if( !Commands_DoesExist( cmd ) )
	{
		#if DEVELOPER
			mAssert( false, "cmd \"" + cmd + "\" doesn't exist." )
		#endif 
		
		return false
	}
	
	if( Commands_ReturnBaseCmdForAlias( alias ) == cmd  )
		return true
		
	return false
}

array<string> function Commands_GetCommandAliases( string cmd )
{
	if( Commands_DoesExist( cmd ) )
		return file.commandHandlers[ cmd ].aliases
		
	array<string> emptyArray
	return emptyArray
}

string function Commands_ReturnBaseCmdForAlias( string cmdAlias )
{
	if( cmdAlias in file.cmdAliasLookupTable )
		return file.cmdAliasLookupTable[ cmdAlias ]
	
	return ""
}

bool function Commands_RequiresPlayersCommandsEnabled( string cmd )
{
	#if DEVELOPER
		if ( !( cmd in file.commandHandlers ) )
		{
			mAssert( false, "Command \"" + cmd + "\" does not exist. Calling function should be checking." ) //reduce check trains
			return false 
		}
	#endif
	
	return file.commandHandlers[ cmd ].bRequiresCommandsEnabled
}

bool function Commands_AllCmdAliasesContains( string alias )
{
	return ( alias in file.cmdAliasLookupTable )
}

void function __InsertCmdAliasLookupTable( string cmd, array<string> aliases )
{
	__CmdAliasTable_CheckSlot( cmd, cmd )
		
	foreach( alias in aliases )
		__CmdAliasTable_CheckSlot( alias, cmd )
}

void function __CmdAliasTable_CheckSlot( string alias, string cmd )
{
	if( !( alias in file.cmdAliasLookupTable ) )
	{
		file.cmdAliasLookupTable[ alias ] <- cmd

		#if DEVELOPER && PRINT_REGISTERED
			printt( "Registered command alias \"" + alias + "\" for [", cmd, "]" )
		#endif
	}
	#if DEVELOPER
	else
		mAssert( false, "Tried to insert a key in command table twice. Duplicate cmd aliases running?" )
	#endif
}

void function Commands_SetupArg( string arg, array<string> aliases = [] )
{
	mAssert( !empty( arg ), "Cannot register empty arg" )
	
	if ( !Commands_ArgDoesExist( arg ) ) 
	{
		ArgData data 
		
		data.aliases = aliases
		
		file.argTable[ arg ] <- data

		#if DEVELOPER && PRINT_REGISTERED
			printt( "== Registered arg \"" + arg + "\"" )
		#endif
		
		__InsertArgAliasLookupTable( arg, aliases )
	}
	else
	{
		#if DEVELOPER
			printw( "Arg", "\"" + arg + "\"", "already exists" )
		#endif
	}
}

bool function Commands_ArgDoesExist( string arg )
{
	return ( arg in file.argTable )
}

string function Commands_ReturnBaseArgForAlias( string argAlias )
{
	if( argAlias in file.argAliasLookupTable )
		return file.argAliasLookupTable[ argAlias ]
	
	return ""
}

bool function Commands_AllArgAliasesContains( string alias )
{
	return ( alias in file.argAliasLookupTable )
}

array<string> function Commands_GetArgAliases( string arg )
{
	if( Commands_ArgDoesExist( arg ) )
		return file.argTable[ arg ].aliases
		
	array<string> emptyArray
	return emptyArray
}

bool function Commands_ArgAliasPointsTo( string alias, string arg )
{
	if( !Commands_ArgDoesExist( arg ) )
		return false
	
	if( Commands_ReturnBaseArgForAlias( alias ) == arg  )
		return true
		
	return false
}

void function __InsertArgAliasLookupTable( string arg, array<string> aliases )
{
	__ArgAliasTable_CheckAndCreateSlot( arg, arg )
		
	foreach( alias in aliases )
		__ArgAliasTable_CheckAndCreateSlot( alias, arg )
}

void function __ArgAliasTable_CheckAndCreateSlot( string alias, string arg )
{
	if( !( alias in file.argAliasLookupTable ) )
	{
		file.argAliasLookupTable[ alias ] <- arg
		
		#if DEVELOPER && PRINT_REGISTERED
			printt( "Registered arg alias: \"" + alias + "\" for arg [", arg, "]" )
		#endif
	}
	#if DEVELOPER
	else 
		mAssert( false, "Tried to insert a key in arg alias table twice. Duplicate arg aliases running?" )
		
	#endif
}

void function nullreturn( string cmd, array<string> args, entity activator ) 
{
	#if DEVELOPER
		printw( "No handler for command:", cmd )
	#endif
}