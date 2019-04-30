#if defined _stripweapons_included
  #endinput
#endif
#define _stripweapons_included

#include <fakemeta>
#include <hamsandwich>	



/*
 * Strips a player's weapon based on type.
 * 
 * @param id:	Player id
 * @param type:	Weapon type (check enum below for types)
 * @param bSwitchIfActive:	Switch to other weapon before stripping 
 *							if stripped weapon is currently deployed
 * @return:	1 on success, otherwise 0
 *
 * Ex: 	StripWeapons(id, Secondary);	// Strips secondary weapon with switching if deployed.
 *		StripWeapons(iPlayer, C4, false);	// Strips c4 without switching if deployed.
 */
enum /* Weapon types */
{
	Primary = 1
	, Secondary
	, Knife
	, Grenades
	, C4
};


stock StripWeapons(id, Type, bool: bSwitchIfActive = true)
{
	new iReturn;
	
	if(is_user_alive(id))
	{
		new iEntity, iWeapon;
		while((iWeapon = GetWeaponFromSlot(id, Type, iEntity)) > 0)
			iReturn = ham_strip_user_weapon(id, iWeapon, Type, bSwitchIfActive);
	}
	
	return iReturn;
}
	
		
/*
 * bugsy
 * http://forums.alliedmods.net/showpost.php?p=1575989&postcount=2
 *
 * Gets a weapon entity id based on inventory slot.
 *
 * @param id:			Player id
 * @param iSlot:		Inventory slot you want to get the weaponid from
 * @param &iEntity:		Weapon entity id
 * @return:				Weapon CSW_* index on success, otherwise 0
 *
 * Ex: GetWeaponFromSlot(id, 3, iEntity);	// Should return CSW_KNIFE if player has one. 
 *											// Knife is always in 3th slot (if not changed with plugin or something);
*/
stock GetWeaponFromSlot( id , iSlot , &iEntity )
{
	if ( !( 1 <= iSlot <= 5 ) )
		return 0;
	
	iEntity = 0;
	const m_rgpPlayerItems_Slot0 = 367;
	const m_iId = 43;
	const XO_WEAPONS = 4;
	const XO_PLAYER = 5;
		
	iEntity = get_pdata_cbase( id , m_rgpPlayerItems_Slot0 + iSlot , XO_PLAYER );
	
	return ( iEntity > 0 ) ? get_pdata_int( iEntity , m_iId , XO_WEAPONS ) : 0;
}  


/*
 * ConnorMcLeod
 * http://forums.alliedmods.net/showpost.php?p=1109747&postcount=42
 *
 * Strips a player's weapon based on weapon index.
 *
 * @param id:				Player id
 * @param iCswId:			Weapon CSW_* index
 * @param iSlot:			Inventory slot (Leave 0 if not sure)
 * @param bSwitchIfActive:	Switch weapon if currently deployed
 * @return:	1 on success, otherwise 0
 *
 * Ex: 	ham_strip_user_weapon(id, CSW_M4A1); 	// Strips m4a1 if user has one.
 * 		ham_strip_user_weapon(id, CSW_HEGRENADE, _, false);		// Strips HE grenade if user has one 
 *																// without switching weapons.
*/
stock ham_strip_user_weapon(id, iCswId, iSlot = 0, bool:bSwitchIfActive = true)
{
	new iWeapon
	if( !iSlot )
	{
		static const iWeaponsSlots[] = {
			-1,
			2, //CSW_P228
			-1,
			1, //CSW_SCOUT
			4, //CSW_HEGRENADE
			1, //CSW_XM1014
			5, //CSW_C4
			1, //CSW_MAC10
			1, //CSW_AUG
			4, //CSW_SMOKEGRENADE
			2, //CSW_ELITE
			2, //CSW_FIVESEVEN
			1, //CSW_UMP45
			1, //CSW_SG550
			1, //CSW_GALIL
			1, //CSW_FAMAS
			2, //CSW_USP
			2, //CSW_GLOCK18
			1, //CSW_AWP
			1, //CSW_MP5NAVY
			1, //CSW_M249
			1, //CSW_M3
			1, //CSW_M4A1
			1, //CSW_TMP
			1, //CSW_G3SG1
			4, //CSW_FLASHBANG
			2, //CSW_DEAGLE
			1, //CSW_SG552
			1, //CSW_AK47
			3, //CSW_KNIFE
			1 //CSW_P90
		}
		iSlot = iWeaponsSlots[iCswId]
	}

	const XTRA_OFS_PLAYER = 5
	const m_rgpPlayerItems_Slot0 = 367

	iWeapon = get_pdata_cbase(id, m_rgpPlayerItems_Slot0 + iSlot, XTRA_OFS_PLAYER)

	const XTRA_OFS_WEAPON = 4
	const m_pNext = 42
	const m_iId = 43

	while( iWeapon > 0 )
	{
		if( get_pdata_int(iWeapon, m_iId, XTRA_OFS_WEAPON) == iCswId )
		{
			break
		}
		iWeapon = get_pdata_cbase(iWeapon, m_pNext, XTRA_OFS_WEAPON)
	}

	if( iWeapon > 0 )
	{
		const m_pActiveItem = 373
		if( bSwitchIfActive && get_pdata_cbase(id, m_pActiveItem, XTRA_OFS_PLAYER) == iWeapon )
		{
			ExecuteHamB(Ham_Weapon_RetireWeapon, iWeapon)
		}

		if( ExecuteHamB(Ham_RemovePlayerItem, id, iWeapon) )
		{
			user_has_weapon(id, iCswId, 0)
			ExecuteHamB(Ham_Item_Kill, iWeapon)
			return 1
		}
	}

	return 0
} 
	