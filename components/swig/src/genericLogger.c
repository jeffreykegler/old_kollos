#include "marpa_wrapper_config.h"

#ifdef HAVE_SYS_TYPES_H
#include <sys/types.h>
#endif
#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <stdio.h>
#include <stdarg.h>
#include <stddef.h>               /*  size_t definition */
#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif
#ifdef HAVE_IO_H
#include <io.h>
#endif

#include "messageBuilder.h"
#include "dateBuilder.h"
#include "genericLogger.h"

static const char *GENERICLOGGER_LOG_NO_MESSAGE = "No message";

struct genericLogger {
  genericLoggerOption_t genericLoggerOption;
};

/*****************************************/
/* genericLogger_genericLoggerOption_get */
/*****************************************/
MARPAWRAPPER_EXPORT genericLoggerOption_t genericLogger_genericLoggerOption_get(genericLogger_t *genericLoggerp) {
  return genericLoggerp->genericLoggerOption;
}

/*******************************/
/* genericLogger_logLevel_seti */
/*******************************/
MARPAWRAPPER_EXPORT genericLoggerLevel_t genericLogger_logLevel_seti(genericLogger_t *genericLoggerp, genericLoggerLevel_t leveli) {
  genericLoggerp->genericLoggerOption.leveli = leveli;
  return genericLoggerp->genericLoggerOption.leveli;
}

/*******************************/
/* genericLogger_logLevel_geti */
/*******************************/
MARPAWRAPPER_EXPORT genericLoggerLevel_t genericLogger_logLevel_geti(const genericLogger_t *genericLoggerp) {
  return genericLoggerp->genericLoggerOption.leveli;
}

/************************************/
/* genericLogger_defaultLogCallback */
/************************************/
MARPAWRAPPER_EXPORT genericLoggerCallback_t genericLogger_defaultLogCallback(void) {
  return &_genericLogger_defaultCallback;
}

/**********************************/
/* _genericLogger_defaultCallback */
/**********************************/
MARPAWRAPPER_EXPORT void _genericLogger_defaultCallback(const void *userDatavp, const genericLoggerLevel_t leveli, const char *msgs) {
  /* We are NOT going to do a general log4c mechanism (this can come later) */
  /* I.e. we are fixing the default output to be: DD/MM/YYYY hh::mm::ss PREFIX MESSAGE */
  const char *prefixs =
    (leveli == GENERICLOGGER_LOGLEVEL_TRACE    ) ? "TRACE"     :
    (leveli == GENERICLOGGER_LOGLEVEL_DEBUG    ) ? "DEBUG"     :
    (leveli == GENERICLOGGER_LOGLEVEL_INFO     ) ? "INFO"      :
    (leveli == GENERICLOGGER_LOGLEVEL_NOTICE   ) ? "NOTICE"    :
    (leveli == GENERICLOGGER_LOGLEVEL_WARNING  ) ? "WARNING"   :
    (leveli == GENERICLOGGER_LOGLEVEL_ERROR    ) ? "ERROR"     :
    (leveli == GENERICLOGGER_LOGLEVEL_CRITICAL ) ? "CRITICAL"  :
    (leveli == GENERICLOGGER_LOGLEVEL_ALERT    ) ? "ALERT"     :
    (leveli == GENERICLOGGER_LOGLEVEL_EMERGENCY) ? "EMERGENCY" :
    "UNKOWN";
  char *dates = dateBuilder("%d/%m/%Y %H:%M:%S");
  char *localMsgs = messageBuilder("%s %9s %s\n", dates, prefixs, (msgs != NULL) ? (char *) msgs : (char *) GENERICLOGGER_LOG_NO_MESSAGE);
  char *p = localMsgs;
#ifdef FILENO
  int filenoStderr = FILENO(stderr);
#ifdef SYS_FILENO_IS_FILENO
  ssize_t bytesWriten = 0;
#else
  size_t bytesWriten = 0;
#endif
  size_t  count;
#endif

#ifdef FILENO
  count = strlen(p);
  while (bytesWriten < count) {
    bytesWriten += SYS_WRITE(filenoStderr, p+bytesWriten, count-bytesWriten);
  }
#else
  /* Note: this is not asynchroneous safe */
  fprintf(stderr, "%s", p);
#endif

  if (dates != dateBuilder_internalErrors()) {
    free(dates);
  }
  if (localMsgs != messageBuilder_internalErrors()) {
    free(localMsgs);
  }
}

/**************************/
/* genericLogger_defaultv */
/**************************/
MARPAWRAPPER_EXPORT void genericLogger_defaultv(genericLoggerOption_t *genericLoggerOptionp) {
  if (genericLoggerOptionp != NULL) {
    genericLoggerOptionp->logCallbackp = NULL;
    genericLoggerOptionp->userDatavp   = NULL;
    genericLoggerOptionp->leveli       = GENERICLOGGER_LOGLEVEL_WARNING;
  }
}

/**********************/
/* genericLogger_newp */
/**********************/
MARPAWRAPPER_EXPORT genericLogger_t *genericLogger_newp(const genericLoggerOption_t *genericLoggerOptionp) {
  genericLoggerOption_t  genericLoggerOption;
  genericLogger_t       *genericLoggerp = malloc(sizeof(genericLogger_t));

  /* Fill the defaults */
  if (genericLoggerOptionp == NULL) {
    genericLogger_defaultv(&genericLoggerOption);
  } else {
    genericLoggerOption = *genericLoggerOptionp;
  }

  if (genericLoggerp == NULL) {
    /* Well, shall we log about this - a priori no: the caller wanted to set up a particular */
    /* logging system, and not use our default */
    return NULL;
  }

  genericLoggerp->genericLoggerOption = genericLoggerOption;

  return genericLoggerp;
}

/**************************/
/* genericLogger_destroyv */
/**************************/
MARPAWRAPPER_EXPORT void genericLogger_destroyv(genericLogger_t *genericLoggerp) {
  if (genericLoggerp != NULL) {
    free(genericLoggerp);
  }
}

/*********************/
/* genericLogger_log */
/*********************/
MARPAWRAPPER_EXPORT void genericLogger_log(const genericLogger_t *genericLoggerp, genericLoggerLevel_t leveli, const char *fmts, ...) {
  va_list                ap;
#ifdef VA_COPY
  va_list                ap2;
#endif
  char                  *msgs;
  static const char     *emptyMessages = "Empty message";
  genericLoggerCallback_t  logCallbackp;
  void                  *userDatavp;
  genericLoggerLevel_t     genericLoggerDefaultLogLeveli;

  if (genericLoggerp != NULL) {
    if (genericLoggerp->genericLoggerOption.logCallbackp != NULL) {
      logCallbackp = genericLoggerp->genericLoggerOption.logCallbackp;
    } else {
      logCallbackp = &_genericLogger_defaultCallback;
    }
    userDatavp = genericLoggerp->genericLoggerOption.userDatavp;
    genericLoggerDefaultLogLeveli = genericLoggerp->genericLoggerOption.leveli;
  } else {
    userDatavp = NULL;
    logCallbackp = &_genericLogger_defaultCallback;
    genericLoggerDefaultLogLeveli = GENERICLOGGER_LOGLEVEL_WARNING;
  }

  if (leveli >= genericLoggerDefaultLogLeveli) {

    va_start(ap, fmts);
#ifdef VA_COPY
    VA_COPY(ap2, ap);
    msgs = (fmts != NULL) ? messageBuilder_ap(fmts, ap2) : (char *) emptyMessages;
    va_end(ap2);
#else
    msgs = (fmts != NULL) ? messageBuilder_ap(fmts, ap) : (char *) emptyMessages;
#endif
    va_end(ap);

    if (msgs != messageBuilder_internalErrors()) {
      logCallbackp(userDatavp, leveli, msgs);
    } else {
      logCallbackp(userDatavp, GENERICLOGGER_LOGLEVEL_ERROR, msgs);
    }

    if (msgs != emptyMessages && msgs != messageBuilder_internalErrors()) {
      /* No need to assign to NULL, this is a local variable and we will return just after */
      free(msgs);
    }
  }

}

/****************************/
/* genericLoggerOption_newp */
/****************************/
MARPAWRAPPER_EXPORT genericLoggerOption_t *genericLoggerOption_newp(void) {
  genericLoggerOption_t *genericLoggerOptionp = (genericLoggerOption_t *) malloc(sizeof(genericLoggerOption_t));
  if (genericLoggerOptionp != NULL) {
    genericLoggerOption_defaultv(genericLoggerOptionp);
  }
  return genericLoggerOptionp;
}

/********************************/
/* genericLoggerOption_destroyv */
/********************************/
MARPAWRAPPER_EXPORT void genericLoggerOption_destroyv(genericLoggerOption_t *genericLoggerOptionp) {
  if (genericLoggerOptionp == NULL) {
    return;
  }
  free(genericLoggerOptionp);
}

/********************************/
/* genericLoggerOption_defaultv */
/********************************/
MARPAWRAPPER_EXPORT void genericLoggerOption_defaultv(genericLoggerOption_t *genericLoggerOptionp) {

  if (genericLoggerOptionp != NULL) {
    genericLoggerOptionp->logCallbackp = NULL;
    genericLoggerOptionp->userDatavp   = NULL;
    genericLoggerOptionp->leveli       = GENERICLOGGER_LOGLEVEL_WARNING;
  }

}
