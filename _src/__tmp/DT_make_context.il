(defun DT_make_context ()
  (let ()
    (setContext "DT_test")
    (load "C:/src/DesignTools-src/base/lib/_DTL_UTILS.il")
    (load "C:/src/DesignTools-src/deliver/src/DT_deliver.il")
    (load "C:/src/DesignTools-src/__tmp/DT_init.il")
;    DT_deliver_main.autoload = "E:/work/board/DT_test.cxt"
;    (axlCmdRegister "DT_deliver_main", "DT_deliver_main")
    (defInitProc "DT_test" 'DT_init)
    (saveContext "DT_test.cxt")))

(DT_make_context)