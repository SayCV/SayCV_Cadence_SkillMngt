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

;-------------------------------------------------------------------------------
; This application allows the user to tell us where to look for site wide
; program configuration data
;
;We'll Have Three Levels of configuration files:

/*

SITE    -   DT_CONF_SITE
  This will be a location where shared configuration files will be stored. The
  company EDA/CAD manager will be able to define the SITE-level configuration of
  the tools and keep the configuration files in read-only directory, shared over
  NFS, SMB or similar.

USER    -   DT_CONF_USER
  This will be the location where users store their personal configuration
  files.

FILE
  Data on previous configuration choices will be stored within the project
  directory itself so the chosen configuration for THIS PARTICULAR design
  will be retained.

  It would be nice to store this data in the board file itself but that means
  this code will only be usable with boards.


Store the DT_CONF_SITE and DT_CONT_USER someplace?
  * We can not put these in the __DesignTools__ section of the allegro.ilinit
    file since it would require force the user to re-enter information every
    tim they install a new version of DesignTools.

  * we could put the information at the end of the allegro.ilinit file

  * we could put the information in a file in the users $home directory

  * we could put the information in a file in the users $pcbenv directory.

  * we can not write into the DesignTools directory since this will mess up the
    uninstall routine (you can't delete a directory when it's not empty).

--------------------------------------------------------------------------------
Order of execution:

1.) If an application finds one of it's configuration files in the current
    working directory, the file is loaded. This tells us the config entry name
    to use.

2.) Next we load the USER configuration file for the application.

3.) If DTG_CONF_SITE exists and there is a SITE configuration file for the
    application, we load it.

*/
;-------------------------------------------------------------------------------

;*******************************************************************************
; Register the callable command(s)
(axlCmdRegister "DT_config_main", "DT_config_main")

;*******************************************************************************
; the main() procedure is basically a loader of sorts which sets up the form,
; and activates the form and timer and exit/cleanup callbacks.
(procedure (DT_config_main)
(prog
  ( ;start local symbol bindings
    DTP                           ; Procedure Name
    DTD                           ; Debug print switch
    DTOP_log                      ; Output Port for log
    DTOB_FORM                     ; Form Object Handle
    LogsFileName
    FormFileName
    ErrMsg
    HelpURLlocal
    HelpURLonline
    TMP_CONF_SITE
    CancelFlag
  ) ;end local symbol bindings
  ;procedure body expressions
  (unless (and
      (setfdoc 'DT_config_main "DesignTools: Configurator program launcher.")
      (setq DTP "(DT_config_main)")
      (setq LogsFileName (strcat (getWorkingDir) "/DT_config.log"))
      (setq FormFileName (strcat (getWorkingDir) "/DT_config.form"))
      (rexCompile "\\\\")
      (setq LogsFileName (rexReplace LogsFileName "/" 0))
      (setq FormFileName (rexReplace FormFileName "/" 0))
;      (setvdoc
    )
    (printf "\n\nERROR: (DT_config_main) - Could Not Set Variables\n\n")
    (go EndProg))

  (setq DTD nil)
  (setq DTV "DT-config-v1.1")
  (when DTD
    (printf "\nSTATUS: %s \n" DTP)
    (printf "LogsFileName: %L\nFormFileName: %L\n" LogsFileName FormFileName))

  ; open logging file
  (unless (setq DTOP_log (outfile LogsFileName "w"))
    (printf "\n\nERROR: %s - Can Not Open Log Output File!\n" DTP)
    (go EndProg))
  (when DTD (printf "DTOP_log: %L\n" (get_filename DTOP_log)))
  (putprop 'DT_config_main DTOP_log "DTOP_log")
  ; open the text help file
  (unless (setq DTIP_help
      (infile (strcat (axlGetVariable "designtools") "/base/cfg/DT_config_quickhelp.txt")))
    (printf "\n\nERROR: %s - Can Not Open QuickHelp File!\n" DTP)
    (go EndProg))
  (when DTD (printf "DTIP_help: %L\n" (get_filename DTIP_help)))
  (putprop 'DT_config_main DTIP_help "DTIP_help")

  ; set the location of the help files
  (putprop 'DT_config_main
      (strcat "file://localhost/"
          (axlGetVariable "designtools") "/base/man/index.html")
      "HelpURLlocal")
  (putprop 'DT_config_main
      (strcat "http://www.DesignTools.org/programs/cadence/pcb-editor/configurator/index.php?"
          DTV)
      "HelpURLonline")

  ;--------------------------------------------------------------------------------
  ;The DTG_CONF_SITE top-level variable symbol should point to the location
  ;where the SITE configuration files are saved.
  ;
  ;The DTG_CONF_USER top-level variable symbol should point to the location
  ;where the USER configuration files are saved.
  ;
  ;If either is unbound, we've got a serious problem.
  (unless (and (boundp 'DTG_CONF_SITE) (boundp 'DTG_CONF_USER))
    (printf "\n\nERROR: %s - Top Level Variables Are Not Properly Set\n\tDTG_CONF_USER\n\tDTG_CONF_SITE\n" DTP)
    (go EndProg))
  ;The DTG_CONF_USER variable should always be non-nil and point to an existing
  ;directory. Normally it's the "$home/.DesignToools" directory.
  (unless (and (not (null DTG_CONF_USER)) (isDir DTG_CONF_USER) (isWritable DTG_CONF_USER))
    (printf "\n\nERROR: %s - DTG_CONF_USER is not a directory." DTP)
    (go EndProg))

  (rexCompile "\\\\")
  (setq DTG_CONF_USER (rexReplace DTG_CONF_USER "/" 0))
  (unless (null DTG_CONF_SITE)
    (setq DTG_CONF_SITE (rexReplace DTG_CONF_SITE "/" 0)))
  (setq TMP_CONF_SITE DTG_CONF_SITE)

;FIXME -I should be setting and unsetting write protect on the variable symbols
;This will need to be done in the installer as well as here.
; (setVarWriteProtect...)
; (getVarWriteProtect...)

  ; create non-blocking form and initialize it
  (if (setq DTOB_FORM (DT_config_form_create FormFileName))
  then
    (putprop 'DT_config_main DTOB_FORM "DTOB_FORM")
    (DT_config_form_init)
  else
    (printf "\nERROR: %s Could not create form!\n" DTP)
    (go EndProg))

  ; Everything should be set up and running...

  ;exiting
  (unless CancelFlag
    ; open the config file
    (unless (setq DTOP_cfg (outfile (strcat DTG_CONF_USER "/DT_config_cfg.il")))
      (printf "\n\nERROR: %s - Can Not Open Config File!\n" DTP)
      (go EndProg))

    (if TMP_CONF_SITE
    then
      (rexCompile "\\\\") ;replace single backslash "\"
      (setq TMP_CONF_SITE (rexReplace TMP_CONF_SITE "/" 0))
      (rexCompile "//")   ;replace double slash "//"
      (setq TMP_CONF_SITE (rexReplace TMP_CONF_SITE "/" 0))
      (rexCompile "/$")   ;trim trailing "/"
      (setq TMP_CONF_SITE (rexReplace TMP_CONF_SITE "" 0))
      (if (and (isDir TMP_CONF_SITE) (isReadable TMP_CONF_SITE))
      then
        (setq DTG_CONF_SITE TMP_CONF_SITE)
        (fprintf DTOP_cfg "(setq DTG_CONF_SITE %L)\n" DTG_CONF_SITE)
        (when DTD (printf "\nDTG_CONF_SITE: %L\n" DTG_CONF_SITE))
      else
        (setq ErrMsg (sprintf nil "Something went horribly wrong and there\nis garbage in the DTG_CONF_SITE variable."))
        (setq DTG_CONF_SITE nil)
        (fprintf DTOP_cfg "(setq DTG_CONF_SITE nil)\n")
        (go EndProg))
    else
        (setq DTG_CONF_SITE nil)
        (fprintf DTOP_cfg "(setq DTG_CONF_SITE nil)\n"))

    ;Write Company Contact Info
    (fprintf DTOP_cfg "\n(setq DTG_CONF_COMPANY (list\n")
    (fprintf DTOP_cfg "  %L\n" (nth 0 DTG_CONF_COMPANY))
    (fprintf DTOP_cfg "  %L\n" (nth 1 DTG_CONF_COMPANY))
    (fprintf DTOP_cfg "  %L\n" (nth 2 DTG_CONF_COMPANY))
    (fprintf DTOP_cfg "  %L\n" (nth 3 DTG_CONF_COMPANY))
    (fprintf DTOP_cfg "  %L\n" (nth 4 DTG_CONF_COMPANY))
    (fprintf DTOP_cfg "  %L\n" (nth 5 DTG_CONF_COMPANY))
    (fprintf DTOP_cfg "  %L\n" (nth 6 DTG_CONF_COMPANY))
    (fprintf DTOP_cfg "  %L\n" (nth 7 DTG_CONF_COMPANY))
    (fprintf DTOP_cfg "  %L\n" (nth 8 DTG_CONF_COMPANY))
    (fprintf DTOP_cfg "))\n")
    ;Write Designer Contact Info
    (fprintf DTOP_cfg "\n(setq DTG_CONF_DESIGNER (list\n")
    (fprintf DTOP_cfg "  %L\n" (nth 0 DTG_CONF_DESIGNER))
    (fprintf DTOP_cfg "  %L\n" (nth 1 DTG_CONF_DESIGNER))
    (fprintf DTOP_cfg "  %L\n" (nth 2 DTG_CONF_DESIGNER))
    (fprintf DTOP_cfg "  %L\n" (nth 3 DTG_CONF_DESIGNER))
    (fprintf DTOP_cfg "  %L\n" (nth 4 DTG_CONF_DESIGNER))
    (fprintf DTOP_cfg "))\n")
    ;Write Sales Contact Info
    (fprintf DTOP_cfg "\n(setq DTG_CONF_SALES (list\n")
    (fprintf DTOP_cfg "  %L\n" (nth 0 DTG_CONF_SALES))
    (fprintf DTOP_cfg "  %L\n" (nth 1 DTG_CONF_SALES))
    (fprintf DTOP_cfg "  %L\n" (nth 2 DTG_CONF_SALES))
    (fprintf DTOP_cfg "  %L\n" (nth 3 DTG_CONF_SALES))
    (fprintf DTOP_cfg "  %L\n" (nth 4 DTG_CONF_SALES))
    (fprintf DTOP_cfg "))\n")
  )

EndProg
  (fprintf DTOP_log "\nSTATUS: %s - Exiting\n" DTP)
  ; flush and close files
  (when (and (boundp 'DTOP_log) (openportp DTOP_log))
    (unless (and (drain DTOP_log) (close DTOP_log) (setq DTOP_log 'unbound))
      (printf "\nERROR: %s - Flush/Close failed DTOP_log file\n" DTP)))
  (when (and (boundp 'DTOP_cfg) (openportp DTOP_cfg))
    (unless (and (drain DTOP_cfg) (close DTOP_cfg) (setq DTOP_cfg 'unbound))
      (printf "\nERROR: %s - Flush/Close failed DTOP_cfg file\n" DTP)))
  (when (and (boundp 'DTIP_help) (openportp DTIP_help))
    (unless (and (close DTIP_help) (setq DTIP_help 'unbound))
      (printf "\nERROR: %s - Flush/Close failed DTIP_help file\n" DTP)))

  (when ErrMsg
    (printf ErrMsg))
));END_PROG_&_PROCEDURE (DT_config_main)

;--------------------------------------------------------------------------------
; PROCEDURE: Initialize form
(procedure (DT_config_form_init)
(prog ()
  (setq DTD nil)
  (when DTD (printf "\nSTATUS: %s \n" DTP))
; might want to validate that all these statement complete properly.
    (axlFormColorize DTOB_FORM "TxtMessage0" 'background 'button)
    (axlFormSetField DTOB_FORM "TxtMessage0" "There are three levels of configuration possible:")
    (axlFormColorize DTOB_FORM "TxtSite0" 'background 'white)
    (axlFormColorize DTOB_FORM "TxtSite1" 'background 'white)
    (axlFormColorize DTOB_FORM "TxtSite2" 'background 'white)
    (axlFormColorize DTOB_FORM "TxtSite3" 'background 'white)
    (axlFormSetField DTOB_FORM "TxtSite1" "Your company-wide settings for all employees to use on all projects. Stored in the directory you set below.")
    (if (null TMP_CONF_SITE)
    then
      (axlFormSetField DTOB_FORM "SiteSetRaidoNone" t)
      (axlFormSetFieldEditable DTOB_FORM "SiteFillin" nil)
      (axlFormSetFieldEditable DTOB_FORM "SiteButtonBrowse" nil)
      (axlFormSetFieldEditable DTOB_FORM "SiteButtonPromote" nil)
      (axlFormSetField DTOB_FORM "TxtSite3" " (Not Configured)")
      (axlFormSetField DTOB_FORM "SiteFillin" "(Not Configured)")
      (axlFormColorize DTOB_FORM "SiteFillin" 'background 'button)
      (axlFormColorize DTOB_FORM "TxtPromote" 'background 'button)
    else
      (axlFormSetField DTOB_FORM "SiteSetRaidoUsed" t)
      (axlFormSetFieldEditable DTOB_FORM "SiteFillin" t)
      (axlFormSetFieldEditable DTOB_FORM "SiteButtonBrowse" t)
      (axlFormSetFieldEditable DTOB_FORM "SiteButtonPromote" t)
      (axlFormSetField DTOB_FORM "TxtSite3" (strcat " \"" TMP_CONF_SITE "\""))
      (axlFormColorize DTOB_FORM "SiteFillin" 'background 'white)
      (axlFormColorize DTOB_FORM "TxtPromote" 'background 'white)
      (axlFormSetField DTOB_FORM "SiteFillin" TMP_CONF_SITE))

    (axlFormColorize DTOB_FORM "TxtUser0" 'background 'yellow)
    (axlFormColorize DTOB_FORM "TxtUser1" 'background 'yellow)
    (axlFormColorize DTOB_FORM "TxtUser2" 'background 'yellow)
    (axlFormColorize DTOB_FORM "TxtUser3" 'background 'yellow)
    (axlFormSetField DTOB_FORM "TxtUser1" "Your personal settings choices for all of the projects you do. Stored in your \"$home/.DesignTools\" directory.")
    (axlFormSetField DTOB_FORM "TxtUser3" (strcat " \"" DTG_CONF_USER "\""))
    (axlFormColorize DTOB_FORM "TxtFile0" 'background 'green)
    (axlFormColorize DTOB_FORM "TxtFile1" 'background 'green)
    (axlFormColorize DTOB_FORM "TxtFile2" 'background 'green)
    (axlFormColorize DTOB_FORM "TxtFile3" 'background 'green)
    (axlFormSetField DTOB_FORM "TxtFile1" "Your previous configuration choices for this particular project/file. Stored in the current working directory.")
    (rexCompile "\\\\")
    (axlFormSetField DTOB_FORM "TxtFile3"
        (strcat " \"" (rexReplace (getWorkingDir) "/" 0) "\""))
    (axlFormSetField DTOB_FORM "TxtPromote" "If you are the company CAD Manager and have write access to the SITE directory, you can promote your USER settings to become the new SITE settings.")
    ;load the QuickHelp tab
    (while (gets CurLine DTIP_help)
      (axlFormListAddItem DTOB_FORM "QHTxtMessage0" CurLine -1))

    (when (boundp 'DTG_CONF_COMPANY)
      (axlFormSetField DTOB_FORM "ContactCompanyName"    (nth 0 DTG_CONF_COMPANY))
      (axlFormSetField DTOB_FORM "ContactCompanyStreet"  (nth 1 DTG_CONF_COMPANY))
      (axlFormSetField DTOB_FORM "ContactCompanyCity"    (nth 2 DTG_CONF_COMPANY))
      (axlFormSetField DTOB_FORM "ContactCompanyState"   (nth 3 DTG_CONF_COMPANY))
      (axlFormSetField DTOB_FORM "ContactCompanyCode"    (nth 4 DTG_CONF_COMPANY))
      (axlFormSetField DTOB_FORM "ContactCompanyCountry" (nth 5 DTG_CONF_COMPANY))
      (axlFormSetField DTOB_FORM "ContactCompanyWeb"     (nth 6 DTG_CONF_COMPANY))
      (axlFormSetField DTOB_FORM "ContactCompanyFax"     (nth 7 DTG_CONF_COMPANY))
      (axlFormSetField DTOB_FORM "ContactCompanyPhone"   (nth 8 DTG_CONF_COMPANY)))

    ;save designer contact data
    (when (boundp 'DTG_CONF_DESIGNER)
      (axlFormSetField DTOB_FORM "ContactDesignerName"        (nth 0 DTG_CONF_DESIGNER))
      (axlFormSetField DTOB_FORM "ContactDesignerMainPhone"   (nth 1 DTG_CONF_DESIGNER))
      (axlFormSetField DTOB_FORM "ContactDesignerMainEmail"   (nth 2 DTG_CONF_DESIGNER))
      (axlFormSetField DTOB_FORM "ContactDesignerMobilePhone" (nth 3 DTG_CONF_DESIGNER))
      (axlFormSetField DTOB_FORM "ContactDesignerMobileEmail" (nth 4 DTG_CONF_DESIGNER)))

    ;save sales contact data
    (when (boundp 'DTG_CONF_SALES)
      (axlFormSetField DTOB_FORM "ContactSalesName"           (nth 0 DTG_CONF_SALES))
      (axlFormSetField DTOB_FORM "ContactSalesMainPhone"      (nth 1 DTG_CONF_SALES))
      (axlFormSetField DTOB_FORM "ContactSalesMainEmail"      (nth 2 DTG_CONF_SALES))
      (axlFormSetField DTOB_FORM "ContactSalesMobilePhone"    (nth 3 DTG_CONF_SALES))
      (axlFormSetField DTOB_FORM "ContactSalesMobileEmail"    (nth 4 DTG_CONF_SALES)))

    (axlFormDefaultButton   DTOB_FORM "OpOKButton")
    (axlFormSetActiveField  DTOB_FORM "OpOKButton")
    (axlFormDisplay DTOB_FORM)
    (axlUIWExpose DTOB_FORM)

))


;********************************************************************************
; This is the form callback procedure.
; We use the log file handle which was attached as a property to the _maim
; procedure.
(procedure (DT_config_form_cb Arg_DTOB_FORM "g")
(prog (
    DTP   ;DT Procedure Name
    DTD   ;DT Debug print switch
  ) ;end local bindings
  (setq DTD nil)
  (setq DTP "(DT_config_form_cb)")
  (when DTD (printf "\nSTATUS: %s \n" DTP))
  ; somebody hit the "X" to close the window
  (unless (equal Arg_DTOB_FORM->doneState 0)
    (when DTD
      (fprintf DTOP_log "\n\nSTATUS: %s - Form not in \"done\" state.\n\n" DTP))
    (setq CancelFlag t)
    (axlFormClose Arg_DTOB_FORM))
  ; debug printing
  (when DTD
    (fprintf DTOP_log
        "\n\nSTATUS: %s - Arg_DTOB_FORM->?? BASE" DTP)
    (_DTL_UTILS_PrintProp DTOP_log Arg_DTOB_FORM))
  ; The big case...
  (case Arg_DTOB_FORM->curField
    ("OpCancelButton"
      (when DTD
        (fprintf DTOP_log "\nSTATUS: %s - curField == %L\n" DTP
            Arg_DTOB_FORM->curField))
      (setq CancelFlag t)
      (axlFormClose Arg_DTOB_FORM))
    ("OpOKButton"
      (when DTD (fprintf DTOP_log
          "\nSTATUS: %s - curField == %L\n" DTP Arg_DTOB_FORM->curField))
      (setq CancelFlag nil)
      ;validate contact info
      ;save company contact data
      (setq DTG_CONF_COMPANY (list
          (axlFormGetField DTOB_FORM "ContactCompanyName")
          (axlFormGetField DTOB_FORM "ContactCompanyStreet")
          (axlFormGetField DTOB_FORM "ContactCompanyCity")
          (axlFormGetField DTOB_FORM "ContactCompanyState")
          (axlFormGetField DTOB_FORM "ContactCompanyCode")
          (axlFormGetField DTOB_FORM "ContactCompanyCountry")
          (axlFormGetField DTOB_FORM "ContactCompanyWeb")
          (axlFormGetField DTOB_FORM "ContactCompanyFax")
          (axlFormGetField DTOB_FORM "ContactCompanyPhone")))
      ;save designer contact data
      (setq DTG_CONF_DESIGNER (list
          (axlFormGetField DTOB_FORM "ContactDesignerName")
          (axlFormGetField DTOB_FORM "ContactDesignerMainPhone")
          (axlFormGetField DTOB_FORM "ContactDesignerMainEmail")
          (axlFormGetField DTOB_FORM "ContactDesignerMobilePhone")
          (axlFormGetField DTOB_FORM "ContactDesignerMobileEmail")))
      ;save sales contact data
      (setq DTG_CONF_SALES (list
          (axlFormGetField DTOB_FORM "ContactSalesName")
          (axlFormGetField DTOB_FORM "ContactSalesMainPhone")
          (axlFormGetField DTOB_FORM "ContactSalesMainEmail")
          (axlFormGetField DTOB_FORM "ContactSalesMobilePhone")
          (axlFormGetField DTOB_FORM "ContactSalesMobileEmail")))
      ;validate CONF_SITE
      (setq TMP_CONF_SITE (axlFormGetField DTOB_FORM "SiteFillin"))
      (if (axlFormGetField DTOB_FORM "SiteSetRaidoUsed")
      then
        (if (and TMP_CONF_SITE (isDir TMP_CONF_SITE) (isReadable TMP_CONF_SITE))
        then
          (axlFormClose Arg_DTOB_FORM)
        else
          (axlUIConfirm "The text you entered is not a directory or you\ndo not have read permissions on the directory.\n\nPlease choose a new directory or choose cancel."))
      else
        (if (axlFormGetField DTOB_FORM "SiteSetRaidoNone")
        then
          (setq TMP_CONF_SITE nil)
          (axlFormClose Arg_DTOB_FORM)))


    )
    ("SiteButtonBrowse"
      (when DTD (fprintf DTOP_log
          "\nSTATUS: %s - curField == %L\n" DTP Arg_DTOB_FORM->curField))
      (setq TMP_CONF_SITE
          (axlDMDirectoryBrowse "." nil  ?title
              "Choose SITE Configuration Directory"))
      (if (null TMP_CONF_SITE)
      then
        (axlFormSetField DTOB_FORM "SiteSetRaidoNone" t)
        (axlFormSetFieldEditable DTOB_FORM "SiteFillin" nil)
        (axlFormSetFieldEditable DTOB_FORM "SiteButtonBrowse" nil)
        (axlFormSetFieldEditable DTOB_FORM "SiteButtonPromote" nil)
        (axlFormSetField DTOB_FORM "TxtSite3" " (Not Configured)")
        (axlFormSetField DTOB_FORM "SiteFillin" "(Not Configured)")
        (axlFormColorize DTOB_FORM "SiteFillin" 'background 'button)
        (axlFormColorize DTOB_FORM "TxtPromote" 'background 'button)
      else
        (rexCompile "\\\\")
        (setq TMP_CONF_SITE (rexReplace TMP_CONF_SITE "/" 0))
        (axlFormColorize DTOB_FORM "SiteFillin" 'background 'white)
        (axlFormColorize DTOB_FORM "TxtPromote" 'background 'white)
        (axlFormSetField DTOB_FORM "TxtSite3" (strcat " \"" TMP_CONF_SITE "\""))
        (axlFormSetField DTOB_FORM "SiteFillin" TMP_CONF_SITE)))
    ("SiteSetRaidoUsed"
      (when DTD (fprintf DTOP_log
          "\nSTATUS: %s - curField == %L\n" DTP Arg_DTOB_FORM->curField))
      (axlFormColorize DTOB_FORM "SiteFillin" 'background 'white)
      (axlFormColorize DTOB_FORM "TxtPromote" 'background 'white)
      (axlFormSetFieldEditable DTOB_FORM "SiteFillin" t)
      (axlFormSetFieldEditable DTOB_FORM "SiteButtonBrowse" t)
      (axlFormSetFieldEditable DTOB_FORM "SiteButtonPromote" t)
      (axlFormSetField DTOB_FORM "TxtSite3" " (Please Select Directory)")
      (axlFormSetField DTOB_FORM "SiteFillin" "(Please Select Directory)"))
    ("SiteSetRaidoNone"
      (when DTD (fprintf DTOP_log
          "\nSTATUS: %s - curField == %L\n" DTP Arg_DTOB_FORM->curField))
      (setq TMP_CONF_SITE nil)
      (axlFormSetFieldEditable DTOB_FORM "SiteButtonBrowse" nil)
      (axlFormSetFieldEditable DTOB_FORM "SiteButtonPromote" nil)
      (axlFormSetField DTOB_FORM "TxtSite3" " (Not Configured)")
      (axlFormSetField DTOB_FORM "SiteFillin" "(Not Configured)")
      (axlFormColorize DTOB_FORM "SiteFillin" 'background 'button)
      (axlFormColorize DTOB_FORM "TxtPromote" 'background 'button))
    ("HelpButtonOnLine"
      (when DTD (fprintf DTOP_log
          "\nSTATUS: %s - curField == %L\n" DTP Arg_DTOB_FORM->curField))
      (axlHttp (get 'DT_config_main "HelpURLonline")))
;    ("HelpButtonLocal"
;      (when DTD (fprintf DTOP_log
;          "\nSTATUS: %s - curField == %L\n" DTP Arg_DTOB_FORM->curField))
;      (axlHttp (get 'DT_config_main "HelpURLlocal")))
    ("SiteButtonPromote"
      (if (null TMP_CONF_SITE)
      then
        (axlUIConfirm (sprintf nil
            "Please Click The \"Browse\"\nButton To Set The SITE Directory\n"))
      else
        (if (isDir TMP_CONF_SITE)
        then
          (if (isWritable TMP_CONF_SITE)
          then
            ;do something useful
            (axlUIConfirm
                (sprintf nil "At the moment, none of the other DesignTools programs\nhave been wired into the new configuration framework.\n\nThis is a nice way to say there is nothing for you to promote.\nPlease try again when I get the other applications incorporate\ninto the new config framework. Thanks for the patience."))
          else
          (axlUIConfirm (sprintf nil
              "You Do Not Have Write Permission\nTo The SITE Directory\n\t%L"
              TMP_CONF_SITE)))
        else
          (axlUIConfirm (sprintf nil
            "ERROR - %s\n\nYou should never see this message.\nPlease report it.\n\nIt means something went dreadfully wrong\nwith selecting your SITE directory.\n\nThe best thing you could do is click the\n\"Browse\" Button and select a new directory." DTP))))))
  (drain DTOP_log)
));END_PROG_&_PROCEDURE (DT_config_form_cb)

;*******************************************************************************
; Write the form file and instantiate
(procedure (DT_config_form_create ArgFormFileName "t")
(prog (
    DTP                           ;DT Procedure Name
    DTD                           ;DT Debug print switch
    DTOP_form                       ; output port for writing the form file
    FormSym                       ; the handle to the form
  ) ;end local bindings
  (setq DTP "(DT_config_form_create)")
  (setq DTD nil)
  (when DTD (printf "\nSTATUS: %s \n" DTP))
  (unless (setq DTOP_form (outfile ArgFormFileName "w")) ; open form file handle
    (printf "\nERROR: %s - Can Not Open Form Output File!\n" DTP)
    (return nil))
  (unless
    (and ; write out form file contents
        (fprintf DTOP_form "FILE_TYPE=FORM_DEFN VERSION=2\n")
        (fprintf DTOP_form "FORM FIXED_FONT\n")
        (fprintf DTOP_form "FIXED\n")
        (fprintf DTOP_form "PORT 66 40\n")
        (fprintf DTOP_form "HEADER \"DesignTools: Configurator\"\n")
        (fprintf DTOP_form "DEFAULT \"OpCancelButton\"\n")
        (fprintf DTOP_form "\n")
        ;begin tile
        (fprintf DTOP_form "TILE\n")
        (fprintf DTOP_form "\n")
        ;start tab set
        (fprintf DTOP_form "TABSET \"FullTabSet\"\n")
        (fprintf DTOP_form "FLOC 0 0\n")
        (fprintf DTOP_form "FSIZE 67 35\n")
        (fprintf DTOP_form "OPTIONS tabsetDispatch\n")
        (fprintf DTOP_form "\n")
          ;start Site Configuration Tab
          (fprintf DTOP_form "TAB \"Site Configuration\"\n")
          (fprintf DTOP_form "\n")
            ;start text messages
            (fprintf DTOP_form "TEXT \"Message\" TxtMessage0\n")
            (fprintf DTOP_form "FLOC 1 0\n")
            (fprintf DTOP_form "FSIZE 65 2\n")
            (fprintf DTOP_form "OPTIONS BORDER CENTER BOLD\n")
            (fprintf DTOP_form "ENDTEXT\n")
            (fprintf DTOP_form "\n")
            ; SITE Info Text
            (fprintf DTOP_form "TEXT \"SITE\" TxtSite0\n")
            (fprintf DTOP_form "FLOC 1 2\n")
            (fprintf DTOP_form "FSIZE 6 2\n")
            (fprintf DTOP_form "OPTIONS BORDER CENTER BOLD\n")
            (fprintf DTOP_form "ENDTEXT\n")
            (fprintf DTOP_form "\n")
            (fprintf DTOP_form "TEXT \"message\" TxtSite1\n")
            (fprintf DTOP_form "FLOC 8 2\n")
            (fprintf DTOP_form "FSIZE 58 4\n")
            (fprintf DTOP_form "OPTIONS BORDER\n")
            (fprintf DTOP_form "ENDTEXT\n")
            (fprintf DTOP_form "\n")
            (fprintf DTOP_form "TEXT \"site:\" TxtSite2\n")
            (fprintf DTOP_form "FLOC 8 5\n")
            (fprintf DTOP_form "FSIZE 6 2\n")
            (fprintf DTOP_form "OPTIONS BORDER CENTER\n")
            (fprintf DTOP_form "ENDTEXT\n")
            (fprintf DTOP_form "\n")
            (fprintf DTOP_form "TEXT \"message\" TxtSite3\n")
            (fprintf DTOP_form "FLOC 14 5\n")
            (fprintf DTOP_form "FSIZE 52 2\n")
            (fprintf DTOP_form "OPTIONS BORDER\n")
            (fprintf DTOP_form "ENDTEXT\n")
            (fprintf DTOP_form "\n")
            ; USER Info Text
            (fprintf DTOP_form "TEXT \"USER\" TxtUser0\n")
            (fprintf DTOP_form "FLOC 1 8\n")
            (fprintf DTOP_form "FSIZE 6 2\n")
            (fprintf DTOP_form "OPTIONS BORDER CENTER BOLD\n")
            (fprintf DTOP_form "ENDTEXT\n")
            (fprintf DTOP_form "\n")
            (fprintf DTOP_form "TEXT \"message\" TxtUser1\n")
            (fprintf DTOP_form "FLOC 8 8\n")
            (fprintf DTOP_form "FSIZE 58 4\n")
            (fprintf DTOP_form "OPTIONS BORDER\n")
            (fprintf DTOP_form "ENDTEXT\n")
            (fprintf DTOP_form "\n")
            (fprintf DTOP_form "TEXT \"user:\" TxtUser2\n")
            (fprintf DTOP_form "FLOC 8 11\n")
            (fprintf DTOP_form "FSIZE 6 2\n")
            (fprintf DTOP_form "OPTIONS BORDER CENTER\n")
            (fprintf DTOP_form "ENDTEXT\n")
            (fprintf DTOP_form "\n")
            (fprintf DTOP_form "TEXT \"message\" TxtUser3\n")
            (fprintf DTOP_form "FLOC 14 11\n")
            (fprintf DTOP_form "FSIZE 52 2\n")
            (fprintf DTOP_form "OPTIONS BORDER\n")
            (fprintf DTOP_form "ENDTEXT\n")
            (fprintf DTOP_form "\n")
            ; FILE Info Text
            (fprintf DTOP_form "TEXT \"FILE\" TxtFile0\n")
            (fprintf DTOP_form "FLOC 1 14\n")
            (fprintf DTOP_form "FSIZE 6 2\n")
            (fprintf DTOP_form "OPTIONS BORDER CENTER BOLD\n")
            (fprintf DTOP_form "ENDTEXT\n")
            (fprintf DTOP_form "\n")
            (fprintf DTOP_form "TEXT \"message\" TxtFile1\n")
            (fprintf DTOP_form "FLOC 8 14\n")
            (fprintf DTOP_form "FSIZE 58 4\n")
            (fprintf DTOP_form "OPTIONS BORDER\n")
            (fprintf DTOP_form "ENDTEXT\n")
            (fprintf DTOP_form "\n")
            (fprintf DTOP_form "TEXT \"file:\" TxtFile2\n")
            (fprintf DTOP_form "FLOC 8 17\n")
            (fprintf DTOP_form "FSIZE 6 2\n")
            (fprintf DTOP_form "OPTIONS BORDER CENTER\n")
            (fprintf DTOP_form "ENDTEXT\n")
            (fprintf DTOP_form "\n")
            (fprintf DTOP_form "TEXT \"message\" TxtFile3\n")
            (fprintf DTOP_form "FLOC 14 17\n")
            (fprintf DTOP_form "FSIZE 52 2\n")
            (fprintf DTOP_form "OPTIONS BORDER\n")
            (fprintf DTOP_form "ENDTEXT\n")
            (fprintf DTOP_form "\n")
            ;start set site group
            (fprintf DTOP_form "GROUP \"Please Choose Your SITE Configuration Policy\" SiteSettingsGroup\n")
            (fprintf DTOP_form "FLOC 1 19\n")
            (fprintf DTOP_form "FSIZE 65 14\n")
            (fprintf DTOP_form "\n")
              ;set site check/radio none
              (fprintf DTOP_form "FIELD SiteSetRaidoNone\n")
              (fprintf DTOP_form "FLOC 2 21\n")
              (fprintf DTOP_form "CHECKLIST \"Do Not Use SITE Configuration\" \"SiteRadioSet\"\n")
              (fprintf DTOP_form "ENDFIELD\n")
              (fprintf DTOP_form "\n")
              ;set site check/radio used
              (fprintf DTOP_form "FIELD SiteSetRaidoUsed\n")
              (fprintf DTOP_form "FLOC 2 23\n")
              (fprintf DTOP_form "CHECKLIST \"Use SITE Configuration (On Permission Errors See QuickHelp)\" \"SiteRadioSet\"\n")
              (fprintf DTOP_form "ENDFIELD\n")
              (fprintf DTOP_form "\n")
              ;set site fillin field
              (fprintf DTOP_form "FIELD SiteFillin\n")
              (fprintf DTOP_form "FLOC 3 25\n")
              (fprintf DTOP_form "STRFILLIN 50 256\n")
              (fprintf DTOP_form "VALUE 0\n")
              (fprintf DTOP_form "OPTIONS INFO_ONLY\n")
              (fprintf DTOP_form "ENDFIELD\n")
              (fprintf DTOP_form "\n")
              ;set site directory browse button
              (fprintf DTOP_form "FIELD SiteButtonBrowse\n")
              (fprintf DTOP_form "FLOC 55 25\n")
              (fprintf DTOP_form "MENUBUTTON \"Browse\" 10 3\n")
              (fprintf DTOP_form "ENDFIELD\n")
              (fprintf DTOP_form "\n")
              ;set site promote settings
              (fprintf DTOP_form "TEXT \"message\" TxtPromote\n")
              (fprintf DTOP_form "FLOC 3 28\n")
              (fprintf DTOP_form "FSIZE 51 5\n")
              (fprintf DTOP_form "OPTIONS BORDER\n")
              (fprintf DTOP_form "ENDTEXT\n")
              (fprintf DTOP_form "\n")
              ;set site directory browse button
              (fprintf DTOP_form "FIELD SiteButtonPromote\n")
              (fprintf DTOP_form "FLOC 55 29\n")
              (fprintf DTOP_form "MENUBUTTON \"Promote\" 10 3\n")
              (fprintf DTOP_form "ENDFIELD\n")
              (fprintf DTOP_form "\n")
            ;end of set site group
            (fprintf DTOP_form "ENDGROUP\n")
            (fprintf DTOP_form "\n")
          ;end site configuration tab
          (fprintf DTOP_form "ENDTAB\n")
          (fprintf DTOP_form "\n")
          ;start Contact Configuration Tab
          (fprintf DTOP_form "TAB \"Contact Configuration\"\n")
          (fprintf DTOP_form "\n")
            ;start Company Info Group
            (fprintf DTOP_form "GROUP \"Company Contact Information\" SettingsPlaceGroup\n")
            (fprintf DTOP_form "FLOC 0 0\n")
            (fprintf DTOP_form "FSIZE 66 15\n")
            (fprintf DTOP_form "\n")
              ;company name
              (fprintf DTOP_form "TEXT \"Company Name.:\" ContactCompanyTxt00\n")
              (fprintf DTOP_form "FLOC 1 2\n")
              (fprintf DTOP_form "FSIZE 14 2\n")
              (fprintf DTOP_form "ENDTEXT\n")
              (fprintf DTOP_form "FIELD ContactCompanyName\n")
              (fprintf DTOP_form "FLOC 15 2\n")
              (fprintf DTOP_form "STRFILLIN 49 128\n")
              (fprintf DTOP_form "ENDFIELD\n")
              (fprintf DTOP_form "\n")
              ;company street
              (fprintf DTOP_form "TEXT \"Street.......:\" ContactCompanyTxt00\n")
              (fprintf DTOP_form "FLOC 1 4\n")
              (fprintf DTOP_form "FSIZE 14 2\n")
              (fprintf DTOP_form "ENDTEXT\n")
              (fprintf DTOP_form "FIELD ContactCompanyStreet\n")
              (fprintf DTOP_form "FLOC 15 4\n")
              (fprintf DTOP_form "STRFILLIN 49 128\n")
              (fprintf DTOP_form "ENDFIELD\n")
              (fprintf DTOP_form "\n")
              ;company city
              (fprintf DTOP_form "TEXT \"City.........:\" ContactCompanyTxt00\n")
              (fprintf DTOP_form "FLOC 1 6\n")
              (fprintf DTOP_form "FSIZE 14 2\n")
              (fprintf DTOP_form "ENDTEXT\n")
              (fprintf DTOP_form "FIELD ContactCompanyCity\n")
              (fprintf DTOP_form "FLOC 15 6\n")
              (fprintf DTOP_form "STRFILLIN 49 128\n")
              (fprintf DTOP_form "ENDFIELD\n")
              (fprintf DTOP_form "\n")
              ;companystate/Provence
              (fprintf DTOP_form "TEXT \"State/Prov...:\" ContactCompanyTxt00\n")
              (fprintf DTOP_form "FLOC 1 8\n")
              (fprintf DTOP_form "FSIZE 14 2\n")
              (fprintf DTOP_form "ENDTEXT\n")
              (fprintf DTOP_form "FIELD ContactCompanyState\n")
              (fprintf DTOP_form "FLOC 15 8\n")
              (fprintf DTOP_form "STRFILLIN 16 128\n")
              (fprintf DTOP_form "ENDFIELD\n")
              (fprintf DTOP_form "\n")
              ;company postal Code
              (fprintf DTOP_form "TEXT \"Postal Code..:\" ContactCompanyTxt00\n")
              (fprintf DTOP_form "FLOC 1 10\n")
              (fprintf DTOP_form "FSIZE 14 2\n")
              (fprintf DTOP_form "ENDTEXT\n")
              (fprintf DTOP_form "FIELD ContactCompanyCode\n")
              (fprintf DTOP_form "FLOC 15 10\n")
              (fprintf DTOP_form "STRFILLIN 16 128\n")
              (fprintf DTOP_form "ENDFIELD\n")
              (fprintf DTOP_form "\n")
              ;company country
              (fprintf DTOP_form "TEXT \"Country......:\" ContactCompanyTxt00\n")
              (fprintf DTOP_form "FLOC 1 12\n")
              (fprintf DTOP_form "FSIZE 14 2\n")
              (fprintf DTOP_form "ENDTEXT\n")
              (fprintf DTOP_form "FIELD ContactCompanyCountry\n")
              (fprintf DTOP_form "FLOC 15 12\n")
              (fprintf DTOP_form "STRFILLIN 16 128\n")
              (fprintf DTOP_form "ENDFIELD\n")
              (fprintf DTOP_form "\n")
              ;company web
              (fprintf DTOP_form "TEXT \"Web Site.....:\" ContactCompanyTxt00\n")
              (fprintf DTOP_form "FLOC 34 8\n")
              (fprintf DTOP_form "FSIZE 14 2\n")
              (fprintf DTOP_form "ENDTEXT\n")
              (fprintf DTOP_form "FIELD ContactCompanyWeb\n")
              (fprintf DTOP_form "FLOC 48 8\n")
              (fprintf DTOP_form "STRFILLIN 16 128\n")
              (fprintf DTOP_form "ENDFIELD\n")
              (fprintf DTOP_form "\n")
              ;company phone
              (fprintf DTOP_form "TEXT \"Telephone....:\" ContactCompanyTxt00\n")
              (fprintf DTOP_form "FLOC 34 10\n")
              (fprintf DTOP_form "FSIZE 14 2\n")
              (fprintf DTOP_form "ENDTEXT\n")
              (fprintf DTOP_form "FIELD ContactCompanyPhone\n")
              (fprintf DTOP_form "FLOC 48 10\n")
              (fprintf DTOP_form "STRFILLIN 16 128\n")
              (fprintf DTOP_form "ENDFIELD\n")
              (fprintf DTOP_form "\n")
              ;company fax
              (fprintf DTOP_form "TEXT \"FAX Number...:\" ContactCompanyTxt00\n")
              (fprintf DTOP_form "FLOC 34 12\n")
              (fprintf DTOP_form "FSIZE 14 2\n")
              (fprintf DTOP_form "ENDTEXT\n")
              (fprintf DTOP_form "FIELD ContactCompanyFax\n")
              (fprintf DTOP_form "FLOC 48 12\n")
              (fprintf DTOP_form "STRFILLIN 16 128\n")
              (fprintf DTOP_form "ENDFIELD\n")
              (fprintf DTOP_form "\n")
            ;end Company Info Group
            (fprintf DTOP_form "ENDGROUP\n")
            (fprintf DTOP_form "\n")
            ;start Designer Group
            (fprintf DTOP_form "GROUP \"Designer Contact Information\" SettingsPlaceGroup\n")
            (fprintf DTOP_form "FLOC 0 15\n")
            (fprintf DTOP_form "FSIZE 66 9\n")
            (fprintf DTOP_form "\n")
              ;Designer name
              (fprintf DTOP_form "TEXT \"Designer Name:\" ContactCompanyTxt00\n")
              (fprintf DTOP_form "FLOC 1 17\n")
              (fprintf DTOP_form "FSIZE 14 2\n")
              (fprintf DTOP_form "ENDTEXT\n")
              (fprintf DTOP_form "FIELD ContactDesignerName\n")
              (fprintf DTOP_form "FLOC 15 17\n")
              (fprintf DTOP_form "STRFILLIN 49 128\n")
              (fprintf DTOP_form "ENDFIELD\n")
              (fprintf DTOP_form "\n")
              ;Designer desk phone
              (fprintf DTOP_form "TEXT \"Main Phone...:\" ContactCompanyTxt00\n")
              (fprintf DTOP_form "FLOC 1 19\n")
              (fprintf DTOP_form "FSIZE 14 2\n")
              (fprintf DTOP_form "ENDTEXT\n")
              (fprintf DTOP_form "FIELD ContactDesignerMainPhone\n")
              (fprintf DTOP_form "FLOC 15 19\n")
              (fprintf DTOP_form "STRFILLIN 16 128\n")
              (fprintf DTOP_form "ENDFIELD\n")
              (fprintf DTOP_form "\n")
              ;Designer desk email
              (fprintf DTOP_form "TEXT \"Main Email...:\" ContactCompanyTxt00\n")
              (fprintf DTOP_form "FLOC 1 21\n")
              (fprintf DTOP_form "FSIZE 14 2\n")
              (fprintf DTOP_form "ENDTEXT\n")
              (fprintf DTOP_form "FIELD ContactDesignerMainEmail\n")
              (fprintf DTOP_form "FLOC 15 21\n")
              (fprintf DTOP_form "STRFILLIN 16 128\n")
              (fprintf DTOP_form "ENDFIELD\n")
              (fprintf DTOP_form "\n")
              ;Designer mobile phone
              (fprintf DTOP_form "TEXT \"Mobile Phone.:\" ContactCompanyTxt00\n")
              (fprintf DTOP_form "FLOC 34 19\n")
              (fprintf DTOP_form "FSIZE 14 2\n")
              (fprintf DTOP_form "ENDTEXT\n")
              (fprintf DTOP_form "FIELD ContactDesignerMobilePhone\n")
              (fprintf DTOP_form "FLOC 48 19\n")
              (fprintf DTOP_form "STRFILLIN 16 128\n")
              (fprintf DTOP_form "ENDFIELD\n")
              (fprintf DTOP_form "\n")
              ;Designer mobile email
              (fprintf DTOP_form "TEXT \"Mobile Email.:\" ContactCompanyTxt00\n")
              (fprintf DTOP_form "FLOC 34 21\n")
              (fprintf DTOP_form "FSIZE 14 2\n")
              (fprintf DTOP_form "ENDTEXT\n")
              (fprintf DTOP_form "FIELD ContactDesignerMobileEmail\n")
              (fprintf DTOP_form "FLOC 48 21\n")
              (fprintf DTOP_form "STRFILLIN 16 128\n")
              (fprintf DTOP_form "ENDFIELD\n")
              (fprintf DTOP_form "\n")
            ;end Designer Info Group
            (fprintf DTOP_form "ENDGROUP\n")
            (fprintf DTOP_form "\n")
            ;start Sales Group
            (fprintf DTOP_form "GROUP \"Sales Contact Information\" SettingsPlaceGroup\n")
            (fprintf DTOP_form "FLOC 0 24\n")
            (fprintf DTOP_form "FSIZE 66 9\n")
            (fprintf DTOP_form "\n")
              ;sales name
              (fprintf DTOP_form "TEXT \"Sales Name...:\" ContactCompanyTxt00\n")
              (fprintf DTOP_form "FLOC 1 26\n")
              (fprintf DTOP_form "FSIZE 14 2\n")
              (fprintf DTOP_form "ENDTEXT\n")
              (fprintf DTOP_form "FIELD ContactSalesName\n")
              (fprintf DTOP_form "FLOC 15 26\n")
              (fprintf DTOP_form "STRFILLIN 49 128\n")
              (fprintf DTOP_form "ENDFIELD\n")
              (fprintf DTOP_form "\n")
              ;sales desk phone
              (fprintf DTOP_form "TEXT \"Main Phone...:\" ContactCompanyTxt00\n")
              (fprintf DTOP_form "FLOC 1 28\n")
              (fprintf DTOP_form "FSIZE 14 2\n")
              (fprintf DTOP_form "ENDTEXT\n")
              (fprintf DTOP_form "FIELD ContactSalesMainPhone\n")
              (fprintf DTOP_form "FLOC 15 28\n")
              (fprintf DTOP_form "STRFILLIN 16 128\n")
              (fprintf DTOP_form "ENDFIELD\n")
              (fprintf DTOP_form "\n")
              ;sales desk email
              (fprintf DTOP_form "TEXT \"Main Email...:\" ContactCompanyTxt00\n")
              (fprintf DTOP_form "FLOC 1 30\n")
              (fprintf DTOP_form "FSIZE 14 2\n")
              (fprintf DTOP_form "ENDTEXT\n")
              (fprintf DTOP_form "FIELD ContactSalesMainEmail\n")
              (fprintf DTOP_form "FLOC 15 30\n")
              (fprintf DTOP_form "STRFILLIN 16 128\n")
              (fprintf DTOP_form "ENDFIELD\n")
              (fprintf DTOP_form "\n")
              ;sales mobile phone
              (fprintf DTOP_form "TEXT \"Mobile Phone.:\" ContactCompanyTxt00\n")
              (fprintf DTOP_form "FLOC 34 28\n")
              (fprintf DTOP_form "FSIZE 14 2\n")
              (fprintf DTOP_form "ENDTEXT\n")
              (fprintf DTOP_form "FIELD ContactSalesMobilePhone\n")
              (fprintf DTOP_form "FLOC 48 28\n")
              (fprintf DTOP_form "STRFILLIN 16 128\n")
              (fprintf DTOP_form "ENDFIELD\n")
              (fprintf DTOP_form "\n")
              ;sales mobile email
              (fprintf DTOP_form "TEXT \"Mobile Email.:\" ContactCompanyTxt00\n")
              (fprintf DTOP_form "FLOC 34 30\n")
              (fprintf DTOP_form "FSIZE 14 2\n")
              (fprintf DTOP_form "ENDTEXT\n")
              (fprintf DTOP_form "FIELD ContactSalesMobileEmail\n")
              (fprintf DTOP_form "FLOC 48 30\n")
              (fprintf DTOP_form "STRFILLIN 16 128\n")
              (fprintf DTOP_form "ENDFIELD\n")
              (fprintf DTOP_form "\n")
            ;end Sales Info Group
            (fprintf DTOP_form "ENDGROUP\n")
            (fprintf DTOP_form "\n")
          ;end Contact configuration tab
          (fprintf DTOP_form "ENDTAB\n")
          (fprintf DTOP_form "\n")

          ; start QuickHelp Tab
          (fprintf DTOP_form "TAB \"QuickHelp\"\n")
          (fprintf DTOP_form "\n")
            ;start QuickHelp text messages
            (fprintf DTOP_form "FIELD QHTxtMessage0\n")
            (fprintf DTOP_form "FLOC 0 0\n")
            (fprintf DTOP_form "LIST \"\" 66 17\n")
            (fprintf DTOP_form "OPTIONS INFO_ONLY\n")
            (fprintf DTOP_form "ENDTEXT\n")
            (fprintf DTOP_form "\n")
          ;end quickhelp tab
          (fprintf DTOP_form "ENDTAB\n")
          (fprintf DTOP_form "\n")
        ;end of tab set
        (fprintf DTOP_form "ENDTABSET\n")
        ;main form body
        ;online help
        (fprintf DTOP_form "FIELD HelpButtonOnLine\n")
        (fprintf DTOP_form "FLOC 1 36\n")
        (fprintf DTOP_form "MENUBUTTON \"On-Line Help\" 15 3\n")
        (fprintf DTOP_form "ENDFIELD\n")
        (fprintf DTOP_form "\n")
        ;local help
;        (fprintf DTOP_form "FIELD HelpButtonLocal\n")
;        (fprintf DTOP_form "FLOC 17 36\n")
;        (fprintf DTOP_form "MENUBUTTON \"Local Help\" 15 3\n")
;        (fprintf DTOP_form "ENDFIELD\n")
;        (fprintf DTOP_form "\n")
        ;ok button
        (fprintf DTOP_form "FIELD OpOKButton\n")
        (fprintf DTOP_form "FLOC 46 36\n")
        (fprintf DTOP_form "MENUBUTTON \"OK\" 9 3\n")
        (fprintf DTOP_form "ENDFIELD\n")
        (fprintf DTOP_form "\n")
        ;cancel button
        (fprintf DTOP_form "FIELD OpCancelButton\n")
        (fprintf DTOP_form "FLOC 57 36\n")
        (fprintf DTOP_form "MENUBUTTON \"Cancel\" 9 3\n")
        (fprintf DTOP_form "ENDFIELD\n")
        (fprintf DTOP_form "\n")
        ;ending
        (fprintf DTOP_form "ENDTILE\n")
        (fprintf DTOP_form "\n")
        (fprintf DTOP_form "ENDFORM\n")
    )
    (when DTD
      (fprintf DTOP_log "\nERROR: %s - Failed On Form File Writing\n" DTP))
    (printf           "\nERROR: %s - Failed On Form File Writing\n" DTP)
    (return nil))
  (if (and (boundp 'DTOP_form) (openportp DTOP_form))
  then
    (unless (and (drain DTOP_form) (close DTOP_form))
      (printf "\nERROR: %s - File close failed on Form File\n" DTP))
  else
    (printf "\nERROR: %s - Form File port unbound or port not open\n" DTP))
;  (setq DTOP_form 'unbound)

  ; create blocking form
  (setq FormSym (axlFormCreate (gensym) ArgFormFileName
      '( "msglines" 0 "E" "inner" "NoBorder") 'DT_config_form_cb nil))

  (return FormSym)
));END_LET_&_PROCEDURE (DT_config_form_create)
