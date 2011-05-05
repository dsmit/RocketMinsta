
void vip_removegem(entity g)
{
	remove(g.enemy);
	remove(g);
}

void vip_ClearSoulGems()
{
	if(vip_redgem)
		vip_removegem(vip_redgem);
	
	if(vip_bluegem)
		vip_removegem(vip_bluegem);
}

void vip_RespawnSoulGems()
{
	if(!vip_soulgem)
		return;
	
	//vip_ClearSoulGems();
	//vip_SpawnSoulGem(redgem_loc, COLOR_TEAM1);
	//vip_SpawnSoulGem(bluegem_loc, COLOR_TEAM2);
	
	vip_redgem.reset2();
	vip_bluegem.reset2();
}

void vip_delayedinit()
{
	if(vip_soulgem)
	{
		if(!vip_redgem || !vip_bluegem)
		{
			bprint("^5Can't spawn soulgems on this map, falling back to random selection!\n");
			vip_ClearSoulGems();
			vip_soulgem = 0;
		}
	}
	
	if(inWarmupStage)
		vip_AssignVIPs();
	else
		defer(time + cvar("g_start_delay"), vip_AssignVIPs);
	
	vip_started = !vip_soulgem;
}

vector vip_SoulGemColormod(float theteam)
{
	switch(theteam)
	{
		case COLOR_TEAM1:
			return '1 .8 .8';
		case COLOR_TEAM2:
			return '.8 .8 1';
		default:
			return '.2 .2 .2';
	}
}

vector vip_SoulGemColormod2(float theteam)
{
	switch(theteam)
	{
		case COLOR_TEAM1:
			return '1 .4 .4';
		case COLOR_TEAM2:
			return '.4 .4 1';
		default:
			return '.1 .1 .1';
	}
}

void vip_SoulGem_touch()
{
	if(other.classname != "player")
		return;
	
	if(self.gem_pickedup)
		return;
	
	if(other.team != self.team)
		return;
	
	switch(other.team)
	{
		case COLOR_TEAM1:
			vip_AssignCustomRedVIP(other);
			break;
		case COLOR_TEAM2:
			vip_AssignCustomBlueVIP(other);
			break;
	}
	
	if(redvip && bluevip)
	{
		local entity e;
		FOR_EACH_PLAYER(e)
		{
			bigprint_clear_spec(e);
			bigprint_spec(e, "^5Begin!", "", 1);
			
			local entity oldself;
			oldself = self;
			self = e;
			PutClientInServer();
			self = oldself;
			
			if(ISVIP(e))
				vip_ResetHealthArmor(e);
		}
		vip_started = 1;
	}
	
	//vip_removegem(self);
	self.gem_pickedup = 1;
	self.alpha = 0;
	self.enemy.alpha = 0;
	self.colormod = vip_SoulGemColormod(-self.team);
	self.enemy.colormod = vip_SoulGemColormod2(-self.team);
	
	if(self.waypointsprite_attached)
		WaypointSprite_Kill(self.waypointsprite_attached);
}

void WHAT_THE_FUCK_think()
{
	vip_SpawnSoulGem(self.origin, self.team);
	remove(self);
}

void vip_SoulGem_reset()
{
	self.gem_pickedup = 0;
	self.alpha = self.enemy.alpha = 0.8;
	self.colormod = vip_SoulGemColormod(self.team);
	self.enemy.colormod = vip_SoulGemColormod2(self.team);
	
	// "run here" waypoint
	if(!self.waypointsprite_attached)
		WaypointSprite_Spawn("keycarrier-finish", 0, 0, self, '0 0 64', world, self.team, self, waypointsprite_attached, TRUE);
}

void vip_SpawnSoulGem(vector orig, float theteam)
{
	if(!vip_soulgem)
		return;
	
	bprint("vip_SpawnSoulGem(", vtos(orig), ", ", ftos(theteam), ")\n");
	
	local entity e;
	e = spawn();
	e.classname = "vip_soulgem";
	e.target = "###item###";
	e.team = theteam;
	e.movetype = MOVETYPE_NONE;
	e.touch = vip_SoulGem_touch;
	e.solid = SOLID_TRIGGER;
	e.flags = FL_ITEM;
	e.reset2 = vip_SoulGem_reset;
	setmodel(e, "models/runematch/rune.mdl");
	setsize(e, '0 0 -35', '0 0 0');
	
	e.enemy = spawn();
	e.enemy.enemy = e;
	e.enemy.classname = "vip_soulgem_effect";
	setmodel(e.enemy, "models/runematch/curse.mdl");
	e.origin = orig;
	//setorigin(e, e.origin);
	e.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_PLAYERCLIP;
	setorigin (e, e.origin);
	setattachment(e.enemy, e, "");

	if (!move_out_of_solid(e))
		bprint("\x01^!WARNING: ^7failed to move soulgem out of solid, expect weird shit and breakages\n");
	
	local entity oldself;
	oldself = self;
	self = e;
	droptofloor();
	self = oldself;

	e.colormod = vip_SoulGemColormod(theteam);
	e.enemy.colormod = vip_SoulGemColormod2(theteam);

	e.alpha = e.enemy.alpha = 0.8;
	e.effects = e.enemy.effects = (EF_ADDITIVE | EF_FULLBRIGHT);
	
	
	
	// "run here" waypoint
	if(!e.waypointsprite_attached)
		WaypointSprite_Spawn("keycarrier-finish", 0, 0, e, '0 0 64', world, e.team, e, waypointsprite_attached, TRUE);
	
	//MoveToRandomMapLocation(e, DPCONTENTS_SOLID | DPCONTENTS_CORPSE | DPCONTENTS_PLAYERCLIP, DPCONTENTS_SLIME | DPCONTENTS_LAVA | DPCONTENTS_SKY | DPCONTENTS_BODY | DPCONTENTS_DONOTENTER, Q3SURFACEFLAG_SKY, 10, 1024, 256);
	
	switch(theteam)
	{
		case COLOR_TEAM1:
			if(vip_redgem)
				vip_removegem(vip_redgem);
			
			if(redgem_loc == '0 0 0')
				redgem_loc = e.origin;
			
			vip_redgem = e;
			//bprint("vid_redgem is a ", vip_redgem.classname, " at ", vtos(vip_redgem.origin), "\n");
			//bprint("vid_bluegem is a ", vip_bluegem.classname, " at ", vtos(vip_bluegem.origin), "\n");
			//bprint("e is a ", e.classname, " at ", vtos(e.origin), "\n");
			
			/// HOLY FUCKING COCKS FROM HELL
			/// THIS SHIT BLOWS MY MIIIIND
			if(e.origin != redgem_loc)
			{
				bprint("^1WTF?!?!?!??!?!?!??!\n");
				vip_removegem(e);
				
				local entity WHAT_THE_FUCK = spawn();
				WHAT_THE_FUCK.think = WHAT_THE_FUCK_think;
				WHAT_THE_FUCK.team = theteam;
				WHAT_THE_FUCK.origin = orig;
				WHAT_THE_FUCK.nextthink = time + 0.01;
			}
			
			return;
		case COLOR_TEAM2:
			if(vip_bluegem)
				vip_removegem(vip_bluegem);
			
			if(bluegem_loc == '0 0 0')
				bluegem_loc = e.origin;
			vip_bluegem = e;
			
			/// HOLY FUCKING COCKS FROM HELL
			/// THIS SHIT BLOWS MY MIIIIND
			if(e.origin != bluegem_loc)
			{
				bprint("^4WTF?!?!?!??!?!?!??!\n");
				vip_removegem(e);
				
				local entity WHAT_THE_FUCK = spawn();
				WHAT_THE_FUCK.think = WHAT_THE_FUCK_think;
				WHAT_THE_FUCK.team = theteam;
				WHAT_THE_FUCK.origin = orig;
				WHAT_THE_FUCK.nextthink = time + 0.01;
			}

			return;
		default:
			error(strcat("Tried to spawn a Soul Gem for an invalid team ", ftos(theteam)));
	}
}

void vip_init()
{
    if(inWarmupStage)
        warmup = time;
    else
        warmup = time + cvar("g_start_delay");
    
    precache_sound("ctf/red_capture.wav");
    precache_sound("ctf/blue_capture.wav");
    ScoreRules_vip();
	
	vip_soulgem = cvar("g_explosive_vip_soulgem");
	
	if(vip_soulgem)
	{
		precache_model("models/runematch/curse.mdl");
		precache_model("models/runematch/rune.mdl");
	}
	precache_sound("kh/capture.wav");
	InitializeEntity(world, vip_delayedinit, INITPRIO_GAMETYPE);
}

void vip_EndRound_Think()
{
    local float timeleft = rint(self.cnt - time);
    
    if(intermission_running)
    {
        remove(self);
        return;
    }
    
    update_playercount();
    
    if(timeleft <= cvar("g_explosive_vip_warmup"))
    {
        if(timeleft <= 0)
        {
            local entity e;
            FOR_EACH_PLAYER(e)
            {
                bigprint_clear_spec(e);
                bigprint_spec(e, "^5Begin!", "", 1);
            }
            vip_started = 1;
            vip_AssignVIPs();
            remove(self);
            return;
        }
        
        vip_started = 0;
        vip_ended = 0;
        
        local entity e;
        FOR_EACH_PLAYER(e)
        {
            bigprint_clear_spec(e);
            bigprint_spec(e, strcat("vip starts in: ", ftos(timeleft)), "", 1);
        }
    }
    self.nextthink = time + 1;
}

void vip_EndRound()
{
	next_round = time + 5;
	
	if(!vip_soulgem)
	{
		local entity e = spawn();
		e.think = vip_EndRound_Think;
		e.nextthink = time + 1;
		e.cnt = cvar("g_explosive_vip_warmup") + next_round;
	}
	else
		defer(5.1, vip_SoulGem_StartRound);
    
    update_playercount();
    defer(5.1, vip_ClearVIPs);
    //vip_started = 0;
    vip_ended = 1;
}

void vip_SoulGem_StartRound()
{
	if(!redvip || !bluevip)
	{
		local entity e;
		FOR_EACH_PLAYER(e)
		{
			vip_started = 0;
			vip_ended = 0;
			
			bigprint_clear_spec(e);
			
			if(ISVIP(e))
				bigprint_spec(e, "waiting for an enemy VIP", "", 5);
			else
				bigprint_spec(e, "waiting for VIPs", "Pickup your Soul Gem to become a VIP", 5);
		}
		
		defer(5, vip_SoulGem_StartRound);
	}
}

entity vip_PickRedVIP()
{
	local float players;
	players = 0;
	entity my_player, player;
	
	FOR_EACH_PLAYER(player)
		if(player.deadflag == DEAD_NO)
			if(player.team == COLOR_TEAM1)
			{
				++players;
				if(random() * players <= 1)
					my_player = player;
			}
	
	return my_player;
}

entity vip_PickBlueVIP()
{
	local float players;
	players = 0;
	entity my_player, player;
	
	FOR_EACH_PLAYER(player)
		if(player.deadflag == DEAD_NO)
			if(player.team == COLOR_TEAM2)
			{
				++players;
				if(random() * players <= 1)
					my_player = player;
			}
	
	return my_player;
}

float vip_EnemiesMultiplier(entity pl, string cvarname)
{
	local entity e;
	local float c;
	
	if(!cvar(cvarname))
		return 1;
	
	FOR_EACH_PLAYER(e) if(e.team != pl.team)
		++c;
	
	return (c? c : 1); //NEVER return 0 here
}

void vip_RegenerateHealth()
{
	self.owner.vip_maxhealth = cvar("g_explosive_vip_health") * vip_EnemiesMultiplier(self.owner, "g_explosive_vip_health_dependonenemies");
	
	self.owner.health = min(self.owner.health + cvar("g_explosive_vip_regenerate_health_amount"),
		self.owner.vip_maxhealth
	);
	
	self.nextthink = time + cvar("g_explosive_vip_regenerate_health_delay");
}

void vip_RegenerateArmor()
{
	self.owner.vip_maxarmor = cvar("g_explosive_vip_armor") * vip_EnemiesMultiplier(self.owner, "g_explosive_vip_armor_dependonenemies");
	
	self.owner.armorvalue = min(self.owner.armorvalue + cvar("g_explosive_vip_regenerate_armor_amount"),
		self.owner.vip_maxarmor
	);
	
	self.nextthink = time + cvar("g_explosive_vip_regenerate_armor_delay");
}

void vip_RegenerateExtra()
{
	self.owner.vip_maxarmor = cvar("g_explosive_vip_extralives") * vip_EnemiesMultiplier(self.owner, "g_explosive_vip_extralives_dependonenemies");
	
	self.owner.armorvalue = min(self.owner.armorvalue + cvar("g_explosive_vip_regenerate_extra_amount"),
		self.owner.vip_maxarmor
	);
	
	self.nextthink = time + cvar("g_explosive_vip_regenerate_extralives_delay");
}

void vip_UpdateState_Health()
{
	if(self.owner.waypointsprite_attached)
	{
		WaypointSprite_UpdateMaxHealth(self.owner.waypointsprite_attached, self.owner.vip_maxhealth );
		WaypointSprite_UpdateHealth(self.owner.waypointsprite_attached, self.owner.health);
	}
	
	self.nextthink = 0.1;
}

void vip_FixVIPState()
{
	if(ISVIP(self.owner)) //nothing to fix
		return;
	
	vip_ClearVIP_Common(self.owner);
	
	if(self.owner.waypointsprite_attached)
	{
		bprint("^1FAILED to fix ", self.owner.netname, "^1, what the FUCK is going on?!\n");
		
		local entity oldself;
		oldself = self;
		self = self.owner;
		defer(0.1, vip_FixVIPState);
		self = oldself;
	}
	
	print("^2Hopefully fixed ", self.owner.netname, "\n");
}

void vip_UpdateState()
{
	if(!ISVIP(self.owner))
	{
		print("^1CALLED vip_UpdateState FOR A REGULAR PLAYER: ^7", self.owner.netname, ",^1, ATTEMPTING TO FIX VIP STATE!\n");
		//vip_ClearVIP_Common(self.owner);
		vip_FixVIPState();
		return;
	}
	
	self.use();
}

void vip_UpdateState_Armor()
{
	if(self.owner.waypointsprite_attached)
	{
		WaypointSprite_UpdateMaxHealth(self.owner.waypointsprite_attached, self.owner.vip_maxhealth * cvar("g_explosive_armor_factor") + self.owner.vip_maxarmor);
		WaypointSprite_UpdateHealth(self.owner.waypointsprite_attached, self.owner.health * cvar("g_explosive_armor_factor") + self.owner.armorvalue);
	}
	
	self.nextthink = 0.1;
}

void vip_UpdateState_Extras()
{
	if(self.owner.waypointsprite_attached)
	{
		WaypointSprite_UpdateMaxHealth(self.owner.waypointsprite_attached, self.owner.vip_maxarmor);
		WaypointSprite_UpdateHealth(self.owner.waypointsprite_attached, self.owner.armorvalue);
	}
	
	self.nextthink = 0.1;
}

void vip_MakePlayerVIP(entity pl)
{
	// start health/armor regeneration
	
	if(pl.vip_health_regenerator)
	{
		print("vip_MakePlayerVIP on player with vip_health_regenerator: ", pl.netname, "\n");
		remove(pl.vip_health_regenerator);
	}
	
	if(pl.vip_armor_regenerator)
	{
		print("vip_MakePlayerVIP on player with vip_armor_regenerator: ", pl.netname, "\n");
		remove(pl.vip_armor_regenerator);
	}
	
	if(pl.vip_armor_regenerator)
	{
		print("vip_MakePlayerVIP on player with vip_state_updater: ", pl.netname, "\n");
		remove(pl.vip_state_updater);
	}
	
	if(pl.waypointsprite_attached)
	{
		print("vip_MakePlayerVIP on player with waypointsprite_attached: ", pl.netname, "\n");
		WaypointSprite_Kill(pl.waypointsprite_attached);
	}
	
	pl.vip_state_updater = spawn();
	pl.vip_state_updater.owner = pl;
	pl.vip_state_updater.nextthink = time + 0.1;
	pl.vip_state_updater.think = vip_UpdateState;
	
	if(cvar("g_balance_minstanex_explosive"))
	{
		pl.vip_maxhealth = cvar("g_explosive_vip_health") * vip_EnemiesMultiplier(pl, "g_explosive_vip_health_dependonenemies");
		
		if(cvar("g_explosive_vip_regenerate_health"))
		{
			pl.vip_health_regenerator = spawn();
			pl.vip_health_regenerator.owner = pl;
			pl.vip_health_regenerator.think = vip_RegenerateHealth;
			pl.vip_health_regenerator.nextthink = time + cvar("g_explosive_vip_regenerate_health_delay");
		}
	}
	
	if(cvar("g_balance_minstanex_explosive") && cvar("g_explosive_armor"))
	{
		pl.vip_maxarmor = cvar("g_explosive_vip_armor") * vip_EnemiesMultiplier(pl, "g_explosive_vip_armor_dependonenemies");
		
		if(cvar("g_explosive_vip_regenerate_armor"))
		{
			pl.vip_armor_regenerator = spawn();
			pl.vip_armor_regenerator.owner = pl;
			pl.vip_armor_regenerator.think = vip_RegenerateArmor;
			pl.vip_armor_regenerator.nextthink = time + cvar("g_explosive_vip_regenerate_health_delay");
		}
		
		pl.vip_state_updater.use = vip_UpdateState_Armor;
	}
	else // in minstagib, we will just give him a bunch of extralives
	{
		pl.vip_maxarmor = cvar("g_explosive_vip_extralives") * vip_EnemiesMultiplier(pl, "g_explosive_vip_extralives_dependonenemies");
		
		if(pl.vip_maxarmor)
			pl.vip_state_updater.use = vip_UpdateState_Extras;
		else
			pl.vip_state_updater.use = vip_UpdateState_Health;
		
		if(cvar("g_explosive_vip_regenerate_extra"))
		{
			pl.vip_armor_regenerator = spawn();
			pl.vip_armor_regenerator.owner = pl;
			pl.vip_armor_regenerator.think = vip_RegenerateExtra;
			pl.vip_armor_regenerator.nextthink = time + cvar("g_explosive_vip_regenerate_extra_delay");
		}
	}

	vip_ResetHealthArmor(pl);

	local entity e, oldself;
	oldself = self;
	self = pl;
	switch(pl.team)
	{
		case COLOR_TEAM1:
			bigprint_spec(pl, "you are the ^1red^7 vip!", "Survive or your team will lose!", 2);
			bprint(pl.netname, " ^7is now the ^1RED^7 VIP!\n");
			
			WaypointSprite_Spawn("redvip", 0, 0, pl, '0 0 64', world, 0, pl, waypointsprite_attached, TRUE);
			if(self.waypointsprite_attached)
				WaypointSprite_UpdateTeamRadar(pl.waypointsprite_attached, RADARICON_WAYPOINT, '1 0 0');
			break;
		
		case COLOR_TEAM2:
			bigprint_spec(pl, "you are the ^4blue^7 vip!", "Survive or your team will lose!", 2);
			bprint(pl.netname, " ^7is now the ^4BLUE^7 VIP!\n");
			
			WaypointSprite_Spawn("bluevip", 0, 0, pl, '0 0 64', world, 0, pl, waypointsprite_attached, TRUE);
			if(self.waypointsprite_attached)
				WaypointSprite_UpdateTeamRadar(pl.waypointsprite_attached, RADARICON_WAYPOINT, '0 0 1');
			break;
		
		default:
			bigprint_spec(pl, "you are... wtf?!?!?", "^1THE MOD IS B0RKED", 2);
			bprint(pl.netname, " ^7is screwed everything up\n");
			break;
	}
	self = oldself;
	
	FOR_EACH_PLAYER(e) if(e.team == pl.team) if(e != pl)
		centerprint_spec(e, strcat(pl.netname, "^7 is now your VIP!"));
		
	play2all("kh/capture.wav");
}

void vip_ResetHealthArmor(entity vip)
{
	vip.health = vip.vip_maxhealth;
	vip.armorvalue = vip.vip_maxarmor;
}

void vip_AssignCustomRedVIP(entity newvip)
{
	if(redvip)
	{
		bprint("^5VIP^7: tried to assign the ^1RED^7 vip, but there is already one!\n");
		return;
	}
	
	redvip = newvip;
	
	if(redvip)
		vip_MakePlayerVIP(redvip);
}

void vip_AssignCustomBlueVIP(entity newvip)
{
	if(bluevip)
	{
		print("^5VIP^7: tried to assign the ^4BLUE^7 vip, but there is already one!\n");
		return;
	}
	
	bluevip = newvip;
	
	if(bluevip)
		vip_MakePlayerVIP(bluevip);
}

void vip_AssignRedVIP()
{
	vip_AssignCustomRedVIP(vip_PickRedVIP());
	
	if(!redvip)
	{
		print("^5VIP^7: not enough players on the red team, polling until there are some...\n");
		defer(1, vip_AssignRedVIP);
		return;
	}
}

void vip_AssignBlueVIP()
{
	vip_AssignCustomBlueVIP(vip_PickBlueVIP());
	
	if(!bluevip)
	{
		print("^5VIP^7: not enough players on the blue team, polling until there are some...\n");
		defer(1, vip_AssignBlueVIP);
		return;
	}
}

void vip_ClearVIP_Common(entity pl)
{
	//bprint("vip_ClearVIP_Common() for ", pl.netname, "\n");
	
	if(pl.vip_health_regenerator)
		remove(pl.vip_health_regenerator);
	
	if(pl.vip_armor_regenerator)
		remove(pl.vip_armor_regenerator);
	
	if(pl.waypointsprite_attached)
		WaypointSprite_Kill(pl.waypointsprite_attached);
	
	if(pl.vip_state_updater)
		remove(pl.vip_state_updater);
}

void vip_ClearRedVIP()
{
	vip_ClearVIP_Common(redvip);
	redvip = world;
	
	if(vip_soulgem)
	{
		local entity oldself;
		oldself = self;
		self = vip_redgem;
		vip_redgem.reset2();
		self = oldself;
	}
}

void vip_ClearBlueVIP()
{
	//vip_ClearVIP_Common(bluevip);
	vip_ClearVIP_Common(bluevip);
	bluevip = world;
	
	if(vip_soulgem)
	{
		local entity oldself;
		oldself = self;
		self = vip_bluegem;
		vip_bluegem.reset2();
		self = oldself;
	}
}

void vip_ClearVIPs()
{
	//bprint("vip_ClearVIPs()\n");
	vip_ClearRedVIP();
	vip_ClearBlueVIP();
}

void vip_AssignVIPs()
{
	if(vip_soulgem)
	{
		vip_SoulGem_StartRound();
		return;
	}
	
	//bprint("vip_AssignVIPs()\n");
	vip_AssignRedVIP();
	vip_AssignBlueVIP();
}

void vip_ClearVIPs_MaybeAssign()
{
	vip_ClearVIPs();
	
	if(vip_started)
		//vip_AssignVIPs();
		defer(1, vip_AssignVIPs);
}

float vip_RedVIPDown()
{
	local entity e;
	FOR_EACH_PLAYER(e)
	{
		bigprint_spec(e, "^4blue^7scores!", "The enemy VIP is down", 5);
		
		if(e.team == COLOR_TEAM2)
			hudflash_teamcolor_default_spec(e);
	}
	bprint("^4Blue team ^5wins the round since the enemy VIP is dead\n");
	play2all("ctf/blue_capture.wav");
	TeamScore_AddToTeam(COLOR_TEAM2, ST_SCORE, 1);
	PlayerScore_Add(bluevip, SP_VIP_SURVIVALS, 1);
	PlayerScore_Add(bluevip, SP_SCORE, cvar((vip_soulgem? "g_explosive_vip_score_survival_soulgem" : "g_explosive_vip_score_survival")));
	vip_EndRound();
}

float vip_BlueVIPDown()
{
	local entity e;
	FOR_EACH_PLAYER(e)
	{
		bigprint_spec(e, "^1red^7scores!", "The enemy VIP is down", 5);
		
		if(e.team == COLOR_TEAM1)
			hudflash_teamcolor_default_spec(e);
	}
	bprint("^1Red team ^5wins the round since the enemy VIP is dead\n");
	play2all("ctf/red_capture.wav");
	TeamScore_AddToTeam(COLOR_TEAM1, ST_SCORE, 1);
	PlayerScore_Add(redvip, SP_VIP_SURVIVALS, 1);
	PlayerScore_Add(redvip, SP_SCORE, cvar((vip_soulgem? "g_explosive_vip_score_survival_soulgem" : "g_explosive_vip_score_survival")));
	vip_EndRound();
}

float vip_PlayerDies(float deathtype)
{
	DEPENDON(g_vip)
	
	if(vip_ended)
		return;
	
	if(!vip_started)
	{
		if(ISREDVIP(frag_target))
		{
			vip_ClearRedVIP();
			
			if(!vip_soulgem)
				vip_AssignRedVIP();
		}
		else if(ISBLUEVIP(frag_target))
		{
			vip_ClearBlueVIP();
			
			if(!vip_soulgem)
				vip_AssignBlueVIP();
		}
		
		return;
	}
	
	if(!ISVIP(frag_target))
		return 0;
	
	if(frag_attacker) if(frag_attacker.classname == "player")
	{
		PlayerScore_Add(frag_attacker, SP_VIP_VIPKILLS, 1);
		
		if(DEATH_ISSPECIAL(deathtype) || deathtype == DEATH_HURTTRIGGER)
			PlayerScore_Add(frag_attacker, SP_SCORE, cvar("g_explosive_vip_score_vipkill_special"));
		else
			PlayerScore_Add(frag_attacker, SP_SCORE, cvar("g_explosive_vip_score_vipkill"));
	}
	
	if(ISREDVIP(frag_target))
		return vip_RedVIPDown();
	else if(ISBLUEVIP(frag_target))
		return vip_BlueVIPDown();
}

float vip_RemovePlayer()
{
	DEPENDON(g_vip)
	
	if(vip_ended)
		return;
	
	if(ISREDVIP(self))
	{
		vip_ClearRedVIP();
		
		if(vip_started)
			vip_RedVIPDown();
		else if(!vip_soulgem)
			vip_AssignRedVIP();
	}
	else if(ISBLUEVIP(self))
	{
		vip_ClearBlueVIP();
		
		if(vip_started)
			vip_BlueVIPDown();
		else if(!vip_soulgem)
			vip_AssignBlueVIP();
	}
}
