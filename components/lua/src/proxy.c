/*
* proxy.c
* lexer proxy for Lua parser -- implements __FILE__ and __LINE__
* Luiz Henrique de Figueiredo
* This code is hereby placed in the public domain.
* Add <<#include "proxy.c">> just before the definition of luaX_next in llex.c
*/

#include <string.h>

static int nexttoken(LexState *ls, SemInfo *seminfo)
{
  int t=llex(ls,seminfo);
  if (t==TK_NAME) {
    if (strcmp(getstr(seminfo->ts),"__FILE__")==0) {
      t=TK_STRING;
      seminfo->ts = ls->source;
    }
    else if (strcmp(getstr(seminfo->ts),"__LINE__")==0) {
      t=TK_NUMBER;
      seminfo->r = ls->linenumber;
    }
  }
  return t;
}

#define llex nexttoken
