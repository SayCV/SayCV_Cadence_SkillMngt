;-------------------------------------------------------------------------------
; Copyright (c) 2005, J.C. Roberts <True(@)DigitalLove_org> All Rights Reserved
; http://www.DesignTools.org
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


;*******************************************************************************
;
; Register the command
axlCmdRegister("_DTL_UIGUI_ChooseSubclass", "_DTL_UIGUI_ChooseSubclass")

(defun _DTL_UIGUI_ChooseSubclass ()
(prog ()

  ;generate a form file axlTempFile
  (setq FormFileName axlTempFile())
  
  (setq FormFH outfile( FormFileName "w"))

  (fprintf FormFH "FILE_TYPE=FORM_DEFN VERSION=2 \n")
  (fprintf FormFH "FORM\n")
  (fprintf FormFH "FIXED \n")
  (fprintf FormFH "PORT 28 20\n")
  (fprintf FormFH "HEADER \"Subclass Select\" \n")
  (fprintf FormFH "\n")

  (fprintf FormFH "TILE\n")
  (fprintf FormFH "\n")
  
  (fprintf FormFH "TEXT \"Choose Class and Subclass\"\n")
  (fprintf FormFH "TLOC 2 0\n")
  (fprintf FormFH "ENDTEXT\n")
  (fprintf FormFH "\n")

  (fprintf FormFH "TEXT \"containing dimension data.\"\n")
  (fprintf FormFH "TLOC 2 1\n")
  (fprintf FormFH "ENDTEXT\n")
  (fprintf FormFH "\n")

  (fprintf FormFH "POPUP <class_list> \"\" \"\". \n")
  (fprintf FormFH " \n")

  (fprintf FormFH "TEXT \"Active class:\"  \n")
  (fprintf FormFH "TLOC 2 4 \n")
  (fprintf FormFH "ENDTEXT  \n")
  (fprintf FormFH " \n")

  (fprintf FormFH "FIELD class_name \n")
  (fprintf FormFH "FLOC 2 6 \n")
  (fprintf FormFH "ENUMSET 19 \n")
  (fprintf FormFH "OPTIONS prettyprint \n")
  (fprintf FormFH "POP \"class_list\" \n")
  (fprintf FormFH "ENDFIELD \n")
  (fprintf FormFH " \n")

  (fprintf FormFH "POPUP <subclass_list> \"\" \"\". \n")
  (fprintf FormFH " \n")

  (fprintf FormFH "TEXT \"subclass:\" \n")
  (fprintf FormFH "TLOC 2 8 \n")
  (fprintf FormFH "ENDTEXT  \n")
  (fprintf FormFH "  \n")

  (fprintf FormFH "FIELD subclass_name \n")
  (fprintf FormFH "FLOC 2 10 \n")
  (fprintf FormFH "ENUMSET 19 \n")
  (fprintf FormFH "OPTIONS prettyprint ownerdrawn \n")
  (fprintf FormFH "POP \"subclass_list\" \n")
  (fprintf FormFH "ENDFIELD \n")
  (fprintf FormFH "\n")

  (fprintf FormFH "FIELD done \n")
  (fprintf FormFH "FLOC 2 16 \n")
  (fprintf FormFH "MENUBUTTON \"Done\" 9 3 \n")
  (fprintf FormFH "ENDFIELD \n")
  (fprintf FormFH "\n")

  (fprintf FormFH "FIELD cancel \n")
  (fprintf FormFH "FLOC 14 16 \n")
  (fprintf FormFH "MENUBUTTON \"Cancel\" 9 3 \n")
  (fprintf FormFH "ENDFIELD \n")
  (fprintf FormFH "\n")

  (fprintf FormFH "ENDTILE\n")
  (fprintf FormFH "\n")

  (fprintf FormFH "ENDFORM\n")
  (close FormFH)

  ;--------------------------------------------------------------------------------
  ; The default CLASS and SUBCLASS variables
  ClassName = "BOARD GEOMETRY"
  SubclassName = "DIMENSION"

  ; build the list of class pairs (list of two element lists)
  LayerList = '()
  LayerObj = (axlGetParam "paramLayerGroup")
  foreach( Layer LayerObj->groupMembers
    TmpLyr = (list Layer Layer)
    LayerList = (append LayerList (list TmpLyr)))

  ; build the list of subclass pairs (list of two element lists)
  SubLayerList = '()
  SubLayerObj = (axlGetParam (strcat "paramLayerGroup:" ClassName))
  foreach( SubLayer SubLayerObj->groupMembers
    TmpLyr = (list SubLayer SubLayer)
    SubLayerList = (append SubLayerList (list TmpLyr)))

  ;--------------------------------------------------------------------------------
  ; define the call back funciton
  (defun _formAction ( RForm)
    (case RForm->curField
      ("done"
        (axlFormClose RForm)
        (axlCancelEnterFun)
        t)

      ("cancel"
        ClassName = nil
        SubclassName = nil
        (axlFinishEnterFun)
        (axlFormClose RForm)
        nil)

      ("class_name"
        ClassName = RForm->curValue
        ; rebuild the list of subclass pairs
        SubLayerList = '()
        SubLayerObj = (axlGetParam (strcat "paramLayerGroup:" ClassName))
        foreach( SubLayer SubLayerObj->groupMembers
          TmpLyr = (list SubLayer SubLayer)
          SubLayerList = (append SubLayerList (list TmpLyr))
          )
        ; update the subclass popup
        (axlFormBuildPopup
                  r_form = RForm
                  t_field = "subclass_name"
                  l_pairs = SubLayerList
                  )
        ; set the SubclassName variable to the first item
        SubclassName = (car (car SubLayerList))
        ; set the selected subclass to the first itme in list
        (axlFormSetField RForm, "subclass_name" SubclassName)
        nil)

      ("subclass_name"
        ; set the SubclassName varible to the selected item
        SubclassName = RForm->curValue
        nil)

    ) ; END: case( RForm->curField
  ) ; END: defun( _formAction (RForm)


;  ;--------------------------------------------------------------------------------
;  ; create the compiled form with call back
;  RForm = axlFormCreate(
;          s_formHandle = gensym()
;          t_formfile   = FormFileName
;          lt_placement = '("E" "OUTER") 
;          g_formAction = '_formAction
;          g_nonBlock   = nil
;;          [g_stringOption]
;          )

;  ; create the class drop down select box (a.k.a "POPUP")
;  axlFormBuildPopup( 
;                  r_form = RForm
;                  t_field = "class_name"
;                  l_pairs = LayerList
;                  )


  ;--------------------------------------------------------------------------------
  ; create the compiled form with call back
  (setq RForm 
      (axlFormCreate (gensym) FormFileName '("E" "OUTER") '_formAction nil ))
  
  (printf "\n\n")
  (pprint RForm)
  (printf "\n\n")

  ; create the class drop down select box (a.k.a "POPUP")
  (axlFormBuildPopup RForm "class_name" LayerList )

  ; Set default selected class 
  (axlFormSetField RForm "class_name" ClassName)

  ; create the class drop down select box (a.k.a "POPUP")
  (axlFormBuildPopup
                  r_form = RForm
                  t_field = "subclass_name"
                  l_pairs = SubLayerList
                  )

  ; set default selected subclass
  (axlFormSetField RForm, "subclass_name" SubclassName)

  (axlFormDisplay RForm)

  ; Remove Temporary FORM file
  (axlTempFileRemove FormFileName)


  ; Set return value  
  (if { {ClassName == nil} || {SubclassName == nil} }
  then
    (printf "\nUser Cancel\n")
    (setq RetVal nil)
  else
    (setq RetVal (strcat ClassName "/" SubclassName)))

  (return RetVal)

)) ; END: procedure( _DTL_UIGUI_ChooseSubclass()


