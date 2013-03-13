cd /d %~dp0
@echo	off
@echo	COPYIT.BAT transfers all files in 
@echo	all subdirectories of rem the source drive or directory (%1) 
@echo	to the destination

rem	drive or directory (%2)
call cmd
xcopy /?

if errorlevel 4 goto lowmemory 
if errorlevel 2 goto abort 
if errorlevel 0 goto exit 
:lowmemory 
	echo Insufficient memory to copy files or echo invalid drive or command-line syntax. 
	goto exit

:abort 
	echo You pressed CTRL+C to end the copy operation. 
	goto exit 
:exit 
	pause