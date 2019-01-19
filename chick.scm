;; Chick: IRC bot in Chicken.
;; -*- geiser-scheme-implementation: chicken -*-

(include "sirc")
(import sirc)
(import matchable srfi-13 fmt srfi-69 regex srfi-18 format)
(import (chicken string)
        (chicken io)
        (chicken format))
(define conn
  (sirc:connection "irc.esper.net" nick: "CHICK"))

;; display a message nicely.
(define (fmthost host)
  (car (string-split (string-trim host #\:) "!")))
(define (fmtmsg parsed)
  (match parsed
    [(from "PRIVMSG" to msg) (printf "[~A] ~A: ~A\n" to (fmthost from) msg)]
    [(from "NOTICE" to msg) (printf "[~A] Notice from ~A: ~A\n" to (fmthost from) msg)]
    [(who "JOIN" chan) (printf "[~A] ~A joined\n" chan (fmthost who))]
    [(who "PART" chan) (printf "[~A] ~A left\n" chan (fmthost who))]
    [(who "PART" chan msg) (printf "[~A] ~A left: ~A\n" chan (fmthost who) msg)]
    [(who "QUIT" reason) (printf "~A quit: ~A\n" who reason)]
    [(who "MODE" whom mode) (printf "~A sets umode ~A ~A\n" (fmthost who) mode whom)]
    [(who "MODE" chan whom mode) (printf "[~A] ~A sets mode ~A ~A\n" chan (fmthost who) mode whom)]

    [(_ "332" _ chan topic) (printf "Topic of ~A: ~A\n" chan topic)]
    [(_ "333" _ chan who ts) (printf "Topic of ~A set by ~A\n" chan (fmthost who))] ;; todo: parse timestamp
    [(who "TOPIC" chan topic) (printf "[~A] ~A changed topic to: ~A\n" chan (fmthost who) topic)]

    [(_ "353" _ _ chan names) (printf "Names of ~A: ~A\n" chan names)] ;; todo: format and order
    [(_ "366" _ ...) '()]

    ;; welcome messages
    [(from "001" _ msg) (printf "~A: ~A\n" (fmthost from) msg)]
    [(from "002" _ msg) (printf "~A: ~A\n" (fmthost from) msg)]
    [(from "003" _ msg) (printf "~A: ~A\n" (fmthost from) msg)]
    [(from "004" _ msg) (printf "~A: ~A\n" (fmthost from) msg)]
    [(from "250" _ msg) (printf "~A: ~A\n" (fmthost from) msg)]
    [(from "251" _ msg) (printf "~A: ~A\n" (fmthost from) msg)]
    [(from "252" _ opers _) (printf "~A: ~A opers online.\n" (fmthost from) opers)]
    [(from "254" _ chancount _) (printf "~A: ~A channels formed.\n" (fmthost from) chancount)]
    [(from "255" _ msg) (printf "~A: ~A\n" (fmthost from) msg)]
    [(from "372" _ msg) (printf "~A MOTD: ~A\n" (fmthost from) msg)] ;; motd content
    [(_ "375" _ _) '()] ;; motd start
    [(_ "376" _ _) '()] ;; motd end
    [(_ "004" _ ...) '()] ;; version info
    [(_ "005" _ ...) '()] ;; features
    [(_ "265" _ ...) '()] ;; local users
    [(_ "266" _ ...) '()] ;; global users

    [(_ "PING" _) '()]

    [_ (fmt #t "Unknown message: " parsed nl) ]))

;; hooks
(define hooks (make-hash-table))
(define (add-hook type proc) ;; adds to the proc list
  (hash-table-set!
   hooks type
   (cons proc (hash-table-ref/default hooks type '()))))

(define (call-hook type . args)
  (if (hash-table-exists? hooks type)
      (let ([fn
             (lambda (self cmds)
               (if (not (eq? cmds '()))
                   (begin
                     (thread-start! ; green threading, yay!
                      (make-thread
                       (lambda () (apply (car cmds) args))))
                     (self self (cdr cmds)))))])
        (fn fn (hash-table-ref hooks type)))))


;; parse commands
(define-constant cmdprefix ";")

(define commands (make-hash-table string=?))
(define cmdregex (regexp "^([^ ]+) *(.*)$"))
(define (parsecmd cmd reply who)
  (let ([parsed (string-match cmdregex cmd)])
    (if parsed
        (let ([command (cadr parsed)]
              [args (cadr (cdr parsed))])
          (if (hash-table-exists? commands command)
              ((hash-table-ref commands command) reply args who)
              (reply (format "No such command: ~A" command)))))))

(add-hook 'msg
          (lambda (from to msg)
            (if (string-prefix? cmdprefix msg)
                (parsecmd
                 (string-drop msg (string-length cmdprefix))
                 (lambda (txt)
                   (printf "Reply to ~A: ~A\n" to txt)
                   (sirc:msg conn (if (string-prefix? "#" to) to (fmthost from)) txt))
                 (fmthost from)))))

;; command definitions
(define (defcmd name proc)
  (hash-table-set! commands name proc))

(include "cmds/basic")
(include "cmds/sandbox")

;; main loop
(define (mainloop)
  (let ([parsed (sirc:receive conn)])
    (fmtmsg parsed)
    (match parsed
      [(#f "PING" msg) (sirc:send conn "PONG :~A" msg)]
      [(_ "376" _ _) (sirc:join conn "#V")]
      [(who "PRIVMSG" to msg) (call-hook 'msg who to msg)]
      [(who "JOIN" chan) (call-hook 'join who chan)]
      [(who "PART" chan) (call-hook 'part who chan)]
      [(who "PART" chan msg) (call-hook 'part who chan msg)]
      [(who "MODE" chan whom mode) (call-hook 'cmode chan who whom mode)] ;; note the order
      [(who "QUIT" reason) (call-hook 'quit who reason)]
      [_ '()]))
  (mainloop))

;; entry point
(sirc:connect conn)
(mainloop)
(sirc:disconnect conn "Goodbye.")
