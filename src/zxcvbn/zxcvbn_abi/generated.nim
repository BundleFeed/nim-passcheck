# Generated @ 2023-05-04T13:51:38+02:00
import std/os
const zxcvbnPath = currentSourcePath().parentDir() / "zxcvbn-c-2.5"

{.push hint[ConvFromXtoItselfNotNeeded]: off.}
import macros

macro defineEnum(typ: untyped): untyped =
  result = newNimNode(nnkStmtList)

  # Enum mapped to distinct cint
  result.add quote do:
    type `typ`* = distinct cint

  for i in ["+", "-", "*", "div", "mod", "shl", "shr", "or", "and", "xor", "<", "<=", "==", ">", ">="]:
    let
      ni = newIdentNode(i)
      typout = if i[0] in "<=>": newIdentNode("bool") else: typ # comparisons return bool
    if i[0] == '>': # cannot borrow `>` and `>=` from templates
      let
        nopp = if i.len == 2: newIdentNode("<=") else: newIdentNode("<")
      result.add quote do:
        proc `ni`*(x: `typ`, y: cint): `typout` = `nopp`(y, x)
        proc `ni`*(x: cint, y: `typ`): `typout` = `nopp`(y, x)
        proc `ni`*(x, y: `typ`): `typout` = `nopp`(y, x)
    else:
      result.add quote do:
        proc `ni`*(x: `typ`, y: cint): `typout` {.borrow.}
        proc `ni`*(x: cint, y: `typ`): `typout` {.borrow.}
        proc `ni`*(x, y: `typ`): `typout` {.borrow.}
    result.add quote do:
      proc `ni`*(x: `typ`, y: int): `typout` = `ni`(x, y.cint)
      proc `ni`*(x: int, y: `typ`): `typout` = `ni`(x.cint, y)

  let
    divop = newIdentNode("/")   # `/`()
    dlrop = newIdentNode("$")   # `$`()
    notop = newIdentNode("not") # `not`()
  result.add quote do:
    proc `divop`*(x, y: `typ`): `typ` = `typ`((x.float / y.float).cint)
    proc `divop`*(x: `typ`, y: cint): `typ` = `divop`(x, `typ`(y))
    proc `divop`*(x: cint, y: `typ`): `typ` = `divop`(`typ`(x), y)
    proc `divop`*(x: `typ`, y: int): `typ` = `divop`(x, y.cint)
    proc `divop`*(x: int, y: `typ`): `typ` = `divop`(x.cint, y)

    proc `dlrop`*(x: `typ`): string {.borrow.}
    proc `notop`*(x: `typ`): `typ` {.borrow.}


{.experimental: "codeReordering".}
{.passC: "-I" & zxcvbnPath & "".}
{.compile: "" & zxcvbnPath & "/zxcvbn.c".}
defineEnum(ZxcTypeMatch_t) ## ```
                           ##   Enum for the types of match returned in the Info arg to ZxcvbnMatch
                           ## ```
const
  NON_MATCH* = (0).ZxcTypeMatch_t ## ```
                                  ##   0
                                  ## ```
  BRUTE_MATCH* = (NON_MATCH + 1).ZxcTypeMatch_t ## ```
                                                ##   1
                                                ## ```
  DICTIONARY_MATCH* = (BRUTE_MATCH + 1).ZxcTypeMatch_t ## ```
                                                       ##   2
                                                       ## ```
  DICT_LEET_MATCH* = (DICTIONARY_MATCH + 1).ZxcTypeMatch_t ## ```
                                                           ##   3
                                                           ## ```
  USER_MATCH* = (DICT_LEET_MATCH + 1).ZxcTypeMatch_t ## ```
                                                     ##   4
                                                     ## ```
  USER_LEET_MATCH* = (USER_MATCH + 1).ZxcTypeMatch_t ## ```
                                                     ##   5
                                                     ## ```
  REPEATS_MATCH* = (USER_LEET_MATCH + 1).ZxcTypeMatch_t ## ```
                                                        ##   6
                                                        ## ```
  SEQUENCE_MATCH* = (REPEATS_MATCH + 1).ZxcTypeMatch_t ## ```
                                                       ##   7
                                                       ## ```
  SPATIAL_MATCH* = (SEQUENCE_MATCH + 1).ZxcTypeMatch_t ## ```
                                                       ##   8
                                                       ## ```
  DATE_MATCH* = (SPATIAL_MATCH + 1).ZxcTypeMatch_t ## ```
                                                   ##   9
                                                   ## ```
  YEAR_MATCH* = (DATE_MATCH + 1).ZxcTypeMatch_t ## ```
                                                ##   10
                                                ## ```
  LONG_PWD_MATCH* = (YEAR_MATCH + 1).ZxcTypeMatch_t ## ```
                                                    ##   11
                                                    ## ```
  MULTIPLE_MATCH* = (32).ZxcTypeMatch_t ## ```
                                        ##   Added to above to indicate matching part has been repeated
                                        ## ```
type
  ZxcMatch* {.bycopy.} = object
    Begin*: cint             ## ```
                             ##   Char position of begining of match
                             ## ```
    Length*: cint            ## ```
                             ##   Number of chars in the match
                             ## ```
    Entrpy*: cdouble         ## ```
                             ##   The entropy of the match
                             ## ```
    MltEnpy*: cdouble ## ```
                      ##   Entropy with additional allowance for multipart password
                      ## ```
    Type*: ZxcTypeMatch_t    ## ```
                             ##   Type of match (Spatial/Dictionary/Order/Repeat)
                             ## ```
    Next*: ptr ZxcMatch      ## ```
                             ##   Type of match (Spatial/Dictionary/Order/Repeat)
                             ## ```
  
  ZxcMatch_t* = ZxcMatch ## ```
                         ##   As the dictionary data is included in the source, define these functions to do nothing.
                         ## ```
proc ZxcvbnMatch*(Passwd: cstring; UserDict: ptr UncheckedArray[cstring];
                  Info: ptr ptr ZxcMatch_t): cdouble {.importc, cdecl.}
  ## ```
                                                                       ##   *******************************************************************************
                                                                       ##    The main password matching function. May be called multiple times.
                                                                       ##    The parameters are:
                                                                       ##     Passwd      The password to be tested. Null terminated string.
                                                                       ##     UserDict    User supplied dictionary words to be considered particulary bad. Passed
                                                                       ##                  as a pointer to array of string pointers, with null last entry (like
                                                                       ##                  the argv parameter to main()). May be null or point to empty array when
                                                                       ##                  there are no user dictionary words.
                                                                       ##     Info        The address of a pointer variable to receive information on the parts
                                                                       ##                  of the password. This parameter can be null if no information is wanted.
                                                                       ##                  The data should be freed by calling ZxcvbnFreeInfo().
                                                                       ##    
                                                                       ##    Returns the entropy of the password (in bits).
                                                                       ## ```
proc ZxcvbnFreeInfo*(Info: ptr ZxcMatch_t) {.importc, cdecl.}
  ## ```
                                                             ##   *******************************************************************************
                                                             ##    Free the data returned in the Info parameter to ZxcvbnMatch().
                                                             ## ```
{.pop.}
