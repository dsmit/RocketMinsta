#ifdef INTERFACE
CLASS(RMCheckBox) EXTENDS(NexuizCheckBox)
	METHOD(RMCheckBox, loadCvars, void(entity))
	METHOD(RMCheckBox, saveCvars, void(entity))
ENDCLASS(RMCheckBox)
entity makeRMCheckBox(float, string, string);
entity makeRMCheckBoxEx(float, float, string, string);
#endif

#ifdef IMPLEMENTATION

entity makeRMCheckBox(float isInverted, string theCvar, string theText)
{
	float y, n;
	if(isInverted > 1)
	{
		n = isInverted - 1;
		y = -n;
	}
	else if(isInverted < -1)
	{
		n = isInverted + 1;
		y = -n;
	}
	else if(isInverted == 1)
	{
		n = 1;
		y = 0;
	}
	else
	{
		n = 0;
		y = 1;
	}
	return makeRMCheckBoxEx(y, n, theCvar, theText);
}

entity makeRMCheckBoxEx(float theYesValue, float theNoValue, string theCvar, string theText)
{
	entity me;
	me = spawnRMCheckBox();
	me.configureNexuizCheckBox(me, theYesValue, theNoValue, theCvar, theText);
	return me;
}

void loadCvarsRMCheckBox(entity me)
{
	float m, d;

	if not(me.cvarName)
		return;

	m = (me.yesValue + me.noValue) * 0.5;
	d = (cvar(strcat("rm_", me.cvarName)) - m) / (me.yesValue - m);
	me.checked = (d > 0);
}
void saveCvarsRMCheckBox(entity me)
{
	if not(me.cvarName)
		return;

	if(me.checked)
		//cvar_set(me.cvarName, ftos(me.yesValue));
		localcmd(me.cvarName, " ", ftos(me.yesValue), "\n");
	else
		//cvar_set(me.cvarName, ftos(me.noValue));
		localcmd(me.cvarName, " ", ftos(me.noValue), "\n");
}
#endif
