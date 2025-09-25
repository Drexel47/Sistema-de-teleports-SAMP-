enum TeleportData {
   
    ID, //ID de la Base de Datos
    PIDIG, 
    PickupID, //ID del pickup de entrada
    PickupIDGo, //Id del pickup de salida
    Float:PosX, //Posicion del pickup
	Float:PosY,
	Float:PosZ,
	Float:PosZZ, //Rotacion del jugador al cambiar de posicion
	Interior,
	VW,  // Virtual World del pickup
	Lock,
	Dueno, //0=Jugador Normal 1 = Hotel 2 = Banco 3 = Museo
	NombreTele[60], //Nombre de destino
	Text3D:PickupText //ID para mostrar en texto 3D del destino
	
	
}

new Iterator:Tele_iter<MAX_TELEPORTS>; // Lista dinámica de teleports
new Teleports[MAX_TELEPORTS][TeleportData]; // Información de cada teleport



public CargarTP()
{
    new Query[128];
    format(Query, sizeof(Query), "SELECT * FROM `teleports`");
    mysql_tquery(database, Query, "_CargarTeleports");
   
    return 1;
}




public _CargarTeleports()
{
    new rows;
    rows = cache_num_rows();
    if(rows == 0) return printf("No se encontraron Teleports.");
      

    for (new i = 0; i < rows; i++) 
    {
        new tid = Iter_Free(Tele_iter); // Obtiene un nuevo índice dinámicamente
        if (tid == -1) continue; // Si no hay espacio, omitimos

        cache_get_value_int(i, "ID", Teleports[tid][ID]);
        cache_get_value_name(i, "NombreTele", Teleports[tid][NombreTele], 50);
        //cache_get_value_name(i, "PickupText", Teleports[tid][PickupText], 60);
        cache_get_value_float(i, "PosX", Teleports[tid][PosX]);
        cache_get_value_float(i, "PosY", Teleports[tid][PosY]);
        cache_get_value_float(i, "PosZ", Teleports[tid][PosZ]);
        cache_get_value_float(i, "PosZZ", Teleports[tid][PosZZ]);
        cache_get_value_int(i, "Interior", Teleports[tid][Interior]);
        cache_get_value_int(i, "World", Teleports[tid][VW]);
        cache_get_value_int(i, "Lock", Teleports[tid][Lock]);
        cache_get_value_int(i, "Dueno", Teleports[tid][Dueno]);
        cache_get_value_int(i, "PickupID", Teleports[tid][PickupID]);
        cache_get_value_int(i, "PickupIDGo", Teleports[tid][PickupIDGo]);
        
        Teleports[tid][PIDIG] = CreateDynamicPickup(19198, 1, 
            Teleports[tid][PosX], Teleports[tid][PosY], Teleports[tid][PosZ], 
            Teleports[tid][VW], Teleports[tid][Interior]);

        
        SetStyleTextDrawTeles(i, Teleports[i][NombreTele],false);
        Iter_Add(Tele_iter, tid);
    }

    printf("[TELEPORTS]: %d Pickups creados dinámicamente.", rows);
    return 1;
}



stock CrearTeleport(playerid, dueno)
{

    new Float:x, Float:y, Float:z, Float:angle;
	new interior, world;
    //Obtener datos del Jugador
	GetPlayerPos(playerid, x, y, z);
    GetPlayerFacingAngle(playerid, angle);
    interior = GetPlayerInterior(playerid);
    world = GetPlayerVirtualWorld(playerid);
	//Obtener indices disponibles
	// Buscar el primer índice libre
    new tid1 = Iter_Free(Tele_iter);

    if (tid1 == cellmin) return Notificaciones(playerid, TELEPORTS, "No hay espacio para mas teleports");


	Iter_Add(Tele_iter, tid1);

	// Buscar el segundo índice libre
    new tid2 = Iter_Free(Tele_iter);
    if (tid2 == cellmin) {
        Iter_Remove(Tele_iter, tid1); // Si no hay un segundo espacio, revertimos el primero
        
        return Notificaciones(playerid, TELEPORTS, "No hay espacio para el segundo teleport, removiendo el primer teleport");
    }

    Iter_Add(Tele_iter, tid2);

   	printf("[DEBUG] TELE ID1: %i, TELE ID2: %i", tid1, tid2);
	
	// Agregar teleports a la lista
    Iter_Add(Tele_iter, tid1);
    Iter_Add(Tele_iter, tid2);
	printf("[DEBUG] ID libre: %i", tid1);
	printf("[DEBUG] ID libre: %i", tid2);

    // Definir los valores al 1er teleport
    //Teleports[tid1][ID] = tid1;
    Teleports[tid1][PosX] = x;
    Teleports[tid1][PosY] = y;
    Teleports[tid1][PosZ] = z + 0.2;
    Teleports[tid1][PosZZ] = angle;
    Teleports[tid1][Interior] = interior;
    Teleports[tid1][VW] = world;
    Teleports[tid1][Dueno] = dueno;
    Teleports[tid1][Lock] = false;
    Teleports[tid1][PickupID] = tid1;
    Teleports[tid1][PickupIDGo] = tid2; //Conexion entre teleports
    format(Teleports[tid1][NombreTele], 50, "Puerta");
    
	//Definir los valores al 2do teleport
    //Teleports[tid2][ID] = tid2;
    Teleports[tid2][PosX] = x + 1;
    Teleports[tid2][PosY] = y + 2;
    Teleports[tid2][PosZ] = z + 0.2;
    Teleports[tid2][PosZZ] = angle;
    Teleports[tid2][Interior] = interior;
    Teleports[tid2][VW] = world;
    Teleports[tid2][Dueno] = dueno;
    Teleports[tid2][Lock] = false;
    Teleports[tid2][PickupID] = tid2;
	Teleports[tid2][PickupIDGo] = tid1; //Conexion entre teleports
	format(Teleports[tid2][NombreTele], 50, "Salida");

	// Crear pickups
    Teleports[tid1][PIDIG] = CreateDynamicPickup(19198, 1, 
        Teleports[tid1][PosX], Teleports[tid1][PosY], Teleports[tid1][PosZ], 
        Teleports[tid1][VW], Teleports[tid1][Interior]);

    Teleports[tid2][PIDIG] = CreateDynamicPickup(19198, 1, 
        Teleports[tid2][PosX], Teleports[tid2][PosY], Teleports[tid2][PosZ], 
        Teleports[tid2][VW], Teleports[tid2][Interior]);
	
	// Crear textdraws
    //SetStyleTextDrawTeles(tid1, TeleportData[tid1][NombreTele], false);
    //SetStyleTextDrawTeles(tid2, TeleportData[tid2][NombreTele], false);

    // Guardar en base de datos
    new Query[500];
    mysql_format(database, Query, sizeof(Query), "INSERT INTO `teleports` (PickupID, PosX, PosY, PosZ, PosZZ, Interior, World, Dueno, PickupIDGo) VALUES ('%d', '%f', '%f', '%f', '%f', '%d', '%d', '%d', '%d')",
        Teleports[tid1][PickupID], 
		Teleports[tid1][PosX], 
		Teleports[tid1][PosY], 
		Teleports[tid1][PosZ], 
		Teleports[tid1][PosZZ], 
        Teleports[tid1][Interior], 
		Teleports[tid1][VW], 
		Teleports[tid1][Dueno], 
		Teleports[tid1][PickupIDGo]);
    mysql_tquery(database, Query, "TeleportGenerado", "i", tid1);

    mysql_format(database, Query, sizeof(Query), "INSERT INTO `teleports` (PickupID, PosX, PosY, PosZ, PosZZ, Interior, World, Dueno, PickupIDGo) VALUES ('%d', '%f', '%f', '%f', '%f', '%d', '%d', '%d', '%d')",
        Teleports[tid2][PickupID], 
		Teleports[tid2][PosX], 
		Teleports[tid2][PosY], 
		Teleports[tid2][PosZ], 
		Teleports[tid2][PosZZ], 
        Teleports[tid2][Interior], 
		Teleports[tid2][VW], 
		Teleports[tid2][Dueno], 
		Teleports[tid2][PickupIDGo]);

    mysql_tquery(database, Query, "TeleportGenerado", "i", tid2);

    // Mensaje al jugador
    new msg[250];
    format(msg, sizeof(msg), "Teleport creado: Entrada (ID %d), Salida (ID %d). Usa /editartpp para modificar posiciones.", tid1, tid2);
    Notificaciones(playerid, ADMINISTRACION, msg);

    return 1;
	
}

public TeleportGenerado(tid)
{
    new id = cache_insert_id();

    Teleports[tid][ID] = id;

    printf("[Debug] Teleport creado con ID de BD: %d y en memoria: %d", id, tid);

    return 1;
}

public ModificarTelePublic(playerid, pos)
{
    new tid = -1;
    // Buscar el teleport por su PickupID en lugar de usar IdentificarPickup
    foreach (new i : Tele_iter)
    {
        if (Teleports[i][PickupID] == pos)
        {
            tid = i;
            break;
        }
    }
    new InfoMessage[250];
    //printf("ACA esta el %d",tid);
    if (tid != -1)
    {   
        new Float:MyPosX, Float:MyPosY, Float:MyPosZ, Float:MyPosZZ;
        new MyInterior, MyWorld;

        GetPlayerPos(playerid, MyPosX, MyPosY, MyPosZ);
        GetPlayerFacingAngle(playerid, MyPosZZ);

        MyInterior = GetPlayerInterior(playerid);
        MyWorld = GetPlayerVirtualWorld(playerid);

        // Modificar teleport
        Teleports[tid][PosX] = MyPosX;
        Teleports[tid][PosY] = MyPosY;
        Teleports[tid][PosZ] = MyPosZ + 0.2;
        Teleports[tid][PosZZ] = MyPosZZ;
        Teleports[tid][Interior] = MyInterior;
        Teleports[tid][VW] = MyWorld;

        new LastPickup = Teleports[tid][PIDIG];
        DestroyDynamicPickup(LastPickup);
        

        
        SetStyleTextDrawTeles(tid, Teleports[tid][NombreTele], true);

        Teleports[tid][PIDIG] = CreateDynamicPickup(19198, 1, 
            Teleports[tid][PosX], Teleports[tid][PosY], Teleports[tid][PosZ], 
            Teleports[tid][VW], Teleports[tid][Interior]);

        //SetStyleTextDrawTeles(tid, TeleportData[tid][NombreTele], true);

        
        format(InfoMessage, sizeof(InfoMessage), 
            "Posición del pickup ID %d modificada a %f, %f, %f con interior %d y mundo %d", 
            LastPickup, Teleports[tid][PosX], Teleports[tid][PosY], Teleports[tid][PosZ], 
            Teleports[tid][Interior], Teleports[tid][VW]);

        Notificaciones(playerid, TELEPORTS, InfoMessage); //Notificacion Teleports
        if (LastPickup != Teleports[tid][PIDIG])
        {
            format(InfoMessage, sizeof(InfoMessage), "La ID del pickup cambió a %d", Teleports[tid][PIDIG]);
            Notificaciones(playerid, TELEPORTS, InfoMessage);
        }
        //printf("%i", LastPickup);
        // Guardar cambios en la base de datos
        new query[512];
        format(query, sizeof(query), "UPDATE teleports SET PosX = %f, PosY = %f, PosZ = %f, PosZZ = %f, Interior = %d, World = %d WHERE ID = %d",\
            Teleports[tid][PosX], Teleports[tid][PosY], Teleports[tid][PosZ], Teleports[tid][PosZZ], 
            Teleports[tid][Interior], Teleports[tid][VW], Teleports[tid][ID]); // Corregido
        
        
        printf("Editar Tp: %s",query);
        mysql_tquery(database, query);

        return true;
    }
    else
    {
        format(InfoMessage, sizeof(InfoMessage), "El pickup que desea editar no existe o pertenece a otra clase de pickups!");
        Notificaciones(playerid, TELEPORTS, InfoMessage);
        return false;
    }

}

stock VerificarTeleport(playerid)
{
    new tid = TeleportCercano(playerid, 2.0);

    if( tid == -1) return 0;

    new destino = Teleports[tid][PickupIDGo];
    
    printf("destino: %i", destino);
    if(destino != -1) defer SetTeleportUserPos(playerid, destino); 
    
        //if(Teleports[destino][VW] == 0 && Teleports[destino][Interior] == 0) 
        
        //else defer SetTeleportUserPos(playerid, destino, Teleports[destino][Interior], Teleports[destino][VW]); 
    
    
    return 1;

}
//Timer encargado de teletransportar al jugador
timer SetTeleportUserPos[1500](playerid, destino)
{
    printf("destino: %i", destino);
    // Congelar al jugador mientras carga el interior
    TogglePlayerControllable(playerid, false);

    SetPlayerVirtualWorld(playerid, Teleports[destino][VW]);
    printf("destino world: %i", Teleports[destino][VW]);

	SetPlayerInterior(playerid, Teleports[destino][Interior]);
    printf("destino interior: %i", Teleports[destino][Interior]);

	SetPlayerFacingAngle(playerid, Teleports[destino][PosZZ]);
    printf("destino rot: %f", Teleports[destino][PosZZ]);

    SetCameraBehindPlayer(playerid);
	SetPlayerPos(playerid, Teleports[destino][PosX], Teleports[destino][PosY], Teleports[destino][PosZ]-0.2);
    printf("destino x: %f, y: %f, z: %f", Teleports[destino][PosX], Teleports[destino][PosY], Teleports[destino][PosZ]);
    defer UnFreezeUser(playerid);
}





stock TeleportCercano(playerid, Float:distancia)
{
    new tid = -1;
    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);

    foreach (new i : Tele_iter)
    {
        new Float:dist = GetDistanceBetweenPoints(x, y, z, Teleports[i][PosX], Teleports[i][PosY], Teleports[i][PosZ]);
                
        if (dist < distancia)
        {
            distancia = dist;
            tid = i; // Guardamos la ID IG del vehículo más cercano
        }
    }
    
    return tid; 
}
stock IdentificarPickup(playerid)
{
    new tid = TeleportCercano(playerid, 5.0);
    if(tid == -1) return Notificaciones(playerid, TELEPORTS, "No estas cerca de algun Teleport!");
   

    SendClientMessage(playerid, -1, "Estás en el Teleport con ID: %i(DB), %i(IG) y Pickup %i", Teleports[tid][ID], Teleports[tid][PickupID], Teleports[tid][PIDIG]);
    return 1;
}

forward SetStyleTextDrawTeles(textdrawid, const text[], bool:Update);
public SetStyleTextDrawTeles(textdrawid, const text[], bool:Update)
{
	if(Update)
	{
		DestroyDynamic3DTextLabel(Teleports[textdrawid][PickupText]);

	}

	new TextDrawTeleText[500];
    format(TextDrawTeleText, sizeof(TextDrawTeleText), "{0097FF}Lugar: {FFFFFF}%s\n\n{FFFFFF}Presione {FB0000}ENTER", text);
   	Teleports[textdrawid][PickupText] = CreateDynamic3DTextLabel(TextDrawTeleText, -1, Teleports[textdrawid][PosX], Teleports[textdrawid][PosY], Teleports[textdrawid][PosZ], 6.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, Teleports[textdrawid][VW], Teleports[textdrawid][Interior]);

}


stock EditarAngTele(playerid)
{
    new tid = TeleportCercano(playerid, 5.0);
    if(tid == -1) return Notificaciones(playerid, TELEPORTS, "No se encontraron Teleports!");
    GetPlayerFacingAngle(playerid, Teleports[tid][PosZZ]);
    ActualizarTeleRot(playerid, tid);
    return 1;
}

forward ActualizarTeleRot(playerid, tid);
public ActualizarTeleRot(playerid, tid)
{
    new query[256], msg[64];

    format(query, sizeof(query), "UPDATE teleports SET PosZZ = %f  WHERE ID = %i",
    Teleports[tid][PosZZ],
    Teleports[tid][ID]
    );
    printf("Query telerot %s", query);
    mysql_tquery(database, query);

    format(msg, sizeof(msg), "Actualizaste el angulo del Teleport %i", Teleports[tid][ID]);
    Notificaciones(playerid, TELEPORTS, msg);
    return 1;
}


//--------------------------------------------------------------------------------------------------------------------------------------
//TELEPORTS
//--------------------------------------------------------------------------------------------------------------------------------------

CMD:creartpp(playerid, params[])
{
    new duenotp;
    if(sscanf(params, "d", duenotp)) return SendClientMessage(playerid, -1, "Usa /creartpp [Dueno]");

    CrearTeleport(playerid, duenotp);
    return 1;
}

CMD:editartpp(playerid, params[])
{
    new pickupid;

    if(sscanf(params, "d", pickupid)) return SendClientMessage(playerid, -1, "Usa /editartpp [id_pickup]");

    ModificarTelePublic(playerid, pickupid);

    return 1;
}


CMD:identificarpickup(playerid, params[]){

    if(!isnull(params)) return 0;
    IdentificarPickup(playerid);

    return 1;
}

COMMAND:editartelerot(playerid, params[])
{
    if(!isnull(params)) return 0;

    EditarAngTele(playerid);

    return 1;
}


timer UnFreezeUser[500](playerid)
{

    TogglePlayerControllable(playerid, true);

}