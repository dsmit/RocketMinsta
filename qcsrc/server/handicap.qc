
#define HC_AFFECT_POSITIVE(f,e) f = f * (1 + (e).rm_handicap)
#define HC_AFFECT_NEGATIVE(f,e) f = f * (1 - (e).rm_handicap)

#define HC_DEPEND(s) if(!cvar(s)) return
#define HC_DEPEND_WITHVAL(s,v) if(!cvar(s)) return v

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
	HC_DEPEND_WITHVAL("g_explosive_handicap_affects_damage", damage);
	
	HC_AFFECT_NEGATIVE(damage, attacker);
	HC_AFFECT_POSITIVE(damage, targ);
	return damage;
}

void Handicap_ApplyStartAmmo(entity player)
{
	HC_DEPEND("g_explosive_handicap_affects_ammo_start");
	
	HC_AFFECT_NEGATIVE(self.ammo_shells, self);
	HC_AFFECT_NEGATIVE(self.ammo_nails, self);
	HC_AFFECT_NEGATIVE(self.ammo_rockets, self);
	HC_AFFECT_NEGATIVE(self.ammo_cells, self);
	HC_AFFECT_NEGATIVE(self.ammo_fuel, self);
}
