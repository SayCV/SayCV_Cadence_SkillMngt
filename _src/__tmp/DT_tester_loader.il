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

(procedure (DT_tester_loader)
(let ()

; (load "C:/src/DesignTools-src/__tmp/DT_init.il")
; (load "C:/src/DesignTools-src/__tmp/DT_make_context.il")
  
  (axlSetVariable "designtools" "C:/src/DesignTools-src")
  (setq DTG_CONF_USER (strcat (getShellEnvVar "HOME") "/.DesignTools"))
  
  (load "C:/src/DesignTools-src/base/lib/_DTL_DEBUG.il")
  (load "C:/src/DesignTools-src/base/lib/_DTL_UTILS.il")
  (load "C:/src/DesignTools-src/base/lib/_DTL_UIGUI.il")
  (load "C:/src/DesignTools-src/base/lib/_DTL_PARTS.il")

;  (load "C:/src/DesignTools-src/base/lib/_DTL_UTILS.il")

;  (load "C:/src/DesignTools-src/__tmp/DT_scope.il")
;  (DT_scope_main)

;  (load "C:/src/DesignTools-src/base/cfg/DT_config.il")
;  (DT_config_main)

;  (load "C:/src/DesignTools-src/deliver/src/DT_deliver.il")
;  (DT_deliver_main)

  (load "C:/src/DesignTools-src/rotator/src/DT_rotator.il")
  (DT_rotator_main)

;  (load "C:/src/DesignTools-src/destub/src/DT_destub.il")
;  (DT_destub_main)

;  (load "C:/src/DesignTools-src/memmon/src/DT_memmon.il")
;  (DT_memmon_main)

))
;
;(DT_tester_loader)