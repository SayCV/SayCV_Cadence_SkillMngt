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

; THIS FILE WAS AUTOMATICLY GENERATED - ALL CHANGES WILL BE LOST

(procedure (DT_install_sets)
(let (DMSG UsrMsg PathSet FileSet MenuSet LoadSet)
  (setq DMSG nil)
  (setq UsrMsg (sprintf nil "MESSAGE: DesignTools File Loaded - DT_install_sets.il\n"))
  (printf "%s" UsrMsg)
  (setq DT_FILE_SETS nil)

  ;MODULE_NAME: base
  (setq PathSet nil)
  (setq FileSet nil)
  (setq PathSet (cons "/base" PathSet))
  (setq PathSet (cons "/base/cfg" PathSet))
  (setq PathSet (cons "/base/lib" PathSet))
  (setq PathSet (cons "/base/ins" PathSet))
  (setq FileSet (cons "/_readme.txt" FileSet))
  (setq FileSet (cons "/base/cfg/DT_config.il" FileSet))
  (setq FileSet (cons "/base/cfg/DT_config_quickhelp.txt" FileSet))
  (setq FileSet (cons "/base/ins/DT_install.il" FileSet))
  (setq FileSet (cons "/base/ins/DT_uninstall.il" FileSet))
  (setq FileSet (cons "/base/ins/DT_install_sets.il" FileSet))
  (setq FileSet (cons "/base/ins/DT_install_menu.il" FileSet))
  (setq FileSet (cons "/base/lib/_DTL_UTILS.il" FileSet))
  (setq FileSet (cons "/base/lib/_DTL_UIGUI.il" FileSet))
  (setq FileSet (cons "/base/lib/_DTL_MENUS.il" FileSet))
  (setq PathSet (reverse PathSet))
  (setq DT_FILE_SETS (cons (list "base" PathSet FileSet) DT_FILE_SETS))

  ;MODULE_NAME: ChaosUtils
  (setq PathSet nil)
  (setq FileSet nil)
  (setq PathSet (cons "/ChaosUtils" PathSet))
  (setq PathSet (cons "/ChaosUtils/src" PathSet))
  (setq FileSet (cons "/ChaosUtils/src/chaosutils_DebugSkill.il" FileSet))
  (setq PathSet (reverse PathSet))
  (setq DT_FILE_SETS (cons (list "ChaosUtils" PathSet FileSet) DT_FILE_SETS))

  ;MODULE_NAME: Extractxsection
  (setq PathSet nil)
  (setq FileSet nil)
  (setq PathSet (cons "/ExtractXSection" PathSet))
  (setq PathSet (cons "/ExtractXSection/src" PathSet))
  (setq FileSet (cons "/ExtractXSection/src/stack.il" FileSet))
  (setq FileSet (cons "/ExtractXSection/src/stack.scr" FileSet))
  (setq FileSet (cons "/ExtractXSection/src/materials.dat" FileSet))
  (setq PathSet (reverse PathSet))
  (setq DT_FILE_SETS (cons (list "Extractxsection" PathSet FileSet) DT_FILE_SETS))

  ;MODULE_NAME: NetworkCollections
  (setq PathSet nil)
  (setq FileSet nil)
  (setq PathSet (cons "/NetworkCollections" PathSet))
  (setq PathSet (cons "/NetworkCollections/src" PathSet))
  (setq FileSet (cons "/NetworkCollections/src/lgs_grid_system.il" FileSet))
  (setq FileSet (cons "/NetworkCollections/src/Create_Thermal_Flash.il" FileSet))
  (setq FileSet (cons "/NetworkCollections/src/dsy_setlayout.il" FileSet))
  (setq FileSet (cons "/NetworkCollections/src/dsy_extract.il" FileSet))
  (setq FileSet (cons "/NetworkCollections/src/jfh_refdes_location.il" FileSet))
  (setq FileSet (cons "/NetworkCollections/src/jfh_refdes_rotate.il" FileSet))
  (setq FileSet (cons "/NetworkCollections/src/jkAdd_ICT_testpoint.il" FileSet))
  (setq FileSet (cons "/NetworkCollections/src/jkAddLayerList.il" FileSet))
  (setq FileSet (cons "/NetworkCollections/src/lgs_tech_manager_V1_2.il" FileSet))
  (setq FileSet (cons "/NetworkCollections/src/CONSTRAINS_V1.lte" FileSet))
  (setq FileSet (cons "/NetworkCollections/src/pdi_vis.il" FileSet))
  (setq PathSet (reverse PathSet))
  (setq DT_FILE_SETS (cons (list "NetworkCollections" PathSet FileSet) DT_FILE_SETS))

  ;MODULE_NAME: alignsymbol
  (setq PathSet nil)
  (setq FileSet nil)
  (setq PathSet (cons "/alignsymbol" PathSet))
  (setq PathSet (cons "/alignsymbol/src" PathSet))
  (setq FileSet (cons "/alignsymbol/src/CT_alignsymbol.il" FileSet))
  (setq FileSet (cons "/alignsymbol/src/CT_alignsymbol_quickhelp.txt" FileSet))
  (setq FileSet (cons "/alignsymbol/src/align.il" FileSet))
  (setq FileSet (cons "/alignsymbol/src/align_do.il" FileSet))
  (setq FileSet (cons "/alignsymbol/src/align_utils.il" FileSet))
  (setq FileSet (cons "/alignsymbol/src/align.form" FileSet))
  (setq FileSet (cons "/alignsymbol/src/align-bottom.bmp" FileSet))
  (setq FileSet (cons "/alignsymbol/src/align-centerH.bmp" FileSet))
  (setq FileSet (cons "/alignsymbol/src/align-centerV.bmp" FileSet))
  (setq FileSet (cons "/alignsymbol/src/align-left.bmp" FileSet))
  (setq FileSet (cons "/alignsymbol/src/align-right.bmp" FileSet))
  (setq FileSet (cons "/alignsymbol/src/align-top.bmp" FileSet))
  (setq FileSet (cons "/alignsymbol/src/distributeH.bmp" FileSet))
  (setq FileSet (cons "/alignsymbol/src/distributeV.bmp" FileSet))
  (setq FileSet (cons "/alignsymbol/src/pickH.bmp" FileSet))
  (setq FileSet (cons "/alignsymbol/src/pickV.bmp" FileSet))
  (setq PathSet (reverse PathSet))
  (setq DT_FILE_SETS (cons (list "alignsymbol" PathSet FileSet) DT_FILE_SETS))

  ;MODULE_NAME: logomaker
  (setq PathSet nil)
  (setq FileSet nil)
  (setq PathSet (cons "/logomaker" PathSet))
  (setq PathSet (cons "/logomaker/src" PathSet))
  (setq FileSet (cons "/logomaker/src/logoMaker_ImageMagick.il" FileSet))
  (setq FileSet (cons "/logomaker/src/logoMaker_LEDTOOLS.il" FileSet))
  (setq FileSet (cons "/logomaker/src/logoMaker_lfc_Help.txt" FileSet))
  (setq PathSet (reverse PathSet))
  (setq DT_FILE_SETS (cons (list "logomaker" PathSet FileSet) DT_FILE_SETS))

  ;MODULE_NAME: destub
  (setq PathSet nil)
  (setq FileSet nil)
  (setq PathSet (cons "/destub" PathSet))
  (setq PathSet (cons "/destub/src" PathSet))
  (setq PathSet (cons "/destub/man" PathSet))
  (setq PathSet (cons "/destub/man/img" PathSet))
  (setq FileSet (cons "/destub/_readme.txt" FileSet))
  (setq FileSet (cons "/destub/src/DT_destub.il" FileSet))
  (setq FileSet (cons "/destub/src/DT_destub_treeset.bmp" FileSet))
  (setq FileSet (cons "/destub/src/DT_destub_dot_grn.bmp" FileSet))
  (setq FileSet (cons "/destub/src/DT_destub_dot_red.bmp" FileSet))
  (setq FileSet (cons "/destub/src/DT_destub_dot_yel.bmp" FileSet))
  (setq FileSet (cons "/destub/src/DT_destub_fld_grn.bmp" FileSet))
  (setq FileSet (cons "/destub/src/DT_destub_fld_hlf.bmp" FileSet))
  (setq FileSet (cons "/destub/src/DT_destub_fld_red.bmp" FileSet))
  (setq FileSet (cons "/destub/src/DT_destub_fld_yel.bmp" FileSet))
  (setq FileSet (cons "/destub/src/DT_destub_dot_blu.bmp" FileSet))
  (setq FileSet (cons "/destub/man/index.html" FileSet))
  (setq FileSet (cons "/destub/man/img/logo.jpg" FileSet))
  (setq PathSet (reverse PathSet))
  (setq DT_FILE_SETS (cons (list "destub" PathSet FileSet) DT_FILE_SETS))

  ;MODULE_NAME: deliver
  (setq PathSet nil)
  (setq FileSet nil)
  (setq PathSet (cons "/deliver" PathSet))
  (setq PathSet (cons "/deliver/src" PathSet))
  (setq PathSet (cons "/deliver/man" PathSet))
  (setq PathSet (cons "/deliver/man/img" PathSet))
  (setq FileSet (cons "/deliver/_readme.txt" FileSet))
  (setq FileSet (cons "/deliver/src/DT_deliver.il" FileSet))
  (setq FileSet (cons "/deliver/man/index.html" FileSet))
  (setq FileSet (cons "/deliver/man/img/logo.jpg" FileSet))
  (setq PathSet (reverse PathSet))
  (setq DT_FILE_SETS (cons (list "deliver" PathSet FileSet) DT_FILE_SETS))

  ;MODULE_NAME: memmon
  (setq PathSet nil)
  (setq FileSet nil)
  (setq PathSet (cons "/memmon" PathSet))
  (setq PathSet (cons "/memmon/src" PathSet))
  (setq PathSet (cons "/memmon/man" PathSet))
  (setq PathSet (cons "/memmon/man/img" PathSet))
  (setq FileSet (cons "/memmon/_readme.txt" FileSet))
  (setq FileSet (cons "/memmon/src/DT_memmon.il" FileSet))
  (setq FileSet (cons "/memmon/man/index.html" FileSet))
  (setq FileSet (cons "/memmon/man/img/logo.jpg" FileSet))
  (setq PathSet (reverse PathSet))
  (setq DT_FILE_SETS (cons (list "memmon" PathSet FileSet) DT_FILE_SETS))

  ;MODULE_NAME: rotator
  (setq PathSet nil)
  (setq FileSet nil)
  (setq PathSet (cons "/rotator" PathSet))
  (setq PathSet (cons "/rotator/src" PathSet))
  (setq PathSet (cons "/rotator/man" PathSet))
  (setq PathSet (cons "/rotator/man/img" PathSet))
  (setq FileSet (cons "/rotator/_readme.txt" FileSet))
  (setq FileSet (cons "/rotator/src/DT_rotator.il" FileSet))
  (setq FileSet (cons "/rotator/src/DT_rotator_quickhelp.txt" FileSet))
  (setq FileSet (cons "/rotator/man/index.html" FileSet))
  (setq FileSet (cons "/rotator/man/img/logo.jpg" FileSet))
  (setq PathSet (reverse PathSet))
  (setq DT_FILE_SETS (cons (list "rotator" PathSet FileSet) DT_FILE_SETS))

));end LET_and_PROCEDURE

(DT_install_sets)

