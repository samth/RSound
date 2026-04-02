#lang racket

;; this file compiles the buffer-add.c file (it's ten lines long).
;; Instead of a makefile, it just calls gcc twice; once to compile,
;; once to link.

;; why make a makefile? Why not just do the compilation?

;; 2026-03-31 : sigh... because I want it to run inside a container. Ouch.

;; abstraction is weak here...

(define archs '(x86_64 i386 aarch64))

;; don't try this with a name containing spaces...
(define (find-exec name)
  (unless (regexp-match #px"^[a-zA-Z0-9]+$" name)
    (error 'find-exec
           "this string might not parse as a single word in the shell: ~v\n"
           name))
  (define outstr
    (string-trim (with-output-to-string
                   (λ () (system (string-append "which "name))))))
  (when (equal? outstr "")
    (error 'find-exec
           "couldn't find ~v using `which ~v`"
           name name))
  (unless (file-exists? outstr)
    (error 'find-exec
           "command `which ~v` didn't print the path of an existing file"
           name))
  outstr)

(define gcc-path (find-exec "gcc"))

;; the name of the c file we're compiling:
(define stem "buffer-add")

;; the subdirectory used for a given arch and platform
(define (arch-dir arch platform)
  (~a arch "-" platform))

(define (arch-flag arch platform)
  (match arch
    ['x86_64 (match platform
               ['macosx
                "x86_64"]
               ['linux
                "x86-64"])]
    ['i386 (match platform
             ['macosx "i386"]
             ['linux (error "not sure what march flag to use for i686")])]
    ['aarch64 (match platform
                ['macosx
                 "arm64"])]))

;; the flags to use for a given arch & platform
(define (flags arch platform)
  (match platform
    ['macosx
     (list "-arch" (arch-flag arch platform) "-mmacosx-version-min=10.5")]
    ['linux
     (list (string-append "-march=" (arch-flag arch platform)))]))

;; the dylib suffix on the given platform
(define (dylib-suffix platform)
  (match platform
    ['macosx "dylib"]
    ['linux "so"]))

;; the gcc flag for generating a dylib on the given platform
(define (dylib-flag platform)
  (match platform
    ['macosx  "-dynamiclib"]
    ['linux "-shared"]))

;; call gcc (but first print out the args). Halt if an error occurs
(define (call-gcc args)
  (printf "~v\n" (cons "gcc" args))
  (unless (apply system* gcc-path args)
    (error 'call-gcc "error occurred in gcc invocation")))

;; the arch/platform target directory
(define (arch-platform-dir arch platform)
  (build-path 'up (arch-dir arch platform)))

(define (temp-dylib-target arch platform)
  (define tgt-path (arch-platform-dir arch platform))
  (define (suffix->path suffix)
    (path->string (build-path tgt-path (string-append stem "." suffix))))
  (suffix->path (dylib-suffix platform)))

(define (final-dylib-dir arch platform 3m-cs-dir)
  (build-path (arch-platform-dir arch platform) 3m-cs-dir))

;; given 
(define (build-args arch platform)
  (define tgt-path (arch-platform-dir arch platform))
  (define (suffix->path suffix)
    (path->string (build-path tgt-path (string-append stem "." suffix))))

  ;; compile
  (define compile-args
    (append (list "-c" "-o" (suffix->path "o"))
            (flags arch platform)
            (list (string-append stem ".c"))))
  ;; link
  (define link-args
    (append  (list "-o" (temp-dylib-target arch platform)
                   (dylib-flag platform))
             (flags arch platform)
             (list (suffix->path "o"))))
  (list compile-args link-args))

;; compile the shared library for the given platforms, except for
;; the specified architectures
(define (make platform disable-these-archs)
  (for*/list ([arch (in-list archs)]
              #:when (not (member arch disable-these-archs)))
    (define build-argses (build-args arch platform))
    (for ([build-args build-argses])
      (call-gcc build-args))
    
    ;; copy the dylibs into the 3m and cs directories
    (for/list ([cs-3m-dir '("3m" "cs")])
      (copy-file (temp-dylib-target arch platform)
                 (build-path (final-dylib-dir arch platform cs-3m-dir)
                             (string-append stem "." (dylib-suffix platform)))))
    (delete-file (temp-dylib-target arch platform))))


;(make 'macosx '(i386))
;(make 'linux '(i386))
