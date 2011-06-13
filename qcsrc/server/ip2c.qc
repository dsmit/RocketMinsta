
void IP2C_SetCountry_Internal(entity player, string cn)
{
    if(player.ip2c_country)
        strunzone(player.ip2c_country);
    
    player.ip2c_country = strzone(cn);
    
    if(player.scorekeeper)
    {
        local float char0, char1;
        cn = strtolower(cn);  // flag icons have lowcase names
        
        char0 = str2chr(substring(cn, 0, 1), 0);
        char1 = str2chr(substring(cn, 1, 1), 0);
        
        player.scorekeeper.SendFlags |= pow(2, SP_CN_CHAR0);
        player.scorekeeper.(scores[SP_CN_CHAR0]) = char0;
        player.scorekeeper.SendFlags |= pow(2, SP_CN_CHAR1);
        player.scorekeeper.(scores[SP_CN_CHAR1]) = char1;
    }
    else
        IP2C_Log(strcat(player.netname, "^7 has no scorekeeper"));
}

void IP2C_LookupForPlayer_Callback(string ip, string cn, entity player)
{
    local entity e;
    FOR_EACH_REALCLIENT(e) if(e.netaddress == ip)
        IP2C_SetCountry_Internal(e, cn);
}

void IP2C_SetCountry(entity player)
{
    if(clienttype(player) != CLIENTTYPE_REAL)
        return;
    
    IP2C_Lookup(player.netaddress, IP2C_LookupForPlayer_Callback, player);
}
