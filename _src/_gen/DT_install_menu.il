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

(procedure (DT_install_menu)
(let (DMSG UsrMsg PathSet FileSet MenuSet LoadSet)
  (setq DMSG nil)
  (setq UsrMsg (sprintf nil "MESSAGE: DesignTools File Loaded - DT_install_menu.il\n"))
  (printf "%s" UsrMsg)
  (setq DT_MENU_SETS nil)
  (defstruct ZMenuItem name kids text file)

  ;MODULE_NAME: base
  (setq allegro_base (make_ZMenuItem))
  (setq DT_MENU_SETS (cons allegro_base DT_MENU_SETS))
  allegro_base->name = "allegro_base"
  allegro_base->file = "allegro.men"
  allegro_base->kids = nil
  allegro_base->text = nil
  allegro_base->text = (append1 allegro_base->text (list 1 "POPUP \"&ChaosTools\""))
  allegro_base->text = (append1 allegro_base->text (list 1 "BEGIN"))
  allegro_base->text = (append1 allegro_base->text (list 2 "POPUP \"&CT Settings\""))
  allegro_base->text = (append1 allegro_base->text (list 2 "BEGIN"))
  allegro_base->text = (append1 allegro_base->text (list 3 "MENUITEM \"&Configurator\", \"DT_config_main\""))
  allegro_base->text = (append1 allegro_base->text (list 3 "MENUITEM \"&Uninstall\", \"DT_uninstall_main\""))
  allegro_base->text = (append1 allegro_base->text (list 2 "END"))
  allegro_base->text = (append1 allegro_base->text (list 1 "END"))

  ;MODULE_NAME: ChaosUtils
  (setq allegro_ChaosUtils (make_ZMenuItem))
  allegro_ChaosUtils->name = "allegro_ChaosUtils"
  allegro_ChaosUtils->file = "allegro.men"
  allegro_ChaosUtils->kids = nil
  allegro_ChaosUtils->text = nil
  allegro_base->kids = (cons allegro_ChaosUtils allegro_base->kids)
  allegro_ChaosUtils->text = (append1 allegro_ChaosUtils->text (list 2 "POPUP \"Chaos &Utils\""))
  allegro_ChaosUtils->text = (append1 allegro_ChaosUtils->text (list 2 "BEGIN"))
  allegro_ChaosUtils->text = (append1 allegro_ChaosUtils->text (list 3 "MENUITEM \"Debug Skill utils\", \"chaosutils_DebugSkill\""))
  allegro_ChaosUtils->text = (append1 allegro_ChaosUtils->text (list 2 "END"))

  ;MODULE_NAME: Extractxsection
  (setq allegro_Extractxsection (make_ZMenuItem))
  allegro_Extractxsection->name = "allegro_Extractxsection"
  allegro_Extractxsection->file = "allegro.men"
  allegro_Extractxsection->kids = nil
  allegro_Extractxsection->text = nil
  allegro_base->kids = (cons allegro_Extractxsection allegro_base->kids)
  allegro_Extractxsection->text = (append1 allegro_Extractxsection->text (list 2 "MENUITEM \"&ExtractXSection\", \"xs\""))

  ;MODULE_NAME: NetworkCollections
  (setq allegro_NetworkCollections (make_ZMenuItem))
  allegro_NetworkCollections->name = "allegro_NetworkCollections"
  allegro_NetworkCollections->file = "allegro.men"
  allegro_NetworkCollections->kids = nil
  allegro_NetworkCollections->text = nil
  allegro_base->kids = (cons allegro_NetworkCollections allegro_base->kids)
  allegro_NetworkCollections->text = (append1 allegro_NetworkCollections->text (list 2 "POPUP \"&NetworkCollections\""))
  allegro_NetworkCollections->text = (append1 allegro_NetworkCollections->text (list 2 "BEGIN"))
  allegro_NetworkCollections->text = (append1 allegro_NetworkCollections->text (list 3 "MENUITEM \"&Grid system\", \"grid_system\""))
  allegro_NetworkCollections->text = (append1 allegro_NetworkCollections->text (list 3 "MENUITEM \"Grid set&env\", \"grid_setenv\""))
  allegro_NetworkCollections->text = (append1 allegro_NetworkCollections->text (list 3 "MENUITEM \"Create Thermal Flash\", \"mkth\""))
  allegro_NetworkCollections->text = (append1 allegro_NetworkCollections->text (list 3 "MENUITEM \"Auto Cross section\", \"auto crossection\""))
  allegro_NetworkCollections->text = (append1 allegro_NetworkCollections->text (list 3 "MENUITEM \"Artwork Setup\", \"artwork setup\""))
  allegro_NetworkCollections->text = (append1 allegro_NetworkCollections->text (list 3 "MENUITEM \"Locate All Refdes\", \"ch_refdeslocate\""))
  allegro_NetworkCollections->text = (append1 allegro_NetworkCollections->text (list 3 "MENUITEM \"Rotate All Refdes\", \"ch_ref\""))
  allegro_NetworkCollections->text = (append1 allegro_NetworkCollections->text (list 3 "MENUITEM \"Rotate Skip Right\", \"ch_refskip\""))
  allegro_NetworkCollections->text = (append1 allegro_NetworkCollections->text (list 3 "MENUITEM \"Add ICT Testpoint\", \"add ict\""))
  allegro_NetworkCollections->text = (append1 allegro_NetworkCollections->text (list 3 "MENUITEM \"Add Layer List\", \"layer list\""))
  allegro_NetworkCollections->text = (append1 allegro_NetworkCollections->text (list 3 "MENUITEM \"Constraint Input System\", \"lgs_tech_in\""))
  allegro_NetworkCollections->text = (append1 allegro_NetworkCollections->text (list 3 "MENUITEM \"pdiVisibility\", \"visibility\""))
  allegro_NetworkCollections->text = (append1 allegro_NetworkCollections->text (list 2 "END"))

  ;MODULE_NAME: alignsymbol
  (setq allegro_alignsymbol (make_ZMenuItem))
  allegro_alignsymbol->name = "allegro_alignsymbol"
  allegro_alignsymbol->file = "allegro.men"
  allegro_alignsymbol->kids = nil
  allegro_alignsymbol->text = nil
  allegro_base->kids = (cons allegro_alignsymbol allegro_base->kids)
  allegro_alignsymbol->text = (append1 allegro_alignsymbol->text (list 2 "MENUITEM \"&Align Symbol Simple\", \"alignsymbol\""))
  allegro_alignsymbol->text = (append1 allegro_alignsymbol->text (list 2 "MENUITEM \"&Align Symbol\", \"align\""))

  ;MODULE_NAME: logomaker
  (setq allegro_logomaker (make_ZMenuItem))
  allegro_logomaker->name = "allegro_logomaker"
  allegro_logomaker->file = "allegro.men"
  allegro_logomaker->kids = nil
  allegro_logomaker->text = nil
  allegro_base->kids = (cons allegro_logomaker allegro_base->kids)
  allegro_logomaker->text = (append1 allegro_logomaker->text (list 2 "MENUITEM \"&LogoMakerLEDTOOLS\", \"logomaker_lt\""))
  allegro_logomaker->text = (append1 allegro_logomaker->text (list 2 "MENUITEM \"&LogoMakerImageMagick\", \"logomaker_im\""))

  ;MODULE_NAME: destub
  (setq allegro_destub (make_ZMenuItem))
  allegro_destub->name = "allegro_destub"
  allegro_destub->file = "allegro.men"
  allegro_destub->kids = nil
  allegro_destub->text = nil
  allegro_base->kids = (cons allegro_destub allegro_base->kids)
  allegro_destub->text = (append1 allegro_destub->text (list 2 "MENUITEM \"&Destubifier\", \"DT_destub_main\""))

  ;MODULE_NAME: deliver
  (setq allegro_deliver (make_ZMenuItem))
  allegro_deliver->name = "allegro_deliver"
  allegro_deliver->file = "allegro.men"
  allegro_deliver->kids = nil
  allegro_deliver->text = nil
  allegro_base->kids = (cons allegro_deliver allegro_base->kids)
  allegro_deliver->text = (append1 allegro_deliver->text (list 2 "MENUITEM \"&Deliver\", \"DT_deliver_main\""))

  ;MODULE_NAME: memmon
  (setq allegro_memmon (make_ZMenuItem))
  allegro_memmon->name = "allegro_memmon"
  allegro_memmon->file = "allegro.men"
  allegro_memmon->kids = nil
  allegro_memmon->text = nil
  allegro_base->kids = (cons allegro_memmon allegro_base->kids)
  allegro_memmon->text = (append1 allegro_memmon->text (list 2 "MENUITEM \"&MemMon\", \"DT_memmon_main\""))

  ;MODULE_NAME: rotator
  (setq allegro_rotator (make_ZMenuItem))
  allegro_rotator->name = "allegro_rotator"
  allegro_rotator->file = "allegro.men"
  allegro_rotator->kids = nil
  allegro_rotator->text = nil
  allegro_base->kids = (cons allegro_rotator allegro_base->kids)
  allegro_rotator->text = (append1 allegro_rotator->text (list 2 "MENUITEM \"&Rotator\", \"DT_rotator_main\""))

));end LET_and_PROCEDURE

(DT_install_menu)

