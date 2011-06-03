#ifdef INTERFACE
CLASS(RMHudSkinList) EXTENDS(NexuizListBox)
	METHOD(RMHudSkinList, configureRMHudSkinList, void(entity))
	ATTRIB(RMHudSkinList, fontSize, float, SKINFONTSIZE_NORMAL)
	ATTRIB(RMHudSkinList, scrollbarWidth, float, SKINWIDTH_SCROLLBAR)
	ATTRIB(RMHudSkinList, src, string, SKINGFX_SCROLLBAR)
	ATTRIB(RMHudSkinList, tolerance, vector, SKINTOLERANCE_SLIDER)
	ATTRIB(RMHudSkinList, rowsPerItem, float, 1)
	METHOD(RMHudSkinList, resizeNotify, void(entity, vector, vector, vector, vector))
	METHOD(RMHudSkinList, drawListBoxItem, void(entity, float, vector, float))
	METHOD(RMHudSkinList, setSelected, void(entity, float))
	METHOD(RMHudSkinList, keyDown, float(entity, float, float, float))
	METHOD(RMHudSkinList, mouseDrag, float(entity, vector))
	ATTRIB(RMHudSkinList, color, vector, SKINCOLOR_SCROLLBAR_N)
	ATTRIB(RMHudSkinList, colorF, vector, SKINCOLOR_SCROLLBAR_F)
	ATTRIB(RMHudSkinList, color2, vector, SKINCOLOR_SCROLLBAR_S)
	ATTRIB(RMHudSkinList, colorC, vector, SKINCOLOR_SCROLLBAR_C)
	ATTRIB(RMHudSkinList, skinlist_buf, float, -1)
ENDCLASS(RMHudSkinList)
entity makeRMHudSkinList();
#endif

#ifdef IMPLEMENTATION
entity makeRMHudSkinList()
{
	entity me;
	me = spawnRMHudSkinList();
	me.configureRMHudSkinList(me);
	return me;
}

void setSelectedRMHudSkinList(entity me, float i)
{
	if(!me.disabled)
		setSelectedListBox(me, i);
}

float keyDownRMHudSkinList(entity me, float key, float ascii, float shift)
{
	if(!me.disabled)
		return keyDownListBox(me, key, ascii, shift);
	return 0;
}

float mouseDragRMHudSkinList(entity me, vector pos)
{
	if(!me.disabled)
		return mouseDragListBox();
	return 0;
}

void configureRMHudSkinListRMHudSkinList(entity me)
{
	local float i;
	i = -1;
	me.configureNexuizListBox(me);
	
	if(me.skinlist_buf > -1)
		buf_del(me.skinlist_buf);
	
	me.skinlist_buf = buf_create();
	bufstr_set(me.skinlist_buf, ++i, "Replace this");
	bufstr_set(me.skinlist_buf, ++i, "once hud_skinsystem");
	bufstr_set(me.skinlist_buf, ++i, "is merged");
	me.nItems = buf_getsize(me.skinlist_buf);
}

void resizeNotifyRMHudSkinList(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
{
	resizeNotifyNexuizListBox(me, relOrigin, relSize, absOrigin, absSize);

	me.realFontSize_y = me.fontSize / (absSize_y * me.itemHeight);
	me.realFontSize_x = me.fontSize / (absSize_x * (1 - me.controlWidth));
	me.realUpperMargin = 0.5 * (1 - me.realFontSize_y);
}

void setDependent_Check(entity);
void drawListBoxItemRMHudSkinList(entity me, float i, vector absSize, float isSelected)
{
	local string s;
	local float amod;
	amod = (me.disabled? 0.2:1);
	
	if(isSelected)
		draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED * amod);
	
	s = bufstr_get(me.skinlist_buf, i);
	draw_Text(me.realUpperMargin2 * eY + (me.columnNameOrigin + 0.00 * (me.columnNameSize - draw_TextWidth(s, 1) * me.realFontSize_x)) * eX, s, me.realFontSize, '1 1 1', 1 * amod, 1);
}
#endif
