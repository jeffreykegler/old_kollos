#include "marpaWrapper_config.h"

#ifdef _WIN32
#include <windows.h>
#endif
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>

#include "marpaWrapper.h"
#include "genericLogger.h"
#include "messageBuilder.h"

enum { S = 0, E, op, number, MAX_SYMBOL };
enum { START_RULE = 0, OP_RULE, NUMBER_RULE };

typedef struct myStack {
  char *string;
  int   value;
} myStack_t;

static marpaWrapperBool_t      myValueRuleCallback(const marpaWrapperUserData_t    *marpaWrapperUserDatap,
						   const marpaWrapperRecognizer_t  *marpaWrapperRecognizerp,
						   const marpaWrapperRule_t        *marpaWrapperRulep,
						   const size_t                     nValuepInputi,
						   const marpaWrapperValuepArrayp_t valuepArrayInputp,
						   marpaWrapperValuep_t            *valuepOutputp);
static marpaWrapperBool_t      myValueSymbolCallback(const marpaWrapperUserData_t   *marpaWrapperUserDatap,
						     const marpaWrapperRecognizer_t *marpaWrapperRecognizerp,
						     const marpaWrapperSymbol_t     *marpaWrapperSymbolp,
						     const int                       valueIndexi,
						     marpaWrapperValuep_t           *valuepOutputp);
static marpaWrapperBool_t      myValueNullingCallback(const marpaWrapperUserData_t   *marpaWrapperUserDatap,
						      const marpaWrapperRecognizer_t *marpaWrapperRecognizerp,
						      const marpaWrapperSymbol_t     *marpaWrapperSymbolp,
						      marpaWrapperValuep_t           *valuepOutputp);
static marpaWrapperValueBool_t myValueResultCallback(const marpaWrapperUserData_t   *marpaWrapperUserDatap,
						     const marpaWrapperRecognizer_t *marpaWrapperRecognizerp,
						     const marpaWrapperValuep_t      valuepInput);

static marpaWrapperBool_t     myStackElementFreeCallback(const marpaWrapperUserData_t   *marpaWrapperUserDatap,
							 const marpaWrapperRecognizer_t *marpaWrapperRecognizerp,
							 const void                     *elementp);
static marpaWrapperBool_t     myStackElementCopyCallback(const marpaWrapperUserData_t   *marpaWrapperUserDatap,
							 const marpaWrapperRecognizer_t *marpaWrapperRecognizerp,
							 const void                     *elementDstp,
							 const void                     *elementSrcp);

int main() {
  size_t                     i;
  /* Object types */
  marpaWrapper_t            *marpaWrapperp;
  marpaWrapperRecognizer_t  *marpaWrapperRecognizerp;
  marpaWrapperSymbolArrayp_t symbolArrayp[MAX_SYMBOL];
  marpaWrapperSymbolArrayp_t rhsSymbolArrayp[3]; /* Just to have enough room */
  /* Options */
  marpaWrapperOption_t       marpaWrapperOption;
  marpaWrapperSymbolOption_t marpaWrapperSymbolOption;
  marpaWrapperRuleOption_t   marpaWrapperRuleOption;
  marpaWrapperValueOption_t  marpaWrapperValueOption;
  marpaWrapperStackOption_t  marpaWrapperStackOption;
  size_t                     nmarpaWrapperProgressi;
  marpaWrapperProgress_t   **marpaWrapperProgresspp;
  /* Token values */
  const char               *token_values[] = { NULL, "1", "2", "3", "0", "-", "+", "*" };
  int                       one                  = 1;      /* Indice 1 in token_values */
  int                       two                  = 2;      /* Indice 2 in token_values */
  int                       three                = 3;      /* Indice 3 in token_values */
  int                       zero                 = 4;      /* Indice 4 in token_values */
  int                       minus_token_value    = 5;      /* Indice 5 in token_values */
  int                       plus_token_value     = 6;      /* Indice 6 in token_values */
  int                       multiply_token_value = 7;      /* Indice 7 in token_values */
  genericLoggerOption_t     genericLoggerOption;
  genericLogger_t          *genericLoggerp;

  genericLogger_defaultv(&genericLoggerOption);
  genericLoggerOption.leveli = GENERICLOGGER_LOGLEVEL_TRACE;
  genericLoggerp = genericLogger_newp(&genericLoggerOption);

  /* We want TRACE log level */
  marpaWrapperOption_defaultb(&marpaWrapperOption);
  marpaWrapperOption.genericLoggerp = genericLoggerp;

  /* Grammar */
  marpaWrapperp = marpaWrapper_newp(&marpaWrapperOption);

  /* Symbols */
  for (i = 0; i < MAX_SYMBOL; i++) {
    marpaWrapperSymbolOption_defaultb(&(marpaWrapperSymbolOption));
    marpaWrapperSymbolOption.startb = (i == 0) ? MARPAWRAPPER_BOOL_TRUE : MARPAWRAPPER_BOOL_FALSE;
    symbolArrayp[i] = marpaWrapper_addSymbolp(marpaWrapperp, &marpaWrapperSymbolOption);
  }

  /* Rules */
  marpaWrapperRuleOption_defaultb(&marpaWrapperRuleOption);
  marpaWrapperRuleOption.rhsSymbolArraypp = &(rhsSymbolArrayp[0]);

  /* S ::= E */
  marpaWrapperRuleOption.lhsSymbolp     = symbolArrayp[S];
  rhsSymbolArrayp[0]                    = symbolArrayp[E];
  marpaWrapperRuleOption.nRhsSymboli    = 1;
  marpaWrapperRuleOption.datavp         = (void *) START_RULE;
  marpaWrapper_addRulep(marpaWrapperp, &marpaWrapperRuleOption);

  /* E ::= E op E */
  marpaWrapperRuleOption.lhsSymbolp     = symbolArrayp[ E];
  rhsSymbolArrayp[0]                    = symbolArrayp[ E];
  rhsSymbolArrayp[1]                    = symbolArrayp[op];
  rhsSymbolArrayp[2]                    = symbolArrayp[ E];
  marpaWrapperRuleOption.nRhsSymboli    = 3;
  marpaWrapperRuleOption.datavp         = (void *) OP_RULE;
  marpaWrapper_addRulep(marpaWrapperp, &marpaWrapperRuleOption);

  /* E ::= number */
  marpaWrapperRuleOption.lhsSymbolp     = symbolArrayp[     E];
  rhsSymbolArrayp[0]                    = symbolArrayp[number];
  marpaWrapperRuleOption.nRhsSymboli    = 1;
  marpaWrapperRuleOption.datavp         = (void *) NUMBER_RULE;
  marpaWrapper_addRulep(marpaWrapperp, &marpaWrapperRuleOption);
  marpaWrapper_precomputeb(marpaWrapperp);

  marpaWrapperRecognizerp = marpaWrapperRecognizer_newp(marpaWrapperp);

  if (marpaWrapperRecognizer_progressb(marpaWrapperRecognizerp, -1, -1, &nmarpaWrapperProgressi, &marpaWrapperProgresspp) == MARPAWRAPPER_BOOL_TRUE) {
    for (i = 0; i < nmarpaWrapperProgressi; i++) {
      GENERICLOGGER_INFOX("Earley Set Id: %4d, Origin Earley Set Id: %4d, Rule: %10p, Position: %3d",
			  marpaWrapperProgresspp[i]->marpaEarleySetIdi,
			  marpaWrapperProgresspp[i]->marpaEarleySetIdOrigini,
			  (void *) marpaWrapperProgresspp[i]->marpaWrapperRulep,
			  marpaWrapperProgresspp[i]->positioni);
    }
    marpaWrapperRecognizer_progress_freev(marpaWrapperRecognizerp, &nmarpaWrapperProgressi, &marpaWrapperProgresspp);
  }

  marpaWrapperRecognizer_readb(marpaWrapperRecognizerp, symbolArrayp[number],                  two, 1);
  marpaWrapperRecognizer_readb(marpaWrapperRecognizerp, symbolArrayp[    op],    minus_token_value, 1);
  marpaWrapperRecognizer_readb(marpaWrapperRecognizerp, symbolArrayp[number],                 zero, 1);
  marpaWrapperRecognizer_readb(marpaWrapperRecognizerp, symbolArrayp[    op], multiply_token_value, 1);
  marpaWrapperRecognizer_readb(marpaWrapperRecognizerp, symbolArrayp[number],                three, 1);

#ifdef _WIN32
  // Sleep(10000);
#endif
  if (marpaWrapperRecognizer_progressb(marpaWrapperRecognizerp, 0, -1, &nmarpaWrapperProgressi, &marpaWrapperProgresspp) == MARPAWRAPPER_BOOL_TRUE) {
    for (i = 0; i < nmarpaWrapperProgressi; i++) {
      GENERICLOGGER_INFOX("Earley Set Id: %4d, Origin Earley Set Id: %4d, Rule: %10p, Position: %3d",
			  marpaWrapperProgresspp[i]->marpaEarleySetIdi,
			  marpaWrapperProgresspp[i]->marpaEarleySetIdOrigini,
			  (void *) marpaWrapperProgresspp[i]->marpaWrapperRulep,
			  marpaWrapperProgresspp[i]->positioni);
    }
    marpaWrapperRecognizer_progress_freev(marpaWrapperRecognizerp, &nmarpaWrapperProgressi, &marpaWrapperProgresspp);
  }

  marpaWrapperRecognizer_readb(marpaWrapperRecognizerp, symbolArrayp[    op],     plus_token_value, 1);
  marpaWrapperRecognizer_readb(marpaWrapperRecognizerp, symbolArrayp[number],                  one, 1);

  marpaWrapperValueOption_defaultb(&marpaWrapperValueOption);
  marpaWrapperValueOption.valueRuleCallbackp         = &myValueRuleCallback;
  marpaWrapperValueOption.valueSymbolCallbackp       = &myValueSymbolCallback;
  marpaWrapperValueOption.valueSymbolCallbackDatavp  = (void *) token_values;
  marpaWrapperValueOption.valueNullingCallbackp      = &myValueNullingCallback;
  marpaWrapperValueOption.valueResultCallbackp       = &myValueResultCallback;
  marpaWrapperValueOption.valueResultCallbackDatavp  = genericLoggerp;

  marpaWrapperStackOption_defaultb(&marpaWrapperStackOption);
  marpaWrapperStackOption.stackElementSizei = sizeof(myStack_t);
  marpaWrapperStackOption.stackElementFreeCallbackp = &myStackElementFreeCallback;
  marpaWrapperStackOption.stackElementCopyCallbackp = &myStackElementCopyCallback;

#ifdef _WIN32
  // Sleep(10000);
#endif

  marpaWrapper_vb(marpaWrapperRecognizerp, &marpaWrapperValueOption, &marpaWrapperStackOption);

  marpaWrapperRecognizer_destroyv(marpaWrapperRecognizerp);
  marpaWrapper_destroyv(marpaWrapperp);
  genericLogger_destroyv(genericLoggerp);

  return 0;
}

static marpaWrapperBool_t myValueRuleCallback(const marpaWrapperUserData_t    *marpaWrapperUserDatap,
					      const marpaWrapperRecognizer_t  *marpaWrapperRecognizerp,
					      const marpaWrapperRule_t        *marpaWrapperRulep,
					      const size_t                     nValuepInputi,
					      const marpaWrapperValuepArrayp_t valuepArrayInputp,
					      marpaWrapperValuep_t            *valuepOutputp) {
  int rulei;
  myStack_t *outputp = malloc(sizeof(myStack_t));
  myStack_t **stackpp = (myStack_t **) valuepArrayInputp;

  if (outputp == NULL) {
    return MARPAWRAPPER_BOOL_FALSE;
  }

  rulei = (int) marpaWrapperRule_datavp_get(marpaWrapperRulep);

  switch (rulei) {
  case START_RULE:
    /* S ::= E */
    outputp->string = messageBuilder("%s == %d", stackpp[0]->string, stackpp[0]->value);
    if (outputp->string == messageBuilder_internalErrors()) {
      free(outputp);
      return MARPAWRAPPER_BOOL_FALSE;
    }
    outputp->value = stackpp[0]->value;
    break;

  case NUMBER_RULE:
    /* E ::= number */
    outputp->string = messageBuilder("%d", stackpp[0]->value);
    if (outputp->string == messageBuilder_internalErrors()) {
      free(outputp);
      return MARPAWRAPPER_BOOL_FALSE;
    }
    outputp->value = stackpp[0]->value;
    break;

  case OP_RULE:
    /* E ::= E op E */
    outputp->string = messageBuilder("(%s%s%s)", stackpp[0]->string, stackpp[1]->string, stackpp[2]->string);
    if (outputp->string == messageBuilder_internalErrors()) {
      free(outputp);
      return MARPAWRAPPER_BOOL_FALSE;
    }
    switch (stackpp[1]->string[0]) {
    case '+':
      outputp->value = stackpp[0]->value + stackpp[2]->value;
      break;
    case '-':
      outputp->value = stackpp[0]->value - stackpp[2]->value;
      break;
    case '*':
      outputp->value = stackpp[0]->value * stackpp[2]->value;
      break;
    default:
      free(outputp);
      return MARPAWRAPPER_BOOL_FALSE;
    }
    break;

  default:
    free(outputp);
    return MARPAWRAPPER_BOOL_FALSE;
  }

  *valuepOutputp = outputp;

  return MARPAWRAPPER_BOOL_TRUE;
}

static marpaWrapperBool_t myValueSymbolCallback(const marpaWrapperUserData_t   *marpaWrapperUserDatap,
						const marpaWrapperRecognizer_t *marpaWrapperRecognizerp,
						const marpaWrapperSymbol_t     *marpaWrapperSymbolp,
						const int                       valueIndexi,
						marpaWrapperValuep_t           *valuepOutputp) {
  const char **token_valuesp = (const char **) marpaWrapperUserDatap;
  myStack_t *outputp = malloc(sizeof(myStack_t));

  if (outputp == NULL) {
    return MARPAWRAPPER_BOOL_FALSE;
  }
  outputp->string = SYS_STRDUP(token_valuesp[valueIndexi]);
  if (outputp->string == NULL) {
    free(outputp);
    return MARPAWRAPPER_BOOL_FALSE;
  }
  outputp->value   = atoi(outputp->string);

  *valuepOutputp = outputp;

  return MARPAWRAPPER_BOOL_TRUE;
}

static marpaWrapperBool_t myValueNullingCallback(const marpaWrapperUserData_t   *marpaWrapperUserDatap,
						 const marpaWrapperRecognizer_t *marpaWrapperRecognizerp,
						 const marpaWrapperSymbol_t     *marpaWrapperSymbolp,
						 marpaWrapperValuep_t           *valuepOutputp) {
  /* Should not happen with our example */
  return MARPAWRAPPER_BOOL_FALSE;
}

static marpaWrapperValueBool_t myValueResultCallback(const marpaWrapperUserData_t   *marpaWrapperUserDatap,
						     const marpaWrapperRecognizer_t *marpaWrapperRecognizerp,
						     const marpaWrapperValuep_t      valuepInput) {
  genericLogger_t *genericLoggerp = (genericLogger_t *) marpaWrapperUserDatap;
  myStack_t       *outputp = (myStack_t *) valuepInput;

  GENERICLOGGER_INFOX("Result: %s", outputp->string);

  return MARPAWRAPPER_BOOL_TRUE;
}

static marpaWrapperBool_t     myStackElementFreeCallback(const marpaWrapperUserData_t   *marpaWrapperUserDatap,
							 const marpaWrapperRecognizer_t *marpaWrapperRecognizerp,
							 const void                     *elementp) {
  myStack_t *p = (myStack_t *) elementp;

  if (p->string != NULL) {
    free(p->string);
    p->string = NULL;
  }

  return MARPAWRAPPER_BOOL_TRUE;
}

static marpaWrapperBool_t     myStackElementCopyCallback(const marpaWrapperUserData_t   *marpaWrapperUserDatap,
							 const marpaWrapperRecognizer_t *marpaWrapperRecognizerp,
							 const void                     *elementDstp,
							 const void                     *elementSrcp) {
  myStack_t *dstp = (myStack_t *) elementDstp;
  myStack_t *srcp = (myStack_t *) elementSrcp;

  *dstp = *srcp;

  if (dstp->string != NULL) {
    dstp->string = SYS_STRDUP(dstp->string);
    if (dstp->string == NULL) {
      return MARPAWRAPPER_BOOL_FALSE;
    }
  }
  
  return MARPAWRAPPER_BOOL_TRUE;
}
