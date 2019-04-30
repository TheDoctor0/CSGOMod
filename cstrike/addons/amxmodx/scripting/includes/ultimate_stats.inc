#if defined _ultimate_stats_included
	#endinput
#endif
#define _ultimate_stats_included

/**
 * Retrieves the client's current weapon statistics.
 *
 * @note For a list of default CS weapon ids see the CSW_* constants in
 *       amxconst.inc, this function also works on custom weapons.
 * @note For a list of possible body hitplaces see the HIT_* constants in
 *       amxconst.inc
 * @note The fields in the statistics are:
 *          0 - Kills
 *          1 - Deaths
 *          2 - Headshots
 *          3 - Teamkills
 *          4 - Shots
 *          5 - Hits
 *          6 - Damage
 *
 * @param index     Client index
 * @param wpnindex  Weapon id, or 0 to retrieve total statistics across all
 *                  weapons
 * @param stats     Buffer to copy statistics to
 * @param bodyhits  Buffer to copy body hits to
 *
 * @return          1 on success, 0 if no statistics are available for the weapon
 *                  id
 * @error           If an invalid client index or weapon id is provided, an
 *                  error will be thrown.
 */
native get_user_wstats(index, wpnindex, stats[8], bodyhits[8]);

/**
 * Retrieves the client's weapon statistics from the current round.
 *
 * @note For a list of default CS weapon ids see the CSW_* constants in
 *       amxconst.inc, this function also works on custom weapons.
 * @note For a list of possible body hitplaces see the HIT_* constants in
 *       amxconst.inc
 * @note The fields in the statistics are:
 *          0 - Kills
 *          1 - Deaths
 *          2 - Headshots
 *          3 - Teamkills
 *          4 - Shots
 *          5 - Hits
 *          6 - Damage
 *
 * @param index     Client index
 * @param wpnindex  Weapon id, or 0 to retrieve total statistics across all
 *                  weapons
 * @param stats     Buffer to copy statistics to
 * @param bodyhits  Buffer to copy body hits to
 *
 * @return          1 on success, 0 if no statistics are available for the
 *                  weapon id
 * @error           If an invalid client index or weapon id is provided, an
 *                  error will be thrown.
 */
native get_user_wrstats(index, wpnindex, stats[8], bodyhits[8]);

/**
 * Retrieves the client's weapon statistics.
 *
 * @note For a list of possible body hitplaces see the HIT_* constants in
 *       amxconst.inc
 * @note The fields in the statistics are:
 *          0 - Kills
 *          1 - Deaths
 *          2 - Headshots
 *          3 - Teamkills
 *          4 - Shots
 *          5 - Hits
 *          6 - Damage
 *          7 - Rank
 *
 * @param index     Client index
 * @param stats     Buffer to copy statistics to
 * @param bodyhits  Buffer to copy body hits to
 *
 * @return          Players rank > 0 on success, or 0 if player is not ranked
 *                  and no statistics are available
 * @error           If an invalid client index is provided, an error will be
 *                  thrown.
 */
native get_user_stats(index, stats[8], bodyhits[8]);

/**
 * Retrieves the client's statistics from the current round.
 *
 * @note For a list of possible body hitplaces see the HIT_* constants in
 *       amxconst.inc
 * @note The fields in the statistics are:
 *          0 - Kills
 *          1 - Deaths
 *          2 - Headshots
 *          3 - Teamkills
 *          4 - Shots
 *          5 - Hits
 *          6 - Damage
 *
 * @param index     Client index
 * @param stats     Buffer to copy statistics to
 * @param bodyhits  Buffer to copy body hits to
 *
 * @return          1 on success, 0 if no statistics are available
 * @error           If an invalid client index is provided, an error will be
 *                  thrown.
 */
native get_user_rstats(index, stats[8], bodyhits[8]);

/**
 * Retrieves the client's statistics inflicted upon another client from the
 * current round.
 *
 * @note For a list of possible body hitplaces see the HIT_* constants in
 *       amxconst.inc
 * @note The fields in the statistics are:
 *          0 - Kills
 *          1 - Deaths
 *          2 - Headshots
 *          3 - Teamkills
 *          4 - Shots
 *          5 - Hits
 *          6 - Damage
 *
 * @param index     Client index
 * @param victim    Victim client index, or 0 to retrieve the statistics against
 *                  all victims
 * @param stats     Buffer to copy statistics to
 * @param bodyhits  Buffer to copy body hits to
 * @param wpnname   Optional buffer to copy last used weapon name to
 * @param len       Maximum buffer size
 *
 * @return          1 on success, 0 if no statistics are available against the
 *                  specified victim
 * @error           If an invalid client index is provided, an error will be
 *                  thrown.
 */
native get_user_vstats(index, victim, stats[8], bodyhits[8], wpnname[] = "", len = 0);

/**
 * Retrieves the client's statistics received from another client from the
 * current round.
 *
 * @note For a list of possible body hitplaces see the HIT_* constants in
 *       amxconst.inc
 * @note The fields in the statistics are:
 *          0 - Kills
 *          1 - Deaths
 *          2 - Headshots
 *          3 - Teamkills
 *          4 - Shots
 *          5 - Hits
 *          6 - Damage
 *
 * @param index     Client index
 * @param wpnindex  Attacker client index, or 0 to retrieve the statistics from
 *                  all attackers
 * @param stats     Buffer to copy statistics to
 * @param bodyhits  Buffer to copy body hits to
 * @param wpnname   Optional buffer to copy last used weapon name to
 * @param len       Maximum buffer size
 *
 * @return          1 on success, 0 if no statistics are available against the
 *                  specified attacker
 * @error           If an invalid client index is provided, an error will be
 *                  thrown.
 */
native get_user_astats(index, wpnindex, stats[8], bodyhits[8], wpnname[] = "", len = 0);

/**
 * Resets the current round weapon, attacker and victim statistics.
 *
 * @param index     Client index
 *
 * @noreturn
 * @error           If an invalid client index is provided, an error will be
 *                  thrown.
 */
native reset_user_wstats(index);

/**
 * Retrieves statistics from the permanent storage on the server via iterative,
 * incremental access.
 *
 * @note For a list of possible body hitplaces see the HIT_* constants in
 *       amxconst.inc
 * @note The fields in the statistics are:
 *          0 - Kills
 *          1 - Deaths
 *          2 - Headshots
 *          3 - Teamkills
 *          4 - Shots
 *          5 - Hits
 *          6 - Damage
 *          7 - Rank
 *
 * @param index         Rank index
 * @param stats         Buffer to copy statistics to
 * @param bodyhits      Buffer to copy body hits to
 * @param name          Buffer to copy client name to
 * @param len           Maximum name buffer size
 * @param authid        Buffer to copy client auth id to
 * @param authidlen     Maximum authid buffer size
 *
 * @return              Next rank index (> 0 and > index), or 0 if no more
 *                      statistics exist
 */
native get_stats(index, stats[8], bodyhits[8], name[], len, authid[] = "", authidlen = 0);

/**
 * Returns the number of all entries in the permanent statistics storage.
 *
 * @return  Number of entries in statistics storage
 */
native get_statsnum();

/**
 * Retrieves the client's objective statistics.
 *
 * @note The fields in the statistics are:
 *          0 - total defusions
 *          1 - bomb defused
 *          2 - bomb plants
 *          3 - bomb explosions
 *
 * @param index     Client index
 * @param stats     Buffer to copy statistics to
 *
 * @return          Players rank > 0 on success, or 0 if player is not ranked
 *                  and no statistics are available
 * @error           If an invalid client index is provided, an error will be
 *                  thrown.
 */
native get_user_stats2(index, stats[4]);

/**
 * Retrieves objective statistics via iterative, incremental access.
 *
 * @note The fields in the statistics are:
 *          0 - total defusions
 *          1 - bomb defused
 *          2 - bomb plants
 *          3 - bomb explosions
 *
 * @param index         Client index
 * @param stats         Buffer to copy statistics to
 * @param authid        Buffer to copy client auth id to
 * @param authidlen     Maximum authid buffer size
 *
 * @return              Next rank index (> 0 and > index), or 0 if no more
 *                      statistics exist
 */
native get_stats2(index, stats[4], authid[] = "", authidlen = 0);

/**
 * Returns total time spent on server.
 *
 * @param index         Client index
 *
 * @return              Total time online on server
 */
native get_user_total_time(index);

/**
 * Retrieves elo rank.
 *
 * @param index         Client index
 *
 * @return              Elo rank
 * @error               If an invalid client index is provided, an error will be
 *                      thrown.
 */
native Float:get_user_elo(index);

/**
 * Adds value to elo rank.
 *
 * @param index         Client index
 * @param elo           Value to add
 *
 * @return              1 on success, 0 on error
 * @error               If an invalid client index is provided, an error will be
 *                      thrown.
 */
native add_user_elo(index, Float:elo);

/**
 * Called after a client attacks another client.
 *
 * @note For a list of possible weapon ids see the CSW_* constants in
 *       amxconst.inc
 * @note For a list of possible body hitplaces see the HIT_* constants in
 *       amxconst.inc
 *
 * @param attacker  Attacker client index
 * @param victim    Victim client index
 * @param damage    Damage dealt to victim
 * @param wpnindex  Weapon id
 * @param hitplace  Body hitplace
 * @param ta        If nonzero the attack was a team attack
 *
 * @noreturn
 */
forward client_damage(attacker, victim, damage, wpnindex, hitplace, TA);

/**
 * Called after a client death.
 *
 * @note For a list of possible weapon ids see the CSW_* constants in
 *       amxconst.inc
 * @note For a list of possible body hitplaces see the HIT_* constants in
 *       amxconst.inc
 *
 * @param attacker  Attacker client index
 * @param victim    Victim client index
 * @param wpnindex  Weapon id
 * @param hitplace  Body hitplace
 * @param tk        If nonzero the death was a teamkill
 *
 * @noreturn
 */
forward client_death(killer, victim, wpnindex, hitplace, TK);

/**
 * Called after a client kill with assist.
 *
 * @param killer    Killer client index
 * @param victim    Victim client index
 * @param assistant Assistant client index
 *
 * @noreturn
 */
forward client_assist(killer, victim, assistant);

/**
 * Called after a client kill with assist.
 *
 * @param killer    Killer client index
 * @param victim    Victim client index
 * @param assistant Assistant client index
 *
 * @noreturn
 */
forward client_assist(killer, victim, assistant);

/**
 * Called after a revenge kill.
 *
 * @param killer    Killer client index
 * @param victim    Victim client index
 *
 * @noreturn
 */
forward client_revenge(killer, victim);

/**
 * Called after a grenade was thrown.
 *
 * @note Weapon id is one of CSW_HEGRENADE, CSW_SMOKEGRENADE or CSW_FLASHBANG.
 *
 * @param index     Client index
 * @param greindex  Grenade entity index
 * @param wId       Weapon id
 *
 * @noreturn
 */
forward grenade_throw(index, greindex, wId);

/**
 * Called after a bomb plant attempt has started.
 *
 * @param planter   Planter client index
 *
 * @noreturn
 */
forward bomb_planting(planter);

/**
 * Called after a bomb plant has finished.
 *
 * @param planter   Planter client index
 *
 * @noreturn
 */
forward bomb_planted(planter);

/**
 * Called when the bomb exploded.
 *
 * @param planter   Planter client index
 * @param defuser   Defuser client index, if applicable
 *
 * @noreturn
 */
forward bomb_explode(planter, defuser);

/**
 * Called after a bomb defuse attempt has started.
 *
 * @param defuser   Defuser client index
 *
 * @noreturn
 */
forward bomb_defusing(defuser);

/**
 * Called after a bomb defuse has finished.
 *
 * @param defuser   Defuser client index
 *
 * @noreturn
 */
forward bomb_defused(defuser);

/**
 * Called after client stats loading has finished.
 *
 * @param index   Client index
 *
 * @noreturn
 */
forward stats_loaded(index);
