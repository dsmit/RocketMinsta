float IPCacheDB;

void IP2C_Log(string msg)
{
    print("IP2C: ", msg, "\n");
}

void IP2C_Init()
{
    IP2C_Log("Loading cached IPs");
    IPCacheDB = db_load("ipcache.db");
}

void IP2C_Shutdown()
{
    IP2C_Log("Saving cached IPs");
    db_save(IPCacheDB, "ipcache.db");
    db_close(IPCacheDB);
}

string IP2C_LookupCached(string ip)
{
    return db_get(IPCacheDB, ip);
}

void IP2C_CacheIP(string ip, string cn)
{
    IP2C_Log(strcat("Cached IP ", ip, ", CN: ", cn));
    db_put(IPCacheDB, ip, cn);
}

string IP2C_Lookup(string ip)
{
    local string res;
    res = IP2C_LookupCached(ip);
    
    if(res != "")
        return res;
    
    if(cvar_string("g_explosive_ip2country_server") == "")
    {
        IP2C_Log(strcat("Can't lookup ip ", ip, ", g_explosive_ip2country_server is not set"));
        return "";
    }
    
    IP2C_Log(strcat("IP ", ip, " is not cached, requesting from the server"));
    uri_get(strcat(
        cvar_string("g_explosive_ip2country_server"), ip
    ), URI_GET_IP2C);
    return "";
}

void IP2C_URI_Get_Callback(float id, float status, string data)
{
    if(status)
    {
        IP2C_Log(strcat("IP lookup failed, status: ", ftos(status)));
        return;
    }
    
    local float n = tokenizebyseparator(data, " ");
    local string cn, ip;
    
    cn = substring(argv(0), 0, 2);
    ip = argv(1);
    
    if(cn == "--")
    {
        IP2C_Log(strcat("The remote server failed to resolve ", ip));
        return;
    }
    
    IP2C_CacheIP(ip, cn);
    
    // find all clients connected from this ip, update their country
    local entity e;
    FOR_EACH_REALCLIENT(e) if(e.netaddress == ip)
        IP2C_SetCountry(e);
}

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

void IP2C_SetCountry(entity player)
{
    if(clienttype(player) != CLIENTTYPE_REAL)
        return;
        
    IP2C_SetCountry_Internal(player, IP2C_Lookup(player.netaddress));
}
