;; Chick: IRC bot in Chicken.
;; -*- geiser-scheme-implementation: chicken -*-

(use inclub)
(inclub "sirc")
(import sirc)
(require-extension matchable)

(define conn
  (sirc:connection "irc.esper.net" nick: "CHICK"))

(define (test _)
  (sirc:say conn "#V" "test lol"))

(sirc:connect conn)

(sirc:join conn "#V")

;; todo: loop over messages
(define (mainloop)
  (let ([parsed (sirc:recieve conn)])
    (print parsed)
    (match parsed
      [(#f "PING" msg) (sirc:send conn "PONG :~A" msg)]
      [(from "PRIVMSG" to msg) (printf "~A wrote to ~A: ~A" from to msg)]
      [(from "NOTICE" to msg) (printf "Notice ~A to ~A: ~A" from to msg)]))
  (mainloop))

(mainloop)

(sirc:disconnect conn "Goodbye.")
