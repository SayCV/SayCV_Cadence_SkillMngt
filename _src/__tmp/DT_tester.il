;*******************************************************************************
;
; Copyright (c) J.C. Roberts 2005 - All Rights Reserved
;
; NO PART OF THIS FILE MAY BE REPRODUCED, STORED IN A RETRIEVAL SYSTEM,
; OR TRANSMITTED IN ANY FORM OR BY ANY MEANS, INCLUDING ELECTRONIC, MECHANICAL,
; PHOTOCOPYING, RECORDING, OR OTHERWISE, WITHOUT PRIOR WRITTEN PERMISSION
; OF THE COPYRIGHT HOLDER, J.C. ROBERTS
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

;_______________________________________________________________________________
;*******************************************************************************
;-------------------------------------------------------------------------------
; Markings:
;   __FIXME__   -Stuff that needs to be fixed
;   __NOFIX__   -Things that are bad but are not fixable
;   __HACKS__   -Sad hacks and work arounds
;-------------------------------------------------------------------------------

axlCmdRegister("DT_tester_main", "DT_tester_main")

;********************************************************************************
;PROCEDURE: A simple loader/reloader for executing code / debugging
;
(procedure (DT_tester_main)
(let ()
  (load "C:/src/DesignTools-src/__tmp/DT_tester_loader.il")
  (DT_tester_loader)
))