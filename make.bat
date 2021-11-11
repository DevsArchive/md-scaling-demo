@echo off

set OUT=scale

if exist %OUT%.gen del %OUT%.gen
cd src
..\bin\asm68k.exe /k /p /o l. /o m+ _md/mdmain.s,..\%OUT%.gen,,..\%OUT%.lst > ..\errors.txt
cd ..
if not exist %OUT%.gen goto Error
if exist errors.txt del errors.txt
bin\rompad.exe %OUT%.gen 0 0 > nul
bin\fixheadr.exe %OUT%.gen > nul
exit

:Error
type errors.txt
pause > nul