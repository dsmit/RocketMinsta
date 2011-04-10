
#define DEPENDON(d) if(!d) return 0;

void freezetag_EndRound_Think()
{
    local float timeleft = rint(self.cnt - time);
    
    //bprint("next_round = ", ftos(next_round), "\n");
    //bprint("time = ", ftos(time), "\n");
    //bprint("timeleft = ", ftos(timeleft), "\n");
    
    if(intermission_running)
    {
        //bprint("Freezetag: GAME OVER\n");
        remove(self);
        return;
    }
    
    if(timeleft <= cvar("g_explosive_freezetag_warmup"))
    {
        if(timeleft <= 0)
        {
            local entity e;
            FOR_EACH_PLAYER(e)
            {
                bigprint_clear_spec(e);
                bigprint_spec(e, "^5Begin!", "", 1);
            }
            remove(self);
            return;
        }
        
        local entity e;
        FOR_EACH_PLAYER(e)
        {
            bigprint_clear_spec(e);
            bigprint_spec(e, strcat("freezetag starts in: ", ftos(timeleft)), "", 1);
        }
    }
    self.nextthink = time + 1;
}

void freezetag_EndRound()
{
    local entity e = spawn();
    e.think = freezetag_EndRound_Think;
    e.nextthink = time + 1;
    next_round = time + 5;
    e.cnt = cvar("g_explosive_freezetag_warmup") + next_round;
}

void freezetag_Initialize()
{
	precache_model("models/ice/ice.md3");
    
    if(inWarmupStage)
        warmup = time;
    else
        warmup = time + cvar("g_start_delay");
    
    precache_sound("ctf/red_capture.wav");
    precache_sound("ctf/blue_capture.wav");
	ScoreRules_freezetag();
}

void freezetag_CheckWinner()
{
    DEPENDON(g_freezetag)
    
	if(time <= game_starttime) // game didn't even start yet! nobody can win in that case.
		return;

	if(next_round || (time > warmup - cvar("g_explosive_freezetag_warmup") && time < warmup))
		return; // already waiting for next round to start

    /*
    bprint("redalive = ", ftos(redalive), "\n");
    bprint("bluealive = ", ftos(bluealive), "\n");
    bprint("yellowalive = ", ftos(yellowalive), "\n");
    bprint("pinkalive = ", ftos(pinkalive), "\n");
    */
    
	if((redalive >= 1 && bluealive >= 1) // counted in arena.qc
		|| (redalive >= 1 && yellowalive >= 1)
		|| (redalive >= 1 && pinkalive >= 1)
		|| (bluealive >= 1 && yellowalive >= 1)
		|| (bluealive >= 1 && pinkalive >= 1)
		|| (yellowalive >= 1 && pinkalive >= 1))
		return; // we still have active players on two or more teams, nobody won yet

	entity e, winner;
	string teamname, teamname_full;
	winner = world;

	FOR_EACH_PLAYER(e)
	{
		if(e.freezetag_frozen == 0 && e.classname == "player" && e.health >= 1) // here's one player from the winning team... good
		{
			winner = e;
			break; // break, we found the winner
		}
	}

	if(winner != world) // just in case a winner wasn't found
	{
		if(winner.team == COLOR_TEAM1)
        {
			teamname = "^1red";
            teamname_full = "^1Red team";
            play2all("ctf/red_capture.wav");
        }
		else if(winner.team == COLOR_TEAM2)
        {
			teamname = "^4blue";
            teamname_full = "^4Blue team";
            play2all("ctf/blue_capture.wav");
        }
		else if(winner.team == COLOR_TEAM3)
        {
			teamname = "^3yellow";
            teamname_full = "^3Yellow team";
        }
		else
        {
			teamname = "^6pink";
            teamname_full = "^6Pink team";
        }
		FOR_EACH_PLAYER(e) {
			//centerprint(e, strcat(teamname, "^5 wins the round, all other teams were frozen.\n"));
            bigprint_spec(e, strcat(teamname, "^7scores!"), "All opponents are frozen", 5);
		}
		bprint(teamname_full, "^5 wins the round since all their opponents were frozen.\n");
		TeamScore_AddToTeam(winner.team, ST_SCORE, +1);
	}

	//next_round = time + 5;
    freezetag_EndRound();
}

// this is needed to allow the player to turn his view around (fixangle can't
// be used to freeze his view, as that also changes the angles), while not
// turning that ice object with the player
void freezetag_Ice_Think()
{
	setorigin(self, self.owner.origin - '0 0 16');
	self.nextthink = time;
    self.alpha = 0.6 * (1 - self.owner.freezetag_revive_progress);
}

void freezetag_Freeze(entity attacker)
{
    DEPENDON(g_freezetag)
	if(self.freezetag_frozen)
		return;
		
	self.freezetag_frozen = 1;
	self.freezetag_revive_progress = 0;

	entity ice;
	ice = spawn();
	ice.owner = self;
	ice.classname = "freezetag_ice";
	ice.think = freezetag_Ice_Think;
	ice.nextthink = time;
	ice.frame = floor(random() * 21); // ice model has 20 different looking frames
    ice.alpha = 0.6;
	setmodel(ice, "models/ice/ice.md3");

	entity oldself;
	oldself = self;
	self = ice;
	freezetag_Ice_Think();
	self = oldself;

	// add waypoint
	WaypointSprite_Spawn("freezetag_frozen", 0, 0, self, '0 0 64', world, self.team, self, waypointsprite_attached, TRUE);
	if(self.waypointsprite_attached)
	{
		WaypointSprite_UpdateTeamRadar(self.waypointsprite_attached, RADARICON_WAYPOINT, '0.25 0.90 1');
	}

	if(attacker == self)
	{
		// you froze your own dumb self
		// counted as "suicide" already
		PlayerScore_Add(self, SP_SCORE, -1);
	}
	else if(attacker.classname == "player")
	{
		// got frozen by an enemy
		// counted as "kill" and "death" already
		PlayerScore_Add(self, SP_SCORE, -1);
		PlayerScore_Add(attacker, SP_SCORE, +1);
	}
	else
	{
		// nothing - got frozen by the game type rules themselves
	}
}

void freezetag_Unfreeze(entity attacker)
{
    DEPENDON(g_freezetag)
	self.freezetag_frozen = 0;
	self.freezetag_revive_progress = 0;

	// remove the ice block
	entity ice;
	for(ice = world; (ice = find(ice, classname, "freezetag_ice")); ) if(ice.owner == self)
	{
		remove(ice);
		break;
	}

	// remove waypoint
	if(self.waypointsprite_attached)
		WaypointSprite_Kill(self.waypointsprite_attached);
}

.vector ft_oldorigin;
.vector ft_oldangles;
.float ft_oldteam;
.float ft_forcespawn;
float freezetag_RemovePlayer()
{
    DEPENDON(g_freezetag)
	if(self.freezetag_frozen == 0)
	{
		if(self.team == COLOR_TEAM1)
			--redalive;
		else if(self.team == COLOR_TEAM2)
			--bluealive;
		else if(self.team == COLOR_TEAM3)
			--yellowalive;
		else if(self.team == COLOR_TEAM4)
			--pinkalive;
		--totalalive;
	}

	if(totalspawned > 2) // only check for winners if we had more than two players (one of them left, don't let the other player win just because of that)
		freezetag_CheckWinner();

	if(self.freezetag_frozen)
	{
		self.ft_oldorigin = self.origin;
		self.ft_oldangles = self.angles;
		self.ft_oldteam = self.team;
		self.ft_forcespawn = TRUE;
	}

	freezetag_Unfreeze(world);
	
	return 1;
}

string W_ThrowNewWeapon(entity own, float wpn, float doreduce, vector org, vector velo);
float freezetag_PlayerDies()
{
    DEPENDON(g_freezetag)
    
    if(warmup >= time)
    {
        //bprint("Not counting freeze: wamrup\n");
        return 0;
    }
    
	if(self.freezetag_frozen == 0)
	{
		if(self.team == COLOR_TEAM1)
			--redalive;
		else if(self.team == COLOR_TEAM2)
			--bluealive;
		else if(self.team == COLOR_TEAM3)
			--yellowalive;
		else if(self.team == COLOR_TEAM4)
			--pinkalive;
		--totalalive;

        freezetag_Freeze(frag_attacker);
	}

    /*if(frag_attacker.classname == STR_PLAYER)
        centerprint(frag_attacker, strcat("^2You froze ^7", frag_target.netname, ".\n"));

	if(frag_attacker == frag_target || frag_attacker == world)
	{
        if(frag_target.classname == STR_PLAYER)
            centerprint(frag_target, "^1You froze yourself.\n");
		bprint("^7", frag_target.netname, "^1 froze himself.\n");
	}
	else
	{
        if(frag_target.classname == STR_PLAYER)
            centerprint(frag_target, strcat("^1You were frozen by ^7", frag_attacker.netname, ".\n"));
		bprint("^7", frag_target.netname, "^1 was frozen by ^7", frag_attacker.netname, ".\n");
	}*/

	frag_target.health = 100; // "respawn" the player :P
	W_ThrowNewWeapon(frag_target, WEP_MINSTANEX, 0, frag_target.origin, frag_target.velocity);
	freezetag_CheckWinner();

	return 1;
}

float freezetag_PlayerSpawn()
{
    DEPENDON(g_freezetag)
    freezetag_Unfreeze(world); // start by making sure that all ice blocks are removed

	if(totalspawned == 1 && time > game_starttime) // only one player active on server, start a new match immediately
	if(!next_round && warmup && (time < warmup - cvar("g_explosive_freezetag_warmup") || time > warmup)) // not awaiting next round
	{
		next_round = time;
		return 1;
	}
	if(warmup && time > warmup) // spawn too late, freeze player
	{
		centerprint_spec(self, "^5You spawned after the round started, you'll spawn frozen\n");
		freezetag_Freeze(world);
	}

	// Prevents frozen players from "teleporting" around
	if(self.freezetag_frozen) if(self.ft_forcespawn) if(self.ft_oldteam == self.team)
	{
		self.origin = self.ft_oldorigin;
		self.angles = self.ft_oldangles;
		self.angles_z = 0;
		self.fixangle = 1;
		setorigin(self, self.ft_oldorigin + '0 0 1' * (1 - self.mins_z - 24));
	}

	self.ft_forcespawn = FALSE;
	return 1;
}

float freezetag_PlayerPreThink()
{
	float n;
	vector revive_extra_size;
    DEPENDON(g_freezetag)
	revive_extra_size = '1 1 1' * cvar("g_explosive_freezetag_revive_extra_size");

	entity o;
	o = world;
	n = 0;
    
    if(!self.freezetag_frozen)
    {
        FOR_EACH_PLAYER(other) if(self != other)
        {
            if(other.freezetag_frozen)
            {
                if(other.team == self.team)
                {
                    if(boxesoverlap(self.absmin - revive_extra_size, self.absmax + revive_extra_size, other.absmin, other.absmax))
                    {
                        //reviving, don't reset status
                        return 0;
                    }
                }
            }
        }
        self.freezetag_revive_progress = 0;
        return 0;
    }
    
	FOR_EACH_PLAYER(other) if(self != other)
	{
		if(other.freezetag_frozen == 0)
		{
			if(other.team == self.team)
			{
				if(boxesoverlap(self.absmin - revive_extra_size, self.absmax + revive_extra_size, other.absmin, other.absmax))
				{
					if(!o)
						o = other;
					++n;
				}
			}
		}
	}

	if(n && self.freezetag_frozen) // OK, there is at least one teammate reviving us
	{
		self.freezetag_revive_progress = bound(0, self.freezetag_revive_progress + frametime * cvar("g_explosive_freezetag_revive_speed"), 1);
        //bprint("revive debug: ", self.netname, "^7.freezetag_revive_progress = ", ftos(self.freezetag_revive_progress), "\n");

		if(self.freezetag_revive_progress >= 1)
		{
			freezetag_Unfreeze(self);

			// EVERY team mate nearby gets a point (even if multiple!)
			FOR_EACH_PLAYER(other) if(self != other)
			{
				if(other.freezetag_frozen == 0)
				{
					if(other.team == self.team)
					{
						if(boxesoverlap(self.absmin - revive_extra_size, self.absmax + revive_extra_size, other.absmin, other.absmax))
						{
							PlayerScore_Add(other, SP_FREEZETAG_REVIVALS, +1);
							PlayerScore_Add(other, SP_SCORE, +1);
                            other.health = max(other.health, 100);
						}
					}
				}
			}

			if(n > 1)
				centerprint_spec(self, strcat("^5You were revived by ^7", o.netname, "^5 et al\n"));
			else
				centerprint_spec(self, strcat("^5You were revived by ^7", o.netname, "\n"));
			centerprint_spec(o, strcat("^5You revived ^7", self.netname, "\n"));
			if(n > 1)
				bprint("^7", o.netname, "^5 et al revived ^7", self.netname, "\n");
			else
				bprint("^7", o.netname, "^5 revived ^7", self.netname, "\n");
		}

		// now find EVERY teammate within reviving radius, set their revive_progress values correct
		FOR_EACH_PLAYER(other) if(self != other)
		{
            //bprint("revive debug: setting ", other.netname, "^7: check #1 passed\n");
            
			if(other.freezetag_frozen == 0)
			{
                //bprint("revive debug: setting ", other.netname, "^7: check #2 passed\n");
				if(other.team == self.team)
				{
                    //bprint("revive debug: setting ", other.netname, "^7: check #3 passed\n");
					if(boxesoverlap(self.absmin - revive_extra_size, self.absmax + revive_extra_size, other.absmin, other.absmax))
                    {
                        //bprint("revive debug: setting ", other.netname, "^7: check #4 passed\n");
						other.freezetag_revive_progress = self.freezetag_revive_progress;
                        //bprint("^5revive debug: ", other.netname, "^7.freezetag_revive_progress = ", ftos(self.freezetag_revive_progress), "\n");
                    }
				}
			}
		}
	}
	else if(!n && self.freezetag_frozen) // only if no teammate is nearby will we reset
	{
		self.freezetag_revive_progress = bound(0, self.freezetag_revive_progress - frametime * cvar("g_explosive_freezetag_revive_clearspeed"), 1);
	}
	else if(!n)
	{
		self.freezetag_revive_progress = 0; // thawing nobody
        //bprint("^1revive debug: reset ", self.netname, "^7.freezetag_revive_progress\n");
	}

	return 1;
}

float freezetag_PlayerPhysics()
{
    DEPENDON(g_freezetag)
	if(self.freezetag_frozen)
	{
		self.movement = '0 0 0';
		self.disableclientprediction = 1;
	}
	return 1;
}
