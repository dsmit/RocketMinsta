#ifdef INTERFACE
CLASS(NexuizVoteList) EXTENDS(NexuizListBox)
	METHOD(NexuizVoteList, configureNexuizVoteList, void(entity))
	METHOD(NexuizVoteList, drawListBoxItem, void(entity, float, vector, float))
	METHOD(NexuizVoteList, loadCvars, void(entity))
	METHOD(NexuizVoteList, setSelected, void(entity, float))
	METHOD(NexuizVoteList, resizeNotify, void(entity, vector, vector, vector, vector))
	METHOD(NexuizVoteList, RMUpdate, void(entity))
	ATTRIB(NexuizVoteList, RMUpdatable, float, TRUE)
	ATTRIB(NexuizVoteList, textBox, entity, NULL)
ENDCLASS(NexuizVoteList)
entity makeNexuizVoteList();
#endif

#ifdef IMPLEMENTATION

#define MAX_VOTES 100
string votelist[MAX_VOTES];
float numvotes;

void RMUpdateNexuizVoteList(entity me)
{
	me.loadCvars(me);
}

entity makeNexuizVoteList(void)
{
	entity me;
	me = spawnNexuizVoteList();
	me.configureNexuizVoteList(me);
	return me;
}

void configureNexuizVoteListNexuizVoteList(entity me)
{
	me.loadCvars(me);
	me.configureNexuizListBox(me);
}

void setSelectedNexuizVoteList(entity me, float i)
{
	setSelectedListBox(me, i);
    string s = strcat(votelist[i], " ");
    me.textBox.setText(me.textBox, s);
    me.textBox.cursorPos = strlen(s);
}

void loadCvarsNexuizVoteList(entity me)
{
    local float i, limit;
    numvotes = tokenizebyseparator(cvar_string("_vote_commands"), " ");
    limit = min(MAX_VOTES, numvotes);
    
    for(i = 0; i < limit; i++)
    {
        if(votelist[i])
            strunzone(votelist[i]);
        
        votelist[i] = strzone(argv(i));
    }
    
    me.nItems = limit;
}

void resizeNotifyNexuizVoteList(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
{
	resizeNotifyNexuizListBox(me, relOrigin, relSize, absOrigin, absSize);

	me.realFontSize_y = me.fontSize / (absSize_y * me.itemHeight);
	me.realFontSize_x = me.fontSize / (absSize_x * (1 - me.controlWidth));
	me.realUpperMargin = 0.5 * (1 - me.realFontSize_y);
}

void drawListBoxItemNexuizVoteList(entity me, float i, vector absSize, float isSelected)
{
	string s;
	if(isSelected)
		draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);
	s = votelist[i];
	draw_Text(me.realUpperMargin * eY + (me.columnNameOrigin) * eX, s, me.realFontSize, '1 1 1', SKINALPHA_TEXT, 0);
}

#endif

