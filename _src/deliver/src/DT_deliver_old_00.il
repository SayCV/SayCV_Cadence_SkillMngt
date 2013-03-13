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


/* ********************************************************************************

PROGRAM NOTES - Deliver

Configuration Files:
  1.) SITE Configuration File   -Saved in user defiend location
  2.) USER Configuration File   -Saved in localenv
  3.) PROJ Configuration File   -Saved in Current Project Directory

GUI Forms:
  1.) Main Program
  2.) Create/Edit Settings Entry

Things We Could Deliver:
  1.) Deliver Current Parts     -Show Current Progress To Client
  2.) Deliver Current Board     -Show Current Progress To Clinet
  3.) Deliver Finished Board    -Deliver Completed Project


*/


;*******************************************************************************
; Register the callable command(s)
;
(axlCmdRegister "DT_deliver_main", "DT_deliver_main")



;*******************************************************************************
;
(procedure (DT_deliver_main)
(prog 
  ; localized variables and procedures
  ( 
    DTD                 ; bool - debug message flag
    DTP                 ; string - current procedure name
    DTOP_log            ; port/handle - logging file
    ErrMsg              ; string - error message
    TempDir             ; string - system temporary directory

    OutFH               ; port/handle - output file

    UserFile            ; string - FQN for user conf "DT_deliver_conf.il"
    SiteFile            ; string - FQN for site conf
    LocalEnv            ; string - the "localenv" Allegro Variable

    CustomerStruct      ; structure for customer records
;    CustList            ; list of customer structures

    VersionDeliver      ; version number of the deliver program
    VersionSetting      ; version number of the conf file
    
    FormMain            ; symbol - for main form file
    FormEdit            ; symbol - for edit form file

    FormMainFile        ; string - FQN for form file
    FormEditFile        ; string - FQN for form file

;    DT_deliver_get_version
;    DT_deliver_chk_version

  )

  (setq DTD nil)
  (defstruct CustomerStruct type name)    ; structure for customer records
  (setq CustRecord (make_CustomerStruct)) ; a reusable instance of the struct
  (setq CustList nil)                     ; list of customer structures
  (setq UserFile nil)
  (setq SiteFile nil)
  
  (setq FormMainFile nil)
  (setq FormEditFile nil)

  (setq RG_g_FORM nil)                   ; Form Handle
  (setq RG_t_LINE3 "--------------------------------------------------------------------------------")

  (rexMagic t)  ; Make sure we have "magic" characters turned on for regex

  ;*****************************************************************************
  ;
  (defun DT_deliver_get_log ()
    (let ( DTP)
      (setq DTP "(DT_deliver_get_log)")
      (unless (setq DTOP_log (outfile "./DT_deliver.log"))
        (setq ErrMsg "ERROR - Can not write log file to current directory.")
        (go EndProg))
      (fprintf DTOP_log "DesignTools Deliver Logging\n")
      (fprintf DTOP_log "\n%s\nCurProcedure: %s\n" RG_t_LINE3 DTP)
      (fprintf DTOP_log       "Log_File....: %L\n" (get_filename DTOP_log))))
  
  ;*****************************************************************************
  ;
  


  ;*****************************************************************************
  ; PROCEDURE: Get the conf files loaded
  ; The local conf file should contain the user-created entries and if need
  ; be, a link to the site conf file
  (procedure (DT_deliver_get_conf)
    (setq DTP "(DT_deliver_get_conf)")
    (fprintf DTOP_log "\n%s\nCurProcedure: %s\n" RG_t_LINE3 DTP)
    ; if the *localenv/DesignTools/ directory doesn't exist, create it.
    (setq UserFile (strcat LocalEnv "/DesignTools"))
    (unless (and !(null UserFile) (isDir UserFile))
      (unless (createDir UserFile)
        (setq ErrMsg "ERROR: Could not create local DesignTools directory.\n")
        (go EndProg)))
    ; if the *localenv/DesignTools/deliver directory doesn't exist, create it.
    (setq UserFile (strcat UserFile "/deliver"))  
    (unless (and !(null UserFile) (isDir UserFile))
      (unless (createDir UserFile)
        (setq ErrMsg "ERROR: Could not create local DesignTools/deliver directory.\n")
        (go EndProg)))

    (setq UserFile (strcat UserFile "/DT_deliver_conf.il"))
    
;HACKS a hack for developing the conf files
    (setq TempHack nil)
    (if TempHack
;    (if (and !(null UserFile) (isFile UserFile))
    then 
;FIXME - test file version and edit
      (fprintf DTOP_log "File_Exists_: %L\n" UserFile)
      (load UserFile)
      (foreach CustRecord CustList
        (fprintf DTOP_log "  CustRecord: %s:%s\n" CustRecord->type CustRecord->name))

    ; must be the first run, so create an initial "/DT_deliver_conf.il" file
    else
      (fprintf DTOP_log "File_Created: %L\n" UserFile)

      (setq CustRecord (make_CustomerStruct))
      CustRecord->type = "USER"
      CustRecord->name = "_GENERIC_"
;      (setq CustList (cons (copy_CustomerStruct CustRecord) CustList))
      (setq CustList (cons CustRecord CustList))
      (setq CustRecord (make_CustomerStruct))
      CustRecord->type = "USER"
      CustRecord->name = "_GENERIC2_"
;      (setq CustList (cons (copy_CustomerStruct CustRecord) CustList))
      (setq CustList (cons CustRecord CustList))
      (setq CustRecord (make_CustomerStruct))
      CustRecord->type = "USER"
      CustRecord->name = "_GENERIC3_"
;      (setq CustList (cons (copy_CustomerStruct CustRecord) CustList))
      (setq CustList (cons CustRecord CustList))
      
      (DT_deliver_save_conf UserFile)

    )
    ; Get PROJECT conf file if it exists
  ); end procedure

;      type  user or site
;      name  customer name
  ;********************************************************************************
  ; PROCEDURE: Save the current conf to a file.
  
  (procedure (DT_deliver_save_conf FileSet "t")
    (setq DTP "(DT_deliver_save_conf)")
    (fprintf DTOP_log "\n%s\nCurProcedure: %s\n" RG_t_LINE3 DTP)
    ; open the local conf file for writing
    (unless (setq OutFH (outfile UserFile "w"))
      (setq ErrMsg (sprintf nil "ERROR: %s Failed to create new file\n%s\n" DTP UserFile))
      (go EndProg))
    
    (fprintf OutFH "; This is the conf for DesignTools Deliver.\n\n")
    (foreach CustRecord CustList
      (fprintf DTOP_log "Save_Record_: %s:%s\n" CustRecord->type CustRecord->name)
      (fprintf OutFH "  CustRecord->type = \"%s\"\n" CustRecord->type)
      (fprintf OutFH "  CustRecord->name = \"%s\"\n" CustRecord->name)
      (fprintf OutFH "(setq CustList (cons (copy_CustomerStruct CustRecord) CustList))\n"))
    
    (when SiteFile
      (fprintf OutFH "(setq SiteFile %L)\n" SiteFile)
      (fprintf OutFH "(load %L)\n" SiteFile))

    ;flush and close output file
    (when (and (boundp 'OutFH) (openportp OutFH))
      (unless (and (drain OutFH) (close OutFH) (setq OutFH 'unbound))
        (setq ErrMsg 
          (sprintf nil "\nERROR: %s - Flush/Close failed OutFH\n" DTP))
        (go EndProg)))
  )


  ;********************************************************************************
  ; PROCEDURE write the main program form file
  (procedure (DT_deliver_form_create)
    (setq DTP "(DT_deliver_form_create)")
    (fprintf DTOP_log "\n%s\nCurProcedure: %s\n" RG_t_LINE3 DTP)
    ; open the main form file for writing in current directory
    (setq FormMainFile "./DT_deliver.form")
    (unless (setq OP_form (outfile FormMainFile "w"))
      (setq ErrMsg (sprintf nil "ERROR: %s Failed to create new file\n%L\n" DTP FormMainFile))
      (go EndProg))
    (setq FormMainFile (get_filename OP_form)) ;get FQN for main form file
    
    (unless 
      (and ; write out form file contents
        (fprintf OP_form "FILE_TYPE=FORM_DEFN VERSION=2\n")
        (fprintf OP_form "FORM FIXED_FONT\n")
        (fprintf OP_form "FIXED\n")
        (fprintf OP_form "PORT 110 64\n")
        (fprintf OP_form "HEADER \"DesignTools: Deliver\"\n")
        (fprintf OP_form "DEFAULT \"OpCloseButton\"\n")
        (fprintf OP_form "\n")
        ;popups
        (fprintf OP_form "POPUP <popCellProp>\"NONE\"\"0\".\n")
        ;begin tile
        (fprintf OP_form "TILE\n")
        (fprintf OP_form "\n")

        ;close button
        (fprintf OP_form "FIELD OpCloseButton\n")
        (fprintf OP_form "FLOC 97 39\n")
        (fprintf OP_form "MENUBUTTON \"Close\" 12 3\n")
        (fprintf OP_form "ENDFIELD\n")
        (fprintf OP_form "\n")

        (fprintf OP_form "ENDTILE\n")
        (fprintf OP_form "\n")
        (fprintf OP_form "ENDFORM\n"))
      ;end of big unless and
      (setq ErrMsg (sprintf nil "ERROR: %s Failed to write new file\n%L\n" DTP FormMainFile))
      (go EndProg))
      
    ;flush and close output file
    (when (and (boundp 'OP_form) (openportp OP_form))
      (unless (and (drain OP_form) (close OP_form) (setq OP_form 'unbound))
        (setq ErrMsg 
          (sprintf nil "\nERROR: %s - Flush/Close failed OP_form\n" DTP))
        (go EndProg)))
    ; generate form symbol
    (unless (setq FormMain (axlFormCreate (gensym) FormMainFile  '( "msglines" 3 "E" "inner" ) 'DT_deliver_form_cb nil))
      (setq ErrMsg (sprintf nil "\nERROR: %s - Failed to load form.\n%L\n" DTP FormMainFile))
      (go EndProg))

  )

  ;********************************************************************************
  ; PROCEDURE: the main form callback
  (procedure (DT_deliver_form_cb FormArg "g")
    (setq DTP "(DT_deliver_form_cb)")
    (fprintf DTOP_log "\n%s\nCurProcedure: %s\n" RG_t_LINE3 DTP)
    (_DTL_UTILS_PrintProp DTOP_log FormArg)
    ; sanity check for form state
    (unless (FormArg->doneState == 0)
      (setq ErrMsg (sprintf nil "\nERROR: %s - Form not in \"done\" state.\n\n" DTP))
      (go EndProg))
    ; 

    ; The big case...
    (case FormArg->curField
      ("OpCloseButton"
        (fprintf DTOP_log "\nFUNCTION: %s - MainForm->curField == %L\n" DTP FormArg->curField )
        (axlFormClose FormArg))
    ) ;end big case
  )

  ;********************************************************************************
  ; PROCEDURE: the main form init
  (procedure (DT_deliver_form_init)
    (setq DTP "(DT_deliver_form_init)")
    (fprintf DTOP_log "\n%s\nCurProcedure: %s\n" RG_t_LINE3 DTP)
    
    ;display the form
    (axlFormDisplay FormMain)
  )



;  ;********************************************************************************
;  ; PROCEDURE write the form file for editing entries
;  (procedure (DT_deliver_form_edit_write)
;    (setq DTP "(DT_deliver_form_edit_write)")
;    (fprintf DTOP_log "\n%s\nCurProcedure: %s\n" RG_t_LINE3 DTP)
;
;  )


  ;********************************************************************************
  ; main program
  (DT_deliver_get_log)
  (unless (setq TempDir (_DTL_UTILS_get_temp))
    (setq ErrMsg "ERROR - Environment Variable TEMP (MS-Windows) or TMP (UNIX)\nis not set to your temporary directory or is not a writable directory.")
    (go EndProg))
  (unless (setq LocalEnv (_DTL_UTILS_get_localenv))    
     (setq ErrMsg "ERROR: Allegro Variable \"localenv\" is not set.\n")
     (go EndProg))

  (_DTL_UTILS_conf_get "DT_deliver_cfg.il")

;  (DT_deliver_get_temp)
;  (DT_deliver_get_localenv)
  (DT_deliver_get_conf)
  (DT_deliver_form_create)
  (DT_deliver_form_init)

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
  ;show the error message and log file
  (when ErrMsg
    (printf ErrMsg)
    (axlUIConfirm ErrMsg)
;    (axlUIViewFileCreate (strcat TempDir "/DT_deliver.log") "DT Deliver Log" nil)
    (when (axlOKToProceed) (return nil)))


));end let & procedure

