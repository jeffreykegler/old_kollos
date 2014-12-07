#ifndef MARPAWRAPPER_INTERNAL_MARPAWRAPPER_H
#define MARPAWRAPPER_INTERNAL_MARPAWRAPPER_H

#include "marpa_wrapper_Export.h"
#include <stddef.h>                  /* size_t definition */

/* Convention is:
   - all pointer symbols end with 'p'
   - all number  symbols end with 'i'
   - all boolean symbols end with 'b'
   - all string  symbols end with 's'
   - all void    symbols end with 'v'
   - all types    end with '_t'
*/

#include "genericLogger.h"

/***********************/
/* Opaque object types */
/***********************/
typedef struct marpaWrapper           marpaWrapper_t;
typedef struct marpaWrapperSymbol     marpaWrapperSymbol_t;
typedef struct marpaWrapperRule       marpaWrapperRule_t;
typedef struct marpaWrapperRecognizer marpaWrapperRecognizer_t;
typedef        void                  *marpaWrapperValuep_t;
typedef        void                   marpaWrapperUserData_t;

/* Arrays should be typed explicitely to distinguish them with a basic pointer */
typedef        marpaWrapperValuep_t  *marpaWrapperValuepArrayp_t;
typedef        marpaWrapperSymbol_t  *marpaWrapperSymbolArrayp_t;

/*******************/
/* Published types */
/*******************/

/* Boolean */
typedef enum marpaWrapperBool {
  MARPAWRAPPER_BOOL_FALSE =  0,
  MARPAWRAPPER_BOOL_TRUE  =  1
} marpaWrapperBool_t;

/* Value callback: boolean and stop directive */
typedef enum marpaWrapperValueBool {
  MARPAWRAPPER_VALUECALLBACKBOOL_STOP  = -1,     /* Used only when iterating over values via marpaWrapperValueCallback() */
  MARPAWRAPPER_VALUECALLBACKBOOL_FALSE =  0,
  MARPAWRAPPER_VALUECALLBACKBOOL_TRUE  =  1
} marpaWrapperValueBool_t;

/* Events */
typedef enum marpaWrapperEventType {
  MARPAWRAPPER_EVENTTYPE_COMPLETED = 0x01,
  MARPAWRAPPER_EVENTTYPE_NULLED    = 0x02,
  MARPAWRAPPER_EVENTTYPE_PREDICTED = 0x04,
} marpaWrapperEventType_t;

typedef struct marpaWrapperEvent {
  const marpaWrapperEventType_t  eventType;
  const marpaWrapperSymbol_t    *marpaWrapperSymbolp;
} marpaWrapperEvent_t;
typedef marpaWrapperEvent_t *marpaWrapperEventArrayp_t;

/*************/
/* Callbacks */
/*************/

/* marpaWrapperEventCallback_t happen during lexing phase only */
typedef marpaWrapperBool_t      (*marpaWrapperEventCallback_t)           (const marpaWrapperUserData_t   *marpaWrapperUserDatap,
									  const marpaWrapper_t           *marpaWrapperp,
									  const size_t                    nEventi,
									  const marpaWrapperEventArrayp_t marpaWrapperEventArrayp);

/* Rule, symbol, nulling and result callbacks happen during value phase only. In this phase there is the notion of generic stack as well. */
typedef marpaWrapperBool_t      (*marpaWrapperValueRuleCallback_t)       (const marpaWrapperUserData_t    *marpaWrapperUserDatap,
									  const marpaWrapperRecognizer_t  *marpaWrapperRecognizerp,
									  const marpaWrapperRule_t        *marpaWrapperRulep,
									  const size_t                     nValuepInputi,
									  const marpaWrapperValuepArrayp_t valuepArrayInputp,
									        marpaWrapperValuep_t      *valuepOutputp);

typedef marpaWrapperBool_t      (*marpaWrapperValueSymbolCallback_t)     (const marpaWrapperUserData_t   *marpaWrapperUserDatap,
									  const marpaWrapperRecognizer_t *marpaWrapperRecognizerp,
									  const marpaWrapperSymbol_t     *marpaWrapperSymbolp,
									  const int                       valueIndexi,
									        marpaWrapperValuep_t     *valuepOutputp);

typedef marpaWrapperBool_t      (*marpaWrapperValueNullingCallback_t)    (const marpaWrapperUserData_t   *marpaWrapperUserDatap,
									  const marpaWrapperRecognizer_t *marpaWrapperRecognizerp,
									  const marpaWrapperSymbol_t     *marpaWrapperSymbolp,
									        marpaWrapperValuep_t     *valuepOutputp);

typedef marpaWrapperValueBool_t (*marpaWrapperValueResultCallback_t)     (const marpaWrapperUserData_t   *marpaWrapperUserDatap,
									  const marpaWrapperRecognizer_t *marpaWrapperRecognizerp,
									  const marpaWrapperValuep_t      valuepInput);

typedef marpaWrapperBool_t      (*marpaWrapperStackElementFreeCallback_t)(const marpaWrapperUserData_t *marpaWrapperUserDatap,
									  const marpaWrapperRecognizer_t *marpaWrapperRecognizerp,
									  const void                   *elementp);

typedef marpaWrapperBool_t      (*marpaWrapperStackElementCopyCallback_t)(const marpaWrapperUserData_t *marpaWrapperUserDatap,
									  const marpaWrapperRecognizer_t *marpaWrapperRecognizerp,
									  const void                   *elementDstp,
									  const void                   *elementSrcp);

/* Symbol options - This is an optional parameter, so there are defaults if is not supplied. */
typedef struct marpaWrapperSymbolOption {
  marpaWrapperUserData_t *datavp;      /* Default: NULL.                    User's opaque data pointer for this symbol     */
  marpaWrapperBool_t      terminalb;   /* Default: MARPAWRAPPER_BOOL_FALSE. Eventually force symbol to be terminal         */
  marpaWrapperBool_t      startb;      /* Default: MARPAWRAPPER_BOOL_FALSE. Eventually force symbol to be the start symbol */
  int                     eventSeti;   /* Default: 0.                                                                      */
  size_t                  sizel;       /* Default: 0. Used only if this is seen as an expected terminal and in LATM mode   */
  signed int              firstChari;  /* Default: -1. Used only if this is seen as an expected terminal and in LATM mode  */
} marpaWrapperSymbolOption_t;

/* Rule options - this is a required parameter, so the user is EXPECTED to overwrite some members */
/* with meaningful values. In particular:                                                         */
/* - lhsSymbolp                                                                                   */
/* - nRhsSymboli                                                                                  */
/* - rhsSymbolpp                                                                                  */
typedef struct marpaWrapperRuleOption {
  marpaWrapperUserData_t     *datavp;           /* Default: NULL.                    User's opaque data pointer for this rule                           */
  marpaWrapperSymbol_t       *lhsSymbolp;       /* Default: NULL.                    LHS symbol as returned by marpaWrapperSymbol_newp()                */
  size_t                      nRhsSymboli;      /* Default: 0.                       Number of RHS                                                      */
  marpaWrapperSymbolArrayp_t *rhsSymbolArraypp; /* Default: NULL.                    RHS symbols as returned by marpaWrapperSymbol_newp()               */
  int                         ranki;            /* Default: 0.                       Rank                                                               */
  marpaWrapperBool_t          nullRanksHighb;   /* Default: MARPAWRAPPER_BOOL_FALSE. Null variant pattern                                               */

  marpaWrapperBool_t          sequenceb;        /* Default: MARPAWRAPPER_BOOL_FALSE. Sequence ?                                                         */
  marpaWrapperSymbol_t       *separatorSymbolp; /* Default: NULL.                    Eventual separator symbol as returned by marpaWrapperSymbol_newp() */
  marpaWrapperBool_t          properb;          /* Default: MARPAWRAPPER_BOOL_FALSE. Proper flag                                                        */
  int                         minimumi;         /* Default: 0.                       Mininimum - must be 0 or 1                                         */
} marpaWrapperRuleOption_t;

/**************************/
/* Constructor/destructor */
/**************************/
typedef struct marpaWrapperOption {
  int                         (*versionip)[3];        /* Default: NULL                                                             */
  genericLogger_t             *genericLoggerp;        /* Default: NULL                                                             */
  marpaWrapperEventCallback_t  eventCallbackp;        /* Default: NULL                                                             */
  marpaWrapperUserData_t      *eventCallbackDatavp;   /* Default: NULL                                                             */
  marpaWrapperBool_t           warningIsErrorb;       /* Default: MARPAWRAPPER_BOOL_FALSE. Have precedence over warningIsIgnoredb  */
  marpaWrapperBool_t           warningIsIgnoredb;     /* Default: MARPAWRAPPER_BOOL_FALSE                                          */
  marpaWrapperBool_t           unsortedEventsb;       /* Default: MARPAWRAPPER_BOOL_FALSE. Completed, then nulled, then predicted. */
} marpaWrapperOption_t;

MARPAWRAPPER_EXPORT marpaWrapper_t           *marpaWrapper_newp    (const marpaWrapperOption_t *marpaWrapperOptionp);
MARPAWRAPPER_EXPORT void                      marpaWrapper_destroyv(marpaWrapper_t *marpaWrapperp);

/**************************************************/
/* Phase 1: Grammar definition and precomputation */
/**************************************************/
MARPAWRAPPER_EXPORT marpaWrapperSymbol_t     *marpaWrapper_addSymbolp (marpaWrapper_t *marpaWrapperp, const marpaWrapperSymbolOption_t *marpaWrapperSymbolOption);
MARPAWRAPPER_EXPORT marpaWrapperRule_t       *marpaWrapper_addRulep   (marpaWrapper_t *marpaWrapperp, const marpaWrapperRuleOption_t *marpaWrapperRuleOptionp);
MARPAWRAPPER_EXPORT marpaWrapperBool_t        marpaWrapper_precomputeb(marpaWrapper_t *marpaWrapperp);

/***********************/
/* Phase 2: Recognizer */
/***********************/
typedef struct marpaWrapperProgress {
  int                 marpaEarleySetIdi;
  int                 marpaEarleySetIdOrigini;
  marpaWrapperRule_t *marpaWrapperRulep;
  int                 positioni;
} marpaWrapperProgress_t;

typedef marpaWrapperProgress_t *marpaWrapperProgressArrayp_t;

/* For those wanting to have manual control on recognizer */
MARPAWRAPPER_EXPORT marpaWrapperRecognizer_t *marpaWrapperRecognizer_newp                 (const marpaWrapper_t *marpaWrapperp);
MARPAWRAPPER_EXPORT marpaWrapperBool_t        marpaWrapperRecognizer_alternativeb         (const marpaWrapperRecognizer_t *marpaWrapperRecognizerp, const marpaWrapperSymbol_t *marpaWrapperSymbolp, const int value, const int length);
MARPAWRAPPER_EXPORT marpaWrapperBool_t        marpaWrapperRecognizer_completeb            (const marpaWrapperRecognizer_t *marpaWrapperRecognizerp);
MARPAWRAPPER_EXPORT marpaWrapperBool_t        marpaWrapperRecognizer_readb                (const marpaWrapperRecognizer_t *marpaWrapperRecognizerp, const marpaWrapperSymbol_t *marpaWrapperSymbolp, const int value, const int length);
MARPAWRAPPER_EXPORT marpaWrapperBool_t        marpaWrapperRecognizer_event_activateb      (const marpaWrapperRecognizer_t *marpaWrapperRecognizerp, const marpaWrapperSymbol_t *marpaWrapperSymbolp, const int eventSeti, const marpaWrapperBool_t onb);
MARPAWRAPPER_EXPORT marpaWrapperBool_t        marpaWrapperRecognizer_terminals_expectedb  (const marpaWrapperRecognizer_t *marpaWrapperRecognizerp, size_t *nMarpaWrapperSymbolArraypip, marpaWrapperSymbolArrayp_t **marpaWrapperSymbolArrayppp);
MARPAWRAPPER_EXPORT marpaWrapperBool_t        marpaWrapperRecognizer_terminal_is_expectedb(const marpaWrapperRecognizer_t *marpaWrapperRecognizerp, const marpaWrapperSymbol_t *marpaWrapperSymbolp, marpaWrapperBool_t *isExpectedbp);
MARPAWRAPPER_EXPORT marpaWrapperBool_t        marpaWrapperRecognizer_progressb            (const marpaWrapperRecognizer_t *marpaWrapperRecognizerp, const int starti, const int endi, size_t *nmarpaWrapperProgressip, marpaWrapperProgressArrayp_t **marpaWrapperProgressppp);
MARPAWRAPPER_EXPORT void                      marpaWrapperRecognizer_progress_freev       (const marpaWrapperRecognizer_t *marpaWrapperRecognizerp, size_t *nmarpaWrapperProgressip, marpaWrapperProgressArrayp_t **marpaWrapperProgressppp);
MARPAWRAPPER_EXPORT void                      marpaWrapperRecognizer_destroyv             (marpaWrapperRecognizer_t *marpaWrapperRecognizerp);

typedef marpaWrapperBool_t (*marpaWrapper_readerCallback_t)        (const marpaWrapperUserData_t *readerCallbackDatavp, marpaWrapperBool_t *endOfInputbp);
typedef marpaWrapperBool_t (*marpaWrapper_isLexemebCallback_t)     (const marpaWrapperUserData_t *marpaWrapperSymbolOptionDatavp, size_t *lengthlp);
/* If there is more than one possible alternative, marpaWrapper_lexemeValuebCallback() will be called with one of the symbol candidates, once */
typedef marpaWrapperBool_t (*marpaWrapper_lexemeValuebCallback_t)  (const marpaWrapperUserData_t *marpaWrapperSymbolOptionDatavp, int *lexemeValueip, int *lexemeLengthip);
typedef marpaWrapperBool_t (*marpaWrapper_ruleToCharsbCallback_t)  (const marpaWrapperUserData_t *marpaWrapperRuleOptionDatavp, const char **rulesp);
typedef marpaWrapperBool_t (*marpaWrapper_symbolToCharsbCallback_t)(const marpaWrapperUserData_t *marpaWrapperSymbolOptionDatavp, const char **symbolsp);

typedef struct marpaWrapperRecognizerOption {
  marpaWrapperBool_t                    remainingDataIsOkb;                                      /* Default: MARPAWRAPPER_BOOL_FALSE */
  marpaWrapperBool_t                    longestAcceptableTokenMatchb;                            /* Default: MARPAWRAPPER_BOOL_TRUE */
  marpaWrapperBool_t                    longestAcceptableTokensShareTheSameValueAndLengthb;      /* Default: MARPAWRAPPER_BOOL_TRUE */
  marpaWrapper_readerCallback_t         readerCallbackp;                                         /* Default: NULL. Must be overwriten by caller */
  marpaWrapperUserData_t               *readerDatavp;                                            /* Default: NULL */
  marpaWrapper_isLexemebCallback_t      isLexemebCallbackp;                                      /* Default: NULL. Must be overwriten by caller */
  marpaWrapper_lexemeValuebCallback_t   lexemeValuebCallbackp;                                   /* Default: NULL. Must be overwriten by caller */
#ifndef MARPAWRAPPER_NTRACE
  marpaWrapper_ruleToCharsbCallback_t   ruleToCharsbCallbackp;                                   /* Default: NULL. Must be overwriten by caller */
  marpaWrapper_symbolToCharsbCallback_t symbolToCharsbCallbackp;                                 /* Default: NULL. Must be overwriten by caller */
#endif
} marpaWrapperRecognizerOption_t;

MARPAWRAPPER_EXPORT marpaWrapperBool_t marpaWrapper_r_recognizeb(marpaWrapper_t *marpaWrapperp, const marpaWrapperRecognizerOption_t *marpaWrapperRecognizerOptionp);

/******************/
/* Phase 3: Value */
/******************/
typedef struct marpaWrapperValueOption {
  /* Ordering options */
  marpaWrapperBool_t                     highRankOnlyb;                          /* Default: MARPAWRAPPER_BOOL_TRUE  */
  marpaWrapperBool_t                     orderByRankb;                           /* Default: MARPAWRAPPER_BOOL_TRUE  */
  marpaWrapperBool_t                     ambiguityb;                             /* Default: MARPAWRAPPER_BOOL_TRUE  */
  marpaWrapperBool_t                     nullb;                                  /* Default: MARPAWRAPPER_BOOL_TRUE  */
  /* Stack manipulation */
  marpaWrapperValueRuleCallback_t        valueRuleCallbackp;                     /* Default: NULL                    */
  marpaWrapperUserData_t                *valueRuleCallbackDatavp;                /* Default: NULL                    */
  marpaWrapperValueSymbolCallback_t      valueSymbolCallbackp;                   /* Default: NULL                    */
  marpaWrapperUserData_t                *valueSymbolCallbackDatavp;              /* Default: NULL                    */
  marpaWrapperValueNullingCallback_t     valueNullingCallbackp;                  /* Default: NULL                    */
  marpaWrapperUserData_t                *valueNullingCallbackDatavp;             /* Default: NULL                    */
  marpaWrapperValueResultCallback_t      valueResultCallbackp;                   /* Default: NULL                    */
  marpaWrapperUserData_t                *valueResultCallbackDatavp;              /* Default: NULL                    */
} marpaWrapperValueOption_t;

/* marpaWrapperStackOptionp is mandatory, so there is no default */
typedef struct marpaWrapperStackOption {
  size_t                                 stackElementSizei;                      /* Default: 0. Must be > 0          */
  marpaWrapperStackElementFreeCallback_t stackElementFreeCallbackp;              /* Default: NULL.                   */
  marpaWrapperUserData_t                *stackElementFreeCallbackUserDatap;      /* Default: NULL                    */
  marpaWrapperStackElementCopyCallback_t stackElementCopyCallbackp;              /* Default: NULL                    */
  marpaWrapperUserData_t                *stackElementCopyCallbackUserDatap;      /* Default: NULL                    */
} marpaWrapperStackOption_t;

MARPAWRAPPER_EXPORT marpaWrapperBool_t        marpaWrapper_vb(const marpaWrapperRecognizer_t *marpaWrapperRecognizerp, const marpaWrapperValueOption_t *marpaWrapperValueOptionp, const marpaWrapperStackOption_t *marpaWrapperStackOptionp);

/***********************************************************************************/
/* Options constructors/destructors and helpers in case of allocation on the stack */
/***********************************************************************************/
MARPAWRAPPER_EXPORT marpaWrapperOption_t       *marpaWrapperOption_newp            (void);
MARPAWRAPPER_EXPORT marpaWrapperBool_t          marpaWrapperOption_defaultb        (marpaWrapperOption_t *marpaWrapperOptionp);
MARPAWRAPPER_EXPORT void                        marpaWrapperOption_destroyv        (marpaWrapperOption_t *marpaWrapperOptionp);

MARPAWRAPPER_EXPORT marpaWrapperSymbolOption_t *marpaWrapperSymbolOption_newp      (void);
MARPAWRAPPER_EXPORT marpaWrapperBool_t          marpaWrapperSymbolOption_defaultb  (marpaWrapperSymbolOption_t *marpaWrapperSymbolOptionp);
MARPAWRAPPER_EXPORT void                        marpaWrapperSymbolOption_destroyv  (marpaWrapperSymbolOption_t *marpaWrapperSymbolOptionp);

MARPAWRAPPER_EXPORT marpaWrapperRecognizerOption_t *marpaWrapperRecognizerOption_newp    (void);
MARPAWRAPPER_EXPORT marpaWrapperBool_t              marpaWrapperRecognizerOption_defaultb(marpaWrapperRecognizerOption_t *marpaWrapperRecognizerOptionp);
MARPAWRAPPER_EXPORT void                            marpaWrapperRecognizerOption_destroyv(marpaWrapperRecognizerOption_t *marpaWrapperRecognizerOptionp);

MARPAWRAPPER_EXPORT marpaWrapperRuleOption_t   *marpaWrapperRuleOption_newp        (void);
MARPAWRAPPER_EXPORT marpaWrapperBool_t          marpaWrapperRuleOption_defaultb    (marpaWrapperRuleOption_t *marpaWrapperRuleOptionp);
MARPAWRAPPER_EXPORT void                        marpaWrapperRuleOption_destroyv    (marpaWrapperRuleOption_t *marpaWrapperRuleOptionp);

MARPAWRAPPER_EXPORT marpaWrapperValueOption_t  *marpaWrapperValueOption_newp       (void);
MARPAWRAPPER_EXPORT marpaWrapperBool_t          marpaWrapperValueOption_defaultb   (marpaWrapperValueOption_t *marpaWrapperValueOptionp);
MARPAWRAPPER_EXPORT void                        marpaWrapperValueOption_destroyv   (marpaWrapperValueOption_t *marpaWrapperValueOptionp);

MARPAWRAPPER_EXPORT marpaWrapperStackOption_t  *marpaWrapperStackOption_newp       (void);
MARPAWRAPPER_EXPORT marpaWrapperBool_t          marpaWrapperStackOption_defaultb   (marpaWrapperStackOption_t *marpaWrapperStackOptionp);
MARPAWRAPPER_EXPORT void                        marpaWrapperStackOption_destroyv   (marpaWrapperStackOption_t *marpaWrapperStackOptionp);

/* Generic getter definition */
#define MARPAWRAPPER_GENERATE_GETTER_DECLARATION(prefix, externalType, externalName) \
  MARPAWRAPPER_EXPORT externalType prefix##_##externalName##_get(const prefix##_t *prefix##p)

/*************************************************************************************/
/* Avdanced users will want to play themselves with Marpa objects                    */
/* The user application will have to #include "marpa.h" and typecast correspondingly */
/* For ever Marpa_xxx variable.                                                      */
/*************************************************************************************/

/***************************************************************************************/
/* From a wrapper opaque pointer, get size of/array of opaque symbol and rule pointers */
/***************************************************************************************/
MARPAWRAPPER_GENERATE_GETTER_DECLARATION(marpaWrapper          ,                  const void *, Marpa_Config);
MARPAWRAPPER_GENERATE_GETTER_DECLARATION(marpaWrapper          ,                  const void *, Marpa_Grammar);
MARPAWRAPPER_GENERATE_GETTER_DECLARATION(marpaWrapper          ,       const genericLogger_t *, genericLoggerp);
MARPAWRAPPER_GENERATE_GETTER_DECLARATION(marpaWrapper          ,                  const size_t, nMarpaWrapperSymboli);
MARPAWRAPPER_GENERATE_GETTER_DECLARATION(marpaWrapper          , const marpaWrapperSymbol_t **, marpaWrapperSymbolpp);
MARPAWRAPPER_GENERATE_GETTER_DECLARATION(marpaWrapper          ,                  const size_t, nMarpaWrapperRulei);
MARPAWRAPPER_GENERATE_GETTER_DECLARATION(marpaWrapper          ,   const marpaWrapperRule_t **, marpaWrapperRulepp);
MARPAWRAPPER_GENERATE_GETTER_DECLARATION(marpaWrapper          ,    const marpaWrapperOption_t, marpaWrapperOption);

MARPAWRAPPER_GENERATE_GETTER_DECLARATION(marpaWrapperRecognizer,                  const void *, Marpa_Recognizer);
MARPAWRAPPER_GENERATE_GETTER_DECLARATION(marpaWrapperRecognizer,        const marpaWrapper_t *, marpaWrapperp);

MARPAWRAPPER_GENERATE_GETTER_DECLARATION(marpaWrapperSymbol    ,                  const void *, datavp);
MARPAWRAPPER_GENERATE_GETTER_DECLARATION(marpaWrapperSymbol    ,            const unsigned int, Marpa_Symbol_ID);

MARPAWRAPPER_GENERATE_GETTER_DECLARATION(marpaWrapperRule      ,                  const void *, datavp);
MARPAWRAPPER_GENERATE_GETTER_DECLARATION(marpaWrapperRule      ,            const unsigned int, Marpa_Rule_ID);


#endif /* MARPAWRAPPER_INTERNAL_MARPAWRAPPER_H */
