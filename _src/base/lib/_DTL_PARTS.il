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


/*
  _DTL_UTILS_BBoxAdd( bbox 
  _DTL_UTILS_BBoxSubtract( bbox
  _DTL_UTILS_BBoxGrow( bbox
  _DTL_UTILS_BBoxGrow( bbox
  increase
  decrease
*/ 

; Requires

;load( strcat( (axlGetVariable "designtools") "/base/lib/_DTL_UIGUI.il"))
;load( strcat( (axlGetVariable "designtools") "/base/lib/_DTL_UTILS.il"))

;*******************************************************************************
;
; Register the commands
  axlCmdRegister("_DTL_PARTS_SetCheckColors", "_DTL_PARTS_SetCheckColors")
  axlCmdRegister("_DTL_PARTS_ZMoveDim2PGDim", "_DTL_PARTS_ZMoveDim2PGDim")
  axlCmdRegister("_DTL_PARTS_DeleteJunkSubclass", "_DTL_PARTS_DeleteJunkSubclass")
;  axlCmdRegister("_DTL_PARTS_InfoSubclassCreate", "_DTL_PARTS_InfoSubclassCreate")
  axlCmdRegister("_DTL_PARTS_PartCheck", "_DTL_PARTS_PartCheck")

;*******************************************************************************
; global variables
;
;__DEBUG_PRINT__ = t

; User defined subclasses
GV_PACKAGE_GEOMETRY_DIMENSION     = "PACKAGE GEOMETRY/DIMENSION"
GV_PACKAGE_GEOMETRY_INFO_INTERNAL = "PACKAGE GEOMETRY/INFO_INTERNAL"
GV_PACKAGE_GEOMETRY_INFO_EXTERNAL = "PACKAGE GEOMETRY/INFO_EXTERNAL"

; User interaction
GV_SHOW_PROMPTS = nil           ; annoy user with prompts
GV_SHOW_INSTRUCTIONS = nil    ; further annoy user with instructions
GV_SHOW_PROMPTS_ANNOY = nil   ; might as well be a bastard

; Defaults for TextBlock Size and Through Hole
GV_BASE_TEXTBLOCK_SIZE = 3     ; Use this whereever you need a textBlock size
GV_BASE_THROUGH_HOLE = nil

; base tests
IsTest_Chk_BASE_PART_ORIGIN                         = nil
IsGood_Chk_BASE_PART_ORIGIN                         = nil
IsTest_Chk_BASE_THROUGH_HOLE                        = nil
IsGood_Chk_BASE_THROUGH_HOLE                        = nil
IsTest_Chk_BASE_TEXTBLOCK_SIZE                      = nil
IsGood_Chk_BASE_TEXTBLOCK_SIZE                      = nil

; Tests for Class "REF DES"
IsTest_Chk_REF_DES_DISPLAY_BOTTOM                   = nil
IsGood_Chk_REF_DES_DISPLAY_BOTTOM                   = nil
IsTest_Chk_REF_DES_DISPLAY_TOP                      = nil
IsGood_Chk_REF_DES_DISPLAY_TOP                      = nil
IsTest_Chk_REF_DES_SILKSCREEN_BOTTOM                = nil
IsGood_Chk_REF_DES_SILKSCREEN_BOTTOM                = nil
IsTest_Chk_REF_DES_SILKSCREEN_TOP                   = nil
IsGood_Chk_REF_DES_SILKSCREEN_TOP                   = nil
IsTest_Chk_REF_DES_ASSEMBLY_BOTTOM                  = nil
IsGood_Chk_REF_DES_ASSEMBLY_BOTTOM                  = nil
IsTest_Chk_REF_DES_ASSEMBLY_TOP                     = nil
IsGood_Chk_REF_DES_ASSEMBLY_TOP                     = nil

; Tests for Class "PACKAGE GEOMETRY"
IsTest_Chk_PACKAGE_GEOMETRY_MODULES                 = nil
IsGood_Chk_PACKAGE_GEOMETRY_MODULES                 = nil
IsTest_Chk_PACKAGE_GEOMETRY_DISPLAY_BOTTOM          = nil
IsGood_Chk_PACKAGE_GEOMETRY_DISPLAY_BOTTOM          = nil
IsTest_Chk_PACKAGE_GEOMETRY_DISPLAY_TOP             = nil
IsGood_Chk_PACKAGE_GEOMETRY_DISPLAY_TOP             = nil
IsTest_Chk_PACKAGE_GEOMETRY_SOLDERMASK_BOTTOM       = nil
IsGood_Chk_PACKAGE_GEOMETRY_SOLDERMASK_BOTTOM       = nil
IsTest_Chk_PACKAGE_GEOMETRY_SOLDERMASK_TOP          = nil
IsGood_Chk_PACKAGE_GEOMETRY_SOLDERMASK_TOP          = nil
IsTest_Chk_PACKAGE_GEOMETRY_BODY_CENTER             = nil
IsGood_Chk_PACKAGE_GEOMETRY_BODY_CENTER             = nil
IsTest_Chk_PACKAGE_GEOMETRY_SILKSCREEN_BOTTOM       = nil
IsGood_Chk_PACKAGE_GEOMETRY_SILKSCREEN_BOTTOM       = nil
IsTest_Chk_PACKAGE_GEOMETRY_SILKSCREEN_TOP          = nil
IsGood_Chk_PACKAGE_GEOMETRY_SILKSCREEN_TOP          = nil
IsTest_Chk_PACKAGE_GEOMETRY_PAD_STACK_NAME          = nil
IsGood_Chk_PACKAGE_GEOMETRY_PAD_STACK_NAME          = nil
IsTest_Chk_PACKAGE_GEOMETRY_PIN_NUMBER              = nil
IsGood_Chk_PACKAGE_GEOMETRY_PIN_NUMBER              = nil
IsTest_Chk_PACKAGE_GEOMETRY_PLACE_BOUND_BOTTOM      = nil
IsGood_Chk_PACKAGE_GEOMETRY_PLACE_BOUND_BOTTOM      = nil
IsTest_Chk_PACKAGE_GEOMETRY_PLACE_BOUND_TOP         = nil
IsGood_Chk_PACKAGE_GEOMETRY_PLACE_BOUND_TOP         = nil
IsTest_Chk_PACKAGE_GEOMETRY_ASSEMBLY_BOTTOM         = nil
IsGood_Chk_PACKAGE_GEOMETRY_ASSEMBLY_BOTTOM         = nil
IsTest_Chk_PACKAGE_GEOMETRY_ASSEMBLY_TOP            = nil
IsGood_Chk_PACKAGE_GEOMETRY_ASSEMBLY_TOP            = nil
IsTest_Chk_PACKAGE_GEOMETRY_DIMENSION               = nil
IsGood_Chk_PACKAGE_GEOMETRY_DIMENSION               = nil
IsTest_Chk_PACKAGE_GEOMETRY_TEXTDATA_FIXED          = nil
IsGood_Chk_PACKAGE_GEOMETRY_TEXTDATA_FIXED          = nil
IsTest_Chk_PACKAGE_GEOMETRY_TEXTDATA_VARIABLE       = nil
IsGood_Chk_PACKAGE_GEOMETRY_TEXTDATA_VARIABLE       = nil

;________________________________________________________________________________
;********************************************************************************
;--------------------------------------------------------------------------------
; _DTL_PARTS_*
;
; ooohh, aaahh magical part checking and correcting logic.
;
; Well, producing a part checking and correcting program is going to be 
; nontrivial at best and at worst it may be close to impossible.
;
;--------------------------------------------------------------------------------
; Odds and ends, mad hacks and whatever else...
;
; 1.) Create a "CheatMode" to copy "PACKAGE GEOMETRY/ASSEMBLY_TOP" to 
;     "PACKAGE GEOMETRY/SILKSCREEN_TOP" if it is missing
;
; 2.) Create the reverse of the above
;
;    copy__axlPath
;    copy__axlPathSeg
;    make__axlPath
;    make__axlPathSeg
;--------------------------------------------------------------------------------


;________________________________________________________________________________
;********************************************************************************
;--------------------------------------------------------------------------------
;                           BASE TESTS FOR ALL CLASSES
;--------------------------------------------------------------------------------
; _X_BASE_PART_ORIGIN
;
; I.) DEPENDENCIES
;   A.) None (Access to pin data so basically none)
;
; II.) LOGIC
;   A.) If pin #1 is through hole, then part center at center of pin #1
;       else part center is at the center of the bounding box of all pins.
;
;--------------------------------------------------------------------------------
; _X_ BASE_THROUGH_HOLE
;
; I.) DEPENDENCIES
;   A.) None (Access to pin data so basically none)
;
; II.) LOGIC
;   A.) Check for any through hole pins or vias since this will be the 
;       determining factor in the logic for all "*/*_BOTTOM" subclasses.
;
;--------------------------------------------------------------------------------
; _X_ BASE_TEXTBLOCK_SIZE
;
; I.) DEPENDENCIES
;   A.) General Drawing Extents
;
; II.) LOGIC
;
; 1.) Check TextBlock Sizes have not been changed, reset if necessary.
;
;--------------------------------------------------------------------------------



;________________________________________________________________________________
;********************************************************************************
;--------------------------------------------------------------------------------
;                          CHECKS FOR CLASS: "REF DES"
;--------------------------------------------------------------------------------
; _X_ REF DES
; I.)   GENERAL CHECKS FOR "REF DES" SUBCLASSES
;
; 1.) There should only be six (6) subclasses of the "REF DES" class:
;
;         ASSEMBLY_TOP
;         ASSEMBLY_BOTTOPM
;         DISPLAY_TOP
;         DISPLAY_BOTTOM
;         SILKSCREEN_TOP
;         SILKSCREEN_BOTTOM
;
;     All other user created subclasses should be deleted.
;
;
;--------------------------------------------------------------------------------
; _X_ REF DES/ASSEMBLY_TOP
; II.)  CHECKS FOR SUBCLASS: "REF DES/ASSEMBLY_TOP"
; 
; DEPENDENCIES: 
;     TextBlock Size -> PG/PLACEBOUND_TOP
;
; 1.) Check the number of TEXT objects on this layer. There should be only one.
;     Delete additiona text objects if necessary.
;
; 2.) Check/Change the text in the TEXT Object to a standard: "*"
;
; 3.) Check the TextBlock size used for the TEXT Object
;
; 4.) Check the location of the TEXT Object. It should be at the origin (0, 0).
;
;--------------------------------------------------------------------------------
; _X_ REF DES/ASSEMBLY_BOTTOM
; III.) CHECKS FOR SUBCLASS: "REF DES/ASSEMBLY_BOTTOM"
; 
; DEPENDENCIES: THROUGH_HOLE_PART
;
; 1.) Only if the part contains through hole pins or vias, then there should be a
;     reference designator on "REF DES/ASSEMBLY_BOTTOM"
;
; 2.) Check the number of TEXT objects on this layer. There should be only one.
;     Delete additiona text objects if necessary.
;
; 3.) Check/Change the text in the TEXT Object to a standard: "*"
;
; 4.) Check the TextBlock size used for the TEXT Object
;
; 5.) Check the location of the TEXT Object. It should be at the origin (0, 0).
;
;--------------------------------------------------------------------------------
; _X_ REF DES/DISPLAY_TOP
; IV.)  CHECKS FOR SUBCLASS: "REF DES/DISPLAY_TOP"
; 
; DEPENDENCIES: None
;
; 1.) This layer is not normally used. If anything exists on this subclass, then
;     it should be deleted.
;
;--------------------------------------------------------------------------------
; _X_ REF DES/DISPLAY_BOTTOM
; V.)   CHECKS FOR SUBCLASS: "REF DES/DISPLAY_BOTTOM"
; 
; DEPENDENCIES: None
;
; 1.) This layer is not normally used. If anything exists on this subclass, then
;     it should be deleted.
;
;--------------------------------------------------------------------------------
; _X_ REF DES/SILKSCREEN_TOP
; VI.)  CHECKS FOR SUBCLASS: "REF DES/SILKSCREEN_TOP"
; 
; DEPENDENCIES: PACKAGE GEOMETRY/PLACE_BOUND_TOP
; 
; 1.) Check the number of TEXT objects on this layer. There should be only one.
;     Delete additiona text objects if necessary.
;
; 2.) Check/Change the text in the TEXT Object to a standard: "*"
;
; 3.) Check the TextBlock size used for the TEXT Object
;
; 4.) Check the location of the TEXT Object. It should be outside of the
;     PACKAGE_GEOMETRY/PLACE_BOUND_TOP area.
;
;--------------------------------------------------------------------------------
; _X_ REF DES/SILKSCREEN_BOTTOM
; VII.) CHECKS FOR SUBCLASS: "REF DES/SILKSCREEN_BOTTOM"
;
; DEPENDENCIES: PACKAGE GEOMETRY/PLACE_BOUND_BOTTOM
;
; 1.) Only if the part contains through hole pins or vias, then there should be a
;     reference designator on "REF DES/ASSEMBLY_BOTTOM"
;
; 2.) Check the number of TEXT objects on this layer. There should be only one.
;     Delete additiona text objects if necessary.
;
; 3.) Check/Change the text in the TEXT Object to a standard: "*"
;
; 4.) Check the TextBlock size used for the TEXT Object
;
; 5.) Check the location of the TEXT Object. It should be at the origin (0, 0).
;
;--------------------------------------------------------------------------------


;________________________________________________________________________________
;********************************************************************************
;--------------------------------------------------------------------------------
;                          CHECKS FOR CLASS: "ROUTE KEEPOUT"
;--------------------------------------------------------------------------------
; _X_ ROUTE KEEPOUT
; 1.)   GENERAL CHECKS FOR "ROUTE KEEPOUT" CLASS
;
;  We need some decent logic to figure out when route keepout is necessary
;  between pads.
;
; How close to the edge of the pad should the rout keepout be? Does it matter?
;
; Still thinking...


;________________________________________________________________________________
;********************************************************************************
;--------------------------------------------------------------------------------
;                          CHECKS FOR CLASS: "PACKAGE GEOMETRY"
;--------------------------------------------------------------------------------
; _X_ PACKAGE GEOMETRY
; I.)   GENERAL CHECKS FOR "PACKAGE GEOMETRY" SUBCLASSES
;
; 1.) There should only be 14 standard subclasses and 3 user created subclasses
;       Standard:
;           ASSEMBLY_TOP
;           ASSEMBLY_BOTTOPM
;           BODY_CENTER
;           DISPLAY_TOP
;           DISPLAY_BOTTOM
;           MODULES
;           PAD_STACK_NAME
;           PIN_NUMBER
;           PLACE_BOUND_TOP
;           PLACE_BOUND_BOTTOM
;           SILKSCREEN_TOP
;           SILKSCREEN_BOTTOM
;           SOLDERMASK_TOP
;           SOLDERMASK_BOTTOM
;       
;       User:
;           DIMENSION
;           DATA_INTERNAL
;           DATA_EXTERNAL
;
;     There may be other situations where additional user created subclasses
;     may be necessary (i.e. "GLUE_DOT").
;
;--------------------------------------------------------------------------------
; _X_ PACKAGE GEOMETRY/ASSEMBLY_TOP
; .)CHECKS FOR SUBCLASS: "PACKAGE GEOMETRY/ASSEMBLY_TOP"
;
; 1.) 
;
;--------------------------------------------------------------------------------
; _X_ PACKAGE GEOMETRY/ASSEMBLY_BOTTOM
; .)CHECKS FOR SUBCLASS: "PACKAGE GEOMETRY/ASSEMBLY_BOTTOM"
;
; 1.)
;
;--------------------------------------------------------------------------------
; _X_ PACKAGE GEOMETRY/BODY_CENTER
; .)CHECKS FOR SUBCLASS: "PACKAGE GEOMETRY/BODY_CENTER"
;
; 1.)
;
;--------------------------------------------------------------------------------
; _X_ PACKAGE GEOMETRY/DISPLAY_TOP
; .)CHECKS FOR SUBCLASS: "PACKAGE GEOMETRY/DISPLAY_TOP"
;
; 1.)
;
;--------------------------------------------------------------------------------
; _X_ PACKAGE GEOMETRY/DISPLAY_BOTTOM
; .)CHECKS FOR SUBCLASS: "PACKAGE GEOMETRY/DISPLAY_BOTTOM"
;
; 1.)
;
;--------------------------------------------------------------------------------
; _X_ PACKAGE GEOMETRY/MODULES
; .)CHECKS FOR SUBCLASS: "PACKAGE GEOMETRY/MODULES"
;
; 1.)
;
;--------------------------------------------------------------------------------
; _X_ PACKAGE GEOMETRY/PAD_STACK_NAME
; .)CHECKS FOR SUBCLASS: "PACKAGE GEOMETRY/PAD_STACK_NAME"
;
; 1.)
;
;--------------------------------------------------------------------------------
; _X_ PACKAGE GEOMETRY/PIN_NUMBER
; .)CHECKS FOR SUBCLASS: "PACKAGE GEOMETRY/PIN_NUMBER"
;
; 1.)
;
;--------------------------------------------------------------------------------
; _X_ PACKAGE GEOMETRY/PLACE_BOUND_TOP
; .)CHECKS FOR SUBCLASS: "PACKAGE GEOMETRY/PLACE_BOUND_TOP"
;
; DEPENDENCIES:
;   A.) know the bounding box of all pins (ETCH/PINS)
;   B.) know the bounding box of device (PACKAGE GEOMETRY/ASSEMBLY_TOP)
;
; 1.) Note on BGA's we need +125 mils from edge of part to make sure they can
;     can be reworked if necessary.
;
; 2.) must only contain shapes
;
; 3.) 5 mils over
;
; 4.) Part Height
;
; 5.) Only shapes are allowed on this layer. No text or lines

;--------------------------------------------------------------------------------
; _X_ PACKAGE GEOMETRY/PLACE_BOUND_BOTTOM
; .)CHECKS FOR SUBCLASS: "PACKAGE GEOMETRY/PLACE_BOUND_BOTTOM"
;
; 1.) BGA +125 mils
;
;--------------------------------------------------------------------------------
; _X_ PACKAGE GEOMETRY/SILKSCREEN_TOP
; .)CHECKS FOR SUBCLASS: "PACKAGE GEOMETRY/SILKSCREEN_TOP"
;
; 1.)
;
;--------------------------------------------------------------------------------
; _X_ PACKAGE GEOMETRY/SILKSCREEN_BOTTOM
; .)CHECKS FOR SUBCLASS: "PACKAGE GEOMETRY/SILKSCREEN_BOTTOM"
;
; 1.)
;
;--------------------------------------------------------------------------------
; _X_ PACKAGE GEOMETRY/SOLDERMASK_TOP
; .)CHECKS FOR SUBCLASS: "PACKAGE GEOMETRY/SOLDERMASK_TOP"
;
; 1.)
;
;
;--------------------------------------------------------------------------------
; _X_ PACKAGE GEOMETRY/SOLDERMASK_BOTTOM
; .)CHECKS FOR SUBCLASS: "PACKAGE GEOMETRY/SOLDERMASK_BOTTOM"
;
; 1.)
;
;
;--------------------------------------------------------------------------------

;________________________________________________________________________________
;********************************************************************************
;--------------------------------------------------------------------------------
;   _DTL_PARTS_ChkRD_ASSEMBLY_TOP( OutFH "p")
;
procedure( _DTL_PARTS_ChkRD_ASSEMBLY_TOP( OutFH DatFH "pp")
  prog( ()

    __DEBUG_PRINT__ = nil

  ;--------------------------------------------------------------------------------
  ; Hmmmm... let's try using a "Disembodied Property List" to handle the needed
  ; test strings, retrun value expanliations and whaterver else I dream up.
  ;
  ; Create a named symbol to hold the base code needed in all tests. This symbol
  ; will be a "Test Object" that holds all the needed strings, vlaues and even
  ; the actual code for preforming the test stored in lambda function.
  ;
  ; Note that the scope of variables within the lambda is limited 
  ; lexographically to the procedure/prog block. 
  ;
  ; Yes, this seems like madness since lambda functions are best suited for
  ; code that will be called repeatedly (i.e. they are compiled only once) but
  ; there is some degree of method to the madness. The goal is to be able to
  ; reorder the tests quickly as well as store all of the details of a test
  ; in one place. This should also allow us an easy way to turn tests off and
  ; on as wanted.
  ;
  ;--------------------------------------------------------------------------------
  

  ;********************************************************************************
  ;--------------------------------------------------------------------------------
  ; SECTION_
  ;
  ; This is the basic stuff that all the other tests will need.
  ;
  ;--------------------------------------------------------------------------------
  ; do the basic printing
  fprintf(OutFH "\n#--------------------------------------------------------------------------------\n")
  fprintf(OutFH "TESTING: \"REF DES/ASSEMBLY_TOP\"\n")
  fprintf(DatFH "!TESTS FOR: \"REF DES/ASSEMBLY_TOP\"")
  ; Get all the text from "REF DES/ASSEMBLY_TOP"
  axlClearSelSet()
  vis_list = axlVisibleGet()
  axlVisibleDesign(nil)
  axlVisibleLayer("REF DES/ASSEMBLY_TOP" t)
  axlSetFindFilter(?enabled list("NOALL" "TEXT") ?onButtons list("NOALL" "TEXT"))
  axlAddSelectAll()
  TxtObjList = axlGetSelSet() ; get a list of test objects
  TxtObj = car(TxtObjList)    ; get the first hopefully only text object from list

  ;--------------------------------------------------------------------------------
  ; Create an empty list to hold all the Test Objects. 
  Tests = '()

  ;********************************************************************************
  ;--------------------------------------------------------------------------------
  ; SECTION_00
  ; Check the dependiences needed to test this subclass. This particular 
  ; subclass does not have any dependencies.
  ;
  Test           = concat( "TEST_00" "")
  Test->Number   = 0
  Test->Question = "Test Dependencies?"
  Test->Text     = "The REF DES/ASSEMBLY_TOP subclass requires a reference designator."
  Test->Result   = 0  
  Test->Message  = list( "PASS: No Dependencies" )
  Test->TestFunc = lambda( ()    
    Test->Result = 0                ;"PASS: No Dependencies"
  ) ; END lamda
  ; append the test object to the test list
  Tests = append( Tests list(Test))


  ;********************************************************************************
  ;--------------------------------------------------------------------------------
  ; SECTION_01
  ; Create the first test object which actually does testing. 
  ;
  ; There should be only one text object on "REF DES/ASSEMBLY_TOP" namely the
  ; reference designator itself. Just to be safe, we count the number of 
  ; returned text objects. Usually Allegro prevents users from adding more than
  ; text element but I'm not so sure it can prevent a bad program/script from
  ; doing such a nasty thing to a database.
  ;
  Test           = concat( "TEST_01" "")
  Test->Number   = 1
  Test->Question = "Does Refernce Designator In Exists?"
  Test->Text     = "The REF DES/ASSEMBLY_TOP subclass requires a reference designator."
  Test->Result   = 1  
  Test->Message  = list( "PASS: Reference Designator Exists"
                         "FAIL: Reference Designator Missing"
                         "FAIL: Reference Designator Missing length(TxtObjList) failed"
                         "FAIL: More than one text object on REF DES/ASSEMBLY_TOP")
  Test->TestFunc = lambda( ()    
    if(TxtObjList != nil
    then
      ; count number of text objects
      case( length(TxtObjList)
        ( 1   {Test->Result = 0} )    ; PASS One text object exists in subclass
        ( 0   {Test->Result = 1} )    ; FAIL No text objects in subclass
        ( nil {Test->Result = 2} )    ; FAIL The length(TxtObjList) failed
        ( t   {Test->Result = 3} )    ; FAIL (default) more than one exists.
      ) ; END: case TxtObjCount
    else
      Test->Result = 1                ; FAIL No text objects in subclass
    )
  ) ; END lamda
  ; append the test object to the test list
  Tests = append( Tests list(Test))

  ;--------------------------------------------------------------------------------
  ; SECTION_02
  ; Test location of refernce designator to see if it's at (0,0)
  ;
  Test           = concat( "TEST_02" "")
  Test->Number   = 2
  Test->Question = "Is Refernce Designator at (0,0)?"
  Test->Text     = "The Reference Designator on the REF DES/ASSEMBLY_TOP subclass should be located at (0, 0)."
  Test->Result   = 1  
  Test->Message  = list( "PASS: Reference Designator is at (0,0)"
                         "FAIL: Reference Designator is not at (0,0)"
                         "FAIL: Reference Designator Missing")
  Test->TestFunc = lambda( ()    
    if(TxtObj != nil
    then
      if( { {nth( 0 TxtObj->xy) == 0 } && {nth(1 TxtObj->xy) == 0 } }
      then
        Test->Result   = 0    ; PASS: Reference Designator is at (0,0)
      else
        Test->Result   = 1    ; FAIL: Reference Designator is not at (0,0)
      )
    else
      Test->Result   = 2      ; FAIL: Reference Designator Missing
    )
  ) ; END lamda
  ; append the test object to the test list
  Tests = append( Tests list(Test))

  ;--------------------------------------------------------------------------------
  ; SECTION_03
  ; Test textBlock size of refernce designator to see if it matches global var
  ;
  Test           = concat( "TEST_03" "")
  Test->Number   = 3
  Test->Question = sprintf( nil "Is Refernce Designator Size TextBlock #%d?" GV_BASE_TEXTBLOCK_SIZE)
  Test->Text     = "The Reference Designator on the REF DES/ASSEMBLY_TOP subclass should be \"*\"."
  Test->Result   = 1  
  Test->Message  = list( sprintf(nil "PASS: Reference Designator size is TextBlock #%d" GV_BASE_TEXTBLOCK_SIZE)
                         sprintf(nil "FAIL: Reference Designator size is not TextBlock #%d" GV_BASE_TEXTBLOCK_SIZE)
                                     "FAIL: Reference Designator Missing") ; END list
  Test->TestFunc = lambda( ()    
    if(TxtObj != nil
    then
      if( strcmp(TxtObj->textBlock sprintf(nil "%d" GV_BASE_TEXTBLOCK_SIZE)) == 0
      then
        Test->Result   = 0    ; PASS: RefDes size is TextBlock #%d
      else
        Test->Result   = 1    ; FAIL: RefDes size is not TextBlock #%d (actual #%s)
        TmpTxt = strcat(nth(1 Test->Message) sprintf(nil " (currently #%s)" TxtObj->textBlock))
        rplaca( cdr(Test->Message) TmpTxt)
      )
    else
      Test->Result   = 2      ; FAIL: Reference Designator Missing
    )
  ) ; END lamda
  ; append the test object to the test list
  Tests = append( Tests list(Test))


  ;--------------------------------------------------------------------------------
  ; SECTION_04
  ; Test text of refernce designator to see if it is "*"
  ;
  Test           = concat( "TEST_04" "")
  Test->Number   = 4
  Test->Question = "Is Refernce Designator text \"*\"?"
  Test->Text     = "The Reference Designator on the REF DES/ASSEMBLY_TOP subclass should be \"*\"."
  Test->Result   = 1  
  Test->Message  = list( "PASS: Reference Designator is \"*\""
                         "FAIL: Reference Designator is not \"*\""
                         "FAIL: Reference Designator Missing")
  Test->TestFunc = lambda( ()    
    if(TxtObj != nil
    then
      if( strcmp(TxtObj->text "*") == 0
      then
        Test->Result   = 0    ; PASS: Reference Designator is "*"
      else
        Test->Result   = 1    ; FAIL: Reference Designator is not "*"
      )
    else
      Test->Result   = 2      ; FAIL: Reference Designator Missing
    )
  ) ; END lamda
  ; append the test object to the test list
  Tests = append( Tests list(Test))


  Failure = 0

  ; __FIXME__
  ; This should be set up as a list of tests (integers) passed to the procedure
  ; so we have control of what tests are run. Also "Failures" should be a list
  ; of integers so we know what failed though it's better to write out test
  ; results in a manner that allows viewing like symcheck.
  ;
  ; run the rest of the test functions and print results
  foreach( Test Tests
    funcall(Test->TestFunc)
    fprintf(OutFH "  %02d %-48s%s\n" Test->Number Test->Question nth(Test->Result Test->Message))
    fprintf(DatFH "!%02d %s" Test->Number nth(Test->Result Test->Message))
    Failure = Failure + Test->Result
  )

  if( __DEBUG_PRINT__
  then
    printf("Failure %d\n" Failure)
    fprintf(OutFH "\n\nTxtObjList: ")
    pprint(TxtObjList OutFH)
    fprintf(OutFH "\n\n")
    pprint(TxtObjList->?? OutFH)
    fprintf(OutFH "\n\nTxtObj: ")
    pprint(TxtObj OutFH)
    fprintf(OutFH "\n\n")
    pprint(TxtObj->?? OutFH)
    fprintf(OutFH "\n\n")
  )

  ;--------------------------------------------------------------------------------
  ; Fixing the ref des is fairly simple. No matter what's wrong, delete the old
  ; one if it eixts and create a new one.
  ;
  if(Failure > 0
  then
    axlDeleteObject(TxtObjList)
    
    ; create an TextOrientation structure from the text object
    text_orient = make_axlTextOrientation(
                        ?textBlock sprintf(nil "%d" GV_BASE_TEXTBLOCK_SIZE),   ; text size
                        ?rotation 0,      ; rotation
                        ?mirrored nil, 
                        ?justify "LEFT")
    
    ; write the text into the correct layer (subclass)
    RetVal = axlDBCreateText(t_text = "*",                      ; text to write
                    l_anchorPoint = 0:0,               ; location to write it
                    r_textOrientation = text_orient,   ; orientation struct
                    t_layer = "REF DES/ASSEMBLY_TOP",  ; layer to write on
                    o_attach = nil )                   ; attach to object ?

    ;write status to log
    if( RetVal != nil
    then
      fprintf(OutFH "STATUS: FIXED\n")
      fprintf(DatFH "!STATUS: FIXED")
      IsGood_REF_DES_ASSEMBLY_TOP = t
    else
      fprintf(OutFH "STATUS: FAILED\n")
      fprintf(DatFH "!STATUS: FAILED")
      IsGood_REF_DES_ASSEMBLY_TOP = nil
    )      
  else
    fprintf(OutFH "STATUS: PASSED\n")
    fprintf(DatFH "!STATUS: PASSED")
    IsGood_REF_DES_ASSEMBLY_TOP = t
  )

  IsTest_REF_DES_ASSEMBLY_TOP = t

) ; END:   prog
) ; END: procedure _DTL_PARTS_ChkRD_ASSEMBLY_TOP


;________________________________________________________________________________
;********************************************************************************
;--------------------------------------------------------------------------------
;   _DTL_PARTS_ChkRD_SILKSCREEN_TOP( OutFH "p")
;
procedure( _DTL_PARTS_ChkRD_SILKSCREEN_TOP( OutFH DatFH "pp")
  prog( ()

  __DEBUG_PRINT__ = nil

  ;********************************************************************************
  ;--------------------------------------------------------------------------------
  ; Dependency Checks
  ;

  ; Has dependency been tested, if not test it.
;  if( IsTest_PACKAGE_GEOMETRY_PLACE_BOUND_BOTTOM == nil
;    _DTL_PARTS_Chk_GEOMETRY_PLACE_BOUND_BOTTOM( OutFH )
;  )
  ;IsTest_PACKAGE_GEOMETRY_PLACE_BOUND_BOTTOM       = nil
  ;IsGood_PACKAGE_GEOMETRY_PLACE_BOUND_BOTTOM       = nil



  ;********************************************************************************
  ;--------------------------------------------------------------------------------
  ; SECTION_X
  ;
  ; This is the basic stuff that all the other tests will need.
  ;
  ;--------------------------------------------------------------------------------
  ; do the basic printing
  fprintf(OutFH "\n#--------------------------------------------------------------------------------\n")
  fprintf(OutFH "TESTING: \"REF DES/SILKSCREEN_TOP\"\n")
  fprintf(DatFH "!TESTS FOR: \"REF DES/SILKSCREEN_TOP\"")
  ; Get all the text from "REF DES/SILKSCREEN_TOP"
  axlClearSelSet()
  vis_list = axlVisibleGet()
  axlVisibleDesign(nil)
  axlVisibleLayer("REF DES/SILKSCREEN_TOP" t)
  axlSetFindFilter(?enabled list("NOALL" "TEXT") ?onButtons list("NOALL" "TEXT"))
  axlAddSelectAll()
  TxtObjList = axlGetSelSet() ; get a list of test objects
  TxtObj = car(TxtObjList)    ; get the first hopefully only text object from list



  ;--------------------------------------------------------------------------------
  ; Create an empty list to hold all the Test Objects. 
  Tests = '()

  ;********************************************************************************
  ;--------------------------------------------------------------------------------
  ; SECTION_00
  ; Check the dependiences needed to test this subclass. This particular 
  ; subclass depends on the bounding box of PACKAGE GEOMETRY/PLACE_BOUND_TOP for
  ; positioning of the reference designator.
  ;
  Test           = concat( "TEST_00" "")
  Test->Number   = 0
  Test->Question = "Test Dependencies?"
  Test->Text     = "The REF DES/ASSEMBLY_TOP subclass requires a reference designator."
  Test->Result   = 0  
  Test->Message  = list( "PASS: Dependencies Met" )
  Test->TestFunc = lambda( ()    
    Test->Result = 0                ;"PASS: No Dependencies"
  ) ; END lamda
  ; append the test object to the test list
  Tests = append( Tests list(Test))

  ;********************************************************************************
  ;--------------------------------------------------------------------------------
  ; SECTION_01
  ; Create the first test object which actually does testing. 
  ;
  ; There should be only one text object on "REF DES/SILKSCREEN_TOP" namely the
  ; reference designator itself. Just to be safe, we count the number of 
  ; returned text objects. Usually Allegro prevents users from adding more than
  ; text element but I'm not so sure it can prevent a bad program/script from
  ; doing such a nasty thing to a database.
  ;
  Test           = concat( "TEST_01" "")
  Test->Number   = 1
  Test->Question = "Does Refernce Designator In Exists?"
  Test->Text     = "The REF DES/SILKSCREEN_TOP subclass requires a reference designator."
  Test->Result   = 1  
  Test->Message  = list( "PASS: Reference Designator Exists"
                         "FAIL: Reference Designator Missing"
                         "FAIL: Reference Designator Missing length(TxtObjList) failed"
                         "FAIL: More than one text object on REF DES/SILKSCREEN_TOP"
                         )
  Test->TestFunc = lambda( ()    
    if(TxtObjList != nil
    then
      ; count number of text objects
      case( length(TxtObjList)
        ( 1   {Test->Result = 0} )    ; PASS One text object exists in subclass
        ( 0   {Test->Result = 1} )    ; FAIL No text objects in subclass
        ( nil {Test->Result = 2} )    ; FAIL The length(TxtObjList) failed
        ( t   {Test->Result = 3} )    ; FAIL (default) more than one exists.
      ) ; END: case TxtObjCount
    else
      Test->Result = 1                ; FAIL No text objects in subclass
    )
  ) ; END lamda
  ; append the test object to the test list
  Tests = append( Tests list(Test))


; __FIXME__
; This test is not working right. It always fails.

  ;--------------------------------------------------------------------------------
  ; SECTION_02
  ; Test location of refernce designator to see if it's outside of the
  ; "PACAGE GEOMETRY.PLACE_BOND_TOP" bounding box.
  ;
  Test           = concat( "TEST_02" "")
  Test->Number   = 2
  Test->Question = "Is Ref Des outside of PG/PLACE_BOND_TOP?"
  Test->Text     = "The Reference Designator location should be outside of the area covered by PACAGE GEOMETRY/PLACE_BOND_TOP"
  Test->Result   = 1  
  Test->Message  = list( "PASS: Ref Des is outside of PACAGE GEOMETRY/PLACE_BOND_TOP"
                         "FAIL: Ref Des is not outside of PACAGE GEOMETRY/PLACE_BOND_TOP"
                         "FAIL: Ref Des Missing")
  Test->TestFunc = lambda( ()    
    if(TxtObj != nil
    then

      ; get the bounding box of "PACKAGE GEOMETRY/PLACE_BOUND_TOP"
      SubClassBbox = _DTL_UTILS_GetSubClassBBox("PACKAGE GEOMETRY/PLACE_BOUND_TOP")

      if( __DEBUG_PRINT__
      then
        fprintf( OutFH "\nSubClassBbox: ")
        println( SubClassBbox OutFH)
      )
;__FIXME__
; this is not great since it's using default textblock size rather than actual.
; a more accurate test would be using the actual txtblock size of the existing 
; ref des rather than our default.

      ; get the default text block size of the text
      TxtBlkObj = axlGetParam(sprintf( nil "paramTextBlock:%d" GV_BASE_TEXTBLOCK_SIZE))

      if( __DEBUG_PRINT__
      then
        fprintf( OutFH "\nTxtBlkObj: \n")
        pprint(TxtBlkObj->?? OutFH)
        fprintf( OutFH "\n\n")
      )
      
      ; get the height and width of one char for default textblock size
      TxtBlkCharHeight = TxtBlkObj->lineSpace
      TxtBlkCharWidth = TxtBlkObj->width
 
      ; increase the size of the bounding box by line height and char width
      ; we could get away with just extending the lower left corner but might
      ; as well be safe about it.
      lowLeftLst = car(SubClassBbox)
      upRightLst = car(cdr(SubClassBbox))

      if( __DEBUG_PRINT__
      then
        fprintf( OutFH "\nlowLeftLst: ")
        println( lowLeftLst OutFH)
        fprintf( OutFH "upRightLst: ")
        println( upRightLst OutFH)
      )
      
      ; calculate new extents
      new_ll_x = car(lowLeftLst) - TxtBlkCharWidth
      new_ll_y = car(cdr(lowLeftLst)) - TxtBlkCharHeight
      new_ur_x = car(upRightLst) + TxtBlkCharWidth
      new_ur_y = car(cdr(upRightLst)) + TxtBlkCharHeight

      if( __DEBUG_PRINT__
      then
        fprintf( OutFH "new_ll_x: ")
        println( new_ll_x OutFH)
        fprintf( OutFH "new_ll_y: ")
        println( new_ll_y OutFH)
        fprintf( OutFH "new_ur_x: ")
        println( new_ur_x OutFH)
        fprintf( OutFH "new_ur_y: ")
        println( new_ur_y OutFH)
      )
      
      ; replace bbox values with new extents
      tmp_lst = rplaca(car(SubClassBbox) new_ll_x) 
      tmp_lst = rplacd(car(SubClassBbox) list(new_ll_y) )
      tmp_lst = rplaca(car(cdr(SubClassBbox)) new_ur_x) 
      tmp_lst = rplacd(car(cdr(SubClassBbox)) list(new_ur_y) )

      if( __DEBUG_PRINT__
      then
        fprintf( OutFH "\nExtended SubClassBbox: ")
        println( SubClassBbox OutFH)
        fprintf( OutFH "\nTxtObj->xy: ")
        println( TxtObj->xy OutFH)
        fprintf( OutFH "axlIsPointInsideBox: ")
        pprint(axlIsPointInsideBox(TxtObj->xy SubClassBbox) OutFH)
        fprintf( OutFH "\n\n")
      )
      
      if( !axlIsPointInsideBox(TxtObj->xy SubClassBbox)
      then
        Test->Result   = 0    ; PASS: Ref Des is outside of PACAGE GEOMETRY/PLACE_BOND_TOP
      else
        Test->Result   = 1    ; FAIL: Ref Des is not outside of PACAGE GEOMETRY/PLACE_BOND_TOP
      )
    else
      Test->Result   = 2      ; FAIL: Reference Designator Missing
    )
  ) ; END lamda
  ; append the test object to the test list
  Tests = append( Tests list(Test))

  ;--------------------------------------------------------------------------------
  ; SECTION_03
  ; Test textBlock size of refernce designator to see if it matches global var
  ;
  Test           = concat( "TEST_03" "")
  Test->Number   = 3
  Test->Question = sprintf( nil "Is Refernce Designator Size TextBlock #%d?" GV_BASE_TEXTBLOCK_SIZE)
  Test->Text     = "The Reference Designator on the REF DES/SILKSCREEN_TOP subclass should be \"*\"."
  Test->Result   = 1  
  Test->Message  = list( sprintf(nil "PASS: Reference Designator size is TextBlock #%d" GV_BASE_TEXTBLOCK_SIZE)
                         sprintf(nil "FAIL: Reference Designator size is not TextBlock #%d" GV_BASE_TEXTBLOCK_SIZE)
                                     "FAIL: Reference Designator Missing") ; END list
  Test->TestFunc = lambda( ()    
    if(TxtObj != nil
    then
      if( strcmp(TxtObj->textBlock sprintf(nil "%d" GV_BASE_TEXTBLOCK_SIZE)) == 0
      then
        Test->Result   = 0    ; PASS: RefDes size is TextBlock #%d
      else
        Test->Result   = 1    ; FAIL: RefDes size is not TextBlock #%d (actual #%s)
        TmpTxt = strcat(nth(1 Test->Message) sprintf(nil " (currently #%s)" TxtObj->textBlock))
        rplaca( cdr(Test->Message) TmpTxt)
      )
    else
      Test->Result   = 2      ; FAIL: Reference Designator Missing
    )
  ) ; END lamda
  ; append the test object to the test list
  Tests = append( Tests list(Test))


  ;--------------------------------------------------------------------------------
  ; SECTION_04
  ; Test text of refernce designator to see if it is "*"
  ;
  Test           = concat( "TEST_04" "")
  Test->Number   = 4
  Test->Question = "Is Refernce Designator text \"*\"?"
  Test->Text     = "The Reference Designator on the REF DES/SILKSCREEN_TOP subclass should be \"*\"."
  Test->Result   = 1  
  Test->Message  = list( "PASS: Reference Designator is \"*\""
                         "FAIL: Reference Designator is not \"*\""
                         "FAIL: Reference Designator Missing")
  Test->TestFunc = lambda( ()    
    if(TxtObj != nil
    then
      if( strcmp(TxtObj->text "*") == 0
      then
        Test->Result   = 0    ; PASS: Reference Designator is "*"
      else
        Test->Result   = 1    ; FAIL: Reference Designator is not "*"
      )
    else
      Test->Result   = 2      ; FAIL: Reference Designator Missing
    )
  ) ; END lamda
  ; append the test object to the test list
  Tests = append( Tests list(Test))


  Failure = 0

  ; __FIXME__
  ; This should be set up as a list of tests (integers) passed to the procedure
  ; so we have control of what tests are run. Also "Failures" should be a list
  ; of integers so we know what failed though it's better to write out test
  ; results in a manner that allows viewing like symcheck.
  ;
  ; run the rest of the test functions and print results
  foreach( Test Tests
    funcall(Test->TestFunc)
    fprintf(OutFH "  %02d %-48s%s\n" Test->Number Test->Question nth(Test->Result Test->Message))
    fprintf(DatFH "!%02d %s" Test->Number nth(Test->Result Test->Message))
    Failure = Failure + Test->Result
  )

  if( __DEBUG_PRINT__
  then
    printf("Failure %d\n" Failure)
    fprintf(OutFH "\n\nTxtObjList: ")
    pprint(TxtObjList OutFH)
    fprintf(OutFH "\n\n")
    pprint(TxtObjList->?? OutFH)
    fprintf(OutFH "\n\nTxtObj: ")
    pprint(TxtObj OutFH)
    fprintf(OutFH "\n\n")
    pprint(TxtObj->?? OutFH)
    fprintf(OutFH "\n\n")
  )


  ;--------------------------------------------------------------------------------
  ; Fixing the ref des is fairly simple. No matter what's wrong, delete the old
  ; one if it eixts and create a new one.
  ;
  if(Failure > 0
  then
    axlDeleteObject(TxtObjList)
    
    ; create an TextOrientation structure from the text object
    text_orient = make_axlTextOrientation(
                        ?textBlock sprintf(nil "%d" GV_BASE_TEXTBLOCK_SIZE),   ; text size
                        ?rotation 0,      ; rotation
                        ?mirrored nil, 
                        ?justify "LEFT")
    
; __FIXME__ Not safe for metirc

    ; Make sure we are out of the bounding box
    new_ll_x = new_ll_x -1
    new_ur_y = new_ur_y +1
    
    ; write the text into the correct layer (subclass)
    RetVal = axlDBCreateText(t_text = "*",                      ; text to write
                    l_anchorPoint = list(new_ll_x new_ur_y),               ; location to write it
                    r_textOrientation = text_orient,   ; orientation struct
                    t_layer = "REF DES/SILKSCREEN_TOP",  ; layer to write on
                    o_attach = nil )                   ; attach to object ?

    ;write status to log
    if( RetVal != nil
    then
      fprintf(OutFH "STATUS: FIXED\n")
      fprintf(DatFH "!STATUS: FIXED")
      IsGood_REF_DES_ASSEMBLY_TOP = t
    else
      fprintf(OutFH "STATUS: FAILED\n")
      fprintf(DatFH "!STATUS: FAILED")
      IsGood_REF_DES_ASSEMBLY_TOP = nil
    )      
  else
    fprintf(OutFH "STATUS: PASSED\n")
    fprintf(DatFH "!STATUS: PASSED")
    IsGood_REF_DES_ASSEMBLY_TOP = t
  )

) ; END:   prog
) ; END: procedure _DTL_PARTS_ChkRD_SILKSCREEN_TOP

;________________________________________________________________________________
;********************************************************************************
;--------------------------------------------------------------------------------
;
procedure( _DTL_PARTS_PartCheck()
  prog( (OutFH DatFH)
      
  ; We will need a file to keep our check reults
  if( isFile("DT_Part_Check_Notes.txt")
  then
    OutFH = outfile( "DT_Part_Check_Notes.txt" "a")
  else
    OutFH = outfile( "DT_Part_Check_Notes.txt" "w")
  )

  ; We will need a file to keep our check reults
  if( isFile("DT_Part_Check_Datum.txt")
  then
    DatFH = outfile( "DT_Part_Check_Datum.txt" "a")
  else
    DatFH = outfile( "DT_Part_Check_Datum.txt" "w")
  )


  fprintf(OutFH "\n\n#_______________________________________________________________________________\n")
  fprintf(OutFH "#*******************************************************************************\n")
  fprintf(OutFH "#--------------------------------------------------------------------------------\n")
  
  
  fprintf(OutFH "# %s\n" axlGetDrawingName())
  fprintf(OutFH "# CURRENT_DIR:\t\t%s\n" getWorkingDir())
  fprintf(OutFH "# FILE_NAME:\t\t%s\n" axlGetVariable("module"))

  
;  fprintf(DatFH "\n%s!" axlGetVariable("module"))
  fprintf(DatFH "\n%s" axlCurrentDesign())

  ; No Dependencies
  _DTL_PARTS_ChkRD_ASSEMBLY_TOP(OutFH DatFH)

  ; Depends on PACKAGE_GEOMETRY/PLACEBOUND_TOP
  _DTL_PARTS_ChkRD_SILKSCREEN_TOP(OutFH DatFH)

  ; close files
  close(OutFH)
  close(DatFH)
  
  ; turn on visibility on all layers
  axlVisibleDesign(t)       ; set all layers visible
  axlVisibleUpdate(t)       ; update visible objects
  axlUIWUpdate(nil)         ; do UI main window update
  axlUIWRedraw(nil)         ; force refresh of main window

) ; END:   prog( ()
) ; END: procedure( _DTL_PARTS_PartCheck()


;________________________________________________________________________________


;________________________________________________________________________________
;********************************************************************************
;--------------------------------------------------------------------------------
;
procedure( _DTL_PARTS_DeleteJunkSubclass()
  prog( ()
    
    println("START: _DTL_PARTS_DeleteJunkSubclass()")

  ; Do UI confirmation 
  if( GV_SHOW_PROMPTS == t
  then
    TmpTxt = strcat("You are about to delete all UNUSED subclasses.\n\n")
    TmpTxt = strcat(TmpTxt "Are you sure you want to do this?\n")
    RetVal = axlUIYesNo(TmpTxt)

    ; be annoying
    if( GV_SHOW_PROMPTS_ANNOY == t
    then
      TmpTxt = strcat("You may be sure but\n")
      TmpTxt = strcat(TmpTxt "are you completely certain?\n")
      axlUIYesNo(TmpTxt)
      
      TmpTxt = strcat("Though you may be sure and completely certain,\n")
      TmpTxt = strcat(TmpTxt "are you completely sure?\n")
      axlUIYesNo(TmpTxt)

      NotABastard = t
      while( NotABastard == t
        TmpTxt = strcat("Have you called me a bastard yet?,\n")
        NotABastard = !axlUIYesNo(TmpTxt)
      )
    )

    if( RetVal != t
    then
      printf("\nUSER CANCEL\n")
      return(nil)
    ) ; END: if( RetVal == t

  ) ; END: if( GV_SHOW_PROMPTS == t

;  return(nil)
  
;  ClassName = "PACKAGE GEOMETRY" = 14 Normal SubClasses


  ; open file handle for new script
  OutFH = outfile( "_toaster.scr" )

  fprintf(OutFH "#------------------------------------\n")
  fprintf(OutFH "# Toaster Script File\n\n")
  fprintf(OutFH "version 14.2\n\n")
  fprintf(OutFH "trapsize 1012 \n")
  fprintf(OutFH "define subclass \n")

  ; compile our regex, a space
  rexMagic(t)
  rexCompile("[ ]")


  ClassNames = list("BOARD GEOMETRY" 
                    "COMPONENT VALUE"
                    "DEVICE TYPE"
                    "DRAWING FORMAT"
                    "MANUFACTURING"
                    "ANALYSIS"
                    "PACKAGE GEOMETRY"
                    "REF DES"
                    "TOLERANCE"
                    "USER PART NUMBER"
                    )

  foreach( ClassName ClassNames
    ClassObj = axlGetParam(strcat("paramLayerGroup:" ClassName))
    
    ; change the format from "PACKAGE GEOMETRY" to "package_geometry"
    ClassName = lowerCase(ClassName)
    ClassName = rexReplace(ClassName "_" 0)
    
    ; set the form to the correct non-etch class
    fprintf(OutFH "setwindow form.subclass\n")
    fprintf(OutFH "FORM subclass %s pick \n" ClassName)
    
    ; change the format from "SUPER HOSER" to "super_hoser"
    SubClassNames = ClassObj->groupMembers
    foreach( SubClassName SubClassNames
    
      SubClassName = lowerCase(SubClassName)
      SubClassName = rexReplace(SubClassName "_" 0)  
    
      fprintf(OutFH "setwindow form.subclass_nonetch \n")
      fprintf(OutFH "FORM subclass_nonetch %s delete Delete \n" SubClassName)
    ) ; END: foreach( SubClassName SubClassNames
  ) ; END: foreach( ClassName ClassNames
  

  ; Deal with unused etch layers
  fprintf(OutFH "setwindow form.subclass\n")
  fprintf(OutFH "FORM subclass etch pick \n")
  fprintf(OutFH "setwindow form.xsection\n")

  ClassObj = axlGetParam("paramLayerGroup:ETCH")

  SubClassNames = ClassObj->groupMembers

  printf("\n\nSubClassNames: ")
  pprint(SubClassNames)
  printf("\n\n")

  ; The first unnamed external dilectric layer (AIR) is "unnamed1"
  ; The second unnamed internal dilectric layer (FR-4) is "unnamed2" and comes
  ; after the "TOP" layer. We need one internal dilectric layer to prevent
  ; errors so we do not delete this one.
  ; The third  unnamed internal dilectric layer (FR-4) is "unnamed4" since it
  ; is the fourth layer in the stack 
  ;   1.) unnamed1 
  ;   2.) TOP 
  ;   3.) unnamed2 
  ;   4.) UNNEEDED_LAYER_NAME
  ;   5.) unnamed4 
  
  Name_Top = axlConductorTopLayer()
  Name_Bottom = axlConductorBottomLayer()
  foreach( SubClassName SubClassNames
    if( { { alphaNumCmp(SubClassName Name_Top) != 0 } && 
          { alphaNumCmp(SubClassName Name_Bottom) != 0 } }
    then
      printf("\nTOPName: %s\n" axlConductorTopLayer())
      printf("BOTTOMName: %s\n" axlConductorBottomLayer())
      printf("SubClassName: %s\n" SubClassName)
      pprint(SubClassName)
      
      SubClassName = lowerCase(SubClassName)
      SubClassName = rexReplace(SubClassName "_" 0)  

      fprintf(OutFH "FORM xsection %s edit Delete\n" SubClassName)

    ) ; END: if( { {SubClassName != "TOP"} || {SubClassName != "BOTTOM"} }
  ) ; END: foreach( SubClassName SubClassNames

  ; Delete all "unnamed*" layers.
  ; Manditory "AIR" layers above TOP and below BOTTOM are not affected.
  LayerCount = {2 * {ClassObj->nChildren}} -1
  for( i 3 LayerCount
      UnnamedStr = sprintf( nil "unnamed%d" i)
      fprintf(OutFH "FORM xsection %s edit Delete\n" UnnamedStr)
  
  )

  ; Add one default (FR-4) dialetric layer between TOP and BOTTOM
  fprintf(OutFH "FORM xsection bottom edit Insert\n")
  fprintf(OutFH "FORM xsection done \n")

  fprintf(OutFH "setwindow form.subclass\n")
  fprintf(OutFH "FORM subclass done\n")
  fprintf(OutFH "setwindow pcb \n")
  fprintf(OutFH "save \n")

; __FIXME__
; We need a test for if confirmations is on.
;  fprintf(OutFH "fillin yes\n")

  fprintf(OutFH "exit\n")

  ; close the file
  close(OutFH)
  ; make sure it's OK to proceed
  axlOKToProceed()
  
  
  CurrentDir = getWorkingDir()
  FileName = axlGetVariable("module")

  ; also see axlShell("shadow 0")
;  FullCmd = "allegro -expert -j _toaster.jrl -S _toaster.scr -p "
  FullCmd = "allegro -expert -nographic -j _toaster.jrl -S _toaster.scr -p "
  FullCmd = strcat( FullCmd CurrentDir " " FileName)
  
  axlRunBatchDBProgram( "allegro" FullCmd
                             ?startMsg "SubClass Toaster"
                             ?logfile "_toaster"
                             ?reloadDB t)

  ; reopen file with noconfirm (i.e. don't save)
  axlOpenDesign( ?design FileName ?mode "wf" )

  println("END: _DTL_PARTS_DeleteJunkSubclass()")
    
) ; END:   prog( () 
) ; END: procedure( _DTL_PARTS_DeleteSubclass(ClassName SubClassName)




;________________________________________________________________________________
;********************************************************************************
;--------------------------------------------------------------------------------
;
procedure( _DTL_PARTS_SetCheckColors()
  prog( ()

  ; print start message
  printf("\nSTART: _DTL_PARTS_SetCheckColors()\n")


  ; turn on visibility on all layers
  axlVisibleDesign(t)       ; set all layers visible
  axlVisibleUpdate(t)       ; update visible objects
  axlUIWUpdate(nil)         ; do UI main window update
  axlUIWRedraw(nil)         ; force refresh of main window

  ; NOTE: color numbers are represented in the color dialog in the lower palette
  ; SLC = List of Sublayer Color pair lists
  SLC = '()

  ;********************************************************************************
  ; LAYER: "PACKAGE GEOMETRY"
  ;--------------------------------------------------------------------------------
  SLC = append(SLC list(list(GV_PACKAGE_GEOMETRY_DIMENSION 2)))
  SLC = append(SLC list(list(GV_PACKAGE_GEOMETRY_INFO_INTERNAL 20)))
  SLC = append(SLC list(list(GV_PACKAGE_GEOMETRY_INFO_EXTERNAL 18)))
  SLC = append(SLC list(list("PACKAGE GEOMETRY/BODY_CENTER" 1)))
  SLC = append(SLC list(list("PACKAGE GEOMETRY/PIN_NUMBER" 9)))       ; Dk Blue
  ;--------------------------------------------------------------------------------
  SLC = append(SLC list(list("PACKAGE GEOMETRY/ASSEMBLY_TOP" 16)))    ; Lt blue
  SLC = append(SLC list(list("PACKAGE GEOMETRY/ASSEMBLY_BOTTOM" 6)))    ; pale blue
  ;--------------------------------------------------------------------------------
  SLC = append(SLC list(list("PACKAGE GEOMETRY/DISPLAY_TOP" 19)))      ; Lt Grey
  SLC = append(SLC list(list("PACKAGE GEOMETRY/DISPLAY_BOTTOM" 11)))      ; Grey
  ;--------------------------------------------------------------------------------
  SLC = append(SLC list(list("PACKAGE GEOMETRY/PLACE_BOUND_TOP" 21)))    ; Lt Green
  SLC = append(SLC list(list("PACKAGE GEOMETRY/PLACE_BOUND_BOTTOM" 12)))    ; pale blue
  ;--------------------------------------------------------------------------------
  SLC = append(SLC list(list("PACKAGE GEOMETRY/SILKSCREEN_TOP" 8)))     ; Lt Yellow
  SLC = append(SLC list(list("PACKAGE GEOMETRY/SILKSCREEN_BOTTOM" 13)))     ; Dk Yellow
  ;--------------------------------------------------------------------------------
  SLC = append(SLC list(list("PACKAGE GEOMETRY/SOLDERMASK_TOP" 7)))     ; salmon
  SLC = append(SLC list(list("PACKAGE GEOMETRY/SOLDERMASK_BOTTOM" 22)))     ; Dk Red
  ;********************************************************************************
  ; LAYER: "ETCH"
  ;--------------------------------------------------------------------------------
  SLC = append(SLC list(list("ETCH/TOP" 23)))      ; Lt Purple
  SLC = append(SLC list(list("ETCH/BOTTOM" 17)))     ; Purple

  ;********************************************************************************
  ; LAYER: "PIN"
  ;--------------------------------------------------------------------------------
  SLC = append(SLC list(list("PIN/TOP" 23)))      ; Lt Purple
  SLC = append(SLC list(list("PIN/BOTTOM" 17)))     ; Purple
  ;--------------------------------------------------------------------------------
  SLC = append(SLC list(list("PIN/SOLDERMASK_TOP" 7)))      ; Red
  SLC = append(SLC list(list("PIN/SOLDERMASK_BOTTOM" 22)))     ; Dk Red
  ;--------------------------------------------------------------------------------
  SLC = append(SLC list(list("PIN/PASTEMASK_TOP" 13)))      ; Gold
  SLC = append(SLC list(list("PIN/PASTEMASK_BOTTOM" 18)))     ; DK Gold
  ;--------------------------------------------------------------------------------
  SLC = append(SLC list(list("PIN/FILMMASKTOP" 23)))      ; Lt Purple
  SLC = append(SLC list(list("PIN/FILMMASKBOTTOM" 17)))     ; Purple
  ;********************************************************************************
  ; LAYER: "VIA CLASS"
  ;--------------------------------------------------------------------------------
  SLC = append(SLC list(list("VIA CLASS/TOP" 23)))      ; Lt Purple
  SLC = append(SLC list(list("VIA CLASS/BOTTOM" 17)))     ; Purple
  ;--------------------------------------------------------------------------------
  SLC = append(SLC list(list("VIA CLASS/SOLDERMASK_TOP" 7)))      ; Red
  SLC = append(SLC list(list("VIA CLASS/SOLDERMASK_BOTTOM" 22)))     ; Dk Red
  ;--------------------------------------------------------------------------------
  SLC = append(SLC list(list("VIA CLASS/PASTEMASK_TOP" 13)))      ; Gold
  SLC = append(SLC list(list("VIA CLASS/PASTEMASK_BOTTOM" 18)))     ; DK Gold
  ;--------------------------------------------------------------------------------
  SLC = append(SLC list(list("VIA CLASS/FILMMASKTOP" 23)))      ; Lt Purple
  SLC = append(SLC list(list("VIA CLASS/FILMMASKBOTTOM" 17)))     ; Purple
  ;********************************************************************************
  ;--------------------------------------------------------------------------------
  SLC = append(SLC list(list("DRC ERROR CLASS/TOP" 7)))      ; Lt Purple
  SLC = append(SLC list(list("DRC ERROR CLASS/BOTTOM" 7)))     ; Purple
  ;********************************************************************************
  ; LAYER: "ANTI ETCH"
  ;--------------------------------------------------------------------------------
  SLC = append(SLC list(list("ANTI ETCH/TOP" 23)))      ; Lt Purple
  SLC = append(SLC list(list("ANTI ETCH/BOTTOM" 17)))     ; Purple
  ;********************************************************************************
  ; LAYER: "COMPONENT VALUE"
  ;--------------------------------------------------------------------------------
  SLC = append(SLC list(list("COMPONENT VALUE/ASSEMBLY_TOP" 16)))    ; Lt blue
  SLC = append(SLC list(list("COMPONENT VALUE/ASSEMBLY_BOTTOM" 6)))    ; pale blue
  ;--------------------------------------------------------------------------------
  SLC = append(SLC list(list("COMPONENT VALUE/SILKSCREEN_TOP" 8)))     ; Lt Yellow
  SLC = append(SLC list(list("COMPONENT VALUE/SILKSCREEN_BOTTOM" 13)))     ; Dk Yellow
  ;--------------------------------------------------------------------------------
  SLC = append(SLC list(list("COMPONENT VALUE/DISPLAY_TOP" 19)))      ; Lt Grey
  SLC = append(SLC list(list("COMPONENT VALUE/DISPLAY_BOTTOM" 11)))      ; Grey
  ;********************************************************************************
  ; LAYER: "DEVICE TYPE"
  ;--------------------------------------------------------------------------------
  SLC = append(SLC list(list("DEVICE TYPE/ASSEMBLY_TOP" 16)))    ; Lt blue
  SLC = append(SLC list(list("DEVICE TYPE/ASSEMBLY_BOTTOM" 6)))    ; pale blue
  ;--------------------------------------------------------------------------------
  SLC = append(SLC list(list("DEVICE TYPE/SILKSCREEN_TOP" 8)))     ; Lt Yellow
  SLC = append(SLC list(list("DEVICE TYPE/SILKSCREEN_BOTTOM" 13)))     ; Dk Yellow
  ;--------------------------------------------------------------------------------
  SLC = append(SLC list(list("DEVICE TYPE/DISPLAY_TOP" 19)))      ; Lt Grey
  SLC = append(SLC list(list("DEVICE TYPE/DISPLAY_BOTTOM" 11)))      ; Grey
  ;********************************************************************************
  ; LAYER: "REF DES"
  ;--------------------------------------------------------------------------------
  SLC = append(SLC list(list("REF DES/ASSEMBLY_TOP" 16)))    ; Lt blue
  SLC = append(SLC list(list("REF DES/ASSEMBLY_BOTTOM" 6)))    ; pale blue
  ;--------------------------------------------------------------------------------
  SLC = append(SLC list(list("REF DES/SILKSCREEN_TOP" 8)))     ; Lt Yellow
  SLC = append(SLC list(list("REF DES/SILKSCREEN_BOTTOM" 13)))     ; Dk Yellow
  ;--------------------------------------------------------------------------------
  SLC = append(SLC list(list("REF DES/DISPLAY_TOP" 19)))      ; Lt Grey
  SLC = append(SLC list(list("REF DES/DISPLAY_BOTTOM" 11)))      ; Grey
  ;********************************************************************************
  ; LAYER: "TOLERANCE"
  ;--------------------------------------------------------------------------------
  SLC = append(SLC list(list("TOLERANCE/ASSEMBLY_TOP" 16)))    ; Lt blue
  SLC = append(SLC list(list("TOLERANCE/ASSEMBLY_BOTTOM" 6)))    ; pale blue
  ;--------------------------------------------------------------------------------
  SLC = append(SLC list(list("TOLERANCE/SILKSCREEN_TOP" 8)))     ; Lt Yellow
  SLC = append(SLC list(list("TOLERANCE/SILKSCREEN_BOTTOM" 13)))     ; Dk Yellow
  ;--------------------------------------------------------------------------------
  SLC = append(SLC list(list("TOLERANCE/DISPLAY_TOP" 19)))      ; Lt Grey
  SLC = append(SLC list(list("TOLERANCE/DISPLAY_BOTTOM" 11)))      ; Grey
  ;********************************************************************************
  ; LAYER: "USER PART NUMBER"
  ;--------------------------------------------------------------------------------
  SLC = append(SLC list(list("USER PART NUMBER/ASSEMBLY_TOP" 16)))    ; Lt blue
  SLC = append(SLC list(list("USER PART NUMBER/ASSEMBLY_BOTTOM" 6)))    ; pale blue
  ;--------------------------------------------------------------------------------
  SLC = append(SLC list(list("USER PART NUMBER/SILKSCREEN_TOP" 8)))     ; Lt Yellow
  SLC = append(SLC list(list("USER PART NUMBER/SILKSCREEN_BOTTOM" 13)))     ; Dk Yellow
  ;--------------------------------------------------------------------------------
  SLC = append(SLC list(list("USER PART NUMBER/DISPLAY_TOP" 19)))      ; Lt Grey
  SLC = append(SLC list(list("USER PART NUMBER/DISPLAY_BOTTOM" 11)))      ; Grey
  ;********************************************************************************
  ; LAYER: "ROUTE KEEPOUT"
  ;--------------------------------------------------------------------------------
  SLC = append(SLC list(list("ROUTE KEEPOUT/TOP" 1)))      ; Lt Grey
  SLC = append(SLC list(list("ROUTE KEEPOUT/BOTTOM" 1)))      ; Grey
  SLC = append(SLC list(list("ROUTE KEEPOUT/ALL" 1)))      ; Grey
  ;********************************************************************************
  ; LAYER: "ROUTE KEEPIN"
  ;--------------------------------------------------------------------------------
  SLC = append(SLC list(list("ROUTE KEEPIN/ALL" 3)))      ; Grey
  ;********************************************************************************
  ; LAYER: "VIA KEEPOUT"
  ;--------------------------------------------------------------------------------
  SLC = append(SLC list(list("VIA KEEPOUT/TOP" 1)))      ; Lt Grey
  SLC = append(SLC list(list("VIA KEEPOUT/BOTTOM" 1)))      ; Grey
  SLC = append(SLC list(list("VIA KEEPOUT/ALL" 1)))      ; Grey
  ;********************************************************************************
  ; LAYER: "VIA KEEPIN"
  ;--------------------------------------------------------------------------------
  SLC = append(SLC list(list("VIA KEEPIN/ALL" 3)))      ; Grey
  ;********************************************************************************
  ; LAYER: "PACKAGE KEEPOUT"
  ;--------------------------------------------------------------------------------
  SLC = append(SLC list(list("PACKAGE KEEPOUT/TOP" 1)))      ; Lt Grey
  SLC = append(SLC list(list("PACKAGE KEEPOUT/BOTTOM" 1)))      ; Grey
  SLC = append(SLC list(list("PACKAGE KEEPOUT/ALL" 1)))      ; Grey
  ;********************************************************************************
  ; LAYER: "PACKAGE KEEPIN"
  ;--------------------------------------------------------------------------------
  SLC = append(SLC list(list("PACKAGE KEEPIN/ALL" 3)))      ; Grey



  ;--------------------------------------------------------------------------------
  ; Change color of all BOARD GEOMETRY/ sublayers to default pink
  ;--------------------------------------------------------------------------------
  layer = axlGetParam("paramLayerGroup:BOARD GEOMETRY")
  foreach( subLayerName layer->groupMembers
    subLayerName = sprintf( nil "paramLayerGroup:BOARD GEOMETRY/paramLayer:%s" subLayerName)
    sublayer = axlGetParam(subLayerName)
    sublayer->color = 3
    axlSetParam(sublayer)
  ) ; END: foreach(sublayer layer->groupMemebers


  ;--------------------------------------------------------------------------------
  ; If necessary, add needed part/sybol subclasses/sublayers
  ;--------------------------------------------------------------------------------
  if( { {axlIsLayer(GV_PACKAGE_GEOMETRY_DIMENSION) == nil} ||
        {axlIsLayer(GV_PACKAGE_GEOMETRY_INFO_INTERNAL) == nil} ||
        {axlIsLayer(GV_PACKAGE_GEOMETRY_INFO_EXTERNAL) == nil} }
  then
    _DTL_PARTS_InfoSubclassCreate()
  )

  ;--------------------------------------------------------------------------------
  ; run through every sublayer/colorVal pair and change the color
  ;--------------------------------------------------------------------------------
  rexMagic(t)
  rexCompile("[/]")
  foreach( SLColor SLC
    LayerName = car(SLColor)
    LayerName = strcat("paramLayerGroup:" LayerName)
    LayerName = rexReplace( LayerName "/paramLayer:" 0)
    TmpSublayer = axlGetParam(LayerName)
    if( TmpSublayer != nil
    then
      TmpSublayer->color = car(cdr(SLColor))
      axlSetParam(TmpSublayer)
    )
  )

  ; force redraw of screen
  axlUIWRedraw(nil)

  ; print end message
  printf("\nEND: _DTL_PARTS_SetCheckColors()\n")


) ; END:   prog( ()
) ; END: procedure( _DTL_PARTS_SetCheckColors()


;________________________________________________________________________________
;********************************************************************************
;--------------------------------------------------------------------------------
;
procedure( _DTL_PARTS_ZMoveDim2PGDim()
  prog( ()

  ; print start message
  printf("\nSTART: _DTL_ZMoveDimensions()\n")
  __DEBUG_PRINT__ = nil
  if( axlIsLayer(GV_PACKAGE_GEOMETRY_DIMENSION) == nil
  then
    _DTL_PARTS_InfoSubclassCreate()
  )

  ; Print info message
  printf("\n\nSelect a small portion that contains just dimesion info\n")

  ; UI Instructions
  if( GV_SHOW_INSTRUCTIONS == t
  then
    TmpTxt = strcat("Please select a small area only containing\n")
    TmpTxt = strcat(TmpTxt "existing dimensions info (lines/text).\n")
    axlUIConfirm(TmpTxt)
  )

  axlClearSelSet()
  ; UI graphical selection code
  ; set the needed "popup" for right click menu
  mypopup = axlUIPopupDefine( nil 
    list(list("Done" `axlFinishEnterFun) list("Cancel" `axlCancelEnterFun)))
  axlUIPopupSet( mypopup )
  ; set the filter for only the stuff normally found in dimension data 
  axlSetFindFilter(
        ?enabled list("NOALL" "TEXT" "CLINES" "CLINESEGS" "LINES" "LINESEGS") 
        ?onButtons list("NOALL" "TEXT" "CLINES" "CLINESEGS" "LINES" "LINESEGS"))
  axlOpenFindFilter()
  ; UI selection loop
  while( axlSelect()
    ; save the selected object id's
    BadDimSet = axlGetSelSet()
  )
  axlClearSelSet()
  axlCloseFindFilter()


  ; make sure BadDimSet has been bound/allocated in the environment since
  ; hitting "Cancel" on the right-click popup leaves the variable undefined.
  if( boundp('BadDimSet)
  then
    ; grab the first dbid object from the list returned from user select
    BadDimObj = car(BadDimSet)
    ; grab the string from the "layer" elelment of the object
    BadDimSubclass = BadDimObj->layer
  else
    BadDimSubclass = nil
  )
  
  ; well the user mouse select didn't work, let's have the user choose the layer
  ; this may not be a good idea but what the heck.
  if( BadDimSubclass == nil
  then
    axlUIWBeep()
    TmpTxt = strcat("Could not determine subclass from selection.\n")
    TmpTxt = strcat(TmpTxt "Please choose class/subclass with dimensions.\n")
    axlUIConfirm(TmpTxt)
    ; UI let the user choose the layer containing dimension data   

; FIXME The US stuff is broken in 14.2
;    BadDimSubclass = _DTL_UIGUI_ChooseSubclass()
    
    ; Nope we're still hosed, throw message and return error (nil)
    if( BadDimSubclass == nil
    then
      axlUIConfirm("Could not determine subclass selection")
      return(nil)
    )
  )


  ; Gather/Select all the dimension stuff on the BadDimSubclass
  axlClearSelSet()
  vis_list = axlVisibleGet()
  axlVisibleDesign(nil)
  axlVisibleLayer(BadDimSubclass t)
  axlSetFindFilter(
      ?enabled list("NOALL" "TEXT" "CLINES" "CLINESEGS" "LINES" "LINESEGS") 
      ?onButtons list("NOALL" "TEXT" "CLINES" "CLINESEGS" "LINES" "LINESEGS"))
  axlAddSelectAll()
  bad_dims = axlGetSelSet()

  ; cycle through each hunk of junk in the BadDimSubclass layer of the
  ; part. The Bad Dimensions Sublayer is usually the "BOARD GEOMETRY/DIMENSION"
  foreach( bad_dim bad_dims

    ; test if we're dealing with a path (line/cline/segs)
    ; _FIXME_ -need error checks for sermgt type of "line" etc.
    if( bad_dim->objType == "path"
    then
      seg_count = length(bad_dim->segments)
      seg_count--
      for( i 0 seg_count
        segment = nth( i bad_dim->segments)
        if( i == 0
        then
          ;get the first coordinate in list (of xy lists)
          ; i.e. startEnd ((193.5 -117.1) (201.5 -117.1)
          ; returns (193.5 -117.1)
          coord_pair = nth( 0 segment->startEnd)
          coord_y = nth( 1 coord_pair)
          coord_x = nth( 0 coord_pair)

          ; create an r_path structure named "path"
          path = axlPathStart( list(coord_x:coord_y))

;          ; __DEBUG__  printing
;          printf("FIRST coord_pair: ")
;          pprint(coord_pair)
;          printf("\n")
;          printf("coord_x: ")
;          println(coord_x)
;          printf("coord_y: ")
;          println(coord_y)
;          coord_list =  list(coord_x:coord_y )
;          printf("coord_list: ")
;          pprint(coord_list)
        ) ; END: if( i == 0

        ;get the second coordinate in list (of xy lists)
        ; if startEnd ((193.5 -117.1) (201.5 -117.1))
        ; it  returns (201.5 -117.1)
        coord_pair = nth( 1 segment->startEnd)
        coord_y = nth( 1 coord_pair)
        coord_x = nth( 0 coord_pair)

        ; add coordinate to the r_path structure
        axlPathLine( path, nil, coord_x:coord_y)

;        ; __DEBUG__ printing
;        printf("\ncoord_pair: ")
;        pprint(coord_pair)
;        printf("\n")
;        printf("coord_x: ")
;        println(coord_x)
;        printf("coord_y: ")
;        println(coord_y)
;        coord_list =  append( coord_list list(coord_x:coord_y ))
;        printf("coord_list: ")
;        pprint(coord_list)
      ) ; END: for( i 0 seg_count

      ; And finally write the collected path data to the new layer
      axlDBCreatePath( path "PACKAGE GEOMETRY/DIMENSION")

    ) ; END: if( bad_dim->objType == "path"
    
    ; let's deal with the text data that's in the wrong layer
    if( bad_dim->objType == "text"
    then
      text_data = bad_dim->text


      ; only replicate strings that are dimension numbers like "0.42" or ".42"
;      rexMagic(t)
;      rexCompile("^[0-9]*[/.][0-9]*")
;      if( { rexMatchp("^[0-9]*[/.][0-9]*" text_data) && !rexMatchp("[a-z]" text_data) }

      ; works fairly well
      rexCompile("^[0-9]*[/.][0-9]*")
      if( { rexMatchp("^[0-9]*[/.][0-9]*" text_data) }

;      rexMagic(t)
;      rexCompile("[^a-z]")
;      if( { !rexMatchp("[^a-z]" text_data) }

      then
      ; create an TextOrientation structure from the text object
      text_orient = make_axlTextOrientation(
                          ?textBlock bad_dim->textBlock,   ; text size
                          ?rotation bad_dim->rotation,      ; rotation
                          ?mirrored bad_dim->isMirrored, 
                          ?justify bad_dim->justify)
      
      ; grab xy corordinates
      coord_y = nth( 1 bad_dim->xy)
      coord_x = nth( 0 bad_dim->xy)

      ; write the text into the correct layer (subclass)
      axlDBCreateText( bad_dim->text,             ; text to write
                   coord_x:coord_y,               ; location to write it
                   text_orient,                   ; orientation struct
                   "PACKAGE GEOMETRY/DIMENSION",  ; layer to write on
                   bad_dim->parent)               ; attach to object ?
      )
    ) ; END: if( bad_dim->objType == "text"
  ) ; END: foreach( bad_dim bad_dims

  ; delete all the crap from Bad Dim layer, usually "BOARD GEOMETRY/DIMENSION"  
  axlDeleteObject(axlGetSelSet())

  ; print end message
  printf("\nEND: _DTL_ZMoveDimensions()\n")

) ; END:   prog( ()
) ; END: procedure( _DTL_ZMoveDimensions()



;________________________________________________________________________________
;********************************************************************************
;--------------------------------------------------------------------------------
;
procedure( _DTL_PARTS_ZCopySilk2Ass()
  prog( ()

  ; print start message
  printf("\nSTART: _DTL_PARTS_ZCopySilk2Ass()\n")

  ; write debug info to file?
  __DEBUG_PRINT__ = nil

  ; get dbug file handle
  if(__DEBUG_PRINT__
  then
    if( isFile("__DEBUG_DTL_PARTS_ZCopySilk2Ass.txt")
    then
      OutDBGFile = outfile("__DEBUG_DTL_PARTS_ZCopySilk2Ass.txt" "a")
      fprintf(OutDBGFile "\n\nSTART FUNCTION: _DTL_PARTS_ZCopySilk2Ass\n\n")
      drain(OutDBGFile)
    else
      OutDBGFile = outfile("__DEBUG_DTL_PARTS_ZCopySilk2Ass.txt" "w")
      fprintf(OutDBGFile "\n\nSTART FUNCTION: _DTL_PARTS_ZCopySilk2Ass\n\n")
      drain(OutDBGFile)
    )
  )


  OrigSettings = _DTL_UTILS_SettingsGet()

  ; get everything on PACKAGE GEOMETRY/ASSEMBLY_TOP and delete it.
  axlVisibleDesign(nil)
  axlVisibleLayer("PACKAGE GEOMETRY/ASSEMBLY_TOP" t)

  axlClearSelSet()
  axlSetFindFilter( 
          ?enabled list( "NOALL" "ALLTYPES") 
          ?onButtons list("NOALL" "ALLTYPES"))
  axlAddSelectAll()
  axlDeleteObject(axlGetSelSet())
  axlClearSelSet()

  ; get all lines on "PACKAGE GEOMETRY/SILKSCREEN_TOP"
  axlVisibleDesign(nil)
  axlVisibleLayer("PACKAGE GEOMETRY/SILKSCREEN_TOP" t)
  axlVisibleUpdate(t)  
  axlClearSelSet()
  axlSetFindFilter(
        ?enabled list("NOALL" "SHAPES" "FIGURES" "CLINES" "CLINESEGS" "LINES" "LINESEGS") 
        ?onButtons list("NOALL" "SHAPES" "FIGURES" "CLINESEGS" "LINES" "LINESEGS"))
;          ?enabled list( "NOALL" "ALLTYPES") 
;          ?onButtons list("NOALL" "ALLTYPES"))
  axlAddSelectAll()
  LineObjList = axlGetSelSet() ; get a list of test objects
;  axlClearSelSet()

    if(__DEBUG_PRINT__
    then
      fprintf(OutDBGFile "LineObjList: ")
      println(LineObjList OutDBGFile)
      pprint( LineObjList->?? OutDBGFile)
      fprintf(OutDBGFile "\n\n")
    )


  ; cycle through each hunk of junk in the Subclass layer of the part.
  foreach( LineObj LineObjList

    if(__DEBUG_PRINT__
    then
      fprintf(OutDBGFile "\n\n")
      fprintf(OutDBGFile "LineObj: ")
      pprint( LineObj->?? OutDBGFile)
      fprintf(OutDBGFile "\n\n")
    )
  
; _FIXME_ -to deal with arcs, circles and other such stuff.
    ; test if we're dealing with a path (line/cline/segs)
    if( LineObj->objType == "path"
    then
      seg_count = 0
      foreach( segment LineObj->segments
        if( segment->objType == "line"
        then
        
          if( seg_count == 0
          then
            ; get the first coordinate in list (of xy lists)
            ; i.e. startEnd ( (193.5 -117.1) (201.5 -117.1) )
            ; returns (193.5 -117.1)
            coord_pair = nth( 0 segment->startEnd)
            coord_y = nth( 1 coord_pair)
            coord_x = nth( 0 coord_pair)
        
            ; create an r_path structure named "path"
            path = axlPathStart( list(coord_x:coord_y))
        
            if(__DEBUG_PRINT__
            then
              fprintf(OutDBGFile "\n\n")
              fprintf(OutDBGFile "segment: \n")
              pprint( segment->?? OutDBGFile)
        
              fprintf(OutDBGFile "\n")
              fprintf(OutDBGFile "1st coord_pair: ")
              pprint( coord_pair OutDBGFile)
              fprintf(OutDBGFile "\n")
              fprintf(OutDBGFile "coord_x: ")
              println(coord_x OutDBGFile)
              fprintf(OutDBGFile "coord_y: ")
              println(coord_y OutDBGFile)
              coord_list =  list(coord_x:coord_y )
              fprintf(OutDBGFile "coord_list: ")
              pprint(coord_list OutDBGFile)
            ) ; END: if __DEBUG_PRINT__
          ) ; END: if seg_count == 0
        
          ; get the second coordinate in list (of xy lists)
          ; if startEnd ((193.5 -117.1) (201.5 -117.1))
          ; it  returns (201.5 -117.1)
          coord_pair = nth( 1 segment->startEnd)
          coord_y = nth( 1 coord_pair)
          coord_x = nth( 0 coord_pair)
        
          ; add coordinate to the r_path structure
          axlPathLine( path, nil, coord_x:coord_y)
        
          if(__DEBUG_PRINT__
          then
            fprintf(OutDBGFile "\n\n")
            fprintf(OutDBGFile "segment: \n")
            pprint( segment->?? OutDBGFile)
        
            fprintf(OutDBGFile "\n")
            fprintf(OutDBGFile "2nd coord_pair: ")
            pprint( coord_pair OutDBGFile)
            fprintf(OutDBGFile "\n")
            fprintf(OutDBGFile "coord_x: ")
            println(coord_x OutDBGFile)
            fprintf(OutDBGFile "coord_y: ")
            println(coord_y OutDBGFile)
            coord_list =  list(coord_x:coord_y )
            fprintf(OutDBGFile "coord_list: ")
            pprint(coord_list OutDBGFile)
          ) ; END: if __DEBUG_PRINT__
        
          seg_count++
        ) ; END: for  i 0 seg_count
        
        ; And finally write the collected path data to the new layer
        axlDBCreatePath( path "PACKAGE GEOMETRY/ASSEMBLY_TOP")
      ) ; END: if segment->objType == "line"
    else
      if( LineObj->objType == "polygon"
      then
        if( LineObj->isRect == t
        then
          ; create rectangle
          axlDBCreateRectangle(LineObj->bBox nil "PACKAGE GEOMETRY/ASSEMBLY_TOP")
        )
      else
          if(__DEBUG_PRINT__
          then
            println("\nUnhandled Shape\n" OutDBGFile)
            pprint(LineObj->?? OutDBGFile)
          ) ; END: if __DEBUG_PRINT__
      ) ; END: if LineObj->objType == "polygon"
    ) ; END: if  LineObj->objType == "path"
  ) ; END: foreach LineObj LineObjs



  ;restore original settings and update screen
  _DTL_UTILS_SettingsSet(OrigSettings t nil)
  
  RetVal = t
  if(__DEBUG_PRINT__
  then
    fprintf(OutDBGFile "\nReturn Value: ")
    println(RetVal OutDBGFile)
    println("END: _DTL_PARTS_ZCopySilk2Ass()" OutDBGFile)
    drain(OutDBGFile)
    close(OutDBGFile)
  )

  ; print end message
  printf("\nEND: _DTL_PARTS_ZCopySilk2Ass()\n")

) ; END:   prog( ()
) ; END: procedure( _DTL_ZCopySilk2Ass()


;________________________________________________________________________________
;********************************************************************************
;--------------------------------------------------------------------------------
;
procedure( _DTL_PARTS_ZCopyAss2Silk()
  prog( ()

  ; print start message
  printf("\nSTART: _DTL_PARTS_ZCopyAss2Silk()\n")

  ; write debug info to file?
  __DEBUG_PRINT__ = t

  ; get dbug file handle
  if(__DEBUG_PRINT__
  then
    if( isFile("__DEBUG_DTL_PARTS_ZCopyAss2Silk.txt")
    then
      OutDBGFile = outfile("__DEBUG_DTL_PARTS_ZCopyAss2Silk.txt" "a")
      fprintf(OutDBGFile "\n\nSTART FUNCTION: _DTL_PARTS_ZCopyAss2Silk\n\n")
      drain(OutDBGFile)
    else
      OutDBGFile = outfile("__DEBUG_DTL_PARTS_ZCopyAss2Silk.txt" "w")
      fprintf(OutDBGFile "\n\nSTART FUNCTION: _DTL_PARTS_ZCopyAss2Silk\n\n")
      drain(OutDBGFile)
    )
  )

  OrigSettings = _DTL_UTILS_SettingsGet()

  ; get everything on PACKAGE GEOMETRY/SILKSCREEN_TOP and delete it.
  axlVisibleDesign(nil)
  axlVisibleLayer("PACKAGE GEOMETRY/SILKSCREEN_TOP" t)

  axlClearSelSet()
  axlSetFindFilter( 
          ?enabled list( "NOALL" "ALLTYPES" "NOTEXT") 
          ?onButtons list("NOALL" "ALLTYPES"))
  axlAddSelectAll()
  axlDeleteObject( axlGetSelSet() )
  axlClearSelSet()

  ; get all lines on "PACKAGE GEOMETRY/ASSEMBLY_TOP"
  axlVisibleDesign(nil)
  axlVisibleLayer("PACKAGE GEOMETRY/ASSEMBLY_TOP" t)
  axlVisibleUpdate(t)  
  axlClearSelSet()
  axlSetFindFilter(
        ?enabled list("NOALL" "SHAPES" "FIGURES" "CLINES" "CLINESEGS" "LINES" "LINESEGS") 
        ?onButtons list("NOALL" "SHAPES" "FIGURES" "CLINES" "CLINESEGS" "LINES" "LINESEGS"))
;          ?enabled list( "NOALL" "ALLTYPES") 
;          ?onButtons list("NOALL" "ALLTYPES"))
  axlAddSelectAll()
  LineObjList = axlGetSelSet() ; get a list of test objects
;  axlClearSelSet()

    if(__DEBUG_PRINT__
    then
      fprintf(OutDBGFile "LineObjList: ")
      println(LineObjList OutDBGFile)
      pprint( LineObjList->?? OutDBGFile)
      fprintf(OutDBGFile "\n\n")
    )


  ; cycle through each hunk of junk in the Subclass layer of the part
  foreach( LineObj LineObjList

    if(__DEBUG_PRINT__
    then
      fprintf(OutDBGFile "\n\n")
      fprintf(OutDBGFile "LineObj: ")
      pprint( LineObj->?? OutDBGFile)
      fprintf(OutDBGFile "\n\n")
    )
  
    ; test if we're dealing with a path (line/cline/segs)
    ; _FIXME_ -need error checks for segment type of "line" etc.
    if( { {LineObj->objType == "path"} || {{LineObj->objType == "polygon"} && {LineObj->isRect == t} } }
    then
      seg_count = length(LineObj->segments)
      seg_count--
      for( i 0 seg_count
        segment = nth( i LineObj->segments)
        if( i == 0
        then
          ;get the first coordinate in list (of xy lists)
          ; i.e. startEnd ((193.5 -117.1) (201.5 -117.1)
          ; returns (193.5 -117.1)
          coord_pair = nth( 0 segment->startEnd)
          coord_y = nth( 1 coord_pair)
          coord_x = nth( 0 coord_pair)

; __FIXME__
; This is not safe for metric

          ; create an r_path structure named "path"
          path = axlPathStart( list(coord_x:coord_y) 0)

          if(__DEBUG_PRINT__
          then
            fprintf(OutDBGFile "\n")
            fprintf(OutDBGFile "1st coord_pair: ")
            pprint( coord_pair OutDBGFile)
            fprintf(OutDBGFile "\n")
            fprintf(OutDBGFile "coord_x: ")
            println(coord_x OutDBGFile)
            fprintf(OutDBGFile "coord_y: ")
            println(coord_y OutDBGFile)
            coord_list =  list(coord_x:coord_y )
            fprintf(OutDBGFile "coord_list: ")
            pprint(coord_list OutDBGFile)
          )
        ) ; END: if( i == 0

        ;get the second coordinate in list (of xy lists)
        ; if startEnd ((193.5 -117.1) (201.5 -117.1))
        ; it  returns (201.5 -117.1)
        coord_pair = nth( 1 segment->startEnd)
        coord_y = nth( 1 coord_pair)
        coord_x = nth( 0 coord_pair)

; __FIXME__
; This is not safe for metric
        ; add coordinate to the r_path structure
        axlPathLine( path 0 coord_x:coord_y)

          if(__DEBUG_PRINT__
          then
            fprintf(OutDBGFile "\n")
            fprintf(OutDBGFile "2nd coord_pair: ")
            pprint( coord_pair OutDBGFile)
            fprintf(OutDBGFile "\n")
            fprintf(OutDBGFile "coord_x: ")
            println(coord_x OutDBGFile)
            fprintf(OutDBGFile "coord_y: ")
            println(coord_y OutDBGFile)
            coord_list =  list(coord_x:coord_y )
            fprintf(OutDBGFile "coord_list: ")
            pprint(coord_list OutDBGFile)
          )
      ) ; END: for( i 0 seg_count

      ; And finally write the collected path data to the new layer
      axlDBCreatePath( path "PACKAGE GEOMETRY/SILKSCREEN_TOP")

    ;--------------------------------------------------------------------------------
    ; Deal with polygons / shapes
    else
      if( LineObj->objType == "polygon"
      then
        if( LineObj->isRect == t
        then
          ; create rectangle this hack works for going from silk to ass
          ; but not the other way around since it creates a silk with a width
          ; of zero (i.e. it only shows up on the drawing but not on the board.
          ;
          ;axlDBCreateRectangle(LineObj->bBox nil "PACKAGE GEOMETRY/SILKSCREEN_TOP")
          
          println("oh crap")
          
        )
      else
          if(__DEBUG_PRINT__
          then
            println("\nUnhandled Shape\n" OutDBGFile)
            pprint(LineObj->?? OutDBGFile)
          )
      ) ; END: if LineObj->objType == "polygon"

    ) ; END: if( LineObj->objType == "path"
  ) ; END: foreach( LineObj LineObjs


  ;restore original settings and update screen
  _DTL_UTILS_SettingsSet(OrigSettings t nil)
  RetVal = t
  if(__DEBUG_PRINT__
  then
    fprintf(OutDBGFile "\nReturn Value: ")
    println(RetVal OutDBGFile)
    println("END: _DTL_PARTS_ZCopyAss2Silk()" OutDBGFile)
    drain(OutDBGFile)
    close(OutDBGFile)
  )

  ; print end message
  printf("\nEND: _DTL_PARTS_ZCopyAss2Silk()\n")

) ; END:   prog( ()
) ; END: procedure( _DTL_PARTS_ZCopyAss2Silk()


;________________________________________________________________________________
;********************************************************************************
;--------------------------------------------------------------------------------
;
procedure( _DTL_PARTS_InfoSubclassCreate()
  prog( ()

  if( axlIsLayer(GV_PACKAGE_GEOMETRY_DIMENSION) == nil
  then
    axlLayerCreateNonConductor(GV_PACKAGE_GEOMETRY_DIMENSION)
  )

  if( axlIsLayer(GV_PACKAGE_GEOMETRY_INFO_INTERNAL) == nil
  then
    axlLayerCreateNonConductor(GV_PACKAGE_GEOMETRY_INFO_INTERNAL)
  )

  if( axlIsLayer(GV_PACKAGE_GEOMETRY_INFO_EXTERNAL) == nil
  then
    axlLayerCreateNonConductor(GV_PACKAGE_GEOMETRY_INFO_EXTERNAL)
  )

;  ; component dimensions layer to keep them out of the way on the board level
;  axlLayerCreateNonConductor("PACKAGE GEOMETRY/DIMENSION")
;  
;  ; A layer (subclass) for internal/private FIXED data like the IPC standard 
;  ; land pattern footprint name for this part, part database ID, my initials, 
;  ; dirty jokes and whatever else I think of.
;  ;
;  ; NOTE: use something innocuous like "PROJECT_UID" to store a ROT13 encoded
;  ; password for protected files.
;  ;
;  ; NOTE: I'll have to adde code to set the "FIXED" property to the text
;  ; nodes on this layer to prevent them from getting accidentally changed.
;  ;
;  axlLayerCreateNonConductor("PACKAGE GEOMETRY/DATA_INTERNAL")
;  
;    ; IPC_PATTERN     - IPC Land Pattern Name (if any)
;    ; PROJECT_UID     - ROT13 encoded password
;    ; INTERNAL_UID    - Our Internal Part Database ID for this part
;    ; COPYRIGHT       - Copyright notice
;    ;
;    ; PIN_COUNT       - number of pins
;    ; PAD_COUNT       - number of pads
;    ; PADSTACKS       - padstacks used
;    ; DIM_UPPER_E     - dimension "E"
;    ; DIM_LOWER_E     - dimension "e"
;  
;  ; A layer (subclass) for external/public VARIABLE data displayed to the 
;  ; cusomer such as the symbol name used by the customer.
;  axlLayerCreateNonConductor("PACKAGE GEOMETRY/DATA_EXTERNAL")
;
;    ; SYMBOL_NAME
;    ; IPC_PATTERN
;    ; PIN_COUNT
;    ; PAD_COUNT
;    ; COPYRIGHT
;    ; PADSTACKS
;    ;
;    ; DATASHEET
;  
;

) ; END:   prog( ()
) ; END: procedure( _DTL_PARTS_SetCheckColors()



;________________________________________________________________________________
;********************************************************************************
;--------------------------------------------------------------------------------
procedure( _DTL_PARTS_InfoAddText()
  prog( ()

  ; print start message
  printf("\nSTART: (_DTL_PARTS_InfoAddText)\n")

  ; turn on visibility on all layers
  axlVisibleDesign(t)       ; set all layers visible
  axlVisibleUpdate(t)       ; update visible objects
  axlUIWUpdate(nil)         ; do UI main window update
  axlUIWRedraw(nil)         ; force refresh of main window


  ;--------------------------------------------------------------------------------
  ; fix part origin
;  _DTL_PARTS_FixOrigin()
;  axlSaveDesign()

  ; turn on visibility on all layers
  axlVisibleDesign(t)       ; set all layers visible
  axlVisibleUpdate(t)       ; update visible objects
  axlUIWUpdate(nil)         ; do UI main window update
  axlUIWRedraw(nil)         ; force refresh of main window

  ;--------------------------------------------------------------------------------
  ; If necessary, add needed part/sybol subclasses/sublayers
  ;--------------------------------------------------------------------------------
  if( { {axlIsLayer(GV_PACKAGE_GEOMETRY_DIMENSION) == nil} ||
        {axlIsLayer(GV_PACKAGE_GEOMETRY_INFO_INTERNAL) == nil} ||
        {axlIsLayer(GV_PACKAGE_GEOMETRY_INFO_EXTERNAL) == nil} }
  then
    _DTL_PARTS_InfoSubclassCreate()
  )

  ; move dimension data to the correct layer
  _DTL_PARTS_ZMoveDim2PGDim()

  ; set part checking colors
  _DTL_PARTS_SetCheckColors()

  ;--------------------------------------------------------------------------------
  ; we need room to write our data, so take our current design size and increas
  ; by ten inches ( or 10000 mm) on all sides
  ;--------------------------------------------------------------------------------
  ; turn on visibility on all layers
  axlVisibleDesign(t)       ; set all layers visible
  axlVisibleUpdate(t)       ; update visible objects
  axlUIWUpdate(nil)         ; do UI main window update
  axlUIWRedraw(nil)         ; force refresh of main window

  ; get the maximum extents of all objects in the part drawing
  CurExtents = axlExtentDB('obstacle)

; __FIXME__ not safe for metric

  ; add two bBox lists together, increasing drawing size by 20000
  NewExtents = bBoxAdd(CurExtents '((-20000 -20000) (20000 20000)))

  ; set the new drawing size to the increased extents bBox
  axlDBChangeDesignExtents(NewExtents)

  ; zoom the display to a comforable size
  axlShell("zoom fit; zoom out;")

  ; set line counter for the DATA_INTERNAL and DATA_EXTERNAL layers
  Ext_LineCount = 0
  Int_LineCount = 0
  


  ;--------------------------------------------------------------------------------
  ; if any text exists, delete the text in the "DATA_EXTERNAL" layer
  ; since this data may have changed. For example, this part was used in a board
  ; then dumped from board and has a new symbol name.
  ;--------------------------------------------------------------------------------
  axlClearSelSet()
  axlVisibleDesign(nil)
  axlVisibleLayer(GV_PACKAGE_GEOMETRY_INFO_EXTERNAL t)
  axlSetFindFilter(?enabled list("noall" "text") ?onButtons list("noall" "text"))
  axlAddSelectAll()
  axlDeleteObject(axlGetSelSet())
  axlClearSelSet()

  ; get the symbol name (design) string
  symbol_name = axlCurrentDesign()
  text_data = strcat( "SYMBOL_NAME: " symbol_name "\n")
  Int_LineCount++
  
  ; write IPC Land Pattern Name
  text_data = strcat( text_data "IPC_PATTERN: \n")
  Int_LineCount++


  ; get all pins in the part
	axlClearSelSet()
	axlSetFindFilter( ?enabled  list("noall" "pins" "invisible") 
			  ?onButtons  list( "noall" "pins"))
	axlAddSelectAll()
	pins = axlGetSelSet()

  ; count the pins
  pin_count = length(pins)
  ; write the pin count for the part
  text_data = strcat( text_data "PIN_COUNT..: ")
  text_data = strcat( text_data sprintf(nil "%d" pin_count) "\n")
  Int_LineCount++

  ; get the dbid for the design (top level dbid of database)
  design_dbid = axlDBGetDesign()

  ; count the pads
  pad_count = length(design_dbid->padstacks)
  ; write the pad count for the part
  text_data = strcat( text_data "PAD_COUNT..: ")
  text_data = strcat( text_data sprintf(nil "%d" pad_count) "\n")
  Int_LineCount++
  text_data = strcat( text_data "PADSTACKS..: (see name legend)\n")
  Int_LineCount++

  n_count = 0
  ; loop throug padstacks in design coutning how many times a padstack is
  ; used for a pin in the symbol. generate strings with pad usage "(count)"
  foreach( padstack design_dbid->padstacks
    n_count++
    p_count = 0
    foreach( pin pins
      if( pin->name == padstack->name
        p_count++
      )
    ) ;foreach pin
    temp_text = sprintf( nil "(%d): " p_count)
    temp_text = sprintf( nil "%13s" temp_text)
    text_data = strcat( text_data temp_text padstack->name)
    if( n_count != pad_count
    then
      text_data = strcat( text_data "\n")
      Int_LineCount++
    ) ;end if
  ) ; foreach padstack

  ; write copyright info
  text_data = strcat( text_data "\nCOPYRIGHT..: Millennium Design Inc.")
  Int_LineCount++


  ;--------------------------------------------------------------------------------
  ; The base textBlock sizes are a pain to read because the lines are too close
  ; together. We adjust the text block line height so things print better. We
  ; also need the text height (different than line height) so we can properly
  ; place our new text outside of the existing drawing extents.
  ;

; __FIXME__
; This should use the global var for textBlock size

  ParamString = sprintf( nil "paramTextBlock:%d" GV_BASE_TEXTBLOCK_SIZE)

  ; grab the textBlock object
  ;TxtBlkObj = axlGetParam("paramTextBlock:2")
  TxtBlkObj = axlGetParam(ParamString)

  ; add 20% to the line height
  TxtBlkLine = TxtBlkObj->lineSpace
  TxtBlkLineNew = TxtBlkLine + { TxtBlkLine / 5 }
  
  ; set the object to the increased line height
  TxtBlkObj->lineSpace = TxtBlkLineNew
  axlSetParam(TxtBlkObj)

  ; read the text height of the object
  TxtBlkHeight = TxtBlkObj->height
  
  ;--------------------------------------------------------------------------------
  ; once again we need the drawing extents. We could reuse the CurExtents var
  ; from above but why not waste some of that system RAM
  ;
  ; axlExtentDB('windowfit) is broken in 15.0 but ('obstacle) works though it 
  ; returns a larger than needed extents (i.e. not the minimum which should
  ; be returned by ('windowfit).
  ;
  ; The returned bBox (list of lists) is LowerLeft and UpperRight
  ; 
  ; ((-602.25 -339.53) (553.25 469.32))
  ;
  ;
  TmpExtents = axlExtentDB('obstacle)

  TmpLowLeftCoord  = nth(0 TmpExtents)
  TmpUpRightCoord = nth(1 TmpExtents)

  LowLeftX = nth(0 TmpLowLeftCoord) ; X from lower left corner coords (X Y)
  LowLeftY = nth(1 TmpLowLeftCoord) ; Y from lower left corner coords (X Y)
  UpRightX = nth(0 TmpUpRightCoord) ; X from upper right corner coords (X Y)
  UpRightY = nth(1 TmpUpRightCoord) ; Y from upper right corner coords (X Y)

  if(LowLeftX <= 0
  then CnLnLowLeftX = LowLeftX * -1
  else CnLnLowLeftX = LowLeftX
  )
  if(LowLeftY <= 0
  then CnLnLowLeftY = LowLeftY * -1
  else CnLnLowLeftY = LowLeftY
  )
  if(UpRightX <= 0
  then CnLnUpRightX = UpRightX * -1
  else CnLnUpRightX = UpRightX
  )
  if(UpRightY <= 0
  then CnLnUpRightY = UpRightY * -1
  else CnLnUpRightY = UpRightY
  )

  ClineY = min(CnLnLowLeftY CnLnUpRightY)
  ClineX = min(CnLnLowLeftX CnLnUpRightX)

  ; delete everything on "PACKAGE GEOMETRY/BODY_CENTER"
  axlClearSelSet()
  axlVisibleDesign(nil)
  axlVisibleLayer("PACKAGE GEOMETRY/BODY_CENTER" t)
  axlSetFindFilter( ?enabled list( "NOALL" "ALLTYPES") 
                    ?onButtons list("NOALL" "ALLTYPES"))
  axlAddSelectAll()
  axlDeleteObject(axlGetSelSet())
  axlClearSelSet()


  ; Create the X dimension cetner line
  axlDBCreateLine(
    l_points = list(list({ClineX*-1} 0) list(ClineX 0))
    f_width = nil
    t_layer = "PACKAGE GEOMETRY/BODY_CENTER"
  )

  ; Create the Y dimension cetner line
  axlDBCreateLine(
    l_points = list(list( 0 {ClineY*-1}) list(0 ClineY))
    f_width = nil
    t_layer = "PACKAGE GEOMETRY/BODY_CENTER"
  )


  ;--------------------------------------------------------------------------------
  ; Adjust for the number of text lines we are adding plus two extra lines 
  ; for proper spacing from the drawing extents
  ;
  NewUpRightY = UpRightY + { round( {{1+Int_LineCount} * TxtBlkLineNew} ) }
  NewXY = list(round(LowLeftX) round(NewUpRightY))

  ; create an TextOrientation structure
  text_orient = make_axlTextOrientation(
                          ?textBlock sprintf( nil "%d" GV_BASE_TEXTBLOCK_SIZE),   ; text size
                          ?rotation 0,      ; rotation
                          ?mirrored nil, 
                          ?justify "left"
                )

  ; write the design/symbol name into the correct layer (subclass)
  axlDBCreateText(  text_data,                              ; text to write
                    NewXY,
                    text_orient,                            ; orientation struct
                    GV_PACKAGE_GEOMETRY_INFO_EXTERNAL,      ; layer to write on
                    nil                                     ; attach to object ?
                 )
  

  ; set the TextBlock object back to the original line height
  TxtBlkObj->lineSpace = TxtBlkLine
  axlSetParam(TxtBlkObj)


  ; turn on visibility on all layers
  axlVisibleDesign(t)       ; set all layers visible
  axlVisibleUpdate(t)       ; update visible objects
  axlUIWUpdate(nil)         ; do UI main window update
  axlUIWRedraw(nil)         ; force refresh of main window

  ; zoom the display to a comforable size
  axlShell("zoom fit; zoom out;")

;  ; cool test for getting the created text objects
;  txtlines = axlDBGetAttachedText(sublayer)
;  foreach( txtline txtlines
;    println( txtline )
;  )

  ; print end message
  printf("\nEND: _DTL_PARTS_InfoAddText()\n")

) ; END: prog
) ; END: procedure _DTL_PARTS_InfoAddText()

;********************************************************************************
;--------------------------------------------------------------------------------
;
procedure( _DTL_PARTS_FixOrigin()
  prog( ()

  println("START: _DTL_PARTS_FixOrigin()")

  ; write debug info to file?
  __DEBUG_PRINT__ = nil

  ; get dbug file handle
  if(__DEBUG_PRINT__
  then
    if( isFile("__DEBUG_DTL_PARTS_FixOrigin.txt")
    then
      OutDBGFile = outfile("__DEBUG_DTL_PARTS_FixOrigin.txt" "a")
      fprintf(OutDBGFile "\n\nSTART FUNCTION: _DTL_PARTS_FixOrigin\n\n")
      drain(OutDBGFile)
    else
      OutDBGFile = outfile("__DEBUG_DTL_PARTS_FixOrigin.txt" "w")
      fprintf(OutDBGFile "\n\nSTART FUNCTION: _DTL_PARTS_FixOrigin\n\n")
      drain(OutDBGFile)
    )
  )
 
  ; get all pins in the part
	axlClearSelSet()
	axlVisibleDesign(nil)
	axlVisibleLayer("ETCH/TOP" t)
	axlVisibleUpdate(t)
	axlSetFindFilter( ?enabled  list("noall" "pins" "invisible") 
			              ?onButtons  list( "noall" "pins"))
	axlAddSelectAll()
	pins = axlGetSelSet()
	axlClearSelSet()

  ; for our list of all pin bounding boxes
  pinBBoxList = '()
  pinCount = 0
  pinOne = nil

  ; loop through pins collecting bounding boxes and the Pin #1 object
  foreach( pin pins
    if( pin->number == "1"
    then 
      pinOne = pin
    )
    if(__DEBUG_PRINT__
    then
      fprintf( OutDBGFile "\n")
      pprint(pin OutDBGFile)
      fprintf( OutDBGFile "\n")
      pprint(pin->?? OutDBGFile)
      drain(OutDBGFile)
    )
    ; append the bbox of this pin to the list of all pin bboxes
    pinBBoxList = append(pinBBoxList list(pin->bBox))
    pinCount++
  )

  Check the number of pins is greater
  if(pinCount > 1
  then
    ; get the union of all pin bboxes
    pinBBox = _DTL_UTILS_BBoxCombine( pinBBoxList )
  else
    if(pinCount == 1
    then
      pinBBox = pinOne->bBox
    else
      if(__DEBUG_PRINT__
      then
        println("WARNING: No pins found" OutDBGFile)
        drain(OutDBGFile)
      )
      println("WARNING: No pins found")
      return(nil)
    )
  )

  if(__DEBUG_PRINT__
  then
    pprint(pinBBox OutDBGFile)
    fprintf( OutDBGFile "\n")
    drain(OutDBGFile)
  )

  ; find out if pin #1 is through hole
  if(pinOne->isThrough
  then ; if yes, set origin to pin one.
    ; get center of pin one
    PinOneCenter = pinOne->xy
    if(__DEBUG_PRINT__
    then
      fprintf( OutDBGFile "PinOneCenter: ")
      pprint(PinOneCenter  OutDBGFile)
      drain(OutDBGFile)
    )
    ; negate the X/Y to get the ammount to move the origin by
    MoveOriginBy = list( {car(PinOneCenter) * -1} {cadr(PinOneCenter) *-1} )
    if(__DEBUG_PRINT__
    then
      fprintf( OutDBGFile "\n\nMove Origin By: ")
      pprint(MoveOriginBy  OutDBGFile)
      drain(OutDBGFile)
    )
    RetVal = axlDBChangeDesignOrigin(MoveOriginBy)

  else ; else set origin to center of pin extents
    ; get center of pin bounding box
    BBoxCenter = _DTL_UTILS_BBoxCenter(pinBBox)
    if(__DEBUG_PRINT__
    then
      fprintf( OutDBGFile "BBoxCenter: ")
      pprint(BBoxCenter  OutDBGFile)
      drain(OutDBGFile)
    )
    ; negate the X/Y to get the ammount to move the origin by
    MoveOriginBy = list( {car(BBoxCenter) * -1} {{cadr(BBoxCenter) *-1} } )
    if(__DEBUG_PRINT__
    then
      fprintf( OutDBGFile "\n\nMove Origin By: ")
      pprint(MoveOriginBy  OutDBGFile)
      drain(OutDBGFile)
    )
    RetVal = axlDBChangeDesignOrigin(MoveOriginBy)
  )

  if(__DEBUG_PRINT__
  then
    fprintf(OutDBGFile "\nReturn Value: ")
    println(RetVal OutDBGFile)
    println("END: _DTL_PARTS_FixOrigin()" OutDBGFile)
    drain(OutDBGFile)
    close(OutDBGFile)
  )

  println("END: _DTL_PARTS_FixOrigin()")
  return(RetVal)

) ; END: prog
) ; END: procedure _DTL_PARTS_FixOrigin


;________________________________________________________________________________
;********************************************************************************
;--------------------------------------------------------------------------------
; REQUIRES:
;     TopBot    -Text "TOP" or "BOTTOM"
; 
procedure( _DTL_PARTS_FixPG_PlaceBound(TopBot "t")
  prog( ()

  printf( "\nSTART_: _DTL_PARTS_FixPG_PlaceBound(%s)\n" TopBot)
  ; set Return Value (RetVal) to failure just to be safe
  RetVal = nil

  ; write debug info to file?
  __DEBUG_PRINT__ = t

  ; get dbug file handle
  if(__DEBUG_PRINT__
  then
    if( isFile("__DEBUG_DTL_PARTS_FixPG_PlaceBound.txt")
    then
      OutDBGFile = outfile("__DEBUG_DTL_PARTS_FixPG_PlaceBound.txt" "a")
      fprintf(OutDBGFile "\n\nSTART FUNCTION: _DTL_PARTS_FixPG_PlaceBound\n\n")
      drain(OutDBGFile)
    else
      OutDBGFile = outfile("__DEBUG_DTL_PARTS_FixPG_PlaceBound.txt" "w")
      fprintf(OutDBGFile "\n\nSTART FUNCTION: _DTL_PARTS_FixPG_PlaceBound\n\n")
      drain(OutDBGFile)
    )
  )

  IsTop = nil
  IsBottom = nil

  ; test input
  if( strcmp(TopBot "TOP") == 0
  then
    IsTop = t
  else
    if( strcmp(TopBot "BOTTOM") == 0
    then
      IsBottom = t
    else
      println("ERROR: _DTL_PARTS_FixPG_PlaceBound input not \"TOP\" or \"BOTTOM\"")
      if(__DEBUG_PRINT__
      then
        fprintf(OutDBGFile "\n\n****\nERROR: _DTL_PARTS_FixPG_PlaceBound input not \"TOP\" or \"BOTTOM\"\n\n")
        drain(OutDBGFile)
      ) ; END if__DEBUG_PRINT__
      return(nil)
    ) ; END: if strcmp(TopBot "BOTTOM") == 0
  ) ; END: if strcmp(TopBot "TOP") == 0

  ; set variables containing Class/Subclass names
  PlaceBoundName = strcat("PACKAGE GEOMETRY/PLACE_BOUND_" TopBot)
  AssemblyName   = strcat("PACKAGE GEOMETRY/ASSEMBLY_" TopBot)
  SilkScreenName = strcat("PACKAGE GEOMETRY/SILKSCREEN_" TopBot)
  EtchPinsName   = strcat("ETCH/" TopBot)

  ; Get and delete everything on the "PACAGE GEOMETRY/PLACE_BOUND_TOP" sublayer
  axlClearSelSet()
  axlVisibleDesign(nil)
  axlVisibleLayer(PlaceBoundName t)
  axlSetFindFilter( ?enabled list( "NOALL" "ALLTYPES") 
                    ?onButtons list("NOALL" "ALLTYPES"))
  axlAddSelectAll()
  axlDeleteObject(axlGetSelSet()) ; get a list of test objects
  axlClearSelSet()
  axlCloseFindFilter()

  ; get all pins in the part
	axlClearSelSet()
	axlVisibleDesign(t)
	axlSetFindFilter( ?enabled  list("noall" "pins" "invisible") 
			              ?onButtons  list( "noall" "pins"))
	axlAddSelectAll()
	pins = axlGetSelSet()
	axlClearSelSet()

  ; for our list of all pin bounding boxes
  pinBBoxList = '()
  pinCount = 0

  ; loop through pins collecting bounding boxes and the Pin #1 object
  foreach( pin pins
    if( pin->number == "1"
    then 
      pinOne = pin
    )
    if(__DEBUG_PRINT__ && {pin->isThrough == t}
    then
      fprintf( OutDBGFile "\n")
      pprint(pin OutDBGFile)
      fprintf( OutDBGFile "\n")
      pprint(pin->?? OutDBGFile)
      drain(OutDBGFile)
    )
    
    if( { {IsBottom == t} && {pin->isThrough == t} }
    then
      ; append the bbox of this pin to the list of all pin bboxes
      pinBBoxList = append(pinBBoxList list(pin->bBox))
      pinCount++
    else
      if( IsTop
      then
        pinBBoxList = append(pinBBoxList list(pin->bBox))
        pinCount++
      )
    )
  )

  ; Check the number of pins is greater
  if(pinCount > 1
  then
    ; get the union of all pin bboxes
    pinBBox = _DTL_UTILS_BBoxCombine( pinBBoxList )
  else
    if(pinCount == 1
    then
      pinBBox = pinOne->bBox
    else
      if(__DEBUG_PRINT__
      then
        println("WARNING: No pins found" OutDBGFile)
        drain(OutDBGFile)
      )
      println("WARNING: No pins found")
    )
  )

  ; a little more printing...
  if(__DEBUG_PRINT__
  then
    fprintf( OutDBGFile "\npinBBox: \n")
    pprint( pinBBox OutDBGFile)
    drain(OutDBGFile)
  )

  ; OK, now deal with the other subclasses we have to cover and get a union of
  ; all the bboxes.
  allBBoxList = '()
  assBBox = _DTL_UTILS_GetSubClassBBox(AssemblyName)
  silkBBox = _DTL_UTILS_GetSubClassBBox(SilkScreenName)

  ; a little more printing...
  if(__DEBUG_PRINT__
  then
    fprintf( OutDBGFile "\n\tassBBox: \n")
    pprint( assBBox OutDBGFile)
    fprintf( OutDBGFile "\n\tsilkBBox: \n")
    pprint( silkBBox OutDBGFile)
    drain(OutDBGFile)
  )

  ; build a list of all the BBoxes
  tmpBBoxList = list( pinBBox assBBox silkBBox)
  ; run through the list from above, saving the non nil into a new list.
  foreach( tmpBBox tmpBBoxList
    if(tmpBBox != nil
    then
       allBBoxList = append( allBBoxList list(tmpBBox))
    )
  )
  
  ; print out our count of good BBoxes
  if(__DEBUG_PRINT__
  then
    fprintf( OutDBGFile "\nCount of good BBox: ")
    pprint(length(allBBoxList) OutDBGFile )
    fprintf( OutDBGFile "\n\nallBBoxList: %L\n" allBBoxList)
    drain(OutDBGFile)
  )

  ; deal with the number of good BBoxes
  if(length(allBBoxList) > 1
  then
    ; if more than one is good, then find the combined bBox of all of the bBoxes
    allBBox = _DTL_UTILS_BBoxCombine( allBBoxList )
  else
    if(length(allBBoxList) == 1
    then
      ; it seems only one of our tmpBBoxList was good, so grab just that one.
      allBBox = car(allBBoxList)
    else
      ; it seems we're hosed, none of the BBoxes were good.
      allBBox = nil
    )
  )

  ; a little more printing...
  if(__DEBUG_PRINT__
  then
    fprintf( OutDBGFile "\nallBBox: \n")
    pprint( allBBox OutDBGFile)
    drain(OutDBGFile)
  )


  RetVal = nil
  if( allBBox
  then
;__FIXME__
; this is not safe for metric parts

;__FIXME__
; This crap should have a config file or config interface so the user can
; set their prefered overage
 
    if(TopBot == "TOP"
    then
      ; if PLACE_BOUND_TOP give us +5 mils on all sides
;      newBBox = bBoxAdd(allBBox '((-125 -125) (125 125)))
      newBBox = bBoxAdd(allBBox '((-5 -5) (5 5)))
    else
      if(TopBot == "BOTTOM"
      then
        ; if PLACE_BOUND_BOTTOM give us +125 mils on all sides
        newBBox = bBoxAdd(allBBox '((-125 -125) (125 125)))
      )
    )      
  
    ; generate a new filled rectangle on Package Geometry Place Bound Top
    RetVal = axlDBCreateRectangle( newBBox t PlaceBoundName)
    
    ; test RetVal
    if(RetVal
    then
      RetVal = t
    else
      RetVal = nil
    )
  else
    RetVal = nil
  )
  
  if(__DEBUG_PRINT__
  then
    fprintf(OutDBGFile "\nReturn Value: ")
    println(RetVal OutDBGFile)
    println("END: _DTL_PARTS_FixPG_PlaceBound()" OutDBGFile)
    drain(OutDBGFile)
    close(OutDBGFile)
  )

  printf( "\nEND___: _DTL_PARTS_FixPG_PlaceBound(%s)\n" TopBot)
  return(RetVal)

) ; END: prog
) ; END: procedure _DTL_PARTS_FixPG_PlaceBound()




;________________________________________________________________________________
;********************************************************************************
;--------------------------------------------------------------------------------
;
; Fix Plated Through Hole on PACKAGE_GEOMETRY/PLACE_BOUND_BOTTOM
;
procedure( _DTL_PARTS_FixPTH_PKG_GEO_PBB()
  prog( ()

  println("START: _DTL_PARTS_FixPTH_PKG_GEO_PBB()")

  ; write debug info to file?
  __DEBUG_PRINT__ = t

  ; get dbug file handle
  if(__DEBUG_PRINT__
  then
    if( isFile("__DEBUG_DTL_PARTS_FixPTH_PKG_GEO_PBB.txt")
    then
      OutDBGFile = outfile("__DEBUG_DTL_PARTS_FixPTH_PKG_GEO_PBB.txt" "a")
      fprintf(OutDBGFile "\n\nSTART FUNCTION: _DTL_PARTS_FixPTH_PKG_GEO_PBB\n\n")
      drain(OutDBGFile)
    else
      OutDBGFile = outfile("__DEBUG_DTL_PARTS_FixPTH_PKG_GEO_PBB.txt" "w")
      fprintf(OutDBGFile "\n\nSTART FUNCTION: _DTL_PARTS_FixPTH_PKG_GEO_PBB\n\n")
      drain(OutDBGFile)
    )
  )
 
  ; get all pins in the part
	axlClearSelSet()
	axlVisibleDesign(nil)
	axlVisibleLayer("ETCH/BOTTOM" t)
	axlVisibleUpdate(t)
	axlSetFindFilter( ?enabled  list("noall" "pins" "invisible") 
			              ?onButtons  list( "noall" "pins"))
	axlAddSelectAll()
	pins = axlGetSelSet()
	axlClearSelSet()

  ; for our list of all pin bounding boxes
  pinBBoxList = '()
  pinCount = 0


  ; get the design DBID so we can access the padstacks
  design_dbid = axlDBGetDesign()

  myOShapeList = '()

  poly_count = 0

  ; loop through pins collecting bounding boxes and the Pin #1 object
  foreach( pin pins
    if(__DEBUG_PRINT__
    then
      fprintf( OutDBGFile "\n\nPIN:\n")
      pprint(pin OutDBGFile)
      fprintf( OutDBGFile "\n")
      pprint(pin->?? OutDBGFile)
      drain(OutDBGFile)
    )
    if( pin->isThrough
    then
;      myCircle = '()
;      ; get the center of the pin
;      myCircle = append(myCircle pin->xy)
      
; __FIXME__
; Going with the actual size of the pad on ETCH/BOTTOM may be more accurate
; but going with the bounding box of the pin is probably a safer bet.
;
;      foreach( padstack design_dbid->padstacks
;          if( pin->name == padstack->name
;          then
;            if(__DEBUG_PRINT__
;            then
;              fprintf( OutDBGFile "\n\nPADSTACK:\n")
;              pprint(padstack OutDBGFile)
;              fprintf( OutDBGFile "\n")
;              pprint(padstack->?? OutDBGFile)
;              drain(OutDBGFile)
;            ) ; END if __DEBUG_PRINT__
;          ) ; END: if pin->name == padstack->name
;      ) ; foreach padstack


;    ( (-368.5 -368.5) (-231.5 -231.5) )

;      ll_x = car(car(pin->bBox))
;      ll_y = car(cdr(car(pin->bBox)))
;      ur_x = cdar(pin->bBox)
;      ur_y = cddar(pin->bBox)
      

      ll_x = nth(0 nth( 0 pin->bBox))
      ll_y = nth(1 nth( 0 pin->bBox))
      ur_x = nth(0 nth( 1 pin->bBox))
      ur_y = nth(1 nth( 1 pin->bBox))

      ; get length of X and length of Y
      x_len = ur_x - ll_x
      y_len = ur_y - ll_y

      ; get hypotenuse of square/rectangle
      hypot = sqrt({x_len**2} + {y_len**2})

; __FIXME__
; This is not safe for metric
      ; set radius (edge of pat plus 125 mils
      radius = round({hypot/2} + 125)
      
      myCircle = '()
      myCircle = append(myCircle list(pin->xy))
      myCircle = append(myCircle list(radius))


      if(__DEBUG_PRINT__
      then
        fprintf( OutDBGFile "\n\nll_x:")
        println(ll_x OutDBGFile)
        fprintf( OutDBGFile "ll_y:")
        println(ll_y OutDBGFile)
        fprintf( OutDBGFile "ur_x:")
        println(ur_x OutDBGFile)
        fprintf( OutDBGFile "ur_y:")
        println(ur_y OutDBGFile)
        fprintf( OutDBGFile "x_len:")
        println(x_len OutDBGFile)
        fprintf( OutDBGFile "x_len:")
        println(x_len OutDBGFile)
        fprintf( OutDBGFile "\nhypot:")
        println(hypot OutDBGFile)
        fprintf( OutDBGFile "radius:")
        println(radius OutDBGFile)
        fprintf( OutDBGFile "myCircle:")
        println(myCircle OutDBGFile)
        drain(OutDBGFile)
      ) ; END if __DEBUG_PRINT__


      ; get the r_path of the circle
      myCirPath = axlPathStartCircle(myCircle 0)

      ; open the shape     
      myOShape = axlDBCreateOpenShape( myCirPath t "PACKAGE GEOMETRY/PLACE_BOUND_BOTTOM")    
      
      ;punch holes in it
      foreach( zpin pins
        if( zpin->isThrough
        then
          zll_x = nth(0 nth( 0 zpin->bBox))
          zll_y = nth(1 nth( 0 zpin->bBox))
          zur_x = nth(0 nth( 1 zpin->bBox))
          zur_y = nth(1 nth( 1 zpin->bBox))
      
          ; get length of X and length of Y
          zx_len = zur_x - zll_x
          zy_len = zur_y - zll_y
      
          ; get hypotenuse of square/rectangle
          zhypot = sqrt({zx_len**2} + {zy_len**2})
      
;     __FIXME__
;     This is not safe for metric +125 mils
          ; set radius (edge of pat plus 125 mils
          zradius = round({zhypot/2} + 125)

          zmyCircle = '()
          zmyCircle = append(zmyCircle list(zpin->xy))
          zmyCircle = append(zmyCircle list(zradius))
      
          axlDBCreateVoidCircle(myOShape zmyCircle)
        )
      )

      axlDBCreateCloseShape(myOShape t)

;      axlDBCreateShape( myCirPath t "PACKAGE GEOMETRY/PLACE_BOUND_BOTTOM")    
;      myOShapeList = append(myOShapeList list(myOShape))
;      axlPolyFromDB(
;      axlPolyFromHole(
     
  
      poly_count++
      
    ) ; END: if pin->isThrough
  ) ; END: foreach pin pins


;      _fpUtilPolyMerge()
;      axlDBCreateShape( newPoly t "PACKAGE GEOMETRY/PLACE_BOUND_BOTTOM")    


;      axlDBCreateCloseShape(newPoly t)
;      axlDBCreateVoidCircle(myOShape myCirPath)
;      axlDBCreateCloseShape(myOShape t)


  if(__DEBUG_PRINT__
  then
    fprintf(OutDBGFile "\nReturn Value: ")
    println(RetVal OutDBGFile)
    println("END: _DTL_PARTS_FixPTH_PKG_GEO_PBB()" OutDBGFile)
    drain(OutDBGFile)
    close(OutDBGFile)
  )

  println("END: _DTL_PARTS_FixPTH_PKG_GEO_PBB()")
  return(RetVal)

) ; END: prog
) ; END: procedure _DTL_PARTS_FixPTH_PKG_GEO_PBB



;________________________________________________________________________________
;********************************************************************************
;--------------------------------------------------------------------------------
;
; Crop part Drawing size to something reasonable. Other functions make the
; size of the drawing _HUGE_ so we don't hit write errors when adding text 
; or whatever else we add. The parts then need to be cropped back down so
; they don't take up so much room on disk (and make the board file size huge).
; 
procedure( _DTL_PARTS_CropDrawingSize()
  prog( ()

  ; get the maximum extents of all objects in the part drawing
  CurExtents = axlExtentDB('obstacle)

;__FIXME__
; This is not safe for metric

  ; add two bBox lists together, increasing drawing size by 10000
;  NewExtents = bBoxAdd(CurExtents '((-500 -500) (500 500)))
  NewExtents = bBoxAdd(CurExtents '((-10 -10) (10 10)))


  ; set the new drawing size to the increased extents bBox
  axlDBChangeDesignExtents(NewExtents)

) ; END: prog
) ; END: procedure _DTL_PARTS_CropDrawingSize()

;________________________________________________________________________________
;********************************************************************************
;--------------------------------------------------------------------------------

procedure( _DTL_PARTS_DirCreateSymbols()
  prog( ()

  foreach(FileName rexMatchList("\\.dra$" getDirFiles("."))

    rexCompile("autosave")
    if( { rexMatchp("autosave" FileName) || rexMatchp("AUTOSAVE" FileName) }
    then
      axlMsgPut("Skipping Autosave File/n")
    else
      axlOpenDesign( ?design FileName ?mode "wf" )
      axlCompileSymbol(?silentOnOverwrite t)
	    when(axlOKToProceed()
	    	axlMsgPut("Finished Smybol/n")
	    	axlUIWRedraw(nil)
	    )
      axlVisibleDesign(t)       ; set all layers visible
      axlVisibleUpdate(t)       ; update visible objects
      axlUIWUpdate(nil)         ; do UI main window update
      axlUIWRedraw(nil)         ; force refresh of main window
      axlShell("zoom fit;")     ; zoom the display to a comforable size
      axlSaveDesign()           ; save the design
	    when(axlOKToProceed()
	    	axlMsgPut("Finished Save/n")
	    	axlUIWRedraw(nil)
	    )
	  )
  )
) ; END: prog
) ; END: procedure _DTL_PARTS_DirCreateSymbols()


;________________________________________________________________________________
;********************************************************************************
;--------------------------------------------------------------------------------

procedure( _DTL_PARTS_DirCropDrawingSize()
  prog( ()

  foreach(FileName rexMatchList("\\.dra$" getDirFiles("."))

    rexCompile("autosave")
    if( { rexMatchp("autosave" FileName) || rexMatchp("AUTOSAVE" FileName) }
    then
      axlMsgPut("Skipping Autosave File/n")
    else
      axlOpenDesign( ?design FileName ?mode "wf" )
      axlCompileSymbol(?silentOnOverwrite t)
	    when(axlOKToProceed()
	    	axlMsgPut("Finished Smybol/n")
	    	axlUIWRedraw(nil)
	    )
      _DTL_PARTS_CropDrawingSize()
      axlVisibleDesign(t)       ; set all layers visible
      axlVisibleUpdate(t)       ; update visible objects
      axlUIWUpdate(nil)         ; do UI main window update
      axlUIWRedraw(nil)         ; force refresh of main window
      axlShell("zoom fit;")     ; zoom the display to a comforable size
      axlSaveDesign()           ; save the design
	    when(axlOKToProceed()
	    	axlMsgPut("Finished Save/n")
	    	axlUIWRedraw(nil)
	    )
	  )
  )
) ; END: prog
) ; END: procedure _DTL_PARTS_DirCropDrawingSize()

