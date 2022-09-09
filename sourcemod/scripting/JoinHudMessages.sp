#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <adminmenu>
#include <cstrike>
#include <multicolors>

#pragma newdecls required

int g_iMessagesCount = -1;

char g_kvPath[PLATFORM_MAX_PATH];

Handle g_hHudMsg;

public Plugin myinfo =
{
	name 			= "JoinHudMessages",
	author 			= "Dolly",
	description 	= "Send multiple hud messages when someone joins server",
	version 		= "1.0",
	url 			= ""
};

enum struct MsgIndexData
{
    float MsgTime;
    float HoldTime;
    char Message[124];
    int color[4];
}

MsgIndexData MsgData[500];

public void OnPluginStart()
{
    BuildPath(Path_SM, g_kvPath, sizeof(g_kvPath), "configs/JoinHudMessages.cfg");
    if(!FileExists(g_kvPath))
        SetFailState("Missing file %s", g_kvPath);
    
    g_hHudMsg = CreateHudSynchronizer();
    
    RegAdminCmd("sm_reloadhudmsgs", Command_Hud, ADMFLAG_GENERIC);
}

public Action Command_Hud(int client, int args)
{
    OnMapStart();
    CReplyToCommand(client, "{green}[SM] {default}Successfully reloaded all messages from config");
    return Plugin_Handled;
}
    
public void OnMapStart()
{
    g_iMessagesCount = -1;
    
    KeyValues Kv = new KeyValues("HudMessages");
    if(!Kv.ImportFromFile(g_kvPath))
        return;
    
    if(!Kv.GotoFirstSubKey())
        return;
    
    do
    {
        char sIndex[10], sMessage[124];
        Kv.GetSectionName(sIndex, sizeof(sIndex));
        float time = Kv.GetFloat("MsgTime");
        float holdtime = Kv.GetFloat("HoldTime");
        Kv.GetString("Message", sMessage, sizeof(sMessage));
        int index = StringToInt(sIndex);
        
        // let's store message index data:
        MsgData[index].MsgTime = time;
        MsgData[index].HoldTime = holdtime;
        Format(MsgData[index].Message, 124, sMessage);
        MsgData[index].color[0] = Kv.GetNum("r");
        MsgData[index].color[1] = Kv.GetNum("g");
        MsgData[index].color[2] = Kv.GetNum("b");
        MsgData[index].color[3] = Kv.GetNum("a");
        
        g_iMessagesCount++;
    }
    while(Kv.GotoNextKey());
    
    delete Kv;
}

public void OnClientPostAdminCheck(int client)
{
    for(int i = 0; i <= g_iMessagesCount; i++)
    {
    	DataPack pack;
        CreateDataTimer(MsgData[i].MsgTime, HudMessage_Timer, pack);
        pack.WriteCell(GetClientUserId(client));
    	pack.WriteCell(i);
    }
}

public Action HudMessage_Timer(Handle timer, DataPack pack)
{
    pack.Reset();
    int userid = pack.ReadCell();
    int client = GetClientOfUserId(userid);
    int index = pack.ReadCell();
    
    if(!IsClientInGame(client))
        return Plugin_Stop;    

    SetHudTextParams(-1.0, 0.2, MsgData[index].HoldTime, MsgData[index].color[0], MsgData[index].color[1], MsgData[index].color[2], MsgData[index].color[3]);
    ShowSyncHudText(client, g_hHudMsg, MsgData[index].Message);
    return Plugin_Continue;
}
