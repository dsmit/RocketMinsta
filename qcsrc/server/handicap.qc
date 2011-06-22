
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
	damage *= (1 - attacker.rm_handicap);
	damage *= (1 + targ.rm_handicap);
	return damage;
}
