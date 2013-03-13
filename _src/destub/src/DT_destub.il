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

;_______________________________________________________________________________
;-------------------------------------------------------------------------------
; TODO:
;
; Research situations where a PATH has no NET. -Should result in a bad branch.
;
; Add IGNORE_FILLET and use it as a default because they drastically increase
; processing time.
;
;   There is a FILLET property someplace which might be usable.
;
;-------------------------------------------------------------------------------

;*******************************************************************************
; Register the callable command(s)
;
(axlCmdRegister "DT_destub_main", "DT_destub_main")

;*******************************************************************************
; defstruct psym  -Data Type for holding all the needed info on a per item
; basis.
;
;      dbid      list of DBID objects (it's a list because of chains)
;      ndex      int holding the current row numer in the grid for this object(s)
;      prop      list of relevant properties on this object(s)
;      lays      list of layers used by this object(s)
;      tree      list of tree items associated with this object
;      nets      text net associated with this object
;      yval      float Y-Axis value for the center of this object or group of objects
;      xval      float X-Axis value for the center of this object or group of objects
;      otyp      text Object Type (chain, net, branch, path, pin, shape, tee, via)
;      chck      boolean/general "is selected" check mark
;      kids      list of child pSym's
;      pars      list of parent tree items
;      chld      list of child DBID's (including good objects)
(defstruct psym dbid ndex prop lays tree item nets yval xval otyp chck kids pars chld)

;*******************************************************************************
;
(procedure (DT_destub_main)
(prog (
    DMSG OrigSettings OrigRatsNest OrigDRCState OrigActiveLayer
    LogsFileName DbugFileName FormFileName BmapFileName LogsFH DbugFH
    RG_x_IMG_SELECT RG_x_IMG_NORMAL RG_x_IMG_YELLOW RG_x_IMG_GRAYED
    RG_x_IMG_C_NORM RG_x_IMG_O_NORM RG_x_IMG_C_HALF RG_x_IMG_O_HALF
    RG_x_IMG_C_FULL RG_x_IMG_O_FULL RGsl_ITEM_GOOD RGsl_ITEM_BAD
    RG_b_DEL_FILES RGls_FULL_LIST RG_x_FULL_ROWS RGld_LITE_OBJS
    RG_d_LITE_RATS RG_b_REST_ZOOM RGls_SHOW_LIST RG_x_SHOW_ROWS
    RG_x_GROUP_THIS RG_x_GROUP_START RG_x_GROUP_ADD RG_x_GROUP_END
    RGlx_GROUP_LIST RGlt_LAYS_LIST RGlt_PROP_LIST
    RG_t_BMP_FILE_TREESET RG_x_COL_SORT RGsl_BAD_VIA
    RGsl_BAD_SHAPE RGsl_BAD_PATH RGsl_BAD_PIN RGsl_BAD_BRANCH
    RGsl_BAD_NET RGsl_BAD_CHAIN RG_g_FORM
    RG_t_LINE1 RG_t_LINE2 RG_t_LINE3 RG_BITMAP_LIST
    DTD
    DTN
    DTV
    RG_t_HelpProgram
    RG_t_HelpVersion
    RG_t_HelpAuthors
    RG_t_HelpContact
    RG_t_HelpURLonline
    RG_t_HelpURLlocal
    RG_t_BMP_PATH
    RG_t_BMP_FILE_TREESET
    RG_t_BMP_FILE_DOT_BLU
    RG_t_BMP_FILE_DOT_GRN
    RG_t_BMP_FILE_DOT_RED
    RG_t_BMP_FILE_DOT_YEL
    RG_t_BMP_FILE_FLD_GRN
    RG_t_BMP_FILE_FLD_HLF
    RG_t_BMP_FILE_FLD_RED
    RG_t_BMP_FILE_FLD_YEL

  )

  (setq DTD nil)
  (setq DTV "DT-destub-v1.1")
  (setq DTN "(DT_destub_main)")
  (when DTD (printf "\nSTATUS: %s \n" DTN))
  (setq DMSG nil)           ; Debug MESage switch
;  (when DMSG (axlDebug t))  ; The "debug mode" with extended warnings (v15.2)

  (setq RG_t_HelpProgram  " The Destubifier")
  (setq RG_t_HelpVersion  " 1.0.0")
  (setq RG_t_HelpAuthors  " J.C. Roberts")
  (setq RG_t_HelpContact  " True (@) DigitalLove.org")
  (setq RG_t_HelpCredits  " Please See Website")

  ; set the documentation URLs
  (setq RG_t_HelpURLlocal
      (strcat "file://localhost/"
          (axlGetVariable "designtools") "/destub/man/index.html"))
  (setq RG_t_HelpURLonline 
      (strcat "http://www.DesignTools.org/programs/cadence/pcb-editor/destubifier/docs.php?"
          DTV))

;__FIXME__ Does not need to be global
  (setq RG_BITMAP_LIST nil)     ; List of loaded bitmap images (as int)

  ; Set Globals
  (setq RG_x_IMG_SELECT nil)      ; Red "X" Image           (Selected)
  (setq RG_x_IMG_NORMAL nil)      ; Green Circle Image      (Normal -not selected)
  (setq RG_x_IMG_YELLOW nil)      ; Yellow "X" image        (not sure yet)
  (setq RG_x_IMG_GRAYED nil)      ; Gray "X" image          (disabled)
  (setq RG_x_IMG_C_NORM nil)      ; folder closed           (none marked selected)
  (setq RG_x_IMG_O_NORM nil)      ; folder open             (none marked selected)
  (setq RG_x_IMG_C_HALF nil)      ; folder closed half red  (some marked selected)
  (setq RG_x_IMG_O_HALF nil)      ; folder open half red    (some marked selected)
  (setq RG_x_IMG_C_FULL nil)      ; folder closed full red  (all marked selected)
  (setq RG_x_IMG_O_FULL nil)      ; folder open full red    (all marked selected)

  (setq RG_x_IMG_REDD_DOT_O nil)   ; Red   Dot "Select"
  (setq RG_x_IMG_REDD_DOT_X nil)   ; Red   Dot "Select-X"   (not listed)
  (setq RG_x_IMG_GREN_DOT_O nil)   ; Green Dot "NotSel"
  (setq RG_x_IMG_GREN_DOT_X nil)   ; Green Dot "NotSel-X"   (not listed)
  (setq RG_x_IMG_YELL_DOT_O nil)   ; Gray  Dot "Disabled"
  (setq RG_x_IMG_YELL_DOT_X nil)   ; Gray  Dot "Disabled-X" (not listed)
  (setq RG_x_IMG_NORM_FCL_O nil)   ; Normal   Folder Closed
  (setq RG_x_IMG_NORM_FOP_O nil)   ; Normal   Folder Open
  (setq RG_x_IMG_REDF_FCL_O nil)   ; FullRed  Folder Closed
  (setq RG_x_IMG_REDF_FOP_O nil)   ; FullRed  Folder Open
  (setq RG_x_IMG_REDH_FCL_O nil)   ; HalfRed  Folder Closed
  (setq RG_x_IMG_REDH_FOP_O nil)   ; HalfRed  Folder Open
  (setq RG_x_IMG_GREN_FCL_O nil)   ; Green    Folder Closed
  (setq RG_x_IMG_GREN_FOP_O nil)   ; Green    Folder Open
  (setq RG_x_IMG_GREN_FCL_X nil)   ; Green    Folder Closed-X (not listed)
  (setq RG_x_IMG_GREN_FOP_X nil)   ; Green    Folder Open-X   (not listed)
  (setq RG_x_IMG_REDF_FCL_X nil)   ; FullRed  Folder Closed-X (not listed)
  (setq RG_x_IMG_REDF_FOP_X nil)   ; FullRed  Folder Open-X   (not listed)
  (setq RG_x_IMG_REDH_FCL_X nil)   ; HalfRed  Folder Closed-X (not listed)
  (setq RG_x_IMG_REDH_FOP_X nil)   ; HalfRed  Folder Open-X   (not listed)

  (setq RGsl_ITEM_GOOD nil)       ; Ass List of net/branch children not found bad TreeItem/pSym
  (setq RGsl_ITEM_BAD nil)       ; Ass List of bad object TreeItem/pSym
  (setq RGsl_ITEM_SKIP nil)

  (setq RGls_FULL_LIST nil)       ; full list of bad objects
  (setq RG_x_FULL_ROWS 0)         ; count of bad objects
  (setq RGls_SHOW_LIST nil)       ; list of objects shown in grid
  (setq RG_x_SHOW_ROWS 0)         ; count of objects shown in grid
  (setq RGld_LITE_OBJS nil)       ; list of objects to highlight/unhighlight
  (setq RGld_LITE_NETS nil)       ; list of nets to highlight/unhighlight
  (setq RG_d_LITE_RATS nil)       ; list of nets to highlight/unhighlight
  (setq RGlt_LITE_LAYS nil)       ; list of layers made visible
  (setq RGlx_LITE_TREE nil)       ; list of tree item images in hilight mode

  (setq RG_b_REST_ZOOM t)         ; restore original zoom on exit
  (setq RG_x_GROUP_THIS nil)      ; the current row selected in the grid
  (setq RG_x_GROUP_START nil)     ; starting temp group row number (int)
  (setq RG_x_GROUP_ADD nil)       ; row number to add to temp group (int)
  (setq RG_x_GROUP_END nil)       ; ending temp group row number (int)
  (setq RGlx_GROUP_LIST nil)      ; list of row numbers (int) in temp group

  (setq RGlt_LAYS_LIST (axlGetParam "paramLayerGroup:ETCH")->groupMembers)
  (setq RGlt_PROP_LIST (list "DT_FANOUT" "DT_IGNORE"))
  (setq RGlt_NETS_LIST nil)       ;list of strings of net names for filtering

  (setq RGtt_ZOOM (makeTable "zoom" 100))
  RGtt_ZOOM["chain"]  =  500
  RGtt_ZOOM["net"]    =  110
  RGtt_ZOOM["branch"] =  500
  RGtt_ZOOM["path"]   = 1000
  RGtt_ZOOM["pin"]    = 2000
  RGtt_ZOOM["shape"]  = 1000
  RGtt_ZOOM["tee"]    =  500
  RGtt_ZOOM["via"]    = 2500

  (setq RG_x_COL_SORT nil)        ; Column Sorting Popup Trigger

  (setq RGsl_BAD_VIA nil)         ; Association List of Bad Vias
  (setq RGsl_BAD_SHAPE nil)       ; Association List of Bad Shapes
  (setq RGsl_BAD_PATH nil)        ; Association List of Bad Paths
  (setq RGsl_BAD_PIN nil)         ; Association List of Bad Pins
  (setq RGsl_BAD_BRANCH nil)      ; Association List of Bad Branches
  (setq RGsl_BAD_NET nil)         ; Association List of Bad Nets
  (setq RGsl_BAD_CHAIN nil)       ; Association List of Bad Chains
  (setq RGsl_BAD_END nil)         ; Association List of Bad Chains End Points

  (setq RG_g_FORM nil)                   ; Form Handle
  (setq RG_t_LINE1 "________________________________________________________________________________")
  (setq RG_t_LINE2 "********************************************************************************")
  (setq RG_t_LINE3 "--------------------------------------------------------------------------------")

  ; set file name variables
  (unless (setq LogsFileName "DT_destub.log")
    (printf "\n\nERROR: destub_main() - Can Not set LogsFileName Variable\n\n")
    (return nil))
  (unless (setq DbugFileName "DT_destub.dbg")
    (printf "\n\nERROR: destub_main() - Can Not set DbugFileName Variable\n\n")
    (return nil))
  (unless (setq FormFileName "DT_destub.form")
    (printf "\n\nERROR: destub_main() - Can Not set FormFileName Variable\n\n")
    (return nil))
  ; open debug and logging files
  (unless (setq DbugFH (outfile DbugFileName))
    (printf "\n\nERROR: destub_main() - Can Not Open Debug Output File!\n\n")
    (return nil))
  (unless (setq LogsFH (outfile LogsFileName))
    (fprintf DbugFH "\nERROR: destub_main() - Can Not Open Log Output File!\n")
    (return nil))
  ; check that the currently open file is a board file
  (unless (_DTL_UTILS_FileTypeCheck "board")
    (fprintf DbugFH "\nERROR: destub_main() - Wrong File Type (not a board file)\n")
    (return nil))

  (setq RG_b_DEL_FILES t)       ; delete working and debug files?

;__FIXME__ -need error checks
  ; save original settings for Find, Select, Visibility, Rats and etc.
  (setq OrigSettings _DTL_UTILS_SettingsGet())
  (setq OrigRatsNest (axlDBControl 'ratsnestDistance))
  (setq OrigBmapPath (axlGetVariable "bmppath"))
  (setq OrigActiveLayer (axlDBControl 'activeLayer))
;  (setq OrigDRCState (axlDBControl 'drcEnable))
  (fprintf LogsFH "DesignTools Destubifier Logging\n")

  ; set up visibility...
  (axlDBControl 'ratsnestDistance nil)      ; set ratsnest to end of dangling line
;  (axlDBControl 'drcEnable t)               ; trun on DRC's
  (axlVisibleLayer "ETCH" nil)
  (axlVisibleLayer "DRC ERROR CLASS" nil)
  (axlVisibleLayer "PIN" t)
  (axlVisibleUpdate t)
  (axlShell "shadow 40")             ; darken all layers
  ; add the DesignTools/destub/src path to the bitmap path so we can load the image file.
  (axlSetVariable "bmppath" (strcat (strcat 
      (axlGetVariable "designtools") "/destub/src ") OrigBmapPath))

;  ; This is what *SHOULD* be all that is necessary, namely just the file name
;  ; of the bitmap we want to use and having previously modified the 
;  ; AllegroVar "bmppath" -Works fine in 15.2.x but breaks in 15.5.0
;  (setq RG_t_BMP_FILE_TREESET "DT_destub_treeset.bmp")
;  (setq RG_t_BMP_FILE_DOT_BLU "DT_destub_dot_blu.bmp")
;  (setq RG_t_BMP_FILE_DOT_GRN "DT_destub_dot_grn.bmp")
;  (setq RG_t_BMP_FILE_DOT_RED "DT_destub_dot_red.bmp")
;  (setq RG_t_BMP_FILE_DOT_YEL "DT_destub_dot_yel.bmp")
;  (setq RG_t_BMP_FILE_FLD_GRN "DT_destub_fld_grn.bmp")
;  (setq RG_t_BMP_FILE_FLD_HLF "DT_destub_fld_hlf.bmp")
;  (setq RG_t_BMP_FILE_FLD_RED "DT_destub_fld_red.bmp")
;  (setq RG_t_BMP_FILE_FLD_YEL "DT_destub_fld_yel.bmp")

;NOFIX
  ; This is the work-around for the above problem, namely giving full path/file
  ; strings to Allegro so it can find the files. This may or may not become a
  ; pain latter when building contextes.
  (setq RG_t_BMP_PATH (strcat (axlGetVariable "designtools") "/destub/src/"))
  (setq RG_t_BMP_FILE_TREESET (strcat RG_t_BMP_PATH "DT_destub_treeset.bmp"))
  (setq RG_t_BMP_FILE_DOT_BLU (strcat RG_t_BMP_PATH "DT_destub_dot_blu.bmp"))
  (setq RG_t_BMP_FILE_DOT_GRN (strcat RG_t_BMP_PATH "DT_destub_dot_grn.bmp"))
  (setq RG_t_BMP_FILE_DOT_RED (strcat RG_t_BMP_PATH "DT_destub_dot_red.bmp"))
  (setq RG_t_BMP_FILE_DOT_YEL (strcat RG_t_BMP_PATH "DT_destub_dot_yel.bmp"))
  (setq RG_t_BMP_FILE_FLD_GRN (strcat RG_t_BMP_PATH "DT_destub_fld_grn.bmp"))
  (setq RG_t_BMP_FILE_FLD_HLF (strcat RG_t_BMP_PATH "DT_destub_fld_hlf.bmp"))
  (setq RG_t_BMP_FILE_FLD_RED (strcat RG_t_BMP_PATH "DT_destub_fld_red.bmp"))
  (setq RG_t_BMP_FILE_FLD_YEL (strcat RG_t_BMP_PATH "DT_destub_fld_yel.bmp"))



  ;--------------------------------------------------------------------------------
  ; non-blocking...
;  (when (setq RG_g_FORM (DT_destub_form_write FormFileName))
;    (DT_destub_form_enable nil nil)
;    (axlFormDisplay RG_g_FORM)
;    (axlUIWExpose RG_g_FORM)
;    (DT_destub_init)
;    (DT_destub_form_enable t t)
;  )

  (setq RG_g_FORM (DT_destub_form_write FormFileName))
  (DT_destub_init)
  (DT_destub_form_enable t t)
  (axlFormDisplay RG_g_FORM)

  ; make sure we don't leave anything highlighted
  (if RGld_LITE_OBJS (axlDehighlightObject RGld_LITE_OBJS nil)) ;uses "temp" color
  (if RGld_LITE_NETS (axlDehighlightObject RGld_LITE_NETS t))   ;uses "perm" color
  (if RG_d_LITE_RATS (axlRatsnestBlank RG_d_LITE_RATS))         ;uses "rats" color

;__FIXME__ -need error checks
  ;--------------------------------------------------------------------------------
  ; restore original settings for Find, Select, Visibility, rats, drc ...
  (_DTL_UTILS_SettingsSet OrigSettings t RG_b_REST_ZOOM)
  (axlDBControl 'ratsnestDistance OrigRatsNest)
;  (axlDBControl 'drcEnable OrigDRCState)
  (axlSetVariable "bmppath" OrigBmapPath)
  (axlDBControl 'activeLayer OrigActiveLayer)
  (axlShell "shadow off")

;__FIXME__ Should be using (regExitBefore) or (regExitAfter) for clean up
; allong with (err) (errSet) and (error)

  ;--------------------------------------------------------------------------------
  ; flush and close files
  (when (and (boundp 'LogsFH) (openportp LogsFH))
    (unless (and (drain LogsFH) (close LogsFH))
      (printf "\nERROR: destub_main() - File write/close failed on Logs File\n")))
  (when (and (boundp 'DbugFH) (openportp DbugFH))
    (unless (and (drain DbugFH) (close DbugFH))
      (printf "\nERROR: destub_main() - File write/close failed on Dbug File\n")))

  ;--------------------------------------------------------------------------------
  ; delete log and debug files
  (when RG_b_DEL_FILES
    (unless (and (isFile LogsFileName "./") (deleteFile LogsFileName))
      (printf "\nERROR: destub_main() - File delete failed on Logs File\n"))
    (unless (and (isFile DbugFileName "./") (deleteFile DbugFileName))
      (printf "\nERROR: destub_main() - File delete failed on Dbug File\n"))
    (unless (and (isFile FormFileName "./") (deleteFile FormFileName))
      (printf "\nERROR: destub_main() - File delete failed on Forms File\n")))
  ;--------------------------------------------------------------------------------
  (return t)
));end-PROG_and_PROCEDURE DT_destub_main()


;*******************************************************************************
; compatibility layer for older allegro versions
(defun DT_destub_GetConnect ( dbid full "og")
  (let ()
    (if (lessp (axlVersion 'version) 15.1)
    then
      (axlDBGetConnect dbid)
    else
      (axlDBGetConnect dbid full))))


;*******************************************************************************
;
; Heck, the time measurements should be using (measureTime) and (cputime)
;
(procedure (DT_destub_init)
(let (DoTimeTest LocVar UpVal StartTime StartTest)
  (setq DTD nil)
  (setq DTN "(DT_destub_init)")
  (when DTD (printf "\nSTATUS: %s \n" DTN))

  (setq DoTimeTest nil)
  (setq StartTime (getCurrentTime))
  (if (boundp 'RGls_FULL_LIST) then (setq RGls_FULL_LIST 'unbound) (gc)) ;help the garbage collector
  (setq RGls_FULL_LIST nil)

  (if (boundp 'RGlt_NETS_LIST) then (setq RGlt_NETS_LIST 'unbound) (gc)) ;help the garbage collector
  (setq RGlt_NETS_LIST nil)

  (DT_destub_tree_init)  ;init the treeview field

  (axlMeterCreate "Destubifier Analysis", "", nil)
  (setq UpVal (fix {100 / 10}))
  ;--------------------------------------------------------------------------------
  (axlMeterUpdate 1 "Analyzing VIAS")
  (if DoTimeTest
  then
    (setq StartTestData (getCurrentTime))
    (DT_destub_data_via)
    (DT_destub_data_via)
    (DT_destub_data_via)
    (DT_destub_data_via)
    (DT_destub_data_via)
    (DT_destub_data_via)
    (DT_destub_data_via)
    (DT_destub_data_via)
    (DT_destub_data_via)
    (DT_destub_data_via)
    (fprintf DbugFH "\n\n%s\nPROFILE TIMER - DT_destub_data_via TIME: %d seconds\n\n" RG_t_LINE1 (compareTime (getCurrentTime) StartTestData))
  else
    (DT_destub_data_via))
  ;--------------------------------------------------------------------------------
  (axlMeterUpdate {1 * UpVal} "Analyzing SHAPES")
  (if DoTimeTest
  then
    (setq StartTestData (getCurrentTime))
    (DT_destub_data_shape)
    (DT_destub_data_shape)
    (DT_destub_data_shape)
    (DT_destub_data_shape)
    (DT_destub_data_shape)
    (DT_destub_data_shape)
    (DT_destub_data_shape)
    (DT_destub_data_shape)
    (DT_destub_data_shape)
    (DT_destub_data_shape)
    (fprintf DbugFH "\n\n%s\nPROFILE TIMER - DT_destub_data_shape TIME: %d seconds\n\n" RG_t_LINE1 (compareTime (getCurrentTime) StartTestData))
  else
    (DT_destub_data_shape))
  ;--------------------------------------------------------------------------------
  (axlMeterUpdate {2 * UpVal} "Analyzing PATHS")
  (if DoTimeTest
  then
    (setq StartTestData (getCurrentTime))
    (DT_destub_data_path)
    (DT_destub_data_path)
    (DT_destub_data_path)
    (DT_destub_data_path)
    (DT_destub_data_path)
    (DT_destub_data_path)
    (DT_destub_data_path)
    (DT_destub_data_path)
    (DT_destub_data_path)
    (DT_destub_data_path)
    (fprintf DbugFH "\n\n%s\nPROFILE TIMER - DT_destub_data_path TIME: %d seconds\n\n" RG_t_LINE1 (compareTime (getCurrentTime) StartTestData))
  else
    (DT_destub_data_path))
  ;--------------------------------------------------------------------------------
  (axlMeterUpdate {3 * UpVal} "Analyzing PINS")
  (if DoTimeTest
  then
    (setq StartTestData (getCurrentTime))
    (DT_destub_data_pin)
    (DT_destub_data_pin)
    (DT_destub_data_pin)
    (DT_destub_data_pin)
    (DT_destub_data_pin)
    (DT_destub_data_pin)
    (DT_destub_data_pin)
    (DT_destub_data_pin)
    (DT_destub_data_pin)
    (DT_destub_data_pin)
    (fprintf DbugFH "\n\n%s\nPROFILE TIMER - DT_destub_data_pin TIME: %d seconds\n\n" RG_t_LINE1 (compareTime (getCurrentTime) StartTestData))
  else
    (DT_destub_data_pin))
  ;--------------------------------------------------------------------------------
  (axlMeterUpdate {4 * UpVal} "Analyzing BRANCHES")
  (if DoTimeTest
  then
    (setq StartTestData (getCurrentTime))
    (DT_destub_data_branch)
    (DT_destub_data_branch)
    (DT_destub_data_branch)
    (DT_destub_data_branch)
    (DT_destub_data_branch)
    (DT_destub_data_branch)
    (DT_destub_data_branch)
    (DT_destub_data_branch)
    (DT_destub_data_branch)
    (DT_destub_data_branch)
    (fprintf DbugFH "\n\n%s\nPROFILE TIMER - DT_destub_data_branch TIME: %d seconds\n\n" RG_t_LINE1 (compareTime (getCurrentTime) StartTestData))
  else
    (DT_destub_data_branch))
  ;--------------------------------------------------------------------------------
  (axlMeterUpdate {5 * UpVal} "Analyzing NETS")
  (setq StartTestData (getCurrentTime))
  (if DoTimeTest
  then
    (DT_destub_data_net)
    (DT_destub_data_net)
    (DT_destub_data_net)
    (DT_destub_data_net)
    (DT_destub_data_net)
    (DT_destub_data_net)
    (DT_destub_data_net)
    (DT_destub_data_net)
    (DT_destub_data_net)
    (DT_destub_data_net)
    (fprintf DbugFH "\n\n%s\nPROFILE TIMER - DT_destub_data_net TIME: %d seconds\n\n" RG_t_LINE1 (compareTime (getCurrentTime) StartTestData))
  else
    (DT_destub_data_net))
  ;--------------------------------------------------------------------------------
  (axlMeterUpdate {6 * UpVal} "Analyzing CHAINS")
  (DT_destub_data_chain)
  ;--------------------------------------------------------------------------------
  (axlMeterUpdate {7 * UpVal} "Building Problem List")
  ;--------------------------------------------------------------------------------
  (axlMeterUpdate {8 * UpVal} "Initializing Form")
  (setq RG_x_FULL_ROWS (length RGls_FULL_LIST))
  (DT_destub_form_init)
  ;--------------------------------------------------------------------------------
  (axlMeterUpdate {9 * UpVal} "Initializing Grid")
  (if DoTimeTest
  then
    (setq StartTestData (getCurrentTime))
    (DT_destub_filter_run)
    (fprintf DbugFH "\n\n%s\nPROFILE TIMER - DT_destub_filter_run TIME: %d seconds\n\n" RG_t_LINE1 (compareTime (getCurrentTime) StartTestData))
  else
    (DT_destub_filter_run))
  ;--------------------------------------------------------------------------------
  (axlMeterDestroy)
  (axlUIWPrint RG_g_FORM 'info0 "Analysis Time: %d seconds" (compareTime (getCurrentTime) StartTime))
  t
));end let & procedure DT_destub_init

;*******************************************************************************
;
(procedure (DT_destub_form_write ArgFormFileName "t")
(prog (FormFH)
  (setq DTD nil)
  (setq DTN "(DT_destub_form_write ...)")
  (when DTD (printf "\nSTATUS: %s \n" DTN))

  (unless (setq FormFH (outfile ArgFormFileName)) ; open form file handle
    (fprintf DbugFH "\nERROR: DT_destub_form_write() - Can Not Open Form Output File!\n")
    (return nil))
  (unless (and ; write out form file contents
    (fprintf FormFH "FILE_TYPE=FORM_DEFN VERSION=2\n")
    (fprintf FormFH "FORM FIXED_FONT\n")
    (fprintf FormFH "FIXED\n")
    (fprintf FormFH "PORT 110 64\n")
    (fprintf FormFH "HEADER \"DesignTools: Destubifier\"\n")
    (fprintf FormFH "DEFAULT \"OpCloseButton\"\n")
    (fprintf FormFH "\n")
    ; Grid Cell Property ENUM/Drop-Down-List
    (fprintf FormFH "POPUP <popCellProp>\"NONE\"\"0\".\n")
    ; Grid Cell Layer ENUM/Drop-Down-List
    (fprintf FormFH "POPUP <popCellLays>\"NONE\"\"0\".\n")
    ; Grid Column Sorting Right Click PopUp (multi-line through trailing "\")
    (fprintf FormFH "POPUP <popGridSortCol>\\\n")
    (fprintf FormFH "\"Sort Ascending\"\"ColSortAsc\",\\\n")
    (fprintf FormFH "\"Sort Decending\"\"ColSortDsc\",\\\n")
    (fprintf FormFH "\"Cancel Sort\"\"ColSortCan\".\n")
    ; Temp Group Row popup (multi-line through trailing "\")
    (fprintf FormFH "POPUP <popGridGroupRow>\\\n")
    (fprintf FormFH "\"Show Element On Current\"\"RowShowElement\",\\\n")
    (fprintf FormFH "\"Set DT_FANOUT On Current\"\"RowSetDT_FANOUT\",\\\n")
    (fprintf FormFH "\"Set DT_IGNORE On Current\"\"RowSetDT_IGNORE\",\\\n")
    (fprintf FormFH "\"--------------------------\"\"\",\\\n")
    (fprintf FormFH "\"Temp Group Start Row\"\"RowGroupStart\",\\\n")
    (fprintf FormFH "\"Temp Group End Row\"\"RowGroupEnd\",\\\n")
    (fprintf FormFH "\"Temp Group Add Row\"\"RowGroupAdd\",\\\n")
    (fprintf FormFH "\"--------------------------\"\"\",\\\n")
    (fprintf FormFH "\"Finish/Select Temp Group\"\"RowGroupCheck\",\\\n")
    (fprintf FormFH "\"Finish/Unselect Temp Group\"\"RowGroupUnCheck\",\\\n")
    (fprintf FormFH "\"Finish/Show Element Temp Group\"\"RowGroupShowElement\",\\\n")
    (fprintf FormFH "\"Finish/Set DT_FANOUT Temp Group\"\"RowGroupSetDT_FANOUT\",\\\n")
    (fprintf FormFH "\"Finish/Set DT_IGNORE Temp Group\"\"RowGroupSetDT_IGNORE\",\\\n")
    (fprintf FormFH "\"Cancel Temp Group\"\"RowGroupCancel\".\n")
    ;tree item popup
    (fprintf FormFH "POPUP <popTreeItem>\"NONE\"\"0\".\n")
    (fprintf FormFH "\n")
;    ;units popup
    (fprintf FormFH "POPUP <popUnits>\\\n")
    (fprintf FormFH "\"Mils\"\"mils\",\\\n")
    (fprintf FormFH "\"Inch\"\"inch\",\\\n")
    (fprintf FormFH "\"Micron\"\"micron\",\\\n")
    (fprintf FormFH "\"Millimeter\"\"millimeter\",\\\n")
    (fprintf FormFH "\"Centimeter\"\"centimeter\".\n")
    ;begin tile
    (fprintf FormFH "TILE\n")
    (fprintf FormFH "\n")
    ;start tab set
    (fprintf FormFH "TABSET \"FullTabSet\"\n")
    (fprintf FormFH "FLOC 0 0\n")
    (fprintf FormFH "FSIZE 111 36\n")
    (fprintf FormFH "OPTIONS tabsetDispatch\n")
    (fprintf FormFH "\n")

;********************************************************************************
    ; Display Tab
    (fprintf FormFH "TAB \"Display\"\n")
    (fprintf FormFH "\n")

    ; hidden dummy button -keeps the tree field from stealing focus on startup
    (fprintf FormFH "FIELD DumbButton\n")
    (fprintf FormFH "FLOC 0 0\n")
    (fprintf FormFH "MENUBUTTON \"\" 1 1\n")
    (fprintf FormFH "ENDFIELD\n")
    (fprintf FormFH "\n")
    ; tree view
    (fprintf FormFH "FIELD Ztree\n")
    (fprintf FormFH "FLOC 0 0\n")
    (fprintf FormFH "TREEVIEW 24 17\n")
    (fprintf FormFH "POP \"popTreeItem\"\n")
    (fprintf FormFH "ENDFIELD\n")
    (fprintf FormFH "\n")

    ;--------------------------------------------------------------------------------
    ; grid field
    (fprintf FormFH "GRID GridField\n")
    (fprintf FormFH "FLOC 24 0\n")
    (fprintf FormFH "FSIZE 86 31\n")
    (fprintf FormFH "POP \"popGridGroupRow\"\n")
    (fprintf FormFH "OPTIONS VLINES HLINES USERSIZE\n")
    (fprintf FormFH "\n")
    ; horizontal grid header
    (fprintf FormFH "GHEAD TOP\n")
    (fprintf FormFH "HEADSIZE 2\n")
    (fprintf FormFH "POP \"popGridSortCol\"\n")
    (fprintf FormFH "OPTIONS 3D\n")
    (fprintf FormFH "ENDGHEAD\n")
    (fprintf FormFH "\n")
    ; vertical grid header
    (fprintf FormFH "GHEAD SIDE\n")
    (fprintf FormFH "HEADSIZE 6\n")
    (fprintf FormFH "OPTIONS 3D NUMBER\n")
    (fprintf FormFH "ENDGHEAD\n")
    (fprintf FormFH "\n")
    (fprintf FormFH "ENDGRID\n")
    (fprintf FormFH "\n")
; Looks cool in windows but this is hosed on UNIX
;    ; decoration for grid - upper left corner
;    (fprintf FormFH "FIELD dec0\n")
;    (fprintf FormFH "FLOC 24 0\n")
;    (fprintf FormFH "MENUBUTTON \"\" 6 3\n")
;    (fprintf FormFH "ENDFIELD\n")
;    (fprintf FormFH "\n")
;    ; decoration for grid - upper right corner
;    (fprintf FormFH "FIELD dec1\n")
;    (fprintf FormFH "FLOC 108 0\n")
;    (fprintf FormFH "MENUBUTTON \"\" 2 3\n")
;    (fprintf FormFH "ENDFIELD\n")
;    (fprintf FormFH "\n")
;    ; decoration for grid -lower left corner
;    (fprintf FormFH "FIELD dec2\n")
;    (fprintf FormFH "FLOC 24 28\n")
;    (fprintf FormFH "MENUBUTTON \"\" 6 2\n")
;    (fprintf FormFH "ENDFIELD\n")
;    (fprintf FormFH "\n")
    ;--- Range Select Rows Sub ----------------------------------------------------
    (fprintf FormFH "FIELD VSelectRangeLoVal\n")
    (fprintf FormFH "FLOC 24 31\n")
    (fprintf FormFH "LONGFILLIN 4 8\n")
    (fprintf FormFH "VALUE 0\n")
    (fprintf FormFH "ENDFIELD\n")
    (fprintf FormFH "\n")
    (fprintf FormFH "TEXT \"To\" VSelectRangeToTxt\n")
    (fprintf FormFH "FLOC 30 31\n")
    (fprintf FormFH "FSIZE 3 2\n")
    (fprintf FormFH "ENDTEXT\n")
    (fprintf FormFH "\n")
    (fprintf FormFH "FIELD VSelectRangeHiVal\n")
    (fprintf FormFH "FLOC 33 31\n")
    (fprintf FormFH "LONGFILLIN 4 6\n")
    (fprintf FormFH "VALUE 0\n")
    (fprintf FormFH "ENDFIELD\n")
    (fprintf FormFH "\n")
    (fprintf FormFH "FIELD VSelectRangeOnBut\n")
    (fprintf FormFH "FLOC 39 31\n")
    (fprintf FormFH "MENUBUTTON \"Select Range\" 15 3\n")
    (fprintf FormFH "ENDFIELD\n")
    (fprintf FormFH "\n")
    (fprintf FormFH "FIELD VSelectRangeUnBut\n")
    (fprintf FormFH "FLOC 55 31\n")
    (fprintf FormFH "MENUBUTTON \"Unselect Range\" 18 3\n")
    (fprintf FormFH "ENDFIELD\n")
    (fprintf FormFH "\n")
    ;--- List Select All Sub ------------------------------------------------------
    (fprintf FormFH "FIELD VSelectListsOnBut\n")
    (fprintf FormFH "FLOC 78 31\n")
    (fprintf FormFH "MENUBUTTON \"Select List\" 15 3\n")
    (fprintf FormFH "ENDFIELD\n")
    (fprintf FormFH "\n")
    ;unselect list button
    (fprintf FormFH "FIELD VSelectListsUnBut\n")
    (fprintf FormFH "FLOC 94 31\n")
    (fprintf FormFH "MENUBUTTON \"Unselect List\" 16 3\n")
    (fprintf FormFH "ENDFIELD\n")
    (fprintf FormFH "\n")
    ;--------------------------------------------------------------------------------
    (fprintf FormFH "ENDTAB\n")
    (fprintf FormFH "\n")


;********************************************************************************
    (fprintf FormFH "TAB \"Filters\"\n")
    (fprintf FormFH "\n")
    ;--------------------------------------------------------------------------------
    ; filter by net (net name)
    (fprintf FormFH "GROUP \"Filter By Nets\" FiltNetsGroup\n")
    (fprintf FormFH "FLOC 0 0\n")
    (fprintf FormFH "FSIZE 34 33\n")
    (fprintf FormFH "\n")
    ; nets all button
    (fprintf FormFH "FIELD FiltNetsAllButton\n")
    (fprintf FormFH "FLOC 1 2\n")
    (fprintf FormFH "MENUBUTTON \"All\" 8 2\n")
    (fprintf FormFH "ENDFIELD\n")
    (fprintf FormFH "\n")
    ; nets none button
    (fprintf FormFH "FIELD FiltNetsWithButton\n")
    (fprintf FormFH "FLOC 11 2\n")
    (fprintf FormFH "MENUBUTTON \"With Net\" 11 2\n")
    (fprintf FormFH "ENDFIELD\n")
    (fprintf FormFH "\n")
    ; nets none button
    (fprintf FormFH "FIELD FiltNetsNoneButton\n")
    (fprintf FormFH "FLOC 24 2\n")
    (fprintf FormFH "MENUBUTTON \"No Net\" 9 2\n")
    (fprintf FormFH "ENDFIELD\n")
    (fprintf FormFH "\n")
    ; nets grid field
    (fprintf FormFH "GRID FiltNetsGrid\n")
    (fprintf FormFH "FLOC 1 4\n")
    (fprintf FormFH "FSIZE 32 29\n")
;    (fprintf FormFH "POP \"popGridGroupRow\"\n")
    (fprintf FormFH "OPTIONS VLINES HLINES USERSIZE\n")
    (fprintf FormFH "\n")
    (fprintf FormFH "ENDGRID\n")
    (fprintf FormFH "\n")
    ;end FilterNetsGroup
    (fprintf FormFH "ENDGROUP\n")
    (fprintf FormFH "\n")
    ;--------------------------------------------------------------------------------
    ; filter by layer (layer name)
    (fprintf FormFH "GROUP \"Filter By Layers\" FiltLaysGroup\n")
    (fprintf FormFH "FLOC 36 0\n")
    (fprintf FormFH "FSIZE 34 33\n")
    (fprintf FormFH "\n")
    ; lays all button
    (fprintf FormFH "FIELD FiltLaysAllButton\n")
    (fprintf FormFH "FLOC 37 2\n")
    (fprintf FormFH "MENUBUTTON \"All\" 6 2\n")
    (fprintf FormFH "ENDFIELD\n")
    (fprintf FormFH "\n")
    ; lays none button
    (fprintf FormFH "FIELD FiltLaysWithButton\n")
    (fprintf FormFH "FLOC 44 2\n")
    (fprintf FormFH "MENUBUTTON \"With Layer\" 13 2\n")
    (fprintf FormFH "ENDFIELD\n")
    (fprintf FormFH "\n")
    ; lays none button
    (fprintf FormFH "FIELD FiltLaysNoneButton\n")
    (fprintf FormFH "FLOC 58 2\n")
    (fprintf FormFH "MENUBUTTON \"No Layer\" 11 2\n")
    (fprintf FormFH "ENDFIELD\n")
    (fprintf FormFH "\n")
    ; lays grid field
    (fprintf FormFH "GRID FiltLaysGrid\n")
    (fprintf FormFH "FLOC 37 4\n")
    (fprintf FormFH "FSIZE 32 29\n")
    (fprintf FormFH "OPTIONS VLINES HLINES USERSIZE\n")
    (fprintf FormFH "\n")
    (fprintf FormFH "ENDGRID\n")
    (fprintf FormFH "\n")
     ;end FilterLaysGroup
    (fprintf FormFH "ENDGROUP\n")
    (fprintf FormFH "\n")
    ;--------------------------------------------------------------------------------s
    ; filter by type (via, path etc.)
    (fprintf FormFH "GROUP \"Filter By Type\" FiltTypeGroup\n")
    (fprintf FormFH "FLOC 72 0\n")
    (fprintf FormFH "FSIZE 37 13\n")
    (fprintf FormFH "\n")
    ; type all button
    (fprintf FormFH "FIELD FiltTypeAllButton\n")
    (fprintf FormFH "FLOC 73 2\n")
    (fprintf FormFH "MENUBUTTON \"All Types\" 16 2\n")
    (fprintf FormFH "ENDFIELD\n")
    (fprintf FormFH "\n")
    ; type none button
    (fprintf FormFH "FIELD FiltTypeNoneButton\n")
    (fprintf FormFH "FLOC 92 2\n")
    (fprintf FormFH "MENUBUTTON \"No Types\" 16 2\n")
    (fprintf FormFH "ENDFIELD\n")
    (fprintf FormFH "\n")
    ; type check CHAINS
    (fprintf FormFH "FIELD FiltTypeCheckCHAINS\n")
    (fprintf FormFH "FLOC 73 4\n")
    (fprintf FormFH "CHECKLIST \"Bad Chains\"\n")
    (fprintf FormFH "ENDFIELD\n")
    ; type check NETS
    (fprintf FormFH "FIELD FiltTypeCheckNETS\n")
    (fprintf FormFH "FLOC 73 6\n")
    (fprintf FormFH "CHECKLIST \"Bad Nets\"\n")
    (fprintf FormFH "ENDFIELD\n")
    ; type check BRANCHES
    (fprintf FormFH "FIELD FiltTypeCheckBRANCHES\n")
    (fprintf FormFH "FLOC 73 8\n")
    (fprintf FormFH "CHECKLIST \"Bad Branches\"\n")
    (fprintf FormFH "ENDFIELD\n")
    ; type check PATHS
    (fprintf FormFH "FIELD FiltTypeCheckPATHS\n")
    (fprintf FormFH "FLOC 73 10\n")
    (fprintf FormFH "CHECKLIST \"Bad Paths\"\n")
    (fprintf FormFH "ENDFIELD\n")
    ; type check PINS
    (fprintf FormFH "FIELD FiltTypeCheckPINS\n")
    (fprintf FormFH "FLOC 92 4\n")
    (fprintf FormFH "CHECKLIST \"Bad Pins\"\n")
    (fprintf FormFH "ENDFIELD\n")
    ; type check SHAPES
    (fprintf FormFH "FIELD FiltTypeCheckSHAPES\n")
    (fprintf FormFH "FLOC 92 6\n")
    (fprintf FormFH "CHECKLIST \"Bad Shapes\"\n")
    (fprintf FormFH "ENDFIELD\n")
    ; type check VIAS
    (fprintf FormFH "FIELD FiltTypeCheckVIAS\n")
    (fprintf FormFH "FLOC 92 8\n")
    (fprintf FormFH "CHECKLIST \"Bad Vias\"\n")
    (fprintf FormFH "ENDFIELD\n")
    ;end FilterTypeGroup
    (fprintf FormFH "ENDGROUP\n")
    (fprintf FormFH "\n")
    ;--------------------------------------------------------------------------------s
    ; filter by property (members of RGlt_PROP_LIST)
    (fprintf FormFH "GROUP \"Filter By Property\" FiltPropGroup\n")
    (fprintf FormFH "FLOC 72 14\n")
    (fprintf FormFH "FSIZE 37 10\n")
    (fprintf FormFH "\n")
    ; prop all button
    (fprintf FormFH "FIELD FiltPropAllButton\n")
    (fprintf FormFH "FLOC 73 16\n")
    (fprintf FormFH "MENUBUTTON \"All Properties\" 17 2\n")
    (fprintf FormFH "ENDFIELD\n")
    (fprintf FormFH "\n")
    ; prop none button
    (fprintf FormFH "FIELD FiltPropNoneButton\n")
    (fprintf FormFH "FLOC 92 16\n")
    (fprintf FormFH "MENUBUTTON \"No Properties\" 16 2\n")
    (fprintf FormFH "ENDFIELD\n")
    (fprintf FormFH "\n")
    ; prop check DT_FANOUT
    (fprintf FormFH "FIELD FiltPropCheckDT_FANOUT\n")
    (fprintf FormFH "FLOC 73 18\n")
    (fprintf FormFH "CHECKLIST \"DT_FANOUT\"\n")
    (fprintf FormFH "ENDFIELD\n")
    ; prop check DT_IGNORE
    (fprintf FormFH "FIELD FiltPropCheckDT_IGNORE\n")
    (fprintf FormFH "FLOC 92 18\n")
    (fprintf FormFH "CHECKLIST \"DT_IGNORE\"\n")
    (fprintf FormFH "ENDFIELD\n")
    ; prop check DT_UNUSED
    (fprintf FormFH "FIELD FiltPropCheckDT_UNUSED\n")
    (fprintf FormFH "FLOC 73 20\n")
    (fprintf FormFH "CHECKLIST \"DT_UNUSED\"\n")
    (fprintf FormFH "ENDFIELD\n")
    ; prop check DT_NOCONN
    (fprintf FormFH "FIELD FiltPropCheckDT_NOCONN\n")
    (fprintf FormFH "FLOC 92 20\n")
    (fprintf FormFH "CHECKLIST \"DT_NOCONN\"\n")
    (fprintf FormFH "ENDFIELD\n")
;    ; prop check DT_NOCONN
;    (fprintf FormFH "FIELD FiltPropCheckWithSettings\n")
;    (fprintf FormFH "FLOC 73 22\n")
;    (fprintf FormFH "CHECKLIST \"Only Show Objects With Properties\"\n")
;    (fprintf FormFH "ENDFIELD\n")

    ;end FilterPropGroup
    (fprintf FormFH "ENDGROUP\n")
    (fprintf FormFH "\n")
    ;--------------------------------------------------------------------------------
    ; filter by selection (checked/unchecked)
    (fprintf FormFH "GROUP \"Filter By Selection\" FiltShowGroup\n")
    (fprintf FormFH "FLOC 72 25\n")
    (fprintf FormFH "FSIZE 37 5\n")
    (fprintf FormFH "\n")
    ; show check all
    (fprintf FormFH "FIELD FiltShowSelected\n")
    (fprintf FormFH "FLOC 73 27\n")
    (fprintf FormFH "CHECKLIST \"Selected\"\n")
    (fprintf FormFH "ENDFIELD\n")
    ; show check all
    (fprintf FormFH "FIELD FiltShowUnselected\n")
    (fprintf FormFH "FLOC 92 27\n")
    (fprintf FormFH "CHECKLIST \"Unselected\"\n")
    (fprintf FormFH "ENDFIELD\n")
    ;end FilterShowGroup
    (fprintf FormFH "ENDGROUP\n")
    (fprintf FormFH "\n")
    ;--------------------------------------------------------------------------------
    ; show everything
    (fprintf FormFH "FIELD FiltShowEverythingButton\n")
    (fprintf FormFH "FLOC 72 31\n")
    (fprintf FormFH "MENUBUTTON \"Show Everything\" 18 3\n")
    (fprintf FormFH "ENDFIELD\n")
    ; show selected
    (fprintf FormFH "FIELD FiltShowSelectedButton\n")
    (fprintf FormFH "FLOC 92 31\n")
    (fprintf FormFH "MENUBUTTON \"Show Selected\" 17 3\n")
    (fprintf FormFH "ENDFIELD\n")
;    ; show selected
;    (fprintf FormFH "FIELD FiltSaveDefaultButton\n")
;    (fprintf FormFH "FLOC 72 31\n")
;    (fprintf FormFH "MENUBUTTON \"Save Filter Settings As Default\" 37 3\n")
;    (fprintf FormFH "ENDFIELD\n")
    ;--------------------------------------------------------------------------------
    (fprintf FormFH "ENDTAB\n")
    (fprintf FormFH "\n")

;;JCR-MARK: The start of the settings tab
;;********************************************************************************
;    (fprintf FormFH "TAB \"Settings\"\n")
;    (fprintf FormFH "\n")
;    ;--------------------------------------------------------------------------------
;    ; auto bga/pga fanout detection settings
;    (fprintf FormFH "GROUP \"Automatic BGA/PGA Fanout Detection\" SetsFanoutGroup\n")
;    (fprintf FormFH "FLOC 0 0\n")
;    (fprintf FormFH "FSIZE 38 11\n")
;    (fprintf FormFH "\n")
;    ;fanout description
;    (fprintf FormFH "TEXT \"Distance Between Pin And First Via\" SetsViaFanoutTxt1\n")
;    (fprintf FormFH "FLOC 2 2\n")
;    (fprintf FormFH "FSIZE 34 2\n")
;    (fprintf FormFH "ENDTEXT\n")
;    ;fanout description
;    (fprintf FormFH "TEXT \"Value:\" SetsViaFanoutTxt2\n")
;    (fprintf FormFH "FLOC 2 4\n")
;    (fprintf FormFH "FSIZE 6 2\n")
;    (fprintf FormFH "ENDTEXT\n")
;    ; fanout value
;    (fprintf FormFH "FIELD SetsViaFanoutVal\n")
;    (fprintf FormFH "FLOC 10 4\n")
;    (fprintf FormFH "REALFILLIN 6 8\n")
;    (fprintf FormFH "VALUE 0\n")
;    (fprintf FormFH "ENDFIELD\n")
;    (fprintf FormFH "\n")
;    ; fanout units
;    (fprintf FormFH "FIELD SetsUnits\n")
;    (fprintf FormFH "FLOC 20 4\n")
;    (fprintf FormFH "ENUMSET 12\n")
;    (fprintf FormFH "POP \"popUnits\"\n")
;    (fprintf FormFH "ENDFIELD\n")
;    (fprintf FormFH "\n")
;    ; Require via under placebound check box
;    (fprintf FormFH "FIELD SetsViaUnder\n")
;    (fprintf FormFH "FLOC 2 6\n")
;    (fprintf FormFH "CHECKLIST \"Require VIA under PlaceBound\"\n")
;    (fprintf FormFH "ENDFIELD\n")
;    ; min pin/pad description
;    (fprintf FormFH "TEXT \"Min Number of Pins:\" SetsViaMinPadTxt1\n")
;    (fprintf FormFH "FLOC 2 8\n")
;    (fprintf FormFH "FSIZE 19 2\n")
;    (fprintf FormFH "ENDTEXT\n")
;    ; min pin/pad value
;    (fprintf FormFH "FIELD SetsViaMinPadVal\n")
;    (fprintf FormFH "FLOC 22 8\n")
;    (fprintf FormFH "LONGFILLIN 6 8\n")
;    (fprintf FormFH "VALUE 0\n")
;    (fprintf FormFH "ENDFIELD\n")
;    ; min pin/pad description
;    (fprintf FormFH "TEXT \"square\" SetsViaMinPadTxt2\n")
;    (fprintf FormFH "FLOC 30 8\n")
;    (fprintf FormFH "FSIZE 6 2\n")
;    (fprintf FormFH "ENDTEXT\n")
;    ;end of fanout group
;    (fprintf FormFH "ENDGROUP\n")
;    (fprintf FormFH "\n")
;    ;--------------------------------------------------------------------------------
;    ; type filter settings
;    (fprintf FormFH "GROUP \"Type Filter Settings\" SetsTypeGroup\n")
;    (fprintf FormFH "FLOC 72 0\n")
;    (fprintf FormFH "FSIZE 37 13\n")
;    (fprintf FormFH "\n")
;    ; type all button
;    (fprintf FormFH "FIELD SetsTypeAllButton\n")
;    (fprintf FormFH "FLOC 73 2\n")
;    (fprintf FormFH "MENUBUTTON \"All Types\" 16 2\n")
;    (fprintf FormFH "ENDFIELD\n")
;    (fprintf FormFH "\n")
;    ; type none button
;    (fprintf FormFH "FIELD SetsTypeNoneButton\n")
;    (fprintf FormFH "FLOC 92 2\n")
;    (fprintf FormFH "MENUBUTTON \"No Types\" 16 2\n")
;    (fprintf FormFH "ENDFIELD\n")
;    (fprintf FormFH "\n")
;    ; type check CHAINS
;    (fprintf FormFH "FIELD SetsTypeCheckCHAINS\n")
;    (fprintf FormFH "FLOC 73 4\n")
;    (fprintf FormFH "CHECKLIST \"Bad Chains\"\n")
;    (fprintf FormFH "ENDFIELD\n")
;    ; type check NETS
;    (fprintf FormFH "FIELD SetsTypeCheckNETS\n")
;    (fprintf FormFH "FLOC 73 6\n")
;    (fprintf FormFH "CHECKLIST \"Bad Nets\"\n")
;    (fprintf FormFH "ENDFIELD\n")
;    ; type check BRANCHES
;    (fprintf FormFH "FIELD SetsTypeCheckBRANCHES\n")
;    (fprintf FormFH "FLOC 73 8\n")
;    (fprintf FormFH "CHECKLIST \"Bad Branches\"\n")
;    (fprintf FormFH "ENDFIELD\n")
;    ; type check PATHS
;    (fprintf FormFH "FIELD SetsTypeCheckPATHS\n")
;    (fprintf FormFH "FLOC 73 10\n")
;    (fprintf FormFH "CHECKLIST \"Bad Paths\"\n")
;    (fprintf FormFH "ENDFIELD\n")
;    ; type check PINS
;    (fprintf FormFH "FIELD SetsTypeCheckPINS\n")
;    (fprintf FormFH "FLOC 92 4\n")
;    (fprintf FormFH "CHECKLIST \"Bad Pins\"\n")
;    (fprintf FormFH "ENDFIELD\n")
;    ; type check SHAPES
;    (fprintf FormFH "FIELD SetsTypeCheckSHAPES\n")
;    (fprintf FormFH "FLOC 92 6\n")
;    (fprintf FormFH "CHECKLIST \"Bad Shapes\"\n")
;    (fprintf FormFH "ENDFIELD\n")
;    ; type check VIAS
;    (fprintf FormFH "FIELD SetsTypeCheckVIAS\n")
;    (fprintf FormFH "FLOC 92 8\n")
;    (fprintf FormFH "CHECKLIST \"Bad Vias\"\n")
;    (fprintf FormFH "ENDFIELD\n")
;    ;end Type Settings Group
;    (fprintf FormFH "ENDGROUP\n")
;    (fprintf FormFH "\n")
;    ;--------------------------------------------------------------------------------s
;    ; property filter settings
;    (fprintf FormFH "GROUP \"Property Filter Settings\" SetsPropGroup\n")
;    (fprintf FormFH "FLOC 72 13\n")
;    (fprintf FormFH "FSIZE 37 8\n")
;    (fprintf FormFH "\n")
;    ; prop all button
;    (fprintf FormFH "FIELD SetsPropAllButton\n")
;    (fprintf FormFH "FLOC 73 15\n")
;    (fprintf FormFH "MENUBUTTON \"All Properties\" 17 2\n")
;    (fprintf FormFH "ENDFIELD\n")
;    (fprintf FormFH "\n")
;    ; prop none button
;    (fprintf FormFH "FIELD SetsPropNoneButton\n")
;    (fprintf FormFH "FLOC 92 15\n")
;    (fprintf FormFH "MENUBUTTON \"No Properties\" 16 2\n")
;    (fprintf FormFH "ENDFIELD\n")
;    (fprintf FormFH "\n")
;    ; prop check DT_FANOUT
;    (fprintf FormFH "FIELD SetsPropCheckDT_FANOUT\n")
;    (fprintf FormFH "FLOC 73 17\n")
;    (fprintf FormFH "CHECKLIST \"DT_FANOUT\"\n")
;    (fprintf FormFH "ENDFIELD\n")
;    ; prop check DT_IGNORE
;    (fprintf FormFH "FIELD SetsPropCheckDT_IGNORE\n")
;    (fprintf FormFH "FLOC 92 17\n")
;    (fprintf FormFH "CHECKLIST \"DT_IGNORE\"\n")
;    (fprintf FormFH "ENDFIELD\n")
;    ; prop check DT_UNUSED
;    (fprintf FormFH "FIELD SetsPropCheckDT_UNUSED\n")
;    (fprintf FormFH "FLOC 73 19\n")
;    (fprintf FormFH "CHECKLIST \"DT_UNUSED\"\n")
;    (fprintf FormFH "ENDFIELD\n")
;    ; prop check DT_NOCONN
;    (fprintf FormFH "FIELD SetsPropCheckDT_NOCONN\n")
;    (fprintf FormFH "FLOC 92 19\n")
;    (fprintf FormFH "CHECKLIST \"DT_NOCONN\"\n")
;    (fprintf FormFH "ENDFIELD\n")
;    ;end Prop Settings Group
;    (fprintf FormFH "ENDGROUP\n")
;    (fprintf FormFH "\n")
;
;    ;--------------------------------------------------------------------------------s
;    ; get/set filter settings
;    (fprintf FormFH "GROUP \"Current Filter Settings\" SetsSetGetGroup\n")
;    (fprintf FormFH "FLOC 72 21\n")
;    (fprintf FormFH "FSIZE 37 5\n")
;    (fprintf FormFH "\n")
;    ; get current filters button
;    (fprintf FormFH "FIELD SetsGetFiltersButton\n")
;    (fprintf FormFH "FLOC 73 23\n")
;    (fprintf FormFH "MENUBUTTON \"Get Current\" 16 3\n")
;    (fprintf FormFH "ENDFIELD\n")
;    ; set current filters button
;    (fprintf FormFH "FIELD SetsSetFiltersButton\n")
;    (fprintf FormFH "FLOC 92 23\n")
;    (fprintf FormFH "MENUBUTTON \"Set Current\" 16 3\n")
;    (fprintf FormFH "ENDFIELD\n")
;    ;end Get/Set Filters Group
;    (fprintf FormFH "ENDGROUP\n")
;    (fprintf FormFH "\n")
;
;    ;--------------------------------------------------------------------------------s
;    ; save settings to file
;    (fprintf FormFH "FIELD SetsSaveDefButton\n")
;    (fprintf FormFH "FLOC 92 31\n")
;    (fprintf FormFH "MENUBUTTON \"Save Settings\" 17 3\n")
;    (fprintf FormFH "ENDFIELD\n")
;
;    ; load settings from file
;    (fprintf FormFH "FIELD SetsLoadDefButton\n")
;    (fprintf FormFH "FLOC 72 31\n")
;    (fprintf FormFH "MENUBUTTON \"Load Settings\" 17 3\n")
;    (fprintf FormFH "ENDFIELD\n")
;
;
;;    (fprintf FormFH "TEXT \"Test\" Image1\n")
;;    (fprintf FormFH "THUMBNAIL %s\n" RG_t_BMP_FILE_TREESET)
;;;    (fprintf FormFH "THUMBNAIL 2\n" RG_t_BMP_FILE_TREESET)
;;    (fprintf FormFH "FLOC 2 8\n")
;;    (fprintf FormFH "FSIZE 90 10\n")
;;;    (fprintf FormFH "THUMBNAIL [<bitmapFile>|#<resource>]
;;;    (fprintf FormFH "THUMBNAIL [<bitmapFile>|#<resource>]
;;;    (fprintf FormFH "OPTIONS BORDER\n")
;;    (fprintf FormFH "ENDTEXT\n")
;
;;    (fprintf FormFH "FIELD bmp2\n")
;;    (fprintf FormFH "THUMBNAIL %s\n" RG_t_BMP_FILE_TREESET)
;;    (fprintf FormFH "FLOC 2 16\n")
;;    (fprintf FormFH "FSIZE 80 10\n")
;;;    (fprintf FormFH "OPTIONS stretch\n")
;;    (fprintf FormFH "ENDFIELD\n")
;
;    ;end settings tab
;    (fprintf FormFH "ENDTAB\n")


;JCR-MARK: This is the "Help" tab
;********************************************************************************
    (fprintf FormFH "TAB \"QuickHelp\"\n")
    (fprintf FormFH "\n")
    (fprintf FormFH "TEXT \"\" HelpTxt\n")
    (fprintf FormFH "FLOC 1 1\n")
    (fprintf FormFH "FSIZE 71 12\n")
    (fprintf FormFH "OPTIONS BORDER\n")
    (fprintf FormFH "ENDTEXT\n")
    ;---------------------------------------------------------------------------
    ; help version and credit group
    (fprintf FormFH "GROUP \"About\" HelpCreditGroup\n")
    (fprintf FormFH "FLOC 73 0\n")
    (fprintf FormFH "FSIZE 37 13\n")
    (fprintf FormFH "\n")
    ; program
    (fprintf FormFH "TEXT \"Program\" HelpProgram0\n")
    (fprintf FormFH "FLOC 74 2\n")
    (fprintf FormFH "FSIZE 8 2\n")
    (fprintf FormFH "OPTIONS BORDER\n")
    (fprintf FormFH "ENDTEXT\n")
    (fprintf FormFH "TEXT \"\" HelpProgram1\n")
    (fprintf FormFH "FLOC 82 2\n")
    (fprintf FormFH "FSIZE 27 2\n")
    (fprintf FormFH "OPTIONS BORDER\n")
    (fprintf FormFH "ENDTEXT\n")
    ; version
    (fprintf FormFH "TEXT \"Version\" HelpVersion0\n")
    (fprintf FormFH "FLOC 74 4\n")
    (fprintf FormFH "FSIZE 8 2\n")
    (fprintf FormFH "OPTIONS BORDER\n")
    (fprintf FormFH "ENDTEXT\n")
    (fprintf FormFH "TEXT \"\" HelpVersion1\n")
    (fprintf FormFH "FLOC 82 4\n")
    (fprintf FormFH "FSIZE 27 2\n")
    (fprintf FormFH "OPTIONS BORDER\n")
    (fprintf FormFH "ENDTEXT\n")
    ; authors
    (fprintf FormFH "TEXT \"Author\" HelpAuthors0\n")
    (fprintf FormFH "FLOC 74 6\n")
    (fprintf FormFH "FSIZE 8 2\n")
    (fprintf FormFH "OPTIONS BORDER\n")
    (fprintf FormFH "ENDTEXT\n")
    (fprintf FormFH "TEXT \"\" HelpAuthors1\n")
    (fprintf FormFH "FLOC 82 6\n")
    (fprintf FormFH "FSIZE 27 2\n")
    (fprintf FormFH "OPTIONS BORDER\n")
    (fprintf FormFH "ENDTEXT\n")
    ; contact
    (fprintf FormFH "TEXT \"Contact\" HelpContact0\n")
    (fprintf FormFH "FLOC 74 8\n")
    (fprintf FormFH "FSIZE 8 2\n")
    (fprintf FormFH "OPTIONS BORDER\n")
    (fprintf FormFH "ENDTEXT\n")
    (fprintf FormFH "TEXT \"\" HelpContact1\n")
    (fprintf FormFH "FLOC 82 8\n")
    (fprintf FormFH "FSIZE 27 2\n")
    (fprintf FormFH "OPTIONS BORDER\n")
    (fprintf FormFH "ENDTEXT\n")
    ; credits
    (fprintf FormFH "TEXT \"Credits\" HelpCredits0\n")
    (fprintf FormFH "FLOC 74 10\n")
    (fprintf FormFH "FSIZE 8 2\n")
    (fprintf FormFH "OPTIONS BORDER\n")
    (fprintf FormFH "ENDTEXT\n")
    (fprintf FormFH "TEXT \"\" HelpCredits1\n")
    (fprintf FormFH "FLOC 82 10\n")
    (fprintf FormFH "FSIZE 27 2\n")
    (fprintf FormFH "OPTIONS BORDER\n")
    (fprintf FormFH "ENDTEXT\n")
    ;end of help credit group
    (fprintf FormFH "ENDGROUP\n")
    (fprintf FormFH "\n")
    ;---------------------------------------------------------------------------
    ; help colors group
    (fprintf FormFH "GROUP \"Colors\" HelpColorsGroup\n")
    (fprintf FormFH "FLOC 1 12\n")
    (fprintf FormFH "FSIZE 47 11\n")
    (fprintf FormFH "\n")
    ; dot red
    (fprintf FormFH "FIELD HelpImgDotRed\n")
    (fprintf FormFH "THUMBNAIL %s\n" RG_t_BMP_FILE_DOT_RED)
    (fprintf FormFH "FLOC 2 14\n")
    (fprintf FormFH "FSIZE 4 2\n")
    (fprintf FormFH "ENDFIELD\n")
    (fprintf FormFH "TEXT \" RED - OBJECT SELECTED FOR DELETION\" HelpTxtDotRed\n")
    (fprintf FormFH "FLOC 6 14\n")
    (fprintf FormFH "FSIZE 41 2\n")
    (fprintf FormFH "OPTIONS BORDER\n")
    (fprintf FormFH "ENDTEXT\n")
    ; dot green
    (fprintf FormFH "FIELD HelpImgDotGrn\n")
    (fprintf FormFH "THUMBNAIL %s\n" RG_t_BMP_FILE_DOT_GRN)
    (fprintf FormFH "FLOC 2 16\n")
    (fprintf FormFH "FSIZE 4 2\n")
    (fprintf FormFH "ENDFIELD\n")
    (fprintf FormFH "TEXT \" GREEN - Object BAD But Not Selected\" HelpTxtDotGrn\n")
    (fprintf FormFH "FLOC 6 16\n")
    (fprintf FormFH "FSIZE 41 2\n")
    (fprintf FormFH "OPTIONS BORDER\n")
    (fprintf FormFH "ENDTEXT\n")
    ; dot blue
    (fprintf FormFH "FIELD HelpImgDotBlu\n")
    (fprintf FormFH "THUMBNAIL %s\n" RG_t_BMP_FILE_DOT_BLU)
    (fprintf FormFH "FLOC 2 18\n")
    (fprintf FormFH "FSIZE 4 2\n")
    (fprintf FormFH "ENDFIELD\n")
    (fprintf FormFH "TEXT \" BLUE - Object Good (Passed Tests)\" HelpTxtDotBlu\n")
    (fprintf FormFH "FLOC 6 18\n")
    (fprintf FormFH "FSIZE 41 2\n")
    (fprintf FormFH "OPTIONS BORDER\n")
    (fprintf FormFH "ENDTEXT\n")
    ; dot yellow
    (fprintf FormFH "FIELD HelpImgDotYel\n")
    (fprintf FormFH "THUMBNAIL %s\n" RG_t_BMP_FILE_DOT_YEL)
    (fprintf FormFH "FLOC 2 20\n")
    (fprintf FormFH "FSIZE 4 2\n")
    (fprintf FormFH "ENDFIELD\n")
    (fprintf FormFH "TEXT \" YELLOW - Selected Pins (will not delete)\" HelpTxtDotYel\n")
    (fprintf FormFH "FLOC 6 20\n")
    (fprintf FormFH "FSIZE 41 2\n")
    (fprintf FormFH "OPTIONS BORDER\n")
    (fprintf FormFH "ENDTEXT\n")
    ;end of colors group
    (fprintf FormFH "ENDGROUP\n")
    (fprintf FormFH "\n")
    ;---------------------------------------------------------------------------
    ; help folders group
    (fprintf FormFH "GROUP \"Folders\" HelpFoldersGroup\n")
    (fprintf FormFH "FLOC 49 12\n")
    (fprintf FormFH "FSIZE 61 11\n")
    (fprintf FormFH "\n")
    ; folder red
    (fprintf FormFH "FIELD HelpImgFldRed\n")
    (fprintf FormFH "THUMBNAIL %s\n" RG_t_BMP_FILE_FLD_RED)
    (fprintf FormFH "FLOC 50 14\n")
    (fprintf FormFH "FSIZE 4 2\n")
    (fprintf FormFH "ENDFIELD\n")
    (fprintf FormFH "TEXT \" RED - ALL OBJECTS CONTAINED ARE SELECTED FOR DELETION\" HelpTxtFldRed\n")
    (fprintf FormFH "FLOC 54 14\n")
    (fprintf FormFH "FSIZE 55 2\n")
    (fprintf FormFH "OPTIONS BORDER\n")
    (fprintf FormFH "ENDTEXT\n")
    ; folder green
    (fprintf FormFH "FIELD HelpImgFldHlf\n")
    (fprintf FormFH "THUMBNAIL %s\n" RG_t_BMP_FILE_FLD_HLF)
    (fprintf FormFH "FLOC 50 16\n")
    (fprintf FormFH "FSIZE 4 2\n")
    (fprintf FormFH "ENDFIELD\n")
    (fprintf FormFH "TEXT \" HALF RED - SOME OBJECTS ARE SELECTED FOR DELETION\" HelpTxtFldHlf\n")
    (fprintf FormFH "FLOC 54 16\n")
    (fprintf FormFH "FSIZE 55 2\n")
    (fprintf FormFH "OPTIONS BORDER\n")
    (fprintf FormFH "ENDTEXT\n")
    ; folder blue
    (fprintf FormFH "FIELD HelpImgFldGrn\n")
    (fprintf FormFH "THUMBNAIL %s\n" RG_t_BMP_FILE_FLD_GRN)
    (fprintf FormFH "FLOC 50 18\n")
    (fprintf FormFH "FSIZE 4 2\n")
    (fprintf FormFH "ENDFIELD\n")
    (fprintf FormFH "TEXT \" GREEN - Contains Bad Objects But None Are Selected\" HelpTxtFldGrn\n")
    (fprintf FormFH "FLOC 54 18\n")
    (fprintf FormFH "FSIZE 55 2\n")
    (fprintf FormFH "OPTIONS BORDER\n")
    (fprintf FormFH "ENDTEXT\n")
    ; folder yellow
    (fprintf FormFH "FIELD HelpImgFldYel\n")
    (fprintf FormFH "THUMBNAIL %s\n" RG_t_BMP_FILE_FLD_YEL)
    (fprintf FormFH "FLOC 50 20\n")
    (fprintf FormFH "FSIZE 4 2\n")
    (fprintf FormFH "ENDFIELD\n")
    (fprintf FormFH "TEXT \" YELLOW - Normal (Used To Sort Types of Objects)\" HelpTxtFldYel\n")
    (fprintf FormFH "FLOC 54 20\n")
    (fprintf FormFH "FSIZE 55 2\n")
    (fprintf FormFH "OPTIONS BORDER\n")
    (fprintf FormFH "ENDTEXT\n")
    ;end of folders group
    (fprintf FormFH "ENDGROUP\n")
    (fprintf FormFH "\n")

    ;---------------------------------------------------------------------------
    ; additional-help group
    (fprintf FormFH "GROUP \"Additonal Help\" HelpAdditionalGroup\n")
    (fprintf FormFH "FLOC 1 23\n")
    (fprintf FormFH "FSIZE 47 10\n")
    (fprintf FormFH "\n")
    (fprintf FormFH "TEXT \"\" HelpTxtAdd\n")
    (fprintf FormFH "FLOC 2 25\n")
    (fprintf FormFH "FSIZE 45 5\n")
    (fprintf FormFH "OPTIONS BORDER BOLD\n")
    (fprintf FormFH "ENDTEXT\n")
    (fprintf FormFH "\n")
    (fprintf FormFH "FIELD HelpButtonOnLine\n")
    (fprintf FormFH "FLOC 4 30\n")
    (fprintf FormFH "MENUBUTTON \"On-Line Help\" 16 3\n")
    (fprintf FormFH "ENDFIELD\n")
    (fprintf FormFH "\n")
;    (fprintf FormFH "FIELD HelpButtonLocal\n")
;    (fprintf FormFH "FLOC 26 30\n")
;    (fprintf FormFH "MENUBUTTON \"Local Help\" 16 3\n")
;    (fprintf FormFH "ENDFIELD\n")
;    (fprintf FormFH "\n")
    ;end of additional-help group
    (fprintf FormFH "ENDGROUP\n")
    (fprintf FormFH "\n")
    ;---------------------------------------------------------------------------
    ; help folders group
    (fprintf FormFH "GROUP \"Release Notes\" HelpNotesGroup\n")
    (fprintf FormFH "FLOC 49 23\n")
    (fprintf FormFH "FSIZE 61 10\n")
    (fprintf FormFH "\n")
    (fprintf FormFH "TEXT \"this is text...\" HelpTxtNotes\n")
    (fprintf FormFH "FLOC 50 25\n")
    (fprintf FormFH "FSIZE 59 8\n")
    (fprintf FormFH "ENDTEXT\n")
    (fprintf FormFH "\n")

    ;end of additional-help group
    (fprintf FormFH "ENDGROUP\n")
    (fprintf FormFH "\n")

    ;---------------------------------------------------------------------------
;    ;notes group
;    (fprintf FormFH "GROUP \"xxNotes\" HelpNotesGroup\n")
;    (fprintf FormFH "FLOC 49 12\n")
;    (fprintf FormFH "FSIZE 61 11\n")
;    (fprintf FormFH "\n")
;    (fprintf FormFH "TEXT \"this is text...\" HelpTxtNotes\n")
;    (fprintf FormFH "FLOC 50 25\n")
;    (fprintf FormFH "FSIZE 45 7\n")
;    (fprintf FormFH "OPTIONS BORDER\n")
;    (fprintf FormFH "ENDTEXT\n")
;    (fprintf FormFH "\n")
;    ;end of notes group
;    (fprintf FormFH "ENDGROUP\n")
;    (fprintf FormFH "\n")


    ;---------------------------------------------------------------------------
    ;end of help tab
    (fprintf FormFH "ENDTAB\n")
    (fprintf FormFH "\n")

    ;--------------------------------------------------------------------------------
    ;end of tab set
    (fprintf FormFH "ENDTABSET\n")

;********************************************************************************
    ;--- Operations Group -----------------------------------------------------------
    (fprintf FormFH "GROUP \"\" OperationsGroup\n")
    (fprintf FormFH "FLOC 0 35\n")
    (fprintf FormFH "FSIZE 111 7\n")
    (fprintf FormFH "\n")
    ;show all selected
;    (fprintf FormFH "FIELD OpShowSelected\n")
;    (fprintf FormFH "FLOC 1 37\n")
;    (fprintf FormFH "MENUBUTTON \"Show All Selected\" 20 2\n")
;    (fprintf FormFH "ENDFIELD\n")
;    (fprintf FormFH "\n")
    ;delete selected
    (fprintf FormFH "FIELD OpDeleteSelected\n")
    (fprintf FormFH "FLOC 1 39\n")
    (fprintf FormFH "MENUBUTTON \"Delete Selected\" 20 3\n")
    (fprintf FormFH "ENDFIELD\n")
    (fprintf FormFH "\n")
    ; problem message text
    (fprintf FormFH "TEXT \"\" ProblemTxt\n")
    (fprintf FormFH "FLOC 22 37\n")
    (fprintf FormFH "FSIZE 74 5\n")
    (fprintf FormFH "OPTIONS BORDER\n")
    (fprintf FormFH "ENDTEXT\n")
;JCR-MARK : put help button down here where the test button was
;    ; test button
;    (fprintf FormFH "FIELD OpTestButton\n")
;    (fprintf FormFH "FLOC 1 40\n")
;    (fprintf FormFH "MENUBUTTON \"Test\" 10 2\n")
;    (fprintf FormFH "ENDFIELD\n")
;    (fprintf FormFH "\n")
;JCR-MARK: Old Help button
;    ; old help button
;    (fprintf FormFH "FIELD OpHelpButton\n")
;    (fprintf FormFH "FLOC 98 0\n")
;    (fprintf FormFH "MENUBUTTON \"Help\" 12 3\n")
;    (fprintf FormFH "ENDFIELD\n")
;    (fprintf FormFH "\n")
    ;keep zoom checkbox
    (fprintf FormFH "FIELD OpKeepZoom\n")
    (fprintf FormFH "FLOC 97 37\n")
    (fprintf FormFH "CHECKLIST \"Keep Zoom\"\n")
    (fprintf FormFH "ENDFIELD\n")
    ;close button
    (fprintf FormFH "FIELD OpCloseButton\n")
    (fprintf FormFH "FLOC 97 39\n")
    (fprintf FormFH "MENUBUTTON \"Close\" 12 3\n")
    (fprintf FormFH "ENDFIELD\n")
    (fprintf FormFH "\n")
    ;end operations group
    (fprintf FormFH "ENDGROUP\n")
    (fprintf FormFH "\n")

;    ;--- Auto Resize Flex -----------------------------------------------------------
;    (fprintf FormFH "FLEX FilterGroup 0 0 1 1\n")
;    (fprintf FormFH "FLEX FilterType 0 0 1 1\n")
;    (fprintf FormFH "FLEX GridGroup 0 0 1 1\n")
;    (fprintf FormFH "FLEX GridField 0 0 1 1\n")
;    (fprintf FormFH "FLEXMODE edgegravity\n")

;VSelectRangeLoVal
;VSelectRangeToTxt
;VSelectRangeHiVal
;VSelectRangeOnBut
;VSelectRangeUnBut
;VSelectListsOnBut
;VSelectListsUnBut

;OpDeleteSelected
;OpDeleteAllDRC
;OpTestButton
;OpCloseButton
;OpKeepZoom

    (fprintf FormFH "ENDTILE\n")
    (fprintf FormFH "\n")
    (fprintf FormFH "ENDFORM\n"))
  ; end of big unless (and *)
    (fprintf DbugFH "\nERROR: DT_destub_form_write() - Failed On Form File Writing\n")
    (return nil))
  (unless (close FormFH)
    (fprintf DbugFH "\nERROR: DT_destub_form_write() - File close failed on Form File\n")
    (return nil))
  (setq FormFH 'unbound)
  (return (axlFormCreate (gensym) ArgFormFileName '( "msglines" 3 "E" "inner" ) 'DT_destub_form_callback nil))
;  ;for non=blocking / stand-alone
;  (return (axlFormCreate (gensym) ArgFormFileName '( "msglines" 3 "E" "inner" ) 'DT_destub_form_callback t))
));end-PROG_and_PROCEDURE DT_destub_form_write()

;*******************************************************************************
;
(procedure (DT_destub_form_init)
(prog (DMSG MsgStr )
  (setq DTD nil)
  (setq DTN "(DT_destub_form_init)")
  (when DTD (printf "\nSTATUS: %s \n" DTN))
  (setq DMSG nil) ; debug printing
  (when DMSG (fprintf DbugFH "\n\n%s\n%s\nFUNCTION: DT_destub_form_init Form Structure\n\n" RG_t_LINE1 RG_t_LINE2))
  (setq MsgStr " Please set the \"Permanent Highlght\" color to dark gray and \"Temp\n Highlight\" color to something bright through the Allegro menu\n Display->Colors/Visibility then the in \"Group\" dropdown pick \"Display\"")
  (axlFormSetField RG_g_FORM "ProblemTxt" MsgStr)

  ;--- QuickHelp Tab ----------------------------------------------------------------
  (setq MsgStr " For the visualization (problem zooming) to make it easy to spot the\n exact problem, you will need to adjust to your \"Highlighting\" colors.\n\n  (1) From the Allegro menu item \"Display\" select \"Colors/Visibility\".\n  (2) In the \"Group\" dropdown box at the top, select \"Display\".\n  (3) Set the \"Temporary Highlight\" color to a bright pink color.\n  (4) Set the \"Permanent Highlight\" color to a very dark gray.\n  (5) Click the \"Apply\" button, then click the \"OK\" button.")
  (axlFormSetField RG_g_FORM "HelpTxt" MsgStr)
  (axlFormColorize RG_g_FORM "HelpTxt" 'background 'white)

  (axlFormColorize RG_g_FORM "HelpProgram0" 'background 'white)
  (axlFormColorize RG_g_FORM "HelpProgram1" 'background 'white)
  (axlFormColorize RG_g_FORM "HelpVersion0" 'background 'white)
  (axlFormColorize RG_g_FORM "HelpVersion1" 'background 'white)
  (axlFormColorize RG_g_FORM "HelpAuthors0" 'background 'white)
  (axlFormColorize RG_g_FORM "HelpAuthors1" 'background 'white)
  (axlFormColorize RG_g_FORM "HelpContact0" 'background 'white)
  (axlFormColorize RG_g_FORM "HelpContact1" 'background 'white)
  (axlFormColorize RG_g_FORM "HelpCredits0" 'background 'white)
  (axlFormColorize RG_g_FORM "HelpCredits1" 'background 'white)

  (axlFormSetField RG_g_FORM "HelpProgram1" RG_t_HelpProgram)
  (axlFormSetField RG_g_FORM "HelpVersion1" RG_t_HelpVersion)
  (axlFormSetField RG_g_FORM "HelpAuthors1" RG_t_HelpAuthors)
  (axlFormSetField RG_g_FORM "HelpContact1" RG_t_HelpContact)
  (axlFormSetField RG_g_FORM "HelpCredits1" RG_t_HelpCredits)

  ; Additional Help Warning
  (setq MsgStr " You are using a program created to\n DELETE problems from your design, so\n please read all the documentation.")
  (axlFormSetField RG_g_FORM "HelpTxtAdd" MsgStr)
  (axlFormColorize RG_g_FORM "HelpTxtAdd" 'background 'red)

  ; QuickHelp Notes
  (setq MsgStr "There is a small and harmless bug in the handling of the interactive image changes as you click on various items in the tree-view on the left side of the \"Display\" tab. It is due to the fact that I haven't had a chance to completely implement the code to do parent image changes.")
  (axlFormSetField RG_g_FORM "HelpTxtNotes" MsgStr)

  ;--- Settings Tab ----------------------------------------------------------------
  (axlFormSetField RG_g_FORM "SetsUnits" "mils")
  (axlFormSetField RG_g_FORM "SetsViaUnder" t)
;  (axlFormColorize RG_g_FORM "SetsViaUnder" 'background 'blue)
;  (axlFormColorize RG_g_FORM "SetsViaUnder" 'text 'white)
  (axlFormSetField RG_g_FORM "SetsViaFanoutVal" 125)
  (axlFormSetField RG_g_FORM "SetsViaMinPadVal" 6)

  (axlFormSetFieldEditable RG_g_FORM "SetsFanoutGroup" nil)             ;disabled
  (axlFormSetFieldEditable RG_g_FORM "SetsViaFanoutTxt1" nil)
  (axlFormSetFieldEditable RG_g_FORM "SetsViaFanoutTxt2" nil)
  (axlFormSetFieldEditable RG_g_FORM "SetsViaFanoutVal" nil)
  (axlFormSetFieldEditable RG_g_FORM "SetsViaMinPadTxt1" nil)
  (axlFormSetFieldEditable RG_g_FORM "SetsViaMinPadTxt2" nil)
  (axlFormSetFieldEditable RG_g_FORM "SetsViaMinPadVal" nil)
  (axlFormSetFieldEditable RG_g_FORM "SetsUnits" nil)
  (axlFormSetFieldEditable RG_g_FORM "SetsViaUnder" nil)
  (axlFormSetFieldEditable RG_g_FORM "SetsTypeGroup" nil)
  (axlFormSetFieldEditable RG_g_FORM "SetsTypeAllButton" nil)
  (axlFormSetFieldEditable RG_g_FORM "SetsTypeNoneButton" nil)
  (axlFormSetFieldEditable RG_g_FORM "SetsTypeCheckCHAINS" nil)
  (axlFormSetFieldEditable RG_g_FORM "SetsTypeCheckNETS" nil)
  (axlFormSetFieldEditable RG_g_FORM "SetsTypeCheckBRANCHES" nil)
  (axlFormSetFieldEditable RG_g_FORM "SetsTypeCheckPATHS" nil)
  (axlFormSetFieldEditable RG_g_FORM "SetsTypeCheckPINS" nil)
  (axlFormSetFieldEditable RG_g_FORM "SetsTypeCheckSHAPES" nil)
  (axlFormSetFieldEditable RG_g_FORM "SetsTypeCheckVIAS" nil)
  (axlFormSetFieldEditable RG_g_FORM "SetsPropGroup" nil)
  (axlFormSetFieldEditable RG_g_FORM "SetsPropAllButton" nil)
  (axlFormSetFieldEditable RG_g_FORM "SetsPropNoneButton" nil)
  (axlFormSetFieldEditable RG_g_FORM "SetsPropCheckDT_FANOUT" nil)
  (axlFormSetFieldEditable RG_g_FORM "SetsPropCheckDT_IGNORE" nil)
  (axlFormSetFieldEditable RG_g_FORM "SetsPropCheckDT_UNUSED" nil)
  (axlFormSetFieldEditable RG_g_FORM "SetsPropCheckDT_NOCONN" nil)
  (axlFormSetFieldEditable RG_g_FORM "SetsSetGetGroup" nil)
  (axlFormSetFieldEditable RG_g_FORM "SetsGetFiltersButton" nil)
  (axlFormSetFieldEditable RG_g_FORM "SetsSetFiltersButton" nil)
  (axlFormSetFieldEditable RG_g_FORM "SetsSaveDefButton" nil)
  (axlFormSetFieldEditable RG_g_FORM "SetsLoadDefButton" nil)

  ;--- Filters Tab ----------------------------------------------------------------
  ; set default view for nets and layers grids
  (setq RGlt_NETS_LIST (sort RGlt_NETS_LIST nil))             ; sort the net names
  (setq RGlt_NETS_LIST (cons "No Nets" RGlt_NETS_LIST))       ; add special "no nets"
  (setq RGlt_LAYS_LIST (cons "No Layers" RGlt_LAYS_LIST))     ; add special "no nets"
  (DT_destub_filter_init RG_g_FORM "FiltNetsGrid" RGlt_NETS_LIST)  ; net name filter grid
  (DT_destub_filter_init RG_g_FORM "FiltLaysGrid" RGlt_LAYS_LIST)  ; layer name filter grid
;__FIXME__ Disabled the Filter Save Settings Button
  (axlFormSetFieldEditable RG_g_FORM "FiltSaveDefaultButton" nil)           ;disabled
  ; set default view for types
;__FIXME__ Chains Type Disabled
;  (axlFormSetField RG_g_FORM "FiltTypeCheckCHAINS" nil)                     ;disabled
;  (axlFormSetFieldEditable RG_g_FORM "FiltTypeCheckCHAINS" nil)             ;disabled
  (axlFormSetField RG_g_FORM "FiltTypeCheckCHAINS" t)
  (axlFormColorize RG_g_FORM "FiltTypeCheckCHAINS" 'background 'blue)
  (axlFormColorize RG_g_FORM "FiltTypeCheckCHAINS" 'text 'white)
  (axlFormSetField RG_g_FORM "FiltTypeCheckNETS" t)
  (axlFormColorize RG_g_FORM "FiltTypeCheckNETS" 'background 'blue)
  (axlFormColorize RG_g_FORM "FiltTypeCheckNETS" 'text 'white)
  (axlFormSetField RG_g_FORM "FiltTypeCheckBRANCHES" t)
  (axlFormColorize RG_g_FORM "FiltTypeCheckBRANCHES" 'background 'blue)
  (axlFormColorize RG_g_FORM "FiltTypeCheckBRANCHES" 'text 'white)
  (axlFormSetField RG_g_FORM "FiltTypeCheckPATHS" t)
  (axlFormColorize RG_g_FORM "FiltTypeCheckPATHS" 'background 'blue)
  (axlFormColorize RG_g_FORM "FiltTypeCheckPATHS" 'text 'white)
  (axlFormSetField RG_g_FORM "FiltTypeCheckPINS" nil)                       ;disabled
  (axlFormColorize RG_g_FORM "FiltTypeCheckPINS" 'background 'button)       ;disabled
  (axlFormColorize RG_g_FORM "FiltTypeCheckPINS" 'text 'black)              ;disabled
  (axlFormSetField RG_g_FORM "FiltTypeCheckSHAPES" t)
  (axlFormColorize RG_g_FORM "FiltTypeCheckSHAPES" 'background 'blue)
  (axlFormColorize RG_g_FORM "FiltTypeCheckSHAPES" 'text 'white)
  (axlFormSetField RG_g_FORM "FiltTypeCheckVIAS" t)
  (axlFormColorize RG_g_FORM "FiltTypeCheckVIAS" 'background 'blue)
  (axlFormColorize RG_g_FORM "FiltTypeCheckVIAS" 'text 'white)
  ; set default view for properties
  (axlFormSetField RG_g_FORM "FiltPropCheckDT_FANOUT" nil)                  ;disabled
  (axlFormColorize RG_g_FORM "FiltPropCheckDT_FANOUT" 'background 'button)  ;disabled
  (axlFormColorize RG_g_FORM "FiltPropCheckDT_FANOUT" 'text 'black)         ;disabled
  (axlFormSetField RG_g_FORM "FiltPropCheckDT_IGNORE" nil)                  ;disabled
  (axlFormColorize RG_g_FORM "FiltPropCheckDT_IGNORE" 'background 'button)  ;disabled
  (axlFormColorize RG_g_FORM "FiltPropCheckDT_IGNORE" 'text 'black)         ;disabled
  (axlFormSetField RG_g_FORM "FiltPropCheckDT_UNUSED" nil)                  ;disabled
  (axlFormColorize RG_g_FORM "FiltPropCheckDT_UNUSED" 'background 'button)  ;disabled
  (axlFormColorize RG_g_FORM "FiltPropCheckDT_UNUSED" 'text 'black)         ;disabled
  (axlFormSetField RG_g_FORM "FiltPropCheckDT_NOCONN" nil)                  ;disabled
  (axlFormColorize RG_g_FORM "FiltPropCheckDT_NOCONN" 'background 'button)  ;disabled
  (axlFormColorize RG_g_FORM "FiltPropCheckDT_NOCONN" 'text 'black)         ;disabled
  ; set default view for selected/checked
  (axlFormSetField RG_g_FORM "FiltShowSelected" t)
  (axlFormColorize RG_g_FORM "FiltShowSelected" 'background 'blue)
  (axlFormColorize RG_g_FORM "FiltShowSelected" 'text 'white)
  (axlFormSetField RG_g_FORM "FiltShowUnselected" t)
  (axlFormColorize RG_g_FORM "FiltShowUnselected" 'background 'blue)
  (axlFormColorize RG_g_FORM "FiltShowUnselected" 'text 'white)
  ;--- Display Tab ----------------------------------------------------------------
  ;disable the decoration buttons
  (axlFormSetFieldEditable RG_g_FORM "dec0" nil)
  (axlFormSetFieldEditable RG_g_FORM "dec1" nil)
  (axlFormSetFieldEditable RG_g_FORM "dec2" nil)
  ; set limits for numeric row select boxes
  (axlFormSetFieldLimits RG_g_FORM "VSelectRangeLoVal" 0 0)
  (axlFormSetFieldLimits RG_g_FORM "VSelectRangeHiVal" 0 0)
  ; set default values/colors for Row Range/List Select
  (axlFormSetField RG_g_FORM "VSelectRangeLoVal" 0)
  (axlFormSetField RG_g_FORM "VSelectRangeHiVal" 0)
  (axlFormColorize RG_g_FORM "VSelectRangeLoVal" 'background 'blue)
  (axlFormColorize RG_g_FORM "VSelectRangeHiVal" 'background 'blue)
  (axlFormColorize RG_g_FORM "VSelectRangeLoVal" 'text 'white)
  (axlFormColorize RG_g_FORM "VSelectRangeHiVal" 'text 'white)
  
  (axlFormColorize RG_g_FORM "ProblemTxt" 'background 'yellow)

  ;--- Main Form / Always Visible ---------------------------------------------------
  ; set default button/action to close to prevent unexpected surprises
;  (axlFormColorize RG_g_FORM "OpHelpButton" 'background 'blue)
;  (axlFormColorize RG_g_FORM "OpHelpButton" 'text 'red)
  (axlFormDefaultButton   RG_g_FORM "OpCloseButton")
  (axlFormSetActiveField  RG_g_FORM "OpCloseButton")
  ; set the dummy button to be invisible -keeps TreeView from getting focus
  (axlFormSetFieldVisible RG_g_FORM "DumbButton" 0)

; __FIXME__ Set Auto Resize for form
;  (axlFormAutoResize RG_g_FORM)

  (return t)
));end-PROG_and_PROCEDURE   DT_destub_form_init()


;*******************************************************************************
;
(procedure (DT_destub_form_enable ArgEnable ArgGrid "gg")
(prog (LocEnable LocGrid)
  ; test argument and set local variable
  (if !(or {ArgEnable == nil} {ArgEnable == t})
  then
    (fprintf DbugFH "\n\nERROR: DT_destub_form_enable() - Can Not set LocEnable Variable\n\n")
    (return nil)
  else
    (setq LocEnable ArgEnable))
  ; test argument and set local variable
  (if !(or {ArgGrid == nil} {ArgGrid == t})
  then
    (fprintf DbugFH "\n\nERROR: DT_destub_form_grid() - Can Not set LocGrid Variable\n\n")
    (return nil)
  else
    (setq LocGrid ArgGrid))
  ; enable/disable form contents (boxes, buttons etc.)
  ; "Display" Tab
  (axlFormSetFieldEditable RG_g_FORM "Ztree" LocEnable)
  (axlFormSetFieldEditable RG_g_FORM "GridField" LocGrid)
  (axlFormSetFieldEditable RG_g_FORM "VSelectRangeGroup" LocEnable)
  (axlFormSetFieldEditable RG_g_FORM "VSelectRangeLoVal" LocEnable)
  (axlFormSetFieldEditable RG_g_FORM "VSelectRangeToTxt" LocEnable)
  (axlFormSetFieldEditable RG_g_FORM "VSelectRangeHiVal" LocEnable)
  (axlFormSetFieldEditable RG_g_FORM "VSelectRangeOnBut" LocEnable)
  (axlFormSetFieldEditable RG_g_FORM "VSelectRangeUnBut" LocEnable)
  (axlFormSetFieldEditable RG_g_FORM "VSelectListsGroup" LocEnable)
  (axlFormSetFieldEditable RG_g_FORM "VSelectListsOnBut" LocEnable)
  (axlFormSetFieldEditable RG_g_FORM "VSelectListsUnBut" LocEnable)
  ; "Filters" Tab

  ; "Help" Tab

  ;main form, always visible
  (axlFormSetFieldEditable RG_g_FORM "OpDeleteSelected" LocEnable)
  (axlFormSetFieldEditable RG_g_FORM "OpTestButton" LocEnable)
  (axlFormSetFieldEditable RG_g_FORM "OpCloseButton" LocEnable)
  (axlFormSetFieldEditable RG_g_FORM "OpKeepZoom" LocEnable)

  (return t)
));end-PROG_and_PROCEDURE   DT_destub_form_enable()

;*******************************************************************************
; FUNCTION: DT_destub_form_callback
;
(procedure (DT_destub_form_callback ArgRG_g_FORM "g")
(prog (DMSG Img ImgList LayPart ItemCons)
  (setq DMSG nil) ; debug printing
  (unless (ArgRG_g_FORM->doneState == 0)
    (fprintf DbugFH "\n\nERROR: DT_destub_form_callback() - Form not in \"done\" state.\n\n")
    (return nil))
  ;--------------------------------------------------------------------------------
  ; debug printing
  (when DMSG (fprintf DbugFH "\n\n%s\n%s\nFUNCTION: DT_destub_form_callback - ArgRG_g_FORM->?? BASE" RG_t_LINE1 RG_t_LINE2))
  (when DMSG (_DTL_UTILS_PrintProp DbugFH ArgRG_g_FORM))
  ;--------------------------------------------------------------------------------
  ; unset object highlighting, rats visibility and layer visibility
  (when RGld_LITE_OBJS (axlDehighlightObject RGld_LITE_OBJS nil)) ;uses "temp" color
  (when RGld_LITE_NETS (axlDehighlightObject RGld_LITE_NETS t))   ;uses "perm" color
  (when RG_d_LITE_RATS (axlRatsnestBlank RG_d_LITE_RATS))         ;uses "rats" color

  (when RGlt_LITE_LAYS
    (foreach LayPart RGlt_LITE_LAYS (axlVisibleLayer LayPart nil) (axlVisibleUpdate nil))
    (setq RGlt_LITE_LAYS nil))
  ;--------------------------------------------------------------------------------
  ; unset column sorting popup/highlighting back to normal
  (when RG_x_COL_SORT != nil
    (setq ArgList (list RG_x_COL_SORT nil))
    (DT_destub_ui_set_cb ?pSymLst RGls_SHOW_LIST)
    (axlUIWRedraw ArgRG_g_FORM)
    (axlFlushDisplay ArgRG_g_FORM)
    (setq RG_x_COL_SORT nil))
  ;--------------------------------------------------------------------------------
  ; The big case...
  (case ArgRG_g_FORM->curField
    ;--------------------------------------------------------------------------------
    ; Both the TreeView and Grid fields are more than a bit wonky regarding
    ; event models. At times they do not pick up single clicks when switching
    ; between the two. A set active field hack may do the trick...
    ("Ztree"
      (fprintf DbugFH "\n\nFUNCTION: DT_destub_form_callback - ArgRG_g_FORM->curField == \"ZTree\"\n")
;__FIXME__ Need to deal with parent down changes from the treeview...
;__FIXME__ Need to deal with child up changes from the treeview...
;__FIXME__ There's a bug with image flipping on good branches under nets...

        
      ; unset active tree item image
      (when (dtpr RGlx_LITE_TREE)
        (foreach TreeCons RGlx_LITE_TREE
          (setq TreeItem (car  TreeCons))
          (setq ImgList  (cadr TreeCons))
          (setq ImgList (mapcar '(lambda (Img) (Img - 1)) ImgList ))
          (axlFormTreeViewChangeImages RG_g_FORM "Ztree" TreeItem (car ImgList) (cadr ImgList) (caddr ImgList))
        )
;__FIXME__ this dbg print uses pSym before it is set; when destub finds nothing
; wrong (empty problem list) this causes and error when clicking on the
; (empty) tree items.
;
        (when DMSG (fprintf DbugFH "\nUNLITE_ITEM\nImgL: %L\nItem: %L" ImgList TreeItem))
        (when DMSG (drain DbugFH))
        (setq RGlx_LITE_TREE nil))
      ; set tree item image to active/highlight current
      (setq ImgList (axlFormTreeViewGetImages  RG_g_FORM "Ztree" ArgRG_g_FORM->curValueInt))
      (setq ImgList (mapcar '(lambda (Img) (Img + 1)) ImgList ))
      (axlFormTreeViewChangeImages RG_g_FORM "Ztree" ArgRG_g_FORM->curValueInt (car ImgList) (cadr ImgList) (caddr ImgList))
      (setq RGlx_LITE_TREE (list (list ArgRG_g_FORM->curValueInt ImgList)))
      (when DMSG (fprintf DbugFH "\nHILITE_ITEM\npSym: %L\nImgL: %L\nItem: %L" nil ImgList ArgRG_g_FORM->curValueInt))
      (when DMSG (drain DbugFH))
      ;set visibility
;      (axlFormTreeViewSet ArgRG_g_FORM "Ztree" 'TV_EXPAND ArgRG_g_FORM->curValueInt)
      (axlFormTreeViewSet RG_g_FORM "Ztree" 'TV_ENSUREVISIBLE ArgRG_g_FORM->curValueInt)
      (axlFormGridOptions ArgRG_g_FORM "GridField" 'deselectAll) ;unselect row
      ;--------------------------------------------------------------------------------
      ; Item is in the "skiped" items like top level folders
      (setq ItemCons nil)
      (when (setq ItemCons (assoc ArgRG_g_FORM->curValueInt RGsl_ITEM_SKIP))
        (axlFormGridOptions ArgRG_g_FORM "GridField" 'deselectAll) ;unselect row
;__FIXME__ Not currently using checkbox tree items on top level of tree
;        ;keep treeview checkbox disabled
;        (axlFormTreeViewSetSelectState ArgRG_g_FORM "Ztree" ArgRG_g_FORM->curValueInt 'TVSTATE_DISABLED)
      )
      ;--------------------------------------------------------------------------------
      ; Is Tree Item in the "Good Item" list?
      (setq ItemCons nil)
      (when (setq ItemCons (assoc ArgRG_g_FORM->curValueInt RGsl_ITEM_GOOD))
        (setq TreeItem (car ItemCons))
        (setq GoodDBID (cadr ItemCons))
        ;keep treeview checkbox disabled
        (axlFormTreeViewSetSelectState ArgRG_g_FORM "Ztree" ArgRG_g_FORM->curValueInt 'TVSTATE_DISABLED)

        ;hilight relevant object(s)
        (setq RGld_LITE_OBJS (list GoodDBID))
        (axlHighlightObject RGld_LITE_OBJS nil)
        (_DTL_UTILS_ZoomDBIDList RGld_LITE_OBJS RGtt_ZOOM[GoodDBID->objType])

        ;set user interface message for object
        (DT_destub_msg_get GoodDBID nil)

        ; make relevant layer(s) visible
        (setq RGlt_LITE_LAYS (DT_destub_lay_get GoodDBID))
        (when (dtpr RGlt_LITE_LAYS)
          (foreach LayName RGlt_LITE_LAYS
            (axlVisibleLayer LayName t)))
        ; show rats
        (if GoodDBID->otyp == "net"
        then
          (axlRatsnestDisplay (setq RG_d_LITE_RATS GoodDBID))
        else
          (axlRatsnestDisplay (setq RG_d_LITE_RATS GoodDBID->net))))
    ;--------------------------------------------------------------------------------
;__FIXME__ This should be an "else"
      ; Is Tree Item in the "Bad Item" list?
      (setq ItemCons nil)
      (when (setq ItemCons (assoc ArgRG_g_FORM->curValueInt RGsl_ITEM_BAD))
        (setq TreeItem (car ItemCons))
        (setq pSym (cadr ItemCons))
        (if {pSym->ndex > 0}  ;is the pSym listed in the rows? (unlisted == -1)
        then
;          (axlFormTreeViewSet ArgRG_g_FORM "Ztree" 'TV_EXPAND ArgRG_g_FORM->curValueInt)
          (when {ArgRG_g_FORM->treeViewSelState != -1} ;just selecting the item
            (if {(axlFormTreeViewGetSelectState ArgRG_g_FORM "Ztree" TreeItem) == 1}
            then
              (DT_destub_ui_set_cb ?pSymLst (list pSym) ?DoCheck t ?IsCheck t)
              (setq RGlx_LITE_TREE nil)   ;kill the tree image change for current
            else
              (DT_destub_ui_set_cb ?pSymLst (list pSym) ?DoCheck t ?IsCheck nil)
              (setq RGlx_LITE_TREE nil)))   ;kill the tree image change for current
;          (axlFormGridOptions ArgRG_g_FORM "GridField" 'goto pSym->ndex)
          (axlFormGridOptions ArgRG_g_FORM "GridField" 'select pSym->ndex)
          (DT_destub_current_set pSym ?SetItem t) ;use ?SetItem to prevent loop
        else
          (axlFormSetField RG_g_FORM "ProblemTxt" "Item Not Listed Due To Filter Settings")
          (axlFormTreeViewSetSelectState ArgRG_g_FORM "Ztree" 
              ArgRG_g_FORM->curValueInt 'TVSTATE_DISABLED)))
      (axlFormSetActiveField  RG_g_FORM "GridField"))
    ;--------------------------------------------------------------------------------
    ; start GRID callbacks
    ("GridField"
      (when DMSG (fprintf DbugFH "\nFUNCTION: DT_destub_form_callback - ArgRG_g_FORM->curField == \"GridField\"\n"))
      (case ArgRG_g_FORM->event
        ('rowselect
          (setq cell (axlFormGridNewCell))
          (putpropq cell 1 col)
          (putpropq cell ArgRG_g_FORM->row row)
          (setq cell (axlFormGridGetCell RG_g_FORM "GridField" cell))
          (DT_destub_current_set (evalstring cell->scriptLabel)))
        ('change
          (setq cell (axlFormGridNewCell))
          (putpropq cell ArgRG_g_FORM->col col)
          (putpropq cell ArgRG_g_FORM->row row)
          (setq cell (axlFormGridGetCell RG_g_FORM "GridField" cell))
          (when DMSG (fprintf DbugFH "NOTE: cell->?? GridField    change\n"))
;          (when DMSG (_DTL_UTILS_PrintProp DbugFH cell))
          (setq pSym (evalstring cell->scriptLabel))
          (case cell->col
            (1  ; Column #1 select/deselect checkbox
              (DT_destub_ui_set_cb ?pSymLst (list pSym) ?DoCheck t ?IsCheck cell->check)
              ;when just the row checkbox is clicked, rowselect fires first.
              (setq RGlx_LITE_TREE nil)   ;kill the tree image change for current
              (DT_destub_current_set pSym ?SetItem t)
;__FIXME__ Need to deal with TreeItem Parent Image Changes
              ;fix parent tree images
            )
            (6  ; Column #6 Layer ENUM
              (DT_destub_current_set pSym) ;set focus on object
              (setq TmpLayer (strcat "ETCH/" cell->value))
              (axlVisibleLayer TmpLayer t)
              (setq RGlt_LITE_LAYS (cons TmpLayer RGlt_LITE_LAYS))
;__NOFIX__ This messes up color priority
;              (axlDBControl 'activeLayer TmpLayer)
            )
            (7  ; Column #7 Property ENUM -mainly for viewing attached props
              (DT_destub_current_set pSym)))) ;set focus on object
        ('rightpopup
          (setq cell (axlFormGridNewCell))
          (if (or {ArgRG_g_FORM->col == 0} {ArgRG_g_FORM->col == 8})
          then (putpropq cell 1                 col)
          else (putpropq cell ArgRG_g_FORM->col col))
          (if ArgRG_g_FORM->row == 0
          then (putpropq cell 1 row)
          else (putpropq cell ArgRG_g_FORM->row row))
          (setq cell (axlFormGridGetCell RG_g_FORM "GridField" cell))
          (setq pSym (evalstring cell->scriptLabel))
          (when DMSG (fprintf DbugFH "NOTE: cell->?? GridField    rightpopup\n"))
;          (when DMSG (_DTL_UTILS_PrintProp DbugFH cell))

          (case ArgRG_g_FORM->curValue
            ("ColSortAsc"
              (setq ArgList (list cell->col t))
              (axlFormGridSetBatch ArgRG_g_FORM "GridField" `DT_destub_sort 'ArgList)
              (axlFormGridUpdate ArgRG_g_FORM "GridField"))
            ("ColSortDsc"
              (setq ArgList (list cell->col nil))
              (axlFormGridSetBatch ArgRG_g_FORM "GridField" `DT_destub_sort 'ArgList)
              (axlFormGridUpdate ArgRG_g_FORM "GridField"))
            ("ColSortCan"
              ;kind of useless...
            )
            ("RowShowElement"
              (setq pSym (evalstring cell->scriptLabel))
              (DT_destub_current_set pSym)
              (axlShowObject (car pSym->dbid))
              (when DMSG (fprintf DbugFH "\nFUNCTION: DT_destub_form_callback: Show Element Current\n")))
            ("RowSetDT_FANOUT"
              (setq pSym (evalstring cell->scriptLabel))
              (DT_destub_current_set pSym)
              (DT_destub_prop_set (list pSym) "DT_FANOUT" t))
            ("RowSetDT_IGNORE"
              (setq pSym (evalstring cell->scriptLabel))
              (DT_destub_current_set pSym)
              (DT_destub_prop_set (list pSym) "DT_IGNORE" t))
            ("RowGroupStart"
              (DT_destub_form_enable nil t)
              (setq RG_x_GROUP_START RG_x_GROUP_THIS)
              (setq RG_x_GROUP_END nil)
              (when DMSG (fprintf DbugFH "\nFUNCTION: DT_destub_form_callback: Start Temp Group\n"))
              (DT_destub_current_set pSym)) ;set focus on object
            ("RowGroupEnd"
              (setq RG_x_GROUP_END RG_x_GROUP_THIS)
              (when DMSG (fprintf DbugFH "\nFUNCTION: DT_destub_form_callback: End Temp Group\n"))
              (DT_destub_current_set pSym)) ;set focus on object
            ("RowGroupAdd"
              (DT_destub_form_enable nil t)
              (setq RG_x_GROUP_ADD t)
              (setq RGlx_GROUP_LIST (cons RG_x_GROUP_THIS RGlx_GROUP_LIST))
              (setq TmpList nil)
              (foreach pSym RGls_SHOW_LIST
                (when (memq pSym->ndex RGlx_GROUP_LIST)
                  (setq TmpList (cons pSym TmpList))))
              (when DMSG (fprintf DbugFH "\nFUNCTION: DT_destub_form_callback: Add Row To Temp Group\n"))
              (DT_destub_ui_set_cb ?pSymLst TmpList ?DoYLite t))
            ("RowGroupCheck"
              (setq XpSymList nil)
              (setq DoUpdate nil)
              (foreach XpSym RGls_SHOW_LIST
                (when (memq XpSym->ndex RGlx_GROUP_LIST)
                  (setq XpSymList (cons XpSym XpSymList))
                  (if XpSym->ndex == pSym->ndex (setq DoUpdate t))))
              (when DMSG (fprintf DbugFH "\nFUNCTION: DT_destub_form_callback: Check Temp Group\n"))
              (DT_destub_ui_set_cb ?pSymLst XpSymList ?DoCheck t ?IsCheck t)
              (setq RG_x_GROUP_ADD nil)
              (setq RG_x_GROUP_END nil)
              (setq RG_x_GROUP_START nil)
              (setq RGlx_GROUP_LIST nil)
;__FIXME__ Need to deal with TreeItem Parent Image Changes
              ;Since we may not currently be on a row within the Temp Group when
              ; "Finish/Select is called this is necessary.
              (when DoUpdate
                (setq RGlx_LITE_TREE nil)   ;kill the tree image change for current
                (DT_destub_current_set pSym ?SetItem t)) ;use ?SetItem to prevent loop
              (DT_destub_form_enable t t))
            ("RowGroupUnCheck"
              (setq XpSymList nil)
              (setq DoUpdate nil)
              (foreach XpSym RGls_SHOW_LIST
                (when (memq XpSym->ndex RGlx_GROUP_LIST)
                  (setq XpSymList (cons XpSym XpSymList))
                  (if XpSym->ndex == pSym->ndex (setq DoUpdate t))))
              (when DMSG (fprintf DbugFH "\nFUNCTION: DT_destub_form_callback: Check Temp Group\n"))
              (DT_destub_ui_set_cb ?pSymLst XpSymList ?DoCheck t ?IsCheck nil)
              (setq RG_x_GROUP_ADD nil)
              (setq RG_x_GROUP_END nil)
              (setq RG_x_GROUP_START nil)
              (setq RGlx_GROUP_LIST nil)
;__FIXME__ Need to deal with TreeItem Parent Image Changes
              ;Since we may not currently be on a row within the Temp Group when
              ; "Finish/Select is called this is necessary.
              (when DoUpdate
                (setq RGlx_LITE_TREE nil)   ;kill the tree image change for current
                (DT_destub_current_set pSym ?SetItem t)) ;use ?SetItem to prevent loop
              (DT_destub_form_enable t t))
            ("RowGroupShowElement"
              (when DMSG (fprintf DbugFH "\nFUNCTION: DT_destub_form_callback: Show Element Temp Group\n"))
              (setq ShowList nil)
              (setq XpSymList nil)
              (setq DoUpdate nil)
              (foreach XpSym RGls_SHOW_LIST
                (when (memq XpSym->ndex RGlx_GROUP_LIST)
                  (setq ShowList (append ShowList XpSym->dbid))
                  (setq XpSymList (cons XpSym XpSymList))
                  (if XpSym->ndex == pSym->ndex (setq DoUpdate t))))
;              (DT_destub_current_set XpSymList)
              (if (dtpr ShowList) (axlShowObject ShowList))
              (DT_destub_ui_set_cb ?pSymLst XpSymList)  ;set rows to unhilighted
              (setq RG_x_GROUP_ADD nil)
              (setq RG_x_GROUP_END nil)
              (setq RG_x_GROUP_START nil)
              (setq RGlx_GROUP_LIST nil)
              (when DoUpdate
                (setq RGlx_LITE_TREE nil)   ;kill the tree image change for current
                (DT_destub_current_set pSym ?SetItem t))  ;set current row
              (DT_destub_form_enable t t))
            ("RowGroupSetDT_FANOUT"
              (setq XpSymList nil)
              (setq DoUpdate nil)
              (foreach XpSym RGls_SHOW_LIST
                (when (memq XpSym->ndex RGlx_GROUP_LIST)
                  (setq XpSymList (cons XpSym XpSymList))
                  (when (eq XpSym->ndex pSym->ndex) (setq DoUpdate t))))
;              (DT_destub_current_set pSym)
              (DT_destub_prop_set XpSymList "DT_FANOUT" t)
              (when DMSG (fprintf DbugFH "\nFUNCTION: DT_destub_form_callback: Set DT_FANOUT Temp Group\n"))
              (setq RG_x_GROUP_ADD nil)
              (setq RG_x_GROUP_END nil)
              (setq RG_x_GROUP_START nil)
              (setq RGlx_GROUP_LIST nil)
;__FIXME__ Need to deal with TreeItem Parent Image Changes
              ;Since we may not currently be on a row within the Temp Group when
              ; "Finish/Select is called this is necessary.
              (when DoUpdate
                (setq RGlx_LITE_TREE nil)   ;kill the tree image change for current
                (DT_destub_current_set pSym ?SetItem t))  ;use ?SetItem to prevent loop
              (DT_destub_form_enable t t))
            ("RowGroupSetDT_IGNORE"
              (setq XpSymList nil)
              (setq DoUpdate nil)
              (foreach XpSym RGls_SHOW_LIST
                (when (memq XpSym->ndex RGlx_GROUP_LIST)
                  (setq XpSymList (cons XpSym XpSymList))
                  (when (eq XpSym->ndex pSym->ndex) (setq DoUpdate t))))
              (when DMSG (fprintf DbugFH "\nFUNCTION: DT_destub_form_callback: Set DT_IGNORE Temp Group\n"))
;              (DT_destub_current_set pSym)
              (DT_destub_prop_set XpSymList "DT_IGNORE" t)
              (setq RG_x_GROUP_ADD nil)
              (setq RG_x_GROUP_END nil)
              (setq RG_x_GROUP_START nil)
              (setq RGlx_GROUP_LIST nil)
;__FIXME__ Need to deal with TreeItem Parent Image Changes
              ;Since we may not currently be on a row within the Temp Group when
              ; "Finish/Select is called this is necessary.
              (when DoUpdate
                (setq RGlx_LITE_TREE nil)   ;kill the tree image change for current
                (DT_destub_current_set pSym ?SetItem t)) ;use ?SetItem to prevent loop
              (DT_destub_form_enable t t))
            ("RowGroupCancel"
              (setq RG_x_GROUP_ADD nil)
              (setq RG_x_GROUP_END nil)
              (setq RG_x_GROUP_START nil)
              (setq pSymList nil)
              (foreach pSym RGls_SHOW_LIST
                (when (memq pSym->ndex RGlx_GROUP_LIST)
                  (setq pSymList (cons pSym pSymList))))
              (when DMSG (fprintf DbugFH "\nFUNCTION: DT_destub_form_callback: Cancel Temp Group\n"))
              (DT_destub_ui_set_cb ?pSymLst pSymList)
              (setq RGlx_GROUP_LIST nil)
              (DT_destub_form_enable t t))))
        ('rightpopupPre
          ;only for column headers
          (when (and {ArgRG_g_FORM->row == 0} {ArgRG_g_FORM->col > 0})
            (setq cell (axlFormGridNewCell))
            (putpropq cell ArgRG_g_FORM->row row)
            (putpropq cell ArgRG_g_FORM->col col)
            (setq cell (axlFormGridGetCell RG_g_FORM "GridField" cell))
            (when DMSG (fprintf DbugFH "NOTE: cell->?? GridField    rightpopupPre\n"))
            (when {ArgRG_g_FORM->row == 0}
              (DT_destub_ui_set_cb ?pSymLst RGls_SHOW_LIST ?DoXLite ArgRG_g_FORM->col)
              (setq RG_x_COL_SORT cell->col))))
        ('leftpopupPre
          (setq cell (axlFormGridNewCell))
          (putpropq cell ArgRG_g_FORM->row row)
          (putpropq cell ArgRG_g_FORM->col col)
          (setq cell (axlFormGridGetCell RG_g_FORM "GridField" cell))
          (when DMSG (fprintf DbugFH "NOTE: cell->?? GridField    leftpopupPre\n\n"))
          (when DMSG (_DTL_UTILS_PrintProp DbugFH cell))
          (when (or {cell->col == 6} {cell->col == 7})
            (setq ArgList (list cell))
            (axlFormGridSetBatch ArgRG_g_FORM "GridField" `DT_destub_popup_set 'ArgList)
            (axlFormGridUpdate ArgRG_g_FORM "GridField"))
          (DT_destub_current_set (evalstring cell->scriptLabel)))))
    ;end-case GridField
    ;---------------------------------------------------------------------------
    ("VSelectRangeOnBut"
      (when DMSG (fprintf DbugFH "\nFUNCTION: DT_destub_form_callback - ArgRG_g_FORM->curField == \"VSelectRangeOnBut\"\n"))
      (fprintf DbugFH "\n\nVSelectRangeLoVal: ")
      (pprint (axlFormGetField ArgRG_g_FORM "VSelectRangeLoVal") DbugFH)
      (fprintf DbugFH "\nVSelectRangeHiVal: ")
      (pprint (axlFormGetField ArgRG_g_FORM "VSelectRangeHiVal") DbugFH)
      (unless
        (and {(axlFormGetField ArgRG_g_FORM "VSelectRangeLoVal") >=1}
             {(axlFormGetField ArgRG_g_FORM "VSelectRangeLoVal") <= RG_x_SHOW_ROWS}
             {(axlFormGetField ArgRG_g_FORM "VSelectRangeHiVal") >=1}
             {(axlFormGetField ArgRG_g_FORM "VSelectRangeHiVal") <= RG_x_SHOW_ROWS})
        (axlUIWPrint ArgRG_g_FORM 'info0 "Problem: Range Values must be between 1 and %d" RG_x_SHOW_ROWS)
        (_DTL_UTILS_ForceMessage "You Must Fill In The Low and High Row Numbers")
        (return nil))
      (setq LoVal (axlFormGetField ArgRG_g_FORM "VSelectRangeLoVal"))
      (setq HiVal (axlFormGetField ArgRG_g_FORM "VSelectRangeHiVal"))
      (setq TmpList nil)
      (when DMSG (pprint RGls_SHOW_LIST DbugFH))
      (foreach pSym RGls_SHOW_LIST
        (when (and {pSym->ndex >= LoVal} {pSym->ndex <= HiVal})
          (setq TmpList (cons pSym TmpList))))
      (DT_destub_ui_set_cb ?pSymLst TmpList ?DoCheck t ?IsCheck t))
    ("VSelectRangeUnBut"
      (when DMSG (fprintf DbugFH "\nFUNCTION: DT_destub_form_callback - ArgRG_g_FORM->curField == \"VSelectRangeUnBut\"\n"))
      (fprintf DbugFH "\n\nVSelectRangeLoVal: ")
      (pprint (axlFormGetField ArgRG_g_FORM "VSelectRangeLoVal") DbugFH)
      (fprintf DbugFH "\nVSelectRangeHiVal: ")
      (pprint (axlFormGetField ArgRG_g_FORM "VSelectRangeHiVal") DbugFH)
      (unless
        (and {(axlFormGetField ArgRG_g_FORM "VSelectRangeLoVal") >=1}
             {(axlFormGetField ArgRG_g_FORM "VSelectRangeLoVal") <= RG_x_SHOW_ROWS}
             {(axlFormGetField ArgRG_g_FORM "VSelectRangeHiVal") >=1}
             {(axlFormGetField ArgRG_g_FORM "VSelectRangeHiVal") <= RG_x_SHOW_ROWS})
        (_DTL_UTILS_ForceMessage "You Must Fill In The Low and High Row Numbers")
        (return nil)
      )
      (setq LoVal (axlFormGetField ArgRG_g_FORM "VSelectRangeLoVal"))
      (setq HiVal (axlFormGetField ArgRG_g_FORM "VSelectRangeHiVal"))
      (setq TmpList nil)
      (foreach pSym RGls_SHOW_LIST
        (when (and {pSym->ndex >= LoVal} {pSym->ndex <= HiVal})
          (setq TmpList (cons pSym TmpList))))
      (DT_destub_ui_set_cb ?pSymLst TmpList ?DoCheck t ?IsCheck nil))
    ("VSelectListsOnBut"
      (when DMSG (fprintf DbugFH "\nFUNCTION: DT_destub_form_callback - ArgRG_g_FORM->curField == \"VSelectListOnBut\"\n"))
      (DT_destub_ui_set_cb ?pSymLst RGls_SHOW_LIST ?DoCheck t ?IsCheck t))
    ("VSelectListsUnBut"
      (when DMSG (fprintf DbugFH "\nFUNCTION: DT_destub_form_callback - ArgRG_g_FORM->curField == \"VSelectListsUnBut\"\n"))
      (DT_destub_ui_set_cb ?pSymLst RGls_SHOW_LIST ?DoCheck t ?IsCheck nil))
    ;--------------------------------------------------------------------------------
    ; Filter Tab Field Elements
    ("FiltNetsGrid"
      (when DMSG (fprintf DbugFH "\nFUNCTION: DT_destub_form_callback - ArgRG_g_FORM->curField == \"FiltNetsGrid\"\n"))
      (case ArgRG_g_FORM->event
        ('rowselect
          (setq cell (axlFormGridNewCell))
        )
        ('change
          (setq cell (axlFormGridNewCell))
          (putpropq cell ArgRG_g_FORM->col col)
          (putpropq cell ArgRG_g_FORM->row row)
          (setq cell (axlFormGridGetCell RG_g_FORM "FiltNetsGrid" cell))
          (DT_destub_filter_set_cb "FiltNetsGrid" RGlt_NETS_LIST
            (list ArgRG_g_FORM->row) ?DoCheck t ?IsCheck cell->check))))
    ("FiltNetsAllButton"
      (DT_destub_filter_set_cb "FiltNetsGrid" RGlt_NETS_LIST nil ?DoCheck t ?IsCheck t))
    ("FiltNetsWithButton"
      (DT_destub_filter_set_cb "FiltNetsGrid" RGlt_NETS_LIST nil ?DoCheck t ?IsCheck t)
      (DT_destub_filter_set_cb "FiltNetsGrid" RGlt_NETS_LIST (list 1) ?DoCheck t ?IsCheck nil))
    ("FiltNetsNoneButton"
      (DT_destub_filter_set_cb "FiltNetsGrid" RGlt_NETS_LIST nil ?DoCheck t ?IsCheck nil)
      (DT_destub_filter_set_cb "FiltNetsGrid" RGlt_NETS_LIST (list 1) ?DoCheck t ?IsCheck t))
    ("FiltLaysGrid"
      (when DMSG (fprintf DbugFH "\nFUNCTION: DT_destub_form_callback - ArgRG_g_FORM->curField == \"FiltLaysGrid\"\n"))
      (case ArgRG_g_FORM->event
        ('rowselect
          (setq cell (axlFormGridNewCell)))
        ('change
          (setq cell (axlFormGridNewCell))
          (putpropq cell ArgRG_g_FORM->col col)
          (putpropq cell ArgRG_g_FORM->row row)
          (setq cell (axlFormGridGetCell RG_g_FORM "FiltLaysGrid" cell))
          (DT_destub_filter_set_cb "FiltLaysGrid" RGlt_LAYS_LIST
            (list ArgRG_g_FORM->row) ?DoCheck t ?IsCheck cell->check))))
    ("FiltLaysAllButton"
      (DT_destub_filter_set_cb "FiltLaysGrid" RGlt_LAYS_LIST nil ?DoCheck t ?IsCheck t))
    ("FiltLaysWithButton"
      (DT_destub_filter_set_cb "FiltLaysGrid" RGlt_LAYS_LIST nil ?DoCheck t ?IsCheck t)
      (DT_destub_filter_set_cb "FiltLaysGrid" RGlt_LAYS_LIST (list 1) ?DoCheck t ?IsCheck nil))
    ("FiltLaysNoneButton"
      (DT_destub_filter_set_cb "FiltLaysGrid" RGlt_LAYS_LIST nil ?DoCheck t ?IsCheck nil)
      (DT_destub_filter_set_cb "FiltLaysGrid" RGlt_LAYS_LIST (list 1) ?DoCheck t ?IsCheck t))
    ("FiltTypeAllButton"
      (axlFormSetField RG_g_FORM "FiltTypeCheckCHAINS" t)
      (axlFormSetField RG_g_FORM "FiltTypeCheckNETS" t)
      (axlFormSetField RG_g_FORM "FiltTypeCheckBRANCHES" t)
      (axlFormSetField RG_g_FORM "FiltTypeCheckPATHS" t)
      (axlFormSetField RG_g_FORM "FiltTypeCheckPINS" t)
      (axlFormSetField RG_g_FORM "FiltTypeCheckSHAPES" t)
      (axlFormSetField RG_g_FORM "FiltTypeCheckVIAS" t)
      (axlFormColorize RG_g_FORM "FiltTypeCheckCHAINS" 'background 'blue)
      (axlFormColorize RG_g_FORM "FiltTypeCheckCHAINS" 'text 'white)
      (axlFormColorize RG_g_FORM "FiltTypeCheckNETS" 'background 'blue)
      (axlFormColorize RG_g_FORM "FiltTypeCheckNETS" 'text 'white)
      (axlFormColorize RG_g_FORM "FiltTypeCheckBRANCHES" 'background 'blue)
      (axlFormColorize RG_g_FORM "FiltTypeCheckBRANCHES" 'text 'white)
      (axlFormColorize RG_g_FORM "FiltTypeCheckPATHS" 'background 'blue)
      (axlFormColorize RG_g_FORM "FiltTypeCheckPATHS" 'text 'white)
      (axlFormColorize RG_g_FORM "FiltTypeCheckPINS" 'background 'blue)
      (axlFormColorize RG_g_FORM "FiltTypeCheckPINS" 'text 'white)
      (axlFormColorize RG_g_FORM "FiltTypeCheckSHAPES" 'background 'blue)
      (axlFormColorize RG_g_FORM "FiltTypeCheckSHAPES" 'text 'white)
      (axlFormColorize RG_g_FORM "FiltTypeCheckVIAS" 'background 'blue)
      (axlFormColorize RG_g_FORM "FiltTypeCheckVIAS" 'text 'white))
    ("FiltTypeNoneButton"
      (axlFormSetField RG_g_FORM "FiltTypeCheckCHAINS" nil)
      (axlFormSetField RG_g_FORM "FiltTypeCheckNETS" nil)
      (axlFormSetField RG_g_FORM "FiltTypeCheckBRANCHES" nil)
      (axlFormSetField RG_g_FORM "FiltTypeCheckPATHS" nil)
      (axlFormSetField RG_g_FORM "FiltTypeCheckPINS" nil)
      (axlFormSetField RG_g_FORM "FiltTypeCheckSHAPES" nil)
      (axlFormSetField RG_g_FORM "FiltTypeCheckVIAS" nil)
      (axlFormColorize RG_g_FORM "FiltTypeCheckCHAINS" 'background 'button)
      (axlFormColorize RG_g_FORM "FiltTypeCheckCHAINS" 'text 'black)
      (axlFormColorize RG_g_FORM "FiltTypeCheckNETS" 'background 'button)
      (axlFormColorize RG_g_FORM "FiltTypeCheckNETS" 'text 'black)
      (axlFormColorize RG_g_FORM "FiltTypeCheckBRANCHES" 'background 'button)
      (axlFormColorize RG_g_FORM "FiltTypeCheckBRANCHES" 'text 'black)
      (axlFormColorize RG_g_FORM "FiltTypeCheckPATHS" 'background 'button)
      (axlFormColorize RG_g_FORM "FiltTypeCheckPATHS" 'text 'black)
      (axlFormColorize RG_g_FORM "FiltTypeCheckPINS" 'background 'button)
      (axlFormColorize RG_g_FORM "FiltTypeCheckPINS" 'text 'black)
      (axlFormColorize RG_g_FORM "FiltTypeCheckSHAPES" 'background 'button)
      (axlFormColorize RG_g_FORM "FiltTypeCheckSHAPES" 'text 'black)
      (axlFormColorize RG_g_FORM "FiltTypeCheckVIAS" 'background 'button)
      (axlFormColorize RG_g_FORM "FiltTypeCheckVIAS" 'text 'black))
    ("FiltTypeCheckCHAINS"
      (if ArgRG_g_FORM->curValue
      then
        (axlFormColorize RG_g_FORM "FiltTypeCheckCHAINS" 'background 'blue)
        (axlFormColorize RG_g_FORM "FiltTypeCheckCHAINS" 'text 'white)
      else
        (axlFormColorize RG_g_FORM "FiltTypeCheckCHAINS" 'background 'button)
        (axlFormColorize RG_g_FORM "FiltTypeCheckCHAINS" 'text 'black)))
    ("FiltTypeCheckNETS"
      (if ArgRG_g_FORM->curValue
      then
        (axlFormColorize RG_g_FORM "FiltTypeCheckNETS" 'background 'blue)
        (axlFormColorize RG_g_FORM "FiltTypeCheckNETS" 'text 'white)
      else
        (axlFormColorize RG_g_FORM "FiltTypeCheckNETS" 'background 'button)
        (axlFormColorize RG_g_FORM "FiltTypeCheckNETS" 'text 'black)))
    ("FiltTypeCheckBRANCHES"
      (if ArgRG_g_FORM->curValue
      then
        (axlFormColorize RG_g_FORM "FiltTypeCheckBRANCHES" 'background 'blue)
        (axlFormColorize RG_g_FORM "FiltTypeCheckBRANCHES" 'text 'white)
      else
        (axlFormColorize RG_g_FORM "FiltTypeCheckBRANCHES" 'background 'button)
        (axlFormColorize RG_g_FORM "FiltTypeCheckBRANCHES" 'text 'black)))
    ("FiltTypeCheckPATHS"
      (if ArgRG_g_FORM->curValue
      then
        (axlFormColorize RG_g_FORM "FiltTypeCheckPATHS" 'background 'blue)
        (axlFormColorize RG_g_FORM "FiltTypeCheckPATHS" 'text 'white)
      else
        (axlFormColorize RG_g_FORM "FiltTypeCheckPATHS" 'background 'button)
        (axlFormColorize RG_g_FORM "FiltTypeCheckPATHS" 'text 'black)))
    ("FiltTypeCheckPINS"
      (if ArgRG_g_FORM->curValue
      then
        (axlFormColorize RG_g_FORM "FiltTypeCheckPINS" 'background 'blue)
        (axlFormColorize RG_g_FORM "FiltTypeCheckPINS" 'text 'white)
      else
        (axlFormColorize RG_g_FORM "FiltTypeCheckPINS" 'background 'button)
        (axlFormColorize RG_g_FORM "FiltTypeCheckPINS" 'text 'black)))
    ("FiltTypeCheckSHAPES"
      (if ArgRG_g_FORM->curValue
      then
        (axlFormColorize RG_g_FORM "FiltTypeCheckSHAPES" 'background 'blue)
        (axlFormColorize RG_g_FORM "FiltTypeCheckSHAPES" 'text 'white)
      else
        (axlFormColorize RG_g_FORM "FiltTypeCheckSHAPES" 'background 'button)
        (axlFormColorize RG_g_FORM "FiltTypeCheckSHAPES" 'text 'black)))
    ("FiltTypeCheckVIAS"
      (if ArgRG_g_FORM->curValue
      then
        (axlFormColorize RG_g_FORM "FiltTypeCheckVIAS" 'background 'blue)
        (axlFormColorize RG_g_FORM "FiltTypeCheckVIAS" 'text 'white)
      else
        (axlFormColorize RG_g_FORM "FiltTypeCheckVIAS" 'background 'button)
        (axlFormColorize RG_g_FORM "FiltTypeCheckVIAS" 'text 'black)))
    ("FiltPropAllButton"
      (axlFormSetField RG_g_FORM "FiltPropCheckDT_FANOUT" t)
      (axlFormSetField RG_g_FORM "FiltPropCheckDT_IGNORE" t)
;      (axlFormSetField RG_g_FORM "FiltPropCheckDT_UNUSED" t)
;      (axlFormSetField RG_g_FORM "FiltPropCheckDT_NOCONN" t)
      (axlFormColorize RG_g_FORM "FiltPropCheckDT_FANOUT" 'background 'blue)
      (axlFormColorize RG_g_FORM "FiltPropCheckDT_FANOUT" 'text 'white)
      (axlFormColorize RG_g_FORM "FiltPropCheckDT_IGNORE" 'background 'blue)
      (axlFormColorize RG_g_FORM "FiltPropCheckDT_IGNORE" 'text 'white)
;      (axlFormColorize RG_g_FORM "FiltPropCheckDT_UNUSED" 'background 'blue)
;      (axlFormColorize RG_g_FORM "FiltPropCheckDT_UNUSED" 'text 'white)
;      (axlFormColorize RG_g_FORM "FiltPropCheckDT_NOCONN" 'background 'blue)
;      (axlFormColorize RG_g_FORM "FiltPropCheckDT_NOCONN" 'text 'white)
    )
    ("FiltPropNoneButton"
      (axlFormSetField RG_g_FORM "FiltPropCheckDT_FANOUT" nil)
      (axlFormSetField RG_g_FORM "FiltPropCheckDT_IGNORE" nil)
;      (axlFormSetField RG_g_FORM "FiltPropCheckDT_UNUSED" nil)
;      (axlFormSetField RG_g_FORM "FiltPropCheckDT_NOCONN" nil)
      (axlFormColorize RG_g_FORM "FiltPropCheckDT_FANOUT" 'background 'button)
      (axlFormColorize RG_g_FORM "FiltPropCheckDT_FANOUT" 'text 'black)
      (axlFormColorize RG_g_FORM "FiltPropCheckDT_IGNORE" 'background 'button)
      (axlFormColorize RG_g_FORM "FiltPropCheckDT_IGNORE" 'text 'black)
;      (axlFormColorize RG_g_FORM "FiltPropCheckDT_UNUSED" 'background 'button)
;      (axlFormColorize RG_g_FORM "FiltPropCheckDT_UNUSED" 'text 'black)
;      (axlFormColorize RG_g_FORM "FiltPropCheckDT_NOCONN" 'background 'button)
;      (axlFormColorize RG_g_FORM "FiltPropCheckDT_NOCONN" 'text 'black)
    )
    ("FiltPropCheckDT_FANOUT"
      (if ArgRG_g_FORM->curValue
      then
        (axlFormColorize RG_g_FORM "FiltPropCheckDT_FANOUT" 'background 'blue)
        (axlFormColorize RG_g_FORM "FiltPropCheckDT_FANOUT" 'text 'white)
      else
        (axlFormColorize RG_g_FORM "FiltPropCheckDT_FANOUT" 'background 'button)
        (axlFormColorize RG_g_FORM "FiltPropCheckDT_FANOUT" 'text 'black)))
    ("FiltPropCheckDT_IGNORE"
      (if ArgRG_g_FORM->curValue
      then
        (axlFormColorize RG_g_FORM "FiltPropCheckDT_IGNORE" 'background 'blue)
        (axlFormColorize RG_g_FORM "FiltPropCheckDT_IGNORE" 'text 'white)
      else
        (axlFormColorize RG_g_FORM "FiltPropCheckDT_IGNORE" 'background 'button)
        (axlFormColorize RG_g_FORM "FiltPropCheckDT_IGNORE" 'text 'black)))
    ("FiltPropCheckDT_UNUSED"
      (if ArgRG_g_FORM->curValue
      then
        (axlFormColorize RG_g_FORM "FiltPropCheckDT_UNUSED" 'background 'blue)
        (axlFormColorize RG_g_FORM "FiltPropCheckDT_UNUSED" 'text 'white)
      else
        (axlFormColorize RG_g_FORM "FiltPropCheckDT_UNUSED" 'background 'button)
        (axlFormColorize RG_g_FORM "FiltPropCheckDT_UNUSED" 'text 'black)))
    ("FiltPropCheckDT_NOCONN"
      (if ArgRG_g_FORM->curValue
      then
        (axlFormColorize RG_g_FORM "FiltPropCheckDT_NOCONN" 'background 'blue)
        (axlFormColorize RG_g_FORM "FiltPropCheckDT_NOCONN" 'text 'white)
      else
        (axlFormColorize RG_g_FORM "FiltPropCheckDT_NOCONN" 'background 'button)
        (axlFormColorize RG_g_FORM "FiltPropCheckDT_NOCONN" 'text 'black)))
    ("FiltShowSelected"
      (if ArgRG_g_FORM->curValue
      then
        (axlFormColorize RG_g_FORM "FiltShowSelected" 'background 'blue)
        (axlFormColorize RG_g_FORM "FiltShowSelected" 'text 'white)
      else
        (axlFormColorize RG_g_FORM "FiltShowSelected" 'background 'button)
        (axlFormColorize RG_g_FORM "FiltShowSelected" 'text 'black)))
    ("FiltShowUnselected"
      (if ArgRG_g_FORM->curValue
      then
        (axlFormColorize RG_g_FORM "FiltShowUnselected" 'background 'blue)
        (axlFormColorize RG_g_FORM "FiltShowUnselected" 'text 'white)
      else
        (axlFormColorize RG_g_FORM "FiltShowUnselected" 'background 'button)
        (axlFormColorize RG_g_FORM "FiltShowUnselected" 'text 'black)))
    ("FiltShowEverythingButton"
      ;nets
      (DT_destub_filter_set_cb "FiltNetsGrid" RGlt_NETS_LIST nil ?DoCheck t ?IsCheck t)
      ;lays
      (DT_destub_filter_set_cb "FiltLaysGrid" RGlt_LAYS_LIST nil ?DoCheck t ?IsCheck t)
      ;prop
      (axlFormSetField RG_g_FORM "FiltTypeCheckCHAINS" t)
      (axlFormSetField RG_g_FORM "FiltTypeCheckNETS" t)
      (axlFormSetField RG_g_FORM "FiltTypeCheckBRANCHES" t)
      (axlFormSetField RG_g_FORM "FiltTypeCheckPATHS" t)
      (axlFormSetField RG_g_FORM "FiltTypeCheckPINS" t)
      (axlFormSetField RG_g_FORM "FiltTypeCheckSHAPES" t)
      (axlFormSetField RG_g_FORM "FiltTypeCheckVIAS" t)
      (axlFormColorize RG_g_FORM "FiltTypeCheckCHAINS" 'background 'blue)
      (axlFormColorize RG_g_FORM "FiltTypeCheckCHAINS" 'text 'white)
      (axlFormColorize RG_g_FORM "FiltTypeCheckNETS" 'background 'blue)
      (axlFormColorize RG_g_FORM "FiltTypeCheckNETS" 'text 'white)
      (axlFormColorize RG_g_FORM "FiltTypeCheckBRANCHES" 'background 'blue)
      (axlFormColorize RG_g_FORM "FiltTypeCheckBRANCHES" 'text 'white)
      (axlFormColorize RG_g_FORM "FiltTypeCheckPATHS" 'background 'blue)
      (axlFormColorize RG_g_FORM "FiltTypeCheckPATHS" 'text 'white)
      (axlFormColorize RG_g_FORM "FiltTypeCheckPINS" 'background 'blue)
      (axlFormColorize RG_g_FORM "FiltTypeCheckPINS" 'text 'white)
      (axlFormColorize RG_g_FORM "FiltTypeCheckSHAPES" 'background 'blue)
      (axlFormColorize RG_g_FORM "FiltTypeCheckSHAPES" 'text 'white)
      (axlFormColorize RG_g_FORM "FiltTypeCheckVIAS" 'background 'blue)
      (axlFormColorize RG_g_FORM "FiltTypeCheckVIAS" 'text 'white)
      ;type
      (axlFormSetField RG_g_FORM "FiltPropCheckDT_FANOUT" t)
      (axlFormSetField RG_g_FORM "FiltPropCheckDT_IGNORE" t)
;      (axlFormSetField RG_g_FORM "FiltPropCheckDT_UNUSED" t)
;      (axlFormSetField RG_g_FORM "FiltPropCheckDT_NOCONN" t)
      (axlFormColorize RG_g_FORM "FiltPropCheckDT_FANOUT" 'background 'blue)
      (axlFormColorize RG_g_FORM "FiltPropCheckDT_FANOUT" 'text 'white)
      (axlFormColorize RG_g_FORM "FiltPropCheckDT_IGNORE" 'background 'blue)
      (axlFormColorize RG_g_FORM "FiltPropCheckDT_IGNORE" 'text 'white)
;      (axlFormColorize RG_g_FORM "FiltPropCheckDT_UNUSED" 'background 'blue)
;      (axlFormColorize RG_g_FORM "FiltPropCheckDT_UNUSED" 'text 'white)
;      (axlFormColorize RG_g_FORM "FiltPropCheckDT_NOCONN" 'background 'blue)
;      (axlFormColorize RG_g_FORM "FiltPropCheckDT_NOCONN" 'text 'white)
      ;selected
      (axlFormSetField RG_g_FORM "FiltShowSelected" t)
      (axlFormSetField RG_g_FORM "FiltShowUnselected" t)
      (axlFormColorize RG_g_FORM "FiltShowSelected" 'background 'blue)
      (axlFormColorize RG_g_FORM "FiltShowSelected" 'text 'white)
      (axlFormColorize RG_g_FORM "FiltShowUnselected" 'background 'blue)
      (axlFormColorize RG_g_FORM "FiltShowUnselected" 'text 'white))
    ("FiltShowSelectedButton"
      ;nets
      (DT_destub_filter_set_cb "FiltNetsGrid" RGlt_NETS_LIST nil ?DoCheck t ?IsCheck t)
      ;lays
      (DT_destub_filter_set_cb "FiltLaysGrid" RGlt_LAYS_LIST nil ?DoCheck t ?IsCheck t)
      ;prop
      (axlFormSetField RG_g_FORM "FiltTypeCheckCHAINS" t)
      (axlFormSetField RG_g_FORM "FiltTypeCheckNETS" t)
      (axlFormSetField RG_g_FORM "FiltTypeCheckBRANCHES" t)
      (axlFormSetField RG_g_FORM "FiltTypeCheckPATHS" t)
      (axlFormSetField RG_g_FORM "FiltTypeCheckPINS" t)
      (axlFormSetField RG_g_FORM "FiltTypeCheckSHAPES" t)
      (axlFormSetField RG_g_FORM "FiltTypeCheckVIAS" t)
      (axlFormColorize RG_g_FORM "FiltTypeCheckCHAINS" 'background 'blue)
      (axlFormColorize RG_g_FORM "FiltTypeCheckCHAINS" 'text 'white)
      (axlFormColorize RG_g_FORM "FiltTypeCheckNETS" 'background 'blue)
      (axlFormColorize RG_g_FORM "FiltTypeCheckNETS" 'text 'white)
      (axlFormColorize RG_g_FORM "FiltTypeCheckBRANCHES" 'background 'blue)
      (axlFormColorize RG_g_FORM "FiltTypeCheckBRANCHES" 'text 'white)
      (axlFormColorize RG_g_FORM "FiltTypeCheckPATHS" 'background 'blue)
      (axlFormColorize RG_g_FORM "FiltTypeCheckPATHS" 'text 'white)
      (axlFormColorize RG_g_FORM "FiltTypeCheckPINS" 'background 'blue)
      (axlFormColorize RG_g_FORM "FiltTypeCheckPINS" 'text 'white)
      (axlFormColorize RG_g_FORM "FiltTypeCheckSHAPES" 'background 'blue)
      (axlFormColorize RG_g_FORM "FiltTypeCheckSHAPES" 'text 'white)
      (axlFormColorize RG_g_FORM "FiltTypeCheckVIAS" 'background 'blue)
      (axlFormColorize RG_g_FORM "FiltTypeCheckVIAS" 'text 'white)
      ;type
      (axlFormSetField RG_g_FORM "FiltPropCheckDT_FANOUT" t)
      (axlFormSetField RG_g_FORM "FiltPropCheckDT_IGNORE" t)
;      (axlFormSetField RG_g_FORM "FiltPropCheckDT_UNUSED" t)
;      (axlFormSetField RG_g_FORM "FiltPropCheckDT_NOCONN" t)
      (axlFormColorize RG_g_FORM "FiltPropCheckDT_FANOUT" 'background 'blue)
      (axlFormColorize RG_g_FORM "FiltPropCheckDT_FANOUT" 'text 'white)
      (axlFormColorize RG_g_FORM "FiltPropCheckDT_IGNORE" 'background 'blue)
      (axlFormColorize RG_g_FORM "FiltPropCheckDT_IGNORE" 'text 'white)
;      (axlFormColorize RG_g_FORM "FiltPropCheckDT_UNUSED" 'background 'blue)
;      (axlFormColorize RG_g_FORM "FiltPropCheckDT_UNUSED" 'text 'white)
;      (axlFormColorize RG_g_FORM "FiltPropCheckDT_NOCONN" 'background 'blue)
;      (axlFormColorize RG_g_FORM "FiltPropCheckDT_NOCONN" 'text 'white)
      ;selected
      (axlFormSetField RG_g_FORM "FiltShowSelected" t)
      (axlFormSetField RG_g_FORM "FiltShowUnselected" nil)
      (axlFormColorize RG_g_FORM "FiltShowSelected" 'background 'blue)
      (axlFormColorize RG_g_FORM "FiltShowSelected" 'text 'white)
      (axlFormColorize RG_g_FORM "FiltShowUnselected" 'background 'button)
      (axlFormColorize RG_g_FORM "FiltShowUnselected" 'text 'black))
    ("FiltSaveDefaultButton"
    )
    ;--------------------------------------------------------------------------------
    ; The "Settings" tab stuff

    ;--------------------------------------------------------------------------------
    ; The "QuickHelp" tab stuff
;    ("HelpButtonLocal"
;      (when DMSG (fprintf DbugFH "\nFUNCTION: DT_destub_form_callback - ArgRG_g_FORM->curField == \"OpHelpButton\"\n"))
;      (axlHttp RG_t_HelpURLlocal))
    ("HelpButtonOnLine"
      (when DMSG (fprintf DbugFH "\nFUNCTION: DT_destub_form_callback - ArgRG_g_FORM->curField == \"OpHelpButton\"\n"))
      (axlHttp RG_t_HelpURLonline))
;JCR-MARK: tab switch
    ;--------------------------------------------------------------------------------
    ; Tab Switching
    ("FullTabSet"
      (when DMSG (fprintf DbugFH "\nFUNCTION: DT_destub_form_callback ArgRG_g_FORM->curField == \"FullTabSet\"\n"))
      ;unlite tree item
      (when (dtpr RGlx_LITE_TREE)
        (foreach TreeCons RGlx_LITE_TREE
          (setq TreeItem (car  TreeCons))
          (setq ImgList  (cadr TreeCons))
          (setq ImgList (mapcar '(lambda (Img) (Img - 1)) ImgList ))
          (axlFormTreeViewChangeImages RG_g_FORM "Ztree" TreeItem 
              (car ImgList) (cadr ImgList) (caddr ImgList)))
        (when DMSG (fprintf DbugFH "\nUNLITE_ITEM\nImgL: %L\nItem: %L\n" ImgList TreeItem))
        (setq RGlx_LITE_TREE nil))
      ;unselect row
      (axlFormGridOptions ArgRG_g_FORM "GridField" 'deselectAll)
      (case ArgRG_g_FORM->curValue
        ("Display"
          (axlFormSetFieldEditable RG_g_FORM "OpDeleteSelected" t)
          (axlFormSetFieldEditable RG_g_FORM "OpShowSelected" t)
          (DT_destub_filter_run)
          (when DMSG 
            (fprintf DbugFH "Change Tab To: \"Display\"\n") (drain DbugFH)))
        ("Filters"
          (axlFormSetField RG_g_FORM "ProblemTxt" "")
          (axlFormSetFieldEditable RG_g_FORM "OpDeleteSelected" nil)
          (axlFormSetFieldEditable RG_g_FORM "OpShowSelected" nil)
          (when DMSG 
            (fprintf DbugFH "Change Tab To: \"Filters\"\n") (drain DbugFH)))
        ("Settings"
          (axlFormSetField RG_g_FORM "ProblemTxt" "")
          (axlFormSetFieldEditable RG_g_FORM "OpDeleteSelected" nil)
          (axlFormSetFieldEditable RG_g_FORM "OpShowSelected" nil)
          (when DMSG 
            (fprintf DbugFH "Change Tab To: \"Settings\"\n") (drain DbugFH)))
        ("QuickHelp"
          (axlFormSetField RG_g_FORM "ProblemTxt" "")
          (axlFormSetFieldEditable RG_g_FORM "OpDeleteSelected" nil)
          (axlFormSetFieldEditable RG_g_FORM "OpShowSelected" nil)
          (when DMSG 
            (fprintf DbugFH "Change Tab To: \"QuickHelp\"\n") (drain DbugFH)))))
    ;--------------------------------------------------------------------------------
    ; Always visible (not on a tab)
    ("OpDeleteSelected"
      (when DMSG (fprintf DbugFH "\nFUNCTION: DT_destub_form_callback - ArgRG_g_FORM->curField == \"OpDeleteSelected\"\n"))
      (DT_destub_delete_checked))
;    ("OpHelpButton"
;      (when DMSG (fprintf DbugFH "\nFUNCTION: DT_destub_form_callback - ArgRG_g_FORM->curField == \"OpHelpButton\"\n"))
;      (axlHttp "http://www.cadence.com"))
    ("OpKeepZoom" ;checkbox
      (when DMSG (fprintf DbugFH "\nFUNCTION: DT_destub_form_callback - ArgRG_g_FORM->curField == \"OpKeepZoom\"\n"))
      (if ArgRG_g_FORM->curValue
      then (setq RG_b_REST_ZOOM nil)
      else (setq RG_b_REST_ZOOM t)))
    ("OpCloseButton"
      (when DMSG (fprintf DbugFH "\nFUNCTION: DT_destub_form_callback - ArgRG_g_FORM->curField == \"OpCloseButton\"\n"))
      (axlFormClose ArgRG_g_FORM))
    ("OpTestButton"
    )
  );end-case ArgRG_g_FORM->curField
  (return t)
));end-PROG_and_PROCEDURE   DT_destub_form_callback()

;*******************************************************************************
; Initialize/Reinitialize Filter Grid Columns and Rows
(procedure (DT_destub_filter_init RG_g_FORM FiltGrid NameList "gtl")
(let (DMSG ColStuct)
  (setq DMSG nil) ;debug printing
  ;clear entire grid
  (when (greaterp (axlVersion 'version) 14.2)
    (axlFormGridReset RG_g_FORM FiltGrid))
  ; Add Column-1 Check
  (setq ColStruct make_formGridCol())
  ColStruct->fieldType = 'CHECKITEM
  ColStruct->colWidth = 2
  ColStruct->align = 'center
  ColStruct->scriptLabel = ""
  (axlFormGridInsertCol RG_g_FORM FiltGrid ColStruct)
  ; Add Column-2 Name (net name or layer name)
  (setq ColStruct make_formGridCol())
  ColStruct->fieldType = 'TEXT
  ColStruct->colWidth = 28
  ColStruct->fieldLength = 127
  ColStruct->align = 'center
  ColStruct->scriptLabel = ""
  (axlFormGridInsertCol RG_g_FORM FiltGrid ColStruct)
  ; Enable Grid Events
  (axlFormGridEvents RG_g_FORM FiltGrid '(rowselect change))
  ; Add Rows
  (axlFormGridInsertRows RG_g_FORM FiltGrid 1 (length NameList)) ; add rows
  ; fill cells
  (DT_destub_filter_set_cb FiltGrid NameList nil ?DoCheck t ?IsCheck t)
));end-LET_and_PROCEDURE DT_destub_filter_init

;********************************************************************************
; Callback for setting filter net/layer name cells
(procedure (DT_destub_filter_set_cb
    FiltGrid        ; the form grid for either nets or layers
    NameList        ; list of net/layer names
    RowList         ; a list of rows numbers to modify (nil if all rows)
    @key
    (DoCheck nil)   ;Should we reset the check status?      t/nil
    (IsCheck nil)   ;the check status we should set it to   t/nil
    "tllgg"
  )
(let (DMSG ArgList RowName yrow)
  (setq DMSG nil) ; debug printing
  (when DMSG (fprintf DbugFH "\n\n%s\n%s\nFUNCTION: DT_destub_filter_set_cb\n" RG_t_LINE1 RG_t_LINE2))
  (when DMSG (fprintf DbugFH "NameList: %L\n" NameList))
  (when DMSG (fprintf DbugFH "IsCheck: %L\n" IsCheck))
  (when DMSG (drain DbugFH))

  (when (null RowList)
    (setq yrow 1)
    (foreach RowName NameList
      (setq RowList (cons yrow RowList))
      yrow++))

  (setq ArgList (list NameList RowList DoCheck IsCheck))
  (axlFormGridSetBatch RG_g_FORM FiltGrid `DT_destub_filter_set 'ArgList)
  (axlFormGridUpdate RG_g_FORM FiltGrid)
));end-LET_and_PROCEDURE DT_destub_filter_set_cb

;********************************************************************************
; Set Filter Grid Cells
(procedure (DT_destub_filter_set ArgList "l")
(prog (DMSG NameList RowList RowName cell yrow)
  (setq DMSG nil) ;debug printing
  (when DMSG (fprintf DbugFH "\n\n%s\n%s\nFUNCTION: DT_destub_filter_set\n" RG_t_LINE1 RG_t_LINE2))
  (setq NameList (nth 0 ArgList))
  (setq RowList (nth 1 ArgList))
  (setq DoCheck (nth 2 ArgList))
  (setq IsCheck (nth 3 ArgList))
  ; get a single cell for the grid, this will be reused for speed
  (setq cell (axlFormGridNewCell))
  (setq yrow 1) ; row counter
  (foreach RowName NameList
    (when (memq yrow RowList)
      (putpropq cell 1          col)            ; Column-1 Checkbox
      (putpropq cell yrow       row)
      (putpropq cell ""         scriptLabel)
      (putpropq cell nil        popup)
      (putpropq cell IsCheck    check)
      (putpropq cell nil        invisible)
      (putpropq cell nil        value)
      (putpropq cell nil        noEdit)
      (if IsCheck
      then
        (putpropq cell 'blue     backColor)
        (putpropq cell 'white    textColor)
      else
; UNIX workaround - active row background is black
;        (putpropq cell 'green   textColor)
        (putpropq cell 'white     backColor))
      (axlFormGridBatch cell)
      (putpropq cell 2          col)          ; Column-2 Net or Layer Name
      (putpropq cell yrow       row)
      (putpropq cell nil        check)
      (putpropq cell nil        invisible)
      (putpropq cell RowName   value)
      (putpropq cell t          noEdit)
      (axlFormGridBatch cell));end-if
    yrow++)
)) ;end PROG and PROCEDURE DT_destub_filter_set

;*******************************************************************************
;
(procedure (DT_destub_xcol_init RG_g_FORM "g")
(prog (DMSG ColStuct)
  (setq DMSG nil) ;debug printing
  ;clear entire grid
  (when (greaterp (axlVersion 'version) 14.2)
    (axlFormGridReset RG_g_FORM "GridField"))
  (when DMSG (fprintf DbugFH "\n\n%s\n%s\nFUNCTION: DT_destub_xcol_init\n" RG_t_LINE1 RG_t_LINE2))
  ; Column-1 Check
  (setq ColStruct make_formGridCol())
  ColStruct->fieldType = 'CHECKITEM
  ColStruct->colWidth = 2
  ColStruct->align = 'center
  ColStruct->scriptLabel = "chck_head"
  (axlFormGridInsertCol RG_g_FORM "GridField" ColStruct)
  ; Column-2 Type
  (setq ColStruct make_formGridCol())
  ColStruct->fieldType = 'TEXT
  ColStruct->colWidth = 10
  ColStruct->fieldLength = 24
  ColStruct->align = 'center
  ColStruct->headText = 'Type
  ColStruct->scriptLabel = "type_head"
  (axlFormGridInsertCol RG_g_FORM "GridField" ColStruct)
  ; Column-3 X-Value
  (setq ColStruct make_formGridCol())
  ColStruct->fieldType = 'REAL
  ColStruct->colWidth = 12
  ColStruct->fieldLength = 24
  ColStruct->align = 'center
  ColStruct->headText = 'X
  ColStruct->scriptLabel = "xval_head"
  (axlFormGridInsertCol RG_g_FORM "GridField" ColStruct)
  ; Column-4 Y-Value
  (setq ColStruct make_formGridCol())
  ColStruct->fieldType = 'REAL
  ColStruct->colWidth = 12
  ColStruct->fieldLength = 24
  ColStruct->align = 'center
  ColStruct->headText = 'Y
  ColStruct->scriptLabel = "yval_head"
  (axlFormGridInsertCol RG_g_FORM "GridField" ColStruct)
  ; Column-5 Net
  (setq ColStruct make_formGridCol())
  ColStruct->fieldType = 'TEXT
  ColStruct->colWidth = 20
  ColStruct->fieldLength = 127
  ColStruct->align = 'center
  ColStruct->headText = 'Net
  ColStruct->scriptLabel = "nets_head"
  (axlFormGridInsertCol RG_g_FORM "GridField" ColStruct)
  ; Column-6 Layer
  (setq ColStruct make_formGridCol())
  ColStruct->fieldType = 'ENUMSET
  ColStruct->colWidth = 18
  ColStruct->fieldLength = 127
  ColStruct->align = 'center
  ColStruct->headText = 'Layer
  ColStruct->scriptLabel = "lays_head"
  (axlFormGridInsertCol RG_g_FORM "GridField" ColStruct)
  ; Column-7 Property (ENUM)
  (setq ColStruct make_formGridCol())
  ColStruct->fieldType = 'ENUMSET
  ColStruct->colWidth = 14
  ColStruct->fieldLength = 63
  ColStruct->align = 'center
  ColStruct->headText = 'Property
  ColStruct->scriptLabel = "prop_head"
  (axlFormGridInsertCol RG_g_FORM "GridField" ColStruct)
  ; Column-8 Index
  (setq ColStruct make_formGridCol())
  ColStruct->fieldType = 'LONG
  (when DMSG ;make visible for debugging
    ColStruct->colWidth = 6
    ColStruct->align = 'center)
  ColStruct->scriptLabel = "ndex_head"
  ColStruct->invisible = t
  (axlFormGridInsertCol RG_g_FORM "GridField" ColStruct)
  ; Enable Grid Events -NOTE: we do not need the "cellselect" event.
  (axlFormGridEvents RG_g_FORM "GridField"
    '(rowselect change rightpopup rightpopupPre leftpopupPre))
  (axlFormGridUpdate RG_g_FORM "GridField")
  (return t)
));end-PROG_and_PROCEDURE DT_destub_xcol_init()


;********************************************************************************
; PROCEDURE: DT_destub_popup_set
;
; Rewrites the "popup" (actually drop down enum list). Used with Layer cells and
; Property cells prior to it being displayed to the user. This is done through
; the "leftpopupPre" event on the grid (see form callback for details).
;
; It basically rewrites the popup/droplist so that it only contains elements
; applicable to the given row object. If a shape is on a single layer, as it
; must be, only that layer is visible in the drop-down-list. A blind or burried
; via would only show a list of layers where it is. A through hole via would
; show a list of all layers. etc.
;
; The same is true for the properties attached to the object except we're only
; concerned with the DESTUB_FANOUT and DESTUB_IGNORE properties and do not list
; anything else.
;
; __FIXME__
; There are issues on maximum number of "popups" allowed in a form. It may be
; best to use (axlUIPopupDefine) rather than (axlFormBuildPopup). This needs
; to be tested.
;
(procedure (DT_destub_popup_set ArgList "l")
(let (DMSG cell ndexcell pSym PopList i_cnt)
  (setq DMSG nil) ; debug printing
  (setq cell (car ArgList))
  (setq pSym (evalstring cell->scriptLabel))
  (if cell->col == 6
  then
    (setq PopList nil)
    (if pSym->lays
    then
      (setq i_cnt 0)
      (for i_cnt 0 (length pSym->lays)
        (when (nth i_cnt pSym->lays)
          (setq PopList (cons (list (nth i_cnt pSym->lays) i_cnt) PopList))))
      (setq PopList (reverse PopList))
    else
      (setq PopList (cons (list " " " ") PopList)))
    (when DMSG (println PopList DbugFH))
    (axlFormBuildPopup RG_g_FORM "popCellLays" PopList)
;    (setq RG_r_popCellLays (axlUIPopupDefine (list (axlFormGetField RG_g_FORM "popCellLays")) PopList))
  else
    (when cell->col == 7
      (setq PopList nil)
      (if pSym->prop
      then
        (setq i_cnt 0)
        (for i_cnt 0 (length pSym->prop)
          (if (nth i_cnt pSym->prop)
            (setq PopList (cons (list (nth i_cnt pSym->prop) i_cnt) PopList))))
        (setq PopList (reverse PopList))
      else
        (setq PopList (cons (list " " " ") PopList)))
      (when DMSG (println PopList DbugFH))
      (axlFormBuildPopup RG_g_FORM "popCellProp" PopList)
;      (setq RG_r_popCellProp (axlUIPopupDefine (list (axlFormGetField RG_g_FORM "popCellProp")) PopList))
    ))
));end let & procedure


;*******************************************************************************
; FUNCTION: DT_destub_tree_init
; Initialize TreeView Field
; NOTES:
;   Images must be in Windows/OS2 bitmap format and have a color depth of 8-bits
;   Using optimized color palets in the images seems to work but should be
;   tested further.
;   Yes, there really are 48 icons in the image file for the TreeView control
;   including all the hilight versions. They are 16x16 pixels in size, all in
;   single file horizontally. The hilight version comes directly after the
;   unhighlighted version.
;
(procedure (DT_destub_tree_init)
(let ()
  ; delete everything already in the TreeView field
  (axlFormTreeViewSet RG_g_FORM "Ztree" 'TV_REMOVEALL nil)
  ; load bitmaps for use in TreeView
  (setq RG_BITMAP_LIST (axlFormTreeViewLoadBitmaps RG_g_FORM "Ztree" RG_t_BMP_FILE_TREESET))
  (setq RG_x_IMG_REDD_DOT_O  (nth 0  RG_BITMAP_LIST))   ; Red   Dot "Select"     (is  listed)
;  (setq RG_x_IMG_REDD_DOT_OH (nth 1  RG_BITMAP_LIST))   ; Red   Dot "Select"     (is  listed)
  (setq RG_x_IMG_REDD_DOT_X  (nth 2  RG_BITMAP_LIST))   ; Red   Dot "Select-X"   (not listed)
;  (setq RG_x_IMG_REDD_DOT_XH (nth 3  RG_BITMAP_LIST))   ; Red   Dot "Select-X"   (not listed)

  (setq RG_x_IMG_GREN_DOT_O  (nth 4  RG_BITMAP_LIST))   ; Green Dot "NotSel"     (is  listed)
;  (setq RG_x_IMG_GREN_DOT_OH (nth 5  RG_BITMAP_LIST))   ; Green Dot "NotSel"     (is  listed)
  (setq RG_x_IMG_GREN_DOT_X  (nth 6  RG_BITMAP_LIST))   ; Green Dot "NotSel-X"   (not listed)
;  (setq RG_x_IMG_GREN_DOT_XH (nth 7  RG_BITMAP_LIST))   ; Green Dot "NotSel-X"   (not listed)

  (setq RG_x_IMG_YELL_DOT_O  (nth 8  RG_BITMAP_LIST))   ; Gray  Dot "Disabled"   (is  listed)
;  (setq RG_x_IMG_YELL_DOT_OH (nth 9  RG_BITMAP_LIST))   ; Gray  Dot "Disabled"   (is  listed)
  (setq RG_x_IMG_YELL_DOT_X  (nth 10 RG_BITMAP_LIST))   ; Gray  Dot "Disabled-X" (not listed)
;  (setq RG_x_IMG_YELL_DOT_XH (nth 11 RG_BITMAP_LIST))   ; Gray  Dot "Disabled-X" (not listed)

  (setq RG_x_IMG_NORM_FCL_O  (nth 12 RG_BITMAP_LIST))   ; Normal  Folder Closed
;  (setq RG_x_IMG_NORM_FCL_OH (nth 13 RG_BITMAP_LIST))   ; Normal  Folder Closed
  (setq RG_x_IMG_NORM_FCL_X  (nth 14 RG_BITMAP_LIST))   ; Normal  Folder Closed-X
;  (setq RG_x_IMG_NORM_FCL_XH (nth 15 RG_BITMAP_LIST))   ; Normal  Folder Closed-X

  (setq RG_x_IMG_NORM_FOP_O  (nth 16 RG_BITMAP_LIST))   ; Normal  Folder Open
;  (setq RG_x_IMG_NORM_FOP_OH (nth 17 RG_BITMAP_LIST))   ; Normal  Folder Open
  (setq RG_x_IMG_NORM_FOP_X  (nth 18 RG_BITMAP_LIST))   ; Normal  Folder Open-X
;  (setq RG_x_IMG_NORM_FOP_XH (nth 19 RG_BITMAP_LIST))   ; Normal  Folder Open-X

  (setq RG_x_IMG_REDH_FCL_O  (nth 20 RG_BITMAP_LIST))   ; HalfRed Folder Closed  (is  listed)
;  (setq RG_x_IMG_REDH_FCL_OH (nth 21 RG_BITMAP_LIST))   ; HalfRed Folder Closed  (is  listed)
  (setq RG_x_IMG_REDH_FCL_X  (nth 22 RG_BITMAP_LIST))   ; HalfRed Folder Closed-X (not listed)
;  (setq RG_x_IMG_REDH_FCL_XG (nth 23 RG_BITMAP_LIST))   ; HalfRed Folder Closed-X (not listed)

  (setq RG_x_IMG_REDH_FOP_O  (nth 24 RG_BITMAP_LIST))   ; HalfRed Folder Open    (is  listed)
;  (setq RG_x_IMG_REDH_FOP_OH (nth 25 RG_BITMAP_LIST))   ; HalfRed Folder Open    (is  listed)
  (setq RG_x_IMG_REDH_FOP_X  (nth 26 RG_BITMAP_LIST))   ; HalfRed Folder Open-X   (not listed)
;  (setq RG_x_IMG_REDH_FOP_XH (nth 27 RG_BITMAP_LIST))   ; HalfRed Folder Open-X   (not listed)

  (setq RG_x_IMG_REDF_FCL_O  (nth 28 RG_BITMAP_LIST))   ; FullRed Folder Closed  (is  listed)
;  (setq RG_x_IMG_REDF_FCL_OH (nth 29 RG_BITMAP_LIST))   ; FullRed Folder Closed  (is  listed)
  (setq RG_x_IMG_REDF_FCL_X  (nth 30 RG_BITMAP_LIST))   ; FullRed Folder Closed-X (not listed)
;  (setq RG_x_IMG_REDF_FCL_XH (nth 31 RG_BITMAP_LIST))   ; FullRed Folder Closed-X (not listed)

  (setq RG_x_IMG_REDF_FOP_O  (nth 32 RG_BITMAP_LIST))   ; FullRed Folder Open    (is  listed)
;  (setq RG_x_IMG_REDF_FOP_OH (nth 33 RG_BITMAP_LIST))   ; FullRed Folder Open    (is  listed)
  (setq RG_x_IMG_REDF_FOP_X  (nth 34 RG_BITMAP_LIST))   ; FullRed Folder Open-X   (not listed)
;  (setq RG_x_IMG_REDF_FOP_XH (nth 35 RG_BITMAP_LIST))   ; FullRed Folder Open-X   (not listed)

  (setq RG_x_IMG_GREN_FCL_O  (nth 36 RG_BITMAP_LIST))   ; Green   Folder Closed  (is  listed)
;  (setq RG_x_IMG_GREN_FCL_OH (nth 37 RG_BITMAP_LIST))   ; Green   Folder Closed  (is  listed)
  (setq RG_x_IMG_GREN_FCL_X  (nth 38 RG_BITMAP_LIST))   ; Green   Folder Closed-X (not listed)
;  (setq RG_x_IMG_GREN_FCL_XH (nth 39 RG_BITMAP_LIST))   ; Green   Folder Closed-X (not listed)

  (setq RG_x_IMG_GREN_FOP_O  (nth 40 RG_BITMAP_LIST))   ; Green   Folder Open    (is  listed)
  (setq RG_x_IMG_GREN_FOP_OH (nth 41 RG_BITMAP_LIST))   ; Green   Folder Open    (is  listed)
  (setq RG_x_IMG_GREN_FOP_X  (nth 42 RG_BITMAP_LIST))   ; Green   Folder Open-X   (not listed)
  (setq RG_x_IMG_GREN_FOP_XH (nth 43 RG_BITMAP_LIST))   ; Green   Folder Open-X   (not listed)

  (setq RG_x_IMG_GRAY_DIS_O  (nth 44 RG_BITMAP_LIST))   ; Gray  Dot "Disabled"   (is  listed)
;  (setq RG_x_IMG_YELL_DOT_OH (nth 45 RG_BITMAP_LIST))   ; Gray  Dot "Disabled"   (is  listed)
  (setq RG_x_IMG_GRAY_DIS_X  (nth 46 RG_BITMAP_LIST))   ; Gray  Dot "Disabled-X" (not listed)
;  (setq RG_x_IMG_YELL_DOT_XH (nth 47 RG_BITMAP_LIST))   ; Gray  Dot "Disabled-X" (not listed)

  (setq RG_x_IMG_GRAY_FCL_X  (nth 48 RG_BITMAP_LIST))   ; Green   Folder Open    (is  listed)
  (setq RG_x_IMG_GRAY_FCL_XH (nth 49 RG_BITMAP_LIST))   ; Green   Folder Open    (is  listed)
  (setq RG_x_IMG_GRAY_FOP_X  (nth 50 RG_BITMAP_LIST))   ; Green   Folder Open-X   (not listed)
  (setq RG_x_IMG_GRAY_FOP_XH (nth 51 RG_BITMAP_LIST))   ; Green   Folder Open-X   (not listed)



;RG_x_IMG_YELL_DOT_O RG_x_IMG_NORM_FOP_O RG_x_IMG_NORM_FCL_O  -top level folders
;RG_x_IMG_YELL_DOT_X RG_x_IMG_YELL_DOT_X RG_x_IMG_YELL_DOT_X  -not listed "good" items

;RG_x_IMG_GREN_DOT_O RG_x_IMG_GREN_FOP_O RG_x_IMG_GREN_FCL_O  -not selected and listed
;RG_x_IMG_REDD_DOT_O RG_x_IMG_REDF_FOP_O RG_x_IMG_REDF_FCL_O  -is  selected and listed

;RG_x_IMG_GREN_DOT_X RG_x_IMG_GREN_FOP_X RG_x_IMG_GREN_FCL_X  -not selected and not lsited
;RG_x_IMG_REDD_DOT_X RG_x_IMG_REDF_FOP_X RG_x_IMG_REDF_FCL_X  -is  selected and not listed


  ; build top level of tree
;__FIXME__ Need to be able to select the entire toplevel folder down through all items.
  (axlFormTreeViewSet RG_g_FORM "Ztree" 'TV_NOEDITLABEL nil)
  (axlFormTreeViewSet RG_g_FORM "Ztree" 'TV_SHOWSELALWAYS nil)
  (setq T0 (axlFormTreeViewAddItem RG_g_FORM "Ztree" "CHAINS" nil nil
  'TVSELECT_SINGLE RG_x_IMG_GRAY_DIS_X RG_x_IMG_NORM_FOP_O RG_x_IMG_NORM_FCL_O))
  (setq T1 (axlFormTreeViewAddItem RG_g_FORM "Ztree" "BAD NETS" nil nil
  'TVSELECT_SINGLE RG_x_IMG_GRAY_DIS_X RG_x_IMG_NORM_FOP_O RG_x_IMG_NORM_FCL_O))
  (setq T2 (axlFormTreeViewAddItem RG_g_FORM "Ztree" "BAD BRANCHES" nil nil
  'TVSELECT_SINGLE RG_x_IMG_GRAY_DIS_X RG_x_IMG_NORM_FOP_O RG_x_IMG_NORM_FCL_O))
  (setq T3 (axlFormTreeViewAddItem RG_g_FORM "Ztree" "BAD PATHS" nil nil
  'TVSELECT_SINGLE RG_x_IMG_GRAY_DIS_X RG_x_IMG_NORM_FOP_O RG_x_IMG_NORM_FCL_O))
  (setq T4 (axlFormTreeViewAddItem RG_g_FORM "Ztree" "BAD PINS" nil nil
  'TVSELECT_SINGLE RG_x_IMG_GRAY_DIS_X RG_x_IMG_NORM_FOP_O RG_x_IMG_NORM_FCL_O))
  (setq T5 (axlFormTreeViewAddItem RG_g_FORM "Ztree" "BAD SHAPES" nil nil
  'TVSELECT_SINGLE RG_x_IMG_GRAY_DIS_X RG_x_IMG_NORM_FOP_O RG_x_IMG_NORM_FCL_O))
  (setq T6 (axlFormTreeViewAddItem RG_g_FORM "Ztree" "BAD VIAS" nil nil
  'TVSELECT_SINGLE RG_x_IMG_GRAY_DIS_X RG_x_IMG_NORM_FOP_O RG_x_IMG_NORM_FCL_O))

  (setq RGsl_ITEM_SKIP (cons (list T0 nil) RGsl_ITEM_SKIP))
  (setq RGsl_ITEM_SKIP (cons (list T1 nil) RGsl_ITEM_SKIP))
  (setq RGsl_ITEM_SKIP (cons (list T2 nil) RGsl_ITEM_SKIP))
  (setq RGsl_ITEM_SKIP (cons (list T3 nil) RGsl_ITEM_SKIP))
  (setq RGsl_ITEM_SKIP (cons (list T4 nil) RGsl_ITEM_SKIP))
  (setq RGsl_ITEM_SKIP (cons (list T5 nil) RGsl_ITEM_SKIP))
  (setq RGsl_ITEM_SKIP (cons (list T6 nil) RGsl_ITEM_SKIP))
))



;*******************************************************************************
; set property
(procedure (DT_destub_prop_set pSymList PropName DoAdd "ltg")
(let (DMSG pSym Prop RecursiveKids)
  (setq DMSG nil) ; debug printing
  (when DMSG (fprintf DbugFH "\n\n%s\n%s\nFUNCTION: DT_destub_prop_set \n\n" RG_t_LINE1 RG_t_LINE2))

  (setq RecursiveKids nil)

  ;test if propery is in data base /ask user if ok to add.
  (foreach Prop RGlt_PROP_LIST
    (setq PropObj (axlDBGetPropDictEntry Prop))
    (when DMSG (fprintf DbugFH "Prop___: %L\n" Prop))
    (when DMSG (fprintf DbugFH "PropObj: %L\n\n" PropObj))
    (when (null PropObj)
      (setq MsgTxt "Would you like to add the following propery:\n")
      (strcat MsgTxt (sprintf nil "\t%L\n" Prop))
      (strcat MsgTxt "to your current design?\n")
      (when (axlUIYesNo MsgTxt)
        (axlDBCreatePropDictEntry Prop "BOOLEAN"
          (list "COMPONENTS" "CLINES" "PINS" "SHAPES" "VIAS")))))
  ;prevent programming mistakes like misspelled property names...
  (if (member PropName RGlt_PROP_LIST)
  then
    (foreach pSym pSymList
      (if (or {pSym->otyp == "net"} {pSym->otyp == "branch"} {pSym->otyp == "chain"})
      then ;deal with chains, branches and nets
        (if RecursiveKids
        then
          (if DoAdd
          then
            (when DMSG (fprintf DbugFH "\n\nAdd Prop on Chain Net or Branch\n"))
            (when DMSG (fprintf DbugFH "Add_PropName__: %L\n" PropName))
            (when DMSG (fprintf DbugFH "Cur_pSym->prop: %L\n" pSym->prop))
            (if {(car pSym->prop) == " "}
            then
              pSym->prop = (list PropName)
            else
              (when !(member (get_string PropName) pSym->prop)
                pSym->prop = (cons (get_string PropName) pSym->prop)
                pSym->prop = (sort pSym->prop nil)))
            (when DMSG (fprintf DbugFH "New_pSym->prop: %L\n\n" pSym->prop))
            ;recurse for each kid pSym
            (foreach pKid pSym->kids
              (axlDBAddProp pKid->dbid (list PropName t))
              (when DMSG (fprintf DbugFH "Add_PropName__: %L\n" PropName))
              (when DMSG (fprintf DbugFH "Cur_pKid->prop: %L\n" pKid->prop))
              (if {(car pKid->prop) == " "}
              then pKid->prop = (list PropName)
              else
                (when !(member (get_string PropName) pKid->prop)
                  pKid->prop = (cons (get_string PropName) pKid->prop)
                  pKid->prop = (sort pKid->prop nil)))
              (when DMSG (fprintf DbugFH "New_pKid->prop: %L\n" pKid->prop))
            );end foreach pKid
            (DT_destub_ui_set_cb ?pSymLst pSym->kids)
            ; now deal with child objects
            (axlDBAddProp pSym->chld (list PropName t))
          else ;not doAdd chains, branches nets
            (when DMSG (fprintf DbugFH "\n\nDelete Prop on Chain Net or Branch\n"))
            (when DMSG (fprintf DbugFH "Del_PropName__: %L\n" PropName))
            (when DMSG (fprintf DbugFH "Cur_pSym->prop: %L\n" pSym->prop))
            (when (member (get_string PropName) pSym->prop)
              pSym->prop = (remd PropName pSym->prop)
              pSym->prop = (sort pSym->prop nil)
              (when (null pSym->prop) pSym->prop = (list " ")))
            (when DMSG (fprintf DbugFH "New_pSym->prop: %L\n" pSym->prop))
            ;recurse for each kid
            (foreach pKid pSym->kids
              (axlDBDeleteProp pKid->dbid (list (get_string PropName)))
              (when DMSG (fprintf DbugFH "Del_PropName__: %L\n" PropName))
              (when DMSG (fprintf DbugFH "Cur_pKid->prop: %L\n" pKid->prop))
              (when (member (get_string PropName) pKid->prop)
                pKid->prop = (remd PropName pKid->prop)
                pKid->prop = (sort pKid->prop nil)
                (if (null pKid->prop) pKid->prop = (list " ")))
              (when DMSG (fprintf DbugFH "New_pKid->prop: %L\n" pKid->prop)))
            (DT_destub_ui_set_cb ?pSymLst pSym->kids)
            ; now deal with child objects
            (axlDBDeleteProp pSym->chld (list (get_string PropName))))
        else ;RecursiveKids
          (axlUIWPrint RG_g_FORM 'error "Can not set properties on chains, nets or branches"))
      ;--------------------------------------------------------------------------------
      else ;deal with paths, pins, shapes and vias
        (if DoAdd
        then
          (axlDBAddProp pSym->dbid (list PropName t))
          (when DMSG (fprintf DbugFH "Add_PropName__: %L\n" PropName))
          (when DMSG (fprintf DbugFH "Cur_pSym->prop: %L\n" pSym->prop))
          (if {(car pSym->prop) == " "}
          then
            pSym->prop = (list PropName)
          else
            (when !(member (get_string PropName) pSym->prop)
              pSym->prop = (cons (get_string PropName) pSym->prop)
              pSym->prop = (sort pSym->prop nil)))
          (when DMSG (fprintf DbugFH "New_pSym->prop: %L\n" pSym->prop))
        else
          (axlDBDeleteProp pSym->dbid (list (get_string PropName)))
          (when DMSG (fprintf DbugFH "Del_PropName__: %L\n" PropName))
          (when DMSG (fprintf DbugFH "Cur_pSym->prop: %L\n" pSym->prop))
          (when (member (get_string PropName) pSym->prop)
            pSym->prop = (remd PropName pSym->prop)
            pSym->prop = (sort pSym->prop nil)
            (when (null pSym->prop) pSym->prop = (list " ")))
          (when DMSG (fprintf DbugFH "New_pSym->prop: %L\n" pSym->prop)))));end foreach pSym pSymList
    (DT_destub_ui_set_cb ?pSymLst pSymList)
  else
    (printf "\nERROR: DT_destub_prop_set() - Propery Incorrectly Named\n")
    (fprintf DbugFH "\nERROR: DT_destub_prop_set() - Propery Incorrectly Named\n"))
));end LET_and_PROCEDURE DT_destub_prop_set

;*******************************************************************************
;FUNCTION: DT_destub_current_set
;
;  1.) Set visibility and highlighting on layers and objects
;  2.) If given rowNumber, set coresponding tree item to current
;  3.) If given treeItem, set corresponding row item image
;
(procedure (DT_destub_current_set ArgpSym @key (SetItem nil) (UnLite t) "ggg")
(let (DMSG pSym pSymList cell LayName TreeCons TreeItem ImgList Img y_row)
  (setq DMSG nil) ; debug printing
  (when DMSG (fprintf DbugFH "\n\n%s\n%s\nFUNCTION: DT_destub_current_set \n\n" RG_t_LINE1 RG_t_LINE2))

  (setq pSym ArgpSym)

  ;--------------------------------------------------------------------------------
  ; set/reset temp group
  (setq RG_x_GROUP_THIS pSym->ndex)
  (when (and RG_x_GROUP_START !RG_x_GROUP_END !RG_x_GROUP_ADD)
    ; #1 unhighlight any existing group list
    (setq pSymList nil)
    (when (length RGlx_GROUP_LIST) > 0
      (when DMSG (fprintf DbugFH "FUNCTION: DT_destub_current_set: Clearing Selected Rows From Temp Group\n"))
      (when DMSG (fprintf DbugFH "RGlx_GROUP_LIST: %L\n" RGlx_GROUP_LIST))
      (foreach pSym RGls_SHOW_LIST
        (when (memq pSym->ndex RGlx_GROUP_LIST)
          (setq pSymList (cons pSym pSymList))))
      (DT_destub_ui_set_cb ?pSymLst pSymList)  ;reset rows to normal
      (setq RGlx_GROUP_LIST nil))              ;clear existing temp group list
    ; #2 build a new temp group row list, start to current, in order low to high
    (if RG_x_GROUP_START < RG_x_GROUP_THIS
    then
      (for y_row RG_x_GROUP_START RG_x_GROUP_THIS
        (setq RGlx_GROUP_LIST (cons y_row RGlx_GROUP_LIST)))
    else
      (for y_row RG_x_GROUP_THIS RG_x_GROUP_START
        (setq RGlx_GROUP_LIST (cons y_row RGlx_GROUP_LIST))))
    ; #3 highlight the new group list
    (setq pSymList nil)
    (foreach pSym RGls_SHOW_LIST
      (when (memq pSym->ndex RGlx_GROUP_LIST)
        (setq pSymList (cons pSym pSymList))))
    (when DMSG (fprintf DbugFH "\nFUNCTION: DT_destub_current_set: Adding Selected Rows To Temp Group\n"))
    (when DMSG (fprintf DbugFH "RGlx_GROUP_LIST: %L\n" RGlx_GROUP_LIST))
    (DT_destub_ui_set_cb ?pSymLst pSymList ?DoYLite t))

  ;--------------------------------------------------------------------------------
  ;hilight/zoom relevant objects
  ;set active layer to the first layer of the effected layers
;__NOFIX__ This messes up color priority
;  (axlDBControl 'activeLayer (strcat "ETCH/" (car pSym->lays)))

  ;set highlight of problem objects using "temp" highlight color
  (setq RGld_LITE_OBJS pSym->dbid)
  (_DTL_UTILS_ZoomDBIDList RGld_LITE_OBJS RGtt_ZOOM[pSym->otyp])
  (axlHighlightObject RGld_LITE_OBJS nil)

;__NOFIX__ Using the two different highlight colors (temp and perm) is the best
;we can do without mad hackery in color shadowing.
  ;set highlight of net with "perm" highlight color
  (when (car pSym->dbid)->net
    (setq RGld_LITE_NETS (list (car pSym->dbid)->net))
    (axlHighlightObject RGld_LITE_NETS  t)) ;uses "perm" color
  ;set user interface message for object
  (DT_destub_msg_get (car pSym->dbid) t)
  ; get relevant layers
  (if {pSym->otyp == "chain"}
  then
    (foreach DBID pSym->dbid
      (setq RGlt_LITE_LAYS (append (DT_destub_lay_get DBID) RGlt_LITE_LAYS)))
  else (setq RGlt_LITE_LAYS (DT_destub_lay_get (car pSym->dbid))))
  ; make relevant layers visible
  (when (dtpr RGlt_LITE_LAYS)
    (foreach LayName RGlt_LITE_LAYS
      (axlVisibleLayer LayName t)))
  ; show rats
  (if pSym->otyp == "net"
  then (axlRatsnestDisplay (setq RG_d_LITE_RATS (car pSym->dbid)))
  else (axlRatsnestDisplay (setq RG_d_LITE_RATS (car pSym->dbid)->net)))
  ;--------------------------------------------------------------------------------
  ; Tree Item images
  (if SetItem
  then ; unset active tree item image
      (when (dtpr RGlx_LITE_TREE)
        (foreach TreeCons RGlx_LITE_TREE
          (setq TreeItem (car  TreeCons))
          (setq ImgList  (cadr TreeCons))
          (setq ImgList (mapcar '(lambda (Img) (Img - 1)) ImgList ))
          (axlFormTreeViewChangeImages RG_g_FORM "Ztree" TreeItem
            (car ImgList) (cadr ImgList) (caddr ImgList)))
        (when DMSG (fprintf DbugFH "\nUNLITE_ITEM\npSym: %L\nImgL: %L\nItem: %L" pSym ImgList TreeItem))
        (when DMSG (drain DbugFH))
        (setq RGlx_LITE_TREE nil))
      ; set tree item image to active/highlight current
      (setq RGlx_LITE_TREE nil)
      (foreach TreeItem pSym->tree
        (setq ImgList (axlFormTreeViewGetImages  RG_g_FORM "Ztree" TreeItem))
        (setq ImgList (mapcar '(lambda (Img) (Img + 1)) ImgList ))
        (axlFormTreeViewChangeImages RG_g_FORM "Ztree" TreeItem
          (car ImgList) (cadr ImgList) (caddr ImgList))
        (setq RGlx_LITE_TREE (cons (list TreeItem ImgList) RGlx_LITE_TREE)))
      (when DMSG (fprintf DbugFH "\nHILITE_ITEM\npSym: %L\nImgL: %L\nItem: %L" nil ImgList pSym->item))
      (when DMSG (drain DbugFH))
  else ;fire off a "select" on the TreeView field (causes form event/callback)
    (axlFormTreeViewSet ArgRG_g_FORM "Ztree" 'TV_SELECTITEM pSym->item))
  t ;return value
));end let & procedure


;*******************************************************************************
;FUNCTION: DT_destub_lay_get
;
; Create a list of layers relevant to the object(s) so we can make them visible.
;
(procedure (DT_destub_lay_get ArgDBID "g")
(let (DMSG DBID ChildDBID LayList ConnectList Connect)
  (setq DMSG nil) ;debug printing
  (when DMSG (fprintf DbugFH "\n\n%s\n%s\nFUNCTION: DT_destub_lay_get\n" RG_t_LINE1 RG_t_LINE2))
  (setq LayList nil)
  (when (and (setq DBID ArgDBID) (axlIsDBIDType DBID) !(null DBID))
    (case DBID->objType
      ("net"
        (foreach BranchDBID DBID->branches
          (foreach ChildDBID BranchDBID->children
            (if ChildDBID->layer
            then
              (when !(member ChildDBID->layer LayList)
                (setq LayList (cons ChildDBID->layer LayList)))
            else
              (setq ConnectList (DT_destub_GetConnect ChildDBID t))
              (when (dtpr ConnectList)
                (foreach Connect ConnectList
                  (when Connect->layer
                    (if !(member Connect->layer LayList)
                      (setq LayList (cons Connect->layer LayList))))))))))
      ("branch"
          (foreach ChildDBID DBID->children
            (if ChildDBID->layer
            then
              (when !(member ChildDBID->layer LayList)
                (setq LayList (cons ChildDBID->layer LayList)))
            else
              (setq ConnectList (DT_destub_GetConnect ChildDBID t))
              (when (dtpr ConnectList)
                (foreach Connect ConnectList
                  (when Connect->layer
                    (if !(member Connect->layer LayList)
                      (setq LayList (cons Connect->layer LayList)))))))))
      ("path"
        (when (and DBID->layer !(member DBID->layer LayList))
          (setq LayList (cons DBID->layer LayList))))
      ("pin"
        (setq ConnectList (DT_destub_GetConnect DBID t))
        (when (dtpr ConnectList)
          (foreach Connect ConnectList
            (when Connect->layer
              (if !(member Connect->layer LayList)
                (setq LayList (cons Connect->layer LayList)))))))
      ("shape"
        (when (and DBID->layer !(member DBID->layer LayList))
          (setq LayList (cons DBID->layer LayList))))
      ("tee"
        (when (and DBID->layer !(member DBID->layer LayList))
          (setq LayList (cons DBID->layer LayList))))
      ("via"
        (setq ConnectList (DT_destub_GetConnect DBID t))
        (when (dtpr ConnectList)
          (foreach Connect ConnectList
            (when Connect->layer
              (if !(member Connect->layer LayList)
                (setq LayList (cons Connect->layer LayList)))))))))
  (when DMSG (fprintf DbugFH "Layer List: %L\n" LayList))
  LayList
));end DT_destub_lay_get

;"BAD NET - Has more than one branch (not fully connected) (Branch: %d) (Net Logic Will Not Be Deleted)"
;"NET IS GOOD! -You should not see this message..."
;"BAD BRANCH - This BRANCH Does Not Have A Net (i.e. \"Lonely Branch\")"
;"BRANCH IS GOOD! (not listed) -This BRANCH has a net. (net: %s)"
;"BAD PATH - Has less than two connections (Con: %d)"
;"PATH IS GOOD! (not listed) -This PATH has two connections. (Con: %d)"
;"BAD PIN - Has no connections (Con: %d) (Use: %s) (Pins Will Not Be Deleted)"
;"PIN IS GOOD! (not listed) -This PIN has at least one connection. (Con: %d) (Use: %s)"
;"BAD SHAPE - Has less than two connections (Con: %d)"
;"SHAPE IS GOOD! (not listed) -Two or more connections. (Con: %d)"
;"BAD TEE -You should not see this message..."
;"TEE IS GOOD! (not listed)"
;"BAD VIA - Has no connections. (Con: %d) (Test: %L)"
;"BAD VIA - Has less than two connections and is not a test point. (Con: %d) (Test: %L)"
;"BAD VIA - Has two or more connections, all on the same layer and not a test point. (Con: %d) (Test: %L)"
;"VIAS IS GOOD! (not listed) -It has at least two connections. (Con: %d) (TestPoint: %L)"
;"Item Not Listed"

;*******************************************************************************
;FUNCTION: DT_destub_msg_get
; No side effects
; NOTE: this should really be redon as an array of strings...
(procedure (DT_destub_msg_get ArgDBID ArgIsBad "gg")
(let (DMSG DBID IsBad Message)
  (setq DMSG nil) ;debug printing
  (when DMSG (fprintf DbugFH "\n\n%s\n%s\nFUNCTION: DT_destub_msg_get\n" RG_t_LINE1 RG_t_LINE2))
  (setq Message nil)
  (setq IsBad ArgIsBad)
  (if (and (setq DBID ArgDBID) (axlIsDBIDType DBID) !(null DBID))
  then
    (case DBID->objType
;__FIXME__ Deal with chains
      ("net"
        (if IsBad
        then (setq Message (sprintf nil
          "BAD NET - The NET Has More Than One Branch (i.e. The NET is not fully connected).\n(#Branches: %d) (Net Logic Will Not Be Deleted)"
          DBID->nBranches))
        else (setq Message (sprintf nil
          "GOOD NET - You should not see this message..."))))
      ("branch"
        (if IsBad
        then (setq Message (sprintf nil
          "BAD BRANCH - The BRANCH Does Not Have A Net (i.e. It's a \"Lonely Branch\")."))
        else (setq Message (sprintf nil
          "GOOD BRANCH (Not Listed) - The BRANCH Has A Net.\n(Net Name: %s)"
          DBID->net->name))))
      ("path"
        (if IsBad
        then (setq Message (sprintf nil
          "BAD PATH - The PATH Has Less Than Two Connections.\n(#Connections: %d)"
          (length (DT_destub_GetConnect DBID t))))
        else (setq Message (sprintf nil
          "GOOD PATH (Not Listed) - The PATH Has Two Connections.\n(#Connections: %d)"
          (length (DT_destub_GetConnect DBID t))))))
      ("pin"
        (if IsBad
        then (setq Message (sprintf nil
          "BAD PIN - The PIN Has No Connections\n(#Connections: %d) (Use: %s)\n(Pins Will Not Be Deleted)"
          (length (DT_destub_GetConnect DBID t))
          (sprintf nil "%L" DBID->use)))
        else (setq Message (sprintf nil
          "GOOD PIN (Not Listed) - The PIN Has At Least One Connection.\n(#Connections: %d) (Use: %s)"
          (length (DT_destub_GetConnect DBID t))
          (sprintf nil "%L" DBID->use)))))
      ("shape"
        (if IsBad
        then (setq Message (sprintf nil
          "BAD SHAPE - The SHAPE Has Less Than Two Connections.\n(#Connections: %d)"
          (length DBID->connect)))
        else (setq Message (sprintf nil
          "GOOD SHAPE (Not Listed) - The SHAPE Has Two Or More Connections.\n(#Connections: %d)"
          (length (DT_destub_GetConnect DBID t))))))
      ("tee"
        (if IsBad
        then (setq Message (sprintf nil
          "BAD TEE - You should not see this message..."))
        else (setq Message (sprintf nil
          "GOOD TEE (Not Listed)"))))
      ("via"
        (if IsBad
        then
          (case (length (DT_destub_GetConnect (car pSym->dbid) t))
            (0 (setq Message (sprintf nil
               "BAD VIA - The VIA Has No Connections.\n(#Connections: %d) (TestPoint: %L)"
                (length (DT_destub_GetConnect DBID t))
                DBID->testPoint)))
            (1 (setq Message (sprintf nil
                "BAD VIA - The VIA Has Less Than Two Connections And Is Not A Test Point.\n(#Connections: %d) (TestPoint: %L)"
                (length (DT_destub_GetConnect DBID t))
                DBID->testPoint)))
            (t (setq Message (sprintf nil
                "BAD VIA - The VIA Has Two Or More Connections, All Connections Are On The Same Layer And VIA Is Not A Test Point (i.e. Unnecessary).\n(#Connections: %d) (TestPoint: %L)"
                (length (DT_destub_GetConnect DBID t))
                DBID->testPoint))))
        else
          (setq Message (sprintf nil
            "GOOD VIA (Not Listed) - The VIA Has At Least Two Connections.\n(#Connections: %d) (TestPoint: %L)"
            (length (DT_destub_GetConnect DBID t))
            DBID->testPoint)))))
  else
    (setq Message (sprintf nil "Item Not Listed")))
  (when DMSG (fprintf DbugFH "%L\n" Message))
  (axlFormSetField RG_g_FORM "ProblemTxt" Message)
  Message
));end DT_destub_msg_get_get


;*******************************************************************************
; Find Bad Vias
;   via is bad when it has less than two connections and is not a test point
;   via is bad when it is a test point and has no connections.
;   via is bad when it has two or more connections and all are on the same layer and is not a test point
;
(procedure (DT_destub_data_via)
(let (DMSG ViewSet ViaDBID ViaDBIDList ViaDBIDcons Connect ConnectList LayList LaysStart
      LaysEnd pSym TreeItem PropNewList PropAssList PropName BadList)
  (setq DMSG nil) ;debug printing
  (when DMSG (fprintf DbugFH "\n\n%s\n%s\nFUNCTION: DT_destub_data_via\n" RG_t_LINE1 RG_t_LINE2))
  (setq ViewSet (_DTL_UTILS_SettingsGet))
  (axlVisibleDesign t)
  (axlClearSelSet)
  (axlSetFindFilter ?enabled  (list "noall" "vias" "invisible") ?onButtons  (list "noall" "vias"))
  (axlAddSelectAll)
  (setq ViaDBIDList (axlGetSelSet))
  (_DTL_UTILS_SettingsSet ViewSet nil nil)

  ; Unbind The Association List (help garbage collector)
  (when (boundp 'RGsl_BAD_VIA) (setq RGsl_BAD_VIA 'unbound) (gc))
  (setq RGsl_BAD_VIA nil)      ; Empty The Association List

  (foreach ViaDBID ViaDBIDList
    (setq isBad nil)
    (setq ConnectList (DT_destub_GetConnect ViaDBID t))
    (setq LayList nil)
    (case (length ConnectList)
      (0 ; via has no connections
          (setq RGsl_BAD_VIA (cons (list ViaDBID (make_psym)) RGsl_BAD_VIA)))
      (1 ; via has one connection
; __FIXME__ Need logic for auto-detection of FANOUTS
        (unless ViaDBID->testPoint
          (setq RGsl_BAD_VIA (cons (list ViaDBID (make_psym)) RGsl_BAD_VIA))))
; __FIXME__ This stuff needs work, multi-layer objects like pins and such...
      (t ; default -via has two or more connections
        (unless ViaDBID->testPoint
          (foreach Connect ConnectList ;objects like pins have multiple layers (via in pad)
            (unless (memq Connect->layer LayList)
              (setq LayList (cons Connect->layer LayList))))
          (when (lessp (length LayList)  2)
            (setq RGsl_BAD_VIA (cons (list ViaDBID (make_psym)) RGsl_BAD_VIA))))))
;  (setq RGsl_BAD_VIA (cons (list ViaDBID (make_psym)) RGsl_BAD_VIA))
  );end foreach ViaDBID

  (rexMagic t)
  (rexCompile "^ETCH/")
  (when (boundp 'BadList) (setq BadList 'unbound))
  (setq BadList nil)      ; Empty The Association List

  (foreach ViaDBIDcons RGsl_BAD_VIA
    (setq ViaDBID (car ViaDBIDcons))
    (setq pSym (cadr ViaDBIDcons))

    pSym->pars = (list T6)
    pSym->kids = nil
    pSym->chck = nil
    pSym->otyp = ViaDBID->objType
    pSym->xval = (car ViaDBID->xy)
    pSym->yval = (cadr ViaDBID->xy)
    pSym->ndex = -1
    pSym->dbid = (list ViaDBID)
    pSym->chld = nil

;__NOFIX__ Net names can exist as an empty string that's not nil -very weird
    (if (and !(null ViaDBID->net->name) {(strlen ViaDBID->net->name) > 0})
    then
      pSym->nets = ViaDBID->net->name
      (when !(member ViaDBID->net->name RGlt_NETS_LIST)
        (setq RGlt_NETS_LIST (cons ViaDBID->net->name RGlt_NETS_LIST)))
    else
      pSym->nets = " ") ;empty - single space so it's invisible

    (setq TreeItem axlFormTreeViewAddItem(RG_g_FORM "Ztree" "Bad Via" T6 nil 'TVSELECT_3STATE RG_x_IMG_GREN_DOT_O RG_x_IMG_GREN_FOP_O RG_x_IMG_GREN_FCL_O))
    pSym->tree = (list TreeItem)
    (setq RGsl_ITEM_BAD (cons (list TreeItem pSym) RGsl_ITEM_BAD))
    pSym->item = TreeItem

    (if ViaDBID->isThrough
    then
      (setq LaysList RGlt_LAYS_LIST)
    else ; ugly but it works... Deals with getting layers on B/B vias
;__HACKS__ Uses the fixed string "ETCH/" in the rex  (rexCompile "^ETCH/") see v1.27 for other options
      (setq LaysStart (car  ViaDBID->startEnd))
      (setq LaysEnd   (cadr ViaDBID->startEnd))
;      (fprintf DbugFH "Via->StartEnd: %L\t%L\t%L\n" ViaDBID->startEnd LaysStart LaysEnd)
;      (drain DbugFH)
      (if
        (and !(null ViaDBID->startEnd)
          (dtpr ViaDBID->startEnd)
          !(null LaysStart)
          !(null LaysEnd)
          (stringp LaysStart)
          (stringp LaysEnd)
          {(strlen LaysStart) > 0}
          {(strlen LaysEnd) > 0})
      then
        (setq LaysStart (rexReplace LaysStart "" 1))
        (setq LaysEnd   (rexReplace LaysEnd "" 1))
        (setq LaysInc nil)
        (setq LaysList nil)
        (foreach EtchLayer RGlt_LAYS_LIST
          (if EtchLayer == LaysStart
          then
            (setq LaysList (cons EtchLayer LaysList))
            (setq LaysInc t)
          else
            (if (and LaysInc {EtchLayer != LaysEnd})
            then (setq LaysList (cons EtchLayer LaysList))
            else
              (when EtchLayer == LaysEnd
                (setq LaysList (cons EtchLayer LaysList))
                (setq LaysInc nil)))))
      else
        (setq LaysList (list " ")))
      (setq LaysList (reverse LaysList)));end-if isThrough

;    ; if there's one or more connection to the via put it at the start of the
;    ; list so it is the one we turn on -this means duplicates...
;    (setq ConnectList (DT_destub_GetConnect ViaDBID t))
;    (if {(length ConnectList) >= 1}
;    then
;      (setq LaysList (cons "---------" LaysList))
;      (foreach Connect ConnectList
;;__HACKS__ Uses the fixed string "ETCH/" in the rex  (rexCompile "^ETCH/") see v1.27 for other options
;        (setq LaysList (cons (rexReplace Connect->layer "" 1) LaysList))
;      )
;    )
;
    ; make sure we've got a layers list and stuff it in the pSym
    (if (dtpr LaysList)
    then  pSym->lays = LaysList
    else  pSym->lays = (list " "))  ;empty space

    (if ViaDBID->prop
    then
      (setq PropNewList nil)
      (setq PropAssList (axlDBGetProperties ViaDBID '("user" "allegro")))
      (foreach PropName RGlt_PROP_LIST ;check if it's a prop we're looking for
        (when (assq (concat PropName) PropAssList)
          (setq PropNewList (cons PropName PropNewList))))
      (if (dtpr PropNewList)
      then  pSym->prop = PropNewList
      else  pSym->prop = (list " "))  ;empty space
    else
      pSym->prop = (list " "))  ;empty space
    (setq BadList (cons pSym BadList))
  );end foreach ViaDBID
;  (_DTL_UTILS_PrintProp DbugFH pSym)
  ; reverse list order so it matches the item order in the tree view
  (foreach pSym BadList (setq RGls_FULL_LIST (cons pSym RGls_FULL_LIST)))
));end-LET_and_PROCEDURE DT_destub_data_via_add()

;*******************************************************************************
;
(procedure (DT_destub_data_shape)
(let (DMSG ViewSet ShapeList ShapeDBID ShapeDBIDcons ShapeCenter pSym TreeItem
      PropNewList PropAssList PropName BadList)
  (setq DMSG nil) ;debug printing
  (when DMSG (fprintf DbugFH "\n\n%s\n%s\nFUNCTION: DT_destub_data_shape\n" RG_t_LINE1 RG_t_LINE2))
  (setq ViewSet (_DTL_UTILS_SettingsGet))
  (axlVisibleDesign nil)
  (axlVisibleLayer "ETCH" t)
  (axlClearSelSet)
  (axlSetFindFilter ?enabled  (list "noall" "shapes") ?onButtons  (list "noall" "shapes"))
  (axlAddSelectAll)
  (setq ShapeDBIDList (axlGetSelSet))
  (_DTL_UTILS_SettingsSet ViewSet nil nil)

  ; Unbind The Association List (help garbage collector)
  (when (boundp 'RGsl_BAD_SHAPE) (setq RGsl_BAD_SHAPE 'unbound) (gc))
  (setq RGsl_BAD_SHAPE nil)      ; Empty The Association List

  ; the axlDBGetConnect function does not checking shapes before v15.1
  (when (greaterp (axlVersion 'version) 15.0)
    (foreach ShapeDBID ShapeDBIDList
      (when {(length (DT_destub_GetConnect ShapeDBID t)) < 2}  ; check number of connections
        (setq RGsl_BAD_SHAPE (cons (list ShapeDBID (make_psym)) RGsl_BAD_SHAPE)))))

;  (when DMSG
;    (fprintf DbugFH "ShapeDBIDList Count: %8d\n" (length ShapeDBIDList))
;    (fprintf DbugFH "Bad Shapes Count..: %8d\n" (length RGsl_BAD_SHAPE))
;;    (_DTL_UTILS_PrintProp DbugFH ShapeDBIDList)
;;    (_DTL_UTILS_PrintProp DbugFH (car ShapeDBIDList))
;
;;    (foreach ShapeDBID BadShapeList
;;      (fprintf DbugFH "\n%s\nFUNCTION: DT_destub_data_shape BadShapeDBID\n\n" RG_t_LINE3)
;;      (_DTL_UTILS_PrintProp DbugFH ShapeDBID)
;;    )
;  )

  (rexMagic t)
  (rexCompile "^ETCH/")
  (when (boundp 'BadList) (setq BadList 'unbound))
  (setq BadList nil)      ; Empty The Association List

  (foreach ShapeDBIDcons RGsl_BAD_SHAPE
    (setq ShapeDBID (car ShapeDBIDcons))
    (setq pSym (cadr ShapeDBIDcons))
    (setq ShapeCenter (_DTL_UTILS_BBoxCenter ShapeDBID->bBox))

    pSym->pars = (list T5)
    pSym->kids = nil
    pSym->chck = nil
    pSym->otyp = ShapeDBID->objType
    pSym->xval = (car ShapeCenter)
    pSym->yval = (cadr ShapeCenter)
    pSym->ndex = -1
    pSym->dbid = (list ShapeDBID)
    pSym->chld = nil

;__NOFIX__ Net names can exist as an empty string that's not nil -very weird
    (if (and !(null ShapeDBID->net->name) {(strlen ShapeDBID->net->name) > 0})
    then
      pSym->nets = ShapeDBID->net->name
      (when !(member ShapeDBID->net->name RGlt_NETS_LIST)
        (setq RGlt_NETS_LIST (cons ShapeDBID->net->name RGlt_NETS_LIST)))
    else
      pSym->nets = " ") ;empty - single space so it's invisible

    (setq TreeItem axlFormTreeViewAddItem(RG_g_FORM "Ztree" "Bad Shape" T5 nil 'TVSELECT_3STATE RG_x_IMG_GREN_DOT_O RG_x_IMG_GREN_FOP_O RG_x_IMG_GREN_FCL_O))
    pSym->tree = (list TreeItem)
    (setq RGsl_ITEM_BAD (cons (list TreeItem pSym) RGsl_ITEM_BAD))
    pSym->item = TreeItem

    (if ShapeDBID->layer
;__HACKS__ Uses the fixed string "ETCH/" in the rex  (rexCompile "^ETCH/") see v1.27 for other options
    then pSym->lays = (list (rexReplace ShapeDBID->layer "" 1))
    else pSym->lays = (list " "))  ;empty space

    (if ShapeDBID->prop
    then
      (setq PropNewList nil)
      PropAssList = (axlDBGetProperties ShapeDBID '("user" "allegro"))
      (foreach PropName RGlt_PROP_LIST ;check if it's a prop we're looking for
        (when (assq (concat PropName) PropAssList)
          PropNewList = (cons PropName PropNewList)))
      (if (dtpr PropNewList)
      then  pSym->prop = PropNewList
      else  pSym->prop = (list " "))  ;empty space
    else
      pSym->prop = (list " "))  ;empty space
    (setq BadList (cons pSym BadList))
  );end foreach ShapeDBID
  ; reverse list order so it matches the item order in the tree view
  (foreach pSym BadList (setq RGls_FULL_LIST (cons pSym RGls_FULL_LIST)))
));end-LET_and_PROCEDURE DT_destub_data_shape_add()


;*******************************************************************************
;
(procedure (DT_destub_data_pin)
(let (DMSG ViewSet PinDBID PinDBIDList PinDBIDcons LayList LaysStart LaysEnd
      pSym TreeItem PropNewList PropAssList PropName BadList)
  (setq DMSG nil) ;debug printing
  (when DMSG (fprintf DbugFH "\n\n%s\n%s\nFUNCTION: DT_destub_data_pin\n" RG_t_LINE1 RG_t_LINE2))
  (setq ViewSet (_DTL_UTILS_SettingsGet))
  (axlVisibleDesign nil)
  (axlVisibleDesign t)
  (axlClearSelSet)
  (axlSetFindFilter ?enabled  (list "noall" "pins" "invisible") ?onButtons  (list "noall" "pins"))

  (axlAddSelectAll)
  (setq PinDBIDList (axlGetSelSet))
  (_DTL_UTILS_SettingsSet ViewSet nil nil)

  ; Unbind The Association List (help garbage collector)
  (if (boundp 'RGsl_BAD_PIN) then (setq RGsl_BAD_PIN 'unbound) (gc))
  (setq RGsl_BAD_PIN nil)      ; Empty The Association List

;__FIXME__ We may want to check pinDBID->use for "UNSPEC" ?
;  use    == "UNSPEC"
;  isMech == nil          -i.e. FIDUCIAL
;
; Also there is a axlIsPinUnused() function that may be helpful...

  (foreach PinDBID PinDBIDList
    ; not a mechanical pin and check number of connections
    (when (and !{PinDBID->isMech} {(length (DT_destub_GetConnect PinDBID t)) < 1})
      (setq RGsl_BAD_PIN (cons (list PinDBID (make_psym)) RGsl_BAD_PIN))))

;  (when DMSG
;    (fprintf DbugFH "PinDBIDList Count: %8d\n" (length PinDBIDList))
;    (fprintf DbugFH "Bad Pins Count..: %8d\n" (length RGsl_BAD_PIN))
;;    (_DTL_UTILS_PrintProp DbugFH PinDBIDList)
;;    (_DTL_UTILS_PrintProp DbugFH (car PinDBIDList))
;;    (foreach PinDBID BadPinList
;;      (fprintf DbugFH "\n%s\nFUNCTION: DT_destub_data_pin BadPinDBID\nConnections: %d\n" RG_t_LINE3, (length (DT_destub_GetConnect PinDBID t)))
;;      (_DTL_UTILS_PrintProp DbugFH PinDBID)
;;    )
;  )

  (rexMagic t)
  (rexCompile "^ETCH/")
  (when (boundp 'BadList) (setq BadList 'unbound))
  (setq BadList nil)      ; Empty The Association List

  (foreach PinDBIDcons RGsl_BAD_PIN
    (setq PinDBID (car PinDBIDcons))
    (setq pSym (cadr PinDBIDcons))

    pSym->pars = (list T4)
    pSym->kids = nil
    pSym->chck = nil
    pSym->otyp = PinDBID->objType
    pSym->xval = (car PinDBID->xy)
    pSym->yval = (cadr PinDBID->xy)
    pSym->ndex = -1
    pSym->dbid = (list PinDBID)
    pSym->chld = nil

;__NOFIX__ Net names can exist as an empty string that's not nil -very weird
    (if (and !(null PinDBID->net->name) {(strlen PinDBID->net->name) > 0})
    then
      pSym->nets = PinDBID->net->name
      (when !(member PinDBID->net->name RGlt_NETS_LIST)
        (setq RGlt_NETS_LIST (cons PinDBID->net->name RGlt_NETS_LIST)))
    else
      pSym->nets = " ") ;empty - single space so it's invisible

   (setq TreeItem axlFormTreeViewAddItem(RG_g_FORM "Ztree" "Bad Pin" T4 nil 'TVSELECT_3STATE RG_x_IMG_GREN_DOT_O RG_x_IMG_GREN_FOP_O RG_x_IMG_GREN_FCL_O))
    (axlFormTreeViewSetSelectState RG_g_FORM "Ztree" TreeItem 'TVSTATE_DISABLED)
    pSym->tree = (list TreeItem)
    (setq RGsl_ITEM_BAD (cons (list TreeItem pSym) RGsl_ITEM_BAD))
    pSym->item = TreeItem

    (if PinDBID->isThrough
    then
      LaysList = RGlt_LAYS_LIST
    else ; ugly but it works... Deals with getting layers on B/B pins
;__HACKS__ Uses the fixed string "ETCH/" in the rex  (rexCompile "^ETCH/")
      (setq LaysStart (rexReplace (car PinDBID->startEnd) "" 1))
      (setq LaysEnd   (rexReplace (cadr PinDBID->startEnd) "" 1))
      (if (equal LaysStart LaysEnd)
      then
        (setq LaysList (list LaysStart)) ;surface mount top or bottom
      else
        (setq LaysList nil)
        (setq LaysInc nil)
        (foreach EtchLayer RGlt_LAYS_LIST
          (if EtchLayer == LaysStart
          then
            (setq LaysList (cons EtchLayer LaysList))
            (setq LaysInc t)
          else
            (if (and LaysInc {EtchLayer != LaysEnd})
            then
              (setq LaysList (cons EtchLayer LaysList))
            else
              (when EtchLayer == LaysEnd
                (setq LaysList (cons EtchLayer LaysList))
                (setq LaysInc nil))))))
      (setq LaysList (reverse LaysList))) ;end-if isThrough

    (if (dtpr LaysList)
    then  pSym->lays = LaysList
    else  pSym->lays = (list " "))  ;empty space

    (if PinDBID->prop
    then
      (setq PropNewList nil)
      (setq PropAssList (axlDBGetProperties PinDBID '("user" "allegro")))
      (foreach PropName RGlt_PROP_LIST ;check if it's a prop we're looking for
        (when (assq (concat PropName) PropAssList)
          (setq PropNewList (cons PropName PropNewList))))
      (if (dtpr PropNewList)
      then pSym->prop = PropNewList
      else pSym->prop = (list " "))  ;empty space
    else
      pSym->prop = (list " "))  ;empty space
    (setq BadList (cons pSym BadList))

  );end foreach PinDBID
;  (_DTL_UTILS_PrintProp DbugFH pSym)
  ; reverse list order so it matches the item order in the tree view
  (foreach pSym BadList (setq RGls_FULL_LIST (cons pSym RGls_FULL_LIST)))
));end-LET_and_PROCEDURE DT_destub_data_pin_add()

;*******************************************************************************
;
(procedure (DT_destub_data_path)
(let (DMSG ViewSet PathList PathDBID PathDBIDcons PathCenter pSym TreeItem
      PropNewList PropAssList PropName LastItem BadList)
  (setq DMSG nil) ;debug printing
  (when DMSG (fprintf DbugFH "\n\n%s\n%s\nFUNCTION: DT_destub_data_path\n" RG_t_LINE1 RG_t_LINE2))
  (setq ViewSet (_DTL_UTILS_SettingsGet))
  (axlVisibleDesign nil)
  (axlVisibleLayer "ETCH" t)
  (axlClearSelSet)
  (axlSetFindFilter ?enabled  (list "noall" "clines") ?onButtons  (list "noall" "clines"))
  (axlAddSelectAll)
  (setq PathDBIDList (axlGetSelSet))
  (_DTL_UTILS_SettingsSet ViewSet nil nil)

  ; Unbind The Association List (help garbage collector)
  (when (boundp 'RGsl_BAD_PATH) (setq RGsl_BAD_PATH 'unbound) (gc))
  (setq RGsl_BAD_PATH nil)      ; Empty The Association List

  (foreach PathDBID PathDBIDList
    (when {(length (DT_destub_GetConnect PathDBID t)) < 2}  ; check number of connections
      (setq RGsl_BAD_PATH (cons (list PathDBID (make_psym)) RGsl_BAD_PATH))))

;  (when DMSG
;    (fprintf DbugFH "PathDBIDList Count: %8d\n" (length PathDBIDList))
;    (fprintf DbugFH "Bad Path Count...: %8d\n" (length RGsl_BAD_PATH))
;;    (_DTL_UTILS_PrintProp DbugFH PathDBIDList)
;;    (_DTL_UTILS_PrintProp DbugFH (car PathDBIDList))
;;    (foreach PathDBID BadPathList
;;      (fprintf DbugFH "\n%s\nFUNCTION: DT_destub_data_path BadPathDBID\n\n" RG_t_LINE3)
;;      (_DTL_UTILS_PrintProp DbugFH PathDBID)
;;    )
;  )

  (rexMagic t)
  (rexCompile "^ETCH/")
  (when (boundp 'BadList) (setq BadList 'unbound))
  (setq BadList nil)      ; Empty The Association List

  (foreach PathDBIDcons RGsl_BAD_PATH
    (setq PathDBID (car PathDBIDcons))
    (setq pSym (cadr PathDBIDcons))
    (setq PathCenter (_DTL_UTILS_BBoxCenter PathDBID->bBox))

    pSym->pars = (list T3)
    pSym->kids = nil
    pSym->chck = nil
    pSym->otyp = PathDBID->objType
    pSym->xval = (car PathCenter)
    pSym->yval = (cadr PathCenter)
    pSym->ndex = -1
    pSym->dbid = (list PathDBID)
    pSym->chld = nil

;__NOFIX__ Net names can exist as an empty string that's not nil -very weird
    (if (and !(null PathDBID->net->name) {(strlen PathDBID->net->name) > 0})
    then
      pSym->nets = PathDBID->net->name
      (when !(member PathDBID->net->name RGlt_NETS_LIST)
        (setq RGlt_NETS_LIST (cons PathDBID->net->name RGlt_NETS_LIST)))
    else
      pSym->nets = " ") ;empty - single space so it's invisible

    (setq TreeItem axlFormTreeViewAddItem(RG_g_FORM "Ztree" "Bad Path" T3 nil 'TVSELECT_3STATE RG_x_IMG_GREN_DOT_O RG_x_IMG_GREN_FOP_O RG_x_IMG_GREN_FCL_O))
    pSym->tree = (list TreeItem)
    (setq RGsl_ITEM_BAD (cons (list TreeItem pSym) RGsl_ITEM_BAD))
    pSym->item = TreeItem

    (if PathDBID->layer
;__HACKS__ Uses the fixed string "ETCH/" in the rex  (rexCompile "^ETCH/") see v1.27 for other options
    then pSym->lays = (list (rexReplace PathDBID->layer "" 1))
    else pSym->lays = (list " "))  ;empty space

    (if PathDBID->prop
    then
      (setq PropNewList nil)
      (setq PropAssList (axlDBGetProperties PathDBID '("user" "allegro")))
      (foreach PropName RGlt_PROP_LIST ;check if it's a prop we're looking for
        (when (assq (concat PropName) PropAssList)
          (setq PropNewList (cons PropName PropNewList))))
      (if (dtpr PropNewList)
      then  pSym->prop = PropNewList
      else  pSym->prop = (list " "))  ;empty space
    else
      pSym->prop = (list " "))  ;empty space

;    (axlDBAddProp (list PathDBID) (list 'DT_BAD (sprintf nil "%L" pSym)))
    (setq BadList (cons pSym BadList))
  );end foreach PathDBID
  ; reverse list order so it matches the item order in the tree view
  (foreach pSym BadList (setq RGls_FULL_LIST (cons pSym RGls_FULL_LIST)))
;  (_DTL_UTILS_PrintProp DbugFH pSym)
));end-LET_and_PROCEDURE DT_destub_data_path_add()


;*******************************************************************************
;
(procedure (DT_destub_data_branch)
(let (DMSG BranchDBID LonelyBranchList ChildDBID LaysList LaysInc PropNewList
    bBoxList ChildDBID ChildbBox IsThrough ChildCons TreeItem BadList)
  (setq DMSG nil) ;debug printing
  ; Unbind The Association List (help garbage collector)
  (when (boundp 'RGsl_BAD_BRANCH) (setq RGsl_BAD_BRANCH 'unbound) (gc))
  (setq RGsl_BAD_BRANCH nil)      ; Empty The Association List
  (setq LonelyBranchList (axlDBGetLonelyBranches))

; __FIXME__ It may be best to limit this to branches with more than one child ?
  (foreach BranchDBID LonelyBranchList
    (when {(length BranchDBID->children) > 1}
      (setq RGsl_BAD_BRANCH (cons (list BranchDBID (make_psym)) RGsl_BAD_BRANCH))))
  (when DMSG
    (fprintf DbugFH "\n\n%s\n%s\nFUNCTION: DT_destub_data_branch\n" RG_t_LINE1 RG_t_LINE2)
;    (fprintf DbugFH "Bad Branch Count: %8d\n" (length LonelyBranchList))
;;   (_DTL_UTILS_PrintProp DbugFH (car BadBranchList))
  )

  (rexMagic t)
  (rexCompile "^ETCH/")
  (when (boundp 'BadList) (setq BadList 'unbound))
  (setq BadList nil)      ; Empty The Association List

  (foreach BranchDBIDcons RGsl_BAD_BRANCH
    (setq BranchDBID (car BranchDBIDcons))
    (setq pSym (cadr BranchDBIDcons))

    pSym->pars = (list T2)
    pSym->kids = nil
    pSym->chck = nil
    pSym->otyp = BranchDBID->objType
    pSym->nets = " "  ; A "Lonely Branch" has no net - single space so it's invisible
    pSym->ndex = -1
    pSym->dbid = (list BranchDBID)
    pSym->chld = nil

    (setq branchItem (axlFormTreeViewAddItem RG_g_FORM "Ztree" "Bad Branch" T2 nil    'TVSELECT_3STATE RG_x_IMG_GREN_DOT_O RG_x_IMG_GREN_FOP_O RG_x_IMG_GREN_FCL_O))
    pSym->tree = (list branchItem)
    (setq RGsl_ITEM_BAD (cons (list branchItem pSym) RGsl_ITEM_BAD))
    pSym->item = branchItem

    (setq LaysList nil)
    (setq PropNewList (copy RGlt_PROP_LIST)) ;copy all wanted properties into list
    (setq PropAssList nil)

    (setq bBoxList nil)
    (setq ChildbBox nil)

    (foreach ChildDBID BranchDBID->children
      (setq ChildbBox (_DTL_UTILS_GetBBoxFromDBID ChildDBID))
;__FIXME__ Appending is slow!
      (when (_DTL_UTILS_IsBBoxesList ChildbBox)
        (setq bBoxList (append bBoxList ChildbBox)))
      pSym->chld = (cons ChildDBID pSym->chld)

      ; decisions, decisions... I think the best way to deal with layers used
      ; is only to collect them from paths and shapes to speed things up
      ; compared to parsing via paths
      (case ChildDBID->objType
        ("path"
          (when ChildDBID->layer
;__HACKS__ Uses the fixed string "ETCH/" in the rex  (rexCompile "^ETCH/") see v1.27 for other options
            (setq LaysName (rexReplace ChildDBID->layer "" 1))
;__FIXME__ expensive
            (unless (member LaysName LaysList)
              (setq LaysList (cons LaysName LaysList))))
          (if (setq ChildCons (assq ChildDBID RGsl_BAD_PATH))
          then
            (setq ChildpSym (cadr ChildCons))
            (setq TreeItem axlFormTreeViewAddItem(RG_g_FORM "Ztree" "Bad path" branchItem nil 'TVSELECT_3STATE RG_x_IMG_GREN_DOT_O RG_x_IMG_GREN_FOP_O RG_x_IMG_GREN_FCL_O))
            ChildpSym->tree = (cons TreeItem ChildpSym->tree)
            pSym->tree = (append pSym->tree ChildpSym->tree)
            pSym->kids = (cons ChildpSym pSym->kids)
            (setq RGsl_ITEM_BAD (cons (list TreeItem ChildpSym) RGsl_ITEM_BAD))
          else
            (setq TreeItem axlFormTreeViewAddItem(RG_g_FORM "Ztree" "Path" branchItem nil 'TVSELECT_3STATE RG_x_IMG_GRAY_DIS_X RG_x_IMG_GRAY_DIS_X RG_x_IMG_GRAY_DIS_X))
            (axlFormTreeViewSetSelectState RG_g_FORM "Ztree" TreeItem 'TVSTATE_DISABLED)
            (setq RGsl_ITEM_GOOD (cons (list TreeItem ChildDBID) RGsl_ITEM_GOOD))))
        ("pin"
          (when ChildDBID->isThrough
            (setq LaysList RGlt_LAYS_LIST))
          (if (setq ChildCons (assq ChildDBID RGsl_BAD_PIN))
          then
            (setq ChildpSym (cadr ChildCons))
            (setq TreeItem axlFormTreeViewAddItem(RG_g_FORM "Ztree" "Bad Pin" branchItem nil 'TVSELECT_3STATE RG_x_IMG_YELL_DOT_O RG_x_IMG_YELL_DOT_O RG_x_IMG_YELL_DOT_O))
            ChildpSym->tree = (cons TreeItem ChildpSym->tree)
            pSym->tree = (append pSym->tree ChildpSym->tree)
            pSym->kids = (cons ChildpSym pSym->kids)
            (setq RGsl_ITEM_BAD (cons (list TreeItem ChildpSym) RGsl_ITEM_BAD))
          else
            (setq TreeItem axlFormTreeViewAddItem(RG_g_FORM "Ztree" "Pin" branchItem nil 'TVSELECT_3STATE RG_x_IMG_GRAY_DIS_X RG_x_IMG_GRAY_DIS_X RG_x_IMG_GRAY_DIS_X))
            (axlFormTreeViewSetSelectState RG_g_FORM "Ztree" TreeItem 'TVSTATE_DISABLED)
            (setq RGsl_ITEM_GOOD (cons (list TreeItem ChildDBID) RGsl_ITEM_GOOD))))
        ("shape"
          (when ChildDBID->layer
;__HACKS__ Uses the fixed string "ETCH/" in the rex  (rexCompile "^ETCH/") see v1.27 for other options
            (setq LaysName (rexReplace ChildDBID->layer "" 1))
;__FIXME__ expensive
            (unless (member LaysName LaysList) (setq LaysList (cons LaysName LaysList)))
            (when DMSG (println LaysList DbugFH)))
          (if (setq ChildCons (assq ChildDBID RGsl_BAD_SHAPE))
          then
            (setq ChildpSym (cadr ChildCons))
            (setq TreeItem axlFormTreeViewAddItem(RG_g_FORM "Ztree" "Bad Shape" branchItem nil 'TVSELECT_3STATE RG_x_IMG_GREN_DOT_O RG_x_IMG_GREN_FOP_O RG_x_IMG_GREN_FCL_O))
            ChildpSym->tree = (cons TreeItem ChildpSym->tree)
            pSym->tree = (append pSym->tree ChildpSym->tree)
            pSym->kids = (cons ChildpSym pSym->kids)
            (setq RGsl_ITEM_BAD (cons (list TreeItem ChildpSym) RGsl_ITEM_BAD))
          else
            (setq TreeItem axlFormTreeViewAddItem(RG_g_FORM "Ztree" "Shape" branchItem nil 'TVSELECT_3STATE RG_x_IMG_GRAY_DIS_X RG_x_IMG_GRAY_DIS_X RG_x_IMG_GRAY_DIS_X))
            (axlFormTreeViewSetSelectState RG_g_FORM "Ztree" TreeItem 'TVSTATE_DISABLED)
            (setq RGsl_ITEM_GOOD (cons (list TreeItem ChildDBID) RGsl_ITEM_GOOD))))
        ("tee"
;          (if (setq ChildCons (assq ChildDBID RGsl_BAD_VIA))
;          then
;            (setq ChildpSym (cadr ChildCons))
;            (setq TreeItem axlFormTreeViewAddItem(RG_g_FORM "Ztree" "Bad tee" branchItem nil 'TVSELECT_3STATE RG_x_IMG_GREN_DOT_O RG_x_IMG_GREN_FOP_O RG_x_IMG_GREN_FCL_O))
;            ChildpSym->tree = (cons TreeItem ChildpSym->tree)
;            (setq RGsl_ITEM_BAD (cons (list TreeItem ChildpSym) RGsl_ITEM_BAD))
;          else
            (setq TreeItem axlFormTreeViewAddItem(RG_g_FORM "Ztree" "Tee" branchItem nil 'TVSELECT_3STATE RG_x_IMG_GRAY_DIS_X RG_x_IMG_GRAY_DIS_X RG_x_IMG_GRAY_DIS_X))
            (axlFormTreeViewSetSelectState RG_g_FORM "Ztree" TreeItem 'TVSTATE_DISABLED)
            (setq RGsl_ITEM_GOOD (cons (list TreeItem ChildDBID) RGsl_ITEM_GOOD))
;          )
        )
        ("via"
          (when ChildDBID->isThrough
            (setq LaysList RGlt_LAYS_LIST))
          (if (setq ChildCons (assq ChildDBID RGsl_BAD_VIA))
          then
            (setq ChildpSym (cadr ChildCons))
            (setq TreeItem axlFormTreeViewAddItem(RG_g_FORM "Ztree" "Bad Via" branchItem nil 'TVSELECT_3STATE RG_x_IMG_GREN_DOT_O RG_x_IMG_GREN_FOP_O RG_x_IMG_GREN_FCL_O))
            ChildpSym->tree = (cons TreeItem ChildpSym->tree)
            pSym->tree = (append pSym->tree ChildpSym->tree)
            pSym->kids = (cons ChildpSym pSym->kids)
            (setq RGsl_ITEM_BAD (cons (list TreeItem ChildpSym) RGsl_ITEM_BAD))
          else
            (setq TreeItem axlFormTreeViewAddItem(RG_g_FORM "Ztree" "Via" branchItem nil 'TVSELECT_3STATE RG_x_IMG_GRAY_DIS_X RG_x_IMG_GRAY_DIS_X RG_x_IMG_GRAY_DIS_X))
            (axlFormTreeViewSetSelectState RG_g_FORM "Ztree" TreeItem 'TVSTATE_DISABLED)
            (setq RGsl_ITEM_GOOD (cons (list TreeItem ChildDBID) RGsl_ITEM_GOOD)))))

      ;if a child object dose not have a wanted property, remove the property
      ;from the list. i.e. all children will have the prop for the net/branch
      ;to be labled as having the propery.
      (when (and ChildDBID->prop {ChildDBID->objType != "tee"})
        (setq PropAssList nil)
        (setq PropAssList (axlDBGetProperties ChildDBID '("user" "allegro")))
        (foreach PropName PropNewList
          (if (and !(null PropAssList) !(assq (concat PropName) PropAssList))
            (setq PropNewList (remd PropName PropNewList))))))

    ;see if PropNewList is unchanged or nil
    (if (or (equal PropNewList RGlt_PROP_LIST) (null PropNewList))
    then pSym->prop = (list " ")  ;empty space
    else pSym->prop = PropNewList)
    ;find center of all objects
    (if (_DTL_UTILS_IsBBoxesList bBoxList)
    then
      (setq FullbBox (_DTL_UTILS_BBoxesCombine bBoxList))
      (setq TmpCenter (_DTL_UTILS_BBoxCenter FullbBox))
      pSym->xval = (car TmpCenter)
      pSym->yval = (cadr TmpCenter)
    else ;oh crap!
      pSym->xval = 0
      pSym->yval = 0)
    ;set layers
    (if (pairp LaysList)
    then  pSym->lays = LaysList
    else  pSym->lays = (list " "))
    (setq BadList (cons pSym BadList))
  );end foreach BranchDBIDcons
;  (_DTL_UTILS_PrintProp DbugFH pSym)
  ; reverse list order so it matches the item order in the tree view
  (foreach pSym BadList (setq RGls_FULL_LIST (cons pSym RGls_FULL_LIST)))
));end-LET_and_PROCEDURE DT_destub_data_branch

;*******************************************************************************
;
(procedure (DT_destub_data_net)
(prog (DMSG ViewSet NetDBID NetDBIDList NetList NetName BadList)
  (setq DMSG nil) ;debug printing
  (setq ViewSet (_DTL_UTILS_SettingsGet))
  (axlVisibleDesign t)
  (axlClearSelSet)
  (axlSetFindFilter ?enabled  (list "noall" "nets" "invisible") ?onButtons  (list "noall" "nets"))
  (axlAddSelectAll)
  (setq NetDBIDList (axlGetSelSet))
  (_DTL_UTILS_SettingsSet ViewSet nil nil)

  (when (boundp 'RGsl_BAD_NET) (setq RGsl_BAD_NET 'unbound) (gc)) ;help the garbage collector
  (setq RGsl_BAD_NET nil) ; Empty The Association List

  (foreach NetDBID NetDBIDList
    (axlRatsnestBlank NetDBID)            ; remove ratsnest from all nets
    (when {NetDBID->nBranches != 1}             ; check number of connections
      (setq RGsl_BAD_NET (cons (list NetDBID (make_psym)) RGsl_BAD_NET))))

  (when DMSG
    (fprintf DbugFH "\n\n%s\n%s\nFUNCTION: DT_destub_data_net\n" RG_t_LINE1 RG_t_LINE2)
;    (fprintf DbugFH "NetDBIDList Count: %8d\n" (length NetDBIDList))
;    (fprintf DbugFH "Bad Net Count...: %8d\n" (length RGsl_BAD_NET))
;    (_DTL_UTILS_PrintProp DbugFH NetDBIDList)
;    (_DTL_UTILS_PrintProp DbugFH (car NetDBIDList))
;    (for i 1 20
;      NetDBID = (car NetDBIDList)
;      (fprintf DbugFH "\n%s\nFUNCTION: DT_destub_data_net NetDBID\n" RG_t_LINE3)
;      (_DTL_UTILS_PrintProp DbugFH NetDBID)
;    )
    (foreach NetDBIDcons RGsl_BAD_NET
      (fprintf DbugFH "\n%s\nFUNCTION: DT_destub_data_net Bad NetDBID" RG_t_LINE3)
      (_DTL_UTILS_PrintProp DbugFH (car NetDBIDcons))))

  (rexMagic t)
  (rexCompile "^ETCH/")
  (if (boundp 'BadList) (setq BadList 'unbound))
  (setq BadList nil)      ; Empty The Association List

  (foreach NetDBIDcons RGsl_BAD_NET
    (setq NetDBID (car NetDBIDcons))
    (setq pSym (cadr NetDBIDcons))

    pSym->pars = (list T1)
    pSym->kids = nil
    pSym->chck = nil
    pSym->otyp = NetDBID->objType
    pSym->ndex = -1
    pSym->dbid = (list NetDBID)
    pSym->chld = nil

    (setq netItem (axlFormTreeViewAddItem RG_g_FORM "Ztree" "Bad Net" T1 nil    'TVSELECT_3STATE RG_x_IMG_GREN_DOT_O RG_x_IMG_GREN_FOP_O RG_x_IMG_GREN_FCL_O))
    pSym->tree = (list netItem)
    (setq RGsl_ITEM_BAD (cons (list netItem pSym) RGsl_ITEM_BAD))
    pSym->item = netItem

;__NOFIX__ Net names can exist as an empty string that's not nil -very weird
    (if (and !(null NetDBID->net->name) {(strlen NetDBID->net->name) > 0})
    then
      pSym->nets = NetDBID->net->name
      (when !(member NetDBID->net->name RGlt_NETS_LIST)
        (setq RGlt_NETS_LIST (cons NetDBID->net->name RGlt_NETS_LIST)))
    else
      pSym->nets = " ") ;empty - single space so it's invisible

    ;--------------------------------------------------------------------------------
    (setq LaysList nil)
    (setq PropNewList (copy RGlt_PROP_LIST)) ;copy all wanted properties into list
    (setq PropAssList nil)
    (setq bBoxList nil)
    (setq ChildbBox nil)

    ;--------------------------------------------------------------------------------
    ; Note: since these branches are obviously connected to a net (how we get them)
    ; they are not technically "Lonely Branches" and are not in RGsl_BAD_BRANCH
    (foreach BranchDBID NetDBID->branches
;save this "lonely branch" walking code for later, might need it...
;      (if (setq BranchCons (assq BranchDBID RGsl_BAD_BRANCH))
;      then
;        (setq BranchpSym (cadr BranchCons))
;        (setq branchItem (axlFormTreeViewAddItem RG_g_FORM "Ztree" "Bad Branch" netItem nil 'TVSELECT_3STATE RG_x_IMG_GREN_DOT_O RG_x_IMG_GREN_FOP_O RG_x_IMG_GREN_FCL_O))
;        BranchpSym->tree = (cons branchItem BranchpSym->tree)
;        pSym->tree = (append pSym->tree BranchpSym->tree)
;        pSym->kids = (cons BranchpSym pSym->kids)
;        (setq RGsl_ITEM_BAD (cons (list branchItem BranchDBID) RGsl_ITEM_BAD))
;      else
;        (setq branchItem (axlFormTreeViewAddItem RG_g_FORM "Ztree" "Branch" netItem nil 'TVSELECT_3STATE RG_x_IMG_GRAY_DIS_X RG_x_IMG_GRAY_DIS_X RG_x_IMG_GRAY_DIS_X))
;        (axlFormTreeViewSetSelectState RG_g_FORM "Ztree" ChildItem 'TVSTATE_DISABLED)
;        (setq RGsl_ITEM_GOOD (cons (list branchItem BranchDBID) RGsl_ITEM_GOOD))
;      )
      (setq branchItem (axlFormTreeViewAddItem RG_g_FORM "Ztree" "Branch" netItem nil 'TVSELECT_3STATE RG_x_IMG_GRAY_DIS_X RG_x_IMG_GRAY_FOP_X RG_x_IMG_GRAY_FCL_X))
      (axlFormTreeViewSetSelectState RG_g_FORM "Ztree" branchItem 'TVSTATE_DISABLED)
      (setq RGsl_ITEM_GOOD (cons (list branchItem BranchDBID) RGsl_ITEM_GOOD))

      (foreach ChildDBID BranchDBID->children
        (setq ChildbBox (_DTL_UTILS_GetBBoxFromDBID ChildDBID))
  ;__FIXME__ Appending is slow!
        (when (_DTL_UTILS_IsBBoxesList ChildbBox)
          (setq bBoxList (append bBoxList ChildbBox)))
        pSym->chld = (cons ChildDBID pSym->chld)
        ; decisions, decisions... I think the best way to deal with layers used
        ; is only to collect them from paths and shapes to speed things up
        ; compared to parsing via paths
        (case ChildDBID->objType
          ("path"
            (when ChildDBID->layer
  ;__HACKS__ Uses the fixed string "ETCH/" in the rex  (rexCompile "^ETCH/") see v1.27 for other options
              (setq LaysName (rexReplace ChildDBID->layer "" 1))
  ;__FIXME__ expensive
              (unless (member LaysName LaysList)
                (setq LaysList (cons LaysName LaysList))))
            (if (setq ChildCons (assq ChildDBID RGsl_BAD_PATH))
            then
              (setq ChildpSym (cadr ChildCons))
              (setq ChildItem axlFormTreeViewAddItem(RG_g_FORM "Ztree" "Bad Path" branchItem nil 'TVSELECT_3STATE RG_x_IMG_GREN_DOT_O RG_x_IMG_GREN_FOP_O RG_x_IMG_GREN_FCL_O))
              ChildpSym->tree = (cons ChildItem ChildpSym->tree)
              pSym->tree = (append pSym->tree ChildpSym->tree)
              pSym->kids = (cons ChildpSym pSym->kids)
              (setq RGsl_ITEM_BAD (cons (list ChildItem ChildpSym) RGsl_ITEM_BAD))
            else
              (setq ChildItem axlFormTreeViewAddItem(RG_g_FORM "Ztree" "Path" branchItem nil 'TVSELECT_3STATE RG_x_IMG_GRAY_DIS_X RG_x_IMG_GRAY_DIS_X RG_x_IMG_GRAY_DIS_X))
              (axlFormTreeViewSetSelectState RG_g_FORM "Ztree" ChildItem 'TVSTATE_DISABLED)
              (setq RGsl_ITEM_GOOD (cons (list ChildItem ChildDBID) RGsl_ITEM_GOOD))))
          ("pin"
            (when ChildDBID->isThrough
              (setq LaysList RGlt_LAYS_LIST))
            (if (setq ChildCons (assq ChildDBID RGsl_BAD_PIN))
            then
              (setq ChildpSym (cadr ChildCons))
              (setq ChildItem axlFormTreeViewAddItem(RG_g_FORM "Ztree" "Bad Pin" branchItem nil 'TVSELECT_3STATE RG_x_IMG_YELL_DOT_O RG_x_IMG_YELL_DOT_O RG_x_IMG_YELL_DOT_O))
              ChildpSym->tree = (cons ChildItem ChildpSym->tree)
              pSym->tree = (append pSym->tree ChildpSym->tree)
              pSym->kids = (cons ChildpSym pSym->kids)
              (setq RGsl_ITEM_BAD (cons (list ChildItem ChildpSym) RGsl_ITEM_BAD))
            else
              (setq ChildItem axlFormTreeViewAddItem(RG_g_FORM "Ztree" "Pin" branchItem nil 'TVSELECT_3STATE RG_x_IMG_GRAY_DIS_X RG_x_IMG_GRAY_DIS_X RG_x_IMG_GRAY_DIS_X))
              (axlFormTreeViewSetSelectState RG_g_FORM "Ztree" ChildItem 'TVSTATE_DISABLED)
              (setq RGsl_ITEM_GOOD (cons (list ChildItem ChildDBID) RGsl_ITEM_GOOD))))
          ("shape"
            (when ChildDBID->layer
  ;__HACKS__ Uses the fixed string "ETCH/" in the rex  (rexCompile "^ETCH/") see v1.27 for other options
              (setq LaysName (rexReplace ChildDBID->layer "" 1))
  ;__FIXME__ expensive
              (unless (member LaysName LaysList) (setq LaysList (cons LaysName LaysList)))
;              (when DMSG (println LaysList DbugFH))
            )
            (if (setq ChildCons (assq ChildDBID RGsl_BAD_SHAPE))
            then
              (setq ChildpSym (cadr ChildCons))
              (setq ChildItem axlFormTreeViewAddItem(RG_g_FORM "Ztree" "Bad Shape" branchItem nil 'TVSELECT_3STATE RG_x_IMG_GREN_DOT_O RG_x_IMG_GREN_FOP_O RG_x_IMG_GREN_FCL_O))
              ChildpSym->tree = (cons ChildItem ChildpSym->tree)
              pSym->tree = (append pSym->tree ChildpSym->tree)
              pSym->kids = (cons ChildpSym pSym->kids)
              (setq RGsl_ITEM_BAD (cons (list ChildItem ChildpSym) RGsl_ITEM_BAD))
            else
              (setq ChildItem axlFormTreeViewAddItem(RG_g_FORM "Ztree" "Shape" branchItem nil 'TVSELECT_3STATE RG_x_IMG_GRAY_DIS_X RG_x_IMG_GRAY_DIS_X RG_x_IMG_GRAY_DIS_X))
              (axlFormTreeViewSetSelectState RG_g_FORM "Ztree" ChildItem 'TVSTATE_DISABLED)
              (setq RGsl_ITEM_GOOD (cons (list ChildItem ChildDBID) RGsl_ITEM_GOOD))))
          ("tee"
  ;          (if (setq ChildCons (assq ChildDBID RGsl_BAD_VIA))
  ;          then
  ;            (setq ChildpSym (cadr ChildCons))
  ;            (setq ChildItem axlFormTreeViewAddItem(RG_g_FORM "Ztree" "Bad tee" branchItem nil 'TVSELECT_3STATE RG_x_IMG_GREN_DOT_O RG_x_IMG_GREN_FOP_O RG_x_IMG_GREN_FCL_O))
  ;            ChildpSym->tree = (cons ChildItem ChildpSym->tree)
  ;            (setq RGsl_ITEM_BAD (cons (list ChildItem ChildpSym) RGsl_ITEM_BAD))
  ;          else
              (setq ChildItem axlFormTreeViewAddItem(RG_g_FORM "Ztree" "Tee" branchItem nil 'TVSELECT_3STATE RG_x_IMG_GRAY_DIS_X RG_x_IMG_GRAY_DIS_X RG_x_IMG_GRAY_DIS_X))
              (axlFormTreeViewSetSelectState RG_g_FORM "Ztree" ChildItem 'TVSTATE_DISABLED)
              (setq RGsl_ITEM_GOOD (cons (list ChildItem ChildDBID) RGsl_ITEM_GOOD))
  ;          )
          )
          ( "via"
            (when ChildDBID->isThrough
              (setq LaysList RGlt_LAYS_LIST)
            )
            (if (setq ChildCons (assq ChildDBID RGsl_BAD_VIA))
            then
              (setq ChildpSym (cadr ChildCons))
              (setq ChildItem axlFormTreeViewAddItem(RG_g_FORM "Ztree" "Bad Via" branchItem nil 'TVSELECT_3STATE RG_x_IMG_GREN_DOT_O RG_x_IMG_GREN_FOP_O RG_x_IMG_GREN_FCL_O))
              ChildpSym->tree = (cons ChildItem ChildpSym->tree)
              pSym->tree = (append pSym->tree ChildpSym->tree)
              pSym->kids = (cons ChildpSym pSym->kids)
              (setq RGsl_ITEM_BAD (cons (list ChildItem ChildpSym) RGsl_ITEM_BAD))
            else
              (setq ChildItem axlFormTreeViewAddItem(RG_g_FORM "Ztree" "Via" branchItem nil 'TVSELECT_3STATE RG_x_IMG_GRAY_DIS_X RG_x_IMG_GRAY_DIS_X RG_x_IMG_GRAY_DIS_X))
              (axlFormTreeViewSetSelectState RG_g_FORM "Ztree" ChildItem 'TVSTATE_DISABLED)
              (setq RGsl_ITEM_GOOD (cons (list ChildItem ChildDBID) RGsl_ITEM_GOOD)))))

;      !(forall NameVal PropAssList !(equal (get_string (car NameVal)) PropName))

        ;if a child object dose not have a wanted property, remove the property
        ;from the list. i.e. all children will have the prop for the net/branch
        ;to be labled as having the propery.
        (when (and ChildDBID->prop {ChildDBID->objType != "tee"})
          (setq PropAssList nil)
          (setq PropAssList (axlDBGetProperties ChildDBID '("user" "allegro")))
          (foreach PropName PropNewList
            (when (and !(null PropAssList) !(assq (concat PropName) PropAssList))
              (setq PropNewList (remd PropName PropNewList))))))) ;remove from list

    ;see if PropNewList is unchanged or nil
    (if (or (equal PropNewList RGlt_PROP_LIST) (null PropNewList))
    then  pSym->prop = (list " ")  ;empty space
    else  pSym->prop = PropNewList)

    ;find center of all objects
    (if (_DTL_UTILS_IsBBoxesList bBoxList)
    then
      (setq FullbBox (_DTL_UTILS_BBoxesCombine bBoxList))
      (setq TmpCenter (_DTL_UTILS_BBoxCenter FullbBox))
      pSym->xval = (car TmpCenter)
      pSym->yval = (cadr TmpCenter)
    else ;oh crap!
      pSym->xval = 0
      pSym->yval = 0)

    ;set layers
    (if (pairp LaysList)
    then  pSym->lays = LaysList
    else  pSym->lays = (list " "))

    (setq BadList (cons pSym BadList))
  );end foreach NetDBID
  ; reverse list order so it matches the item order in the tree view
  (foreach pSym BadList (setq RGls_FULL_LIST (cons pSym RGls_FULL_LIST)))
));end-LET_and_PROCEDURE DT_destub_data_net()


;*******************************************************************************
;FUNCTION: DT_destub_data_chain
;
; Now this is the tough one to grok. There are only three possible types of
; bad ends which begin a linear chain of bad objects:
;     -A Via with one connection
;     -A Path with one connection
;     -A Shape with one connection
;
(procedure (DT_destub_data_chain)
(let (DMSG BadList pSym Connections DBIDList
     BadCons BadpSym BadDBID TempDBID endPoint
     )
  (setq DMSG nil) ;debug printing
  (when DMSG (fprintf DbugFH "\n\n%s\n%s\nFUNCTION: DT_destub_data_chain \n\n" RG_t_LINE1 RG_t_LINE2))
  ; Unbind The Association List (help garbage collector)
  (when (boundp 'RGsl_BAD_CHAIN) (setq RGsl_BAD_CHAIN 'unbound) (gc))
  (setq RGsl_BAD_CHAIN nil)      ; Empty The Association List

  (setq BadEnds (list RGsl_BAD_VIA RGsl_BAD_SHAPE RGsl_BAD_PATH))
  (foreach BadList BadEnds
    (foreach BadCons BadList
      (setq BadpSym (cadr BadCons))
      (setq BadDBID (car BadpSym->dbid))
      (setq Connections (DT_destub_GetConnect BadDBID t))
      (when {(length Connections) == 1}
        (setq DBIDList nil)
        (setq DBIDList (DT_destub_data_walk BadDBID nil))
        (when {(length DBIDList) > 1}       ; deal with via->shape
          (setq startPoint BadDBID)      ; start-point is the current DBID
          (setq endPoint (car DBIDList))  ; end-point is the car of DBIDList
          (setq DBIDList (reverse DBIDList))
          ; save the ending point of the chain, so it can be used to walk past
          ; situations where all but one of the connections are already known
          ; bad chains or items.
          (when !(memq endPoint RGsl_BAD_END)
            (setq RGsl_BAD_END (cons endPoint RGsl_BAD_END)))
          (setq pSym (make_psym))
          pSym->dbid = DBIDList
;          (setq RGsl_BAD_CHAIN (cons (list endPoint pSym) RGsl_BAD_CHAIN))
          (setq RGsl_BAD_CHAIN (cons (list startPoint pSym) RGsl_BAD_CHAIN))))))

  (rexMagic t)
  (rexCompile "^ETCH/")
  (when (boundp 'BadList) (setq BadList 'unbound))
  (setq BadList nil)

  (foreach BadCons RGsl_BAD_CHAIN
    (setq ChainDBID (car BadCons))
    (setq pSym (cadr BadCons))

    pSym->pars = (list T0)
    pSym->kids = nil
    pSym->chld = nil
    pSym->chck = nil
    pSym->otyp = "chain"
    pSym->ndex = -1

    (setq ParentItem (axlFormTreeViewAddItem RG_g_FORM "Ztree" "Bad Chain" T0 nil    'TVSELECT_3STATE RG_x_IMG_GREN_DOT_O RG_x_IMG_GREN_FOP_O RG_x_IMG_GREN_FCL_O))
    pSym->tree = (list ParentItem)
    (setq RGsl_ITEM_BAD (cons (list ParentItem pSym) RGsl_ITEM_BAD))
    pSym->item = ParentItem

    ;get the net from one of the chain child objects.
    (setq ChildDBID (car pSym->dbid))
    (if (and !(null ChildDBID->net->name) {(strlen ChildDBID->net->name) > 0})
    then
      pSym->nets = ChildDBID->net->name
      (when !(member ChildDBID->net->name RGlt_NETS_LIST)
        (setq RGlt_NETS_LIST (cons ChildDBID->net->name RGlt_NETS_LIST)))
    else
      pSym->nets = " ") ;empty - single space so it's invisible

    (setq LaysList nil)
    (setq PropNewList (copy RGlt_PROP_LIST)) ;copy all wanted properties into list
    (setq PropAssList nil)
    (setq bBoxList nil)
    (setq ChildbBox nil)

    (foreach ChildDBID pSym->dbid
      (setq ChildbBox (_DTL_UTILS_GetBBoxFromDBID ChildDBID))
;__FIXME__ Appending is slow!
      (when (_DTL_UTILS_IsBBoxesList ChildbBox)
        (setq bBoxList (append bBoxList ChildbBox)))
      pSym->chld = (cons ChildDBID pSym->chld)

      ; decisions, decisions... I think the best way to deal with layers used
      ; is only to collect them from paths and shapes to speed things up
      ; compared to parsing via paths
      (case ChildDBID->objType
        ("path"
          (when ChildDBID->layer
;__HACKS__ Uses the fixed string "ETCH/" in the rex  (rexCompile "^ETCH/") see v1.27 for other options
            (setq LaysName (rexReplace ChildDBID->layer "" 1))
;__FIXME__ expensive
            (unless (member LaysName LaysList) (setq LaysList (cons LaysName LaysList))))
          (if (setq ChildCons (assq ChildDBID RGsl_BAD_PATH))
          then
            (setq ChildpSym (cadr ChildCons))
            (setq TreeItem axlFormTreeViewAddItem(RG_g_FORM "Ztree" "Bad path" ParentItem nil 'TVSELECT_3STATE RG_x_IMG_GREN_DOT_O RG_x_IMG_GREN_FOP_O RG_x_IMG_GREN_FCL_O))
            ChildpSym->tree = (cons TreeItem ChildpSym->tree)
            pSym->tree = (append pSym->tree ChildpSym->tree)
            pSym->kids = (cons ChildpSym pSym->kids)
            (setq RGsl_ITEM_BAD (cons (list TreeItem ChildpSym) RGsl_ITEM_BAD))
          else
            (setq TreeItem axlFormTreeViewAddItem(RG_g_FORM "Ztree" "Path" ParentItem nil 'TVSELECT_3STATE RG_x_IMG_GRAY_DIS_X RG_x_IMG_GRAY_DIS_X RG_x_IMG_GRAY_DIS_X))
            (axlFormTreeViewSetSelectState RG_g_FORM "Ztree" TreeItem 'TVSTATE_DISABLED)
            (setq RGsl_ITEM_GOOD (cons (list TreeItem ChildDBID) RGsl_ITEM_GOOD))))
        ;NOTE: there are no "pin" objects in a chain
        ("shape"
          (when ChildDBID->layer
;__HACKS__ Uses the fixed string "ETCH/" in the rex  (rexCompile "^ETCH/") see v1.27 for other options
            (setq LaysName (rexReplace ChildDBID->layer "" 1))
;__FIXME__ expensive
            (unless (member LaysName LaysList) (setq LaysList (cons LaysName LaysList)))
            (when DMSG (println LaysList DbugFH)))
          (if (setq ChildCons (assq ChildDBID RGsl_BAD_SHAPE))
          then
            (setq ChildpSym (cadr ChildCons))
            (setq TreeItem axlFormTreeViewAddItem(RG_g_FORM "Ztree" "Bad Shape" ParentItem nil 'TVSELECT_3STATE RG_x_IMG_GREN_DOT_O RG_x_IMG_GREN_FOP_O RG_x_IMG_GREN_FCL_O))
            ChildpSym->tree = (cons TreeItem ChildpSym->tree)
            pSym->tree = (append pSym->tree ChildpSym->tree)
            pSym->kids = (cons ChildpSym pSym->kids)
            (setq RGsl_ITEM_BAD (cons (list TreeItem ChildpSym) RGsl_ITEM_BAD))
          else
            (setq TreeItem axlFormTreeViewAddItem(RG_g_FORM "Ztree" "Shape" ParentItem nil 'TVSELECT_3STATE RG_x_IMG_GRAY_DIS_X RG_x_IMG_GRAY_DIS_X RG_x_IMG_GRAY_DIS_X))
            (axlFormTreeViewSetSelectState RG_g_FORM "Ztree" TreeItem 'TVSTATE_DISABLED)
            (setq RGsl_ITEM_GOOD (cons (list TreeItem ChildDBID) RGsl_ITEM_GOOD))))
        ;NOTE: there are no "tee" objects in a chain
        ("via"
          (when ChildDBID->isThrough
            (setq LaysList RGlt_LAYS_LIST))
          (if (setq ChildCons (assq ChildDBID RGsl_BAD_VIA))
          then
            (setq ChildpSym (cadr ChildCons))
            (setq TreeItem axlFormTreeViewAddItem(RG_g_FORM "Ztree" "Bad Via" ParentItem nil 'TVSELECT_3STATE RG_x_IMG_GREN_DOT_O RG_x_IMG_GREN_FOP_O RG_x_IMG_GREN_FCL_O))
            ChildpSym->tree = (cons TreeItem ChildpSym->tree)
            pSym->tree = (append pSym->tree ChildpSym->tree)
            pSym->kids = (cons ChildpSym pSym->kids)
            (setq RGsl_ITEM_BAD (cons (list TreeItem ChildpSym) RGsl_ITEM_BAD))
          else
            (setq TreeItem axlFormTreeViewAddItem(RG_g_FORM "Ztree" "Via" ParentItem nil 'TVSELECT_3STATE RG_x_IMG_GRAY_DIS_X RG_x_IMG_GRAY_DIS_X RG_x_IMG_GRAY_DIS_X))
            (axlFormTreeViewSetSelectState RG_g_FORM "Ztree" TreeItem 'TVSTATE_DISABLED)
            (setq RGsl_ITEM_GOOD (cons (list TreeItem ChildDBID) RGsl_ITEM_GOOD)))))

      ;if a child object dose not have a wanted property, remove the property
      ;from the list. i.e. all children will have the prop for the net/branch
      ;to be labled as having the propery.
      (when (and ChildDBID->prop {ChildDBID->objType != "tee"})
        (setq PropAssList nil)
        (setq PropAssList (axlDBGetProperties ChildDBID '("user" "allegro")))
        (foreach PropName PropNewList
          (when (and !(null PropAssList) !(assq (concat PropName) PropAssList))
            (setq PropNewList (remd PropName PropNewList)))))) ;remove from list

    ;see if PropNewList is unchanged or nil
    (if (or (equal PropNewList RGlt_PROP_LIST) (null PropNewList))
    then  pSym->prop = (list " ")  ;empty space
    else  pSym->prop = PropNewList)

    ;find center of all objects
    (if (_DTL_UTILS_IsBBoxesList bBoxList)
    then
      (setq FullbBox (_DTL_UTILS_BBoxesCombine bBoxList))
      (setq TmpCenter (_DTL_UTILS_BBoxCenter FullbBox))
      pSym->xval = (car TmpCenter)
      pSym->yval = (cadr TmpCenter)
    else ;oh crap!
      pSym->xval = 0
      pSym->yval = 0)

    ;set layers
    (if (pairp LaysList)
    then  pSym->lays = LaysList
    else  pSym->lays = (list " "))

    (setq BadList (cons pSym BadList))
  );end foreach BadCons

;  ; reverse list order so it matches the item order in the tree view
  (foreach pSym BadList (setq RGls_FULL_LIST (cons pSym RGls_FULL_LIST)))
));end-LET_and_PROCEDURE DT_destub_data_chain()

;*******************************************************************************
;FUNCTION: DT_destub_data_chain
;
;(procedure (DT_destub_data_walk DBID DBIDList "gl")
(procedure (DT_destub_data_walk DBID PrevDBID "gg")
(let (DMSG Connections ConDBID DBIDList)
  (setq DMSG nil) ;debug printing
  (when DMSG (fprintf DbugFH "\n\n%s\n%s\nFUNCTION: DT_destub_data_walk \n\n" RG_t_LINE1 RG_t_LINE2))

  (setq DBIDList nil)
  (setq Connections nil)
  (when DMSG (fprintf DbugFH "%L " DBID->objType))

  (if (axlIsDBIDType DBID)
  then
    (case DBID->objType
      ("path"
        ;get connections to object
        (setq Connections (DT_destub_GetConnect DBID t))
        ;remove previous from connections list
        (setq Connections (remdq PrevDBID Connections))
        ;test the number of connections
        (case (length Connections)
          (0 ; this object is also bad (i.e. only one connection to prev)
            (setq DBIDList (cons DBID DBIDList)))
          (1 ; there's one other connection (besides prev)
            (setq DBIDList (cons DBID DBIDList))
            (setq ConDBID (car Connections))
            (setq DBIDList (append (DT_destub_data_walk ConDBID DBID) DBIDList)))))
      ("shape"
        ;get connections to object
        (setq Connections (DT_destub_GetConnect DBID t))
        ;remove previous from connections list
        (setq Connections (remdq PrevDBID Connections))
        ;test the number of connections
        (case (length Connections)
          (0 ; this object is also bad (i.e. only one connection to prev)
            (setq DBIDList (cons DBID DBIDList)))
          (1 ; there's one other connection (besides prev)
            (setq DBIDList (cons DBID DBIDList))
            (setq ConDBID (car Connections))
            (setq DBIDList (append (DT_destub_data_walk ConDBID DBID) DBIDList)))))
      ("via"
        ;get connections to object
        (setq Connections (DT_destub_GetConnect DBID t))
        ;remove previous from connections list
        (setq Connections (remdq PrevDBID Connections))
        ;test the number of connections
        (case (length Connections)
          (0 ; this object is also bad (i.e. only one connection to prev)
            (setq DBIDList (cons DBID DBIDList)))
          (1 ; there's one other connection (besides prev)
            (setq DBIDList (cons DBID DBIDList))
            (setq ConDBID (car Connections))
            (setq DBIDList (append (DT_destub_data_walk ConDBID DBID) DBIDList)))
          (t ;see if all other via connections are on the same layer
            (unless DBID->testPoint
              (setq LayList nil)
              (foreach ConDBID Connections
                (unless (memq ConDBID->layer LayList)
                  (setq LayList (cons ConDBID->layer LayList))))
              (when {(length LayList) < 2}
                (setq DBIDList (cons DBID DBIDList))))))))

    (when DMSG (fprintf DbugFH "\n"))
    DBIDList
  else
    (fprintf DbugFH "ERROR: DT_destub_data_walk() - Argument Not A DBID: %L\n" DBID)
    nil)
));end-LET_and_PROCEDURE DT_destub_data_walk()

;********************************************************************************
; FUNCTION: DT_destub_sort
;
; Sort grid by a particular column.
;
; As with others, this needs to have a single argument since it's a call back
; function for (axlFormGridSetBatch). We deal with the need for more arguments
; by passing a list of them.
;
(procedure (DT_destub_sort ArgList)
(prog (DMSG RevSort GridList x_col y_row pSym pSymList pSymName x y RowCons)
  (setq DMSG nil) ; debug printing
  (setq x_col (car ArgList))
  (setq RevSort (cadr ArgList))
  (when DMSG (fprintf DbugFH "\n\n%s\n%s\n\nFUNCTION: DT_destub_sort - Sorting...\n\n" RG_t_LINE1 RG_t_LINE2))
;__FIXME__ doesn't seem to work on col8 due to "No Col0" hack in form callback
  (when (or {x_col == 0} (equal x_col 8))
    (fprintf DbugFH "\n\n%s\n%s\n\nERROR: DT_destub_sort - Tried to sort on colum 0 or 8\n\n" RG_t_LINE1 RG_t_LINE2)
    (return nil))

  ; get filter field ENUM box settings -needed for setting visible cell enum
;  (setq FiltLays (get_string (axlFormGetField RG_g_FORM "FilterLays")))
;  (setq FiltProp (get_string (axlFormGetField RG_g_FORM "FilterProp")))
  ;reset the popups used on enums cells, keeps junk from getting in from user selections
  (axlFormBuildPopup RG_g_FORM "popCellProp" (list (list " " " ")))
  (axlFormBuildPopup RG_g_FORM "popCellLays" (list (list " " " ")))

  (setq GridList nil)
  (setq cell (axlFormGridNewCell))
  (for y_row 1 RG_x_SHOW_ROWS ; grab the col value and pSym string
    (putpropq cell x_col col)
    (putpropq cell y_row row)
    (setq cell (axlFormGridGetCell RG_g_FORM "GridField" cell))
    (if {x_col == 1}
    then
      (if cell->check
      then (setq GridList (cons (list 0 cell->scriptLabel) GridList))
      else (setq GridList (cons (list 1 cell->scriptLabel) GridList)))
    else
      (setq GridList (cons (list cell->value cell->scriptLabel) GridList))))
  ; now we can use sortcar, sorting on the first element of each sublist.
  (if (or {x_col == 1} {x_col == 3} {x_col == 4})
  then ;numeric so use lessp for speed.
    (setq GridList (sortcar GridList 'lessp))
  else ; sortcar, alphalessp and sprintf all croak when passed nil
    (setq GridList
        (sortcar GridList
            (lambda (x y)
                (alphalessp
                  (if (null x) then "" else (sprintf nil "%L" x))
                  (if (null y) then "" else (sprintf nil "%L" y)))))))

;__FIXME__ This should be backwards if reverse == true, then reverse sort
  ; reverse sort for "descending" order
  (when !RevSort (setq GridList (reverse GridList)))

  (setq pSymList nil)
  (foreach RowCons GridList
    (setq pSymList (cons (evalstring (cadr RowCons)) pSymList)))
  (DT_destub_ui_set_cb ?pSymLst pSymList ?SetNdex t)
))

;********************************************************************************
;
(procedure (DT_destub_filter_run)
(prog (DMSG FiltNets FiltLays FiltType FiltProp FiltShow pSym yrow)
  (setq DMSG nil) ; debug printing
  (setq FiltNets nil)
  (setq FiltLays nil)
  (setq FiltType nil)
  (setq FiltProp nil)
  (setq FiltShow nil)
  ;disable the form
  (DT_destub_form_enable nil t)
  (setq cell (axlFormGridNewCell))
  (setq RGlx_LITE_TREE nil)   ;kill the tree image change for current
  ;generate a list of nets from selected filter nets grid
  (for yrow 1 (length RGlt_NETS_LIST)
    (putpropq cell 1 col)
    (putpropq cell yrow row)
    (setq cell (axlFormGridGetCell RG_g_FORM "FiltNetsGrid" cell))
    (when cell->check
      (setq FiltNets (cons (nth {yrow - 1} RGlt_NETS_LIST) FiltNets))))
  ;generate a list of layers from selected filter layer grid rows
  (for yrow 1 (length RGlt_LAYS_LIST)
    (putpropq cell 1 col)
    (putpropq cell yrow row)
    (setq cell (axlFormGridGetCell RG_g_FORM "FiltLaysGrid" cell))
    (when cell->check
      (setq FiltLays (cons (nth {yrow - 1} RGlt_LAYS_LIST) FiltLays))))
  ;generate a list of types from selected filter types
  (when (axlFormGetField RG_g_FORM "FiltTypeCheckCHAINS")
    (setq FiltType (cons "chain" FiltType)))
  (when (axlFormGetField RG_g_FORM "FiltTypeCheckNETS")
    (setq FiltType (cons "net" FiltType))  )
  (when (axlFormGetField RG_g_FORM "FiltTypeCheckBRANCHES")
    (setq FiltType (cons "branch" FiltType)))
  (when (axlFormGetField RG_g_FORM "FiltTypeCheckPATHS")
    (setq FiltType (cons "path" FiltType)))
  (when (axlFormGetField RG_g_FORM "FiltTypeCheckPINS")
    (setq FiltType (cons "pin" FiltType)))
  (when (axlFormGetField RG_g_FORM "FiltTypeCheckSHAPES")
    (setq FiltType (cons "shape" FiltType)))
  (when (axlFormGetField RG_g_FORM "FiltTypeCheckVIAS")
    (setq FiltType (cons "via" FiltType)))
  ;generate a list of properties from selected filter properties
  (when (axlFormGetField RG_g_FORM "FiltPropCheckDT_FANOUT")
    (setq FiltProp (cons "DT_FANOUT" FiltProp)))
  (when (axlFormGetField RG_g_FORM "FiltPropCheckDT_IGNORE")
    (setq FiltProp (cons "DT_IGNORE" FiltProp)))
  (when (axlFormGetField RG_g_FORM "FiltPropCheckDT_UNUSED")
    (setq FiltProp (cons "DT_UNUSED" FiltProp)))
  (when (axlFormGetField RG_g_FORM "FiltPropCheckDT_NOCONN")
    (setq FiltProp (cons "DT_NOCONN" FiltProp)))
  ;generate a list of show/selected from filters
  (when (axlFormGetField RG_g_FORM "FiltShowSelected")
    (setq FiltShow (cons t FiltShow)))
  (when (axlFormGetField RG_g_FORM "FiltShowUnselected")
    (setq FiltShow (cons nil FiltShow)))
  (when DMSG (fprintf DbugFH "\n\n%s\n%s\nFUNCTION: DT_destub_filter_run - Current Values\n" RG_t_LINE1 RG_t_LINE2))
  (when DMSG (fprintf DbugFH "FiltNets: %L\n\n" FiltNets))
  (when DMSG (fprintf DbugFH "FiltLays: %L\n\n" FiltLays))
  (when DMSG (fprintf DbugFH "FiltType: %L\n\n" FiltType))
  (when DMSG (fprintf DbugFH "FiltProp: %L\n\n" FiltProp))
  (when DMSG (fprintf DbugFH "FiltShow: %L\n\n" FiltShow))
  ;help the garbage collector
  (when (boundp 'RGls_SHOW_LIST) (setq RGls_SHOW_LIST 'unbound) (gc))
  (setq RGls_SHOW_LIST nil)       ;reset the shown list to nil
  (foreach pSym RGls_FULL_LIST
;__NOFIX__ This crap does not work... -If used as stated in the documentation.
; First they misspelled "collapse" in the documentation. This also fails to
; set the closed folder image and hence messes up the open/closed state.
;    (axlFormTreeViewSet ArgRG_g_FORM "Ztree" 'TV_COLLAPSE pSym->item)
    ;set TreeItem images correctly for "checked" and "unchecked"
    (if pSym->chck
    then
      (foreach ZItem pSym->tree ;use "checked" images with slash
        (if (rexMatchp "Pin" (axlFormTreeViewGetLabel RG_g_FORM "Ztree" ZItem))
        then
          (axlFormTreeViewChangeImages RG_g_FORM "Ztree" ZItem RG_x_IMG_YELL_DOT_X RG_x_IMG_NORM_FOP_X RG_x_IMG_NORM_FCL_X)
          (axlFormTreeViewSetSelectState RG_g_FORM "Ztree" ZItem 'TVSTATE_DISABLED)
        else
          (axlFormTreeViewChangeImages RG_g_FORM "Ztree" ZItem RG_x_IMG_REDD_DOT_X RG_x_IMG_REDF_FOP_X RG_x_IMG_REDF_FCL_X)
          (axlFormTreeViewSetSelectState RG_g_FORM "Ztree" ZItem 'TVSTATE_DISABLED)))
    else
      (foreach ZItem pSym->tree ;use "unchecked" images with slash
        (axlFormTreeViewChangeImages RG_g_FORM "Ztree" ZItem RG_x_IMG_GREN_DOT_X RG_x_IMG_GREN_FOP_X RG_x_IMG_GREN_FCL_X)
        (axlFormTreeViewSetSelectState RG_g_FORM "Ztree" ZItem 'TVSTATE_DISABLED)))
;__FIXME__ I should probably code something better for this... like (cond ..)
    ;filter search tree
    ;NETS - All/None/Match
    (when (or (member pSym->nets FiltNets)
        (and (member "No Nets" FiltNets) {pSym->nets == " "}))
      ;LAYS - All/None/Match
      (when (or !(forall LayName pSym->lays !(member LayName FiltLays))
          (and (member "No Layers" FiltLays) (member " " pSym->lays)))
        ;TYPE - All/None/Match
        (when (member pSym->otyp FiltType)
          ;PROP - All/None/Match
          (when (or !(forall PropName pSym->prop !(member PropName FiltProp))
              (member " " pSym->prop))
            ;SHOW - All/Selected/Unselected
            (when (member pSym->chck FiltShow)
              (setq RGls_SHOW_LIST (cons pSym RGls_SHOW_LIST)))))))

    (putprop pSym -1 'ndex) ;reset index value on all pSym's in FULL_LIST
  );end foreach pSym
  (setq RGls_SHOW_LIST (reverse RGls_SHOW_LIST))  ;reverse to keep orig order
  (setq RG_x_SHOW_ROWS (length RGls_SHOW_LIST))   ;set show length (row count)
  ; set limits for numeric row select boxes
  (axlFormSetFieldLimits RG_g_FORM "VSelectRangeLoVal" 1 RG_x_SHOW_ROWS)
  (axlFormSetFieldLimits RG_g_FORM "VSelectRangeHiVal" 1 RG_x_SHOW_ROWS)
  ; clear entire grid and (re)add columns and rows
  (DT_destub_xcol_init RG_g_FORM)
  (axlFormGridInsertRows RG_g_FORM "GridField" 1 (length RGls_SHOW_LIST))
  (DT_destub_ui_set_cb ?pSymLst RGls_SHOW_LIST ?SetNdex t)
  (DT_destub_form_enable t t)
))


;********************************************************************************
; Delete Selected Objects
(procedure (DT_destub_delete_checked)
(prog (DMSG StartTime pSym yrow i_ndx ShowValue cell DeleteList DeleteLength
       DBID DelPath DelShape DelVia TransMark IsCanceled ViewSet DeleteObj MsgTxt
      )
  (setq DMSG nil) ; debug printing
  (when DMSG (fprintf DbugFH "\n%s\n%s\nFUNCTION: DT_destub_delete_checked\n\n" RG_t_LINE1 RG_t_LINE2))
  ;disable form
  (DT_destub_form_enable nil nil)
  (setq DeleteList nil)
  (setq DelPath nil)
  (setq DelShape nil)
  (setq DelVia nil)

  (axlMeterCreate "Destubifier Delete", "", nil)
  (setq yrow 1)
  (foreach pSym RGls_FULL_LIST
    (when {(mod yrow 50) == 0}
;FIXME sprint lisp formatting
      (axlMeterUpdate (fix {{(float yrow) / (float RG_x_FULL_ROWS)} * 100})
      sprintf(nil "Collecting Selected Objects (%d of %d)" yrow RG_x_FULL_ROWS)))
    (when pSym->chck
      (case pSym->otyp
        ("chain"
          (foreach DBID pSym->dbid
            (case DBID->objType
              ("path"
                (when !(memq DBID DelPath) (setq DelPath (cons DBID DelPath))))
              ("shape"
                (if DBID->shapeBoundary
                then ;dynamic shapes
                  (when !(memq DBID->shapeBoundary DelShape)
                    (setq DelShape (cons DBID->shapeBoundary DelShape)))
                else ;static shapes (filled rectangles etc)
                  (when !(memq DBID DelShape)
                    (setq DelShape (cons DBID DelShape)))))
              ("via"
                (when !(memq DBID DelVia) (setq DelVia (cons DBID DelVia)))))))
        ("net"
          (foreach DBID pSym->chld
            (case DBID->objType
              ("path"
                (when !(memq DBID DelPath) (setq DelPath (cons DBID DelPath))))
              ("shape"
                (if DBID->shapeBoundary
                then ;dynamic shapes
                  (when !(memq DBID->shapeBoundary DelShape)
                    (setq DelShape (cons DBID->shapeBoundary DelShape)))
                else ;static shapes (filled rectangles etc)
                  (when !(memq DBID DelShape)
                    (setq DelShape (cons DBID DelShape)))))
              ("via"
                (when !(memq DBID DelVia) (setq DelVia (cons DBID DelVia)))))))
        ("branch"
          (foreach DBID pSym->chld
            (case DBID->objType
              ("path"
                (when !(memq DBID DelPath) (setq DelPath (cons DBID DelPath))))
              ("shape"
                (if DBID->shapeBoundary
                then ;dynamic shapes
                  (when !(memq DBID->shapeBoundary DelShape)
                    (setq DelShape (cons DBID->shapeBoundary DelShape)))
                else ;static shapes (filled rectangles etc)
                  (when !(memq DBID DelShape)
                    (setq DelShape (cons DBID DelShape)))))
              ("via"
                (when !(memq DBID DelVia) (setq DelVia (cons DBID DelVia)))))))
        ("path"
          (setq DBID (car pSym->dbid))
          (when !(memq DBID DelPath) (setq DelPath (cons DBID DelPath))))
        ("shape"
          (setq DBID (car pSym->dbid))
          (if DBID->shapeBoundary
          then ;dynamic shapes
            (when !(memq DBID->shapeBoundary DelShape)
              (setq DelShape (cons DBID->shapeBoundary DelShape)))
          else ;static shapes (filled rectangles etc)
            (when !(memq DBID DelShape)
              (setq DelShape (cons DBID DelShape)))))
        ("via"
          (setq DBID (car pSym->dbid))
          (when !(memq DBID DelVia) (setq DelVia (cons DBID DelVia))))))

    (preincrement yrow)) ;end foreach

  (axlMeterDestroy)
  ; NOTE: if you delete a via, it changes the DBID of the path attached to it
  (setq DeleteList (append DeleteList DelPath ))  ;delete paths first
  (setq DeleteList (append DeleteList DelShape))  ;then delete shapes
  (setq DeleteList (append DeleteList DelVia))    ;then finally delete vias

  (if (null DeleteList)
  then
    (_DTL_UTILS_ForceMessage "There are no objects selected\nso nothing has been deleted.")
  else
    (setq ViewSet (_DTL_UTILS_SettingsGet))
    (axlVisibleDesign nil)
    (axlVisibleUpdate t)
    (axlMeterCreate "Destubifier Delete", "", t)
    (setq TransMark  (axlDBTransactionStart))
    (setq IsCanceled nil)
    (axlMeterUpdate 0  "Deleting Selected Objects")
    (setq i_cnt 1)

    (setq StartTime (getCurrentTime))

    (setq DeleteLength (length DeleteList))
    (foreach DeleteObj DeleteList
      (when !IsCanceled
        (axlMeterUpdate (fix {{(float i_cnt) / (float DeleteLength)} * 100})
          (sprintf nil "Deleting Selected Objects (%d of %d)" i_cnt DeleteLength))
        (axlDeleteObject DeleteObj)
        ; Allegro "stop" button was hit
        (when (axlMeterIsCancelled) (setq IsCanceled t))
        (preincrement i_cnt)))
    (axlMeterDestroy)
    (if IsCanceled
    then
      (_DTL_UTILS_ForceMessage "Deletion was canceled by\nthe Allegro \"Stop\" button")
      (axlDBTransactionRollback TransMark)
    else
      (setq MsgTxt "Are You Sure You Want To\nDelete The Selected Objects?")
      (when DMSG
        (strcat MsgTxt
          (sprintf nil "\nTIME: %d seconds"
            (compareTime (getCurrentTime) StartTime))))
      (when (axlUIYesNo MsgTxt)
        (axlDBTransactionCommit TransMark)
        (setq MsgTxt "Would You Like To Reanalyze The Design?\n(Or Quit The Destubifier)")
        (if (axlUIYesNo MsgTxt)
        then
          (_DTL_UTILS_SettingsSet ViewSet t nil)
          (DT_destub_init)
        else
          (when DMSG (fprintf DbugFH "\nFUNCTION: DT_destub_delete_checked - User Decided To Close.\n"))
          (axlFormClose ArgRG_g_FORM)))))

  (DT_destub_form_enable t t)
));end- prog & procedure DT_destub_delete_checked


;********************************************************************************
; Set colors on rows
;
(procedure (DT_destub_ui_set_cb @key
    (pSymLst nil)   ;list of pSym structs
    (SetNdex nil)   ;Should we reset the row index?         t/nil
    (DoCheck nil)   ;Should we reset the check status?      t/nil
    (IsCheck nil)   ;the check status we should set it to   t/nil
    (DoXLite nil)   ;Should we highlight a column?          int Col Number
    (DoYLite nil)   ;Should we highlight these rows?        t/nil
    (Recurse 0)     ;recursive level
     "lgggggx"
  )
(let (DMSG ArgList)
  (setq DMSG nil) ; debug printing
  (when DMSG (fprintf DbugFH "\n\n%s\n%s\nFUNCTION: DT_destub_ui_set_cb\n" RG_t_LINE1 RG_t_LINE2))
  (when DMSG (fprintf DbugFH "pSymLst: %L\n" pSymLst))
  (when DMSG (fprintf DbugFH "SetNdex: %L\n" SetNdex))
  (when DMSG (fprintf DbugFH "DoCheck: %L\n" DoCheck))
  (when DMSG (fprintf DbugFH "IsCheck: %L\n" IsCheck))
  (when DMSG (fprintf DbugFH "DoXLite: %L\n" DoXLite))
  (when DMSG (fprintf DbugFH "DoYLite: %L\n" DoYLite))
  (when DMSG (fprintf DbugFH "Recurse: %L\n" Recurse))
  (when DMSG (drain DbugFH))
  (setq ArgList (list pSymLst SetNdex DoCheck IsCheck DoXLite DoYLite Recurse))
  (axlFormGridSetBatch RG_g_FORM "GridField" `DT_destub_ui_set 'ArgList)
  (axlFormGridUpdate RG_g_FORM "GridField")
))

;********************************************************************************
; Set colors on rows
;
(procedure (DT_destub_ui_set ArgList "l")
(prog (DMSG pSym pSymLst SetNdex DoCheck IsCheck DoXLite DoYLite pSymName
       cell y_row FiltLays FiltProp DoCheck IsCheck IsPin IsLite OrigCheck
       RecIndent)
  (setq DMSG nil) ; debug printing
  (setq pSymLst (nth 0 ArgList))  ;list of pSym structs
  (setq SetNdex (nth 1 ArgList))  ;Should we reset the row index?         t/nil
  (setq DoCheck (nth 2 ArgList))  ;Should we reset the check status?      t/nil
  (setq IsCheck (nth 3 ArgList))  ;the check status we should set it to   t/nil
  (setq DoXLite (nth 4 ArgList))  ;Should we highlight a column?          int Col Number
  (setq DoYLite (nth 5 ArgList))  ;Should we highlight these rows?        t/nil
  (setq Recurse (nth 6 ArgList))  ;recursive level

  (setq RecIndent "")
  (for i 1 Recurse (setq RecIndent (strcat RecIndent (sprintf nil "--->"))))
  (when DMSG (fprintf DbugFH "%s%s\n%sFUNCTION: DT_destub_ui_set\n" RecIndent RG_t_LINE3 RecIndent))
  (when DMSG (fprintf DbugFH "%spSymLst: %L\n" RecIndent pSymLst))
  (when DMSG (fprintf DbugFH "%sSetNdex: %L\n" RecIndent SetNdex))
  (when DMSG (fprintf DbugFH "%sDoCheck: %L\n" RecIndent DoCheck))
  (when DMSG (fprintf DbugFH "%sIsCheck: %L\n" RecIndent IsCheck))
  (when DMSG (fprintf DbugFH "%sDoXLite: %L\n" RecIndent DoXLite))
  (when DMSG (fprintf DbugFH "%sDoYLite: %L\n" RecIndent DoYLite))
  (when DMSG (fprintf DbugFH "%sRecurse: %L\n" RecIndent Recurse))
  (when DMSG (fprintf DbugFH "%sLoopsCn: %L\n\n" RecIndent (length pSymLst)))
  (when DMSG (drain DbugFH))
  ;get filter field ENUM box settings -needed for setting visible cell enum
;  (setq FiltLays (get_string (axlFormGetField RG_g_FORM "FilterLays")))
;  (setq FiltProp (get_string (axlFormGetField RG_g_FORM "FilterProp")))
  ;reset the popups used on enums cells, keeps from getting user selections
;  (setq RG_r_popCellProp (axlUIPopupDefine (list (axlFormGetField RG_g_FORM "popCellProp")) (list (list " " " "))))
;  (setq RG_r_popCellLays (axlUIPopupDefine (list (axlFormGetField RG_g_FORM "popCellLays")) (list (list " " " "))))

  (axlFormBuildPopup RG_g_FORM "popCellProp" (list (list " " " ")))
  (axlFormBuildPopup RG_g_FORM "popCellLays" (list (list " " " ")))


  ; get a single cell from the grid, this will be reused for speed
  (setq cell (axlFormGridNewCell))

  (setq IsLite (or DoXLite DoYLite))        ;setup if we do highlighting
  (setq OrigCheck IsCheck)                  ;save the original argument
  (setq y_row 1)                            ;set initial row number (indexed 1)
  (foreach pSym pSymLst
    (setq pSymName (sprintf nil "%L" pSym)) ;get the print name of symbol/struct
    (if (null DoCheck)                      ;test if we set the check status
    then  (setq IsCheck pSym->chck)         ;get existing check status from pSym
    else  (putpropq pSym IsCheck chck))     ;set the check status in the pSym

    (when SetNdex                           ;test if we set the index value
      (putpropq pSym y_row ndex))           ;set the new index value in the pSym

    (if {pSym->otyp == "pin"}               ;get if pSym is a pin
    then  (setq IsPin t)
    else  (setq IsPin nil))

    (if IsCheck ;set TreeItem images correctly for "checked"
    then
      (foreach ZItem pSym->tree ;use "checked" images
        (if (rexMatchp "Pin" (axlFormTreeViewGetLabel RG_g_FORM "Ztree" ZItem))
        then
          (axlFormTreeViewChangeImages RG_g_FORM "Ztree" ZItem RG_x_IMG_YELL_DOT_O RG_x_IMG_NORM_FOP_O RG_x_IMG_NORM_FCL_O)
          (axlFormTreeViewSetSelectState RG_g_FORM "Ztree" ZItem 'TVSTATE_CHECKED)
        else
          (axlFormTreeViewChangeImages RG_g_FORM "Ztree" ZItem RG_x_IMG_REDD_DOT_O RG_x_IMG_REDF_FOP_O RG_x_IMG_REDF_FCL_O)
          (axlFormTreeViewSetSelectState RG_g_FORM "Ztree" ZItem 'TVSTATE_CHECKED)))
    else
      (foreach ZItem pSym->tree ;use "unchecked" images
        (axlFormTreeViewChangeImages RG_g_FORM "Ztree" ZItem RG_x_IMG_GREN_DOT_O RG_x_IMG_GREN_FOP_O RG_x_IMG_GREN_FCL_O)
        (axlFormTreeViewSetSelectState RG_g_FORM "Ztree" ZItem 'TVSTATE_UNCHECKED)))

    (when {pSym->ndex != -1}                  ;test if we have an row index value
      ; Column-1 Check
      (when (or (null DoXLite) {DoXLite == 1})
        (putpropq cell 1          col)
        (putpropq cell pSym->ndex row)
        (putpropq cell pSymName   scriptLabel)
        (putpropq cell nil        popup)
        (putpropq cell IsCheck    check)
        (putpropq cell nil        invisible)
        (putpropq cell nil        value)
        (putpropq cell nil        noEdit)
        (if IsLite
        then
          (putpropq cell 'blue    backColor)
          (putpropq cell 'red     textColor)
        else
; UNIX workaround - active row background is black
;          (putpropq cell 'green   textColor)
          (putpropq cell 'green   backColor)
          (when IsCheck
            (if IsPin
            then  (putpropq cell 'yellow backColor)
            else  (putpropq cell 'red   backColor))))
        ;__NOFIX__ This should fail when row/ndex == -1 but does not fail
        (if (axlFormGridBatch cell)
        then  (when DMSG (fprintf DbugFH "\n%sSucess: row/ndex %d\n" RecIndent pSym->ndex))
        else  (when DMSG (fprintf DbugFH "\n%sFailed: row/ndex %d\n" RecIndent pSym->ndex))))
      ; Column-2 Type
      (when (or (null DoXLite) {DoXLite == 2})
        (putpropq cell 2          col)
        (putpropq cell pSym->ndex row)
        (putpropq cell pSymName   scriptLabel)
        (putpropq cell nil        popup)
        (putpropq cell t          noEdit)
        (putpropq cell nil        check)
        (putpropq cell nil        invisible)
        (putpropq cell pSym->otyp value)
        (if IsLite
        then
          (putpropq cell 'blue    backColor)
          (putpropq cell 'red     textColor)
        else
; UNIX workaround - active row background is black
;          (putpropq cell 'green   textColor)
          (putpropq cell 'white   backColor)
          (when IsCheck
            (if IsPin
            then  (putpropq cell 'yellow backColor)
            else  (putpropq cell 'red   backColor))))
        (axlFormGridBatch cell))
      ; Column-3 X-Value
      (when (or (null DoXLite) {DoXLite == 3})
        (putpropq cell 3          col)
        (putpropq cell pSym->ndex row)
        (putpropq cell pSymName   scriptLabel)
        (putpropq cell nil        popup)
        (putpropq cell t          noEdit)
        (putpropq cell nil        check)
        (putpropq cell nil        invisible)
        (putpropq cell pSym->xval value)
        (if IsLite
        then
          (putpropq cell 'blue    backColor)
          (putpropq cell 'red     textColor)
        else
; UNIX workaround - active row background is black
;          (putpropq cell 'green   textColor)
          (putpropq cell 'white     backColor)
          (when IsCheck
            (if IsPin
            then  (putpropq cell 'yellow backColor)
            else  (putpropq cell 'red   backColor))))
        (axlFormGridBatch cell))
      ; Column-4 Y-Value
      (when (or (null DoXLite) {DoXLite == 4})
        (putpropq cell 4          col)
        (putpropq cell pSym->ndex row)
        (putpropq cell pSymName   scriptLabel)
        (putpropq cell nil        popup)
        (putpropq cell t          noEdit)
        (putpropq cell nil        check)
        (putpropq cell nil        invisible)
        (putpropq cell pSym->yval value)
        (if IsLite
        then
          (putpropq cell 'blue    backColor)
          (putpropq cell 'red     textColor)
        else
; UNIX workaround - active row background is black
;          (putpropq cell 'green   textColor)
          (putpropq cell 'white     backColor)
          (when IsCheck
            (if IsPin
            then  (putpropq cell 'yellow backColor)
            else  (putpropq cell 'red   backColor))))
        (axlFormGridBatch cell))
      ; Column-5 Net
      (when (or (null DoXLite) {DoXLite == 5})
        (putpropq cell 5          col)
        (putpropq cell pSym->ndex row)
        (putpropq cell pSymName   scriptLabel)
        (putpropq cell nil        popup)
        (putpropq cell t          noEdit)
        (putpropq cell nil        check)
        (putpropq cell nil        invisible)
        (putpropq cell pSym->nets value)
        (if IsLite
        then
          (putpropq cell 'blue    backColor)
          (putpropq cell 'red     textColor)
        else
; UNIX workaround - active row background is black
;          (putpropq cell 'green   textColor)
          (putpropq cell 'white     backColor)
          (when IsCheck
            (if IsPin
            then  (putpropq cell 'yellow backColor)
            else  (putpropq cell 'red   backColor))))
        (axlFormGridBatch cell))
      ; Column-6 Layer
      (when (or (null DoXLite) {DoXLite == 6})
        (putpropq cell 6          col)
        (putpropq cell pSym->ndex row)
        (putpropq cell pSymName   scriptLabel)
        (putpropq cell "popCellLays" popup)
        (putpropq cell nil          noEdit)
        (putpropq cell nil        check)
        (putpropq cell nil        invisible)
;        (if (member FiltLays pSym->lays)         ; if filter names a layer and layer is
;          (putpropq cell FiltLays         value) ; in the pSym layer list then display
          (putpropq cell (car pSym->lays) value) ; filter name or else use first in list.
;        )
        (if IsLite
        then
          (putpropq cell 'blue    backColor)
          (putpropq cell 'red     textColor)
        else
; UNIX workaround - active row background is black
;          (putpropq cell 'green   textColor)
          (putpropq cell 'white   backColor)
          (when IsCheck
            (if IsPin
            then  (putpropq cell 'yellow backColor)
            else  (putpropq cell 'red   backColor))))
        (axlFormGridBatch cell))
      ; Column-7 Property (ENUM)
      (when (or (null DoXLite) {DoXLite == 7})
        (putpropq cell 7          col)
        (putpropq cell pSym->ndex row)
        (putpropq cell pSymName   scriptLabel)
        (putpropq cell "popCellProp" popup)
        (putpropq cell nil        noEdit)
        (putpropq cell nil        check)
        (putpropq cell nil        invisible)
;        (if (member FiltProp pSym->prop)         ; if filter names a layer and layer is
;          (putpropq cell FiltProp         value) ; in the pSym layer list then display
          (putpropq cell (car pSym->prop) value) ; filter name or else use first in list.
;        )
        (if IsLite
        then
          (putpropq cell 'blue    backColor)
          (putpropq cell 'red     textColor)
        else
; UNIX workaround - active row background is black
;          (putpropq cell 'green   textColor)
          (putpropq cell 'green   backColor)
          (when IsCheck
            (if IsPin
            then  (putpropq cell 'yellow backColor)
            else  (putpropq cell 'red   backColor))))
        (axlFormGridBatch cell))
      ; Column-8 NDEX -no need to hilight
      (when (or (null DoXLite) {DoXLite == 8})
        (putpropq cell 8          col)
        (putpropq cell pSym->ndex row)
        (putpropq cell pSymName   scriptLabel)
        (putpropq cell nil        popup)
        (putpropq cell t          noEdit)
        (putpropq cell nil        check)
        (putpropq cell pSym->ndex value)
; UNIX workaround - active row background is black
;        (putpropq cell 'green   textColor)
        (putpropq cell 'button    backColor)
        (putpropq cell t          invisible)
        (axlFormGridBatch cell))
      ;end when ndex != -1
      (preincrement y_row))

;__FIXME__ Argument Vars are not restored to their original values when
; returning from the recursive call... very strange... The same is not true
; for non-Argument vars like y_row. This is due to how variable scope works
; in skill, where arguments are global variables.
;
    ;recursive call
    (if pSym->kids
    then
      (when DMSG
        (fprintf DbugFH "%sKids: %d - y_row: %d - ndex: %d - recurse %d\n"
            RecIndent (length pSym->kids) y_row pSym->ndex Recurse))
      (DT_destub_ui_set
        (list
          pSym->kids        ;?pSymLst
          nil               ;?SetNdex -Do Not Reset The Row Index In Recursion
          DoCheck           ;?DoCheck
          OrigCheck         ;?IsCheck
          DoXLite           ;?DoXLite
          DoYLite           ;?DoYLite
          {Recurse + 1}))   ;?Recurse
      --Recurse       ;manual decrement if Recurse counter (should not be necessary)
      (when DMSG (setq RecIndent ""))
      (when DMSG
        (for i 1 Recurse
          (setq RecIndent (strcat RecIndent (sprintf nil "--->")))))
    else
      (when DMSG
        (fprintf DbugFH "%sKids: 0 - y_row: %d - ndex: %d - recurse %d\n"
            RecIndent y_row pSym->ndex Recurse)))
  );end foreach pSym
));end let & procedure
