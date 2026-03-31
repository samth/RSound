#lang racket

;; WIP, let's use existing racket build infrastructure to
;; recompile portaudio for windows?

;; working on recompiling the buffer-copy dll now. Trying first
;; with macosx.

;; using pre-build docker images, not sure that's the best idea but...
;; docker pull racket/distro-build:crosswin
;; docker pull racket/distro-build:osxcross-aarch64

(require remote-shell/docker)

(define name "portaudio-osx-aarch64-build")
#;(define name "portaudio-win-build")

;; create the container
(define (create)
  (docker-create #:name name
                 #:image-name "racket/distro-build:crosswin"))

;; start the container
(define (start)
  (docker-start #:name name))

(define portaudio-src-bundle "pa_stable_v190700_20210406.tgz")

;; I happen to have it in /tmp/right now. This is all totally WIP:
#;(docker-copy #:name name
             #:src (build-path "/tmp" portaudio-src-bundle)
             #:dest (string-append name ":"
                                   (path->string
                                    (build-path "/home/racket"
                                                portaudio-src-bundle))))

;; did this interactively, use docker-exec in future?
;; tar xvzf pa-stable...
;; cd portaudio
;; mkdir my-build # build already exists...
;; cd my-build
;; ../configure --host=x86_64-w64-mingw32 --with-winapi=wasapi
;; make

;; .. I'm guessing I'll need headers? for wasapi or directx?

(define result-dll-name "libportaudio-2.dll")

#;(docker-copy #:name name
             #:src (string-append
                    name ":"
                    "/home/racket/portaudio/my-build/lib/.libs/"
                    result-dll-name)
             #:dest (build-path "/tmp" result-dll-name))

#;(docker-stop #:name name)
