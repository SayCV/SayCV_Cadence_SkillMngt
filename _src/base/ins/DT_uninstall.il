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
;-------------------------------------------------------------------------------

axlCmdRegister("DT_uninstall_main", "DT_uninstall_main")

;*******************************************************************************
; PROCEDURE: The main uninstall routine
(procedure (DT_uninstall_main)
(prog 
  ; localized variables and procedures
  ( DMSG                ; bool - debug message flag
    DTP                 ; string - current procedure name
    DTOP_log            ; port/handle - logging file
    InnFH               ; port/handle - input file
    OutFH               ; port/handle - output file
    DTPath              ; string - main DesignTools install path
    ErrMsg              ; string - error message
    CurLine             ; string - current line in a file
    TempDir             ; string - system temporary directory
    FileNew             ; string - fully qualified file name
    FileOld             ; string - fully qualified file name (*.old)
    IsComplete          ; bool - success flag
    IsCancel            ; bool - cancel uninstall
                        
;    DT_uninstall_delete ; procedure to delete files/directories
    FilesSet            ; a set of installed files and directories of a module
    ModuleID            ; string - Module Identifier
    FileName            ; string -  RELATIVE path and file name
    FileList            ; list -  list of RELATIVE file names
    PathName            ; string - RELATIVE path
    PathList            ; list - list of RELATIVE path names
    
;    DT_uninstall_edit_file 
    MarkerDT            ; string - the base DesignTools marker text
    MarkText            ; string - the formatted marker to identify DT entries
    Mark_Cnt            ; int - count of markers (2 - start and end)
    FileParts           ; list - FQN chopped up into parts
    EditList            ; list -  old and new files for fixing borked isntall

;    DT_uninstall_ilinit ; procedure to remove *.ilinit entries
    LocalEnv            ; string - the system "localenv" allegro variable
    MarkerDT            ; string - initialization mark in allegro.ilinit
    Mark_Cnt            ; int - a counter for initialization marks

;    DT_uninstall_menus  ; procedure to remove menu entries
;    AllCount            ; count of all lines in the menu file
    Lines_DT            ; a list of line number for existing DT menu stuff
    Count_DT            ; count of DT meun lines        
    IsMarkDT            ; a toggle for finding DT menu stuff
    MenuSet             ; list - a set of module menu structures

;    DT_uninstall_unreg  ; procedure to unregister and unbind cmds/functions
    CmdList             ; list of registered allegro shell command pairs
    CmdPair             ; list - a command pair ("cmd_name" "function_name")
    FunName             ; string - the function/procedure name
  )
  
  ; initialize stuff
  (setq DMSG nil)
  (setq ErrMsg nil)
  (setq DTPath nil)
  (setq TempDir nil)
  (setq LocalEnv nil)
  (setq EditList nil)
  (setq MarkText nil)
  (setq IsComplete nil)
  (setq MarkerDT " ________ChaosTools________ DO NOT EDIT BETWEEN MARKS")
  (setq DT_t_LINE3 "--------------------------------------------------------------------------------")

  (rexMagic t)  ; Make sure we have "magic" characters turned on for regex

  ;*****************************************************************************
  ; The 14.x versions do not support the axlOSSlash() function
  (defun DT_uninstall_unix_slash ( FQN "t")
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
  (procedure (DT_uninstall_get_log)
    (setq DTP "(DT_uninstall_get_log)")
    (setq TempDir (getTempDir))
    (when (and !(null TempDir) (stringp TempDir)) 
      (setq TempDir (DT_uninstall_unix_slash TempDir))
      (rexCompile "//")
      (setq TempDir (rexReplace TempDir "/" 0)))     ; remove double slash //
    (if (and !(null TempDir) (isDir TempDir) (isWritable TempDir))
    then
      (unless (setq DTOP_log (outfile (strcat TempDir "/DT_uninstall.log")))
        (setq ErrMsg "ERROR - Can not write log file to TEMP (MS-Windows) or TMP (UNIX) directory.")
        (go EndProg))
    else
      (setq ErrMsg "ERROR - Environment Variable TEMP (MS-Windows) or TMP (UNIX)\nis not set to your temporary directory or is not a writable directory.")
      (go EndProg))
    (fprintf  DTOP_log "DesignTools Uninstall Logging\n")
    (fprintf DTOP_log "\n%s\nRunProcedure: %s\n" DT_t_LINE3 DTP)
    (fprintf DTOP_log "Temp_Dir: %L\n" TempDir))


  ;*****************************************************************************
  ; PROCEDURE: Get the "localenv" directory. This is an "Allegro Environment"
  ; variable not a system env var. Files like the users "allegro.ilinit" file 
  ; are located in this directory.
  (procedure (DT_uninstall_get_localenv)
    (setq DTP "(DT_uninstall_get_localenv)")
    (fprintf DTOP_log "\n%s\nRunProcedure: %s\n" DT_t_LINE3 DTP)
    (setq LocalEnv nil)
;FIXME  - when we get away from the axl* commands should use (getShellEnvVar )
;and system environment variables
;  (setq DTPath (getShellEnvVar "localenv"))   ; get "System Env Variable"
    (setq LocalEnv (axlGetVariable "localenv"))
    (unless (and !(null LocalEnv) (isDir LocalEnv) (isWritable LocalEnv))
     (setq ErrMsg "ERROR: Environment variable \"localenv\" not set.\n")
     (go EndProg))
    (setq LocalEnv (DT_uninstall_unix_slash LocalEnv))
    (rexCompile "//")
    (setq LocalEnv (rexReplace LocalEnv "/" 0))     ; remove double slash //
    (fprintf DTOP_log "LocalEnv: %L\n" LocalEnv))

  ;*****************************************************************************
  ; PROCEDURE: Get the DesignTools installation path
  (procedure (DT_uninstall_get_dtpath)
    (setq DTP "(DT_uninstall_get_dtpath)")
    (fprintf DTOP_log "\n%s\nRunProcedure: %s\n" DT_t_LINE3 DTP)
    (setq DTPath nil)
    ; see if the "designtools" environment variable is set and if the dir exists
    (setq DTPath (axlGetVariable "designtools"))    ; get "Allegro Env Variable"
    (fprintf DTOP_log "CurentDTPath: \"designtools\" = %L\n" DTPath)    
    ; The DTPath better exist or we're hosed
    (unless (and !(null DTPath) (isDir DTPath) (isWritable DTPath))
      (setq ErrMsg (sprintf nil "ERROR: The ./DesignTools/ subdirectory still exists.\nIt seems a previous uninstall has failed.\n\nYou will need to delete this directory manually.\n\n%s" DTPath))
      (go EndProg)))

  ;*****************************************************************************
  ; PROCEDURE: Test to make sure we have write privledges to the files so
  ; we can delete them. This will be important for pleasing CAD Managers and
  ; properly dealing with shared network installations of Cadence software
  (procedure (DT_uninstall_test_write)
    (setq DTP "(DT_uninstall_test_write)")
    (unless (isWritable (strcat DTPath "/base/ins/DT_uninstall.il"))
      (setq ErrMsg (sprintf nil "ERROR: %s - You do not have write access to the DesignTools files,\nso there is no way to delete them." DTP))
      (go EndProg))
    (unless (isFile (strcat DTPath "/base/ins/DT_install_sets.il"))
      (setq ErrMsg (sprintf nil "ERROR: %s - Your \"designtools\" Allegro Variable is not set correctly." DTP))
      (go EndProg)))



  ;*****************************************************************************
  ; PROCEDURE: Deletes the installed files and directories
  (procedure (DT_uninstall_delete)
    (setq DTP "(DT_uninstall_delete)")
    (fprintf DTOP_log "\n%s\nRunProcedure: %s\n" DT_t_LINE3 DTP)
    ;load the listing of installed files and directories
    (unless (load (strcat DTPath "/base/ins/DT_install_sets.il"))
      (setq ErrMsg (sprintf nil "ERROR: Install Sets File Missing.\n%s" DTPath))
      (go EndProg))                                                                        
    ; loop through the installed file and directory sets
    (foreach FilesSet DT_FILE_SETS
      (setq ModuleID (car   FilesSet))
      (setq PathList (reverse (cadr  FilesSet)))  ; needs to be reversed
      (setq FileList (caddr FilesSet))
      (foreach FileName FileList                  ; delete files
        (if (deleteFile (strcat DTPath FileName))
        then (fprintf DTOP_log "Deleted_File: \"%s\"\n" (strcat DTPath FileName))
        else
          (setq ErrMsg (sprintf nil "ERROR: Failed To Delete File\n%s" FileName))
          (go EndProg)))
      (foreach PathName PathList                  ; delete sub-directories
        (if (deleteDir (strcat DTPath PathName))
        then (fprintf DTOP_log "Deleted_Path: \"%s\"\n" (strcat DTPath PathName))
        else
          (setq ErrMsg (sprintf nil "ERROR: Failed To Delete Directory\n%s" PathName))
          (go EndProg))))
    (if (deleteDir DTPath)                        ; delete DesignTools Directory
    then (fprintf DTOP_log "Deleted_Path: \"%s\"\n" DTPath)
    else
      (setq ErrMsg (sprintf nil "ERROR: Failed To Delete DesignTools Directory\n%s" DTPath))
      (go EndProg)))

  ;*****************************************************************************
  ; PROCEDURE: Remove DT entries from "allegro.ilinit" and menu files
  (procedure (DT_uninstall_edit_file FileNew "t")
    (setq DTP "(DT_uninstall_file_edit)")
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
    (fprintf DTOP_log "FileNew_Name: %s\n" FileNew)      
;NOFIX - Cadence SPB 15.2 (makeTempFileName *) function has bugs
    ; create a string with fully qualifed path to "filename_old.XXXX" file.
    ; this doesn't really work exactly as planed since the (makeTempFileName *)
    ; function has bugs and truncates file names at eight characters.
    (setq FileOld (strcat (car FileParts) "/" (cadr FileParts) "_old.XXXX"))
    (fprintf DTOP_log "FileOld_Name: %s\n" FileOld)
    (setq FileOld (makeTempFileName FileOld))
    (fprintf DTOP_log "FileOld_Real: %s\n" FileOld)
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
    ; copy the contents of the original file into our new file
    ; and delete anything between our marks, including the marks
    (setq Mark_Cnt 0)
    (while (gets CurLine InnFH)
      (when (equal CurLine MarkText) (preincrement Mark_Cnt))
      (caseq Mark_Cnt
        (0 (fprintf OutFH "%s" CurLine))
        (1 (fprintf DTOP_log "Deleted_Line: %L\n" CurLine))
        (2 (setq Mark_Cnt 0) (fprintf DTOP_log "Deleted_Line: %L\n" CurLine))))
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
  ;PROCEDURE: Remove allegro.ilintit entries
  (procedure (DT_uninstall_edit_init)
    (setq DTP "(DT_uninstall_edit_init)")
    (fprintf DTOP_log "\n%s\nRunProcedure: %s\n" DT_t_LINE3 DTP)
    (setq FileNew (strcat LocalEnv "/allegro.ilinit"))
    (setq FileNew (DT_uninstall_unix_slash FileNew))
    (rexCompile "//")
    (setq FileNew (rexReplace FileNew "/" 0))     ; remove double slash //
    (fprintf DTOP_log "OrigInitName: %L\n" FileNew) 
    (setq MarkText (sprintf nil ";%s\n" MarkerDT))
    (DT_uninstall_edit_file FileNew))


  ;*****************************************************************************
  ;PROCEDURE: Remove allegro.ilintit entries
  (defun DT_uninstall_edit_menu ()
    (let ( DTP MenuFileName MenuFileList)
      (setq DTP "(DT_uninstall_edit_menu)")
      (fprintf DTOP_log "\n%s\nRunProcedure: %s\n" DT_t_LINE3 DTP)
      ;load the listing of installed menu items
      (unless (load (strcat DTPath "/base/ins/DT_install_menu.il"))
        (setq ErrMsg (sprintf nil "ERROR: Install Menu File Missing.\n%s" DTPath))
        (go EndProg))                                                                        
      ; loop through the menu file item sets
      (foreach MenuSet DT_MENU_SETS
        (fprintf DTOP_log "ProcessMenu_: %L\n" MenuSet->file)
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
        ;loop through all menu files
        (foreach MenuFileName MenuFileList
          (fprintf DTOP_log "\nMenuFileName: %L\n" MenuSet->file)
          ; find the current location of the menu file (i.e. "allegro.men" )
          (unless (setq FileNew (axlDMFindFile  "MENU" MenuFileName "r"))
            (setq ErrMsg (sprintf nil "ERROR: %s Could Not Locate The \"%s\" Menu File.\n" 
                DTP MenuFileName))
            (go EndProg))
          (setq FileNew (DT_uninstall_unix_slash FileNew))
          (rexCompile "//")
          (setq FileNew (rexReplace FileNew "/" 0))     ; remove double slash //
          (fprintf DTOP_log "OrigMenuName: %L\n" FileNew) 
          (setq MarkText (sprintf nil "//%s\n" MarkerDT))  
          (DT_uninstall_edit_file FileNew)
        )
      )
    )
  )
;FIXME -Relading the menu may not work on UNIX according to docs?
;      (if (equal MenuSet->file "allegro.men") (axlUIMenuLoad "allegro.men"))



  ;*****************************************************************************
  ;PROCEDURE: Unregister Allegro Shell commands and unbind DT function names
  ; The registered "Allegro Shell" command names are saved/stored as all lower
  ; case regardless of how they are entered. The SKILL Function/Procedure names
  ; they link to retain their capitalization.
  ; This also unbinds the DesignTools function/procedure names to prevent them
  ; from being mistakenly used/called again.
  (procedure (DT_uninstall_unreg)
    (setq DTP "(DT_uninstall_unreg)")
    (fprintf DTOP_log "\n%s\nRunProcedure: %s\n" DT_t_LINE3 DTP)
    (when (greaterp (axlVersion 'version) 14.2)
      (setq CmdList (axlCmdList))
      (foreach CmdPair CmdList
        (setq FunName (cadr CmdPair))
        (fprintf DTOP_log   "Exists_____: %L\n" FunName)
        (when (or (rexMatchp "^DT" FunName) (rexMatchp "^_DT" FunName))
          (axlCmdUnregister FunName)                             ;unreg command
          (putd (stringToSymbol (sprintf nil "%s" FunName)) nil) ;unbind function
          (fprintf DTOP_log "Unregister__: %L\n" FunName)))))
;FIXME -this is less than perfect for unbinding DT functions. We should parse
;the list of all available functions to do it right.

  
  ;*****************************************************************************
  ;PROCEDURE: Remove User Configuration Files
  
  
  ;*****************************************************************************
  ; continue main procedure
  (if (axlUIYesNo "Would you like to uninstall your existing DesignTools?\n")
  then
    (DT_uninstall_get_log)
    (DT_uninstall_get_localenv)
    (DT_uninstall_get_dtpath)
    (DT_uninstall_test_write)
    (DT_uninstall_edit_init)
    (DT_uninstall_edit_menu)
;    (DT_uninstall_menus)
    (DT_uninstall_unreg)
    (DT_uninstall_delete)
    ; it seems we finished correctly
    (setq DTP "(DT_uninstall_main)")
    (fprintf DTOP_log "\nRunProcedure: %s -Finished Uninstall\n" DTP)
    (fprintf DTOP_log "\nRunProcedure: %s -Completed Successfully\n" DTP)
    (setq IsComplete t)
  else
    (setq DTP "(DT_uninstall_main)")
    (setq IsCancel t)
    (printf "\nRunProcedure: %s -User Cancel Uninstall\n" DTP))


; End of main procedure
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
;FIXME -need to add file recovery for failed uninstall "EditList"
    (printf ErrMsg)
    (axlUIConfirm ErrMsg)
    (axlUIViewFileCreate (strcat TempDir "/DT_uninstall.log") "Uninstall Log" nil)
    (when (axlOKToProceed) (return nil)))
  
  (if IsComplete
  then
    (axlUIConfirm (sprintf nil "Your DesignTools have been uninstalled.\n\nIf you have any open instances of Cadence\nprograms, they should be restarted.\n\nYour personal settings have been retained\nin your $home/.DesignTools/ directory.\n\nYou may manually delete this directory if\nyou no longer wish to retain your settings\n"))
;    (axlUIViewFileCreate (strcat TempDir "/DT_uninstall.log") "Uninstall Log" nil)
    (when (axlOKToProceed) (return t))
  else
    (if IsCancel
    then
      (return nil)
    else
      (axlUIViewFileCreate (strcat TempDir "/DT_uninstall.log") "Uninstall Log" nil)
      (when (axlOKToProceed) (return nil))))
));end prog & procedure
