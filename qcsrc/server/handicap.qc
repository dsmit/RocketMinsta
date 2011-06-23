
#define HC_AFFECT_POSITIVE(f,e) f = f * (1 + (e).rm_handicap)
#define HC_AFFECT_NEGATIVE(f,e) f = f * (1 - (e).rm_handicap)

#define HC_AFFECT_POSITIVE_CEIL(f,e) f = ceil(f * (1 + (e).rm_handicap))
#define HC_AFFECT_NEGATIVE_CEIL(f,e) f = ceil(f * (1 - (e).rm_handicap))

#define HC_CVAR(s) cvar(strcat("g_explosive_handicap_affects_", s))
#define HC_DEPEND(s) if(!HC_CVAR(s)) return
#define HC_DEPEND_OR(s,code) if(!HC_CVAR(s)) { code return; }
#define HC_DEPEND_WITHVAL(s,v) if(!HC_CVAR(s)) return v

#define HANDICAP_LIMIT_MIN 0
#define HANDICAP_LIMIT_MAX 0.99

void Handicap_Force(entity e, float hvalue)
{
	local float old;
	old = e.rm_handicap;
	e.rm_handicap = max(HANDICAP_LIMIT_MIN, min(hvalue, HANDICAP_LIMIT_MAX));
	
	if(e.rm_handicap != old)
		bprint(self.netname, "^7's handicap is now ", ftos(self.rm_handicap), "\n");
}

void Handicap_Set(entity e, float hvalue)
{
	if(cvar("g_explosive_handicap_enabled"))
	{
		Handicap_Force(e, hvalue);
		return;
	}
	
	sprint(e, "^1You are not allowed to change your handicap on this server\n");
	Handicap_Force(e, 0); // just in case
	return;
}

float Handicap_ApplyDamage(float damage, entity attacker, entity targ)
{
	HC_DEPEND_WITHVAL("damage", damage);
	
	HC_AFFECT_NEGATIVE(damage, attacker);
	HC_AFFECT_POSITIVE(damage, targ);
	return damage;
}

void Handicap_ApplyStartAmmo(entity player)
{
	HC_DEPEND("ammo_start");
	
	HC_AFFECT_NEGATIVE(player.ammo_shells, player);
	HC_AFFECT_NEGATIVE(player.ammo_nails, player);
	HC_AFFECT_NEGATIVE(player.ammo_rockets, player);
	HC_AFFECT_NEGATIVE(player.ammo_cells, player);
	HC_AFFECT_NEGATIVE(player.ammo_fuel, player);
}

float Handicap_GetStartHealth_Force(entity player)
{
	local float f;
	f = start_health;
	HC_AFFECT_NEGATIVE(f, player);
	f = max(1, f);
	return f;
}

float Handicap_GetStartHealth(entity player)
{
	HC_DEPEND_WITHVAL("health_start", start_health);
	return Handicap_GetStartHealth_Force(player);
}

void Handicap_ApplyStartHealth(entity player)
{
	HC_DEPEND("health_start");
	HC_AFFECT_NEGATIVE(player.health, player);
}

void Handicap_ApplyStartArmor(entity player)
{
	HC_DEPEND("armor_start");
	HC_AFFECT_NEGATIVE(player.armorvalue, player);
}

void Handicap_Give_Common(entity player, float amount, .float field, float maxval, string iname)
{
	HC_DEPEND_OR(strcat(iname, "_pickup"), {
		player.field = min(player.field + amount, maxval);
	})
	
	HC_AFFECT_NEGATIVE_CEIL(amount, player);
	
	if(HC_CVAR(strcat(iname, "_max")))
		HC_AFFECT_NEGATIVE_CEIL(maxval, player);
	
	player.field = min(player.field + amount, maxval);
}

void Handicap_GiveAmmo(entity player, float amount, .float field, float maxval)
{
	Handicap_Give_Common(player, amount, field, maxval, "ammo");
}

void Handicap_GiveHealth(entity player, float amount, .float field, float maxval)
{
	Handicap_Give_Common(player, amount, field, maxval, "health");
}

void Handicap_GiveArmor(entity player, float amount, .float field, float maxval)
{
	Handicap_Give_Common(player, amount, field, maxval, "armor");
}

float Handicap_ApplyRefire(float ref, entity player)
{
	HC_DEPEND_WITHVAL("refire", ref);
	HC_AFFECT_POSITIVE(ref, player);
	return ref;
}

void Handicap_ApplyRMOverflow(entity player, .float field, float amount, float maxval, float limit, string iname)
{
	if(HC_CVAR(strcat(iname, "_pickup")))
		HC_AFFECT_NEGATIVE(amount, player);
	
	if(HC_CVAR(strcat(iname, "_max")))
		HC_AFFECT_NEGATIVE(limit, player);
	
	if(player.field < maxval)
		player.field = maxval;
	else if(!limit)
		player.field = player.field + amount;
	else if(player.field < limit)
		player.field = min(limit, player.field + amount);
}

float Handicap_ApplyFreezetagReviveSpeed(float spd, entity player, vector revive_extra_size, entity startfrom)
{
	HC_DEPEND_WITHVAL("freezetag_revive_speed", spd);
	
	local entity e;
	local entity p;
	local float lowest_hc;
	lowest_hc = HANDICAP_LIMIT_MAX;
	
	// Find a reviving player with lowest handicap
	for(e = startfrom; (e = find(e, classname, STR_PLAYER)) != world; ) if(self != e)
	{
		if(!e.freezetag_frozen)
		{
			if(e.team == self.team)
			{
				if(boxesoverlap(self.absmin - revive_extra_size, self.absmax + revive_extra_size, e.absmin, e.absmax))
				{
					if(e.rm_handicap < lowest_hc)
					{
						p = e;
						lowest_hc = e.rm_handicap;
						
						if(p.rm_handicap == HANDICAP_LIMIT_MIN) // The lowest possible handicap found, no point searching any further
							break;
					}
				}
			}
		}
	}

	HC_AFFECT_NEGATIVE(spd, p);
	return spd;
}
