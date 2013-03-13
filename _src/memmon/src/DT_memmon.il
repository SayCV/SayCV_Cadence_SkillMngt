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

;_______________________________________________________________________________
;-------------------------------------------------------------------------------
; Markings:
;   __FIXME__   -Stuff that needs to be fixed
;   __NOFIX__   -Things that are bad but are not fixable
;   __HACKS__   -Sad hacks and work arounds
;-------------------------------------------------------------------------------

;_______________________________________________________________________________
;-------------------------------------------------------------------------------
; ToDo
; remove form and log files
; better port test/close
;-------------------------------------------------------------------------------
;  Undocumented / Internal Functions
;    _axlUIWTimerAdd
;    _axlUIWTimerRemove

/*
In general, I prefer not to bind/assign symbols at the start of a (let *) in
SKILL mode. It just makes things look more convoluted than doing the binding
later through (setq *) and it allows simple switching to (prog *) and back.


This small, trivial program is really quite interesting and involved. As always,
it is best to not go stuffing tons of of accessible symbols into the top-level;
in other words, avoiding globabbly accessible stuff that can get over-written.

Using something like:
  
  (foreach namedvar (listVariables ".") (printf "%s\n" namedvar))

allows you to see what symbols variables have "escaped" into the environment.

Dealing with callbacks can be a pain when you need to access variable symbols
which need to be globally accessible and, of course, you don't want any globally
accessible variable symbols. The best way to handle this that I've found is to
use property lists attached to a function/procedure symbol.

There are some strange and unusal syntax forms in which SKILL/SKILL++ allows 
you to read and write properties.

  the (get SymName PropName) and (putprop SynName Value PropName) syntax
  the "SymName.PropName" syntax
  the "SymName->PropName" syntax 
  
  The latter "->" syntax is the main way to deal with structs

--------------------------------------------------------------------------------
Registered callbacks are another interesting and convoluted area in the way they
handle variable symbol scope. For example, on a form callback the single argument
it takes when registered is not the same FORM object as the one it is given. 

In other words, if you have a globally accessible FORM symbol returned from the 
(axlFormCreate ..) procedure, the form callback can not use it. Instead, the
callback MUST use symbol given as it's argument.

--------------------------------------------------------------------------------
; The "telskill" allegro variable gives you a nice place to play with SKILL
; set telskill

;FIXME -sooner or later this should be rewritten to use a config file  

*/

(axlCmdRegister "DT_memmon_main", "DT_memmon_main")

;*******************************************************************************
; the main() procedure is basically a loader of sorts which sets up the form,
; and activates the form and timer and exit/cleanup callbacks.
(procedure (DT_memmon_main)
(prog (
    DTP                           ; DT Procedure Name
    DTD                           ; DT Debug print switch
    DTOP_log                      ; Output Port for log
    DTOB_FORM                     ; Form Object Handle
    LogsFileName 
    FormFileName
    TimerID                       ; timer handle
    TimeVal                       ; counter for seconds
    TimeInt                       ; update every "x" seconds
    MemLimit                      ; start up memory limit in MB
    MemWarn                       ; percent of limit warning
    MemUsed                       ; memory currently in use
  ) ;end local bindings

; Since this is a non-blocking program, we can not use rexExitBefore/After
;  (regExitBefore 'DT_memmon_cleanup)

  (unless (and
      (setfdoc 'DT_memmon_main "DesignTools: Memory Monitor program launcher.")
      (setq DTP "(DT_memmon_main)")
      (setq TimeVal  0)           ; counter for seconds
      (setq TimeInt  10)          ; time interval - update every "x" seconds
      (setq MemLimit 1024)        ; start up memory limit in MB
      (setq MemWarn  80)          ; percent of limit warning
      (setq MemUsed  0)           ; memory currently in use
      (setq LogsFileName (strcat (getWorkingDir) "/DT_memmon.log"))
      (setq FormFileName (strcat (getWorkingDir) "/DT_memmon.form"))
      (rexCompile "\\\\")
      (setq LogsFileName (rexReplace LogsFileName "/" 0))
      (setq FormFileName (rexReplace FormFileName "/" 0))
    )
    (printf "\n\nERROR: (DT_memmon_main) - Could Not Set Variable Symbols\n\n")
    (go EndProg))

  (setq DTD nil)
  (when DTD
    (printf "\nSTATUS: %s \n" DTP)
    (printf "LogsFileName: %L\nFormFileName: %L\n" LogsFileName FormFileName))

  ; save the FQN file names so we can delete them
  (putprop 'DT_memmon_main LogsFileName "LogsFileName")
  (putprop 'DT_memmon_main FormFileName "FormFileName")

  ; open logging file
  (unless (setq DTOP_log (outfile LogsFileName "w"))
    (printf "\n\nERROR: %s - Can Not Open Log Output File!\n" DTP)
    (go EndProg))
  (when DTD (printf "DTOP_log: %L\n" (get_filename DTOP_log)))
  (putprop 'DT_memmon_main DTOP_log "DTOP_log")

  ; create non-blocking form
  (if (setq DTOB_FORM (DT_memmon_form_create FormFileName)) 
  then
    (when DTD (printf "DTOB_FORM: %L\n" DTOB_FORM))
;    (axlFormColorize DTOB_FORM "TxtTime0" 'background 'blue)
;    (axlFormColorize DTOB_FORM "TxtTime1" 'background 'blue)
;    (axlFormColorize DTOB_FORM "TxtTime0" 'text 'white)
;    (axlFormColorize DTOB_FORM "TxtTime1" 'text 'white)
;    (axlFormColorize DTOB_FORM "TxtMemory0" 'background 'white)
;    (axlFormColorize DTOB_FORM "TxtMemory1" 'background 'white)
;    (axlFormColorize DTOB_FORM "TxtWarn0" 'background 'blue)
;    (axlFormColorize DTOB_FORM "TxtWarn1" 'background 'blue)
    (axlFormSetField DTOB_FORM "TxtTime1" (sprintf nil "%6d" {TimeVal / 60}))
    (axlFormSetField DTOB_FORM "TxtMemory1" (sprintf nil "%6d" {(axlMemSize) / 1048576}))
    (axlFormSetField DTOB_FORM "TxtWarn1" (sprintf nil "%6d" MemWarn))
    (axlFormSetField DTOB_FORM "MemLimit" MemLimit)
    (axlFormSetFieldLimits DTOB_FORM "MemLimit" 1 MemLimit)
    (axlFormDefaultButton   DTOB_FORM "OpResetButton")
    (axlFormSetActiveField  DTOB_FORM "OpResetButton")
    (axlFormDisplay DTOB_FORM)
    (axlUIWExpose DTOB_FORM)
  else
    (printf "\nERROR: %s Could not create form!\n" DTP)
;    (exit)
    (return (DT_memmon_cleanup))
  )
  (putprop 'DT_memmon_main DTOB_FORM     "DTOB_FORM")

;NOFIX
  ; create a timer and register the timer callback
  ; On some versions of Allegro, Cadence failed to bind/export the needed
  ; (axlUIWTimerAdd ...) function. Luckily, the "internal" function is still
  ; available via it's underscore name.
  (if (procedurep (getd 'axlUIWTimerAdd))
  then
    (unless (setq TimerID 
        (axlUIWTimerAdd nil {TimeInt * 1000} nil 'DT_memmon_timer_cb))
      (printf "\nERROR: %s - axlUIWTimerAdd - Could not set the timer!\n" DTP))
  else
    (if (procedurep (getd '_axlUIWTimerAdd))
    then
      (unless (setq TimerID 
          (_axlUIWTimerAdd nil {TimeInt * 1000} nil 'DT_memmon_timer_cb))
        (printf "\nERROR: %s - _axlUIWTimerAdd - Could not set the timer!\n" DTP))
    else
      (printf "\nERROR: %s - missing TimerAdd function - Could not set the timer!\n" DTP)))
      
      
  ; save the important stuff into the property list of the function symbol
  (putprop 'DT_memmon_main TimeVal  "TimeVal")
  (putprop 'DT_memmon_main TimeInt  "TimeInt")
  (putprop 'DT_memmon_main MemLimit "MemLimit")
  (putprop 'DT_memmon_main MemWarn  "MemWarn") 
  (putprop 'DT_memmon_main MemUsed  "MemUsed")
  (putprop 'DT_memmon_main TimerID  "TimerID")
  
  ; Everything should be set up and running so we return 
  (return t)

EndProg
  ; flush and close files
  (when (and (boundp 'DTOP_log) (openportp DTOP_log))
    (unless (and (drain DTOP_log) (close DTOP_log) (setq DTOP_log 'unbound))
      (printf "\nERROR: %s - Flush/Close failed DTOP_log\n" DTP)))
));END_PROG_&_PROCEDURE (DT_memmon_main)


;********************************************************************************
; This is the form callback procedure.
; We use the log file handle which was attached as a property to the _maim
; procedure.
(procedure (DT_memmon_form_cb Arg_DTOB_FORM "g")
(prog (
    DTP   ;DT Procedure Name
    DTD   ;DT Debug print switch
  ) ;end local bindings
  (setq DTD nil)
  (setq DTP "(DT_memmon_form_cb)")
  (when DTD (printf "\nSTATUS: %s \n" DTP))
  ; somebody hit the "X" to close the window
  (unless (equal Arg_DTOB_FORM->doneState 0)
    (when DTD (fprintf (get 'DT_memmon_main "DTOP_log") 
        "\n\nSTATUS: %s - Form not in \"done\" state.\n\n" DTP))
    (return (DT_memmon_cleanup)))
  ; debug printing
  (when DTD (fprintf (get 'DT_memmon_main 
      "DTOP_log") "\n\nSTATUS: %s - Arg_DTOB_FORM->?? BASE" DTP))
  (when DTD (printf "%L\n" Arg_DTOB_FORM->??))
  (when DTD (_DTL_UTILS_PrintProp (get 'DT_memmon_main "DTOP_log") Arg_DTOB_FORM))

  ; The big case...
  (case Arg_DTOB_FORM->curField
    ("MemLimit"
      (when DTD (fprintf (get 'DT_memmon_main "DTOP_log") 
          "\nSTATUS: %s - Arg_DTOB_FORM->curField == \"MemLimit\"\n" DTP))
      (putprop 'DT_memmon_main (fix Arg_DTOB_FORM->curValueInt) "MemLimit")
    )
    ("OpResetButton"
      (when DTD (fprintf (get 'DT_memmon_main "DTOP_log") 
          "\nSTATUS: %s - Arg_DTOB_FORM->curField == \"OpResetButton\"\n" DTP))
      (putprop 'DT_memmon_main (axlFormGetField Arg_DTOB_FORM "MemLimit") "MemLimit")
      (putprop 'DT_memmon_main 0 "TimeVal")
    )
    ("OpCloseButton"
      (when DTD (fprintf (get 'DT_memmon_main "DTOP_log") 
          "\nSTATUS: %s - Arg_DTOB_FORM->curField == \"OpCloseButton\"\n" DTP))
      (return (DT_memmon_cleanup))))
));END_PROG_&_PROCEDURE (DT_memmon_form_cb)
  

  
;*******************************************************************************
; You can't pass normal arguments to a timer callback, so the method suggested 
; in the "axlUIWTimerAdd.txt" documentaiton is to add properties to the TimerID.
;
; As you might expect, the suggested method sucks mainly because any properties
; you attach are probably going to be needed elsewhere and there's no simple
; way to access them.
;
;
(procedure (DT_memmon_timer_cb Arg_Window Arg_TimerID Arg_ElapsedTime "ggg")
(let (
    DTP                           ; DT Procedure Name
    DTD                           ; DT Debug print switch
    PercentUsed                   ; percent of memory currently used
  ) ;end local bindings
  (setq DTP "(DT_memmon_timer_cb)")
  (setq DTD nil)
  (when DTD (printf "\nSTATUS: %s \n" DTP))

  (setq PercentUsed (fix (times (quotient 
      (float (get 'DT_memmon_main "MemUsed"))
      (float (get 'DT_memmon_main "MemLimit"))) 100)))

  (putprop 'DT_memmon_main (fix (quotient (axlMemSize) 1048576)) "MemUsed")
  (putprop 'DT_memmon_main 
      (axlFormGetField (get 'DT_memmon_main "DTOB_FORM") "MemLimit") "MemLimit")

  (if (greaterp PercentUsed (get 'DT_memmon_main "MemWarn"))
  then
    (when DTD (printf "OVER_MemUsed..: %d\n" (get 'DT_memmon_main "MemUsed")))
    (when DTD (printf "OVER_MemLimitB: %d\n" (get 'DT_memmon_main "MemLimit")))
    (when DTD (printf "OVER_PercUsedC: %d\n\n" PercentUsed ))
    (axlUIConfirm (sprintf nil 
        "You are above %d percent\nof allowed memory use.\nUsed: %d percent" 
        (get 'DT_memmon_main "MemWarn") PercentUsed))
  else
    (when DTD (printf "UNDER_MemUsed..: %d\n" (get 'DT_memmon_main "MemUsed")))
    (when DTD (printf "UNDER_MemLimitB: %d\n" (get 'DT_memmon_main "MemLimit")))
    (when DTD (printf "UNDER_PercUsedC: %d\n\n" PercentUsed )))

  (when DTD 
    (fprintf (get 'DT_memmon_main "DTOP_log") "\n%24d    %24d" 
        (get 'DT_memmon_main "TimeVal") (axlMemSize))
    (drain (get 'DT_memmon_main "DTOP_log")))
  
  (unless (and 
      (putprop 'DT_memmon_main 
          (plus (get 'DT_memmon_main "TimeVal") (get 'DT_memmon_main "TimeInt"))
          "TimeVal")
      (axlFormSetField (get 'DT_memmon_main "DTOB_FORM") "TxtTime1" 
          (sprintf nil "%6d" (xquotient (get 'DT_memmon_main "TimeVal") 60)))
      (axlFormSetField (get 'DT_memmon_main "DTOB_FORM") "TxtMemory1" 
          (sprintf nil "%6d" (xquotient (axlMemSize) 1048576))))
    (DT_memmon_cleanup))
));END_LET_&_PROCEDURE (DT_memmon_timer_cb)

;*******************************************************************************
;
(procedure (DT_memmon_form_create ArgFormFileName "t")
(prog (
    DTP                           ;DT Procedure Name
    DTD                           ;DT Debug print switch
    DTOP_form                     ; output port for writing the form file
    DTOB_FORM                     ; Form Object
    FormPathName                  ; FQN for the form file
  ) ;end local bindings
  (setq DTP "(DT_memmon_form_create)")
  (setq DTD nil)
  (when DTD (printf "\nSTATUS: %s \n" DTP))
  (unless (setq DTOP_form (outfile ArgFormFileName "w")) ; open form file handle
    (printf "\nERROR: %s - Can Not Open Form Output File!\n" DTP)
    (return nil))
  (unless (and ; write out form file contents
    (fprintf DTOP_form "FILE_TYPE=FORM_DEFN VERSION=2\n")
    (fprintf DTOP_form "FORM FIXED_FONT\n")
    (fprintf DTOP_form "FIXED\n")
    (fprintf DTOP_form "PORT 15 7\n")
    (fprintf DTOP_form "HEADER \"DesignTools: MemMon\"\n")
    (fprintf DTOP_form "DEFAULT \"OpCloseButton\"\n")
    (fprintf DTOP_form "\n")
    ;begin tile
    (fprintf DTOP_form "TILE\n")
    (fprintf DTOP_form "\n")
    ;time display
    (fprintf DTOP_form "TEXT \"Time:\" TxtTime0\n")
    (fprintf DTOP_form "FLOC 0 0\n")
    (fprintf DTOP_form "FSIZE 5 2\n")
    (fprintf DTOP_form "ENDTEXT\n")
    (fprintf DTOP_form "\n")
    (fprintf DTOP_form "TEXT \"0\" TxtTime1\n")
    (fprintf DTOP_form "FLOC 6 0\n")
    (fprintf DTOP_form "FSIZE 6 2\n")
    (fprintf DTOP_form "ENDTEXT\n")
    (fprintf DTOP_form "\n")
    (fprintf DTOP_form "TEXT \"min\" TxtTime2\n")
    (fprintf DTOP_form "FLOC 13 0\n")
    (fprintf DTOP_form "FSIZE 4 2\n")
    (fprintf DTOP_form "ENDTEXT\n")
    (fprintf DTOP_form "\n")
    ;used memory display
    (fprintf DTOP_form "TEXT \"Used:\" TxtMemory0\n")
    (fprintf DTOP_form "FLOC 0 1\n")
    (fprintf DTOP_form "FSIZE 5 2\n")
    (fprintf DTOP_form "ENDTEXT\n")
    (fprintf DTOP_form "\n")
    (fprintf DTOP_form "TEXT \"0\" TxtMemory1\n")
    (fprintf DTOP_form "FLOC 6 1\n")
    (fprintf DTOP_form "FSIZE 7 2\n")
    (fprintf DTOP_form "ENDTEXT\n")
    (fprintf DTOP_form "\n")
    (fprintf DTOP_form "TEXT \"MB\" TxtMemory2\n")
    (fprintf DTOP_form "FLOC 13 1\n")
    (fprintf DTOP_form "FSIZE 3 2\n")
    (fprintf DTOP_form "ENDTEXT\n")
    (fprintf DTOP_form "\n")
    ;warn percent display
    (fprintf DTOP_form "TEXT \"Warn:\" TxtWarn0\n")
    (fprintf DTOP_form "FLOC 0 2\n")
    (fprintf DTOP_form "FSIZE 5 2\n")
    (fprintf DTOP_form "ENDTEXT\n")
    (fprintf DTOP_form "\n")
    (fprintf DTOP_form "TEXT \"0\" TxtWarn1\n")
    (fprintf DTOP_form "FLOC 6 2\n")
    (fprintf DTOP_form "FSIZE 7 2\n")
    (fprintf DTOP_form "ENDTEXT\n")
    (fprintf DTOP_form "\n")
    (setq tmpstr "%")
    (fprintf DTOP_form "TEXT \"%s\" TxtWarn2\n" tmpstr)
    (fprintf DTOP_form "FLOC 13 2\n")
    (fprintf DTOP_form "FSIZE 3 2\n")
    (fprintf DTOP_form "ENDTEXT\n")
    (fprintf DTOP_form "\n")

    ;user mem limit
    (fprintf DTOP_form "TEXT \"System:\" MemLimit0\n")
    (fprintf DTOP_form "FLOC 0 4\n")
    (fprintf DTOP_form "FSIZE 7 2\n")
    (fprintf DTOP_form "ENDTEXT\n")
    (fprintf DTOP_form "\n")
    (fprintf DTOP_form "FIELD MemLimit\n")
    (fprintf DTOP_form "FLOC 7 4\n")
    (fprintf DTOP_form "LONGFILLIN 4 6\n")
    (fprintf DTOP_form "VALUE 0\n")
    (fprintf DTOP_form "ENDFIELD\n")
    (fprintf DTOP_form "\n")
    (fprintf DTOP_form "TEXT \"MB\" MemLimit1\n")
    (fprintf DTOP_form "FLOC 13 4\n")
    (fprintf DTOP_form "FSIZE 3 2\n")
    (fprintf DTOP_form "ENDTEXT\n")
    (fprintf DTOP_form "\n")
    ;reset button
    (fprintf DTOP_form "FIELD OpResetButton\n")
    (fprintf DTOP_form "FLOC 0 6\n")
    (fprintf DTOP_form "MENUBUTTON \"Reset\" 7 3\n")
    (fprintf DTOP_form "ENDFIELD\n")
    (fprintf DTOP_form "\n")
    ;close button
    (fprintf DTOP_form "FIELD OpCloseButton\n")
    (fprintf DTOP_form "FLOC 8 6\n")
    (fprintf DTOP_form "MENUBUTTON \"Close\" 7 3\n")
    (fprintf DTOP_form "ENDFIELD\n")
    (fprintf DTOP_form "\n")
    ;end tile and form
    (fprintf DTOP_form "ENDTILE\n")
    (fprintf DTOP_form "\n")
    (fprintf DTOP_form "ENDFORM\n")
  )
    (fprintf DTOP_log "\nERROR: %s - Failed On Form File Writing\n" DTP)
    (return nil)
  )
;  ;get form file name
;  (setq FormFileName (get_filename DTOP_form))
;  (printf "FormPathName: %L\n" FormFileName)

  (if (and (boundp 'DTOP_form) (openportp DTOP_form))
  then
    (unless (and (drain DTOP_form) (close DTOP_form))
      (printf "\nERROR: %s - File close failed on Form File\n" DTP))
  else
    (printf "\nERROR: %s - Form File port unbound or port not open\n" DTP))
  (setq DTOP_form 'unbound)
  
  ;non-blocking / stand-alone
  (return (axlFormCreate (gensym) ArgFormFileName 
      '( "msglines" 0 "E" "inner" "NoBorder") 'DT_memmon_form_cb t))

));END_LET_&_PROCEDURE (DT_memmon_form_create)


;*******************************************************************************
; This is just a cleanup procedure to kill the timer and close the form.
; It is used as a the registered exit (regExitBefore) callback, so there's no
; way to pass arguments to it. We get around this problem, once again, by
; previously adding properties to the function symbol (DT_memmon_cleanup).
(procedure (DT_memmon_cleanup)
(let (
    DTP                           ;DT Procedure Name
    DTD                           ;DT Debug print switch
  ) ;end local bindings
  (setq DTP "(DT_memmon_cleanup)")
  (setq DTD nil)
  (when DTD (printf "\nSTATUS: %s \n" DTP))

;NOFIX
  ; On some versions of Allegro, Cadence failed to bind/export the needed
  ; (axlUIWTimerRemove ...) function. Luckily, the "internal" function is still
  ; available via it's underscore name.
  (if (get 'DT_memmon_main "TimerID")
  then
    (if (procedurep (getd 'axlUIWTimerRemove))
    then
      (unless (axlUIWTimerRemove (get 'DT_memmon_main "TimerID"))
        (printf "\nERROR: %s - axlUIWTimerRemoved - Could not remove the timer!\n" DTP))
    else
      (if (procedurep (getd '_axlUIWTimerRemove))
      then
        (unless (_axlUIWTimerRemove (get 'DT_memmon_main "TimerID"))
          (printf "\nERROR: %s - _axlUIWTimerRemove - Could not remove the timer!\n" DTP))
      else
        (printf "\nERROR: %s - missing TimerRemove function - Could not remove the timer!\n" DTP)))
  else
    (printf "\nERROR: %s -  Failed to kill timer\n" DTP))
    
  (if (get 'DT_memmon_main "DTOB_FORM")
  then 
    (axlFormClose (get 'DT_memmon_main "DTOB_FORM"))
  else
    (printf "\nERROR: %s -  Failed to close form\n" DTP))

  (if (and 
      (get 'DT_memmon_main "DTOP_log")
      (openportp (get 'DT_memmon_main "DTOP_log")))
  then
    (drain (get 'DT_memmon_main "DTOP_log"))
    (close (get 'DT_memmon_main "DTOP_log"))
  else
    (printf "\nERROR: %s - Flush/Close failed DTOP_log\n" DTP))
  
  ; wipe the property list
  (setplist 'DT_memmon_main nil)

;
;  ;remove function bindings from toplevel symbols
;  (defun DT_memmon_form_cb     () 'unbound)
;  (defun DT_memmon_timer_cb    () 'unbound)
;  (defun DT_memmon_form_create () 'unbound)
;  (defun DT_memmon_cleanup     () 'unbound)
;
;  ;remove function bindings from toplevel symbols
;  (putd 'DT_memmon_form_cb     'nil)
;  (putd 'DT_memmon_timer_cb    'nil)
;  (putd 'DT_memmon_form_create 'nil)
;  (putd 'DT_memmon_cleanup     'nil)


));END_LED_and_PROCEDURE (DT_memmon_cleanup)
