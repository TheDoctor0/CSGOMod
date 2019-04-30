
/*
	Unix Time Conversion
	     by bugsy
	       v0.3
	
	http://forums.alliedmods.net/showthread.php?t=91915
	
	TimeZone data: http://www.epochconverter.com/epoch/timezones.php
*/

#if defined _file_unixtime_included
	#endinput
#endif
#define _file_unixtime_included

stock const YearSeconds[2] = 
{ 
	31536000,	//Normal year
	31622400 	//Leap year
};

stock const MonthSeconds[12] = 
{ 
	2678400, //January	31 
	2419200, //February	28
	2678400, //March	31
	2592000, //April	30
	2678400, //May		31
	2592000, //June		30
	2678400, //July		31
	2678400, //August	31
	2592000, //September	30
	2678400, //October	31
	2592000, //November	30
	2678400  //December	31
};

enum TimeZones
{
	UT_TIMEZONE_SERVER,
	UT_TIMEZONE_MIT,
	UT_TIMEZONE_HAST,
	UT_TIMEZONE_AKST,
	UT_TIMEZONE_AKDT,
	UT_TIMEZONE_PST,
	UT_TIMEZONE_PDT,
	UT_TIMEZONE_MST,
	UT_TIMEZONE_MDT,
	UT_TIMEZONE_CST,
	UT_TIMEZONE_CDT,
	UT_TIMEZONE_EST,
	UT_TIMEZONE_EDT,
	UT_TIMEZONE_PRT,
	UT_TIMEZONE_CNT,
	UT_TIMEZONE_AGT,
	UT_TIMEZONE_BET,
	UT_TIMEZONE_CAT,
	UT_TIMEZONE_UTC,
	UT_TIMEZONE_WET,
	UT_TIMEZONE_WEST,
	UT_TIMEZONE_CET,
	UT_TIMEZONE_CEST,
	UT_TIMEZONE_EET,
	UT_TIMEZONE_EEST,
	UT_TIMEZONE_ART,
	UT_TIMEZONE_EAT,
	UT_TIMEZONE_MET,
	UT_TIMEZONE_NET,
	UT_TIMEZONE_PLT,
	UT_TIMEZONE_IST,
	UT_TIMEZONE_BST,
	UT_TIMEZONE_ICT,
	UT_TIMEZONE_CTT,
	UT_TIMEZONE_AWST,
	UT_TIMEZONE_JST,
	UT_TIMEZONE_ACST,
	UT_TIMEZONE_AEST,
	UT_TIMEZONE_SST,
	UT_TIMEZONE_NZST,
	UT_TIMEZONE_NZDT
}

stock const TimeZoneOffset[ TimeZones ] = 
{
	-1,
	-39600,
	-36000,
	-32400,
	-28800,
	-28800,
	-25200,
	-25200,
	-21600,
	-21600,
	-18000,
	-18000,
	-14400,
	-14400,
	-12600,
	-10800,
	-10800,
	-3600,
	0,
	0,
	3600,
	3600,
	7200,
	7200,
	10800,
	7200,
	10800,
	12600,
	14400,
	18000,
	19800,
	21600,
	25200,
	28800,
	28800,
	32400,
	34200,
	36000,
	39600,
	43200,
	46800
};
	
stock TimeZones:TimeZone;
stock const DaySeconds = 86400;
stock const HourSeconds = 3600;
stock const MinuteSeconds = 60;

stock UnixToTime( iTimeStamp , &iYear , &iMonth , &iDay , &iHour , &iMinute , &iSecond , TimeZones:tzTimeZone=UT_TIMEZONE_UTC )
{
	new iTemp;
	
	iYear = 1970;
	iMonth = 1;
	iDay = 1;
	iHour = 0;

	if ( tzTimeZone == UT_TIMEZONE_SERVER )
		tzTimeZone = GetTimeZone();
		
	iTimeStamp += TimeZoneOffset[ tzTimeZone ];
	
	while ( iTimeStamp > 0 )
	{
		iTemp = IsLeapYear(iYear);

		if ( ( iTimeStamp - YearSeconds[iTemp] ) >= 0 )
		{
			iTimeStamp -= YearSeconds[iTemp];
			iYear++;
		}
		else
		{
			break;
		}
	}

	while ( iTimeStamp > 0 )
	{
		iTemp = SecondsInMonth( iYear , iMonth );

		if ( ( iTimeStamp - iTemp ) >= 0 ) 
		{
			iTimeStamp -= iTemp;
			iMonth++;
		}
		else
		{
			break;
		}
	}

	while ( iTimeStamp > 0)
	{
		if ( ( iTimeStamp - DaySeconds ) >= 0 )
		{
			iTimeStamp -= DaySeconds;
			iDay++;
		}
		else
		{
			break;
		}
	}
	
	while ( iTimeStamp > 0 )
	{
		if ( ( iTimeStamp - HourSeconds ) >= 0 )
		{
			iTimeStamp -= HourSeconds;
			iHour++;
		}
		else
		{
			break;
		}
	}
	
	iMinute = ( iTimeStamp / 60 );
	iSecond = ( iTimeStamp % 60 );
}

stock TimeToUnix( const iYear , const iMonth , const iDay , const iHour , const iMinute , const iSecond , TimeZones:tzTimeZone=UT_TIMEZONE_UTC)
{
	new i , iTimeStamp;

	for ( i = 1970 ; i < iYear ; i++ )
		iTimeStamp += YearSeconds[ IsLeapYear(i) ];

	for ( i = 1 ; i < iMonth ; i++ )
		iTimeStamp += SecondsInMonth( iYear , i );

	iTimeStamp += ( ( iDay - 1 ) * DaySeconds );
	iTimeStamp += ( iHour * HourSeconds );
	iTimeStamp += ( iMinute * MinuteSeconds );
	iTimeStamp += iSecond;

	if ( tzTimeZone == UT_TIMEZONE_SERVER )
		tzTimeZone = GetTimeZone();
		
	return ( iTimeStamp + TimeZoneOffset[ tzTimeZone ] );
}

stock TimeZones:GetTimeZone()
{
	if ( TimeZone )
		return TimeZone;
	
	new TimeZones:iZone , iOffset , iTime , iYear , iMonth , iDay , iHour , iMinute , iSecond;
	date( iYear , iMonth , iDay );
	time( iHour , iMinute , iSecond );
	
	iTime = TimeToUnix( iYear , iMonth , iDay , iHour , iMinute , iSecond , UT_TIMEZONE_UTC );
	iOffset = iTime - get_systime();
	
	for ( iZone = TimeZones:0 ; iZone < TimeZones ; iZone++ )
	{
		if ( iOffset == TimeZoneOffset[ iZone ] )
			break;
	}
	
	return ( TimeZone = iZone );
}

stock SecondsInMonth( const iYear , const iMonth ) 
{
	return ( ( IsLeapYear( iYear ) && ( iMonth == 2 ) ) ? ( MonthSeconds[iMonth - 1] + DaySeconds ) : MonthSeconds[iMonth - 1] );
}

stock IsLeapYear( const iYear ) 
{
	return ( ( (iYear % 4) == 0) && ( ( (iYear % 100) != 0) || ( (iYear % 400) == 0 ) ) );
}
