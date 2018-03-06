;; Basic commands for CHICK.
;; -*- geiser-scheme-implementation: chicken -*-

(defcmd "echo"
  (lambda (reply arg who)
    (reply arg)))

(defcmd "whoami"
  (lambda (reply _ who)
    (reply who)))
