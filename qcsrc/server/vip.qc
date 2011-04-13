
entity redvip;
entity bluevip;
float vip_started;
.entity vip_health_regenerator;
.entity vip_armor_regenerator;
.entity vip_state_updater;
.float vip_maxhealth;
.float vip_maxarmor;

void vip_init()
{
    if(inWarmupStage)
        warmup = time;
    else
        warmup = time + cvar("g_start_delay");
    
    precache_sound("ctf/red_capture.wav");
    precache_sound("ctf/blue_capture.wav");
    ScoreRules_vip();
    
	if(inWarmupStage)
		vip_AssignVIPs();
	else
		defer(time + cvar("g_start_delay"), vip_AssignVIPs);
	
	vip_started = 1;
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
    local entity e = spawn();
    e.think = vip_EndRound_Think;
    e.nextthink = time + 1;
    next_round = time + 5;
    e.cnt = cvar("g_explosive_vip_warmup") + next_round;
    update_playercount();
    defer(5.1, vip_ClearVIPs);
    vip_started = 0;
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
		pl.health = pl.vip_maxhealth;
		
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
		pl.armorvalue = pl.vip_maxarmor;
		
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
		pl.armorvalue = pl.vip_maxarmor;
		
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

	local entity e;
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
	
	FOR_EACH_PLAYER(e) if(e.team == pl.team) if(e != pl)
		centerprint_spec(e, strcat(pl.netname, "^7 is now your VIP!"));
}

void vip_AssignRedVIP()
{
	//bprint("vip_AssignRedVIP()\n");
	
	if(redvip)
	{
		bprint("^5VIP^7: tried to assign the ^1RED^7 vip, but there is already one!\n");
		return;
	}
	
	redvip = vip_PickRedVIP();
	
	if(!redvip)
	{
		print("^5VIP^7: not enough players on the red team, polling until there are some...\n");
		defer(1, vip_AssignRedVIP);
		return;
	}
	
	vip_MakePlayerVIP(redvip);
}

void vip_AssignBlueVIP()
{
	//bprint("vip_AssignBlueVIP()\n");
	
	if(bluevip)
	{
		print("^5VIP^7: tried to assign the ^4BLUE^7 vip, but there is already one!\n");
		return;
	}
	
	bluevip = vip_PickBlueVIP();
	
	if(!bluevip)
	{
		print("^5VIP^7: not enough players on the blue team, polling until there are some...\n");
		defer(1, vip_AssignBlueVIP);
		return;
	}
	
	vip_MakePlayerVIP(bluevip);
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
	// yes, it HAS to be called two times
	// not anymore it seems
	//vip_ClearVIP_Common(redvip);
	vip_ClearVIP_Common(redvip);
	redvip = world;
}

void vip_ClearBlueVIP()
{
	//vip_ClearVIP_Common(bluevip);
	vip_ClearVIP_Common(bluevip);
	bluevip = world;
}

void vip_ClearVIPs()
{
	//bprint("vip_ClearVIPs()\n");
	vip_ClearRedVIP();
	vip_ClearBlueVIP();
}

void vip_AssignVIPs()
{
	//bprint("vip_AssignVIPs()\n");
	vip_AssignRedVIP();
	vip_AssignBlueVIP();
}

float vip_RedVIPDown()
{
	local entity e;
	FOR_EACH_PLAYER(e)
		bigprint_spec(e, "^4blue^7scores!", "The enemy VIP is down", 5);
	bprint("^4Blue team ^5wins the round since the enemy VIP is dead\n");
	play2all("ctf/blue_capture.wav");
	TeamScore_AddToTeam(COLOR_TEAM2, ST_SCORE, 1);
	vip_EndRound();
}

float vip_BlueVIPDown()
{
	local entity e;
	FOR_EACH_PLAYER(e)
		bigprint_spec(e, "^1red^7scores!", "The enemy VIP is down", 5);
	bprint("^1Red team ^5wins the round since the enemy VIP is dead\n");
	play2all("ctf/red_capture.wav");
	TeamScore_AddToTeam(COLOR_TEAM1, ST_SCORE, 1);
	vip_EndRound();
}

float vip_PlayerDies()
{
	DEPENDON(g_vip)
	
	if(!vip_started)
		return;
	
	if(!ISVIP(frag_target))
		return 0;
	
	if(frag_attacker) if(frag_attacker.classname == "player")
	{
		PlayerScore_Add(frag_attacker, SP_VIP_VIPKILLS, 1);
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
	
	if(!vip_started)
		return;
	
	if(ISREDVIP(self))
	{
		vip_ClearRedVIP();
		vip_RedVIPDown();
	}
	else if(ISBLUEVIP(self))
	{
		vip_ClearBlueVIP();
		vip_BlueVIPDown();
	}
}
