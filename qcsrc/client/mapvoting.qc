float mv_num_maps;

float mv_active;
string mv_maps[MAPVOTE_COUNT];
string mv_pics[MAPVOTE_COUNT];
string mv_pk3[MAPVOTE_COUNT];
float mv_preview[MAPVOTE_COUNT];
float mv_votes[MAPVOTE_COUNT];
float mv_avail[MAPVOTE_COUNT];
entity mv_pk3list;
float mv_abstain;
float mv_ownvote;
float mv_detail;
float mv_timeout;
float mv_maps_mask;

void MapVote_RememberMap(string mname)
{
	mapvote_choosenmap 		= strzone(mname);
	mapvote_choosenmappic 	= strzone(strcat("maps/", mname));
	//print("mapvote_choosenmappic = ", mapvote_choosenmappic, "\n");
}

string MapVote_FormatMapItem(float id, string map, float count, float maxwidth)
{
	string pre, post;
	pre = strcat(ftos(id+1), ". ");
	if(mv_detail)
	{
		if(count == 1)
			post = strcat(" (1 vote)");
		else
			post = strcat(" (", ftos(count), " votes)");
	}
	else
		post = "";
	maxwidth -= stringwidth(pre, FALSE) + stringwidth(post, FALSE);
	map = textShortenToWidth(map, maxwidth, stringwidth_nocolors);
	return strcat(pre, map, post);
}

vector MapVote_RGB(float id)
{
	if(id == mv_ownvote)
		return '1 1 0';
	else
		return '1 1 1';
}

string GameTypeVote_GameTypeName(string gtype)
{
	/*
	switch(gtype)
	{
		case "ctf":
			return "Capture the Flag";
		case "kh":
			return "Key Hunt";
		case "ft":
			return "Freeze Tag";
		case "dom":
			return "Domination";
		case "totaldom":
			return "Total Domination";
		case "vip":
			return "VIP";
		case "dm":
			return "Deathmatch";
		case "tdm":
			return "Team Deathmatch";
	}

	return strcat(gtype, " (unknown gametype?!)");
	*/
	
	return GametypeFullNameFromName(gtype);
}

string GameTypeVote_GameTypeDescription(string gtype)
{
	switch(gtype)
	{
		case "ctf":
			return "Each team has a flag located in its base.\nYou must steal the enemy flag and bring it to yours to score.";
		case "kh":
			return "Every team begins the round with one key.\nSteal all the keys and bring them together to score.";
		case "ft":
			return "Frag your opponents to turn them into ice blocks.\nFreeze the entire opposite team to win the round.\nYou can unfreeze your frozen teammates by standing next to them.";
		case "dom":
			return "Several control points are placed around the map.\nWalk over a control point to capture it.\nWhile captured, control points keep adding to your score until the limit is reached.";
		case "totaldom":
			return "A round-based Domination spin-off.\nYou must take over ALL of the control points on the map to win the round.";
		case "vip":
			return "Each team gets a VIP player (as in Very Important Person).\nYou must kill the enemy VIP to win the round.";
		case "dm":
			return "Free-for-all: the player who gets the most frags wins.";
		case "tdm":
			return "Team-based deathmatch: the team that gets the most frags wins.";
	}

	return "No description is available for this gametype";
}

string GameTypeVote_DescriptionByID(float id)
{
	switch(mv_avail[id])
	{
		case GTV_AVAILABLE:
			return GameTypeVote_GameTypeDescription(mv_maps[id]);

		case GTV_OVERPLAYED:
			return "This gametype is currently overplayed.";

		case GTV_FORBIDDEN:
			return "This gametype is forbidden on this map.";

		default:
			return "wtf?";
	}
}

#define drawGameTypeLine(s,c,sc,a) \
drawstring(o, (s), sbar_fontsize * (sc), (c), a, DRAWFLAG_NORMAL); \
o_y += sbar_fontsize_y * sc

vector GameTypeVote_DrawGametypeItem(vector o, string gtype, float count, float id)
{
	local string s;
	s = GameTypeVote_DescriptionByID(id);

	local float a, i, n = tokenizebyseparator(s, "\n");
	if(mv_avail[id] != GTV_AVAILABLE)
		a = 0.5;
	else
		a = 1;

	drawGameTypeLine(MapVote_FormatMapItem(id, GameTypeVote_GameTypeName(gtype), count, 500), MapVote_RGB(id), 1.2, a);
	for(i = 0; i < n; ++i)
	{
		drawGameTypeLine(argv(i), '1 1 1', 1, a);
	}

	drawGameTypeLine("", '1 1 1', 1, 1);
	return o;
}

void MapVote_DrawMapItem(vector pos, float isize, float tsize, string map, string pic, float count, float id)
{
	vector img_size;
	vector rgb;
	string label;
	float text_size;

	isize -= sbar_fontsize_y; // respect the text when calculating the image size

	rgb = MapVote_RGB(id);

	img_size_y = isize;
	img_size_x = isize / 0.75; // 4:3 x can be stretched easily, height is defined in isize

	drawfont = sbar_font;
	pos_y = pos_y + img_size_y;

	label = MapVote_FormatMapItem(id, map, count, tsize / sbar_fontsize_x);

	text_size = stringwidth(label, false) * sbar_fontsize_x;

	pos_x -= text_size*0.5;
	drawstring(pos, label, sbar_fontsize, rgb, 1, DRAWFLAG_NORMAL);

	pos_x = pos_x + text_size*0.5 - img_size_x*0.5;
	pos_y = pos_y - img_size_y;

	pos += sbar_border_thickness * '1 1 0';
	img_size -= (sbar_border_thickness * 2) * '1 1 0';
	if(pic == "")
	{
		drawfill(pos, img_size, '.5 .5 .5', .7, DRAWFLAG_NORMAL);
	}
	else
	{
		drawpic(pos, pic, img_size, '1 1 1', 1, DRAWFLAG_NORMAL);
	}

	drawpic(pos + '1 0 0', strcat("gfx/hud/num_", ftos(id+1)), (img_size_y / 5) * '1 1 0', '1 1 1', 0.6, DRAWFLAG_NORMAL);

	if(id == mv_ownvote || pic == "")
	{
		drawborderlines(sbar_border_thickness, pos, img_size, rgb, 1, DRAWFLAG_NORMAL);
		drawpic(pos + '1 0 0', strcat("gfx/hud/num_", ftos(id+1)), (img_size_y / 5) * '1 1 0', rgb, 0.6, DRAWFLAG_NORMAL);
	}
	else
	{
		drawborderlines(sbar_border_thickness, pos, img_size, '0 0 0', 1, DRAWFLAG_NORMAL);
		drawpic(pos + '1 0 0', strcat("gfx/hud/num_", ftos(id+1)), (img_size_y / 5) * '1 1 0', '1 1 1', 0.6, DRAWFLAG_NORMAL);
	}
}

void MapVote_DrawAbstain(vector pos, float isize, float tsize, float count, float id)
{
	vector rgb;
	float text_size;
	string label;

	rgb = MapVote_RGB(id);

	drawfont = sbar_font;
	pos_y = pos_y + sbar_fontsize_y;

	label = MapVote_FormatMapItem(id, "Don't care", count, tsize / sbar_fontsize_x);

	text_size = stringwidth(label, false) * sbar_fontsize_x;

	pos_x -= text_size*0.5;
	drawstring(pos, label, sbar_fontsize, rgb, 1, DRAWFLAG_NORMAL);
}

vector MapVote_GridVec(vector gridspec, float i, float m)
{
	float r;
	r = mod(i, m);
	return
		'1 0 0' * (gridspec_x * r)
		+
		'0 1 0' * (gridspec_y * (i - r) / m);
}

void MapVote_Draw()
{
	string map;
	float i, tmp;
	vector pos;
	float isize;
	float center;
	float columns, rows;
	float tsize;
	vector dist;

	if(!mv_active)
		return;

	center = (vid_conwidth - 1)/2;
	xmin = vid_conwidth*0.05; // 5% border must suffice
	xmax = vid_conwidth - xmin;
	ymin = 20;
	i = cvar("con_chatpos"); //*cvar("con_chatsize");
	if(i < 0)
		ymax = vid_conheight + (i - cvar("con_chat")) * cvar("con_chatsize");
	if(i >= 0 || ymax < (vid_conheight*0.5))
		ymax = vid_conheight - ymin;

	drawfont = sbar_bigfont;
	sbar_fontsize = Sbar_GetFontsize("sbar_fontsize");

	pos_y = ymin;
	pos_z = 0;
	pos_x = center - stringwidth((gametypevote? "Decide the gametype" : "Vote for a map"), false) * 0.5 * 24;
	drawstring(pos, (gametypevote? "Decide the gametype" : "Vote for a map"), '24 24 0', '1 1 1', 1, DRAWFLAG_NORMAL);
	pos_y += 26;

	i = ceil(max(0, mv_timeout - time));
	map = strcat(ftos(i), " seconds left");
	pos_x = center - stringwidth(map, false) * 0.5 * 16;
	drawstring(pos, map, '16 16 0', '0 1 0', 1, DRAWFLAG_NORMAL);
	pos_y += 22;
	pos_x = xmin;

	drawfont = sbar_font;

	// base for multi-column stuff...
	ymin = pos_y;
	if(mv_abstain)
		mv_num_maps -= 1;

	if(mv_num_maps > 3)
	{
		columns = 3;
	} else {
		columns = mv_num_maps;
	}
	rows = ceil(mv_num_maps / columns);

	dist_x = (xmax - xmin) / columns;
	dist_y = (ymax - pos_y) / rows;
	tsize = dist_x - 10;
	isize = min(dist_y - 10, 0.75 * tsize);

	pos_x += (xmax - xmin) / (2 * columns);
	pos_y += (dist_y - isize) / 2;
	ymax -= isize;

	local vector o;

	if(gametypevote)
	{
		// draws the picked map

		vector img_size;
		img_size_y = isize;
		img_size_x = isize / 0.75;

		o_x = min(
			vid_conwidth * 0.5 + (sbar_fontsize_x * gametypevote_longest) * 0.25,
			vid_conwidth - sbar_fontsize_x - img_size_x
		);

		o_y = sbar_fontsize_y * 10;

		drawborderlines(sbar_border_thickness, o, img_size, '0 0 0', 1, DRAWFLAG_NORMAL);

		if(mapvote_choosenmappic == "")
		{
			drawfill(o, img_size, '.5 .5 .5', .7, DRAWFLAG_NORMAL);
		}
		else
		{
			drawpic(o, mapvote_choosenmappic, img_size, '1 1 1', 1, DRAWFLAG_NORMAL);
		}

		o_y += img_size_y;
		o_x += img_size_x / 2 - ((stringwidth_nocolors(mapvote_choosenmap) / 2) * sbar_fontsize_x);

		drawstring(o, mapvote_choosenmap, sbar_fontsize, '1 1 1', 1, DRAWFLAG_NORMAL);
	}

	o_x = max(vid_conwidth * 0.5 - (sbar_fontsize_x * gametypevote_longest) * 0.5, sbar_fontsize_x);
	o_y = sbar_fontsize_y * 10;

	for(i = 0; i < mv_num_maps; ++i)
	{
		tmp = mv_votes[i]; // FTEQCC bug: too many array accesses in the function call screw it up
		if(tmp < 0)
			continue;
		map = mv_maps[i];

		if(gametypevote)
		{
			o = GameTypeVote_DrawGametypeItem(o, map, tmp, i);
		}
		else
		{
			if(mv_preview[i])
				MapVote_DrawMapItem(pos + MapVote_GridVec(dist, i, columns), isize, tsize, map, mv_pics[i], tmp, i);
			else
				MapVote_DrawMapItem(pos + MapVote_GridVec(dist, i, columns), isize, tsize, map, "", tmp, i);
		}
	}

	if(mv_abstain)
		++mv_num_maps;

	if(mv_abstain && i < mv_num_maps) {
		tmp = mv_votes[i];
		pos_y = ymax + isize - sbar_fontsize_y;
		pos_x = (xmax+xmin)*0.5;
		MapVote_DrawAbstain(pos, isize, xmax - xmin, tmp, i);
	}
}

void Cmd_MapVote_MapDownload(float argc)
{
	float id;
	entity pak;

	if(argc != 2 || !mv_pk3list)
	{
		print("mv_mapdownload: ^3You're not supposed to use this command on your own!\n");
		return;
	}

	id = stof(argv(1));
	for(pak = mv_pk3list; pak; pak = pak.chain)
		if(pak.sv_entnum == id)
			break;

	if(!pak || pak.sv_entnum != id) {
		print("^1Error:^7 Couldn't find pak index.\n");
		return;
	}

	//print(strcat("^3Adding: ", ftos(id), " - ", pak.message, " - "));

	if(PreviewExists(pak.message))
	{
		mv_preview[id] = true;
		//print("^2Found...\n");
		return;
	} else {
		print("Requesting preview...\n");
		localcmd(strcat("\ncmd mv_getpic ", ftos(id), "\n"));
	}
}

void MapVote_CheckPK3(string pic, string pk3, float id)
{
	entity pak;
	pak = spawn();
	pak.netname = pk3;
	pak.message = pic;
	pak.sv_entnum = id;

	pak.chain = mv_pk3list;
	mv_pk3list = pak;

	if(pk3 != "")
	{
		localcmd(strcat("\ncurl --pak ", pk3, "; wait; cl_cmd mv_download ", ftos(id), "\n"));
	}
	else
	{
		Cmd_MapVote_MapDownload(tokenize_console(strcat("mv_download ", ftos(id))));
	}
}

void MapVote_CheckPic(string pic, string pk3, float id)
{
	// never try to retrieve a pic for the "don't care" 'map'
	if(mv_abstain && id == mv_num_maps - 1)
		return;

	if(PreviewExists(pic))
	{
		mv_preview[id] = true;
		return;
	}
	MapVote_CheckPK3(pic, pk3, id);
}

void MapVote_Init()
{
	float i, n, j, power, tmp;
	string map, pk3, ssdir;

	precache_sound ("misc/invshot.wav");

	registercmd("+showscores");
	registercmd("-showscores");

	mv_active = 1;

	ssdir = ReadString();

	mv_num_maps = min(MAPVOTE_COUNT, ReadByte());
	mv_abstain = ReadByte();
	if(mv_abstain)
		mv_abstain = 1; // must be 1 for bool-true, makes stuff easier
	mv_detail = ReadByte();

	mv_ownvote = -1;
	mv_timeout = ReadCoord();

	gametypevote = ReadByte();

	if(gametypevote)
	{
		print("^5Now decide the GAMETYPE!\n");
		MapVote_RememberMap(ReadString());
	}

	if(mv_num_maps <= 8)
		mv_maps_mask = ReadByte();
	else
		mv_maps_mask = ReadShort();

	// Assume mv_pk3list is NULL, there should only be 1 mapvote per round
	mv_pk3list = NULL; // I'm still paranoid!

	for(i = 0, power = 1; i < mv_num_maps; ++i, power *= 2)
	{
		mv_votes[i] = 0;

		if(mv_maps_mask & power)
		{
			map = strzone(ReadString());
			pk3 = strzone(ReadString());
			mv_maps[i] = map;
			mv_pk3[i] = pk3;
			map = strzone(strcat(ssdir, "/", map));
			mv_pics[i] = map;

			mv_preview[i] = false;

			//print(strcat("RECV: ", map, " in ", pk3, "\n"));
			MapVote_CheckPic(map, pk3, i);

			if(gametypevote)
			{
				mv_avail[i] = ReadByte();

				map = mv_maps[i];
				n = tokenizebyseparator(GameTypeVote_DescriptionByID(i), "\n");
				for(j = 0; j < n; ++j)
				{
					tmp = strlen(argv(j));
					if(tmp > gametypevote_longest)
						gametypevote_longest = tmp;
				}
			}
		}
		else
		{
			mv_maps[i] = strzone("if-you-see-this-the-code-is-broken");
			mv_pk3[i] = strzone("if-you-see-this-the-code-is-broken");
			mv_pics[i] = strzone("if-you-see-this-the-code-is-broken");
			mv_preview[i] = false;
			mv_avail[i] = false;
		}
	}

	// do we NEED this, or can we handle key presses directly in CSQC?
	localcmd("\nin_bind 7 1 \"impulse 1\"; in_bind 7 2 \"impulse 2\"; in_bind 7 3 \"impulse 3\"; in_bind 7 4 \"impulse 4\"; in_bind 7 5 \"impulse 5\"; in_bind 7 6 \"impulse 6\"; in_bind 7 7 \"impulse 7\"; in_bind 7 8 \"impulse 8\"; in_bind 7 9 \"impulse 9\"; in_bind 7 0 \"impulse 10\"; in_bind 7 KP_1 \"impulse 1\"; in_bind 7 KP_2 \"impulse 2\"; in_bind 7 KP_3 \"impulse 3\"; in_bind 7 KP_4 \"impulse 4\"; in_bind 7 KP_5 \"impulse 5\"; in_bind 7 KP_6 \"impulse 6\"; in_bind 7 KP_7 \"impulse 7\"; in_bind 7 KP_8 \"impulse 8\"; in_bind 7 KP_9 \"impulse 9\"; in_bind 7 KP_0 \"impulse 10\"; in_bindmap 7 0\n");


}

void MapVote_UpdateMask()
{
	float i, power;
	float oldmask;

	oldmask = mv_maps_mask;
	if(mv_num_maps <= 8)
		mv_maps_mask = ReadByte();
	else
		mv_maps_mask = ReadShort();

	if(oldmask & mv_maps_mask != oldmask)
		if(oldmask & mv_maps_mask == mv_maps_mask)
			 sound(world, CHAN_AUTO, "misc_invshot.wav", VOL_BASE, ATTN_NONE);

	// remove votes that no longer apply
	for(i = 0, power = 1; i < mv_num_maps; ++i, power *= 2)
		if not(mv_maps_mask & power)
			mv_votes[i] = -1;
}

void MapVote_UpdateVotes()
{
	float i, power;
	for(i = 0, power = 1; i < mv_num_maps; ++i, power *= 2)
	{
		if(mv_maps_mask & power)
		{
			if(mv_detail)
				mv_votes[i] = ReadByte();
			else
				mv_votes[i] = 0;
		}
		else
			mv_votes[i] = -1;
	}

	mv_ownvote = ReadByte()-1;
}

void Ent_MapVote()
{
	float sf;

	sf = ReadByte();

	if(sf & 1)
		MapVote_Init();

	if(sf & 2)
		MapVote_UpdateMask();

	if(sf & 4)
		MapVote_UpdateVotes();
}

void Net_MapVote_Picture()
{
	float type;
	type = ReadByte();
	mv_preview[type] = true;
	mv_pics[type] = strzone(ReadPicture());
}
