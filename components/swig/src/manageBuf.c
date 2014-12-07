#include "marpa_wrapper_config.h"

#include <stdlib.h>
#include <errno.h>
#include <string.h>

#include "manageBuf.h"

/*********************/
/* manageBuf_createp */
/*********************/
void *manageBuf_createp(void ***ppp, size_t *sizeip, const size_t wantedNumberi, const size_t elementSizei) {
  size_t  sizei = *sizeip;
  size_t  origSizei = sizei;
  size_t  prevSizei;
  void  **pp = *ppp;

  /*
   * Per def, this routine is managing an array of pointer
   */

  if (sizei < wantedNumberi) {

    prevSizei = sizei;
    while (sizei < wantedNumberi) {
      if (sizei <= 0) {
	/* Let's start at arbitrary number of elements of 100 */
	sizei = 100;
	pp = malloc(sizei * elementSizei);
	if (pp == NULL) {
	  return NULL;
	}
      } else {
	sizei *= 2;
	if (sizei < prevSizei) {
	  /* Turnaround */
	  errno = ERANGE;
	  return NULL;
	}
	pp = realloc(pp, sizei * elementSizei);
	if (pp == NULL) {
	  return NULL;
	}
      }
      prevSizei = sizei;
    }
  }

  /*
   * Pre-fill pointers with NULL
   */
#ifdef NULL_IS_ZEROES
  memset(&(pp[origSizei]), 0, (sizei - origSizei) * elementSizei);
#else
  {
    int i;
    for (i = origSizei; i < sizei; i++) {
      pp[i] = NULL;
    }
  }
#endif

  *ppp = pp;
  *sizeip = sizei;

  return pp;
}

/*******************/
/* manageBuf_freev */
/*******************/
void manageBuf_freev(void ***ppp, size_t *usedNumberip) {
  void  **pp;
  size_t  i;

  if (ppp != NULL) {
    pp = *ppp;
    if (pp != NULL) {
      if (*usedNumberip > 0) {
        for (i = 0; i < *usedNumberip; i++) {
          if (pp[i] != NULL) {
            free(pp[i]);
            pp[i] = NULL;
	  }
	  /* In theory I could that */
	  /*
	  else {
	    last;
	  }
	  */
        }
      }
      free(pp);
    }
    *ppp = NULL;
    *usedNumberip = 0;
  }
}

