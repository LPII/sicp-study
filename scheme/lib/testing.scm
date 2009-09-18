;;; Very minimalistic testing framework for simple scheme programs.

;;; List of all recorded tests.
(define *tests* ())

;;; Assertion procedure to use.
;;;
;;; Outside of a test, an error is reported.  This is overridden
;;; inside a test so that the remaining tests can continue.
(define *fail-test* (lambda (args) (error "assertion-failed" args)))

;;; Assertion messages -----------------------------------------------

(define (expected-message expected actual)
  (with-output-to-string
    (lambda ()
      (write-string "Expected: <")
      (display expected)
      (write-string "> but got <")
      (display actual)
      (write-string ">"))))

(define (not-expected-message expected actual)
  (with-output-to-string
    (lambda ()
      (write-string "Expected: <")
      (display expected)
      (write-string "> to not equal <")
      (display actual)
      (write-string ">"))))

(define (delta-message expected actual delta)
  (with-output-to-string
    (lambda ()
      (write-string "Expected the delta of <")
      (display expected)
      (write-string "> and <")
      (display actual)
      (write-string "> to be less than <")
      (display delta)
      (write-string "> but was <")
      (display (abs (- expected actual)))
      (write-string ">"))))

(define (not-delta-message expected actual delta)
  (with-output-to-string
    (lambda ()
      (write-string "Expected the delta of <")
      (display expected)
      (write-string "> and <")
      (display actual)
      (write-string "> to be greater than <")
      (display delta)
      (write-string "> but was <")
      (display (abs (- expected actual)))
      (write-string ">"))))

;;; Available Assertions ---------------------------------------------

(define (assert-with procedure message)
  (if (not (procedure))
      (*fail-test*  message)
      'test-ok))

(define (assert-equal expected actual)
  (assert-with (lambda () (equal? expected actual))
               (expected-message expected actual)) )

(define (assert-not-equal expected actual)
  (assert-with (lambda () (not (equal? expected actual)))
               (not-expected-message expected actual)) )

(define (assert-eq expected actual)
  (assert-with (lambda () (eq? expected actual))
               (expected-message expected actual)))

(define (assert-not-eq expected actual)
  (assert-with (lambda () (not (eq? expected actual)))
               (not-expected-message expected actual)))

(define (assert-in-delta expected actual delta)
  (assert-with (lambda () (< (abs (- actual expected)) delta))
               (delta-message expected actual delta)))

(define (assert-not-in-delta expected actual delta)
  (assert-with (lambda () (>= (abs (- actual expected)) delta))
               (not-delta-message expected actual delta)))

;;; Running Tests ----------------------------------------------------

;; Run a single named test.
(define (run-a-test test-name test-code)
  (call-with-current-continuation
   (lambda (cc)
     (fluid-let ((*fail-test*
                  (lambda (msg) (cc (list 'fail test-name msg)))))
       (test-code)
       (list 'pass test-name)))))

;; Run all the recorded tests.  Return a list of test results.
(define (run-tests)
  (define (run-remaining-tests al test-results)
    (if (null? al)
        test-results
        (run-remaining-tests (cdr al)
                             (cons (run-a-test (caar al) (cadar al))
                                   test-results))))
  (run-remaining-tests *tests* ()))

;; Report the results of a test run.
(define (report-tests test-results)
  (define (show-one-failure failure)
    (write-string "Test '")
    (write-string (cadr failure))
    (write-string "' failed: ")
    (write-string (caddr failure))
    (write-string "\n\n"))

  (define (show-failures failures)
    (cond ((null? failures) ())
          (else (show-one-failure (car failures))
                (show-failures (cdr failures)))))

  (define (show-test-results passing failing failures)
    (show-failures failures)
    (display passing)
    (write-string " passing tests, ")
    (display failing)
    (write-string " failing tests.\n")
    'done)

  (define (report-remaining-tests test-results passing failing failures)
    (cond ((null? test-results) (show-test-results passing failing failures))
          ((eq? (caar test-results) 'pass)
           (report-remaining-tests (cdr test-results) (+ 1 passing) failing failures))
          (else
           (report-remaining-tests (cdr test-results)
                                   passing
                                   (+ 1 failing)
                                   (cons (car test-results) failures)))))

  (report-remaining-tests test-results 0 0 ()))

;;; Defining tests ---------------------------------------------------

(define (record-test test-name procedure)
  (set! *tests* (cons (list test-name procedure) *tests*))  )

(define-syntax test-case
  (syntax-rules ()
    ((test-case name . code) (record-test name (lambda () . code)))))

;;; User Facing Code -------------------------------------------------

(define (tests)
  (report-tests (run-tests)))

(define (clear-tests)
  (set! *tests* ())
  'ok)

'done