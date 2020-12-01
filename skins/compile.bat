@ECHO OFF
ECHO ----------------------------------------------------------------------------
ECHO                     CS:GO Mod Models Compiler by O'Zone
ECHO ----------------------------------------------------------------------------
ECHO.
ECHO Input models directory name (or leave empty to use default) and press Enter:
SET directory=
SET /P directory=
ECHO Compiling...
python3 compile.py %directory%
PING -N 2 127.0.0.1 >nul
PAUSE
EXIT