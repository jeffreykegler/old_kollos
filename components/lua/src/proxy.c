/*
* proxy.c
* lexer proxy for Lua parser -- implements __FILE__ and __LINE__
* Luiz Henrique de Figueiredo
* This code is hereby placed in the public domain.
* Add <<#include "proxy.c">> just before the definition of luaX_next in llex.c
*/

/*
 * Luiz's code changed, per his suggestion, to include some polishing
 * the name for __FILE__, taken from luaU_undump.
 * -- Jeffrey Kegler
 */

#include <string.h>

static int nexttoken(LexState *ls, SemInfo *seminfo)
{
  int t = llex (ls, seminfo);
  if (t == TK_NAME)
    {
      if (strcmp (getstr (seminfo->ts), "__FILE__") == 0)
	{
	  const char *name = ls->source;
	  t = TK_STRING;
	  if (*name == '@' || *name == '=')
	    name = name + 1;
	  else if (*name == LUA_SIGNATURE[0])
	    name = "binary string";
	  seminfo->ts = name;
	}
      else if (strcmp (getstr (seminfo->ts), "__LINE__") == 0)
	{
	  t = TK_NUMBER;
	  seminfo->r = ls->linenumber;
	}
    }
  return t;
}

#define llex nexttoken
