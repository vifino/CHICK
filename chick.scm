;; Chick: IRC bot in Chicken.
;; -*- geiser-scheme-implementation: chicken -*-

(use inclub)
(inclub "sirc")
(import sirc)

(define conn
  (sirc:connection "irc.esper.net" nick: "CHICK"))

(define (test _)
  (sirc:say conn "#V" "test lol"))

(sirc:connect conn)

(sirc:join conn "#V")

;; todo: loop over messages

(sirc:quit conn "Goodbye.")
