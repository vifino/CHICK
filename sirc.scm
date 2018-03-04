;; simple irc module
;; lots stolen from the irc chicken egg
;; -*- geiser-scheme-implementation: chicken -*-

(module sirc (sirc:connect sirc:connected? irc:disconnect
                           sirc:send sirc:receive
                           sirc:connection-in sirc:connection-out sirc:connection-server sirc:connection-port
                           sirc:connection-nick sirc:connection-user sirc:connection-real sirc:connection? sirc:connection
                           sirc:connection-channels
                           sirc:join sirc:part
                           sirc:nick)
  (import scheme chicken)
  (use tcp srfi-1 data-structures regex srfi-13 posix)


  (define-record sirc:connection
    server ; string
    port ; int
    nick ; string
    user ; string
    real ; string
    connected? ; bool
    in ; port
    out ; port
    channels ; (string ...)
    )

  (define sirc:connected? sirc:connection-connected?)

  (define (sirc:connection server #!key (nick (gensym)) (user "chicken") (real "clucking schemer") (port 6667))
    (make-sirc:connection
     server port
     nick user real
     #f #f #f
     '()))

  (define (send con fmt . args)
    (let ((str (apply sprintf fstr args)))
      (unless (sirc:connected? con)
        (error "not connected" con))
      (fprintf (sirc:connection-out con) "~A\r\n" str)
      str))

  (define sirc:send send)

  (define (sirc:connect con)
    (let-values
        ([(i o) (tcp-connect (sirc:connection-server con) (sirc:connection-port con))])
      (sirc:connection-in-set! con i)
      (sirc:connection-out-set! con o)
      (sirc:connection-connected?-set! con #t)

      (send con "NICK ~A" (sirc:connection-nick con))
      (send con "USER ~A 0 * :~A" (sirc:connection-user con) (sirc:connection-real con))
      con))

  (define (sirc:disconnect con msg)
    (send con "QUIT :~A" msg)
    (close-output-port (sirc:connection-out con))
    (close-input-port (sirc:connection-in con))
    (sirc:connection-connected?-set! con #f)
    (sirc:connection-in-set! con #f)
    (sirc:connection-out-set! con #f))

  (define (sirc:join con chan)
    (let ((chans (lset-adjoin string=? (sirc:connection-channels con) chan)))
      (sirc:connection-channels-set! con chans)
      (send con "JOIN ~A" chan)))

  (define (sirc:part con chan)
    (sirc:connection-channels-set! con
                                   (delete chan (sirc:connection-channels con) string=?))
    (send con "PART ~A" chan))

  (define (sirc:nick con nick)
    (sirc:connection-nick-set! con nick)
    (send con "NICK ~A" nick))

  ;; input logic
  (define (readline con)
    (read-line (sirc:connection-in con)))
  (define-constant ircregex (regexp "^([A-Z]+) ([\\w# ]+)?(:.*)?$"))
  (define (sirc:recv con)
    (let ((parsed (string-match ircregex (readline con))))
      (if parsed
          (cons (second parsed) ; the command
                (append (if (third parsed)
                            (string-split (third parsed)) ; split the args by space
                            '())
                        (if (fourth parsed)
                            (cons (string-drop (fourth parsed) 1) '()) ; the aftermath
                            '())))
          (error "couldn't parse irc line"))))

  )
