;-------------------------------------------------------------------------------
; Copyright (c) 1996-2006, J.C. Roberts <True(@)DigitalLove_org> 
; http://www.DesignTools.org  - All Rights Reserved
;
; Redistribution and use in source and binary forms, with or without 
; modification, are permitted provided that the following conditions are met:
;
;  1.) Redistributions of source code must retain the above copyright notice, 
;      this list of conditions and the following disclaimer.
;
;  2.) Redistributions in binary form must reproduce the above copyright notice, 
;      this list of conditions and the following disclaimer in the documentation 
;      and/or other materials provided with the distribution.
;
;  3.) The names of the copyright holders, the names of contributors and the 
;      name of the organization, DesignTools, may not be used to endorse or 
;      promote products including or derived from this software without specific 
;      prior written consent.
;
; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
; AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
; DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNERS OR CONTRIBUTORS BE LIABLE 
; FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,OR CONSEQUENTIAL 
; DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR 
; SERVICES, LOSS OF USE, DATA, OR PROFITS, OR BUSINESS INTERRUPTION) HOWEVER
; CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, 
; OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE 
; OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
;-------------------------------------------------------------------------------


;_______________________________________________________________________________
;-------------------------------------------------------------------------------
; Markings:
;   __FIXME__   -Stuff that needs to be fixed
;   __NOFIX__   -Things that are bad but are not fixable
;   __HACKS__   -Sad hacks and work arounds
;   __NOTES__   -Important Notes About Implementation
;-------------------------------------------------------------------------------

;FIXME: The way Allegro handles the ilinit files has changed in v15.2
; The old mode would load the first ilinit file found. 
; The new mode is to load any ilinit file found in either the
; /$CDSROOT/share/pcb/etc/skill/
; /$HOME/pcbenv/
; /$PCBENV/
; or current startup directories.

;________________________________________________________________________________
;********************************************************************************
; PROCEDURE: This is the main() procedure for the installation program.
(procedure (DT_install_main)
(prog 
  ( DTD          ; bool - debug print flag
    EndProg       ; GOTO marker
    DTOP_log         ; port - logging file
    InnFH         ; port - input file
    OutFH         ; port - output file
    ErrMsg        ; string - error message
    UsrMsg        ; string - user messages displayed during install
    DTPath        ; string - Fully Qualified Name to DT directory
    CurLine       ; string -
    ErrFlag       ;bool - try to leave the system in a usable state on error
    IsComplete 

    HomeDTdir     ; USER level DT config files: $home/.DesignTools/
    HomeDTcfg     ; main config file: $home/.DesignTools/DT_config-dfg.il

;    DT_install_get_log
    TempDir       ; string - Fully Qualified Name for system temp directory

;    DT_install_get_media    
    InsMedia      ; string - Fully Qualified Name install media - current dir

;    DT_install_get_localenv
    LocalEnv      ; string - Fully Qualified Name for the "LOCALENV" AllegroVar

;    DT_install_run_uninstall
;    DT_install_test_dtvar
;    DT_install_get_dtpath
    LastChunk     ; string - last chunk of the DT Path "/DesignTools"

;    DT_install_copy_files
    InstallSet    ; list - The install set for a single module
    ModuleID      ; string - Module Identifier
    FileName      ; string -  RELATIVE path and file name
    FileList      ; list -  list of RELATIVE file names
    PathName      ; string - RELATIVE path
    PathList      ; list - list of RELATIVE path names
    FullPath      ; string - Fully Qualified Name of file
  
;    DT_install_edit_file
    FileNew       ; string - fully qualified file name
    FileOld       ; string - fully qualified file name
    FileParts     ; list - FQN chopped up into parts
    MarkerDT      ; string - the base DesignTools marker text
    MarkText      ; string - the formatted marker text for identify DT entries
    InitList      ; list of strings -  lines to be added to "allegro.ilinit" file
    InitLine      ; string - a single line from the InitList
    LastChar      ; last character in the file, used to prevent file growth
    
    EditList      ; list -  old and new files for fixing borked isntall
    EditMode      ; the mode for editing files, either "MENU" or "INIT"

    AllCount      ; int - count of all lines in a file
    Last_END      ; int - line number of the last "END" statement in menu file
    EndCount      ; int - count of "END" statements
    BegCount      ; int - count of "BEGIN" statements
    IndentBy      ; int - count of Indentation from "BEGIN"/"END" statements
    
;    DT_install_edit_ilinit
;    DT_install_edit_menu
    MenuSet             ; list - a set of module menu structures
    HomeVar       ; user home variable

;    DT_install_edit_menu_line
;    DT_install_edit_menu_sets
   
  )
  (load "./base/ins/DT_install_sets.il")
  (load "./base/ins/DT_install_menu.il")

  (setq UsrMsg (sprintf nil "MESSAGE: Loaded DT_install.il\n"))
  (printf "%s" UsrMsg)
  (setq DTP "(DT_install_main)")
  (setq DTD nil)
  (when DTD (printf "\nSTATUS: %s \n" DTP))
  (setq UsrMsg nil)
  (setq ErrMsg nil)
  (setq DTPath nil)
  (setq TempDir nil)
  (setq ErrFlag nil)
  (setq LocalEnv nil)
  (setq EditMode nil)
  (setq EditList nil)
  (setq IsComplete nil)
  (setq HomeVar nil)
  (setq MarkerDT " ________ChaosTools________ DO NOT EDIT BETWEEN MARKS")
  (setq DT_t_LINE3 "--------------------------------------------------------------------------------")
  
  (rexMagic t)  ; Make sure we have "magic" characters turned on for regex

  (when (lessp (axlVersion 'version) 14.0)
     (setq ErrMsg "ERROR - Allegro Versions below 14.0 are not supported.")
     (go EndProg))


  ;*****************************************************************************
  ; The 14.x versions do not support the axlOSSlash() function
  (defun DT_install_unix_slash ( FQN "t")
    (let ( FQN_new)
      (setq FQN_new FQN)
      (rexMagic t)
      (while (or (rexMatchp "\\\\" FQN_new) (rexMatchp "//" FQN_new))
        (rexCompile "\\\\")                       ; "C:\This\Kind\Of\Crap\"
        (setq FQN_new (rexReplace FQN_new "/" 0))
        (rexCompile "//")                         ; "C://This//Kind//Of//Crap//"
        (setq FQN_new (rexReplace FQN_new "/" 0)))
      FQN_new))
  
  ;*****************************************************************************
  ; PROCEDURE: get system temp dir and make sure we can write to it for log file
  (procedure (DT_install_get_log)
    (setq DTP "(DT_install_get_log)")
    (when DTD (printf "\nSTATUS: %s \n" DTP))
    (setq TempDir (getTempDir))
    (when (and !(null TempDir) (stringp TempDir)) 
      (setq TempDir (DT_install_unix_slash TempDir))
      (rexCompile "//")
      (setq TempDir (rexReplace TempDir "/" 0)))     ; remove double slash //
    (if (and !(null TempDir) (isDir TempDir) (isWritable TempDir))
    then
      (unless (setq DTOP_log (outfile (strcat TempDir "/DT_install.log")))
        (setq ErrMsg "ERROR - Can not write log file to TEMP (MS-Windows) or TMP (UNIX) directory.")
        (go EndProg))
    else
      (setq ErrMsg "ERROR - Environment Variable TEMP (MS-Windows) or TMP (UNIX)\nis not set to your temporary directory or is not a writable directory.")
      (go EndProg))
    (fprintf DTOP_log "DesignTools Installation Logging\n")
    (fprintf DTOP_log "\n%s\nRunProcedure: %s\n" DT_t_LINE3 DTP)
    (fprintf DTOP_log "\nTemp_Dir: %L\n" TempDir))

  
  ;*****************************************************************************
  ; PROCEDURE: create configuration directory in users $home directory
  (procedure (DT_install_cfg_create)
    (setq DTP "(DT_install_cfg_create)")
    (when DTD (printf "\nSTATUS: %s \n" DTP))
    (setq HomeDTdir (strcat (getShellEnvVar "HOME") "/.DesignTools/"))
    (rexCompile "\\\\")                             ; "c:\this\kind\of\crap\"
    (setq HomeDTdir (rexReplace HomeDTdir "/" 0))
    (setq HomeDTcfg (strcat HomeDTdir "DT_config_cfg.il"))  
    (unless (isDir HomeDTdir)
      (if (isFile HomeDTdir)
      then
        (setq ErrMsg (sprintf nil "ERROR: %s - Could Not Create Directory.\nBecause there is a file with the same name.\nDirectory: %L" DTP HomeDTdir))
        (go EndProg)
      else
        (unless (createDir HomeDTdir)
          (setq ErrMsg (sprintf nil "ERROR: %s Could Not Create Directory.\nDirectory: %L" DTP HomeDTdir))
          (go EndProg))))
    (unless (isFile HomeDTcfg)
      (if (setq DTOP_cfg (outfile HomeDTcfg))
      then
        (fprintf DTOP_cfg "(setq DTG_CONF_SITE nil)")
        (drain DTOP_cfg) 
        (close DTOP_cfg)
      else
        (setq ErrMsg (sprintf nil "ERROR: %s - Could Not Create File.\nFile: %L\n" DTP, HomeDTcfg))
        (go EndProg))))


  ;*****************************************************************************
  ; PROCEDURE: The current working directory is where the "install media" is 
  ; located and where the installation routine was run via batch/shell script.
  (procedure (DT_install_get_media)
    (setq DTP "(DT_install_get_media)")
    (when DTD (printf "\nSTATUS: %s \n" DTP))
    (fprintf DTOP_log "\n%s\nRunProcedure: %s\n" DT_t_LINE3 DTP)
    (unless (setq InsMedia (getWorkingDir))
      (setq ErrMsg "ERROR: Could Not Get Working Directory.\n")
      (go EndProg))
    (setq InsMedia (DT_install_unix_slash InsMedia))
    (rexCompile "//")
    (setq InsMedia (rexReplace InsMedia "/" 0))     ; remove double slash //
    (fprintf DTOP_log "InsMedia: %L\n" InsMedia))


  ;*****************************************************************************
  ; PROCEDURE: Get the "localenv" directory. This is an "Allegro Environment"
  ; variable not a system env var. Files like the users "allegro.ilinit" file 
  ; are located in this directory.
  (procedure (DT_install_get_localenv)
    (setq DTP "(DT_install_get_localenv)")
    (when DTD (printf "\nSTATUS: %s \n" DTP))
    (fprintf DTOP_log "\n%s\nRunProcedure: %s\n" DT_t_LINE3 DTP)
    (setq LocalEnv nil)
;FIXME  - when we get away from the axl* commands should use (getShellEnvVar )
;and system environment variables
;  (setq DTPath (getShellEnvVar "localenv"))   ; get "System Env Variable"
    (setq LocalEnv (axlGetVariable "localenv"))
    (unless (and !(null LocalEnv) (isDir LocalEnv) (isWritable LocalEnv))
     (setq ErrMsg "ERROR: Environment variable \"localenv\" not set.\n")
     (go EndProg))
    (setq LocalEnv (DT_install_unix_slash LocalEnv))
    (rexCompile "//")
    (setq LocalEnv (rexReplace LocalEnv "/" 0))     ; remove double slash //
    (fprintf DTOP_log "LocalEnv: %L\n" LocalEnv))


  ;*****************************************************************************
  ; PROCEDURE: Test if DesignTools is already isntalled by checking if the
  ; uninstall procedure is bound. If bound, run the uninstaller.
  (procedure (DT_install_run_uninstall)
    (setq DTP "(DT_install_run_uninstall)")
    (when DTD (printf "\nSTATUS: %s \n" DTP))
    (fprintf DTOP_log "\n%s\nRunProcedure: %s\n" DT_t_LINE3 DTP)
    (when (procedurep (getd 'DT_uninstall_main))
      (fprintf DTOP_log "DT_Exist: DesignTools is already installed -attempting uninstall\n")
      (unless (DT_uninstall_main)
        (setq ErrMsg "ERROR - Can not install because user chose not to uninstall existing DesignTools.")
        (go EndProg))
      ;reload the install sets again -was previously done in the startup script
      (load "./base/ins/DT_install_sets.il")
      (load "./base/ins/DT_install_menu.il")))


  ;*****************************************************************************
  ; PROCEDURE: Instruct user on allowed install directory choices, then prompt
  ; user to choose the install directory. Create a "*/DesignTools" subdirectory.
  (procedure (DT_install_get_dtpath)
    (setq DTP "(DT_install_get_dtpath)")
    (when DTD (printf "\nSTATUS: %s \n" DTP))
    (fprintf DTOP_log "\n%s\nRunProcedure: %s\n" DT_t_LINE3 DTP)
    (setq DTPath nil)
    ; see if the "designtools" environment variable is set and if the dir exists
    (setq DTPath (axlGetVariable "designtools"))    ; get "Allegro Env Variable"
    (fprintf DTOP_log "\n%s\nDTEnvVar: \"designtools\" = %L\n" DT_t_LINE3 DTPath)    
    ; Due to the uninstall, the */DesignTools/ last chunk of the previous install
    ; path (/whatever/DesignTools/), stored in the "Allegro Environment" variable 
    ; (not shell env var) should no longer exist (i.e. deleted by the uninstall).
    (when (and !(null DTPath) (isDir DTPath))
      (setq ErrMsg (sprintf nil "ERROR: The ./DesignTools/ subdirectory still exists.\nIt seems a previous uninstall has failed.\n\nYou will need to delete this directory manually.\n\n%s" DTPath))
      (go EndProg))
    ; show instructions to user    
    (setq UsrMsg "Please choose an install directory without spaces in the path.\nA new \"*/DesignTools/\" subdirectory will be created under it.")
    (axlUIConfirm UsrMsg)
    ;__NOFIX__ axlDMDirectoryBrowse always uses current directory.
    ;The function docs say it's supposed to use the provided starting directory.
    (setq HomeVar (getShellEnvVar "HOME"))
;    (printf "HomeVar: %L\n" HomeVar)
    (if HomeVar
    then
      (setq DTPath 
          (axlDMDirectoryBrowse HomeVar t  ?title "Choose Install Directory"))
    else
      (setq DTPath 
          (axlDMDirectoryBrowse "/" t  ?title "Choose Install Directory")))
    
    (if (stringp DTPath)
    then
      (setq DTPath (DT_install_unix_slash DTPath))             ; set slashes to unix style
      (rexCompile "//")
      (setq DTPath (rexReplace DTPath "/" 0))       ; remove double slash //
      (fprintf DTOP_log "NewDTPth: %L\n" DTPath )
      (when !(isDir DTPath)
        (setq ErrMsg "ERROR: Selection is not a directory.\n")
        (go EndProg))
      (when !(isWritable DTPath)
        (setq ErrMsg "ERROR: You must have write permission for the directory.\n")
        (go EndProg))
      (rexCompile " ")
      (when (rexMatchp " " DTPath)
        (setq ErrMsg "ERROR: The directory path can not contain spaces.\n")
        (go EndProg))
      ; test the last chunk of DTPath for "/DesignTools/"
      (rexCompile "/[a-zA-z]+$")
      (rexExecute DTPath)
      (setq LastChunk (rexSubstitute "\\0"))
      (fprintf DTOP_log "EndChunk: %L\n" LastChunk)
      (when (equal LastChunk "/DesignTools")
        (setq ErrMsg (sprintf nil "ERROR: DesignTools Software Not Properly Installed.\n\nYou can not install into an existing */DesignTools/ subdirectory.\n\nPlease manually delete the subdirectory:\n\n%s/" DTPath))
        (go EndProg))
      ;test for existing "/DesignTools/" subdirectory
      (when (isDir (strcat DTPath "/DesignTools"))
        (setq ErrMsg (sprintf nil "ERROR: DesignTools Software Not Properly Installed.\n\nThe */DesignTools/ subdirectory already exists.\n\nPlease manually delete the subdirectory.\n\n%s/DesignTools/" DTPath))
        (go EndProg))
      ; test to make sure we are not trying to install into the install media
      (when (equal DTPath InsMedia)
        (setq ErrMsg "ERROR: You can not install onto the distribution media/directory.\n")
        (setq ErrMsg 
          (strcat ErrMsg 
            (sprintf nil "Instal To: %L\nInsMedia: %L\n" DTPath InsMedia)))
        (go EndProg))
      ;-------------------------------------------------------------------------
      ; create a new, empty DesignTools directory
      (setq DTPath (strcat DTPath "/DesignTools"))
      (when (axlOKToProceed)
        (if (createDir DTPath)
        then (fprintf DTOP_log "Created.: %L\n" DTPath)
        else
          (setq ErrMsg (sprintf nil "ERROR: Could Not Create New Directory.\nDirectory: %L" DTPath))
          (go EndProg)))
    else
      (setq ErrMsg "WARNING: Directory Selection Was Canceled.\n")
      (go EndProg)))


  ;*****************************************************************************
  ; PROCEDURE Create subdirecories and copy files from install media
  (procedure (DT_install_copy_files)
    (setq DTP "(DT_install_copy_files)")
    (when DTD (printf "\nSTATUS: %s \n" DTP))
    (fprintf DTOP_log "\n%s\nRunProcedure: %s\n" DT_t_LINE3 DTP)
    (foreach InstallSet DT_FILE_SETS
      (setq ModuleID (car   InstallSet))
      (setq PathList (cadr  InstallSet))
      (setq FileList (caddr InstallSet))
      (when DTD (fprintf DTOP_log "\n%s\nModuleID: %L\n" DT_t_LINE3 ModuleID))
      (when DTD (fprintf DTOP_log "PathList: %L\n" PathList))
      (when DTD (fprintf DTOP_log "FileList: %L\n" FileList))
      ; check install media for directories
      (when (or (equal ModuleID "BASE") (isDir (strcat "./" ModuleID)))
        ; create subdirectories
        (foreach PathName PathList
          (setq FullPath (strcat DTPath PathName))
          (if (isDir FullPath)
          then
            (unless (isWritable FullPath)
              (setq ErrMsg (sprintf nil "ERROR: Directory Is Not Writable.\nDirectory: %L" FullPath))
              (go EndProg))
          else
            (if (isFile FullPath)
            then
              (setq ErrMsg (sprintf nil "ERROR: Could Not Create Directory.\nBecause there is a file of the same name.\nDirectory: %L" FullPath))
              (go EndProg)
            else
              (unless (createDir FullPath)
                (setq ErrMsg (sprintf nil "ERROR: Could Not Create Directory.\nDirectory: %L" FullPath))
                (go EndProg)))))
        ; copy files
        (foreach FileName FileList
          (unless
            (axlOSFileCopy  (strcat "." FileName) (strcat DTPath FileName) nil)
            (setq ErrMsg (sprintf nil "ERROR: Failed To Copy File\n%s" FileName))
            (go EndProg))))))


  ;*****************************************************************************
  ; PROCEDURE: File editing for allegro.ilinit and Cadence menu files
  ; FileNew     string - file name to edit
;FIXME - deal with passing EditMode
  (procedure (DT_install_edit_file FileNew "t")
    (setq DTP "(DT_install_edit_file)")
    (when DTD (printf "\nSTATUS: %s \n" DTP))
    (fprintf DTOP_log "\n%s\nRunProcedure: %s\n" DT_t_LINE3 DTP)
    ; test the provided FileNew
    (if (stringp FileNew)
    then
      (setq FileParts (axlDMFileParts FileNew))
      (unless (isWritable (car FileParts))    ; is the directory writable?
          (setq ErrMsg (sprintf nil "ERROR: %s FileNew Directory is not writable.\n%L" DTP (car FileParts)))
          (go EndProg))
      (when (isFile FileNew)
        (unless (isWritable FileNew)          ; is the file writable?
          (setq ErrMsg (sprintf nil "ERROR: %s FileNew is not writable.\n%L" DTP FileNew))
          (go EndProg)))
    else ;error FileNew is not a string
      (setq ErrMsg (sprintf nil "ERROR: %s FileNew is not a string.\n%L" DTP FileNew))
      (go EndProg))

;NOFIX - Cadence SPB 15.2 (makeTempFileName *) function has odd behavior
    ; Create a string with fully qualifed path to "filename_old.XXXX" file.
    ; this doesn't really work exactly as planed since the (makeTempFileName...)
    ; function has bugs and truncates file name at eight characters, then adds
    ; a random string.
    (setq FileOld (strcat (car FileParts) "/" (cadr FileParts) "_old.XXXX"))
    (fprintf DTOP_log "FileOld_Name: %s\n" FileOld)
    (setq FileOld (makeTempFileName FileOld))
    (fprintf DTOP_log "FileOld_Real: %s\n" FileOld)
    ; the "allegro.ilinit" file does not exist by default, so create it.
    (when (and (equal EditMode "INIT") !(isFile FileNew))
      ; create file by opening for WRITING (overwrite/create mode)
      (unless (setq OutFH (outfile FileNew "w"))
        (setq ErrMsg (sprintf nil "ERROR: %s Failed to open new file\n%s\n" DTP FileNew))
        (go EndProg))
      (fprintf OutFH "; File Created By DesignTools\n")
      (when (and (boundp 'OutFH) (openportp OutFH))
        (unless (and (drain OutFH) (close OutFH) (setq OutFH 'unbound))
          (setq ErrMsg (sprintf nil "\nERROR: %s - Flush/Close failed OutFH\n" DTP))
          (go EndProg))))
    ; Copy the current file to "filename_old.XXXX" and save both the fully
    ; qualified old and new file names to a list for recovering a bad install.
    (if (axlOSFileCopy FileNew FileOld nil)
    then (setq EditList (cons EditList (list FileOld FileNew)))
    else
      (setq ErrMsg (sprintf nil "ERROR: %s Failed to copy\n%s\nto\n%s\n" DTP FileNew FileOld))
      (go EndProg))
    ; open the current file for WRITING (overwrite/create mode)
    (unless (setq OutFH (outfile FileNew "w"))
      (setq ErrMsg (sprintf nil "ERROR: %s Failed to open new file\n%s\n" DTP FileNew))
      (go EndProg))
    ; open "filename_old.XXXX" for READING
    (unless (setq InnFH (infile FileOld))
      (setq ErrMsg (sprintf nil "ERROR: %s Failed to open old file\n%s\n" DTP FileOld))
      (go EndProg))

    (setq ErrFlag nil)
    ; copy the contents of the original file into our new file
    (case EditMode
      ("INIT" ; Edits for the "allegro.ilinit" file
        (setq MarkText (sprintf nil ";%s\n" MarkerDT))
        (while (gets CurLine InnFH)
          (when (equal CurLine MarkText) (setq ErrFlag t))
          (fprintf OutFH "%s" CurLine))
        ; write our new lines to the file
        (fprintf DTOP_log "\nMod_Init: Appending Lines To \"%s\" File\n" FileNew)
        (setq MarkText (sprintf nil ";%s" MarkerDT))
        (setq InitList
          (list 
              (sprintf nil "%s" MarkText)
              (sprintf nil "(axlSetVariable \"designtools\" \"%s\")" DTPath)
              (sprintf nil "(setq DTG_MENU (strcat (axlGetVariable \"designtools\") \"/base/lib/_DTL_MENUS.il\"))")
              (sprintf nil "(load DTG_MENU)")
              (sprintf nil "(setq DTG_CONF_USER (strcat (getShellEnvVar \"HOME\") \"/.DesignTools\"))")
              (sprintf nil "(load (strcat DTG_CONF_USER \"/DT_config_cfg.il\"))")
              (sprintf nil "%s" MarkText)))
        ; prevent the file from growing one line per run
        (fileSeek InnFH -1 2)
        (setq LastChar (getc InnFH))
        (if (equal (sprintf nil "%s" LastChar) (sprintf nil "\n")) 
        then
          (fileSeek InnFH -1 2)
          (fprintf DTOP_log "LastCHAR: %L\n" LastChar)
          (fprintf DTOP_log "LastINIT: (new line)\n")
        else
          (fprintf DTOP_log "LastCHAR: %L\n" LastChar)
          (fprintf DTOP_log "LastINIT: (text)\n")
          (fprintf OutFH "\n"))
        (foreach InitLine InitList
          (fprintf OutFH "%s\n" InitLine)
          (fprintf DTOP_log "Add_Line: %s\n" InitLine)))
      ("MENU" ; Edit menu file
        (setq MarkText (sprintf nil "//%s\n" MarkerDT))
        (setq AllCount 0)     ; a line index/counter for all lines in the file
        (setq Last_END 0)     ; line number of the last "END" statement
        (setq EndCount 0)     ; count of "END" statements
        (setq BegCount 0)     ; count of "BEGIN" statements
        (setq IndentBy 0)     ; Indent count from "BEGIN"/"END" statements
        ;analyze tree structure of menu file
        (while (gets CurLine InnFH)
          (when (equal CurLine MarkText) (setq ErrFlag t))
          (when (rexMatchp "^[ \t]*END." CurLine) (setq Last_END AllCount))
          AllCount++)
        ;rewrite the file without final "END" only if there was no error in the analysis
        (fprintf DTOP_log "\nLast_END__: %L\n" Last_END)
        (setq AllCount 0)
        (when (null ErrFlag)
          (fileSeek InnFH 0 0)
          (while (gets CurLine InnFH)
            (when (rexMatchp "^[ \t]*END." CurLine) (predecrement IndentBy))
            (if (eq AllCount Last_END)
            then ; add menu items here
              (fprintf DTOP_log "\n\nLAST \"END\" Line %d Modify Menu - %s\n\t%L\n" AllCount DTP CurLine)
              (fprintf OutFH "%s" MarkText) ; write first marker
              ; do something useful
              (DT_install_edit_menu_sets MenuSet)
              (fprintf OutFH "%s" MarkText) ; write second marker
              (fprintf OutFH "%s" CurLine)  ; write the final "END" statement
            else ; finish writing the file
              (setq CurLine (DT_install_edit_menu_line CurLine IndentBy))
              (fprintf OutFH "%s" CurLine))
            (when (rexMatchp "^[ \t]*BEGIN." CurLine) (preincrement IndentBy))
            (preincrement AllCount)))))
    ; deal with error
    (when ErrFlag
      (setq ErrMsg (sprintf nil "ERROR: %s\n\nDesignTools marker found in:\n%s\n\nYou will need to manually edit this file\nand remove the DesignTools Entries." DTP FileNew))
      (go EndProg))
    ; flush and close files
    (when (and (boundp 'OutFH) (openportp OutFH))
      (unless (and (drain OutFH) (close OutFH) (setq OutFH 'unbound))
        (setq ErrMsg (sprintf nil "\nERROR: %s - Flush/Close failed OutFH\n" DTP))
        (go EndProg)))
    (when (and (boundp 'InnFH) (openportp InnFH))
      (unless (and (close InnFH) (setq InnFH 'unbound))
        (setq ErrMsg (sprintf nil "\nERROR: %s - Flush/Close failed InnFH\n" DTP))
        (go EndProg))))

  ;*****************************************************************************
  ;PROCEDURE: Edit or Create "allegro.ilintit" file adding DT entries
  (procedure (DT_install_edit_ilinit)
    (setq DTP "(DT_install_edit_ilinit)")
    (when DTD (printf "\nSTATUS: %s \n" DTP))
    (fprintf DTOP_log "\n%s\nRunProcedure: %s\n" DT_t_LINE3 DTP)
    (setq FileNew (strcat LocalEnv "/allegro.ilinit"))
    (fprintf DTOP_log "New_INITName: %L\n" FileNew) 
    (setq EditMode "INIT")
    (DT_install_edit_file FileNew))

  ;*****************************************************************************
  ; PROCEDURE: Edit the menu files
  (defun DT_install_edit_menu ()
    (let ( DTP MenuFileList MenuFileName)
      (setq DTP "(DT_install_edit_menu)")
;      (setq DTD nil)
      (when DTD (printf "\nSTATUS: %s \n" DTP))
      (fprintf DTOP_log "\n%s\nRunProcedure: %s\n" DT_t_LINE3 DTP)
      (setq ErrFlag nil)    ;used to signal when a marker mistakenly exists
      ; loop through the menu file item sets
      (foreach MenuSet DT_MENU_SETS
        (fprintf DTOP_log "\nProcessMenu_: %L\n" MenuSet->file)
        ;--------------------------------------------------------------------------------
        ;on Allegro 14.2 and earlier there is no "allegro.mem" file
        ;
        ;boards:
        ; explayout.men     -ALLEGRO_EXPERT - BOARD
        ; pcblayout.men     -ALLEGRO_PCB - BOARD
        ; adlayout.men      -ALLEGRO_PEFORMANCE (DESIGNER) - BOARD
        ; lbrlayout.men     -ALLEGRO_LIBRARIAN - BOARD         (Allegro Librarian)
        ; apdlayout.mem     -ALLEGRO_EXPERT - BOARD/MCM (Allegro Package Designer)      
        ; specctraquest.men -SPECCTRAQUEST (board)
        ;
        ;parts:
        ; cbdsymbol.men     -ALLEGRO_SYMBOL - PCB
        ; apdsymbol.men     -ALLEGRO_SYMBOL - APD       (Allegro Package Designer)
        ; xlibsymbol.men    -ALLEGRO_SYMBOL - LIBRARIAN EXPERT (Allegro Librarian)
        ;
        ;--------------------------------------------------------------------------------
        ; on version 15.0 and greater
        ;boards:
        ;  "allegro.men"
        ;  "apdlayout.men"
        ;  "lbrlayout.men"
        ;  "specctraquest.men"
        ; 
        ;parts:
        ; cbdsymbol.men     -ALLEGRO_SYMBOL - PCB
        ; apdsymbol.men     -ALLEGRO_SYMBOL - APD       (Allegro Package Designer)
        ; xlibsymbol.men    -ALLEGRO_SYMBOL - LIBRARIAN EXPERT (Allegro Librarian)
        ;--------------------------------------------------------------------------------
    
        ;This sets up a list of menu files to edit from the datafile keywords
        ;either board file programs or symbol/part file programs
        (setq MenuFileList nil)
        (if (equal "cbdsymbol.men" MenuSet->file)
        then ; symbol/part editors
          (setq MenuFileList (list
            "cbdsymbol.men"
            "apdsymbol.men"
            "xlibsymbol.men"))
        else ;board file editors
          (if (equal "allegro.men" MenuSet->file)
          then 
            (if (lessp (axlVersion 'version) 15.0)
            then ; before 15.0
              (setq MenuFileList (list
                "explayout.men"
                "pcblayout.men"
                "adlayout.men"
                "apdlayout.men"
                "lbrlayout.men"
                "specctraquest.men"))
            else (if (lessp (axlVersion 'version) 16.0)
            then ;between 15.0 and 16.0
              (setq MenuFileList (list
                "allegro.men"
                "apdlayout.men"
                "lbrlayout.men"
                "specctraquest.men"))
            else ;after 16.0, FixedMe by CHAOS
              (setq MenuFileList (list
                "allegro.men"
                "pcb_symbol.men"
                "apd.men"
                "specctraquest.men"))))
          else ;could be some other product
            (setq MenuFileList (list MenuSet->file))))
    
        (foreach MenuFileName MenuFileList
          (fprintf DTOP_log "\nMenuFileName: %L\n" MenuSet->file)
          ; find the current location of the menu file (i.e. "allegro.men" )
          (unless (setq FileNew (axlDMFindFile  "MENU" MenuFileName "r"))
            (setq ErrMsg (sprintf nil "ERROR: %s\n\nCould Not Locate Menu File\n\"%s\"\n" 
                DTP MenuFileName))
            (go EndProg))
          (setq FileNew (DT_install_unix_slash FileNew))      ; i.e. "allegro.men"
          (fprintf DTOP_log "New_MENUName: %L\n" FileNew) 
          (setq EditMode "MENU")
          (DT_install_edit_file FileNew)
        )
      )
    )  
  )
;FIXME -(Re)Loading menus may not work on UNIX according to the docs?
;      (if (equal MenuSet->file "allegro.men") (axlUIMenuLoad "allegro.men"))

  ;*****************************************************************************
  ;PROCEDURE: Reformant menu item line entries so they are consistent.
  ; This is really an unnecessary vanity hack but it does correct the 
  ; inconsistent tab/space formatting found in Cadence menu files.
  (procedure (DT_install_edit_menu_line MenuLine IndentBy "tx")
  (prog (CommLine RealLine NewLine DoLog)
    (setq DTP "(DT_install_edit_menu_line)")
    (when DTD (printf "\nSTATUS: %s \n" DTP))
    (setq DoLog nil)
    (when DoLog (fprintf DTOP_log "\n%s\nRunProcedure: %s\n" DT_t_LINE3 DTP))
    ; if it is just a comment line starting with // or # directive, return it
    (when (or (rexMatchp "^//" MenuLine) (rexMatchp "^#" MenuLine))
      (return MenuLine))
    ; find the first valid comment marker in the line and save the comment
    ;   MenuLine: "This is //a test."
    ;   CommLine: " //a test."
    ;   RealLine: "This is"
    (setq CommLine nil)
    (setq RealLine nil)
    (rexCompile "[ \t]+//.*")   ;one or more whitespace and //-whatever
    (rexExecute MenuLine)
    (setq CommLine (rexSubstitute "\\0"))
    (setq RealLine (rexReplace MenuLine "" 1))
    (when DoLog (fprintf DTOP_log "CurMenuLine: %L\n" MenuLine))
    (when DoLog (fprintf DTOP_log "CommentLine: %L\n" CommLine))
    (when DoLog (fprintf DTOP_log "RealTxtLine: %L\n" RealLine))
    ; the line is just a comment with leading space, return it as is.
    (unless (rexMatchp "[a-zA-Z]+" RealLine)
      (return MenuLine))
;__NOTES__: The string passed to rex* functions is evaluated twice, once by the
; initial reading and again by the rex* function,  so you need to be real 
; careful with the derefernece and special characters.
;  "\\"       -Results in an error
;  "\\\\"     -Matches a single \  blackslash
;
    ; Test if there's a dereferenced double quote (\") in the line. At
    ; the moment, such a thing breaks the menu file but sooner or later
    ; they may fix this bug and allow it -might be useful in commands.
    (when (rexMatchp "\\\\\"" RealLine)
      (rexCompile "\\\\\"")
      (setq RealLine (rexReplace RealLine "__!!DT!!__" 0)))
    (when DoLog (fprintf DTOP_log "RealLine: %L\n" RealLine))
    ; delete all leading space and tabs from line
    (rexCompile "^[ \t]+")
    (setq RealLine (rexReplace RealLine "" 1))
    ; Not very scientific but it generally works...
    ; split on double quote. Why? -Because someone may put a comma in the
    ; text portion of a menu item (i.e. the comma is displayed in the menu)
    ; putting commas in menu item text is actually allowed.
    (setq LineList (parseString RealLine "\""))
    (when DoLog (fprintf DTOP_log "LineList: %04d %L\n" (length LineList) LineList))
    (setq NewMLine "")
    (for i 1 IndentBy (setq NewMLine (strcat NewMLine "  ")))
    (caseq (length LineList)
      (1 ; Usually a "END" or "BEGIN" line like ("BEGIN\n")
        (setq NewMLine (strcat NewMLine (sprintf nil "%s" RealLine))))
      (3 ; Usually a POPUP line like ("POPUP " "&Export" "\n")
        (setq NewMLine (strcat NewMLine (sprintf nil "%s" RealLine))))
      (5  ; problably a MENUITEM ("MENUITEM " "&IDF..." ",\t\t\t" "idf out" "\n")
        (setq NewMLine ;<indent>MENUITEM "&IDF"
          (strcat NewMLine (nth 0 LineList) "\"" (nth 1 LineList) "\","))
        (setq NewMLine (sprintf nil "%-56s\"%s\"\n" NewMLine (nth 3 LineList))))
      (t  ; no clue what the heck it is, so put it back the way we found it
        (setq NewMLine (strcat NewMLine (sprintf nil "%s" RealLine)))))
    ; put the dereferenced double quote (\") back where we found it.
    (rexCompile "__!!DT!!__")
    (setq NewMLine (rexReplace NewMLine "\\\\\"" 0))
    (if (null CommLine)
    then
      (setq RealLine NewMLine)
    else
      (setq RealLine (strcat NewMLine CommLine)))
    (when DoLog (fprintf DTOP_log "FinMenuLine: %L\n" RealLine))
    (return RealLine))); end prog and procedure

  ;*****************************************************************************
  ; PROCEDURE a recursive procedure for adding the menu sets to menu files
  (procedure (DT_install_edit_menu_sets MenuSet "g")
  (prog (LineText IndCount LineCons MenuKid DoLog)
    (setq DTP "(DT_install_edit_menu_sets)")
    (when DTD (printf "\nSTATUS: %s \n" DTP))
    (fprintf DTOP_log "\n%s\nRunProcedure: %s\n" DT_t_LINE3 DTP)
    (fprintf DTOP_log "MenuName: %s\n" MenuSet->name)
    (setq DoLog nil)
    (foreach LineCons MenuSet->text
      (setq IndCount (car  LineCons))
      (setq LineText (cadr LineCons))
      (when (rexMatchp "BEGIN" LineText) (preincrement BegCount))      
      (when (rexMatchp "END" LineText) (preincrement EndCount))
      (when DoLog (fprintf DTOP_log "\nPre_Line: %L\n" LineText))
      (when DoLog (fprintf DTOP_log "BegCount: %d\n" BegCount))
      (when DoLog (fprintf DTOP_log "EndCount: %d\n" EndCount))
      (when ; match last "END" in set then process kids
        (and (greaterp (add1 EndCount) BegCount) MenuSet->kids 
          (rexMatchp "END$" LineText))
        (foreach MenuKid MenuSet->kids (DT_install_edit_menu_sets MenuKid)))
      (when DoLog (fprintf DTOP_log "Pre_Line: %L\n" LineText))
      (sprintf LineText "%s\n" LineText)
      (setq LineText (DT_install_edit_menu_line LineText IndCount))
      (fprintf OutFH "%s" LineText)
      (fprintf DTOP_log "Add_Line: %L\n" LineText))))

  ;*****************************************************************************
  ; main program
  (DT_install_get_log)
  (DT_install_cfg_create)
  (DT_install_get_media)
  (DT_install_get_localenv)
  (DT_install_run_uninstall)
  (DT_install_get_dtpath)
  (DT_install_copy_files)
  (DT_install_edit_ilinit)
  (DT_install_edit_menu)

  ; finished
  (setq IsComplete t)

EndProg

  ; if possible, write error message to log
  (when (and (boundp 'DTOP_log) (openportp DTOP_log) ErrMsg) 
    (fprintf DTOP_log "\n\n%s\n" ErrMsg))
  ; flush and close files
  (when (and (boundp 'DTOP_log) (openportp DTOP_log))
    (unless (and (drain DTOP_log) (close DTOP_log) (setq DTOP_log 'unbound))
      (setq ErrMsg 
        (sprintf nil "\nERROR: %s - Flush/Close failed DTOP_log\n" DTP))))
  (when (and (boundp 'OutFH) (openportp OutFH))
    (unless (and (drain OutFH) (close OutFH) (setq OutFH 'unbound))
      (setq ErrMsg 
        (sprintf nil "\nERROR: %s - Flush/Close failed OutFH\n" DTP))))
  (when (and (boundp 'InnFH) (openportp InnFH))
    (unless (and (close InnFH) (setq InnFH 'unbound))
      (setq ErrMsg 
        (sprintf nil "\nERROR: %s - Flush/Close failed InnFH\n" DTP))))
  (when ErrMsg

;INFO: The (return ...) versions are for debugging
;FIXME -need to add file recovery for failed install "EditList"
    (printf ErrMsg)
    (axlUIConfirm ErrMsg)
;    (axlUIViewFileCreate (strcat TempDir "/DT_install.log") "Install Log" nil)
;    (when (axlOKToProceed) (return nil)))
    (when (axlOKToProceed) (axlShell "exit")))

  (if IsComplete
  then
    (axlUIConfirm (sprintf nil "\tInstallation Complete\n\nYour DesignTools Have Been Installed Successfully!\n\nIf you have any open instances of Cadence\nprograms, please close and restart them."))
;    (axlUIViewFileCreate (strcat TempDir "/DT_install.log") "Install Log" nil)
;    (when (axlOKToProceed) (return t))
    (when (axlOKToProceed) (axlShell "exit"))
  else
;    (axlUIViewFileCreate (strcat TempDir "/DT_install.log") "Install Log" nil)
;    (when (axlOKToProceed) (return nil)))
    (when (axlOKToProceed) (axlShell "exit")))

  
));end prog & procedure

;--------------------------------------------------------------------------------
;Auto-Execute -this might be a problem when contextes are built
(DT_install_main)
