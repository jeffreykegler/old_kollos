#ifndef GENERICLOGGER_LOG_H
#define GENERICLOGGER_LOG_H

#include "marpaWrapper_Export.h"

typedef enum genericLoggerLevel {
  GENERICLOGGER_LOGLEVEL_TRACE = 0,
  GENERICLOGGER_LOGLEVEL_DEBUG,
  GENERICLOGGER_LOGLEVEL_INFO,
  GENERICLOGGER_LOGLEVEL_NOTICE,
  GENERICLOGGER_LOGLEVEL_WARNING,
  GENERICLOGGER_LOGLEVEL_ERROR,
  GENERICLOGGER_LOGLEVEL_CRITICAL,
  GENERICLOGGER_LOGLEVEL_ALERT,
  GENERICLOGGER_LOGLEVEL_EMERGENCY
} genericLoggerLevel_t;

/*************************
   Opaque object pointer
 *************************/
typedef struct genericLogger genericLogger_t;

typedef void (*genericLoggerCallback_t)(const void *userDatavp, const genericLoggerLevel_t logLeveli, const char *msgs);

/*************************
   Options
**************************/
typedef struct genericLoggerOption {
  genericLoggerCallback_t logCallbackp;         /* Default: NULL                           */
  void                   *userDatavp;           /* Default: NULL                           */
  genericLoggerLevel_t    leveli;               /* Default: GENERICLOGGER_LOGLEVEL_WARNING */
} genericLoggerOption_t;

MARPAWRAPPER_EXPORT genericLoggerOption_t  *genericLoggerOption_newp();
MARPAWRAPPER_EXPORT void                    genericLoggerOption_defaultv(genericLoggerOption_t *genericLoggerOptionp);
MARPAWRAPPER_EXPORT void                    genericLoggerOption_destroyv(genericLoggerOption_t *genericLoggerp);

MARPAWRAPPER_EXPORT genericLoggerCallback_t genericLogger_defaultLogCallback(void);
/* For applications that want to initialize a structure outside of executable blocks: */
MARPAWRAPPER_EXPORT void                   _genericLogger_defaultCallback(const void *userDatavp, const genericLoggerLevel_t logLeveli, const char *msgs);

MARPAWRAPPER_EXPORT genericLoggerLevel_t    genericLogger_logLevel_seti(genericLogger_t *genericLoggerp, genericLoggerLevel_t logLeveli);
MARPAWRAPPER_EXPORT genericLoggerLevel_t    genericLogger_logLevel_geti(const genericLogger_t *genericLoggerp);

MARPAWRAPPER_EXPORT genericLogger_t        *genericLogger_newp(const genericLoggerOption_t *genericLoggerOptionp);
MARPAWRAPPER_EXPORT void                    genericLogger_defaultv(genericLoggerOption_t *genericLoggerOptionp);
MARPAWRAPPER_EXPORT void                    genericLogger_destroyv(genericLogger_t *genericLoggerp);
MARPAWRAPPER_EXPORT genericLoggerOption_t   genericLogger_genericLoggerOption_get(genericLogger_t *genericLoggerp);

/* C99 has problems with empty __VA_ARGS__ so we split macros in two categories: */
/* logging with no variable parameter */
/* logging with    variable paramerer(s) */

MARPAWRAPPER_EXPORT void genericLogger_log(const genericLogger_t *genericLoggerp, const genericLoggerLevel_t genericLoggerLeveli, const char *fmts, ...);

#define GENERICLOGGER_LOG0(logLeveli, msgs)      genericLogger_log(genericLoggerp, logLeveli, msgs)
#define GENERICLOGGER_LOGX(logLeveli, fmts, ...) genericLogger_log(genericLoggerp, logLeveli, fmts, __VA_ARGS__)

#ifndef GENERICLOGGER_NTRACE
#define GENERICLOGGER_TRACE0(fmts)               GENERICLOGGER_LOG0(GENERICLOGGER_LOGLEVEL_TRACE, fmts)
#define GENERICLOGGER_TRACEX(fmts, ...)          GENERICLOGGER_LOGX(GENERICLOGGER_LOGLEVEL_TRACE, fmts, __VA_ARGS__)
#else
#define GENERICLOGGER_TRACE0(fmts)
#define GENERICLOGGER_TRACEX(fmts, ...)
#endif

#define GENERICLOGGER_DEBUG0(fmts)               GENERICLOGGER_LOG0(GENERICLOGGER_LOGLEVEL_DEBUG, fmts)
#define GENERICLOGGER_DEBUGX(fmts, ...)          GENERICLOGGER_LOGX(GENERICLOGGER_LOGLEVEL_DEBUG, fmts, __VA_ARGS__)

#define GENERICLOGGER_INFO0(fmts)                GENERICLOGGER_LOG0(GENERICLOGGER_LOGLEVEL_INFO, fmts)
#define GENERICLOGGER_INFOX(fmts, ...)           GENERICLOGGER_LOGX(GENERICLOGGER_LOGLEVEL_INFO, fmts, __VA_ARGS__)

#define GENERICLOGGER_NOTICE0(fmts)              GENERICLOGGER_LOG0(GENERICLOGGER_LOGLEVEL_NOTICE, fmts)
#define GENERICLOGGER_NOTICEX(fmts, ...)         GENERICLOGGER_LOGX(GENERICLOGGER_LOGLEVEL_NOTICE, fmts, __VA_ARGS__)

#define GENERICLOGGER_WARNING0(fmts)             GENERICLOGGER_LOG0(GENERICLOGGER_LOGLEVEL_WARNING, fmts)
#define GENERICLOGGER_WARNINGX(fmts, ...)        GENERICLOGGER_LOGX(GENERICLOGGER_LOGLEVEL_WARNING, fmts, __VA_ARGS__)

#define GENERICLOGGER_ERROR0(fmts)               GENERICLOGGER_LOG0(GENERICLOGGER_LOGLEVEL_ERROR, fmts)
#define GENERICLOGGER_ERRORX(fmts, ...)          GENERICLOGGER_LOGX(GENERICLOGGER_LOGLEVEL_ERROR, fmts, __VA_ARGS__)

#define GENERICLOGGER_CRITICAL0(fmts)            GENERICLOGGER_LOG0(GENERICLOGGER_LOGLEVEL_CRITICAL, fmts)
#define GENERICLOGGER_CRITICALX(fmts, ...)       GENERICLOGGER_LOGX(GENERICLOGGER_LOGLEVEL_CRITICAL, fmts, __VA_ARGS__)

#define GENERICLOGGER_ALERT0(fmts)               GENERICLOGGER_LOG0(GENERICLOGGER_LOGLEVEL_ALERT, fmts)
#define GENERICLOGGER_ALERTX(fmts, ...)          GENERICLOGGER_LOGX(GENERICLOGGER_LOGLEVEL_ALERT, fmts, __VA_ARGS__)

#define GENERICLOGGER_EMERGENCY0(fmts)           GENERICLOGGER_LOG0(GENERICLOGGER_LOGLEVEL_EMERGENCY, fmts)
#define GENERICLOGGER_EMERGENCYX(fmts, ...)      GENERICLOGGER_LOGX(GENERICLOGGER_LOGLEVEL_EMERGENCY, fmts, __VA_ARGS__)

#endif /* GENERICLOGGER_LOG_H */
