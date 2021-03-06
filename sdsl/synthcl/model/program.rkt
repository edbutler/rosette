#lang s-exp rosette

(require (for-syntax (only-in rosette/lib/util/syntax read-module)
                     (only-in racket filter-map))
         "context.rkt")

(provide clCreateProgramWithSource program? program-context program-kernels)

; An OpenCL program consists of a set of kernels that are 
; identified as functions declared with the kernel qualifier 
; in the program source. Each program instance is associated with 
; an OpenCL context.  Once the kernels are loaded, the program is 
; implicitly compiled and built in our model.  The kernels field of 
; each program instance holds a list of pairs, where the first element 
; of each pair is the name of the kernel (given as a string), and the 
; second element is the kernel procedure with that name.
(struct program (context kernels)
  #:guard (lambda (context kernels name)
            (unless (context? context)
              (raise-argument-error 'clCreateProgramWithSource "context" context))
            (values context kernels))
  #:methods gen:custom-write
  [(define (write-proc self port mode) 
     (fprintf port "#<program:~a>" (map car (program-kernels self))))])

; Creates a program object for the context, and loads the kernels
; from the file identified by the provided string literal.  The source 
; code specified by the file must be a module in the OpenCL DSL.  For 
; the full interface, see Ch. 5.6.1 of opencl-1.2 specification.
(define-syntax-rule (clCreateProgramWithSource context filename)
  (program context (load-kernel-procedures filename)))

(define-syntax (load-kernel-procedures stx)
  (syntax-case stx ()
    [(_ filename)
     (with-syntax ([(id ...) (map syntax-local-introduce (parse-kernel-identifiers #'filename))])
       (quasisyntax/loc stx 
         (let ()
           (local-require filename)
           (list (cons (~a (quote id)) id) ...))))]))

(define-for-syntax (parse-kernel-identifiers path)
  (define source (read-module (syntax->datum path)))
  (syntax-case source ()
    [(mod id lang (mod-begin forms ...))
     (filter-map (lambda (form)
                   (syntax-case form ()
                     [(kernel _ (id _ ...) _ ...) 
                      (and (identifier? #'kernel) (eq? 'kernel (syntax->datum #'kernel))) 
                      #'id]
                     [_ #f]))
                 (syntax->list #'(forms ...)))]
    [_ (raise-syntax-error #f "expected a full path to a kernel module" path)]))
