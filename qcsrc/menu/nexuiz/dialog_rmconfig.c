#ifdef INTERFACE
CLASS(NexuizRMConfigDialog) EXTENDS(NexuizRootDialog)
	METHOD(NexuizRMConfigDialog, fill, void(entity)) // to be overridden by user to fill the dialog with controls
	ATTRIB(NexuizRMConfigDialog, title, string, "RocketMinsta Configuration")
	ATTRIB(NexuizRMConfigDialog, color, vector, SKINCOLOR_DIALOG_TEAMSELECT)
	ATTRIB(NexuizRMConfigDialog, intendedWidth, float, 0.8)
	ATTRIB(NexuizRMConfigDialog, rows, float, 19)
	ATTRIB(NexuizRMConfigDialog, columns, float, 16)
	ATTRIB(NexuizRMConfigDialog, name, string, "RMConfig")
ENDCLASS(NexuizRMConfigDialog)
#endif

#ifdef IMPLEMENTATION

#define OPTDEP(o) setDependent(e, "_rm_optavail_"##o, 1, 1);

void fillNexuizRMConfigDialog(entity me)
{
	entity e;
	me.TR(me);
		me.TD(me, 1, 4, e = makeRMCheckBox(0, "showspec", "Show spectators"));
			OPTDEP("showspec")
	me.TR(me);
		me.TD(me, 1, 4, e = makeRMCheckBox(0, "showdamage", "Hit/damage indicator"));
			OPTDEP("showdamage")
	me.TR(me);
		me.TD(me, 1, 4, e = makeRMCheckBox(0, "crosshealth", "Color crosshair by health"));
	me.TR(me);
		me.TD(me, 1, 4, e = makeRMCheckBox(0, "shownames", "Show player names above their heads"));
			OPTDEP("shownames")
	me.TR(me);
		me.TD(me, 1, 4, e = makeRMCheckBox(0, "visualscore", "Visualize score"));
	me.TR(me);
		me.TD(me, 1, 4, e = makeRMCheckBox(0, "teamlasers", "Teamcolored lasers"));
			OPTDEP("teamlasers")
	me.TR(me);
		me.TD(me, 1, 4, e = makeRMCheckBox(0, "legacyvote", "Simple voting screen"));
	me.TR(me);
		me.TD(me, 1, 4, e = makeRMCheckBox(1, "simpleeffects", "Effects for textual notifications"));
	me.TR(me);
		me.TD(me, 1, 4, e = makeRMCheckBox(0, "anonspec", "Spectate anonymously"));
			OPTDEP("anonspec")
	me.TR(me);
		me.TD(me, 1, 4, e = makeRMCheckBox(1, "nobigtext", "Enable big notifications"));
	me.setFirstColumn(me, me.firstColumn + 0.1);
	me.TR(me);
		me.TD(me, 1, 4, e = makeRMCheckBox(1, "hidebigcomments", "with comments"));
		setDependent(e, "rm_nobigtext", 0, 0);
	me.setFirstColumn(me, me.firstColumn - 0.1);
	me.TR(me);
		me.TD(me, 1, 4, e = makeRMCheckBox(1, "noflags", "Country flags in scoreboard"));
	me.TR(me);
		me.TD (me, 1, 4, e = makeRMCheckBox (1, "hidecountry", "Show my country flag"));
			OPTDEP("hidecountry")
	me.TR(me);
		me.TD(me, 1, 4, e = makeRMCheckBox(1, "notimer", "\"time\" column in scoreboard"));
	me.TR(me);
		me.TD(me, 1, 4, e = makeRMCheckBox(1, "nokillsound", "Separate kill and hit sounds"));
	me.TR(me);
		me.TD(me, 1, 4, e = makeRMCheckBox(1, "nogamemenu", "Enable the Game Menu"));
	me.TR(me);
		me.TD(me, 1, 4, e = makeRMCheckBox(1, "hidewatermark", "Show version information"));
	me.TR(me);
		me.TD(me, 1, 4, e = makeNexuizTextLabel(0, "Note: You can access these options through Multiplayer -> Player Setup"));
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
		me.TD(me, me.rows - 6, 8, e = makeRMHudSkinList());
		setDependent(e, "rm_oldhud", 0, 0);
		
}
#endif

/* Click. The c-word is here so you can grep for it :-) */
