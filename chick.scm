;; Chick: IRC bot in Chicken.
;; -*- geiser-scheme-implementation: chicken -*-

(use inclub)
(inclub "sirc")
(import sirc)
(require-extension matchable srfi-13 data-structures fmt)

(define conn
  (sirc:connection "irc.esper.net" nick: "CHICK"))

(define (test _)
  (sirc:say conn "#V" "test lol"))

(sirc:connect conn)

;; display a message nicely.
(define (fmthost host)
  (car (string-split (string-trim host #\:) "!")))
(define (fmtmsg parsed)
  (match parsed
    [(from "PRIVMSG" to msg) (printf "~A -> ~A: ~A\n" (fmthost from) to msg)]
    [(from "NOTICE" to msg) (printf "Notice ~A -> ~A: ~A\n" (fmthost from) to msg)]
    [(who "JOIN" chan) (printf "~A joined ~A\n" (fmthost who) chan)]
    [(who "PART" chan) (printf "~A left ~A\n" (fmthost who) chan)]
    [(who "PART" chan msg) (printf "~A left ~A: ~A\n" (fmthost who) chan msg)]
    [(who "MODE" whom mode) (printf "~A sets mode ~A ~A\n" (fmthost who) mode whom)]

    [(_ "332" _ chan topic) (printf "Topic of ~A: ~A\n" chan topic)]
    [(_ "333" _ chan who ts) (printf "Topic of ~A set by ~A\n" chan (fmthost who))] ;; todo: parse timestamp

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

;; main loop
(define (mainloop)
  (let ([parsed (sirc:receive conn)])
    (fmtmsg parsed)
    (match parsed
      [(#f "PING" msg) (sirc:send conn "PONG :~A" msg)]
      [(_ "376" _ _) (sirc:join conn "#V")]
      [_ '()]))
  (mainloop))

(mainloop)

(sirc:disconnect conn "Goodbye.")
