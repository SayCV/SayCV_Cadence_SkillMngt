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

(procedure (_DTL_MENUS)
(let (DMSG UsrMsg PathSet FileSet MenuSet LoadSet)
  (setq DMSG nil)
  (setq UsrMsg (sprintf nil "MESSAGE: DesignTools File Loaded - _DTL_MENUS.il\n"))
  (printf "%s" UsrMsg)
  (setq PathSet (axlGetVariable "designtools"))

  ;MODULE_NAME: base
  (load (strcat PathSet "/base/cfg/DT_config.il"))
  (load (strcat PathSet "/base/ins/DT_uninstall.il"))
  (load (strcat PathSet "/base/lib/_DTL_UTILS.il"))
  (load (strcat PathSet "/base/lib/_DTL_UIGUI.il"))

  ;MODULE_NAME: ChaosUtils
  (load (strcat PathSet "/ChaosUtils/src/chaosutils_DebugSkill.il"))

  ;MODULE_NAME: Extractxsection
  (load (strcat PathSet "/ExtractXSection/src/stack.il"))

  ;MODULE_NAME: NetworkCollections
  (load (strcat PathSet "/NetworkCollections/src/lgs_grid_system.il"))
  (load (strcat PathSet "/NetworkCollections/src/Create_Thermal_Flash.il"))
  (load (strcat PathSet "/NetworkCollections/src/dsy_setlayout.il"))
  (load (strcat PathSet "/NetworkCollections/src/dsy_extract.il"))
  (load (strcat PathSet "/NetworkCollections/src/jfh_refdes_location.il"))
  (load (strcat PathSet "/NetworkCollections/src/jfh_refdes_rotate.il"))
  (load (strcat PathSet "/NetworkCollections/src/jkAdd_ICT_testpoint.il"))
  (load (strcat PathSet "/NetworkCollections/src/jkAddLayerList.il"))
  (load (strcat PathSet "/NetworkCollections/src/lgs_tech_manager_V1_2.il"))
  (load (strcat PathSet "/NetworkCollections/src/pdi_vis.il"))

  ;MODULE_NAME: alignsymbol
  (load (strcat PathSet "/alignsymbol/src/CT_alignsymbol.il"))
  (load (strcat PathSet "/alignsymbol/src/align.il"))
  (load (strcat PathSet "/alignsymbol/src/align_do.il"))
  (load (strcat PathSet "/alignsymbol/src/align_utils.il"))

  ;MODULE_NAME: logomaker
  (load (strcat PathSet "/logomaker/src/logoMaker_ImageMagick.il"))
  (load (strcat PathSet "/logomaker/src/logoMaker_LEDTOOLS.il"))

  ;MODULE_NAME: destub
  (load (strcat PathSet "/destub/src/DT_destub.il"))

  ;MODULE_NAME: deliver
  (load (strcat PathSet "/deliver/src/DT_deliver.il"))

  ;MODULE_NAME: memmon
  (load (strcat PathSet "/memmon/src/DT_memmon.il"))

  ;MODULE_NAME: rotator
  (load (strcat PathSet "/rotator/src/DT_rotator.il"))

));end LET_and_PROCEDURE

(_DTL_MENUS)

