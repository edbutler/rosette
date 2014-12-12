#lang racket

(require racket/runtime-path "smt.rkt" "../common/server.rkt")

(provide z3%)

(define-runtime-path z3 (build-path ".." ".." ".." "bin" "z3.exe"))

(define z3%
  (class* smt% (writable<%>) (inspect (make-inspector))

    (super-new [path z3] 
               [opts '("-smt2" "-in")])
    
    (define/public (custom-write port) (fprintf port "z3%"))
    (define/public (custom-display port) (custom-write port))))
