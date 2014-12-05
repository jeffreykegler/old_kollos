#include "marpa_wrapper_config.h"

#include <stdlib.h>
#include <stdio.h>
#ifdef HAVE_TIME_H
#include <time.h>
#endif

#include "dateBuilder.h"

static const char *_dateBuilder_internalErrors = "Internal error";

#define DATEBUILDER_MAX_SIZE sizeof(char) * (1024+1)

/*********************************/
/* dateBuilder_internalErrors */
/*********************************/
char *dateBuilder_internalErrors(void) {
  return (char *) _dateBuilder_internalErrors;
}

/******************/
/* dateBuilder */
/******************/
char *dateBuilder(const char *fmts) {
  char      *dates;
  time_t     t;
#if (defined(HAVE_LOCALTIME_R) || defined(HAVE_LOCALTIME_S))
  struct tm  tmpLocal;
#endif
  struct tm *tmp = NULL;

  /* We assume that a date should never exceed 1024 bytes isn't it */
  dates = malloc(DATEBUILDER_MAX_SIZE);
  if (dates == NULL) {
    dates = (char *) _dateBuilder_internalErrors;
  } else {
    t = time(NULL);
#if defined(HAVE_LOCALTIME_R)
    tmp = localtime_r(&t, &tmpLocal);
#elif defined(HAVE_LOCALTIME_S)
    if (localtime_s(&tmpLocal, (const time_t *) &t) == 0) {
      tmp = &tmpLocal;
    }
#else
    tmp = localtime(&t);
#endif
    if (tmp == NULL) {
      dates = (char *) _dateBuilder_internalErrors;
    } else {
      if (strftime(dates, DATEBUILDER_MAX_SIZE, fmts, tmp) == 0) {
	dates = (char *) _dateBuilder_internalErrors;
      }
    }
  }

  return dates;
}
