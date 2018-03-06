;; Sandbox for CHICK.
;; -*- geiser-scheme-implementation: chicken -*-

(require-extension sandbox fmt)

(define (sexp str)
  (call-with-input-string str read))

(define sbox-env
  (make-safe-environment parent: default-safe-environment))

(define-constant sbox-fuel 1000)
(define-constant sbox-alim 100)

(defcmd ">"
  (lambda (reply arg who)
    (handle-exceptions exn
        (reply (format ";; exception: ~A"
                       (if (condition? exn)
                           ((condition-property-accessor 'exn 'message) exn)
                           exn)))
      (reply
       (fmt #f (let ([res (safe-eval (sexp arg)
                                     environment: sbox-env
                                     fuel: sbox-fuel
                                     allocation-limit: sbox-alim)])
                 (if (string? res)
                     (wrt res)
                     res)))))))
