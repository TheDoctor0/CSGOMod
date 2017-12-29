#if defined _csgomod_included
  #endinput
#endif
#define _csgomod_included

/*----------------------------
------------NATYWY------------
----------------------------*/

/*------------------------------
Zwraca czy gracz zostal zalogowany.
Jesli nie jest zalogowany wymusza logowanie.
------------------------------*/
native csgo_check_account(id);

/*------------------------------
Zwraca stan konta euro gracza.
------------------------------*/
native Float:csgo_get_money(id);

/*------------------------------
Dodaje wartosc do stanu konta euro gracza.
Wartosc moze byc zarowno dodatnia jak i ujemna.
------------------------------*/
native csgo_add_money(id, Float:money);

/*------------------------------
Ustawia wartość stanu konta euro gracza.
------------------------------*/
native csgo_set_money(id, Float:money);

/*------------------------------
Zwraca id wykonywanej operacji.
-1 w przypadku braku operacji.
------------------------------*/
native csgo_get_user_operation(id);

/*------------------------------
Zwraca opis wykonywanej opracji.
Format: "x/x (x.x%)"
"Wpisz /operacja" w przypadku braku operacji.
------------------------------*/
native csgo_get_user_operation_text(id, dataReturn[], dataLength);

/*------------------------------
Zwraca progres wykonania operacji.
-1 w przypadku braku operacji.
------------------------------*/
native csgo_get_user_operation_progress(id);

/*------------------------------
Zwraca ogolna liczbe jednostek wymagana do zakonczenia w wykonywanej opracji.
-1 w przypadku braku operacji.
------------------------------*/
native csgo_get_user_operation_need(id);

/*------------------------------
Zwraca id skina broni trzymanej przez gracza.
-1 w przypadku braku skina.
------------------------------*/
native csgo_get_skin(id);

/*------------------------------
Zwraca nazwe skina o podanym id - skin.
"Domyslny" w przypadku braku skina o podanym id.
------------------------------*/
native csgo_get_skin_name(skin, dataReturn[], dataLength);

/*------------------------------
Zwraca nazwe skina aktualnie trzymanej broni.
"Domyslny" w przypadku braku skina.
------------------------------*/
native csgo_get_current_skin_name(id, dataReturn[], dataLength);

/*------------------------------
Zwraca id klanu gracza.
0 w przypadku braku klanu.
------------------------------*/
native csgo_get_user_clan(id);

/*------------------------------
Zwraca nazwe klanu o podanym id - clan.
"Brak" w przypadku braku clanu (id = 0).
------------------------------*/
native csgo_get_clan_name(clan, dataReturn[], dataLength);

/*------------------------------
Zwraca liczbe czlonkow klanu o podanym id - clan.
------------------------------*/
native csgo_get_clan_members(clan);

/*------------------------------
Dodaje zabojstwo do zliczanych statystyk.
------------------------------*/
native csgo_add_kill(id);

/*------------------------------
Zwraca zabojstwa zliczane przez statystyki.
------------------------------*/
native csgo_get_kills(id);

/*------------------------------
Zwraca id rangi gracza.
------------------------------*/
native csgo_get_rank(id);

/*------------------------------
Zwraca nazwe rangi o podanym id - rank.
------------------------------*/
native csgo_get_rank_name(skin, dataReturn[], dataLength);

/*------------------------------
Zwraca nazwe aktualnej rangi gracza.
------------------------------*/
native csgo_get_current_rank_name(id, dataReturn[], dataLength);

/*------------------------------
Zwraca czy gracz posiada konto VIP.
------------------------------*/
native csgo_get_user_vip(id);

/*------------------------------
Zwraca czy gracz posiada konto SVIP.
------------------------------*/
native csgo_get_user_svip(id);

/*------------------------------
-------------FUNKCJE------------
------------------------------*/

#define get_bit(%2,%1) (%1 & (1<<(%2&31)))
#define set_bit(%2,%1) (%1 |= (1<<(%2&31)))
#define rem_bit(%2,%1) (%1 &= ~(1 <<(%2&31)))

#define is_user_valid(%1) (1 <= %1 <= MAX_PLAYERS)

stock mysql_escape_string(const source[], dest[], length)
{
	copy(dest, length, source);
	
	replace_all(dest, length, "\\", "\\\\");
	replace_all(dest, length, "\0", "\\0");
	replace_all(dest, length, "\n", "\\n");
	replace_all(dest, length, "\r", "\\r");
	replace_all(dest, length, "\x1a", "\Z");
	replace_all(dest, length, "'", "\'");
	replace_all(dest, length, "`", "\`");
	replace_all(dest, length, "^"", "\^"");
}

stock cmd_execute(id, const text[], any:...) 
{
	#pragma unused text

	new message[256];

	format_args(message, charsmax(message), 1);

	message_begin(id == 0 ? MSG_ALL : MSG_ONE, SVC_DIRECTOR, _, id);
	write_byte(strlen(message) + 2);
	write_byte(10);
	write_string(message);
	message_end();
}