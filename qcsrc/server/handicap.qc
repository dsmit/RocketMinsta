
void Handicap_Set(entity e, float hvalue)
{
	e.rm_handicap = max(0, min(hvalue, 0.99));
	bprint(self.netname, "^7's handicap is now ", ftos(self.rm_handicap), "\n");
}

float Handicap_ApplyDamage(float damage, entity attacker, entity targ)
{
	damage *= (1 - attacker.rm_handicap);
	damage *= (1 + targ.rm_handicap);
	return damage;
}
