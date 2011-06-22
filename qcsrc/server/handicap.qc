
#define HC_AFFECT_POSITIVE(f,e) f = f * (1 + (e).rm_handicap)
#define HC_AFFECT_NEGATIVE(f,e) f = f * (1 - (e).rm_handicap)

#define HC_AFFECT_POSITIVE_CEIL(f,e) f = ceil(f * (1 + (e).rm_handicap))
#define HC_AFFECT_NEGATIVE_CEIL(f,e) f = ceil(f * (1 - (e).rm_handicap))

#define HC_CVAR(s) cvar(strcat("g_explosive_handicap_affects_", s))
#define HC_DEPEND(s) if(!HC_CVAR(s)) return
#define HC_DEPEND_OR(s,code) if(!HC_CVAR(s)) { code return; }
#define HC_DEPEND_WITHVAL(s,v) if(!HC_CVAR(s)) return v

void Handicap_Force(entity e, float hvalue)
{
	local float old;
	old = e.rm_handicap;
	e.rm_handicap = max(0, min(hvalue, 0.99));
	
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

void Handicap_GiveAmmo(entity player, float amount, .float field, float maxammo)
{
	HC_DEPEND_OR("ammo_pickup", {
		player.field = min(player.field + amount, maxammo);
	});
	
	HC_AFFECT_NEGATIVE_CEIL(amount, player);
	
	if(HC_CVAR("ammo_max"))
		HC_AFFECT_NEGATIVE_CEIL(maxammo, player);
	
	player.field = min(player.field + amount, maxammo);
}
