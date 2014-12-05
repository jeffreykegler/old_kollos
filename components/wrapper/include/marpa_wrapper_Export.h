
#ifndef MARPAWRAPPER_EXPORT_H
#define MARPAWRAPPER_EXPORT_H

#ifdef MARPAWRAPPER_STATIC
#  define MARPAWRAPPER_EXPORT
#  define MARPAWRAPPER_NO_EXPORT
#else
#  ifndef MARPAWRAPPER_EXPORT
#    ifdef marpaWrapper_EXPORTS
        /* We are building this library */
#      define MARPAWRAPPER_EXPORT __attribute__((visibility("default")))
#    else
        /* We are using this library */
#      define MARPAWRAPPER_EXPORT __attribute__((visibility("default")))
#    endif
#  endif

#  ifndef MARPAWRAPPER_NO_EXPORT
#    define MARPAWRAPPER_NO_EXPORT __attribute__((visibility("hidden")))
#  endif
#endif

#ifndef MARPAWRAPPER_DEPRECATED
#  define MARPAWRAPPER_DEPRECATED __attribute__ ((__deprecated__))
#endif

#ifndef MARPAWRAPPER_DEPRECATED_EXPORT
#  define MARPAWRAPPER_DEPRECATED_EXPORT MARPAWRAPPER_EXPORT MARPAWRAPPER_DEPRECATED
#endif

#ifndef MARPAWRAPPER_DEPRECATED_NO_EXPORT
#  define MARPAWRAPPER_DEPRECATED_NO_EXPORT MARPAWRAPPER_NO_EXPORT MARPAWRAPPER_DEPRECATED
#endif

#define DEFINE_NO_DEPRECATED 1
#if DEFINE_NO_DEPRECATED
# define MARPAWRAPPER_NO_DEPRECATED
#endif

#endif
