;*******************************************************************************
;
; Copyright (c) J.C. Roberts 2005 - All Rights Reserved
;
; NO PART OF THIS FILE MAY BE REPRODUCED, STORED IN A RETRIEVAL SYSTEM,
; OR TRANSMITTED IN ANY FORM OR BY ANY MEANS, INCLUDING ELECTRONIC, MECHANICAL,
; PHOTOCOPYING, RECORDING, OR OTHERWISE, WITHOUT PRIOR WRITTEN PERMISSION
; OF THE COPYRIGHT HOLDER J.C. ROBERTS
;
; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER "AS IS" AND ANY
; EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
; PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER BE
; LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
; OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
; OF SUBSTITUTE GOODS OR SERVICES, LOSS OF USE, DATA, OR PROFITS, OR
; BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
; WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
; OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
; EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
;
;*******************************************************************************



;*******************************************************************************
;
; Register the commands
axlCmdRegister("_DTL_DEBUG_UsefulInfo" "_DTL_DEBUG_UsefulInfo")
axlCmdRegister("_DTL_DEBUG_ClassSubClassInfo" "_DTL_DEBUG_ClassSubClassInfo")
axlCmdRegister("_DTL_DEBUG_DumpSubClassInfo" "_DTL_DEBUG_DumpSubClassInfo")
axlCmdRegister("_DTL_DEBUG_DumpArtFilmInfo" "_DTL_DEBUG_DumpArtFilmInfo")
axlCmdRegister("_DTL_DEBUG_DumpEnvVars" "_DTL_DEBUG_DumpEnvVars")


;********************************************************************************
;
(procedure (_DTL_DBUG_DumpFunctions)
(prog (LogFH FuncName FuncList FullLine Description)
  (setq LogFH (outfile "_DTL_DEBUG_DumpFunctions.log"))
  (setq FullLine "--------------------------------------------------------------------------------")
  fprintf(LogFH "NOTE: _DTL_DEBUG_DumpFunctions via (_lfn \".\")\n\n")  

;  (setq FuncList (_lfn "."))
  (setq FuncList (listFunctions "." t))
;  (setq FuncList (listFunctions ".")


  (setq FuncList (sort FuncList nil))
  (setq oldstdout stdout)
  (setq oldpoport poport)
  (setq oldstderr stderr)
  
  (setq stdout LogFH)
  (setq poport LogFH)
  (setq stderr LogFH)


  
  (foreach FuncName FuncList
    (fprintf LogFH "%s\n %s\n" FullLine, FuncName)
;    (describe FuncName)
;    (setq Description (describe FuncName))
    (fprintf LogFH "\n\n")
  )
  (setq stdout oldstdout)
  (setq poport oldpoport)
  (setq stderr oldstderr)

/*  
Additional Coolness...

(gc "filename.txt")

(fdoc s_symbol "s") 
Returns the documentation string for the function bound to this symbol.

(vdoc s_symbol "s")
Returns the documentation string for the variable bound to this symbol.

(setfdoc s_symbol "s")
Sets documentation string for function bound to this symbol.

(setvdoc s_symbol "s")
Sets documentation string for the variable bound to this symbol.

(arglist s_symbol "s")
Returns the arguments required by this funciton.
(setarglist sym "s")
Defines the arguments required by this function.

(describe s_symbol "s")
Gives a description of the function (and possibly variable) bound to symbol.

(help s_symbol "s")
Gives a description of the function (and possibly variable) bound to symbol.

(printFunctions ?)
Skill > (printFunctions ?)
Loading skillDev.cxt 
E- *Error* listFunctions: argument #1 should be a string (type template = "tgg") - ?
(printFunctions ".")

(listFunctions (str \@optional listAll forceLoad "tgg"))
(listFunctions ".")

(setq OP_func (outfile "./_funcs.txt")) 
(foreach funcvar (listFunctions ".") (printf "%s\n" funcvar)) 
(foreach funcvar (listFunctions ".") (fprintf OP_func "%s\n" funcvar)) 
(drain OP_func) 
(close OP_func)

(listVariables (\@optional str "t"))
(listVariables ".")
(foreach namedvar (listVariables ".") (printf "%s\n" namedvar))

(decode (g_general g_general \@optional g_general \@rest g_general "ggg"))

(getdisc (g_general "g"))

(info (t_string \@optional g_general "tg"))

(getFnReadProtect (s_symbol "s"))

(ilDumpCB )
(ilDumpCFuncs (t_string "t"))
(ilDumpPages (g_general t_string S_stringSymbol \@optional s_symbol "gtSs"))

(ilGetDeepestAlias (name nestedLevels))

(ilGetDefiningCapForFn ?)
(ilGetDefiningCapForVar ?)
*/

)); end LET_AND_PROCEDURE


;________________________________________________________________________________
;********************************************************************************
;
(procedure (_DTL_DBUG_DumpEnvVars)
(prog (LogFH EnvVars VarName)
  (setq LogFH (outfile "_DTL_DEBUG_DumpEnvVars.log"))
  (setq EnvVars (axlGetVariable nil))
  (setq EnvVars (sort EnvVars nil))
  (foreach VarName EnvVars
    (fprintf LogFH "%L: %L\n" VarName (axlGetVariable VarName))
  )
))



;________________________________________________________________________________
;********************************************************************************
;
procedure( _DTL_DEBUG_DumpArtFilmInfo()
prog( ()
  OutFH = outfile( "DT_DEBUG_DUMP_ArtFilm_INFO.txt" )
  fprintf(OutFH "--------------------------------------------------------------------------------\n")
  fprintf(OutFH "CODE: layerGrp = axlGetParam (\"artwork\")\n\n")

  artFilmGrp = axlGetParam("artwork")
  pprint(artFilmGrp->?? OutFH)
  fprintf(OutFH "\n\n")
  fprintf(OutFH "--------------------------------------------------------------------------------\n")


;TmpTxt =  strcat("paramLayerGroup:ETCH/paramLayer:" ClassTxt )

  foreach( filmTxt artFilmGrp->groupMembers
    pprint(filmTxt OutFH)
    fprintf(OutFH "\n\n")

    TmpTxt = strcat("artwork:" filmTxt )
    filmObj = axlGetParam(TmpTxt)
    pprint(filmObj OutFH)
        
    fprintf(OutFH "\n\n")
    fprintf(OutFH "--------------------------------------------------------------------------------\n")

  )

  drain(OutFH)
  close(OutFH)

))

;________________________________________________________________________________
;********************************************************************************
;--------------------------------------------------------------------------------
;
procedure( _DTL_DEBUG_DumpSubClassInfo()
prog( ()

;  _DTL_DEBUG_UsefulInfo()
  OutFH = outfile( "DT_DEBUG_DUMP_SUBCLASS_INFO.txt" )
  fprintf(OutFH "--------------------------------------------------------------------------------\n")
  fprintf(OutFH "CODE: layerGrp = axlGetParam(\"paramLayerGroup:ETCH\")\n\n")

;  layerGrp = axlGetParam("paramLayerGroup")
;  pprint(layerGrp->?? OutFH)
;  fprintf(OutFH "\n")
;  pprint(layerGrp->groupMembers OutFH)
;  fprintf(OutFH "\n\n")
;  printf("\n")

  ; compile our regex, a space
  rexMagic(t)
  rexCompile("[ ]")

  layerGrp = axlGetParam("paramLayerGroup:ETCH")
  foreach( ClassTxt layerGrp->groupMembers
    TmpTxt =  strcat("paramLayerGroup:ETCH/paramLayer:" ClassTxt )
    ClassObj = axlGetParam(TmpTxt)
    pprint(TmpTxt OutFH)
    fprintf(OutFH "\n")
    pprint(ClassObj->?? OutFH)
    fprintf(OutFH "\n\n")
;    ClassName = rexReplace( ClassTxt "_" 0)
;    foreach( SubTxt ClassObj->groupMembers
;      TmpTxt = strcat(TmpTxt "/paramLayer:" SubTxt )
;      SubObj = axlGetParam(TmpTxt)
;      SubClassName = rexReplace( SubTxt "_" 0)
;      fprintf(OutFH "%s/%s\n" ClassTxt SubTxt)
;;      IsTest = sprintf( nil "IsTest_%s_%s" ClassName SubClassName)
;;      IsGood = sprintf( nil "IsGood_%s_%s" ClassName SubClassName)
;;      fprintf(OutFH "%-48s = nil\n"  IsTest)
;;      fprintf(OutFH "%-48s = nil\n" IsGood)
;    )
  )
  
  fprintf(OutFH "--------------------------------------------------------------------------------\n")
  drain(OutFH)
  close(OutFH)
)
)
;________________________________________________________________________________
;********************************************************************************
;--------------------------------------------------------------------------------
;
procedure( _DTL_DEBUG_ClassSubClassInfo()
prog( ()

;  _DTL_DEBUG_UsefulInfo()
  OutFH = outfile( "DT_DEBUG_CLASS_SUBCLASS_INFO.txt" )
  fprintf(OutFH "--------------------------------------------------------------------------------\n")
  fprintf(OutFH "CODE: layerGrp = axlGetParam(\"paramLayerGroup\")\n\n")
;  layerGrp = axlGetParam("paramLayerGroup:PACKAGE GEOMETRY")
  layerGrp = axlGetParam("paramLayerGroup")
  pprint(layerGrp->?? OutFH)
  fprintf(OutFH "\n")
  pprint(layerGrp->groupMembers OutFH)
  fprintf(OutFH "\n\n")
;  printf("\n")

  ; compile our regex, a space
  rexMagic(t)
  rexCompile("[ ]")

  foreach( ClassTxt layerGrp->groupMembers
    TmpTxt =  strcat("paramLayerGroup:" ClassTxt )
    ClassObj = axlGetParam(TmpTxt)
    pprint(ClassTxt OutFH)
    fprintf(OutFH "\n")
    pprint(ClassObj->?? OutFH)
    fprintf(OutFH "\n\n")
    ClassName = rexReplace( ClassTxt "_" 0)
    foreach( SubTxt ClassObj->groupMembers
      TmpTxt = strcat(TmpTxt "/paramLayer:" SubTxt )
      SubObj = axlGetParam(TmpTxt)
      SubClassName = rexReplace( SubTxt "_" 0)
      fprintf(OutFH "%s/%s\n" ClassTxt SubTxt)
      IsTest = sprintf( nil "IsTest_%s_%s" ClassName SubClassName)
      IsGood = sprintf( nil "IsGood_%s_%s" ClassName SubClassName)
      fprintf(OutFH "%-48s = nil\n"  IsTest)
      fprintf(OutFH "%-48s = nil\n" IsGood)
    )
  )
  
  fprintf(OutFH "--------------------------------------------------------------------------------\n")
  drain(OutFH)
  close(OutFH)
)
)
;________________________________________________________________________________
;********************************************************************************
;--------------------------------------------------------------------------------
;
procedure( _DTL_DEBUG_UsefulInfo()
prog( ()

  OutFH = outfile( "DT_DEBUG_USEFUL_INFO.txt" )



  fprintf(OutFH "--------------------------------------------------------------------------------\n")
  fprintf(OutFH "NOTE: Registered axl* Functions\n")
	mapcar(
	   lambda( ( x ) 
		fprintf(OutFH "%s\n" x)
		 ) _lfn("axl")
		)
  fprintf(OutFH "\n\n")
  
  fprintf(OutFH "--------------------------------------------------------------------------------\n")
  fprintf(OutFH "NOTE: All Registered *.* Functions\n")
	mapcar(
	   lambda( ( x ) 
		fprintf(OutFH "%s\n" x)
		 ) _lfn(".")
		)
  fprintf(OutFH "\n\n")
  
  
  fprintf(OutFH "--------------------------------------------------------------------------------\n")
  fprintf(OutFH "NOTE: the . listFunctions\n")
	mapcar(
    lambda( ( x ) 
      fprintf(OutFH "%s\n" x)
		) listFunctions(".")
	)
  fprintf(OutFH "\n\n")


  fprintf(OutFH "--------------------------------------------------------------------------------\n")
  fprintf(OutFH "NOTE: USER Registered Functions/Commands\n")
  fprintf(OutFH "CODE: TmpTxt = axlCmdList()\n")
  TmpTxt = axlCmdList()
  pprint( TmpTxt OutFH)
  fprintf(OutFH "\n\n")

  fprintf(OutFH "--------------------------------------------------------------------------------\n")
  fprintf(OutFH "CODE: AxlVars = axlGetVariable( nil )\n\n")
  Axl_Vars = axlGetVariable( nil )
  (setq Axl_Vars (sort Axl_Vars nil))
  pprint(Axl_Vars->?? OutFH)
  fprintf(OutFH "\n\n")
  foreach(var Axl_Vars
    pprint(var OutFH)
    fprintf(OutFH ": ")
    pprint(axlGetVariable(var) OutFH)
    fprintf(OutFH "\n")
  )



  fprintf(OutFH "--------------------------------------------------------------------------------\n")
  fprintf(OutFH "\nDesign DBID axlDBGetDesign()\n")

  design_dbid = axlDBGetDesign()
  
  pprint(design_dbid OutFH)
  fprintf(OutFH "\n")
  pprint(design_dbid->?? OutFH)

  fprintf(OutFH "--------------------------------------------------------------------------------\n")
  fprintf(OutFH "\naxlDBGetDesign()->padstacks\n")
  
  padstackList = design_dbid->padstacks
  pprint(padstackList OutFH)
  fprintf(OutFH "\n")
  pprint(padstackList->?? OutFH)
  fprintf(OutFH "\n\n")

  fprintf(OutFH "--------------------------------------------------------------------------------\n")
  fprintf(OutFH "Get all pins in the part\n")
  ; get all pins in the part
	axlClearSelSet()
	axlSetFindFilter( ?enabled  list("noall" "pins" "invisible") 
			              ?onButtons  list( "noall" "pins"))
	axlAddSelectAll()
	pins = axlGetSelSet()

  foreach( pin pins
  pprint(pin->?? OutFH)
  fprintf(OutFH "\n")

  )

  fprintf(OutFH "\n\n")

  
  fprintf(OutFH "--------------------------------------------------------------------------------\n")
  fprintf(OutFH "CODE: TmpTxt = getWorkingDir()\n")
  TmpTxt = getWorkingDir()
  fprintf(OutFH "%s" TmpTxt)
  fprintf(OutFH "\n\n")


  fprintf(OutFH "--------------------------------------------------------------------------------\n")
  fprintf(OutFH "CODE: dsn = axlDBGetDesign()\n\n")
  dsn = axlDBGetDesign()
  pprint(dsn->?? OutFH)
  fprintf(OutFH "\n\n")
  
  fprintf(OutFH "--------------------------------------------------------------------------------\n")
  fprintf(OutFH "CODE: dsn = axlGetParam(\"paramDesign\")\n\n")
  dsn = axlGetParam("paramDesign")
  pprint(dsn->?? OutFH)
  fprintf(OutFH "\n\n")
  
  fprintf(OutFH "--------------------------------------------------------------------------------\n")
  fprintf(OutFH "CODE: dsn = axlGetParam(\"paramDisplay\")\n\n")
  dsn = axlGetParam("paramDisplay")
  pprint(dsn->?? OutFH)
  fprintf(OutFH "\n\n")
  
  fprintf(OutFH "--------------------------------------------------------------------------------\n")
  fprintf(OutFH "CODE: txtBlk = axlGetParam(\"paramTextBlock\")\n\n")
  txtBlk = axlGetParam("paramTextBlock")
  pprint(txtBlk->?? OutFH)
  fprintf(OutFH "\n\n")

  fprintf(OutFH "--------------------------------------------------------------------------------\n")
  fprintf(OutFH "CODE: layerGrp = axlGetParam(\"paramLayerGroup\")\n\n")
  layerGrp = axlGetParam("paramLayerGroup")
  pprint(layerGrp->?? OutFH)
  fprintf(OutFH "\n")
  pprint(layerGrp->groupMembers OutFH)
  fprintf(OutFH "\n")

  fprintf(OutFH "--------------------------------------------------------------------------------\n")
  fprintf(OutFH "CODE: layerGrp = axlGetParam(\"paramLayerGroup:VIA CLASS\")\n\n")
  layerGrp = axlGetParam("paramLayerGroup:VIA CLASS")
  pprint(layerGrp->?? OutFH)
  fprintf(OutFH "\n\n")

  fprintf(OutFH "--------------------------------------------------------------------------------\n")
  fprintf(OutFH "CODE: layerGrp = axlGetParam(\"paramLayerGroup:ETCH\")\n\n")
  layerGrp = axlGetParam("paramLayerGroup:ETCH")
  pprint(layerGrp->?? OutFH)
  fprintf(OutFH "\n\n")

  fprintf(OutFH "--------------------------------------------------------------------------------\n")
  fprintf(OutFH "CODE: layerGrp = axlGetParam(\"paramLayerGroup:PACKAGE GEOMETRY\")\n\n")
  layerGrp = axlGetParam("paramLayerGroup:PACKAGE GEOMETRY")
  pprint(layerGrp->?? OutFH)
  fprintf(OutFH "\n\n")

  fprintf(OutFH "--------------------------------------------------------------------------------\n")
  fprintf(OutFH "CODE: layerGrp = axlGetParam(\"paramLayerGroup:DRC ERROR CLASS\")\n\n")
  layerGrp = axlGetParam("paramLayerGroup:DRC ERROR CLASS")
  pprint(layerGrp->?? OutFH)
  fprintf(OutFH "\n\n")

  fprintf(OutFH "--------------------------------------------------------------------------------\n")
  fprintf(OutFH "txtGrp = axlGetParam(\"paramTextBlock:2\")\n\n")
  txtGrp = axlGetParam("paramTextBlock:2")
  pprint(txtGrp->?? OutFH)
  fprintf(OutFH "\n\n")

; UNDOCUMENTED
;_sigGetLayerstackDump 998 39634 "sigsetup.il" nil
  fprintf(OutFH "--------------------------------------------------------------------------------\n")
  fprintf(OutFH "DumpLayers = _sigGetLayerstackDump()\n")
  DumpLayers = _sigGetLayerstackDump()
;  printf("\nDumpLayers: ")
  pprint(DumpLayers OutFH)
  fprintf(OutFH "\n\n")

  fprintf(OutFH "--------------------------------------------------------------------------------\nJCR_END\n")
  close(OutFH)


) ; END: prog( ()
) ; END: procedure( _DTL_DEBUG_UsefulInfo()
