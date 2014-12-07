#ifndef MARPAWRAPPER_INTERNAL_GENERICSTACK_H
#define MARPAWRAPPER_INTERNAL_GENERICSTACK_H

#include <stddef.h>              /* size_t definition */

/*************************
   Opaque object pointer
 *************************/
typedef struct genericStack genericStack_t;

/*************************
   Macros/Enums
 *************************/
#define GENERICSTACK_OPTION_GROW_ON_GET 0x01
#define GENERICSTACK_OPTION_GROW_ON_SET 0x02
#define GENERICSTACK_OPTION_GROW_DEFAULT (GENERICSTACK_OPTION_GROW_ON_GET | GENERICSTACK_OPTION_GROW_ON_SET)

typedef enum genericStack_error_parameter {
  GENERICSTACK_ERROR_PARAMETER_ELEMENTSIZE,         /* elementSize error */
} genericStack_error_parameter_t;

typedef enum genericStack_error_runtime {
  GENERICSTACK_ERROR_RUNTIME_STACK_EMPTY,         /* Stack is empty */
  GENERICSTACK_ERROR_RUNTIME_STACK_TOO_SMALL_GET, /* Attempt to get beyond stack size that do not have optionGrowOnGet */
  GENERICSTACK_ERROR_RUNTIME_STACK_TOO_SMALL_SET, /* Attempt to get beyond stack size that do not have optionGrowOnSet */
} genericStack_error_runtime_t;

typedef enum genericStack_error {
  GENERICSTACK_ERROR_SYSTEM,              /* System error, like a malloc() failure. Error number is guaranteed to be system's errno */
  GENERICSTACK_ERROR_PARAMETER,           /* Parameter validation error when calling genericStack. Error number is guaranted to belong to genericStack_error_parameter_t enum */
  GENERICSTACK_ERROR_RUNTIME,             /* Runtime error when processing request within genericStack. Error number is guaranted to belong to genericStack_error_runtime_t enum */
  GENERICSTACK_ERROR_CALLBACK,            /* Error returned from user's callback. Error number will be the value returned by the callback. Only user know what is means. */
} genericStack_error_t;

/*************************
   Callback types
 *************************/
typedef void (*genericStack_failureCallback_t)(const genericStack_error_t errorType, const int errorNumber, const void *failureCallbackUserDatap);
typedef int  (*genericStack_freeCallback_t)(const void *elementp, const void *freeCallbackUserDatap);
typedef int  (*genericStack_copyCallback_t)(const void *elementDstp, const void *elementSrcp, const void *copyCallbackUserDatap);

/*************************
   Options
 *************************/
typedef struct genericStack_option {
  unsigned int                   growFlags;

  genericStack_failureCallback_t failureCallbackp;
  void                          *failureCallbackUserDatap;

  genericStack_freeCallback_t    freeCallbackp;
  void                          *freeCallbackUserDatap;

  genericStack_copyCallback_t    copyCallbackp;
  void                          *copyCallbackUserDatap;
} genericStack_option_t;

/*************************
   Methods
 *************************/
genericStack_t *genericStack_newp    (const size_t elementSize, const genericStack_option_t *optionp);

size_t          genericStack_pushi   (genericStack_t *genericStackp, const void *elementp);
void           *genericStack_popp    (genericStack_t *genericStackp);
void           *genericStack_getp    (genericStack_t *genericStackp, const unsigned int index);
size_t          genericStack_seti    (genericStack_t *genericStackp, const unsigned int index, const void *elementp);
size_t          genericStack_sizei   (const genericStack_t *genericStackp);

void            genericStack_destroyv(genericStack_t *genericStackp);

#endif /* MARPAWRAPPER_INTERNAL_GENERICSTACK_H */
