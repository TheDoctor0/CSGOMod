@ECHO OFF
ECHO --------------------------------
ECHO Half-Life Studio Model Compiler
ECHO Version 1.2
ECHO Copyright by Valve
ECHO --------------------------------
ECHO.
ECHO Drag and drop your .qc file here, after that press Enter:
SET qcfile=
SET /P qcfile=
ECHO.
COPY /Y studiomdl.exe %qcfile%\..
CD %qcfile%\..
studiomdl.exe %qcfile%
PING -N 2 127.0.0.1 >nul
PAUSE
EXIT