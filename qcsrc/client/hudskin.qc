
#define FREE(s) if(s) { strunzone(s); s = string_null; }

void HUDSkin_Unload()
{
    FREE(hudskin_image_border_left)
    FREE(hudskin_image_border_right)
    FREE(hudskin_image_line_fill)
    FREE(hudskin_image_sector_fill_left)
    FREE(hudskin_image_sector_fill_center)
    FREE(hudskin_image_sector_fill_right)
    
    hudskin_size_border_left = '0 0 0';
    hudskin_size_border_right = '0 0 0';
    hudskin_offset_border_left = '0 0 0';
    hudskin_offset_border_right = '0 0 0';
    hudskin_scale_border_left = 0;
    hudskin_scale_border_right = 0;
    hudskin_border_simple = 0;
    hudskin_width_border_left = 0;
    hudskin_width_border_right = 0;
    hudskin_border_teamcolor = TC_NEVER;
    hudskin_sector_teamcolor = TC_NEVER;
    hudskin_border_teamcolor_brightness = 0;
    hudskin_sector_teamcolor_brightness = 0;
    hudskin_sector_color = '0 0 0';
    hudskin_border_color = '0 0 0';
    hudskin_sector_alpha = 0;
    hudskin_border_alpha = 0;
    hudskin_line_color = '0 0 0';
    hudskin_line_alpha = 0;
    hudskin_flash_alphamod = 0;
    hudskin_flash_intmod = 0;
    hudskin_border_drawflag = DRAWFLAG_NORMAL;
    hudskin_sector_padding_left = 0;
    hudskin_sector_padding_right = 0;
    hudskin_sector_padding_top = 0;
    hudskin_sector_padding_bottom = 0;
    hudskin_sector_teamcolor_mod = '0 0 0';
    hudskin_sector_teamcolor_mod_red = '0 0 0';
    hudskin_sector_teamcolor_mod_blue = '0 0 0';
    hudskin_sector_teamcolor_mod_yellow = '0 0 0';
    hudskin_sector_teamcolor_mod_pink = '0 0 0';
    hudskin_border_teamcolor_mod = '0 0 0';
    hudskin_border_teamcolor_mod_red = '0 0 0';
    hudskin_border_teamcolor_mod_blue = '0 0 0';
    hudskin_border_teamcolor_mod_yellow = '0 0 0';
    hudskin_border_teamcolor_mod_pink = '0 0 0';
    hudskin_line_full = FALSE;
    hudskin_flash_line_imod = 0;
    hudskin_flash_line_amod = 0;
    hudskin_flash_sector_imod = 0;
    hudskin_flash_sector_amod = 0;
    hudskin_flash_border_imod = 0;
    hudskin_flash_border_amod = 0;
    hudskin_line_fill = FILL_COLOR;
    hudskin_size_line_fill = '0 0 0';
    hudskin_sector_fill = FILL_COLOR;
    hudskin_size_sector_fill_center = '0 0 0';
    hudskin_size_sector_fill_left = '0 0 0';
    hudskin_size_sector_fill_right = '0 0 0';
    
    print("Unloaded HUD skin\n");
    
    if(hudskin_name)
    {
        fstrunzone(hudskin_name);
        hudskin_name = string_null;
    }
}

float HUDSkin_ReadTC()
{
    switch(argv(1))
    {
        case "none": case "never":
            return TC_NEVER;
        
        case "all": case "always":
            return TC_ALWAYS;
        
        case "some":
            return TC_SOME;
        
        default:
            return TC_WTF;
    }
}

vector HUDSkin_ReadColor()
{
    local vector v;
    v_x = stof(argv(1));
    v_y = stof(argv(2));
    v_z = stof(argv(3));
    return v;
}

float HUDSkin_ReadDrawFlag()
{
    switch(argv(1))
    {
        case "normal":
            return DRAWFLAG_NORMAL;
        
        case "additive":
            return DRAWFLAG_ADDITIVE;
        
        default:
            return -1;
    }
}

float HUDSkin_ReadBool()
{
    switch(argv(1))
    {
        case "true": case "yes": case "1":
            return TRUE;
        
        case "false": case "no": case "0":
            return FALSE;
        
        default:
            return (stof(argv(1))? TRUE : FALSE);
    }
}

float HUDSkin_ReadFillMode()
{
    switch(argv(1))
    {
        case "color":
            return FILL_COLOR;
        
        case "tile":
            return FILL_TILE;
        
        case "stretch":
            return FILL_STRETCH;
        
        default: return FILL_WTF;
    }
}

float HUDSkin_Eval(string cmd)
{
    local float n = tokenize_console(cmd);
    
    switch(argv(0))
    {
        case "border_left_scale":
            hudskin_scale_border_left = stof(argv(1));
            return TRUE;
        
        case "border_right_scale":
            hudskin_scale_border_right = stof(argv(1));
            return TRUE;
        
        case "border_left_offset":
            hudskin_offset_border_left_x = stof(argv(1));
            hudskin_offset_border_left_y = stof(argv(2));
            return TRUE;
        
        case "border_right_offset":
            hudskin_offset_border_right_x = stof(argv(1));
            hudskin_offset_border_right_y = stof(argv(2));
            return TRUE;
        
        case "border_simple":
            hudskin_border_simple = stof(argv(1));
            return TRUE;
        
        case "border_left_width":
            hudskin_width_border_left = stof(argv(1));
            return TRUE;
        
        case "border_right_width":
            hudskin_width_border_right = stof(argv(1));
            return TRUE;
        
        case "border_teamcolor":
            hudskin_border_teamcolor = HUDSkin_ReadTC();
            
            if(hudskin_border_teamcolor == TC_WTF)
            {
                print("HUDSkin_Eval: Invalid value for ", argv(0), ": ", argv(1), "\n");
                hudskin_border_teamcolor = TC_NEVER;
                return FALSE;
            }
            
            return TRUE;
        
        case "sector_teamcolor":
            hudskin_sector_teamcolor = HUDSkin_ReadTC();
            
            if(hudskin_sector_teamcolor == TC_WTF)
            {
                print("HUDSkin_Eval: Invalid value for ", argv(0), ": ", argv(1), "\n");
                hudskin_sector_teamcolor = TC_NEVER;
                return FALSE;
            }
            
            return TRUE;
        
        case "border_teamcolor_brightness":
            hudskin_border_teamcolor_brightness = stof(argv(1));
            return TRUE;
        
        case "sector_teamcolor_brightness":
            hudskin_sector_teamcolor_brightness = stof(argv(1));
            return TRUE;
        
        case "sector_color":
            hudskin_sector_color = HUDSkin_ReadColor();
            return TRUE;
            
        case "border_color":
            hudskin_border_color = HUDSkin_ReadColor();
            return TRUE;
        
        case "sector_alpha":
            hudskin_sector_alpha = stof(argv(1));
            return TRUE;
            
        case "border_alpha":
            hudskin_border_alpha = stof(argv(1));
            return TRUE;
        
        case "line_color":
            hudskin_line_color = HUDSkin_ReadColor();
            return TRUE;
        
        case "line_alpha":
            hudskin_line_alpha = stof(argv(1));
            return TRUE;
        
        case "flash_alphamod":
            hudskin_flash_alphamod = stof(argv(1));
            return TRUE;
            
        case "flash_intmod":
            hudskin_flash_intmod = stof(argv(1));
            return TRUE;
        
        case "border_drawmode":
            hudskin_border_drawflag = HUDSkin_ReadDrawFlag();
            
            if(hudskin_border_drawflag == -1)
            {
                print("HUDSkin_Eval: Invalid value for ", argv(0), ": ", argv(1), "\n");
                hudskin_border_drawflag = DRAWFLAG_NORMAL;
                return FALSE;
            }
            
            return TRUE;
        
        case "sector_padding":
            hudskin_sector_padding_left = stof(argv(1));
            hudskin_sector_padding_right = stof(argv(2));
            hudskin_sector_padding_top = stof(argv(3));
            hudskin_sector_padding_bottom = stof(argv(4));
            return TRUE;
        
        case "sector_teamcolor_mod":
            hudskin_sector_teamcolor_mod = HUDSkin_ReadColor();
            return TRUE;
        
        case "sector_teamcolor_mod_red":
            hudskin_sector_teamcolor_mod_red = HUDSkin_ReadColor();
            return TRUE;
            
        case "sector_teamcolor_mod_blue":
            hudskin_sector_teamcolor_mod_blue = HUDSkin_ReadColor();
            return TRUE;
        
        case "sector_teamcolor_mod_yellow":
            hudskin_sector_teamcolor_mod_yellow = HUDSkin_ReadColor();
            return TRUE;
        
        case "sector_teamcolor_mod_pink":
            hudskin_sector_teamcolor_mod_pink = HUDSkin_ReadColor();
            return TRUE;
        
        case "border_teamcolor_mod":
            hudskin_border_teamcolor_mod = HUDSkin_ReadColor();
            return TRUE;
            
        case "border_teamcolor_mod_red":
            hudskin_border_teamcolor_mod_red = HUDSkin_ReadColor();
            return TRUE;
        
        case "border_teamcolor_mod_blue":
            hudskin_border_teamcolor_mod_blue = HUDSkin_ReadColor();
            return TRUE;
        
        case "border_teamcolor_mod_yellow":
            hudskin_border_teamcolor_mod_yellow = HUDSkin_ReadColor();
            return TRUE;
        
        case "border_teamcolor_mod_pink":
            hudskin_border_teamcolor_mod_pink = HUDSkin_ReadColor();
            return TRUE;
        
        case "line_full":
            hudskin_line_full = HUDSkin_ReadBool();
            return TRUE;
        
        case "flash_line_imod":
            hudskin_flash_line_imod = stof(argv(1));
            return TRUE;
        
        case "flash_line_amod":
            hudskin_flash_line_amod = stof(argv(1));
            return TRUE;
            
        case "flash_sector_imod":
            hudskin_flash_sector_imod = stof(argv(1));
            return TRUE;
        
        case "flash_sector_amod":
            hudskin_flash_sector_amod = stof(argv(1));
            return TRUE;
        
        case "flash_border_imod":
            hudskin_flash_border_imod = stof(argv(1));
            return TRUE;
        
        case "flash_border_amod":
            hudskin_flash_border_amod = stof(argv(1));
            return TRUE;
        
        case "extern_image_border_left":
            FREE(hudskin_image_border_left)
            hudskin_image_border_left = strzone(argv(1));
            hudskin_size_border_left = drawgetimagesize(hudskin_image_border_left);
            return TRUE;
        
        case "extern_image_border_right":
            FREE(hudskin_image_border_right)
            hudskin_image_border_right = strzone(argv(1));
            hudskin_size_border_right = drawgetimagesize(hudskin_image_border_right);
            return TRUE;
        
        case "line_fill":
            hudskin_line_fill = HUDSkin_ReadFillMode();
            
            if(hudskin_line_fill == FILL_WTF)
            {
                print("HUDSkin_Eval: Invalid value for ", argv(0), ": ", argv(1), "\n");
                hudskin_line_fill = FILL_COLOR;
                return FALSE;
            }
            
            return TRUE;
        
        case "extern_image_line_fill":
            FREE(hudskin_image_line_fill)
            hudskin_image_line_fill = strzone(argv(1));
            return TRUE;
        
        case "extern_image_sector_fill_left":
            FREE(hudskin_image_sector_fill_left)
            hudskin_image_sector_fill_left = strzone(argv(1));
            hudskin_size_sector_fill_left = drawgetimagesize(hudskin_image_sector_fill_left);
            return TRUE;
        
        case "extern_image_sector_fill_right":
            FREE(hudskin_image_sector_fill_right)
            hudskin_image_sector_fill_right = strzone(argv(1));
            hudskin_size_sector_fill_right = drawgetimagesize(hudskin_image_sector_fill_left);
            return TRUE;
        
        case "extern_image_sector_fill_center":
            FREE(hudskin_image_sector_fill_center)
            hudskin_image_sector_fill_center = strzone(argv(1));
            hudskin_size_sector_fill_center = drawgetimagesize(hudskin_image_sector_fill_left);
            return TRUE;
        
        case "sector_fill":
			hudskin_sector_fill = HUDSkin_ReadFillMode();
            
            if(hudskin_line_fill == FILL_WTF)
            {
                print("HUDSkin_Eval: Invalid value for ", argv(0), ": ", argv(1), "\n");
                hudskin_sector_fill = FILL_COLOR;
                return FALSE;
            }
            
            return TRUE;
        
        default:
            print("HUDSkin_Eval: Invalid key ", argv(0), "\n");
            return FALSE;
    }
}

float HUDSkin_Load(string skin)
{
    HUDSkin_Unload();
    
    local float fh, n, err;
    local string s;
    
    fh = fopen(strcat("gfx/hud/skins/", skin, "/skininfo"), FILE_READ);
    if(fh < 0)
    {
        if(skin == HUDSKIN_DEFAULT)
        {
            print("Failed to load skininfo for the default HUD skin '", skin, "', something is really screwed up\n");
            return FALSE;
        }
        else
        {
            print("Failed to load skininfo for HUD skin '", skin, "', falling back to '", HUDSKIN_DEFAULT, "'\n");
            HUDSkin_Load(HUDSKIN_DEFAULT);
            return FALSE;
        }
    }
    
    hudskin_image_border_left = strzone(strcat("gfx/hud/skins/", skin, "/border_left"));
    hudskin_image_border_right = strzone(strcat("gfx/hud/skins/", skin, "/border_right"));
    hudskin_image_line_fill = strzone(strcat("gfx/hud/skins/", skin, "/line_fill"));
    hudskin_image_sector_fill_left = strzone(strcat("gfx/hud/skins/", skin, "/sector_fill_left"));
    hudskin_image_sector_fill_center = strzone(strcat("gfx/hud/skins/", skin, "/sector_fill_center"));
    hudskin_image_sector_fill_right = strzone(strcat("gfx/hud/skins/", skin, "/sector_fill_right"));
    
    while((s = fgets(fh)))
        err += !HUDSkin_Eval(s);
    
    if(err)
        print(ftos(err), " errors in skininfo\n");
    
    fclose(fh);
    
    hudskin_size_border_left = drawgetimagesize(hudskin_image_border_left);
    hudskin_size_border_right = drawgetimagesize(hudskin_image_border_right);
    hudskin_size_line_fill = drawgetimagesize(hudskin_image_line_fill);
    hudskin_size_sector_fill_center = drawgetimagesize(hudskin_image_sector_fill_center);
    hudskin_size_sector_fill_left = drawgetimagesize(hudskin_image_sector_fill_left);
    hudskin_size_sector_fill_right = drawgetimagesize(hudskin_image_sector_fill_right);
    
    print("Loaded HUD skin '", skin, "'\n");
    hudskin_name = strzone(skin);
    localcmd("cmd hudinfo ", cvar_string("rm_oldhud"), " ", cvar_string("rm_althud"), " ", hudskin_name, "\n");
    
    return TRUE;
}

float HUDSkin_GetBorderWidth(float border)
{
    if(hudskin_border_simple)
        return hudskin_border_simple;
    
    if(border == BORDER_LEFT)
        return hudskin_width_border_left;
    return hudskin_width_border_right;
}

vector HUDSkin_GetTeamColorMod_Sector(float color)
{
    switch(color)
    {
        default         : return '0 0 0';
        case COLOR_TEAM1: return hudskin_sector_teamcolor_mod_red;
        case COLOR_TEAM2: return hudskin_sector_teamcolor_mod_blue;
        case COLOR_TEAM3: return hudskin_sector_teamcolor_mod_yellow;
        case COLOR_TEAM4: return hudskin_sector_teamcolor_mod_pink;
    }
}

vector HUDSkin_GetTeamColorMod_Border(float color)
{
    switch(color)
    {
        default         : return '0 0 0';
        case COLOR_TEAM1: return hudskin_border_teamcolor_mod_red;
        case COLOR_TEAM2: return hudskin_border_teamcolor_mod_blue;
        case COLOR_TEAM3: return hudskin_border_teamcolor_mod_yellow;
        case COLOR_TEAM4: return hudskin_border_teamcolor_mod_pink;
    }
}

