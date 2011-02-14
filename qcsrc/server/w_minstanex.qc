.float minstanex_lasthit;

//<akari>
//
//    This function implements the explosive attack of minstanex
//    It is a dirty copypaste from the grenadelauncher with some modifications
//
void W_Explosive_Attack (float attacktype)
{
	float SPEED;
	SPEED = 90000000;
	
	local entity gren;

	local float expl_damage = cvar("g_balance_grenadelauncher_primary_damage") / 2;
	local float expl_recoil = 4;
	
	if(cvar("g_explosive_norecoil"))
		expl_recoil = 0;
	
	if(cvar("g_balance_minstanex_explosive") == 3)
		expl_damage = 0;

	W_SetupShot_ProjectileSize (self, '0 0 -3', '0 0 -3', FALSE, expl_recoil, "", expl_damage);
	w_shotdir = v_forward; // no TrueAim for grenades please

	//pointparticles(particleeffectnum("grenadelauncher_muzzleflash"), w_shotorg, w_shotdir * 1000, 1);

	gren = spawn ();
	gren.owner = self;
	gren.classname = "plasma_prim";
	gren.bot_dodge = TRUE;
	gren.bot_dodgerating = cvar("g_balance_grenadelauncher_primary_damage");
	gren.movetype = MOVETYPE_FLY;
	PROJECTILE_MAKETRIGGER(gren);
	
	//maybe later
	/*switch(cvar("g_explosive_explostyle"))
	{
		case 1:
			gren.projectiledeathtype = WEP_ELECTRO;
			break;
		case 2:
			gren.projectiledeathtype = WEP_MINSTANEX;
			break;
		default:
			gren.projectiledeathtype = WEP_ROCKET_LAUNCHER;
	}*/
	
	gren.projectiledeathtype = attacktype;
	
	setorigin(gren, w_shotorg);
	setsize(gren, '0 0 -3', '0 0 -3');

	gren.nextthink = time + cvar("g_balance_grenadelauncher_primary_lifetime");
	gren.think = adaptor_think2use;
	gren.use = W_Grenade_Explode;
	gren.touch = W_Grenade_Touch1;
	gren.velocity = w_shotdir * SPEED;
	W_SetupProjectileVelocity(gren);

	gren.angles = vectoangles (gren.velocity);
	gren.flags = FL_PROJECTILE;

	CSQCProjectile(gren, TRUE, PROJECTILE_GRENADE, TRUE);
}

//Attack function for the rage mode
void W_Hook_Attack2(void);
void W_Rage_Attack (void)
{
	//Just cast another explosive attack. For now.
	W_Explosive_Attack(WEP_ELECTRO);
}
//</akari>

void W_MinstaNex_Attack (void)
{
	float flying;
	flying = IsFlying(self); // do this BEFORE to make the trace values from FireRailgunBullet last

	W_SetupShot (self, TRUE, 0, "weapons/minstanexfire.wav", 0);

	yoda = 0;
	damage_goodhits = 0;
	headshot = 0;
	
	//<akari>
	local float nex_damage = 10000000000;
	//Executes the explosive attack
	if(cvar("g_balance_minstanex_explosive"))
	{
		W_Explosive_Attack(WEP_ROCKET_LAUNCHER);
	}
	
	if(cvar("g_explosive_rage")) if(self.rage >= cvar("g_explosive_rage"))
	{
		W_Rage_Attack();
		self.rage -= 1;
		if(self.rage < 0)
			self.rage = 0;
	}
	
	if(cvar("g_balance_minstanex_explosive") == 2)
		nex_damage = 0;
	FireRailgunBullet (w_shotorg, w_shotorg + w_shotdir * MAX_SHOT_DISTANCE, nex_damage, 800, 0, 0, 0, 0, WEP_MINSTANEX);
    //</akari>

	if(g_minstagib)
	{
		if(yoda)
			announce(self, "announcer/male/yoda.wav");
	}
	else
	{
		if(yoda && flying)
			announce(self, "announcer/male/yoda.wav");
		if(headshot)
		{
			announce(self, "announcer/male/headshot.wav");
			print("h\n");
		}
		if(damage_goodhits && self.minstanex_lasthit)
		{
			if(announce(self, "announcer/male/impressive.wav"))
				damage_goodhits = 0; // only every second time
		}
	}

	self.minstanex_lasthit = damage_goodhits;

	pointparticles(particleeffectnum("nex_muzzleflash"), w_shotorg, w_shotdir * 1000, 1);

	// teamcolor / hit beam effect
	if(teamplay)
	{
	    switch(self.team)
	    {
            case COLOR_TEAM1:   // Red
                if(damage_goodhits)
                    trailparticles(world, particleeffectnum("TE_TEI_G3RED_HIT"), w_shotorg, trace_endpos);
                else
                    trailparticles(world, particleeffectnum("TE_TEI_G3RED"), w_shotorg, trace_endpos);
                break;
            case COLOR_TEAM2:   // Blue
                if(damage_goodhits)
                    trailparticles(world, particleeffectnum("TE_TEI_G3BLUE_HIT"), w_shotorg, trace_endpos);
                else
                    trailparticles(world, particleeffectnum("TE_TEI_G3BLUE"), w_shotorg, trace_endpos);
                break;
            case COLOR_TEAM3:   // Yellow
                if(damage_goodhits)
                    trailparticles(world, particleeffectnum("TE_TEI_G3YELLOW_HIT"), w_shotorg, trace_endpos);
                else
                    trailparticles(world, particleeffectnum("TE_TEI_G3YELLOW"), w_shotorg, trace_endpos);
                break;
            case COLOR_TEAM4:   // Pink
                if(damage_goodhits)
                    trailparticles(world, particleeffectnum("TE_TEI_G3PINK_HIT"), w_shotorg, trace_endpos);
                else
                    trailparticles(world, particleeffectnum("TE_TEI_G3PINK"), w_shotorg, trace_endpos);
                break;
	    }
	}
	else
        trailparticles(world, particleeffectnum("TE_TEI_G3"), w_shotorg, trace_endpos);

	// flash and burn the wall
	if (trace_ent.solid == SOLID_BSP && !(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT))
		Damage_DamageInfo(trace_endpos, 10000, 0, 0, 800 * w_shotdir, WEP_MINSTANEX, self);

	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
	{
		if (g_minstagib)
			self.ammo_cells = self.ammo_cells - 1;
		else
			self.ammo_cells = self.ammo_cells - cvar("g_balance_minstanex_ammo");
	}
}


//<akari>
.entity hooker;
.entity hooked_to;
entity nobody;
string GetHitSound(entity attacker, entity target);
//</akari>

.float minstagib_nextthink;
void minstagib_ammocheck (void)
{
	if (time < self.minstagib_nextthink || self.deadflag || gameover)
		return;

	//<akari>
	//
	// I have commented the code below out to disable the no-ammo-death in minstagib.
	// Enabling it will cause problems.
	
	/*if (self.ammo_cells <= 0)
	{
		if (self.health == 5)
		{
			centerprint(self, "you're dead now...\n");
			Damage(self, self, self, 5, DEATH_NOAMMO, self.origin, '0 0 0');
			announce(self, "announcer/robotic/terminated.wav");
		}
		else if (self.health == 10)
		{
			centerprint(self, "^11^7 second left to find some ammo\n");
			Damage(self, self, self, 5, DEATH_NOAMMO, self.origin, '0 0 0');
			announce(self, "announcer/robotic/1.wav");
		}
		else if (self.health == 20)
		{
			centerprint(self, "^12^7 seconds left to find some ammo\n");
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			announce(self, "announcer/robotic/2.wav");
		}
		else if (self.health == 30)
		{
			centerprint(self, "^13^7 seconds left to find some ammo\n");
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			announce(self, "announcer/robotic/3.wav");
		}
		else if (self.health == 40)
		{
			centerprint(self, "^14^7 seconds left to find some ammo\n");
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			announce(self, "announcer/robotic/4.wav");
		}
		else if (self.health == 50)
		{
			centerprint(self, "^15^7 seconds left to find some ammo\n");
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			announce(self, "announcer/robotic/5.wav");
		}
		else if (self.health == 60)
		{
			centerprint(self, "^36^7 seconds left to find some ammo\n");
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			announce(self, "announcer/robotic/6.wav");
		}
		else if (self.health == 70)
		{
			centerprint(self, "^37^7 seconds left to find some ammo\n");
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			announce(self, "announcer/robotic/7.wav");
		}
		else if (self.health == 80)
		{
			centerprint(self, "^38^7 seconds left to find some ammo\n");
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			announce(self, "announcer/robotic/8.wav");
		}
		else if (self.health == 90)
		{
			centerprint(self, "^39^7 seconds left to find some ammo\n");
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			announce(self, "announcer/robotic/9.wav");
		}
		else if (self.health == 100)
		{
			centerprint(self, "get some ammo or\nyou'll be dead in ^310^7 seconds...");
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			if not(self.flags & FL_GODMODE)
				announce(self, "announcer/robotic/10.wav");
		}
	}*/
	//</akari>
	
	//<akari>
	//Health draining
	
	if(cvar("g_balance_minstanex_explosive") && cvar("g_explosive_health_drain") && self.health > cvar("g_explosive_health_min"))
	{
		self.health -= cvar("g_explosive_health_drain");
	}
	
	//Hook damage
	/*if(self.hooker.hooked_to == self)
	{
		if(!teams_matter || self.hooker.team != self.team)
		{
			play2(self.hooker, "misc/hit.wav");
			Damage(self, self.hooker.hook, self.hooker, random() * 10, DEATH_NOAMMO, self.origin, '0 0 0');
		}
	}*/
	
	//</akari>
	
	self.minstagib_nextthink = time + 1;
}

void spawnfunc_weapon_minstanex (void); // defined in t_items.qc

float w_minstanex(float req)
{
	if (req == WR_AIM)
	{
		if(self.ammo_cells>0)
			self.BUTTON_ATCK = bot_aim(1000000, 0, 1, FALSE);
		else
			self.BUTTON_ATCK2 = bot_aim(cvar("g_balance_laser_primary_speed"), 0, cvar("g_balance_laser_primary_lifetime"), FALSE);
	}
	else if (req == WR_THINK)
	{
		if (self.BUTTON_ATCK)
		{
			if (weapon_prepareattack(0, cvar("g_balance_minstanex_refire")))
			{
				W_MinstaNex_Attack();
				weapon_thinkf(WFRAME_FIRE1, cvar("g_balance_minstanex_animtime"), w_ready);
			}
		}
		else if (self.BUTTON_ATCK2)
		{
			if (self.jump_interval <= time)
			{
				self.jump_interval = time + 0.9 * W_WeaponRateFactor();
				W_Laser_Attack(FALSE);
			}
		}
	}
	else if (req == WR_PRECACHE)
	{
		precache_model ("models/nexflash.md3");
		precache_model ("models/weapons/g_minstanex.md3");
		precache_model ("models/weapons/v_minstanex.md3");
		precache_model ("models/weapons/h_minstanex.dpm");
		precache_sound ("weapons/minstanexfire.wav");
		precache_sound ("weapons/nexwhoosh1.wav");
		precache_sound ("weapons/nexwhoosh2.wav");
		precache_sound ("weapons/nexwhoosh3.wav");
		w_laser(WR_PRECACHE);
	}
	else if (req == WR_SETUP)
	{
		weapon_setup(WEP_MINSTANEX);
		self.minstanex_lasthit = 0;
	}
	else if (req == WR_CHECKAMMO1)
	{
		if (g_minstagib)
			return self.ammo_cells >= 1;
		else
			return self.ammo_cells >= cvar("g_balance_minstanex_ammo");
	}
	else if (req == WR_CHECKAMMO2)
		return TRUE;
	else if (req == WR_SUICIDEMESSAGE)
		//<akari>
		//Since suiciding with the nexgun is now possible, I think we should replace this message
		//w_deathtypestring = "did the impossible";
		w_deathtypestring = "should use a smaller gun";
		//</akari>
	else if (req == WR_KILLMESSAGE)
		w_deathtypestring = "has been vaporized by";
	else if (req == WR_RESETPLAYER)
	{
		self.minstanex_lasthit = 0;
	}
	return TRUE;
};

