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


/*
This was supposed to be an example of how to create an interal function that 
cannot be called from anywhere but it's originating program/procedure.

Unfortunately, it doesn't work. Using (putd...) with (lambda...) is just like 
using (procedure...) or (defun...) -the result is your your function symbol is
globally available.

The only possible way I know of to accomplish this is to use SKILL++ (Scheme) 
and use a "named let" -but this hasn't been tested so the result may be  just
like SKILL.

*/

(procedure (DT_scope_main)
(prog 
  ( ;start local symbol bindings
    DTN                           ; DT Procedure Name
    DTD                           ; DT Debug Switch
    DT_scope_internal            ; internal function name
    ; ...
  ) ;end local symbol bindings
  (unless 
    (and
      (setq DTN "(DT_scope_main)")
      ; ...
    )
    (printf "\n\nERROR: (DT_scope_main) - Could Not Set Variable Symbols\n\n")
    (go EndProg))
  ;set debug mode
  (setq DTD t)
  (when DTD (printf "\nSTATUS: %s \n" DTN))

  ; create an named internal function
  (putd 'DT_scope_internal '(lambda (DT_X DT_Y "xx")
      (let 
        ( ;start local symbol bindings
          DTN
        ) ;end local symbol bindings
        ;program body
        (setq DTN "(DT_scope_internal)")
        (printf "Internal DTN: %L\n" DTN))))
  
  ;execute the internal funciton
  (DT_scope_internal 9 8)
  ;=> This DTN.: "(DT_scope_internal)"
  
  ;execute a normal statement
  (printf "Main DTN....: %L\n" DTN)
  ;=> Main DTN.: "(DT_scope_main)"

;  ; This would throw an error since DT_X is not defined in the top-level
;  (printf "Main DT_X: %L\n" DT_X)

  (return  t)
;    make_
; go label
EndProg
  (return  nil)

)) ;end_prog_&_procedure: DT_scope_main


