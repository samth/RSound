This directory exists because rsound needs a very small shared library
in order to copy data into a portaudio buffer. It contains a shared library
file for all of the supported platforms. The `compile-libs` directory
contains files useful in recompiling this shared library. As of 2026-03-31,
I'm trying to update that DLL for windows, using the newer docker build
mechanisms. 
