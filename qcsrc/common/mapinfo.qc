// generic string stuff
float startsWith(string haystack, string needle)
{
	return substring(haystack, 0, strlen(needle)) == needle;
}
float startsWithNocase(string haystack, string needle)
{
	return strcasecmp(substring(haystack, 0, strlen(needle)), needle) == 0;
}
string extractRestOfLine(string haystack, string needle)
{
	if(startsWith(haystack, needle))
		return substring(haystack, strlen(needle), strlen(haystack) - strlen(needle));
	return string_null;
}
string car(string s)
{
	float o;
	o = strstrofs(s, " ", 0);
	if(o < 0)
		return s;
	return substring(s, 0, o);
}
string cdr(string s)
{
	float o;
	o = strstrofs(s, " ", 0);
	if(o < 0)
		return string_null;
	return substring(s, o + 1, strlen(s) - (o + 1));
}
float matchacl(string acl, string str)
{
	string t, s;
	float r, d;
	r = 0;
	while(acl)
	{
		t = car(acl); acl = cdr(acl);
		d = 1;
		if(substring(t, 0, 1) == "-")
		{
			d = -1;
			t = substring(t, 1, strlen(t) - 1);
		}
		else if(substring(t, 0, 1) == "+")
			t = substring(t, 1, strlen(t) - 1);
		if(substring(t, -1, 1) == "*")
		{
			t = substring(t, 0, strlen(t) - 1);
			s = substring(s, 0, strlen(t));
		}
		else
			s = str;

		if(s == t)
		{
			r = d;
		}
	}
	return r;
}

float _MapInfo_Cache_Active;
float _MapInfo_Cache_DB_NameToIndex;
float _MapInfo_Cache_Buf_IndexToMapData;

void MapInfo_Cache_Destroy()
{
	if(!_MapInfo_Cache_Active)
		return;

	db_close(_MapInfo_Cache_DB_NameToIndex);
	buf_del(_MapInfo_Cache_Buf_IndexToMapData);
	_MapInfo_Cache_Active = 0;
}

void MapInfo_Cache_Create()
{
	MapInfo_Cache_Destroy();
	_MapInfo_Cache_DB_NameToIndex = db_create();
	_MapInfo_Cache_Buf_IndexToMapData = buf_create();
	_MapInfo_Cache_Active = 1;
}

void MapInfo_Cache_Invalidate()
{
	if(!_MapInfo_Cache_Active)
		return;

	MapInfo_Cache_Create();
}

void MapInfo_Cache_Store()
{
	float i;
	string s;
	if(!_MapInfo_Cache_Active)
		return;

	s = db_get(_MapInfo_Cache_DB_NameToIndex, MapInfo_Map_bspname);
	if(!s) // empty string is NOT valid here!
	{
		i = buf_getsize(_MapInfo_Cache_Buf_IndexToMapData);
		db_put(_MapInfo_Cache_DB_NameToIndex, MapInfo_Map_bspname, ftos(i));
	}
	else
		i = stof(s);

	// now store all the stuff
	bufstr_set(_MapInfo_Cache_Buf_IndexToMapData,   i, MapInfo_Map_bspname);
	bufstr_set(_MapInfo_Cache_Buf_IndexToMapData, ++i, MapInfo_Map_title);
	bufstr_set(_MapInfo_Cache_Buf_IndexToMapData, ++i, MapInfo_Map_description);
	bufstr_set(_MapInfo_Cache_Buf_IndexToMapData, ++i, MapInfo_Map_author);
	bufstr_set(_MapInfo_Cache_Buf_IndexToMapData, ++i, ftos(MapInfo_Map_supportedGametypes));
	bufstr_set(_MapInfo_Cache_Buf_IndexToMapData, ++i, ftos(MapInfo_Map_supportedFeatures));
	bufstr_set(_MapInfo_Cache_Buf_IndexToMapData, ++i, ftos(MapInfo_Map_flags));
}

float MapInfo_Cache_Retrieve(string map)
{
	float i;
	string s;
	if(!_MapInfo_Cache_Active)
		return 0;

	s = db_get(_MapInfo_Cache_DB_NameToIndex, map);
	if(!s)
		return 0;
	i = stof(s);

	// now retrieve all the stuff
	MapInfo_Map_bspname = bufstr_get(_MapInfo_Cache_Buf_IndexToMapData, i);
	MapInfo_Map_title = bufstr_get(_MapInfo_Cache_Buf_IndexToMapData, ++i);
	MapInfo_Map_description = bufstr_get(_MapInfo_Cache_Buf_IndexToMapData, ++i);
	MapInfo_Map_author = bufstr_get(_MapInfo_Cache_Buf_IndexToMapData, ++i);
	MapInfo_Map_supportedGametypes = stof(bufstr_get(_MapInfo_Cache_Buf_IndexToMapData, ++i));
	MapInfo_Map_supportedFeatures = stof(bufstr_get(_MapInfo_Cache_Buf_IndexToMapData, ++i));
	MapInfo_Map_flags = stof(bufstr_get(_MapInfo_Cache_Buf_IndexToMapData, ++i));
	return 1;
}

// GLOB HANDLING (for all BSP files)
float _MapInfo_globopen;
float _MapInfo_globcount;
float _MapInfo_globhandle;
string _MapInfo_GlobItem(float i)
{
	string s;
	s = search_getfilename(_MapInfo_globhandle, i);
	return substring(s, 5, strlen(s) - 9); // without maps/ and .bsp
}

void MapInfo_Enumerate()
{
	if(_MapInfo_globopen)
		search_end(_MapInfo_globhandle);
	MapInfo_Cache_Invalidate();
	_MapInfo_globhandle = search_begin("maps/*.bsp", TRUE, TRUE);
	_MapInfo_globcount = search_getsize(_MapInfo_globhandle);
	_MapInfo_globopen = 1;
}

// filter the info by game type mask (updates MapInfo_count)
//
float _MapInfo_filtered;
float _MapInfo_filtered_allocated;
float MapInfo_FilterList_Lookup(float i)
{
	return stof(bufstr_get(_MapInfo_filtered, i));
}

void _MapInfo_FilterList_swap(float i, float j, entity pass)
{
	string h;
	h = bufstr_get(_MapInfo_filtered, i);
	bufstr_set(_MapInfo_filtered, i, bufstr_get(_MapInfo_filtered, j));
	bufstr_set(_MapInfo_filtered, j, h);
}

float _MapInfo_FilterList_cmp(float i, float j, entity pass)
{
	string a, b;
	a = _MapInfo_GlobItem(stof(bufstr_get(_MapInfo_filtered, i)));
	b = _MapInfo_GlobItem(stof(bufstr_get(_MapInfo_filtered, j)));
	return strcasecmp(a, b);
}

float MapInfo_FilterGametype(float pGametype, float pFeatures, float pFlagsRequired, float pFlagsForbidden, float pAbortOnGenerate)
{
	float i, j;
	if not(_MapInfo_filtered_allocated)
	{
		_MapInfo_filtered_allocated = 1;
		_MapInfo_filtered = buf_create();
	}
	MapInfo_count = 0;
	for(i = 0, j = -1; i < _MapInfo_globcount; ++i)
	{
		/*
		if(MapInfo_Get_ByName(_MapInfo_GlobItem(i), 1, 0) == 2) // if we generated one... BAIL OUT and let the caller continue in the next frame.
			if(pAbortOnGenerate)
			{
				dprint("Autogenerated a .mapinfo, doing the rest later.\n");
				MapInfo_progress = i / _MapInfo_globcount;
				return 0;
			}
		if((MapInfo_Map_supportedGametypes & pGametype) != 0)
		*/
		if((MapInfo_Map_supportedFeatures & pFeatures) == pFeatures)
		if((MapInfo_Map_flags & pFlagsForbidden) == 0)
		if((MapInfo_Map_flags & pFlagsRequired) == pFlagsRequired)
			bufstr_set(_MapInfo_filtered, ++j, ftos(i));
			
		MapInfo_Get_ByName(_MapInfo_GlobItem(i), 1, 0);
		//print("^5Adding map: ^7", _MapInfo_GlobItem(i), "\n");
	}
	MapInfo_count = j + 1;
	MapInfo_ClearTemps();

	// sometimes the glob isn't sorted nicely, so fix it here...
	heapsort(MapInfo_count, _MapInfo_FilterList_swap, _MapInfo_FilterList_cmp, world);

	return 1;
}

void MapInfo_Filter_Free()
{
	if(_MapInfo_filtered_allocated)
	{
		buf_del(_MapInfo_filtered);
		_MapInfo_filtered_allocated = 0;
	}
}

// load info about the i-th map into the MapInfo_Map_* globals
string MapInfo_BSPName_ByID(float i)
{
	return _MapInfo_GlobItem(MapInfo_FilterList_Lookup(i));
}

string unquote(string s)
{
	float i, j, l;
	l = strlen(s);
	j = -1;
	for(i = 0; i < l; ++i)
	{
		string ch;
		ch = substring(s, i, 1);
		if(ch != " ") if(ch != "\"")
		{
			for(j = strlen(s) - i - 1; j > 0; --j)
			{
				ch = substring(s, i+j, 1);
				if(ch != " ") if(ch != "\"")
					return substring(s, i, j+1);
			}
			return substring(s, i, 1);
		}
	}
	return "";
}

float MapInfo_Get_ByID(float i)
{
	if(MapInfo_Get_ByName(MapInfo_BSPName_ByID(i), 0, 0))
		return 1;
	return 0;
}

string _MapInfo_Map_worldspawn_music;

float _MapInfo_Generate(string pFilename) // 0: failure, 1: ok ent, 2: ok bsp
{
	string fn;
	float fh;
	string s, k, v;
	vector o;
	float i;
	float inWorldspawn;
	float r;
	float twoBaseModes;
	float diameter, spawnpoints;
	float spawnplaces;

	vector mapMins, mapMaxs;

	r = 1;
	fn = strcat("maps/", pFilename, ".ent");
	fh = fopen(fn, FILE_READ);
	if(fh < 0)
	{
		r = 2;
		fn = strcat("maps/", pFilename, ".bsp");
		fh = fopen(fn, FILE_READ);
	}
	if(fh < 0)
		return 0;
	print("Analyzing ", fn, " to generate initial mapinfo; please edit that file later\n");

	inWorldspawn = 2;
	MapInfo_Map_flags = 0;
	MapInfo_Map_supportedGametypes = 0;
	spawnpoints = 0;
	spawnplaces = 0;
	_MapInfo_Map_worldspawn_music = "";

	for(;;)
	{
		if not((s = fgets(fh)))
			break;
		if(inWorldspawn == 1)
			if(startsWith(s, "}"))
				inWorldspawn = 0;
		k = unquote(car(s));
		v = unquote(cdr(s));
		if(inWorldspawn)
		{
			if(k == "classname" && v == "worldspawn")
				inWorldspawn = 1;
			else if(k == "author")
				MapInfo_Map_author = v;
			else if(k == "_description")
				MapInfo_Map_description = v;
			else if(k == "music")
				_MapInfo_Map_worldspawn_music = v;
			else if(k == "noise")
				_MapInfo_Map_worldspawn_music = v;
			else if(k == "message")
			{
				i = strstrofs(v, " by ", 0);
				if(MapInfo_Map_author == "<AUTHOR>" && i >= 0)
				{
					MapInfo_Map_title = substring(v, 0, i);
					MapInfo_Map_author = substring(v, i + 4, strlen(v) - (i + 4));
				}
				else
					MapInfo_Map_title = v;
			}
		}
		else
		{
			if(k == "origin")
			{
				o = stov(strcat("'", v, "'"));
				mapMins_x = min(mapMins_x, o_x);
				mapMins_y = min(mapMins_y, o_y);
				mapMins_z = min(mapMins_z, o_z);
				mapMaxs_x = max(mapMaxs_x, o_x);
				mapMaxs_y = max(mapMaxs_y, o_y);
				mapMaxs_z = max(mapMaxs_z, o_z);
			}
			else if(k == "race_place")
			{
				if(stof(v) > 0)
					spawnplaces = 1;
			}
			else if(k == "classname")
			{
				if(v == "dom_controlpoint")
					MapInfo_Map_supportedGametypes |= MAPINFO_TYPE_DOMINATION;
				else if(v == "item_flag_team2")
					MapInfo_Map_supportedGametypes |= MAPINFO_TYPE_CTF;
				else if(v == "team_CTF_blueflag")
					MapInfo_Map_supportedGametypes |= MAPINFO_TYPE_CTF;
				else if(v == "runematch_spawn_point")
					MapInfo_Map_supportedGametypes |= MAPINFO_TYPE_RUNEMATCH;
				else if(v == "target_assault_roundend")
					MapInfo_Map_supportedGametypes |= MAPINFO_TYPE_ASSAULT;
				else if(v == "onslaught_generator")
					MapInfo_Map_supportedGametypes |= MAPINFO_TYPE_ONSLAUGHT;
				else if(substring(v, 0, 8) == "nexball_" || substring(v, 0, 4) == "ball")
					MapInfo_Map_supportedGametypes |= MAPINFO_TYPE_NEXBALL;
				else if(v == "info_player_team1")
					++spawnpoints;
				else if(v == "info_player_team2")
					++spawnpoints;
				else if(v == "info_player_start")
					++spawnpoints;
				else if(v == "info_player_deathmatch")
					++spawnpoints;
				else if(v == "trigger_race_checkpoint")
					MapInfo_Map_supportedGametypes |= MAPINFO_TYPE_RACE;
				else if(v == "weapon_nex")
					{ }
				else if(v == "weapon_railgun")
					{ }
				else if(startsWith(v, "weapon_"))
					MapInfo_Map_supportedFeatures |= MAPINFO_FEATURE_WEAPONS;
			}
		}
	}
	if(inWorldspawn)
	{
		print(fn, " ended still in worldspawn, BUG\n");
		return 0;
	}
	diameter = vlen(mapMaxs - mapMins);

	twoBaseModes = MapInfo_Map_supportedGametypes & (MAPINFO_TYPE_CTF | MAPINFO_TYPE_ASSAULT | MAPINFO_TYPE_RACE | MAPINFO_TYPE_NEXBALL);
	if(twoBaseModes && (MapInfo_Map_supportedGametypes == twoBaseModes))
	{
		// we have a CTF-only or Assault-only map. Don't add other modes then,
		// as the map is too symmetric for them.
	}
	else
	{
		MapInfo_Map_supportedGametypes |= MAPINFO_TYPE_DEATHMATCH;      // DM always works
		MapInfo_Map_supportedGametypes |= MAPINFO_TYPE_RUNEMATCH;       // Rune always works
		MapInfo_Map_supportedGametypes |= MAPINFO_TYPE_LMS;             // LMS always works

		if(spawnpoints >= 8  && diameter > 4096)
			MapInfo_Map_supportedGametypes |= MAPINFO_TYPE_TEAM_DEATHMATCH;
		if(                     diameter < 4096)
			MapInfo_Map_supportedGametypes |= MAPINFO_TYPE_ARENA;
		if(spawnpoints >= 12 && diameter > 5120)
			MapInfo_Map_supportedGametypes |= MAPINFO_TYPE_KEYHUNT;
	}

	if(MapInfo_Map_supportedGametypes & MAPINFO_TYPE_RACE)
	if(!spawnplaces)
	{
		MapInfo_Map_supportedGametypes &~= MAPINFO_TYPE_RACE;
		MapInfo_Map_supportedGametypes |= MAPINFO_TYPE_CTS;
	}

	dprint("-> diameter ",    ftos(diameter));
	dprint(";  spawnpoints ", ftos(spawnpoints));
	dprint(";  modes ",       ftos(MapInfo_Map_supportedGametypes), "\n");

	fclose(fh);

	return r;
}

void _MapInfo_Map_Reset()
{
	MapInfo_Map_title = "<TITLE>";
	MapInfo_Map_description = "<DESCRIPTION>";
	MapInfo_Map_author = "<AUTHOR>";
	MapInfo_Map_supportedGametypes = 0;
	MapInfo_Map_supportedFeatures = 0;
	MapInfo_Map_flags = 0;
	MapInfo_Map_clientstuff = "";
	MapInfo_Map_fog = "";
	MapInfo_Map_mins = '0 0 0';
	MapInfo_Map_maxs = '0 0 0';
}

void _MapInfo_Map_ApplyGametype(string s, float pWantedType, float pThisType)
{
	string sa;
	MapInfo_Map_supportedGametypes |= pThisType;
	if(!(pThisType & pWantedType))
		return;

	if(pWantedType == MAPINFO_TYPE_ASSAULT || pWantedType == MAPINFO_TYPE_ONSLAUGHT || pWantedType == MAPINFO_TYPE_RACE || pWantedType == MAPINFO_TYPE_CTS) // these modes don't use fraglimit
	{
		cvar_set("fraglimit", "0");
	}
	else
	{
		cvar_set("fraglimit", car(s));
		s = cdr(s);
	}

	cvar_set("timelimit", car(s));
	s = cdr(s);

	if(pWantedType == MAPINFO_TYPE_TEAM_DEATHMATCH)
	{
		sa = car(s); if(sa == "") sa = "2";
		cvar_set("g_tdm_teams", sa);
		s = cdr(s);
	}

	if(pWantedType == MAPINFO_TYPE_KEYHUNT)
	{
		sa = car(s); if(sa == "") sa = "3";
		cvar_set("g_keyhunt_teams", sa);
		s = cdr(s);
	}

	if(pWantedType == MAPINFO_TYPE_CTF) if(!_is_key_hunt)
	{
		sa = car(s); if(sa == "") sa = "10";
		if(cvar("g_ctf_win_mode") < 2)
			cvar_set("fraglimit", sa);
		s = cdr(s);
	}

	// rc = timelimit timelimit_qualification laps laps_teamplay
	if(pWantedType == MAPINFO_TYPE_RACE)
	{
		sa = car(s); if(sa == "") sa = cvar_string("timelimit");
		cvar_set("g_race_qualifying_timelimit", sa);
		s = cdr(s);

		sa = car(s); if(sa == "") sa = "10";
		if(cvar("g_race_teams") < 2)
			cvar_set("fraglimit", sa);
		s = cdr(s);

		sa = car(s); if(sa == "") sa = "20";
		if(cvar("g_race_teams") >= 2)
			cvar_set("fraglimit", sa);
		s = cdr(s);
	}

	if(pWantedType == MAPINFO_TYPE_CTS)
	{
		sa = car(s); if(sa == "") sa = cvar_string("fraglimit");
		if(cvar("g_race_teams"))
			cvar_set("fraglimit", sa);
		s = cdr(s);
	}

	sa = car(s); if(sa == "") sa = "0";
	cvar_set("leadlimit", sa);
	s = cdr(s);
}

float MapInfo_Type_FromString(string t)
{
	if     (t == "dm")      return MAPINFO_TYPE_DEATHMATCH;
	else if(t == "tdm")     return MAPINFO_TYPE_TEAM_DEATHMATCH;
	else if(t == "dom")     return MAPINFO_TYPE_DOMINATION;
	else if(t == "ctf")     return MAPINFO_TYPE_CTF;
	else if(t == "rune")    return MAPINFO_TYPE_RUNEMATCH;
	else if(t == "lms")     return MAPINFO_TYPE_LMS;
	else if(t == "arena")   return MAPINFO_TYPE_ARENA;
	else if(t == "kh")      return MAPINFO_TYPE_KEYHUNT;
	else if(t == "as")      return MAPINFO_TYPE_ASSAULT;
	else if(t == "ons")     return MAPINFO_TYPE_ONSLAUGHT;
	else if(t == "rc")      return MAPINFO_TYPE_RACE;
	else if(t == "nexball") return MAPINFO_TYPE_NEXBALL;
	else if(t == "cts")     return MAPINFO_TYPE_CTS;
	else if(t == "all")     return MAPINFO_TYPE_ALL;
	else if(t == "ft")		return MAPINFO_TYPE_CTF;
    else if(t == "vip")     return MAPINFO_TYPE_CTF;
	else if(t == "totaldom") return MAPINFO_TYPE_DOMINATION;
	else                    return 0;
}

void _MapInfo_Parse_Settemp(string pFilename, string acl, string s, float recurse)
{
	string t;
	float fh;
	t = car(s); s = cdr(s);
	if(t == "#include")
	{
		if(recurse > 0)
		{
			fh = fopen(s, FILE_READ);
			if(fh < 0)
				print("Map ", pFilename, " references not existing config file ", s, "\n");
			else
			{
				for(;;)
				{
					if not((s = fgets(fh)))
						break;

					// catch different sorts of comments
					if(s == "")                    // empty lines
						continue;
					if(substring(s, 0, 1) == "#")  // UNIX style
						continue;
					if(substring(s, 0, 2) == "//") // C++ style
						continue;
					if(substring(s, 0, 1) == "_")  // q3map style
						continue;

					_MapInfo_Parse_Settemp(pFilename, acl, s, recurse - 1);
				}
				fclose(fh);
			}
		}
		else
			print("Map ", pFilename, " uses too many levels of inclusion\n");
	}
	else if not(cvar_value_issafe(t))
		print("Map ", pFilename, " contains a potentially harmful setting, ignored\n");
	else if not (cvar_value_issafe(s))
		print("Map ", pFilename, " contains a potentially harmful setting, ignored\n");
	else if(substring(t, 0, 10) == "g_mapinfo_")
		print("Map ", pFilename, " contains a potentially harmful setting, ignored\n");
	else if(matchacl(acl, t) <= 0)
		print("Map ", pFilename, " contains a denied setting, ignored\n");
	else
	{
		dprint("Applying temporary setting ", t, " := ", s, "\n");
		if(cvar("g_campaign"))
			cvar_set(t, s); // this is a wrapper and is always temporary anyway; no need to backup old values then
		else
			cvar_settemp(t, s);
	}
}

// load info about a map by name into the MapInfo_Map_* globals
float MapInfo_Get_ByName(string pFilename, float pAllowGenerate, float pGametypeToSet)
{
	string fn;
	string s, t;
	float fh, fh2;
	float r, f, n, i;
	string acl;

	acl = cvar_string("g_mapinfo_settemp_acl");

	if(strstrofs(pFilename, "/", 0) >= 0)
	{
		print("Invalid character in map name, ignored\n");
		return 0;
	}

	if(pGametypeToSet == 0)
		if(MapInfo_Cache_Retrieve(pFilename))
			return 1;

	r = 1;

	MapInfo_Map_bspname = pFilename;

	// default all generic fields so they have "good" values in case something fails
	fn = strcat("maps/", pFilename, ".mapinfo");
	fh = fopen(fn, FILE_READ);
	if(fh < 0)
	{
		if(!pAllowGenerate)
			return 0;
		_MapInfo_Map_Reset();
		r = _MapInfo_Generate(pFilename);
		if(!r)
			return 0;
		fh = fopen(fn, FILE_WRITE);
		fputs(fh, strcat("title ", MapInfo_Map_title, "\n"));
		fputs(fh, strcat("description ", MapInfo_Map_description, "\n"));
		fputs(fh, strcat("author ", MapInfo_Map_author, "\n"));
		if(_MapInfo_Map_worldspawn_music != "")
		{
			if(
				substring(_MapInfo_Map_worldspawn_music, strlen(_MapInfo_Map_worldspawn_music) - 4, 4) == ".wav"
				||
				substring(_MapInfo_Map_worldspawn_music, strlen(_MapInfo_Map_worldspawn_music) - 4, 4) == ".ogg"
			)
				fputs(fh, strcat("cdtrack ", substring(_MapInfo_Map_worldspawn_music, 0, strlen(_MapInfo_Map_worldspawn_music) - 4), "\n"));
			else
				fputs(fh, strcat("cdtrack ", _MapInfo_Map_worldspawn_music, "\n"));
		}
		else
		{
			n = tokenize_console(cvar_string("g_cdtracks_remaplist"));
			s = strcat(" ", cvar_string("g_cdtracks_dontusebydefault"), " ");
			for(;;)
			{
				i = floor(random() * n);
				if(strstrofs(s, strcat(" ", argv(i), " "), 0) < 0)
					break;
			}
			fputs(fh, strcat("cdtrack ", ftos(i + 1), "\n"));
		}
		if(MapInfo_Map_supportedFeatures & MAPINFO_FEATURE_WEAPONS)
			fputs(fh, "has weapons\n");
		else
			fputs(fh, "// uncomment this if you added weapon pickups: has weapons\n");
		if(MapInfo_Map_flags & MAPINFO_FLAG_FRUSTRATING)
			fputs(fh, "frustrating\n");
		if(MapInfo_Map_supportedGametypes & MAPINFO_TYPE_DEATHMATCH)      fputs(fh, "type dm 30 20\n");
		if(MapInfo_Map_supportedGametypes & MAPINFO_TYPE_TEAM_DEATHMATCH) fputs(fh, "type tdm 50 20 2\n");
		if(MapInfo_Map_supportedGametypes & MAPINFO_TYPE_DOMINATION)      fputs(fh, "type dom 200 20\n");
		if(MapInfo_Map_supportedGametypes & MAPINFO_TYPE_CTF)             fputs(fh, "type ctf 300 20 10\n");
		if(MapInfo_Map_supportedGametypes & MAPINFO_TYPE_RUNEMATCH)       fputs(fh, "type rune 200 20\n");
		if(MapInfo_Map_supportedGametypes & MAPINFO_TYPE_LMS)             fputs(fh, "type lms 9 20\n");
		if(MapInfo_Map_supportedGametypes & MAPINFO_TYPE_ARENA)           fputs(fh, "type arena 10 20\n");
		if(MapInfo_Map_supportedGametypes & MAPINFO_TYPE_KEYHUNT)         fputs(fh, "type kh 1000 20 3\n");
		if(MapInfo_Map_supportedGametypes & MAPINFO_TYPE_ASSAULT)         fputs(fh, "type as 20\n");
		if(MapInfo_Map_supportedGametypes & MAPINFO_TYPE_RACE)            fputs(fh, "type rc 20 5 7 15\n");
		if(MapInfo_Map_supportedGametypes & MAPINFO_TYPE_ONSLAUGHT)       fputs(fh, "type ons 20\n");
		if(MapInfo_Map_supportedGametypes & MAPINFO_TYPE_NEXBALL)         fputs(fh, "type nexball 5 20\n");
		if(MapInfo_Map_supportedGametypes & MAPINFO_TYPE_CTS)             fputs(fh, "type cts 20 -1\n");

		fh2 = fopen(strcat("scripts/", pFilename, ".arena"), FILE_READ);
		if(fh2 >= 0)
		{
			fclose(fh2);
			fputs(fh, "settemp_for_type all sv_q3acompat_machineshotgunswap 1\n");
		}

		fputs(fh, "// optional: fog density red green blue alpha mindist maxdist\n");
		fputs(fh, "// optional: settemp_for_type (all|gametypename) cvarname value\n");
		fputs(fh, "// optional: clientsettemp_for_type (all|gametypename) cvarname value\n");
		fputs(fh, "// optional: size mins_x mins_y mins_z maxs_x maxs_y maxs_z\n");
		fputs(fh, "// optional: hidden\n");

		fclose(fh);
		r = 2;
		// return r;
		fh = fopen(fn, FILE_READ);
		if(fh < 0)
			error("... but I just wrote it!");
	}

	_MapInfo_Map_Reset();
	for(;;)
	{
		if not((s = fgets(fh)))
			break;

		// catch different sorts of comments
		if(s == "")                    // empty lines
			continue;
		if(substring(s, 0, 1) == "#")  // UNIX style
			continue;
		if(substring(s, 0, 2) == "//") // C++ style
			continue;
		if(substring(s, 0, 1) == "_")  // q3map style
			continue;

		t = car(s); s = cdr(s);
		if(t == "title")
			MapInfo_Map_title = s;
		else if(t == "description")
			MapInfo_Map_description = s;
		else if(t == "author")
			MapInfo_Map_author = s;
		else if(t == "has")
		{
			t = car(s); s = cdr(s);
			if     (t == "weapons") MapInfo_Map_supportedFeatures |= MAPINFO_FEATURE_WEAPONS;
			else
				dprint("Map ", pFilename, " supports unknown feature ", t, ", ignored\n");
		}
		else if(t == "hidden")
		{
			MapInfo_Map_flags |= MAPINFO_FLAG_HIDDEN;
		}
		else if(t == "forbidden")
		{
			MapInfo_Map_flags |= MAPINFO_FLAG_FORBIDDEN;
		}
		else if(t == "frustrating")
		{
			MapInfo_Map_flags |= MAPINFO_FLAG_FRUSTRATING;
		}
		else if(t == "type")
		{
			t = car(s); s = cdr(s);
			f = MapInfo_Type_FromString(t);
			if(f)
				_MapInfo_Map_ApplyGametype (s, pGametypeToSet, f);
			else
				dprint("Map ", pFilename, " supports unknown game type ", t, ", ignored\n");
		}
		else if(t == "size")
		{
			float a, b, c, d, e;
			t = car(s); s = cdr(s); a = stof(t);
			t = car(s); s = cdr(s); b = stof(t);
			t = car(s); s = cdr(s); c = stof(t);
			t = car(s); s = cdr(s); d = stof(t);
			t = car(s); s = cdr(s); e = stof(t);
			if(s == "")
				print("Map ", pFilename, " contains an incorrect size line (not enough params), syntax: size mins_x mins_y mins_z maxs_x maxs_y maxs_z\n");
			else
			{
				t = car(s); s = cdr(s); f = stof(t);
				if(s != "")
					print("Map ", pFilename, " contains an incorrect size line (too many params), syntax: size mins_x mins_y mins_z maxs_x maxs_y maxs_z\n");
				else
				{
					if(a >= d || b >= e || c >= f)
						print("Map ", pFilename, " contains an incorrect size line, mins have to be < maxs\n");
					else
					{
						MapInfo_Map_mins_x = a;
						MapInfo_Map_mins_y = b;
						MapInfo_Map_mins_z = c;
						MapInfo_Map_maxs_x = d;
						MapInfo_Map_maxs_y = e;
						MapInfo_Map_maxs_z = f;
					}
				}
			}
		}
		else if(t == "settemp_for_type")
		{
			t = car(s); s = cdr(s);
			if((f = MapInfo_Type_FromString(t)))
			{
				if(f & pGametypeToSet)
				{
					_MapInfo_Parse_Settemp(pFilename, acl, s, 1);
				}
			}
			else
			{
				dprint("Map ", pFilename, " has a setting for unknown game type ", t, ", ignored\n");
			}
		}
		else if(t == "clientsettemp_for_type")
		{
			t = car(s); s = cdr(s);
			if((f = MapInfo_Type_FromString(t)))
			{
				if(f & pGametypeToSet)
				{
					t = car(s); s = cdr(s);
					if not(cvar_value_issafe(t))
						print("Map ", pFilename, " contains a potentially harmful client setting, ignored\n");
					else if not (cvar_value_issafe(s))
						print("Map ", pFilename, " contains a potentially harmful client setting, ignored\n");
					else
					{
						dprint("Applying temporary client setting ", t, " := ", s, "\n");
						MapInfo_Map_clientstuff = strcat(
							MapInfo_Map_clientstuff, "cl_cmd settemp \"", t, "\" \"", s, "\"\n"
						);
					}
				}
			}
			else
			{
				dprint("Map ", pFilename, " has a client setting for unknown game type ", t, ", ignored\n");
			}
		}
		else if(t == "fog")
		{
			if not(cvar_value_issafe(t))
				print("Map ", pFilename, " contains a potentially harmful fog setting, ignored\n");
			else
				MapInfo_Map_fog = s;
		}
		else if(t == "cdtrack")
		{
			if(pGametypeToSet)
			{
				if not(cvar_value_issafe(t))
					print("Map ", pFilename, " contains a potentially harmful cdtrack, ignored\n");
				else
					MapInfo_Map_clientstuff = strcat(
						MapInfo_Map_clientstuff, "cd loop \"", s, "\"\n"
					);
			}
		}
		else
			dprint("Map ", pFilename, " provides unknown info item ", t, ", ignored\n");
	}
	fclose(fh);

#ifndef CSQC
	if(!MapInfo_Map_supportedGametypes)
		_MapInfo_Map_ApplyGametype("30 20", pGametypeToSet, MAPINFO_TYPE_DEATHMATCH);

	if(pGametypeToSet)
		if(!(MapInfo_Map_supportedGametypes & pGametypeToSet))
		{
			//error(strcat("Can't select the requested game type. Bailing out. pGametypeToSet = ", ftos(pGametypeToSet), "; MapInfo_Map_supportedGametypes = ", ftos(MapInfo_Map_supportedGametypes )));
			#ifdef SVQC
			bprint("^1Can't select the requested gametype, WTF?!\n");
			#endif
		}
#endif
	MapInfo_Cache_Store();
	if(MapInfo_Map_supportedGametypes != 0)
		return r;
	dprint("Map ", pFilename, " supports no game types, ignored\n");
	return 0;
}

float MapInfo_FindName(string s)
{
	// if there is exactly one map of prefix s, return it
	// if not, return the null string
	// note that DP sorts glob results... so I can use a binary search
	float l, r, m, cmp;
	l = 0;
	r = MapInfo_count;
	// invariants: r is behind s, l-1 is equal or before
	while(l != r)
	{
		m = floor((l + r) / 2);
		MapInfo_FindName_match = _MapInfo_GlobItem(MapInfo_FilterList_Lookup(m));
		cmp = strcasecmp(MapInfo_FindName_match, s);
		if(cmp == 0)
			return m; // found and good
		if(cmp < 0)
			l = m + 1; // l-1 is before s
		else
			r = m; // behind s
	}
	MapInfo_FindName_match = _MapInfo_GlobItem(MapInfo_FilterList_Lookup(l));
	MapInfo_FindName_firstResult = l;
	// r == l, so: l is behind s, l-1 is before
	// SO: if there is any, l is the one with the right prefix
	//     and l+1 may be one too
	if(l == MapInfo_count)
	{
		MapInfo_FindName_match = string_null;
		MapInfo_FindName_firstResult = -1;
		return -1; // no MapInfo_FindName_match, behind last item
	}
	if(!startsWithNocase(MapInfo_FindName_match, s))
	{
		MapInfo_FindName_match = string_null;
		MapInfo_FindName_firstResult = -1;
		return -1; // wrong prefix
	}
	if(l == MapInfo_count - 1)
		return l; // last one, nothing can follow => unique
	if(startsWithNocase(_MapInfo_GlobItem(MapInfo_FilterList_Lookup(l + 1)), s))
	{
		MapInfo_FindName_match = string_null;
		return -1; // ambigous MapInfo_FindName_match
	}
	return l;
}

string MapInfo_FixName(string s)
{
	MapInfo_FindName(s);
	return MapInfo_FindName_match;
}

float MapInfo_CurrentFeatures()
{
	float req;
	req = 0;
	if(!(cvar("g_lms") || cvar("g_instagib") || cvar("g_minstagib") || cvar("g_nixnex") || cvar("g_rocketarena") || !cvar("g_pickup_items") || cvar("g_race") || cvar("g_cts") || cvar("g_nexball")))
		req |= MAPINFO_FEATURE_WEAPONS;
	return req;
}

float MapInfo_CurrentGametype()
{
	if(cvar("g_domination"))
		return MAPINFO_TYPE_DOMINATION;
	else if(cvar("g_total_domination"))
		return MAPINFO_TYPE_DOMINATION;
	else if(cvar("g_ctf"))
		return MAPINFO_TYPE_CTF;
	else if(cvar("g_runematch"))
		return MAPINFO_TYPE_RUNEMATCH;
	else if(cvar("g_tdm"))
		return MAPINFO_TYPE_TEAM_DEATHMATCH;
	else if(cvar("g_assault"))
		return MAPINFO_TYPE_ASSAULT;
	else if(cvar("g_lms"))
		return MAPINFO_TYPE_LMS;
	else if(cvar("g_arena"))
		return MAPINFO_TYPE_ARENA;
	else if(cvar("g_keyhunt"))
		return MAPINFO_TYPE_KEYHUNT;
	else if(cvar("g_onslaught"))
		return MAPINFO_TYPE_ONSLAUGHT;
	else if(cvar("g_race"))
		return MAPINFO_TYPE_RACE;
	else if(cvar("g_nexball"))
		return MAPINFO_TYPE_NEXBALL;
	else if(cvar("g_cts"))
		return MAPINFO_TYPE_CTS;
	else if(cvar("g_freezetag"))
		return MAPINFO_TYPE_CTF;
	else if(cvar("g_vip"))
		return MAPINFO_TYPE_CTF;
	else
		return MAPINFO_TYPE_DEATHMATCH;
}

float _MapInfo_CheckMap(string s) // returns 0 if the map can't be played with the current settings, 1 otherwise
{
	if(!MapInfo_Get_ByName(s, 1, 0))
		return 0;
	return 1;
	
	/*
	if((MapInfo_Map_supportedGametypes & MapInfo_CurrentGametype()) == 0)
		return 0;
	if((MapInfo_Map_supportedFeatures & MapInfo_CurrentFeatures()) != MapInfo_CurrentFeatures())
		return 0;
	return 1;
	*/
}

float MapInfo_CheckMap(string s) // returns 0 if the map can't be played with the current settings, 1 otherwise
{
	float r;
	r = _MapInfo_CheckMap(s);
	MapInfo_ClearTemps();
	return r;
}

string MapInfo_GetGameTypeCvar(float t)
{
	switch(t)
	{
		case MAPINFO_TYPE_DEATHMATCH: return "g_dm";
		case MAPINFO_TYPE_TEAM_DEATHMATCH: return "g_tdm";
		case MAPINFO_TYPE_DOMINATION: return "g_domination";
		case MAPINFO_TYPE_CTF: return "g_ctf";
		case MAPINFO_TYPE_RUNEMATCH: return "g_runematch";
		case MAPINFO_TYPE_LMS: return "g_lms";
		case MAPINFO_TYPE_ARENA: return "g_arena";
		case MAPINFO_TYPE_KEYHUNT: return "g_kh";
		case MAPINFO_TYPE_ASSAULT: return "g_assault";
		case MAPINFO_TYPE_ONSLAUGHT: return "g_onslaught";
		case MAPINFO_TYPE_RACE: return "g_race";
		case MAPINFO_TYPE_NEXBALL: return "g_nexball";
		case MAPINFO_TYPE_CTS: return "g_cts";
		default: return "";
	}
}

void MapInfo_SwitchGameType(float t)
{
	cvar_set("gamecfg",      "0");
	cvar_set("g_dm",         (t == MAPINFO_TYPE_DEATHMATCH)      ? "1" : "0");
	cvar_set("g_tdm",        (t == MAPINFO_TYPE_TEAM_DEATHMATCH) ? "1" : "0");
	cvar_set("g_domination", (t == MAPINFO_TYPE_DOMINATION)      ? "1" : "0");
	cvar_set("g_total_domination", (t == MAPINFO_TYPE_DOMINATION)      ? "1" : "0");
	cvar_set("g_ctf",        (t == MAPINFO_TYPE_CTF)             ? "1" : "0");
	cvar_set("g_runematch",  (t == MAPINFO_TYPE_RUNEMATCH)       ? "1" : "0");
	cvar_set("g_lms",        (t == MAPINFO_TYPE_LMS)             ? "1" : "0");
	cvar_set("g_arena",      (t == MAPINFO_TYPE_ARENA)           ? "1" : "0");
	cvar_set("g_keyhunt",    (t == MAPINFO_TYPE_KEYHUNT)         ? "1" : "0");
	cvar_set("g_assault",    (t == MAPINFO_TYPE_ASSAULT)         ? "1" : "0");
	cvar_set("g_onslaught",  (t == MAPINFO_TYPE_ONSLAUGHT)       ? "1" : "0");
	cvar_set("g_race",       (t == MAPINFO_TYPE_RACE)            ? "1" : "0");
	cvar_set("g_nexball",    (t == MAPINFO_TYPE_NEXBALL)         ? "1" : "0");
	cvar_set("g_cts",        (t == MAPINFO_TYPE_CTS)             ? "1" : "0");
	cvar_set("g_freezetag",  (t == MAPINFO_TYPE_CTF)             ? "1" : "0");
    cvar_set("g_vip",        (t == MAPINFO_TYPE_CTF)             ? "1" : "0");
}

void MapInfo_SwitchGameType_String(string gtname)
{
	MapInfo_SwitchGameType(MapInfo_Type_FromString(gtname));

	// TODO: remove this horrible mess

	if(gtname == "kh")
	{
		cvar_set("g_ctf", "0");
		cvar_set("g_freezetag", "0");
		cvar_set("g_domination", "0");
		cvar_set("g_total_domination", "0");
		cvar_set("g_vip", "0");
		cvar_set("g_dm", "0");
		cvar_set("g_tdm", "0");
        _is_key_hunt = 1;
	}
	else if(gtname == "ft")
	{
		cvar_set("g_ctf", "0");
		cvar_set("g_keyhunt", "0");
		cvar_set("g_domination", "0");
		cvar_set("g_total_domination", "0");
		cvar_set("g_vip", "0");
		cvar_set("g_dm", "0");
		cvar_set("g_tdm", "0");
        _is_key_hunt = 0;
	}
	else if(gtname == "ctf")
	{
		cvar_set("g_keyhunt", "0");
		cvar_set("g_freezetag", "0");
		cvar_set("g_domination", "0");
		cvar_set("g_total_domination", "0");
        cvar_set("g_vip", "0");
        cvar_set("g_dm", "0");
        cvar_set("g_tdm", "0");
		_is_key_hunt = 0;
	}
	else if(gtname == "dom")
	{
		cvar_set("g_keyhunt", "0");
		cvar_set("g_freezetag", "0");
		cvar_set("g_ctf", "0");
		cvar_set("g_total_domination", "0");
        cvar_set("g_vip", "0");
        cvar_set("g_dm", "0");
        cvar_set("g_tdm", "0");
		_is_key_hunt = 0;
	}
	else if(gtname == "totaldom")
	{
		cvar_set("g_keyhunt", "0");
		cvar_set("g_freezetag", "0");
		cvar_set("g_ctf", "0");
		cvar_set("g_total_domination", "1");
		cvar_set("g_domination", "1");
        cvar_set("g_vip", "0");
        cvar_set("g_dm", "0");
        cvar_set("g_tdm", "0");
		_is_key_hunt = 0;
	}
    else if(gtname == "vip")
    {
    	cvar_set("g_keyhunt", "0");
		cvar_set("g_freezetag", "0");
		cvar_set("g_ctf", "0");
		cvar_set("g_total_domination", "0");
		cvar_set("g_domination", "0");
		cvar_set("g_dm", "0");
		cvar_set("g_tdm", "0");
		_is_key_hunt = 0;
    }
    else if(gtname == "dm")
    {
		cvar_set("g_dm", "1");
		cvar_set("g_keyhunt", "0");
		cvar_set("g_freezetag", "0");
		cvar_set("g_ctf", "0");
		cvar_set("g_total_domination", "0");
		cvar_set("g_domination", "0");
		cvar_set("g_vip", "0");
		cvar_set("g_tdm", "0");
		_is_key_hunt = 0;
	}
	else if(gtname == "tdm")
    {
		cvar_set("g_tdm", "1");
		cvar_set("g_dm", "0");
		cvar_set("g_keyhunt", "0");
		cvar_set("g_freezetag", "0");
		cvar_set("g_ctf", "0");
		cvar_set("g_total_domination", "0");
		cvar_set("g_domination", "0");
		cvar_set("g_vip", "0");
		_is_key_hunt = 0;
	}
}

void MapInfo_LoadMap(string s)
{
	MapInfo_Map_supportedGametypes = 0;
	if(!MapInfo_CheckMap(s))
	{
		print("EMERGENCY: can't play the selected map in the given game mode. Falling back to DM.\n");
		//MapInfo_SwitchGameType(MAPINFO_TYPE_DEATHMATCH);
	}
	localcmd(strcat("\nsettemp_restore\nchangelevel ", s, "\n"));
}

string MapInfo_ListAllowedMaps(float pRequiredFlags, float pForbiddenFlags)
{
	string out;
	float i;

	// to make absolutely sure:
	MapInfo_Enumerate();
	MapInfo_FilterGametype(MapInfo_CurrentGametype(), MapInfo_CurrentFeatures(), pRequiredFlags, pForbiddenFlags, 0);

	out = "";
	for(i = 0; i < MapInfo_count; ++i)
		out = strcat(out, " ", _MapInfo_GlobItem(MapInfo_FilterList_Lookup(i)));
	return substring(out, 1, strlen(out) - 1);
}

void MapInfo_LoadMapSettings(string s) // to be called from worldspawn
{
	//print("^1MapInfo_LoadMapSettings\n");

	if(!_MapInfo_CheckMap(s)) // with underscore, it keeps temps
	#ifdef WE_GIVE_A_SHIT_ABOUT_MAPINFO
	{
		float t;
		if(MapInfo_Map_supportedGametypes <= 0)
		{
			//error("Mapinfo system is not functional at all. BAILED OUT.\n");
			#ifdef SVQC
			bprint("^1EVERYTHING IS FUCKED UP\n");
			bprint("^1EVERYTHING IS FUCKED UP\n");
			bprint("^1EVERYTHING IS FUCKED UP\n");
			#endif
			return;
		}

		t = 1;
		while(!(MapInfo_Map_supportedGametypes & 1))
		{
			t *= 2;
			MapInfo_Map_supportedGametypes = floor(MapInfo_Map_supportedGametypes / 2);
		}
		// t is now a supported mode!
		print("EMERGENCY: can't play the selected map in the given game mode. Falling back to a supported mode.\n");
		//MapInfo_SwitchGameType(t);
	}
	#else
		print("Warning: _MapInfo_CheckMap failed\n");
	#endif
	cvar_settemp_restore();
	MapInfo_Get_ByName(s, 1, MapInfo_CurrentGametype());
}

void MapInfo_ClearTemps()
{
	MapInfo_Map_bspname = string_null;
	MapInfo_Map_title = string_null;
	MapInfo_Map_description = string_null;
	MapInfo_Map_author = string_null;
	MapInfo_Map_clientstuff = string_null;
	MapInfo_Map_supportedGametypes = 0;
	MapInfo_Map_supportedFeatures = 0;
}

void MapInfo_Shutdown()
{
	MapInfo_ClearTemps();
	MapInfo_Filter_Free();
	MapInfo_Cache_Destroy();
	if(_MapInfo_globopen)
	{
		search_end(_MapInfo_globhandle);
		_MapInfo_globhandle = -1;
		_MapInfo_globopen = FALSE;
	}
}

float MapInfo_ForbiddenFlags()
{
	float f;
	f = MAPINFO_FLAG_FORBIDDEN;

#ifndef MENUQC
	if not(cvar("g_maplist_allow_hidden"))
#endif
		f |= MAPINFO_FLAG_HIDDEN;

	if not(cvar("g_maplist_allow_frustrating"))
		f |= MAPINFO_FLAG_FRUSTRATING;

	return f;
}

float MapInfo_RequiredFlags()
{
	float f;
	f = 0;

	if(cvar("g_maplist_allow_frustrating") > 1)
		f |= MAPINFO_FLAG_FRUSTRATING;

	return f;
}
