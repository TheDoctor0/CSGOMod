@ECHO OFF
ECHO ---------------------------------
ECHO CS:GO Mod Model Builder by O'Zone
ECHO ---------------------------------
ECHO Compiling...
python3 generate.py .
PING -N 2 127.0.0.1 >nul
PAUSE
EXIT