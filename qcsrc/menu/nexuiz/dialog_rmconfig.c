#ifdef INTERFACE
CLASS(NexuizRMConfigDialog) EXTENDS(NexuizRootDialog)
	METHOD(NexuizRMConfigDialog, fill, void(entity)) // to be overridden by user to fill the dialog with controls
	METHOD(NexuizRMConfigDialog, showNotify, void(entity))
	ATTRIB(NexuizRMConfigDialog, title, string, "RocketMinsta Configuration")
	ATTRIB(NexuizRMConfigDialog, color, vector, SKINCOLOR_DIALOG_TEAMSELECT)
	ATTRIB(NexuizRMConfigDialog, intendedWidth, float, 0.6)
	ATTRIB(NexuizRMConfigDialog, rows, float, 12)
	ATTRIB(NexuizRMConfigDialog, columns, float, 16)
	ATTRIB(NexuizRMConfigDialog, name, string, "RMConfig")
	ATTRIB(NexuizRMConfigDialog, team1, entity, NULL)
	ATTRIB(NexuizRMConfigDialog, team2, entity, NULL)
	ATTRIB(NexuizRMConfigDialog, team3, entity, NULL)
	ATTRIB(NexuizRMConfigDialog, team4, entity, NULL)
ENDCLASS(NexuizRMConfigDialog)
#endif

#ifdef IMPLEMENTATION

void showNotifyNexuizRMConfigDialog(entity me)
{
	float teams, nTeams;
	teams = cvar("_teams_available");
	nTeams = 0;
	me.team1.disabled = !(teams & 1); nTeams += !!(teams & 1);
	me.team2.disabled = !(teams & 2); nTeams += !!(teams & 2);
	me.team3.disabled = !(teams & 4); nTeams += !!(teams & 4);
	me.team4.disabled = !(teams & 8); nTeams += !!(teams & 8);
}

void fillNexuizRMConfigDialog(entity me)
{
	entity e;
	me.TR(me);
		me.TD(me, 1, 4, e = makeRMCheckBox(0, "showspec", "Show spectators"));
	me.TR(me);
		me.TD(me, 1, 4, e = makeRMCheckBox(0, "showdamage", "Hit/damage indicator"));
	me.TR(me);
		me.TD(me, 1, 4, e = makeRMCheckBox(0, "crosshealth", "Color crosshair by health"));
	me.TR(me);
		me.TD(me, 1, 4, e = makeRMCheckBox(0, "shownames", "Show player names above their heads"));
	me.TR(me);
		me.TD(me, 1, 4, e = makeRMCheckBox(0, "visualscore", "Visualize score"));
	me.TR(me);
		me.TD(me, 1, 4, e = makeRMCheckBox(0, "teamlasers", "Teamcolored lasers"));
	me.TR(me);
		me.TD(me, 1, 4, e = makeRMCheckBox(0, "legacyvote", "Simple voting screen"));
	me.TR(me);
		me.TD(me, 1, 4, e = makeRMCheckBox(1, "simpleeffects", "Effects for textual notifications"));
	me.TR(me);
		me.TD(me, 1, 4, e = makeRMCheckBox(0, "anonspec", "Spectate anonymously"));
	me.TR(me);
		me.TD(me, 1, 4, e = makeRMCheckBox(0, "nobigtext", "Disable big notifications"));
	me.TR(me);
		me.TD(me, 1, 4, e = makeRMCheckBox(1, "noflags", "Country flags in scoreboard"));
	me.TR(me);
		me.TD(me, 1, me.columns, e = makeNexuizButton("Ok", '0 0 0'));
			e.onClick = Dialog_Close;
			e.onClickEntity = me;
	
	me.gotoRC(me, 0, 8); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 4, e = makeNexuizTextLabel(0, "HUD settings:"));
	me.setFirstColumn(me, me.firstColumn + 0.1);
	me.TR(me);
		me.TD(me, 1, 4, e = makeRMCheckBox(0, "oldhud", "Use default Nexuiz HUD"));
	me.TR(me);
		me.TD(me, 1, 4, e = makeRMCheckBox(0, "althud", "Use an alternative HUD layout"));
		setDependent(e, "rm_oldhud", 0, 0);
	me.setFirstColumn(me, me.firstColumn - 0.1);
		me.TR(me);
		me.TD(me, 1, 4, e = makeNexuizTextLabel(0, "HUD skin:"));
		setDependent(e, "rm_oldhud", 0, 0);
	me.TR(me);
		me.TD(me, me.rows - 5, 8, e = makeRMHudSkinList());
		setDependent(e, "rm_oldhud", 0, 0);
		
}
#endif

/* Click. The c-word is here so you can grep for it :-) */
