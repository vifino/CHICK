;; simple irc module
;; lots stolen from the irc chicken egg
;; -*- geiser-scheme-implementation: chicken -*-

[module sirc (sirc:connect sirc:connected? sirc:disconnect
                           sirc:send sirc:receive
                           sirc:connection-in sirc:connection-out sirc:connection-server sirc:connection-port
                           sirc:connection-nick sirc:connection-user sirc:connection-real sirc:connection? sirc:connection
                           sirc:connection-channels
                           sirc:join sirc:part sirc:nick
                           sirc:msg sirc:notice
                           sirc:send-ctcp sirc:action)
  (import scheme chicken)
  (use tcp srfi-1 data-structures regex srfi-13 extras posix)


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
    (let ([str (apply sprintf fmt args)])
      (unless (sirc:connected? con)
        (error "not connected" con))
      (fprintf (sirc:connection-out con) "~A\r\n" str)
      str))

  (define sirc:send send)

  ;; basic connection management
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

  ;; input logic
  (define (readline con)
    (parameterize ([tcp-read-timeout #f])
      (read-line (sirc:connection-in con))))
  (define-constant ircregex (regexp "^(:[^ ]*)? ?(\\w+) ([^:]+)?(:.*)?$"))
  (define (sirc:receive con)
    (let ([parsed (string-match ircregex (readline con))])
      (if parsed
          (cons (second parsed) ; the <optional> prefix
                (cons (third parsed) ; the command
                (append (if (fourth parsed)
                            (string-split (fourth parsed)) ; split the args by space
                            '())
                        (if (fifth parsed)
                            (cons (string-drop (fifth parsed) 1) '()) ; the aftermath
                            '()))))
          (error "couldn't parse irc line"))))

  ;; session management
  (define (sirc:join con chan)
    (let ([chans (lset-adjoin string=? (sirc:connection-channels con) chan)])
      (sirc:connection-channels-set! con chans)
      (send con "JOIN ~A" chan)))

  (define (sirc:part con chan)
    (sirc:connection-channels-set! con (delete chan (sirc:connection-channels con) string=?))
    (send con "PART ~A" chan))

  (define (sirc:nick con nick)
    (sirc:connection-nick-set! con nick)
    (send con "NICK ~A" nick))

  ;; handy aliases to make things easier
  (define (sirc:msg con to msg)
    (send con "PRIVMSG ~A :~A" to msg))

  (define (sirc:notice con to msg)
    (send con "NOTICE ~A :~A" to msg))

  (define (sirc:send-ctcp con to type . data)
    (sirc:msg con to (format "\x01~A\x01"
                             (if (pair? data)
                                 (format "~A ~A" type (car data))
                                 type))))
  (define (sirc:action con to msg)
    (sirc:send-ctcp con to "ACTION" msg))

  ]
