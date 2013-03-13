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


/*******************************************************************************
NOTES:

  The goal of the rotator program should be selfevident; it rotates text. The
user chooses the layers (class/subclass) they want to work on, and the value for
degrees of rotation they wish to change from and to. After that, the program
goes to town, changing all text objects with the old rotation value to the new
rotation value.

Though it seems simple enough, how it actually works is far more convoluted
because text objects are read only by default in Allegro. The read only status
means you can not simply change their rotation or any other property. The only
thing you can do with such objects is delete them entirely and that is exactly
what we do.

It would probably be unwise to try rotating text on the actual text center since
this would cause a shift in the bounding box. 

  The height of the actual text is:
      TB->height  + TB->photoWidth

  The width of the actual text is:
  not too sure about this...
      ((TB->width + TB->charSpace) * NumberOfChars ) +  TB->photoWidth

IDEAS:

  add select by area (mouse point/drag selection)
  add better class/subclass settings selection (using checkbox grids)
  add the ability to save settings...

*******************************************************************************/


;*******************************************************************************
; Register the callable command(s)
;
(axlCmdRegister "DT_rotator_main", "DT_rotator_main")


;*******************************************************************************
;
(defun DT_rotator_main ()
(prog 
  ( 
    DTD                 ; bool - debug message flag
    DTP                 ; string - current procedure name
    DTV                 ; DesignTools Program Version String
    DTOP_log            ; port/handle - logging file
    ErrMsg              ; string - error message
    TempDir             ; string - system temporary directory
    DTOB_FORM            ; symbol - for main form file
    FormMainFile        ; string - FQN for form file
    HelpOnlineURL       ; online help url
    HelpLocalURL        ; local help url
  )

  (setq DTD nil)
  (setq DTV "DT-rotator-v1.0")
  (setq HelpOnlineURL
      (strcat "http://www.DesignTools.org/programs/cadence/pcb-editor/rotator/docs.php?"
         DTV))
  (setq FormMainFile nil)
  (setq RG_t_LINE3 "--------------------------------------------------------------------------------")

;  (axlDebug t)  ; Enable AXL debug extended warnings (released in 15.2)
  (rexMagic t)  ; Make sure we have "magic" characters turned on for regex

  ;*****************************************************************************
  ; get the log file output port
  (defun DT_rotator_get_log ()
    (let ( DTP)
      (setq DTP "(DT_rotator_get_log)")
      (unless (setq DTOP_log (outfile "./DT_rotator.log"))
        (setq ErrMsg "ERROR - Can not write log file to current directory.")
        (go EndProg))
      (fprintf DTOP_log "DesignTools rotator Logging")
      (fprintf DTOP_log "\n%s\nCurProcedure: %s\n" RG_t_LINE3 DTP)
      (fprintf DTOP_log       "Log_File....: %L\n" (get_filename DTOP_log))))
  
  ;********************************************************************************
  ; write the form file
  ; note: indentation on the print statements is simply for organization.
  (defun DT_rotator_form_create ()
    (let ( DTP)
      (setq DTP "(DT_rotator_form_create)")
      (fprintf DTOP_log "\n%s\nCurProcedure: %s\n" RG_t_LINE3 DTP)
      ; open the main form file for writing in current directory
      (setq FormMainFile "./DT_rotator.form")
      (unless (setq DTOP_form (outfile FormMainFile "w"))
        (setq ErrMsg (sprintf nil "ERROR: %s Failed to create new file\n%L\n" DTP FormMainFile))
        (go EndProg))
      (setq FormMainFile (get_filename DTOP_form)) ;get FQN for main form file
      ; write out form file contents
      (unless 
        (and 
          (fprintf DTOP_form "FILE_TYPE=FORM_DEFN VERSION=2\n")
          (fprintf DTOP_form "FORM FIXED_FONT\n")
          (fprintf DTOP_form "FIXED\n")
          (fprintf DTOP_form "PORT 54 40\n")
          (fprintf DTOP_form "HEADER \"DesignTools: rotator\"\n")
          (fprintf DTOP_form "DEFAULT \"OpCancelButton\"\n")
          (fprintf DTOP_form "\n")
          ;popups
          (fprintf DTOP_form "POPUP <popClass>\"None\"\"NONE\",\"Nope\"\"NOPE\".\n")
          ;begin tile
          (fprintf DTOP_form "TILE\n")
          (fprintf DTOP_form "\n")
          ;start tab set
          (fprintf DTOP_form "TABSET \"FullTabSet\"\n")
          (fprintf DTOP_form "FLOC 0 0\n")
          (fprintf DTOP_form "FSIZE 55 30\n")
          (fprintf DTOP_form "OPTIONS tabsetDispatch\n")
          (fprintf DTOP_form "\n")
            ;start rotator Tab
            (fprintf DTOP_form "TAB \"Rotator\"\n")
            (fprintf DTOP_form "\n")
              ;--------------------------------------------------------------------------------
              ;start Rotation Group #1
              (fprintf DTOP_form "GROUP \"Rotation Group #1\" RotGroup1\n")
              (fprintf DTOP_form "FLOC 1 0\n")
              (fprintf DTOP_form "FSIZE 22 9\n")
              (fprintf DTOP_form "\n")
                ;Rotation #1 Number
                (fprintf DTOP_form "FIELD Rot1Check\n")
                (fprintf DTOP_form "FLOC 2 2\n")
                (fprintf DTOP_form "CHECKLIST \"Rotate Group #1\"\n")
                (fprintf DTOP_form "ENDFIELD\n")
                (fprintf DTOP_form "\n")
                (fprintf DTOP_form "TEXT \"If Rotation Is:\" RotTxt00\n")
                (fprintf DTOP_form "FLOC 2 4\n")
                (fprintf DTOP_form "FSIZE 15 2\n")
                (fprintf DTOP_form "ENDTEXT\n")
                (fprintf DTOP_form "\n")
                (fprintf DTOP_form "FIELD Rot1Old\n")
                (fprintf DTOP_form "FLOC 18 4\n")
                (fprintf DTOP_form "LONGFILLIN 3 3\n")
                (fprintf DTOP_form "ENDFIELD\n")
                (fprintf DTOP_form "\n")
                (fprintf DTOP_form "TEXT \"Then Change To:\" RotTxt00\n")
                (fprintf DTOP_form "FLOC 2 6\n")
                (fprintf DTOP_form "FSIZE 15 2\n")
                (fprintf DTOP_form "ENDTEXT\n")
                (fprintf DTOP_form "\n")
                (fprintf DTOP_form "FIELD Rot1New\n")
                (fprintf DTOP_form "FLOC 18 6\n")
                (fprintf DTOP_form "LONGFILLIN 3 3\n")
                (fprintf DTOP_form "ENDFIELD\n")
                (fprintf DTOP_form "\n")
              ;end Rotation Group #1
              (fprintf DTOP_form "ENDGROUP\n")
              (fprintf DTOP_form "\n")
              ;--------------------------------------------------------------------------------
              ;start Rotation Group #2
              (fprintf DTOP_form "GROUP \"Rotation Group #2\" RotGroup1\n")
              (fprintf DTOP_form "FLOC 1 9\n")
              (fprintf DTOP_form "FSIZE 22 9\n")
              (fprintf DTOP_form "\n")
                ;Rotation #2 Number
                (fprintf DTOP_form "FIELD Rot2Check\n")
                (fprintf DTOP_form "FLOC 2 11\n")
                (fprintf DTOP_form "CHECKLIST \"Rotate Group #2\"\n")
                (fprintf DTOP_form "ENDFIELD\n")
                (fprintf DTOP_form "\n")
                (fprintf DTOP_form "TEXT \"If Rotation Is:\" RotTxt00\n")
                (fprintf DTOP_form "FLOC 2 13\n")
                (fprintf DTOP_form "FSIZE 15 2\n")
                (fprintf DTOP_form "ENDTEXT\n")
                (fprintf DTOP_form "\n")
                (fprintf DTOP_form "FIELD Rot2Old\n")
                (fprintf DTOP_form "FLOC 18 13\n")
                (fprintf DTOP_form "LONGFILLIN 3 3\n")
                (fprintf DTOP_form "ENDFIELD\n")
                (fprintf DTOP_form "\n")
                (fprintf DTOP_form "TEXT \"Then Change To:\" RotTxt00\n")
                (fprintf DTOP_form "FLOC 2 15\n")
                (fprintf DTOP_form "FSIZE 15 2\n")
                (fprintf DTOP_form "ENDTEXT\n")
                (fprintf DTOP_form "\n")
                (fprintf DTOP_form "FIELD Rot2New\n")
                (fprintf DTOP_form "FLOC 18 15\n")
                (fprintf DTOP_form "LONGFILLIN 3 3\n")
                (fprintf DTOP_form "ENDFIELD\n")
                (fprintf DTOP_form "\n")
              ;end Rotation Group #2
              (fprintf DTOP_form "ENDGROUP\n")
              (fprintf DTOP_form "\n")
              ;--------------------------------------------------------------------------------
              ;start Rotation Group #3
              (fprintf DTOP_form "GROUP \"Rotation Group #3\" RotGroup1\n")
              (fprintf DTOP_form "FLOC 1 18\n")
              (fprintf DTOP_form "FSIZE 22 9\n")
              (fprintf DTOP_form "\n")
                ;Rotation #3 Number
                (fprintf DTOP_form "FIELD Rot3Check\n")
                (fprintf DTOP_form "FLOC 2 20\n")
                (fprintf DTOP_form "CHECKLIST \"Rotate Group #3\"\n")
                (fprintf DTOP_form "ENDFIELD\n")
                (fprintf DTOP_form "\n")
                (fprintf DTOP_form "TEXT \"If Rotation Is:\" RotTxt00\n")
                (fprintf DTOP_form "FLOC 2 22\n")
                (fprintf DTOP_form "FSIZE 15 2\n")
                (fprintf DTOP_form "ENDTEXT\n")
                (fprintf DTOP_form "\n")
                (fprintf DTOP_form "FIELD Rot3Old\n")
                (fprintf DTOP_form "FLOC 18 22\n")
                (fprintf DTOP_form "LONGFILLIN 3 3\n")
                (fprintf DTOP_form "ENDFIELD\n")
                (fprintf DTOP_form "\n")
                (fprintf DTOP_form "TEXT \"Then Change To:\" RotTxt00\n")
                (fprintf DTOP_form "FLOC 2 24\n")
                (fprintf DTOP_form "FSIZE 15 2\n")
                (fprintf DTOP_form "ENDTEXT\n")
                (fprintf DTOP_form "\n")
                (fprintf DTOP_form "FIELD Rot3New\n")
                (fprintf DTOP_form "FLOC 18 24\n")
                (fprintf DTOP_form "LONGFILLIN 3 3\n")
                (fprintf DTOP_form "ENDFIELD\n")
                (fprintf DTOP_form "\n")
              ;end Rotation Group #3
              (fprintf DTOP_form "ENDGROUP\n")
              (fprintf DTOP_form "\n")
              ;--------------------------------------------------------------------------------
              ;start Default Group
              (fprintf DTOP_form "GROUP \"Default Settings\" DefalutGroup1\n")
              (fprintf DTOP_form "FLOC 26 0\n")
              (fprintf DTOP_form "FSIZE 28 4\n")
              (fprintf DTOP_form "\n")
                (fprintf DTOP_form "FIELD DefaultCheck\n")
                (fprintf DTOP_form "FLOC 28 2\n")
                (fprintf DTOP_form "CHECKLIST \"Use Default Subclasses\"\n")
                (fprintf DTOP_form "ENDFIELD\n")
                (fprintf DTOP_form "\n")
              ;end Default Group
              (fprintf DTOP_form "ENDGROUP\n")
              (fprintf DTOP_form "\n")
              ;--------------------------------------------------------------------------------
              ;start Class Group
              (fprintf DTOP_form "GROUP \"Select Class\" ClassGroup1\n")
              (fprintf DTOP_form "FLOC 26 4\n")
              (fprintf DTOP_form "FSIZE 28 5\n")
              (fprintf DTOP_form "\n")
                ;class drop down box            
                (fprintf DTOP_form "FIELD ClassDrop\n")
                (fprintf DTOP_form "FLOC 28 6\n")
                (fprintf DTOP_form "ENUMSET 22\n")
                (fprintf DTOP_form "POP popClass\n")
                (fprintf DTOP_form "ENDFIELD\n")
                (fprintf DTOP_form "\n")
              ;end Class Group
              (fprintf DTOP_form "ENDGROUP\n")
              (fprintf DTOP_form "\n")
              ;--------------------------------------------------------------------------------
              ;start SubClass Group
              (fprintf DTOP_form "GROUP \"Multi-Select SubClasses\" SubClassGroup1\n")
              (fprintf DTOP_form "FLOC 26 9\n")
              (fprintf DTOP_form "FSIZE 28 18\n")
              (fprintf DTOP_form "\n")
                ;subclass list
                (fprintf DTOP_form "FIELD SubClassList\n")
                (fprintf DTOP_form "FLOC 27 11\n")
                (fprintf DTOP_form "LIST \"\" 26 8\n")
                (fprintf DTOP_form "OPTIONS INFO_ONLY MULTISELECT SORT ALPHANUMSORT\n")
                (fprintf DTOP_form "ENDTEXT\n")
                (fprintf DTOP_form "\n")
              ;end SubClass Group
              (fprintf DTOP_form "ENDGROUP\n")
              (fprintf DTOP_form "\n")
            ;end rotator tab
            (fprintf DTOP_form "ENDTAB\n")
            (fprintf DTOP_form "\n")
            ;start Settings Tab
            (fprintf DTOP_form "TAB \"Settings\"\n")
            (fprintf DTOP_form "\n")
;FIXME -The "PACKAGE GEOMETRY" stuff is not exactly a good idea.
;if you're working on a board, this stuff shouldn't exist if the
;parts were made correctly.
                (fprintf DTOP_form "FIELD Set13Check\n")
                (fprintf DTOP_form "FLOC 2 0\n")
                (fprintf DTOP_form "CHECKLIST \"PACKAGE GEOMETRY/SILKSCREEN_TOP\"\n")
                (fprintf DTOP_form "ENDFIELD\n")
                (fprintf DTOP_form "\n")
                (fprintf DTOP_form "FIELD Set14Check\n")
                (fprintf DTOP_form "FLOC 2 2\n")
                (fprintf DTOP_form "CHECKLIST \"PACKAGE GEOMETRY/SILKSCREEN_BOTTOM\"\n")
                (fprintf DTOP_form "ENDFIELD\n")
                (fprintf DTOP_form "\n")
                ;the usual
                (fprintf DTOP_form "FIELD Set01Check\n")
                (fprintf DTOP_form "FLOC 2 4\n")
                (fprintf DTOP_form "CHECKLIST \"BOARD GEOMETRY/SILKSCREEN_TOP\"\n")
                (fprintf DTOP_form "ENDFIELD\n")
                (fprintf DTOP_form "\n")
                (fprintf DTOP_form "FIELD Set02Check\n")
                (fprintf DTOP_form "FLOC 2 6\n")
                (fprintf DTOP_form "CHECKLIST \"BOARD GEOMETRY/SILKSCREEN_BOTTOM\"\n")
                (fprintf DTOP_form "ENDFIELD\n")
                (fprintf DTOP_form "\n")
                (fprintf DTOP_form "FIELD Set03Check\n")
                (fprintf DTOP_form "FLOC 2 8\n")
                (fprintf DTOP_form "CHECKLIST \"BOARD GEOMETRY/ASSEMBLY_TOP\"\n")
                (fprintf DTOP_form "ENDFIELD\n")
                (fprintf DTOP_form "\n")
                (fprintf DTOP_form "FIELD Set04Check\n")
                (fprintf DTOP_form "FLOC 2 10\n")
                (fprintf DTOP_form "CHECKLIST \"BOARD GEOMETRY/ASSEMBLY_BOTTOM\"\n")
                (fprintf DTOP_form "ENDFIELD\n")
                (fprintf DTOP_form "\n")
                (fprintf DTOP_form "FIELD Set05Check\n")
                (fprintf DTOP_form "FLOC 2 12\n")
                (fprintf DTOP_form "CHECKLIST \"BOARD GEOMETRY/DISPLAY_TOP\"\n")
                (fprintf DTOP_form "ENDFIELD\n")
                (fprintf DTOP_form "\n")
                (fprintf DTOP_form "FIELD Set06Check\n")
                (fprintf DTOP_form "FLOC 2 14\n")
                (fprintf DTOP_form "CHECKLIST \"BOARD GEOMETRY/DISPLAY_BOTTOM\"\n")
                (fprintf DTOP_form "ENDFIELD\n")
                (fprintf DTOP_form "\n")
                (fprintf DTOP_form "FIELD Set07Check\n")
                (fprintf DTOP_form "FLOC 2 16\n")
                (fprintf DTOP_form "CHECKLIST \"REF DES/SILKSCREEN_TOP\"\n")
                (fprintf DTOP_form "ENDFIELD\n")
                (fprintf DTOP_form "\n")
                (fprintf DTOP_form "FIELD Set08Check\n")
                (fprintf DTOP_form "FLOC 2 18\n")
                (fprintf DTOP_form "CHECKLIST \"REF DES/SILKSCREEN_BOTTOM\"\n")
                (fprintf DTOP_form "ENDFIELD\n")
                (fprintf DTOP_form "\n")
                (fprintf DTOP_form "FIELD Set09Check\n")
                (fprintf DTOP_form "FLOC 2 20\n")
                (fprintf DTOP_form "CHECKLIST \"REF DES/ASSEMBLY_TOP\"\n")
                (fprintf DTOP_form "ENDFIELD\n")
                (fprintf DTOP_form "\n")
                (fprintf DTOP_form "FIELD Set10Check\n")
                (fprintf DTOP_form "FLOC 2 22\n")
                (fprintf DTOP_form "CHECKLIST \"REF DES/ASSEMBLY_BOTTOM\"\n")
                (fprintf DTOP_form "ENDFIELD\n")
                (fprintf DTOP_form "\n")
                (fprintf DTOP_form "FIELD Set11Check\n")
                (fprintf DTOP_form "FLOC 2 24\n")
                (fprintf DTOP_form "CHECKLIST \"REF DES/DISPLAY_TOP\"\n")
                (fprintf DTOP_form "ENDFIELD\n")
                (fprintf DTOP_form "\n")
                (fprintf DTOP_form "FIELD Set12Check\n")
                (fprintf DTOP_form "FLOC 2 26\n")
                (fprintf DTOP_form "CHECKLIST \"REF DES/DISPLAY_BOTTOM\"\n")
                (fprintf DTOP_form "ENDFIELD\n")
                (fprintf DTOP_form "\n")
              ;start Note Group
              (fprintf DTOP_form "GROUP \"NOTE\" SubClassGroup1\n")
              (fprintf DTOP_form "FLOC 34 15\n")
              (fprintf DTOP_form "FSIZE 20 12\n")
              (fprintf DTOP_form "\n")
                (fprintf DTOP_form "TEXT \"Settings Are NOT\" SetTxt00\n")
                (fprintf DTOP_form "FLOC 35 18\n")
                (fprintf DTOP_form "FSIZE 18 2\n")
                (fprintf DTOP_form "ENDTEXT\n")
                (fprintf DTOP_form "\n")
                (fprintf DTOP_form "TEXT \"Saved Between Runs\" SetTxt00\n")
                (fprintf DTOP_form "FLOC 35 20\n")
                (fprintf DTOP_form "FSIZE 18 2\n")
                (fprintf DTOP_form "ENDTEXT\n")
                (fprintf DTOP_form "\n")
              ;end Note Group
              (fprintf DTOP_form "ENDGROUP\n")
              (fprintf DTOP_form "\n")
            ;end Settings tab
            (fprintf DTOP_form "ENDTAB\n")
            (fprintf DTOP_form "\n")
            ;---------------------------------------------------------------------
            ;start QuickHelp Tab
            (fprintf DTOP_form "TAB \"QuickHelp\"\n")
            (fprintf DTOP_form "\n")
              ;start QuickHelp text messages
              (fprintf DTOP_form "FIELD QHTxtMessage0\n")
              (fprintf DTOP_form "FLOC 0 0\n")
              (fprintf DTOP_form "LIST \"\" 55 15\n")
              (fprintf DTOP_form "OPTIONS INFO_ONLY\n")
              (fprintf DTOP_form "ENDTEXT\n")
              (fprintf DTOP_form "\n")
            ;end QuickHelp tab
            (fprintf DTOP_form "ENDTAB\n")
            (fprintf DTOP_form "\n")
          ;end of tab set
          (fprintf DTOP_form "ENDTABSET\n")
          ;-----------------------------------------------------------------------
          ;online help buttom
          (fprintf DTOP_form "FIELD HelpButtonOnLine\n")
          (fprintf DTOP_form "FLOC 1 31\n")
          (fprintf DTOP_form "MENUBUTTON \"On-Line Help\" 15 3\n")
          (fprintf DTOP_form "ENDFIELD\n")
          (fprintf DTOP_form "\n")
          ;local help
;          (fprintf DTOP_form "FIELD HelpButtonLocal\n")
;          (fprintf DTOP_form "FLOC 17 31\n")
;          (fprintf DTOP_form "MENUBUTTON \"Local Help\" 15 3\n")
;          (fprintf DTOP_form "ENDFIELD\n")
;          (fprintf DTOP_form "\n")
          ;rotate button
          (fprintf DTOP_form "FIELD OpRotateButton\n")
          (fprintf DTOP_form "FLOC 35 31\n")
          (fprintf DTOP_form "MENUBUTTON \"Rotate\" 9 3\n")
          (fprintf DTOP_form "ENDFIELD\n")
          (fprintf DTOP_form "\n")
          ;cancel button
          (fprintf DTOP_form "FIELD OpCancelButton\n")
          (fprintf DTOP_form "FLOC 45 31\n")
          (fprintf DTOP_form "MENUBUTTON \"Close\" 9 3\n")
          (fprintf DTOP_form "ENDFIELD\n")
          (fprintf DTOP_form "\n")
          ;end of form
          (fprintf DTOP_form "ENDTILE\n")
          (fprintf DTOP_form "\n")
          (fprintf DTOP_form "ENDFORM\n"))
        ;end of big unless and
        (setq ErrMsg (sprintf nil "ERROR: %s Failed to write new file\n%L\n" DTP FormMainFile))
        (go EndProg))
      ;flush and close output file
      (when (and (boundp 'DTOP_form) (openportp DTOP_form))
        (unless (and (drain DTOP_form) (close DTOP_form) (setq DTOP_form 'unbound))
          (setq ErrMsg 
            (sprintf nil "\nERROR: %s - Flush/Close failed DTOP_form\n" DTP))
          (go EndProg)))
      ; generate form symbol
      (unless (setq DTOB_FORM (axlFormCreate (gensym) FormMainFile  '( "msglines" 3 "E" "inner" ) 'DT_rotator_form_cb nil))
        (setq ErrMsg (sprintf nil "\nERROR: %s - Failed to load form.\n%L\n" DTP FormMainFile))
        (go EndProg))
    )) ;end let and defun


  ;********************************************************************************
  ; the form callback
  (defun DT_rotator_form_cb ( FormArg "g")
    (let ( DTP)
      (setq DTP "(DT_rotator_form_cb)")
      (fprintf DTOP_log "\n%s\nCurProcedure: %s\n" RG_t_LINE3 DTP)
      (_DTL_UTILS_PrintProp DTOP_log FormArg)
      ; sanity check for form state
      (unless (equal FormArg->doneState 0)
        (when DTD
          (fprintf DTOP_log "\n\nSTATUS: %s - Form not in \"done\" state.\n\n" DTP))
        (axlFormClose FormArg))
      ; The big case...
      (case FormArg->curField
        ("Rot1Check"
          (when (null FormArg->curValue)
            (axlFormSetField FormArg "Rot1Old" nil)
            (axlFormSetField FormArg "Rot1New" nil))  
          (axlFormSetFieldEditable FormArg "Rot1Old" FormArg->curValue)
          (axlFormSetFieldEditable FormArg "Rot1New" FormArg->curValue))
        ("Rot2Check"
          (when (null FormArg->curValue)
            (axlFormSetField FormArg "Rot2Old" nil)
            (axlFormSetField FormArg "Rot2New" nil))  
          (axlFormSetFieldEditable FormArg "Rot2Old" FormArg->curValue)
          (axlFormSetFieldEditable FormArg "Rot2New" FormArg->curValue))
        ("Rot3Check"
          (when (null FormArg->curValue)
            (axlFormSetField FormArg "Rot3Old" nil)
            (axlFormSetField FormArg "Rot3New" nil))
          (axlFormSetFieldEditable FormArg "Rot3Old" FormArg->curValue)
          (axlFormSetFieldEditable FormArg "Rot3New" FormArg->curValue))
        ("ClassDrop"
          (axlFormListDeleteAll FormArg "SubClassList")
          (fprintf DTOP_log "\nCLASS: %s\n" (strcat "paramLayerGroup:" FormArg->curValue))
          (setq subClassList (axlGetParam (strcat "paramLayerGroup:" FormArg->curValue)))
          (fprintf DTOP_log "\nSUBCLASS\n")
          (pprint subClassList->?? DTOP_log)
          (fprintf DTOP_log "\n\n")
          (foreach subClassName subClassList->groupMembers
            (fprintf DTOP_log "SubClassName: %s\n" subClassName)
            (axlFormListAddItem FormArg "SubClassList" subClassName -1))
          (axlFormSetField FormArg "SubClassList" nil))
        ("DefaultCheck"
          (if FormArg->curValue
          then
            (axlFormSetFieldEditable FormArg "SubClassList" nil)
            (axlFormSetFieldEditable FormArg "ClassDrop" nil)
          else
            (axlFormSetFieldEditable FormArg "SubClassList" t)
            (axlFormSetFieldEditable FormArg "ClassDrop" t)
            (axlFormListSelAll FormArg "SubClassList" t)))
        ("FullTabSet"
          (case FormArg->curValue
            ("Settings"  (axlFormSetFieldEditable FormArg "OpRotateButton" nil))
            ("QuickHelp" (axlFormSetFieldEditable FormArg "OpRotateButton" nil))
            ("Rotator"   (axlFormSetFieldEditable FormArg "OpRotateButton" t))
            ("HelpButtonOnLine" (axlHttp HelpOnlineURL))))
        ("OpRotateButton"
          (DT_rotator_do_rotation))
        ("OpCancelButton"
          (fprintf DTOP_log "\nFUNCTION: %s - MainForm->curField == %L\n" DTP FormArg->curField )
          (axlFormClose FormArg))
      ))) ;end big case, let and procedure


  ;********************************************************************************
  ; form initialization
  (defun DT_rotator_form_init ()
    (let (DTP DTD)
      (setq DTP "(DT_rotator_form_init)")
      (fprintf DTOP_log "\n%s\nCurProcedure: %s\n" RG_t_LINE3 DTP)
      (setq DTD nil)
      ;set rotation filling to nil
      (axlFormSetField DTOB_FORM "Rot1Old" nil)
      (axlFormSetField DTOB_FORM "Rot1New" nil)
      (axlFormSetField DTOB_FORM "Rot2Old" nil)
      (axlFormSetField DTOB_FORM "Rot2New" nil)
      (axlFormSetField DTOB_FORM "Rot3Old" nil)
      (axlFormSetField DTOB_FORM "Rot3New" nil)
      ;disable fillins
      (axlFormSetFieldEditable DTOB_FORM "Rot1Old" t)
      (axlFormSetFieldEditable DTOB_FORM "Rot1New" t)  
      (axlFormSetFieldEditable DTOB_FORM "Rot2Old" nil)
      (axlFormSetFieldEditable DTOB_FORM "Rot2New" nil)  
      (axlFormSetFieldEditable DTOB_FORM "Rot3Old" nil)
      (axlFormSetFieldEditable DTOB_FORM "Rot3New" nil)  
      ; enalbe the first rotation set
      (axlFormSetField DTOB_FORM "Rot1Check" t)
      ;set it to use default settings
      (axlFormSetField DTOB_FORM "DefaultCheck" t) 
      (axlFormSetField DTOB_FORM "Set01Check" t)
      (axlFormSetField DTOB_FORM "Set02Check" t)
      (axlFormSetField DTOB_FORM "Set03Check" t)
      (axlFormSetField DTOB_FORM "Set04Check" t)
      (axlFormSetField DTOB_FORM "Set05Check" t)
      (axlFormSetField DTOB_FORM "Set06Check" t)
      (axlFormSetField DTOB_FORM "Set07Check" t)
      (axlFormSetField DTOB_FORM "Set08Check" t)
      (axlFormSetField DTOB_FORM "Set09Check" t)
      (axlFormSetField DTOB_FORM "Set10Check" t)
      (axlFormSetField DTOB_FORM "Set11Check" t)
      (axlFormSetField DTOB_FORM "Set12Check" t)
      (axlFormSetField DTOB_FORM "Set13Check" t)
      (axlFormSetField DTOB_FORM "Set14Check" t)
      ; get list of classes
      (setq classList (axlGetParam "paramLayerGroup"))
      (when DTD
        (fprintf DTOP_log "\nCLASS\n")
        (pprint classList->?? DTOP_log)
        (fprintf DTOP_log "\n\n"))
      (setq pairList nil)
      ;create paired list of class names for popup
      (foreach className classList->groupMembers
        (when DTD (fprintf DTOP_log "Class: %L\n" className))
        (setq pairList (append pairList (list (list className className)))))
      (when DTD (fprintf DTOP_log "\n\nNewLIST: %L\n" pairList))
      (axlFormBuildPopup DTOB_FORM "popClass" pairList) 
      (axlFormSetField DTOB_FORM "ClassDrop" "REF DES")
      ;get the subclasses of the class.
      (setq subClassList (axlGetParam (strcat "paramLayerGroup:" "REF DES")))
      (when DTD
        (fprintf DTOP_log "\nSUBCLASS\n")
        (pprint subClassList->?? DTOP_log)
        (fprintf DTOP_log "\n\n"))
      (foreach subClassName subClassList->groupMembers
        (axlFormListAddItem DTOB_FORM "SubClassList" subClassName -1))
      ;by default we don't use the class/subclass choosers
      (axlFormSetFieldEditable DTOB_FORM "SubClassList" nil)
      (axlFormSetFieldEditable DTOB_FORM "ClassDrop" nil)
      ; open the text quick help file
      (unless (setq DTIP_help
          (infile (strcat (axlGetVariable "designtools") 
              "/rotator/src/DT_rotator_quickhelp.txt")))
        (printf "\n\nERROR: %s - Can Not Open QuickHelp File!\n" DTP)
        (go EndProg))
      ;load text into the QuickHelp tab
      (while (gets CurLine DTIP_help)
        (axlFormListAddItem DTOB_FORM "QHTxtMessage0" CurLine -1))
      (when (and (boundp 'DTIP_help) (openportp DTIP_help))
        (unless (and (close DTIP_help) (setq DTIP_help 'unbound))
          (setq ErrMsg 
            (sprintf nil "\nERROR: %s - Flush/Close failed DTIP_help\n" DTP))))
      ;set the active field so you can just start typing rotation
      (axlFormSetActiveField DTOB_FORM "Rot1Old")
      ;display the form
      (axlFormDisplay DTOB_FORM)
  )) ;end let and defun

  ;********************************************************************************
  ; do rotation
  (defun DT_rotator_do_rotation ()
    (let ( DTP DTD DTDEBUG ViewSet Obj ObjList Ori TmpObj NewObj bBoxCent
           newRot OldRot1 NewRot1 OldRot2 NewRot2 OldRot3 NewRot3 AllList
           SubList ClsName SubName ViewSet LayName urx ury llx lly LengthX 
           LengthY CenterX CenterY TmpCenterX TmpCenterY difX difY NewX NewY
         )
      (setq DTP "(DT_rotator_do_rotation)")
      (fprintf DTOP_log "\n%s\nCurProcedure: %s\n" RG_t_LINE3 DTP)
      (setq DTD nil)
;      (setq DTDEBUG nil)
      (setq OldRot1 (axlFormGetField DTOB_FORM "Rot1Old"))
      (setq NewRot1 (axlFormGetField DTOB_FORM "Rot1New"))
      (setq OldRot2 (axlFormGetField DTOB_FORM "Rot2Old"))
      (setq NewRot2 (axlFormGetField DTOB_FORM "Rot2New"))
      (setq OldRot3 (axlFormGetField DTOB_FORM "Rot3Old"))
      (setq NewRot3 (axlFormGetField DTOB_FORM "Rot3New"))
      (setq AllList nil)
      (if (axlFormGetField DTOB_FORM "DefaultCheck")
      then
        (when (axlFormGetField DTOB_FORM "Set01Check")
          (setq AllList (cons "BOARD GEOMETRY/SILKSCREEN_TOP" AllList)))
        (when (axlFormGetField DTOB_FORM "Set02Check")
          (setq AllList (cons "BOARD GEOMETRY/SILKSCREEN_BOTTOM" AllList)))
        (when (axlFormGetField DTOB_FORM "Set03Check")
          (setq AllList (cons "BOARD GEOMETRY/ASSEMBLY_TOP" AllList)))
        (when (axlFormGetField DTOB_FORM "Set04Check")
          (setq AllList (cons "BOARD GEOMETRY/ASSEMBLY_BOTTOM" AllList)))
        (when (axlFormGetField DTOB_FORM "Set05Check")
          (setq AllList (cons "BOARD GEOMETRY/DISPLAY_TOP" AllList)))
        (when (axlFormGetField DTOB_FORM "Set06Check")
          (setq AllList (cons "BOARD GEOMETRY/DISPLAY_BOTTOM" AllList)))
        (when (axlFormGetField DTOB_FORM "Set07Check")
          (setq AllList (cons "REF DES/SILKSCREEN_TOP" AllList)))
        (when (axlFormGetField DTOB_FORM "Set08Check")
          (setq AllList (cons "REF DES/SILKSCREEN_BOTTOM" AllList)))
        (when (axlFormGetField DTOB_FORM "Set09Check")
          (setq AllList (cons "REF DES/ASSEMBLY_TOP" AllList)))
        (when (axlFormGetField DTOB_FORM "Set10Check")
          (setq AllList (cons "REF DES/ASSEMBLY_BOTTOM" AllList)))
        (when (axlFormGetField DTOB_FORM "Set11Check")
          (setq AllList (cons "REF DES/DISPLAY_TOP" AllList)))
        (when (axlFormGetField DTOB_FORM "Set12Check")
          (setq AllList (cons "REF DES/DISPLAY_BOTTOM" AllList)))
;FIXME -These two PACKAGE GEOMETRY entries should be removed from the default
        (when (axlFormGetField DTOB_FORM "Set13Check")
          (setq AllList (cons "PACKAGE GEOMETRY/SILKSCREEN_TOP" AllList)))
        (when (axlFormGetField DTOB_FORM "Set14Check")
          (setq AllList (cons "PACKAGE GEOMETRY/SILKSCREEN_TOP" AllList)))
      else
        (setq SubList (axlFormListGetSelItems DTOB_FORM "SubClassList"))
        (setq ClsName (axlFormGetField DTOB_FORM "ClassDrop"))
        (foreach SubName SubList
          (setq AllList (cons (strcat ClsName "/" SubName) AllList))))
      ; status logging
      (when DTD (fprintf DTOP_log "\n%s\nAllList: %L\n" RG_t_LINE3 AllList))
      ; collect all text objects on the desired class/subclass layers
      (setq ViewSet (_DTL_UTILS_SettingsGet))
      (axlVisibleDesign nil)
      (foreach LayName AllList
        (axlVisibleLayer LayName t))
      (axlClearSelSet)
      (axlSetFindFilter ?enabled  (list "noall" "text") ?onButtons  (list "noall" "text"))
      (axlAddSelectAll)
      (setq ObjList (axlGetSelSet))
      (_DTL_UTILS_SettingsSet ViewSet nil nil)
      ; status logging
      (when DTD (fprintf DTOP_log "ObjList: %L\n" ObjList))
      ; loop though the list of all the text objects we've collected
      (foreach Obj ObjList
        (setq newRot nil)
        (if (and (axlFormGetField DTOB_FORM "Rot1Check")
            (eq (floor Obj->rotation) OldRot1))
        then
          (setq newRot NewRot1)
        else
          (if (and (axlFormGetField DTOB_FORM "Rot2Check")
              (eq (floor Obj->rotation) OldRot2) )
          then
            (setq newRot NewRot2)
          else
            (if (and (axlFormGetField DTOB_FORM "Rot3Check")
                (eq (floor Obj->rotation) OldRot3))
            then (setq newRot NewRot3))))
        ; when there is a new rotation, then apply it
        (when newRot
          (when DTD 
            (fprintf DTOP_log "\n%s\nOldObj: %L\n" RG_t_LINE3 Obj->??)
            (_DTL_UTILS_PrintProp DTOP_log Obj)
            (fprintf DTOP_log "CHANGED TO: %d\n" newRot))          
          ;create a new text orientation structure
          (setq Ori 
              (make_axlTextOrientation
                  ?textBlock Obj->textBlock,
                  ?rotation  newRot,
                  ?mirrored  Obj->isMirrored,
                  ?justify   Obj->justify))
          ; since we need to figure out what the size of the text object will be
          ; at the correct rotation, we create a temporary text object with the
          ; correct rotation.
          (setq TmpObj (car (car
              (axlDBCreateText 
                  Obj->text
                  Obj->xy
                  Ori 
                  Obj->layer
                  Obj->parent))))
          ; status printing
          (when DTD 
            (fprintf DTOP_log "\n%s\nTmpObj: %L\n" RG_t_LINE3 TmpObj->??)
            (_DTL_UTILS_PrintProp DTOP_log TmpObj)        
            (fprintf DTOP_log "OldbBox: %L    %L\n" 
                Obj->bBox (_DTL_UTILS_BBoxCenter Obj->bBox))
            (fprintf DTOP_log "TmpbBox: %L    %L\n" 
                TmpObj->bBox (_DTL_UTILS_BBoxCenter TmpObj->bBox)))
          ;DEBUG draw bounding box and XY on ORIGINAL
          (when DTDEBUG 
            (_DTL_UTILS_BBoxDraw Obj->bBox "BOARD GEOMETRY/SILKSCREEN_TOP")
            (axlDBCreateLine
              (list 
                  (list (plus       (car Obj->xy) 50) (cadr Obj->xy))
                  (list (difference (car Obj->xy) 50) (cadr Obj->xy)))
              nil "BOARD GEOMETRY/DIMENSION")
            (axlDBCreateLine
              (list
                  (list (car Obj->xy) (plus       (cadr Obj->xy) 50))
                  (list (car Obj->xy) (difference (cadr Obj->xy) 50)))
              nil "BOARD GEOMETRY/DIMENSION"))
          ;DEBUG draw bounding box and XY on TMP
          (when DTDEBUG 
            (_DTL_UTILS_BBoxDraw TmpObj->bBox "BOARD GEOMETRY/SILKSCREEN_BOTTOM")
            (axlDBCreateLine
              (list 
                  (list (plus       (car TmpObj->xy) 50) (cadr TmpObj->xy))
                  (list (difference (car TmpObj->xy) 50) (cadr TmpObj->xy)))
              nil "BOARD GEOMETRY/ASSEMBLY_DETAIL")
            (axlDBCreateLine
              (list
                  (list (car TmpObj->xy) (plus       (cadr TmpObj->xy) 50))
                  (list (car TmpObj->xy) (difference (cadr TmpObj->xy) 50)))
              nil "BOARD GEOMETRY/ASSEMBLY_DETAIL"))
          ; figure out ORIGINAL object size/center
          (setq urx (upperRightX Obj->bBox))
          (setq ury (upperRightY Obj->bBox))
          (setq llx (lowerLeftX Obj->bBox))
          (setq lly (lowerLeftY Obj->bBox))
          (setq LengthX (abs (difference urx llx)))
          (setq LengthY (abs (difference ury lly)))
          (setq CenterX (plus llx (quotient LengthX 2)))
          (setq CenterY (plus lly (quotient LengthY 2)))
          ; figure out the TMP object size/center
          (setq urx (upperRightX TmpObj->bBox))
          (setq ury (upperRightY TmpObj->bBox))
          (setq llx (lowerLeftX TmpObj->bBox))
          (setq lly (lowerLeftY TmpObj->bBox))
          (setq LengthX (abs (difference urx llx)))
          (setq LengthY (abs (difference ury lly)))
          (setq TmpCenterX (plus llx (quotient LengthX 2)))
          (setq TmpCenterY (plus lly (quotient LengthY 2)))
          (setq difX (difference CenterX TmpCenterX))
          (setq difY (difference CenterY TmpCenterY))
          ;calculate our new (X,Y)
          (setq NewX (plus (car  Obj->xy) difX) )
          (setq NewY (plus (cadr Obj->xy) difY) )
          (setq bBoxCent (list NewX NewY))
          ; create a new text object at the correct XY location
          (setq NewObj (car (car
              (axlDBCreateText 
                  Obj->text
                  bBoxCent 
                  Ori 
                  Obj->layer 
                  Obj->parent))))
          ;status printing
          (when DTD 
            (fprintf DTOP_log "NewbBox: %L    %L\n" NewObj->bBox 
                (_DTL_UTILS_BBoxCenter NewObj->bBox))
            (fprintf DTOP_log "\n%s\nNewObj: %L\n" RG_t_LINE3 NewObj->??)
            (_DTL_UTILS_PrintProp DTOP_log NewObj))
          ;DEBUG draw bounding box and XY on NEW
          (when DTDEBUG 
            (_DTL_UTILS_BBoxDraw NewObj->bBox "BOARD GEOMETRY/SILKSCREEN_BOTTOM")
            (axlDBCreateLine
              (list 
                  (list (plus       (car NewObj->xy) 50) (cadr NewObj->xy))
                  (list (difference (car NewObj->xy) 50) (cadr NewObj->xy)))
              nil "BOARD GEOMETRY/ASSEMBLY_DETAIL")
            (axlDBCreateLine
              (list
                  (list (car NewObj->xy) (plus       (cadr NewObj->xy) 50))
                  (list (car NewObj->xy) (difference (cadr NewObj->xy) 50)))
              nil "BOARD GEOMETRY/ASSEMBLY_DETAIL"))
          ;delete the unnecessary temp and old text objects
          (axlDeleteObject TmpObj)
;          (axlDeleteObject NewObj) ;useful for debugging
          (unless DTDEBUG (axlDeleteObject Obj))
        ) ;end if
        (drain DTOP_log)
      ) ;end foreach
      (axlVisibleUpdate t)
  ))


  ;********************************************************************************
  ; main program
  (DT_rotator_get_log)
  (unless (setq TempDir (_DTL_UTILS_get_temp))
    (setq ErrMsg "ERROR - Environment Variable TEMP (MS-Windows) or TMP (UNIX)\nis not set to your temporary directory or is not a writable directory.")
    (go EndProg))
  (unless (setq LocalEnv (_DTL_UTILS_get_localenv))    
     (setq ErrMsg "ERROR: Allegro Variable \"localenv\" is not set.\n")
     (go EndProg))

;  (_DTL_UTILS_conf_get "DT_rotator_cfg.il")

  (DT_rotator_form_create)
  (DT_rotator_form_init)

EndProg
  ; if possible, write error message to log
  (when (and (boundp 'DTOP_log) (openportp DTOP_log) ErrMsg) 
    (fprintf DTOP_log "\n\n%s\n" ErrMsg))
  ; flush and close files
  (when (and (boundp 'DTOP_log) (openportp DTOP_log))
    (unless (and (drain DTOP_log) (close DTOP_log) (setq DTOP_log 'unbound))
      (setq ErrMsg 
        (sprintf nil "\nERROR: %s - Flush/Close failed DTOP_log\n" DTP))))
  (when (and (boundp 'DTIP_help) (openportp DTIP_help))
    (unless (and (close DTIP_help) (setq DTIP_help 'unbound))
      (setq ErrMsg 
        (sprintf nil "\nERROR: %s - Flush/Close failed DTIP_help\n" DTP))))

  ;show the error message and log file
  (when ErrMsg
    (printf ErrMsg)
    (axlUIConfirm ErrMsg)
;    (axlUIViewFileCreate (strcat TempDir "/DT_rotator.log") "DT rotator Log" nil)
    (when (axlOKToProceed) (return nil)))

));end let & procedure

