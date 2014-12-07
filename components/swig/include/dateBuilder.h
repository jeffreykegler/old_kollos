#ifndef MARPAWRAPPER_INTERNAL_DATEBUILDER_H
#define MARPAWRAPPER_INTERNAL_DATEBUILDER_H

#include <stdarg.h>

/* Portable methods to build a date */

/* IF THE OUTPUT OF dateBuilder() or dateBuilder_ap() is    */
/* equal to dateBuilder_internalErrors() then the caller       */
/* must NOT call free(). In any other case the caller MUST CALL   */
/* free() on the returned value.                                  */
/* The method dateBuilder_internalErrors() is guaranteed to    */
/* never fail.                                                    */
/* The others are guaranteed to never return a NULL pointer, but  */
/* this pointer CAN be equal to dateBuilder_internalErrors()   */
/* output.                                                        */

char *dateBuilder_internalErrors(void);
/* Output MUST be freed by caller it is != dateBuilder_internalErrors() */
char *dateBuilder(const char *fmts);

#endif /* MARPAWRAPPER_INTERNAL_DATEBUILDER_H */
