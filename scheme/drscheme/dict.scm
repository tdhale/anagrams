#lang scheme

(require "bag.scm"
         "ports.scm"
         (lib "pretty.ss")
         (lib "process.ss")
         srfi/13)
(provide init *dictionary*)

(define *big-ol-hash-table* #f)

(define (wordlist->hash fn)
  (with-input-from-file fn
    (lambda ()
      (let ((dict (make-hash)))
        (fprintf status-port  "Reading dictionary ... ")
        (let loop ((word  (read-line))
                   (words-read 0))
          (if (eof-object? word)
              (fprintf status-port  "Reading dictionary ... done.")
              (begin
                (when (word-acceptable? word)
                  (adjoin-word dict (string-downcase word)))
                (when (zero? (remainder words-read 1000))
                  (fprintf status-port  (format "Reading dictionary ... ~a words ..." words-read)))
                (loop (read-line)
                      (+ 1 words-read)))
              ))
        dict)
      )))

(define *dictionary* #f)

(define (adjoin-word dict word)
  (let* ((this-bag (bag word))
         (probe (hash-ref dict this-bag (lambda () #f))))
    (cond
     ((not probe)
      (hash-set! dict this-bag  (list word)))
     ((not (member word probe))
      (hash-set! dict this-bag (cons word probe)))
     )))

(define word-acceptable?
  (let ((has-vowel-regexp (regexp "[aeiouyAEIOUY]"))
        (has-non-ASCII-regexp (regexp "[^a-zA-Z]"   )))
    (lambda (word)
      (let ((l (string-length word)))
        (and (not (zero? l))

             ;; it's gotta have a vowel.
             (regexp-match has-vowel-regexp word)

             ;; it's gotta be all ASCII, all the time.
             (not (regexp-match has-non-ASCII-regexp word))

             ;; it's gotta be two letters long, unless it's `i' or `a'.
             (or (string=? "i" word)
                 (string=? "a" word)
                 (< 1 l)))))))


(define (bag-acceptable? this bag-to-meet)
  (and (or (bags=? bag-to-meet this)
           (subtract-bags bag-to-meet this))
       this))

(define (init bag-to-meet dict-file-name)
  (when (not *big-ol-hash-table*)
    (set! *big-ol-hash-table* (wordlist->hash dict-file-name)))

  (fprintf status-port "Pruning dictionary ... ") (flush-output)

  (set! *dictionary*
        (let ((entries-examined 0))
          (let ((result (filter (lambda (entry)
                                  (when (zero? (remainder entries-examined 1000))
                                    (fprintf status-port
                                             (format "Pruning dictionary ... ~a words ..." entries-examined)))
                                  (set! entries-examined (+ 1 entries-examined))
                                  (bag-acceptable? (car entry) bag-to-meet))
                                       (hash-map *big-ol-hash-table* cons))))
            result)))
  (fprintf status-port "Pruning dictionary ... done.")

  (let ()
    (define (biggest-first e1 e2)
      (let* ((s1 (cadr e1))
             (s2 (cadr e2))
             (l1 (string-length s1))
             (l2 (string-length s2)))
        (or (> l1 l2)
            (and (= l1 l2)
                 (string<? s1 s2)))))
    (define (shuffled seq)
      (let ((with-random-numbers (map (lambda (item)
                                        (cons (random 2147483647)
                                              item))
                                      seq)
                                 ))
        (set! with-random-numbers (sort with-random-numbers (lambda (a b)
                                                              (< (car a)
                                                                 (car b)))))
        (map cdr with-random-numbers)))

    (set! *dictionary*
          (if #t
              (sort *dictionary* biggest-first)
              (shuffled *dictionary*))
          )))
