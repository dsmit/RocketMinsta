
// Handgrenades mutator
// Intended for the Camping Rifle Arena mode

void HG_Attack()
{
	if(time < self.hg_next || !self.hg_ammo)
		return;
	
	makevectors(self.v_angle);
	W_Grenade_Attack2_Real(self.hg_power, self.hg_power == 1); // hack hack
	self.hg_next = time + cvar("g_explosive_handgrenades_mindelay");
	self.hg_ammo -= 1;
}

void HG_Frame()
{
	if(!g_handgrenades)
		return;
	
	float held;
	held = self.BUTTON_HG;
	
	if((self.hg_power && !self.hg_state		)||
	   (g_freezetag && self.freezetag_frozen))
			held = 0;
	
	if(held && held != self.hg_state && !self.hg_ammo && self.deadflag == DEAD_NO)
		bigprint_spec(self, "out of grenades", "", 1);
	
	if(held && time >= self.hg_next && self.hg_ammo)
		self.hg_power = bound(0,
			self.hg_power + frametime *
			cvar("g_explosive_handgrenades_speed"),
		1);
	else
	{
		self.hg_power = bound(0,
			self.hg_power - frametime *
			cvar("g_explosive_handgrenades_clearspeed"),
		1);
		
		if(self.hg_state)
			HG_Attack();
	}
	
	if(self.hg_power == 1)
		HG_Attack(); 	// inhand explosion
	
	self.hg_state = held;
}

void HG_PlayerSpawn()
{
	self.hg_power = 0;
	self.hg_ammo = cvar("g_explosive_handgrenades_ammo");
}
