/*
 * Variation on http://rosettacode.org/wiki/Stack
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include "genericStack.h"

#define STACK_INIT_SIZE 4

struct genericStack {
  void                         **bufpp;
  size_t                         allocSizei;
  size_t                         stackSizei;
  size_t                         elementSizei;
  genericStack_failureCallback_t failureCallbackp;
  void                          *failureCallbackUserDatap;
  genericStack_freeCallback_t    freeCallbackp;
  void                          *freeCallbackUserDatap;
  genericStack_copyCallback_t    copyCallbackp;
  void                          *copyCallbackUserDatap;
  short                          optionGrowOnSeti;
  short                          optionGrowOnGeti;
};

/*************************
   genericStack_newp
 *************************/
genericStack_t *genericStack_newp(const size_t elementSizei, const genericStack_option_t *optionp)
{
  genericStack_t    *genericStackp;
  unsigned int       i;

  if (elementSizei <= 0) {
    if (optionp != NULL && optionp->failureCallbackp != NULL) {
      (*optionp->failureCallbackp)(GENERICSTACK_ERROR_PARAMETER, GENERICSTACK_ERROR_PARAMETER_ELEMENTSIZE, optionp->failureCallbackUserDatap);
    }
    return NULL;
  }

  genericStackp = malloc(sizeof(genericStack_t));
  if (genericStackp == NULL) {
    if (optionp != NULL && optionp->failureCallbackp != NULL) {
      (*optionp->failureCallbackp)(GENERICSTACK_ERROR_SYSTEM, errno, optionp->failureCallbackUserDatap);
    }
    return NULL;
  }
  genericStackp->bufpp = malloc(elementSizei * STACK_INIT_SIZE);
  if (genericStackp->bufpp == NULL) {
    if (optionp != NULL && optionp->failureCallbackp != NULL) {
      (*optionp->failureCallbackp)(GENERICSTACK_ERROR_SYSTEM, errno, optionp->failureCallbackUserDatap);
    }
    free(genericStackp);
    return NULL;
  }
  for (i = 0; i < STACK_INIT_SIZE; i++) {
    genericStackp->bufpp[i] = NULL;
  }

  genericStackp->allocSizei                = STACK_INIT_SIZE;
  genericStackp->stackSizei                = 0;
  genericStackp->elementSizei              = elementSizei;
  genericStackp->failureCallbackp         = optionp != NULL ? optionp->failureCallbackp : NULL;
  genericStackp->failureCallbackUserDatap = optionp != NULL ? optionp->failureCallbackUserDatap : NULL;
  genericStackp->freeCallbackp            = optionp != NULL ? optionp->freeCallbackp : NULL;
  genericStackp->freeCallbackUserDatap    = optionp != NULL ? optionp->freeCallbackUserDatap : NULL;
  genericStackp->copyCallbackp            = optionp != NULL ? optionp->copyCallbackp : NULL;
  genericStackp->copyCallbackUserDatap    = optionp != NULL ? optionp->copyCallbackUserDatap : NULL;
  genericStackp->optionGrowOnGeti          = optionp != NULL ? (((optionp->growFlags & GENERICSTACK_OPTION_GROW_ON_GET) == GENERICSTACK_OPTION_GROW_ON_GET) ? 1 : 0) : 0;
  genericStackp->optionGrowOnSeti          = optionp != NULL ? (((optionp->growFlags & GENERICSTACK_OPTION_GROW_ON_SET) == GENERICSTACK_OPTION_GROW_ON_SET) ? 1 : 0) : 0;

  return genericStackp;
}

/*************************
   genericStack_destroyv
 *************************/
void genericStack_destroyv(genericStack_t *genericStackp)
{
  unsigned int i;

  if (genericStackp == NULL) {
    return;
  }

  /* genericStackp->allocSizei is always > 0 per def */
  for (i = 0; i < genericStackp->allocSizei; i++) {
    if (genericStackp->bufpp[i] != NULL) {
      if (genericStackp->freeCallbackp != NULL) {
	int errnum = (*(genericStackp->freeCallbackp))(genericStackp->bufpp[i], genericStackp->freeCallbackUserDatap);
	if (errnum != 0) {
	  if (genericStackp->failureCallbackp != NULL) {
	    (*(genericStackp->failureCallbackp))(GENERICSTACK_ERROR_CALLBACK, errnum, genericStackp->failureCallbackUserDatap);
	  }
	}
      }
      free(genericStackp->bufpp[i]);
      genericStackp->bufpp[i] = NULL;
    }
  }

  free(genericStackp->bufpp);
  free(genericStackp);

  return;
}

/*************************
   genericStack_pushi
 *************************/
size_t genericStack_pushi(genericStack_t *genericStackp, const void *elementp)
{
  unsigned int i;

  if (genericStackp == NULL) {
    return 0;
  }

  if (genericStackp->stackSizei >= genericStackp->allocSizei) {
    size_t allocSizei = genericStackp->allocSizei * 2;
    void **bufpp;

    bufpp = realloc(genericStackp->bufpp, allocSizei * sizeof(void *));
    if (bufpp == NULL) {
      if (genericStackp->failureCallbackp != NULL) {
	(*(genericStackp->failureCallbackp))(GENERICSTACK_ERROR_SYSTEM, errno, genericStackp->failureCallbackUserDatap);
      }
      return 0;
    }
    genericStackp->bufpp = bufpp;
    for (i = genericStackp->allocSizei; i < allocSizei; i++) {
      genericStackp->bufpp[i] = NULL;
    }
    genericStackp->allocSizei = allocSizei;
  }
  if (elementp != NULL) {
    void *newElementp = malloc(genericStackp->elementSizei);
    if (newElementp == NULL) {
      if (genericStackp->failureCallbackp != NULL) {
	(*(genericStackp->failureCallbackp))(GENERICSTACK_ERROR_SYSTEM, errno, genericStackp->failureCallbackUserDatap);
      }
      return 0;
    }
    memcpy(newElementp, elementp, genericStackp->elementSizei);
    if (genericStackp->copyCallbackp != NULL) {
      int errnum = (*(genericStackp->copyCallbackp))(newElementp, elementp, genericStackp->copyCallbackUserDatap);
      if (errnum != 0) {
	if (genericStackp->failureCallbackp != NULL) {
          (*(genericStackp->failureCallbackp))(GENERICSTACK_ERROR_CALLBACK, errnum, genericStackp->failureCallbackUserDatap);
	}
      }
    }
    genericStackp->bufpp[genericStackp->stackSizei] = newElementp;
  } else {
    genericStackp->bufpp[genericStackp->stackSizei] = NULL;
  }
  genericStackp->stackSizei++;

  return 1;
}

/*************************
   genericStack_popp
 *************************/
void  *genericStack_popp(genericStack_t *genericStackp)
{
  void *value;

  if (genericStackp == NULL) {
    return NULL;
  }

  if (genericStackp->stackSizei <= 0) {
    if (genericStackp->failureCallbackp != NULL) {
      (*(genericStackp->failureCallbackp))(GENERICSTACK_ERROR_RUNTIME, GENERICSTACK_ERROR_RUNTIME_STACK_EMPTY, genericStackp->failureCallbackUserDatap);
    }
    return NULL;
  }
  value = genericStackp->bufpp[genericStackp->stackSizei-- - 1];
  if ((genericStackp->stackSizei * 2) <= genericStackp->allocSizei && genericStackp->allocSizei >= 8) {
    size_t allocSizei = genericStackp->allocSizei / 2;
    void **bufpp = realloc(genericStackp->bufpp, allocSizei * sizeof(void *));
    /* If failure, memory is still here. We tried to shrink */
    /* and not to expand, so no need to call the failure callback */
    if (bufpp != NULL) {
      genericStackp->allocSizei = allocSizei;
      genericStackp->bufpp = bufpp;
    }
  }
  return value;
}

/*************************
   genericStack_getp
 *************************/
void  *genericStack_getp(genericStack_t *genericStackp, const unsigned int index)
{
  if (genericStackp == NULL) {
    return NULL;
  }
  if (index >= genericStackp->allocSizei && genericStackp->optionGrowOnGeti == 1) {
    while (index >= genericStackp->allocSizei) {
      genericStack_pushi(genericStackp, NULL);
    }
  }
  if (index >= genericStackp->stackSizei && genericStackp->optionGrowOnGeti != 1) {
    if (genericStackp->failureCallbackp != NULL) {
      (*(genericStackp->failureCallbackp))(GENERICSTACK_ERROR_RUNTIME, GENERICSTACK_ERROR_RUNTIME_STACK_TOO_SMALL_GET, genericStackp->failureCallbackUserDatap);
    }
    return NULL;
  }
  return genericStackp->bufpp[index];
}

/*************************
   genericStack_seti
 *************************/
size_t genericStack_seti(genericStack_t *genericStackp, const unsigned int index, const void *elementp)
{
  size_t minStackSize = index+1;

  if (genericStackp == NULL) {
    return 0;
  }
  if (index >= genericStackp->allocSizei && genericStackp->optionGrowOnSeti == 1) {
    while (index >= genericStackp->allocSizei) {
      genericStack_pushi(genericStackp, NULL);
    }
  }
  if (index >= genericStackp->stackSizei && genericStackp->optionGrowOnSeti != 1) {
    if (genericStackp->failureCallbackp != NULL) {
      (*(genericStackp->failureCallbackp))(GENERICSTACK_ERROR_RUNTIME, GENERICSTACK_ERROR_RUNTIME_STACK_TOO_SMALL_SET, genericStackp->failureCallbackUserDatap);
    }
    return 0;
  }
  if (genericStackp->bufpp[index] != NULL) {
    if (genericStackp->freeCallbackp != NULL) {
      int errnum = (*(genericStackp->freeCallbackp))(genericStackp->bufpp[index], genericStackp->freeCallbackUserDatap);
      if (errnum != 0) {
	if (genericStackp->failureCallbackp != NULL) {
          (*(genericStackp->failureCallbackp))(GENERICSTACK_ERROR_CALLBACK, errnum, genericStackp->failureCallbackUserDatap);
	}
      }
    }
    free(genericStackp->bufpp[index]);
    genericStackp->bufpp[index] = NULL;
  }
  if (elementp != NULL) {
    void *newElementp = malloc(genericStackp->elementSizei);
    if (newElementp == NULL) {
      if (genericStackp->failureCallbackp != NULL) {
        (*(genericStackp->failureCallbackp))(GENERICSTACK_ERROR_SYSTEM, errno, genericStackp->failureCallbackUserDatap);
      }
      return 0;
    }
    memcpy(newElementp, elementp, genericStackp->elementSizei);
    if (genericStackp->copyCallbackp != NULL) {
      int errnum = (*(genericStackp->copyCallbackp))(newElementp, elementp, genericStackp->copyCallbackUserDatap);
      if (errnum != 0) {
	if (genericStackp->failureCallbackp != NULL) {
          (*(genericStackp->failureCallbackp))(GENERICSTACK_ERROR_CALLBACK, errnum, genericStackp->failureCallbackUserDatap);
	}
      }
    }
    genericStackp->bufpp[index] = newElementp;
  }
  if (genericStackp->stackSizei < minStackSize) {
    genericStackp->stackSizei = minStackSize;
  }
  return 1;
}

/*************************
   genericStack_sizei
 *************************/
size_t genericStack_sizei(const genericStack_t *genericStackp)
{
  if (genericStackp == NULL) {
    return 0;
  }
  return (genericStackp->stackSizei);
}
