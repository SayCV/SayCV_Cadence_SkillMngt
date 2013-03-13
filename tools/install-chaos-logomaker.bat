@echo off
cd /d %~dp0
goto SKIP_CHAOS_PATH
C:\Perl\site\bin;C:\Perl\bin;C:\Program Files\AMD APP\bin\x86;C:\Program Files\Common Files\Microsoft Shared\Windows Live;C:\Windows\system32;C:\Windows;C:\Windows\System32\Wbem;C:\Windows\System32\WindowsPowerShell\v1.0\;C:\Program Files\Common Files\Thunder Network\KanKan\Codecs;C:\Program Files\Windows Live\Shared;C:\Program Files\Microsoft SQL Server\100\Tools\Binn\;C:\Program Files\Microsoft SQL Server\100\DTS\Binn\;d:\Cadence\SPB_16.3\tools\bin;d:\Cadence\SPB_16.3\tools\libutil\bin;d:\Cadence\SPB_16.3\tools\fet\bin;d:\Cadence\SPB_16.3\tools\pcb\bin;d:\Cadence\SPB_16.3\tools\specctra\bin;d:\Cadence\SPB_16.3\tools\PSpice;d:\Cadence\SPB_16.3\tools\PSpice\Library;d:\Cadence\SPB_16.3\tools\Capture;d:\Cadence\SPB_16.3\OpenAccess\bin\win32\opt;D:\Program Files\ATI Technologies\ATI.ACE\Core-Static;C:\texlive\2010\bin\win32
:SKIP_CHAOS_PATH
set cur_path=%cd%
set Chaos_DestPath=c:\ChaosLogoMaker
set LEADCMD_DestPath=c:\ChaosLogoMaker\LEADCMD
set potrace_DestPath=c:\ChaosLogoMaker\potrace
set ImageMagick_DestPath=c:\ChaosLogoMaker\ImageMagick

if not exist %Chaos_DestPath% 		md %Chaos_DestPath%
if not exist %LEADCMD_DestPath% 	md %LEADCMD_DestPath%
if not exist %potrace_DestPath% 	md %potrace_DestPath%
if not exist %ImageMagick_DestPath% 	md %ImageMagick_DestPath%

rem echo 复制文件...
call RealXcopy %cur_path%\LEADCMD %LEADCMD_DestPath%
call RealXcopy %cur_path%\potrace-1.9.win32 %potrace_DestPath%
call RealXcopy %cur_path%\ImageMagick-6.7.1-Q16-windows %ImageMagick_DestPath%
call RealXcopy %cur_path%\logoMaker_ImageMagicK.il %WORK_HOME%\pcbenv\
call RealXcopy %cur_path%\logoMaker_LEDTOOLS.il %WORK_HOME%\pcbenv\
call RealXcopy %cur_path%\logoMaker_LEDTOOLS_V10.il %WORK_HOME%\pcbenv\
call RealXcopy %cur_path%\logoMaker_lfc_Help.txt %WORK_HOME%\pcbenv\
call RealXcopy %cur_path%\logoMaker_readme.txt %WORK_HOME%\pcbenv\
rem goto :eof

rem echo 设置LEADTOOLS lfc.exe、mkbitmap.exe环境变量
rem %PATH%值在批处理中更改后得不到自动更新，故应该一次性添加
set ADDpathExist=%LEADCMD_DestPath%\Bin
set chaos_missing_path="%LEADCMD_DestPath%\Bin;%path%"
call :chaos_add_syspath	%chaos_missing_path%
set ADDpathExist=%ImageMagick_DestPath%
set chaos_missing_path="%ImageMagick_DestPath%;%path%"
call :chaos_add_syspath	%chaos_missing_path%
call :chaos_add_potracepath	%potrace_DestPath%
call :chaos_add_ledtoolspath	%LEADCMD_DestPath%\Bin
call :chaos_add_ImageMagicKpath	%ImageMagick_DestPath%
if %errorlevel%==0 ( 
	echo 安装成功！！！
	pause
	goto :EOF
)
if %errorlevel%==1(
	echo 安装失败！！！
	pause
	goto :EOF
)

:chaos_add_syspath
set regpath=HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Session Manager\Environment
set ADDpath=%1
reg query "%regpath%" /v "Path"|find /i "%ADDpathExist%"||(reg add "%regpath%" /v Path /t REG_EXPAND_SZ /d %ADDpath% /f)
if %errorlevel%==1 ( 
	echo ADDpath:reg query or find or add 出错！！！
)
goto :eof

:chaos_add_potracepath
set regpath=HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Session Manager\Environment
set ADDpath=%1
reg add "%regpath%" /v POTRACE_PATH /t REG_EXPAND_SZ /d "%ADDpath%" /f
if %errorlevel%==1 ( 
	echo POTRACE_PATH:reg query or find or add 出错！！！
)
goto :eof

:chaos_add_ledtoolspath
set regpath=HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Session Manager\Environment
set ADDpath=%1
reg add "%regpath%" /v LFC_PATH /t REG_EXPAND_SZ /d "%ADDpath%" /f
if %errorlevel%==1 ( 
	echo POTRACE_PATH:reg query or find or add 出错！！！
)
goto :eof

:chaos_add_ImageMagicKpath
set regpath=HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Session Manager\Environment
set ADDpath=%1
reg add "%regpath%" /v MAGICK_HOME /t REG_EXPAND_SZ /d "%ADDpath%" /f
if %errorlevel%==1 ( 
	echo POTRACE_PATH:reg query or find or add 出错！！！
)
goto :eof
