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

;_______________________________________________________________________________
;-------------------------------------------------------------------------------
; Markings:
;   __FIXME__   -Stuff that needs to be fixed
;   __NOFIX__   -Things that are bad but are not fixable
;   __HACKS__   -Sad hacks and work arounds
;   __NOTES__   -Important Notes About Implementation
;-------------------------------------------------------------------------------


/*
--------------------------------------------------------------------------------
  Ideas for Needed Utilities
  
    object to r_path
  
    bbox to r_path
  
    union of bBoxes (i.e. shared/common area between 2 or more bBoxes)
  
    merge r_paths

    bbox intersects  -maybe (dfaBBoxIntersects) ?
  
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
*/

;*******************************************************************************
;
(defun _DTL_UTILS_conf_get ( BaseName "t")
  (let ( DTD LevelFILE LevelUSER LevelSITE)
    (setq DTD t)
    (setq LevelFILE (strcat (_DTL_UTILS_unix_slash (getWorkingDir)) "/" BaseName))

    (if (isFile LevelFILE)
    then
      (printf "\n\nFILE-Level Configuration Found\n%L\n\n" LevelFILE)
      (load LevelFILE)
    else
      (printf "\n\nFILE-Level Configuration MISSING\n%L\n\n" LevelFILE))

    ; The DTG_CONF_USER symbol should always be set to $HOME/.DesignTools/
    ; so throw an error if it's nil.
    (if (boundp 'DTG_CONF_USER)
    then
      (if DTG_CONF_USER
      then
        (when (rexMatchp "\\\\" DTG_CONF_USER)
          (setq DTG_CONF_USER (_DTL_UTILS_unix_slash DTG_CONF_USER)))
        (setq LevelUSER (strcat DTG_CONF_USER "/" BaseName))
        (if (isFile LevelUSER)
        then
          (printf "\n\nUSER-Level Configuration Found\n%L\n\n" LevelUSER)
          (load LevelUSER)
        else
          (printf "\n\nUSER-Level Configuration MISSING\n%L\n\n" LevelUSER))
      else
        (error "(_DTL_UTILS_conf_get)" "Symbol DTG_CONF_USER is not set."))
    else
      (error "(_DTL_UTILS_conf_get)" "Symbol DTG_CONF_USER is not bound."))
    ; The user may not be using USER level configuration so just ignore it if
    ; the DTG_CONF_SITE symbol is nil.
    (if (boundp 'DTG_CONF_SITE)
    then
      (if DTG_CONF_SITE
      then
        (setq LevelSITE (strcat DTG_CONF_SITE "/" BaseName))
        (if (isFile LevelSITE)
        then
          (printf "\n\nSITE-Level Configuration Found\n%L\n\n" LevelSITE)
          (load LevelSITE)
        else
          (printf "\n\nSITE-Level Configuration MISSING\n%L\n\n" LevelSITE))
      else
        (printf "\n\nSITE-Level Configuration Not Used\n\n"))
    else
      (error "(_DTL_UTILS_conf_get)" "Symbol DTG_CONF_SITE is not bound."))

     
;    (error "_DTL_UTILS_conf_get" "Failed To Get Configuration Data")
  ))

;*******************************************************************************
;
(defun _DTL_UTILS_conf_set ( BaseName "t")
  (let ()
    (error "(_DTL_UTILS_conf_set)" "Failed To Set Configuration Data")
  ))

;*******************************************************************************
; In Allegro, the "localenv" directory is where the user keeps his personal
; startup and environment files. This is different from the "env" directory 
; which can hold system/site level files.
; We make sure it is a writable directory and we fix the inconsistent slash and
; backslash nonsense.
(defun _DTL_UTILS_get_localenv ()
  (let ( LocalEnv)
    (setq LocalEnv (_DTL_UTILS_unix_slash (axlGetVariable "localenv")))
    (if (and LocalEnv (stringp LocalEnv) (isDir LocalEnv) (isWritable LocalEnv))
    then
      LocalEnv
    else
      (error "(_DTL_UTILS_get_localenv)" "Allegro Variable \"localenv\" Not Set"))))

;*******************************************************************************
; Translate a path string into UNIX, slingle slash format.
;
; Unfortunately, the (axlOSSlash) function is, obviously Allegro specific. In 
; time, we'll eventually separate axl/Allegro specific code in order to create
; more generic SKILL libraries for use across multiple Cadence products.
;
;__NOTES__: The string passed to rex* functions is evaluated twice, once by the
; initial reading and again by the rex* function,  so you need to be real 
; careful with the derefernece and special characters.
;  "\\"       -Results in an error
;  "\\\\"     -Matches a single \  blackslash
;
(defun _DTL_UTILS_unix_slash ( FQN "t")
  (let ( FQN_new)
    (setq FQN_new FQN)
    (rexMagic t)
    (while (or (rexMatchp "\\\\" FQN_new) (rexMatchp "//" FQN_new))
      (rexCompile "\\\\")                       ; "C:\This\Kind\Of\Crap\"
      (setq FQN_new (rexReplace FQN_new "/" 0))
      (rexCompile "//")                         ; "C://This//Kind//Of//Crap//"
      (setq FQN_new (rexReplace FQN_new "/" 0)))
    FQN_new))


;*******************************************************************************
; Get the the system temp directory in a consistent manner and make sure we can
; write to it.
;
; I know the SKILL command (getTempDir) exists but there's no way of knowing
; what kind of slashing or backslashing nonsense it will return since it is 
; dependent on the underlying operating system.
;
(defun _DTL_UTILS_get_temp ()
  (let ( TempDir)
    (setq TempDir (_DTL_UTILS_unix_slash (getTempDir)))
    (if (and TempDir (stringp TempDir) (isDir TempDir) (isWritable TempDir))
    then
      TempDir
    else
      (error "(_DTL_UTILS_get_temp)" "Temporary Directory Setting Is Bad"))))



;*******************************************************************************
;
; Print Allegro Object "Properties" (not necessarily a lisp "property list")
;
(defun _DTL_UTILS_PrintProp ( FileH GenObj "pg")
(prog ( ElementName i gObjLength)
  (fprintf FileH "\n(\n")
  (setq gObjLength (length GenObj->??))
  (setq i 0)
  (while i < {gObjLength - 1}
    (setq ElementName (nth i GenObj->??))
    (fprintf FileH "  %-18s" ElementName)
    (print (nth (plus i 1) GenObj->??) FileH)
    (fprintf FileH "\n")
    (setq i (plus i 2)))                    ;the "properties" are in pairs
  (fprintf FileH ")\n")
));endfun _DTL_UTILS_PrintProp
   
;*******************************************************************************
; Force User Confirmation Window even if "noconfirm" variable is set.
; Arguments: message string
(defun _DTL_UTILS_ForceMessage ( MessageString "t")
(let ( ConfirmVar)
  ; save the current "noconfirm" variable
  (setq ConfirmVar (axlGetVariable "noconfirm"))
  ; unset/delete the "noconfirm" variable
  (axlUnsetVariable "noconfirm")
  (axlUIWBeep)
  ; force message to user
  (when (axlOKToProceed)
    (axlUIConfirm MessageString))
  ; restore the "noconfirm" variable to it's original setting
  (when ConfirmVar
    (axlSetVariable "noconfirm" ConfirmVar))
));endfun _DTL_UTILS_ForceMessage


;*******************************************************************************
; Make sure the currently open file is the correct type (board, part etc.)
; Arguments: "board" or "symbol"
; Returns: t/nil
(defun _DTL_UTILS_FileTypeCheck ( ArgFileType "t")
(prog ( TmpTxt FileName)
  ; Get the file name of the currently loaded file

;  (setq DType (axlDesignType t))
;  This returns the type of design. Infomation returned may be high level
;  if g_detailed is nil, where values are: "layout" or "symbol".
;
;  If g_detailed is true(t) design type is fully qualified. Types
;  returned are:
;     for layout:     "board", "mcm", "cio", "mdd" (module) or "til" (tile)
;     for symbol:     "package", "mechanical", "format" or "shape",  "flash"
;
  (setq FileName (axlGetVariable "module"))
  (setq TmpTxt nil)
  (if (equal ArgFileType "symbol")
  then
    (rexMagic t)
    (rexCompile "[.]dra$")
    (when !rexMatchp("[.]dra$" FileName)
      (setq TmpTxt (strcat "Currently Open File: \"" FileName "\"\n"))
      (setq TmpTxt (strcat TmpTxt " is not a symbol drawing (*.dra)\n")))
  else
    (when (equal ArgFileType "board")
      (rexMagic t)
      (rexCompile "[.]brd$")
      (when !rexMatchp("[.]brd$" FileName)
        (setq TmpTxt (strcat "Currently Open File: \"" FileName "\"\n"))
        (setq TmpTxt (strcat TmpTxt " is not a board database (*.brd)\n")))))
  
  (if TmpTxt
  then
    (_DTL_UTILS_ForceMessage TmpTxt)
    (return nil)
  else
    (return t))
));endfun _DTL_UTILS_FileTypeCheck 

;*******************************************************************************
; Get Bounding Box of all objects on a subclass
(defun _DTL_UTILS_GetSubClassBBox ( SubClassName "t")
(prog ( DMSG)

  (printf  "\nSTART_: _DTL_PARTS_GetSubClassBBox(%s)\n" SubClassName)
  ; write debug info to file?
  (setq DMSG nil)

  ; get dbug file handle
  (when DMSG
    (if  isFile("__DEBUG_DTL_PARTS_GetSubClassBBox.txt")
    then
      (setq OutDBG_GSCBBox (outfile "__DEBUG_DTL_PARTS_GetSubClassBBox.txt" "a"))
      (fprintf OutDBG_GSCBBox "\n\nSTART FUNCTION: _DTL_PARTS_GetSubClassBBox\n\n")
      (drain OutDBG_GSCBBox)
    else
      (setq OutDBG_GSCBBox (outfile "__DEBUG_DTL_PARTS_GetSubClassBBox.txt" "w"))
      (fprintf OutDBG_GSCBBox "\n\nSTART FUNCTION: _DTL_PARTS_GetSubClassBBox\n\n")
      (drain OutDBG_GSCBBox)))

  ;--------------------------------------------------------------------------------
  ; we also need the bouding box from everything on the 
  ; PACKAGE GEOMETRY/PLACE_BOUND_TOP class. This class should only contain
  ; shapes but who knows what may be on it.
  ;
  ; get everything on the given layer
  (axlClearSelSet)
  (axlVisibleDesign nil)
  (axlVisibleLayer SubClassName t)
;  axlVisibleUpdate(t)
;  axlSetFindFilter( ?enabled (list  "NOALL" "ALLTYPES") 
;                    ?onButtons (list "NOALL" "ALLTYPES"))

  (axlSetFindFilter ?enabled (list   "ALL" "ALLTYPES" "NOTEXT") 
                    ?onButtons (list "ALL" "ALLTYPES" "NOTEXT") )

  (axlAddSelectAll)
  (setq ObjList (axlGetSelSet)) ; get a list of test objects
  (axlClearSelSet)
;  (axlCloseFindFilter)

  ; additional filtering since axlSetFindFilter() is buggy.
  (setq SubClassObjList '())
  (foreach Obj ObjList
    (if (equal Obj->layer SubClassName)
    then
      (setq SubClassObjList append( SubClassObjList (list Obj)))
    else
      (when DMSG
        (fprintf OutDBG_GSCBBox  "\n\n")
        (pprint Obj->layer OutDBG_GSCBBox))))

  (when DMSG
    (fprintf OutDBG_GSCBBox  "SubClassName: %s\n" SubClassName)
    (pprint SubClassObjList->?? OutDBG_GSCBBox )
    (fprintf OutDBG_GSCBBox  "\n\n")
    (drain OutDBG_GSCBBox))

  (if (greaterp (length SubClassObjList) 1)
  then
    (setq PBTbboxList '())
    (foreach SubClassObj SubClassObjList
      (when DMSG
        (fprintf OutDBG_GSCBBox  "\nSubClassObj->??\n")
        (pprint SubClassObj->?? OutDBG_GSCBBox )
        (fprintf OutDBG_GSCBBox  "\n\nPBTbboxlist: \n")
        (pprint BBoxlist OutDBG_GSCBBox )
        (drain OutDBG_GSCBBox))
      (setq PBTbboxList (append PBTbboxList (list SubClassObj->bBox))))
    (setq BBoxlist (_DTL_UTILS_BBoxesCombine PBTbboxList))
    (when DMSG
      (fprintf OutDBG_GSCBBox  "\nBBoxlist1 :\n")
      (pprint BBoxlist OutDBG_GSCBBox )
      (drain OutDBG_GSCBBox))
  else 
    ; is there one object in the returned list.
    (if (eq (length SubClassObjList) 1)
    then
      (setq SubClassObj (car SubClassObjList))
      (setq BBoxlist SubClassObj->bBox)
      (when DMSG
        (fprintf OutDBG_GSCBBox  "\nBBoxlist2 :\n")
        (pprint BBoxlist OutDBG_GSCBBox )
        (drain OutDBG_GSCBBox))
    ; nope, nothing in the list of returned objects
    else
      (setq BBoxlist nil)
      (when DMSG
        (fprintf OutDBG_GSCBBox  "\nBBoxlist3 :\n")
        (pprint BBoxlist OutDBG_GSCBBox )
        (drain OutDBG_GSCBBox))))

  (setq RetVal t)
  (when DMSG
    (fprintf OutDBG_GSCBBox "\nReturn Value: ")
    (println RetVal OutDBG_GSCBBox)
    (println "END: _DTL_PARTS_GetSubClassBBox()" OutDBG_GSCBBox)
    (drain OutDBG_GSCBBox)
;    (close OutDBG_GSCBBox)
  )

  (if BBoxlist
  then
    (printf  "RETURN: %B\n" BBoxlist)
  else
    (printf  "RETURN: nil\n" BBoxlist))
  
  (printf "END___: _DTL_PARTS_GetSubClassBBox(%s)\n" SubClassName)
;  (println "END: _DTL_PARTS_GetSubClassBBox()")

  (return BBoxlist)
));endfun _DTL_UTILS_GetSubClassBBox


;*******************************************************************************
; Get the existing Allegro settings for:
;     Find Filter
;     Selected Set
;     Layer/object Visibility
;     Window Zoom/Center
;
(defun _DTL_UTILS_SettingsGet ()
(let ()
  (list (axlGetSelSet) 
        (axlGetFindFilter t)
        (axlGetFindFilter nil) 
        (axlVisibleGet)
        (axlWindowBoxGet)
        (axlDBControl 'activeLayer))
));endfun _DTL_UTILS_SettingsGet

;*******************************************************************************
; Restore the original settings for:
;     Find Filter
;     Selected Set
;     Layer/object Visibility
;     Window Zoom/Center
;
;__NOFIX__ __SADHACK__
; There's some massive weirdness in 15.2 where occasionally it puts 
; a list member "DYNTHERMALS" in the onButtons list which gets saved 
; by (_DTL_UTILS_SettingsGet) and then it tosses a *WARNING* when you 
; try to (re)set the (imaginary) button again with the exact (bad) data 
; you read from FindFilter originally. 
;
(defun _DTL_UTILS_SettingsSet ( origSettings doUpdate restoreZoom "lgg")
(let ( doEnabled doButtons)

  (axlSingleSelectObject (car origSettings))
  (setq doEnabled (nth 1 origSettings))
  (setq doButtons (nth 2 origSettings))
  (setq doButtons (remove "DYNTHEMALS" doButtons))
  
  (if doButtons
  then
    (axlSetFindFilter ?enabled cons( "noall" doEnabled)
                      ?onButtons cons( "noall" doButtons))
  else
    (axlSetFindFilter ?enabled cons( "noall" doEnabled)
                      ?onButtons (list  "noall")))  
  
  (axlVisibleSet (nth 3 origSettings))
  (when restoreZoom (axlWindowBoxSet (nth 4 origSettings)))
  (axlDBControl 'activeLayer (nth 5 origSettings))
  (when doUpdate
    (axlVisibleUpdate t)           ; update visible objects
    (axlUIWUpdate nil)             ; do UI main window update
    (axlUIWRedraw nil)             ; force refresh of main window
  )
  t
));endfun _DTL_UTILS_SettingsSet


;*******************************************************************************
; Some objects like branches and nets do not have a "bBox" property since they
; are collections of other objects (like paths, vias, shapes etc.).
;
; __FIXME__ This could/should be expanded to handle other types of DBID's at the
; moment, it's only set up to deal with walking nets, branches and children.
;
(defun _DTL_UTILS_GetBBoxFromDBID ( DBID)
(let (myList branch child)
  (setq myList nil)
  (if (axlIsDBIDType DBID)
  then
    (case DBID->objType
      ("net"
        (foreach branch DBID->branches
          (setq myList (append (_DTL_UTILS_GetBBoxFromDBID branch) myList))))
      ("branch"
        (foreach child DBID->children
          (setq myList (cons (car (_DTL_UTILS_GetBBoxFromDBID child)) myList))))
      ("path"
        (setq myList (cons DBID->bBox myList)))
      ("pin"
        (setq myList (cons DBID->bBox myList)))
      ("shape"
        (setq myList (cons DBID->bBox myList)))
      ("tee" ; the bBox of tees is tiny, as small as board accuracy allows.
; __FIXME__ Not safe for metric        
;        (setq myList (cons (bBoxAdd DBID->bBox '((-100 -100) (100 100))) myList))
        (setq myList (cons DBID->bBox myList)))
      ("via"
        (setq myList (cons DBID->bBox myList))))
    myList
  else
    (error "(_DTL_UTILS_GetBBoxFromDBID) - Argument Not A DBID\n"))))


;*******************************************************************************
; Zoom To a List of DBID's
;
;(procedure (_DTL_UTILS_ZoomDBIDList DBIDList MagVal "lx")
(defun _DTL_UTILS_ZoomDBIDList ( DBIDList MagVal "lx")
  (let ( DBIDobj bBoxList bBox NewbBox)
    (foreach DBIDobj DBIDList
      (setq bBoxList (append bBoxList (_DTL_UTILS_GetBBoxFromDBID DBIDobj)))
    )  
    (setq bBox (_DTL_UTILS_BBoxesCombine bBoxList))
    (setq bBox (_DTL_UTILS_BBoxMagnify bBox MagVal))
    (setq NewbBox (axlWindowBoxSet bBox))
; __HACKS__ See _DTL_UTILS_ZoomCenterHack function below for description.
    (_DTL_UTILS_ZoomCenterHack bBox NewbBox)
));endfun _DTL_UTILS_ZoomDBIDList

;*******************************************************************************
; __HACKS__  
;
; Oh this is a wonderfully sad hack to compensate for a broken axlWindowBoxSet
; function. The axlWindowBoxSet function is "supposed" to make adjustments for
; the current screen ratio but it does not work. The result is if you feed it
; a bounding box (bBox) the bBox is not centered on the screen.
;
(defun _DTL_UTILS_ZoomCenterHack ( OldbBox NewbBox "ll")
(let ( DMSG ourx oury ollx olly nurx nury nllx nlly 
        OldLengthX OldLengthY NewLengthX NewLengthY OldCenterX OldCenterY 
        NewCenterX NewCenterY OldCenter NewCenter DiffX DiffY FixbBox EndbBox
      )
  (setq DMSG nil)
  (setq ourx (upperRightX OldbBox))
  (setq oury (upperRightY OldbBox))
  (setq ollx (lowerLeftX OldbBox))
  (setq olly (lowerLeftY OldbBox))

  (setq nurx (upperRightX NewbBox))
  (setq nury (upperRightY NewbBox))
  (setq nllx (lowerLeftX NewbBox))
  (setq nlly (lowerLeftY NewbBox))

  (setq OldLengthX (abs (difference ourx ollx)))
  (setq OldLengthY (abs (difference oury olly)))
  (setq NewLengthX (abs (difference nurx nllx)))
  (setq NewLengthY (abs (difference nury nlly)))

  (setq OldCenterX (plus ollx (quotient OldLengthX 2)))
  (setq OldCenterY (plus olly (quotient OldLengthY 2)))
  (setq NewCenterX (plus nllx (quotient NewLengthX 2)))
  (setq NewCenterY (plus nlly (quotient NewLengthY 2)))
  (setq OldCenter OldCenterX:OldCenterY)
  (setq NewCenter NewCenterX:NewCenterY)

  (setq DiffX (difference OldCenterX NewCenterX))
  (setq DiffY (difference OldCenterY NewCenterY))
  
  (setq nurx (plus nurx DiffX))
  (setq nury (plus nury DiffY))
  (setq nllx (plus nllx DiffX))
  (setq nlly (plus nlly DiffY))

  (setq FixbBox (list nllx:nlly nurx:nury))
  (setq EndbBox (axlWindowBoxSet FixbBox))

  (when DMSG
    (printf "\n_DTL_UTILS_ZoomCenterHack\n")
    (printf "Old_bBox: ") (println OldbBox)
    (printf "Old_Cent: ") (println OldCenter)
    (printf "Old_LenX: ") (println OldLengthX)
    (printf "Old_LenY: ") (println OldLengthY)
    (printf "New_bBox: ") (println NewbBox)
    (printf "New_Cent: ") (println NewCenter)
    (printf "New_LenX: ") (println NewLengthX)
    (printf "New_LenY: ") (println NewLengthY)
    (printf "Fix_bBox: ") (println FixbBox)
    (printf "Fix_BCen: ") (println (_DTL_UTILS_BBoxCenter FixbBox))
    (printf "End_bBox: ") (println NewbBox)
    (printf "End_BCen: ") (println (_DTL_UTILS_BBoxCenter NewbBox)))
));endfun _DTL_UTILS_ZoomCenterHack


;--------------------------------------------------------------------------------
;  bBoxAdd(
;  ; add two bBox lists together, increasing drawing size by 10000
;  NewExtents = bBoxAdd(CurExtents '((-10000 -10000) (10000 10000)))

;*******************************************************************************
; Increase/Decrease the size of a bBox by "X" percent i.e. 200 doubles the size
; 
(defun _DTL_UTILS_BBoxMagnify ( bBox MagVal "lx")
(let ( DMSG LocMagVal llx lly urx ury LengthX LengthY CenterX CenterY Newurx Newury Newllx Newlly)
    (setq DMSG nil)
    (setq LocMagVal (float (quotient (float MagVal) 100)))
    (setq urx (upperRightX bBox))
    (setq ury (upperRightY bBox))
    (setq llx (lowerLeftX bBox))
    (setq lly (lowerLeftY bBox))
    (setq LengthX (abs (difference urx llx)))
    (setq LengthY (abs (difference ury lly)))
    (setq CenterX (plus llx (quotient LengthX 2)))
    (setq CenterY (plus lly (quotient LengthY 2)))
    (setq Newurx (plus CenterX (times (quotient LengthX 2) LocMagVal)))
    (setq Newury (plus CenterY (times (quotient LengthY 2) LocMagVal)))
    (setq Newllx (difference CenterX (times (quotient LengthX 2) LocMagVal)))
    (setq Newlly (difference CenterY (times (quotient LengthY 2) LocMagVal)))
    (when DMSG
      (printf "\n_DTL_UTILS_BBoxMagnify\n")
      (printf "MagVal: %d\n" MagVal)
      (printf "FLOAT.: %f\n" LocMagVal)
      (printf "Old LengthX: %f\n" LengthX)
      (printf "Old LengthY: %f\n" LengthY)
      (printf "New LengthX: %f\n" (abs (difference Newurx Newllx)))
      (printf "New LengthY: %f\n" (abs (difference Newury Newlly))))
    (list Newllx:Newlly Newurx:Newury)
));endfun _DTL_UTILS_BBoxMagnify

;*******************************************************************************
; Find Area Of A Bounding Box
(defun _DTL_UTILS_BBoxArea ( bBoxList "l")
(let ()
  (if (_DTL_UTILS_IsBBoxList bBoxList)
  then
    (times (abs (difference (upperRightY bBoxList) (lowerLeftY bBoxList)))
           (abs (difference (upperRightX bBoxList) (lowerLeftX bBoxList))))
  else
    (error "_DTL_UTILS_BBoxArea - Argument Not A Bounding Box"))))

;*******************************************************************************
; Find Center Of A Bounding Box
(defun _DTL_UTILS_BBoxCenter ( bBoxList "l")
(let ( llx lly urx ury LengthX LengthY CenterX CenterY)
  (if (_DTL_UTILS_IsBBoxList bBoxList)
  then
    (setq urx (upperRightX bBoxList))
    (setq ury (upperRightY bBoxList))
    (setq llx (lowerLeftX bBoxList))
    (setq lly (lowerLeftY bBoxList))
    (setq LengthX (abs (difference urx llx)))
    (setq LengthY (abs (difference ury lly)))
    (setq CenterX (plus llx (quotient LengthX 2)))
    (setq CenterY (plus lly (quotient LengthY 2)))
    (list CenterX CenterY)
  else
    (error "_DTL_UTILS_BBoxCenter - Argument Not A Bounding Box List\n"))))

;*******************************************************************************
; Combine A List Of Bounding Boxes Into A Single Inclusive Bounding Box
;
; NOTE: The (min) and (max) functions do not accept lists so we use (apply).
;
; (_DTL_UTILS_BBoxesCombine (list (list 10.5 11.2)))
; (_DTL_UTILS_BBoxesCombine (list (list 10.5 11.2) (list 7.441 29.9) ))
; (load (strcat CODEPATH "skill/lib/_DTL_UTILS.il"))
;
(defun _DTL_UTILS_BBoxesCombine ( bBoxesList "l")
(prog ( DMSG llxList llyList urxList uryList minllx minlly maxurx maxury bBox XYpair XorY)
  (setq DMSG nil)
  ; since nil is a list, test argument to make sure it's not nil
  (when (null bBoxesList)
    (error "(_DTL_UTILS_BBoxesCombine) - Received nil As Argument List")
    (return nil))   
  ; test argument list to make sure all elements are bBoxes and subelements are floats
  (unless (_DTL_UTILS_IsBBoxesList bBoxesList)
    (error "(_DTL_UTILS_BBoxesCombine) - Argument bBoxesList Is Not A List of bBoxes\n\tbBoxesList: %L\n" bBoxesList)
    (return nil))
  (setq llxList (mapcar '(lambda (bBox) (lowerLeftX bBox)) bBoxesList))
  (setq llyList (mapcar '(lambda (bBox) (lowerLeftY bBox)) bBoxesList))
  (setq urxList (mapcar '(lambda (bBox) (upperRightX bBox)) bBoxesList))
  (setq uryList (mapcar '(lambda (bBox) (upperRightY bBox)) bBoxesList))
  (case (length llxList)
    (0 (error "(_DTL_UTILS_BBoxesCombine)\nDid not recieve bBox List as argument\nbBoxesList: %L\nllxList Died\n" bBoxesList)
       (return nil))
    (1 (setq minllx (car llxList)))
    (t (setq minllx (apply 'min llxList ))))
  (case (length llyList)
    (0 (error "(_DTL_UTILS_BBoxesCombine)\nDid not recieve bBox List as argument\nbBoxesList: %L\nllyList Died\n" bBoxesList)
       (return nil))
    (1 (setq minlly (car llyList)))
    (t (setq minlly (apply 'min llyList ))))
  (case (length urxList)
    (0 (error "(_DTL_UTILS_BBoxesCombine)\nDid not recieve bBox List as argument\nbBoxesList: %L\nurxList Died\n" bBoxesList)
       (return nil))
    (1 (setq maxurx (car urxList)))
    (t (setq maxurx (apply 'max urxList ))))
  (case (length uryList)
    (0 (error "(_DTL_UTILS_BBoxesCombine)\nDid not recieve bBox List as argument\nbBoxesList: %LuryList Died\n" bBoxesList)
       (return nil))
    (1 (setq maxury (car uryList)))
    (t (setq maxury (apply 'max uryList ))))
  (when DMSG
    (printf "\n_DTL_UTILS_BBoxesCombine\n")
    (printf "bBoxesList: ") (println bBoxesList)
    (printf "LowLeftX: ") (println llxList)
    (printf "LowLeftY: ") (println llyList)
    (printf "UpRightX: ") (println urxList)
    (printf "UpRightY: ") (println uryList)
    (printf "Combined: ") (println (list minllx:minlly maxurx:maxury)))
  (return (list minllx:minlly maxurx:maxury ))
));endfun _DTL_UTILS_BBoxesCombine

;*******************************************************************************
; Test if list is a list of bBoxes
; ( ((LLX LLY) (URX URY)) ((LLX LLY) (URX URY)) ((LLX LLY) (URX URY)) )
;
(defun _DTL_UTILS_IsBBoxesList ( bBoxesList "l")
(let ( bBoxList PointList)
  (if 
    (and
      (pairp bBoxesList)
      (forall bBoxList bBoxesList
        (and  
          (pairp bBoxList)
          (eqv (length bBoxList) 2)
          (pairp (car bBoxList))
          (pairp (cadr bBoxList))
          (forall PointList bBoxList
            (and
              (eqv (length PointList) 2)
              (floatp (car PointList))
              (floatp (cadr PointList)))))))
  then
    t
  else
    (error "(_DTL_UTILS_IsbBoxesList) - Argument bBoxesList is not a list of bBoxes\n\tbBoxesList: %L\n" bBoxesList)
    nil)
));endfun _DTL_UTILS_IsBBoxesList

;*******************************************************************************
; Test if list is a bBox list
; bBox: ((LowLeftX LowLeftY) (UpRightX UpRightY))
;
;(procedure (_DTL_UTILS_IsBBoxList bBoxList "l")
(defun _DTL_UTILS_IsBBoxList ( bBoxList "l")
(let ( PointList)
  (if (and  (pairp bBoxList)
      (eqv (length bBoxList) 2)
      (pairp (car bBoxList))
      (pairp (cadr bBoxList))
      (forall PointList bBoxList
        (and
          (eqv (length PointList) 2)
          (floatp (car PointList))
          (floatp (cadr PointList)))))
  then
    t
  else
    (error "(_DTL_UTILS_IsbBoxList) - Argument bBoxList is not a bBox"))))

;*******************************************************************************
; Test if list is a point 
; PointList: (FloatValueX FloatValueY)
;
(defun _DTL_UTILS_IsPointList ( PointList "l")
(let ()
  (if (and (pairp PointList) 
      (eqv (length PointList) 2)
      (floatp (car PointList))
      (floatp (cadr PointList)))
  then
    t
  else
    (error "(_DTL_UTILS_IsPointList) - Argument PointList Members Are Not All Floating Point Numbers"))))

;*******************************************************************************
;
(defun _DTL_UTILS_BBoxDraw ( bBox layer "lt")
(let ()
  ;top line
  (axlDBCreateLine
      (list
          (list (lowerLeftX  bBox) (upperRightY  bBox))
          (list (upperRightX bBox) (upperRightY  bBox)))
      nil
      layer)
  ;bot line
  (axlDBCreateLine
      (list
          (list (lowerLeftX  bBox) (lowerLeftY  bBox))
          (list (upperRightX bBox) (lowerLeftY  bBox)))
      nil
      layer)
  ;left line
  (axlDBCreateLine
      (list
          (list (lowerLeftX  bBox) (upperRightY bBox))
          (list (lowerLeftX  bBox) (lowerLeftY  bBox)))
      nil
      layer)
  ;right line
  (axlDBCreateLine
      (list
          (list (upperRightX bBox) (upperRightY bBox))
          (list (upperRightX bBox) (lowerLeftY  bBox)))
      nil
      layer)
  ;diagonal
  (axlDBCreateLine
      (list
          (list (upperRightX bBox) (upperRightY bBox))
          (list (lowerLeftX  bBox) (lowerLeftY  bBox)))
      nil
      layer)
  (axlDBCreateLine
      (list
          (list (upperRightX bBox) (lowerLeftY  bBox))
          (list (lowerLeftX  bBox) (upperRightY bBox)))
      nil
      layer)

))