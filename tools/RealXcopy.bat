@echo	off
@echo	COPYIT.BAT transfers all files in 
@echo	all subdirectories of rem the source drive or directory (%1) 
@echo	to the destination

rem	drive or directory (%2)

xcopy %1 %2 /S /E

if errorlevel 5 goto writeerror
if errorlevel 4 goto lowmemory 
if errorlevel 2 goto abort
if errorlevel 1 goto notfoundsourcefiles
if errorlevel 0 goto chaos_eof

:writeerror
	echo Write to disk error
	goto chaos_eof

:lowmemory 
	echo Insufficient memory to copy files or echo invalid drive or command-line syntax. 
	goto chaos_eof

:abort 
	echo You pressed CTRL+C to end the copy operation. 
	goto chaos_eof
:notfoundsourcefiles
	echo Not Found Source files
	goto chaos_eof
:chaos_eof 
@rem	pause