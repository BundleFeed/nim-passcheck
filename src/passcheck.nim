import ./passcheckpkg/private/check_loaded
import ./passcheckpkg/zxcvbn_abi/generated
import std/[os, strutils, math, times, sequtils]




type SecurityBits = cdouble

const
  MinuteInSeconds = 60.0
  HourInSeconds = MinuteInSeconds * 60
  DayInSeconds = HourInSeconds * 24
  MonthInSeconds = DayInSeconds * 30
  YearInSeconds = DayInSeconds * 365
  DecadeInSeconds = YearInSeconds * 10
  CenturyInSeconds = YearInSeconds * 100


type
  RangeOfDuration* =  enum
    Seconds,
    Minutes,
    Hours,
    Days,
    Months,
    Years,
    Decades,
    Centuries

func bitsToRange(entropy: SecurityBits): RangeOfDuration =
  let averageNumberOfTrialsToGuess = 2.0.pow(entropy - 1.0)
  let duration = averageNumberOfTrialsToGuess / 1e10

  if duration < 2 * MinuteInSeconds:
    result = Seconds
  elif duration < 2 * HourInSeconds:
    result = Minutes
  elif duration < 2 * DayInSeconds:
    result = Hours
  elif duration < 2 * MonthInSeconds:
    result = Days
  elif duration < 2 * YearInSeconds:
    result = Months
  elif duration < 2 * DecadeInSeconds:
    result = Years
  elif duration < 2 * CenturyInSeconds:
    result = Decades
  else:
    result = Centuries

type 
  DiagnosticMatchKind* = enum
    NONE = NON_MATCH,
    BRUTE = BRUTE_MATCH,
    DICTIONARY = DICTIONARY_MATCH,
    DICT_LEET = DICT_LEET_MATCH,
    USER = USER_MATCH,
    USER_LEET = USER_LEET_MATCH,
    REPEATS = REPEATS_MATCH,
    SEQUENCE = SEQUENCE_MATCH,
    SPATIAL = SPATIAL_MATCH,
    DATE = DATE_MATCH,
    YEAR = YEAR_MATCH,
    LONG_PWD = LONG_PWD_MATCH


  DiagnosticEntry* = object
    begin*: int
    length*: int
    entropy*: SecurityBits
    multipartEntropy*: SecurityBits
    kind*: DiagnosticMatchKind
    repeated*: bool

  Diagnostic* = object
    password*: string
    estimation*: SecurityBits
    timeToCrack* : RangeOfDuration
    entries*: seq[DiagnosticEntry]


converter toEntry(match: ZxcMatch): DiagnosticEntry =
  let repeated = (match.Type >= MULTIPLE_MATCH)
  let kind = if repeated: DiagnosticMatchKind(match.Type - MULTIPLE_MATCH) else: DiagnosticMatchKind(match.Type)
    
  DiagnosticEntry(
    begin : match.Begin,
    length : match.Length,
    entropy : match.Entrpy,
    multipartEntropy : match.MltEnpy,
    kind : kind,
    repeated : repeated
  )



func toDiagnostic(matchChain: ptr ZxcMatch_t, password: string, totalEntropy: SecurityBits): Diagnostic =
  var node = matchChain
  var entries = newSeq[DiagnosticEntry]()
  
  while node != nil:
    let match = node[]
    entries.add(match)
    node = match.Next
  
  Diagnostic(
    password : password,
    estimation : totalEntropy,
    timeToCrack : bitsToRange(totalEntropy),
    entries : entries
  )

template `$`*(d: Diagnostic): string =
  var result = ""
  result.add("Entropy: " & d.estimation.formatFloat(ffDecimal, 2) & " bits\n")
  result.add("Crack in " & ($(d.timeToCrack)).toLower & "\n")
  var v = 0.0
  for e in d.entries:
    let match =  "  " & ($e.kind).alignLeft(10) & " '" & d.password[e.begin..e.begin + e.length - 1] & "' (entropy: " & e.entropy.formatFloat(ffDecimal, 2) & " bits, multipart entropy: " & e.multipartEntropy.formatFloat(ffDecimal, 2) & " bits, repeated: " & $e.repeated & ")\n"
    result.add(match)
  result

proc extractTokens(token: string, pool: var seq[string]) =
  var current = ""
  for c in token:
    if c.isAlphaNumeric:
      current.add(c)
    else:
      if current.len > 0:
        pool.add(current)
        current = ""
  if current.len > 0:
    pool.add(current)

proc permutations(s: string): seq[string] =
  if s.len <= 1:
    return @[s]
  else:
    for i in 0 ..< s.len:
      for p in permutations(s[0 ..< i] & s[i + 1 ..< s.len]):
        result.add($(s[i]) & p)
    return result

proc extractInitials(token: string, pool: var seq[string]) =
  ## if token contains multiple words, extract the first letter of each word, then emit all permutations of these letters
  var initials : string
  var current = ""
  for c in token:
    if c.isAlphaNumeric:
      current.add(c)
    else:
      if current.len > 0:
        initials.add(current[0].toLowerAscii)
        current = ""
  if current.len > 0:
    initials.add(current[0].toLowerAscii)
  
  if initials.len > 1:
    for p in permutations(initials):
      pool.add(p)
 
proc extractNgrams(token: string, ngramMinSize: int, pool: var seq[string]) =
  assert ngramMinSize > 0
  if token.len <= ngramMinSize:
    pool.add(token)
  else:
    for i in 0..token.len - ngramMinSize:
      for j in (i + ngramMinSize - 1)..(token.len - 1):
        pool.add(token[i..j])


proc evaluatePassword*(password: string, userWords: seq[string] = @[], detailed = false) : Diagnostic =
  ## Evaluate the strength of a password using the zxcvbn library.
  ## The diagnostic returned contains the entropy estimation, the time to crack.
  ## The time to crack is an estimation of the time it would take to crack the password using a brute force attack in a context 
  ## 
  ## The parameter userWords allows to specify a list of words that are specific to the user and that are not in the dictionary.  It is a good practice
  ## to add the name of the user, the name of the company, the name of the website, etc. to this list.  Previous passwords are also good candidates.
  ## The function preprocess the list of provided string to extract initials, tokens, ngrams, etc.  The zxcvbn library will then be able them.
  ## 
  ## where the password is checkable offline (e.g. a stolen database of hashed passwords) and the hash algorithm is known and fast (like MD5 for instance)
  ## which is the worst case scenario.
  ## Putting a constraints on password strength being larger than Decades is a minimum good practice.
  ## 
  ## Additionnally, if detailed is true, the diagnostic contains the list of all the matches found by the zxcvbn library and their influence on the final entropy score in the password.
  ## 

  var tokens = newSeq[string]()
  for e in userWords:
    var subtokens = newSeq[string]()
    extractTokens(e, subtokens)
    for t in subtokens:
      tokens.add(t)
      extractNgrams(t, 3, tokens)
    extractInitials(e, tokens)
    
  tokens = deduplicate(tokens)
  var userDict = newSeqOfCap[cstring](tokens.len + 1)
  for e in tokens:
    userDict.add(cstring(e))
  userDict.add(nil)

  let ptrUncheckArray = cast[ptr UncheckedArray[cstring]](userDict[0].addr)

  if detailed:
    var ptrZxcMatch_t : ptr ZxcMatch_t
    let entropy = ZxcvbnMatch(cstring(password), ptrUncheckArray, ptrZxcMatch_t.addr)
    result = toDiagnostic(ptrZxcMatch_t, password, entropy)
    ZxcvbnFreeInfo(ptrZxcMatch_t)
  else:
    let entropy = ZxcvbnMatch(cstring(password), ptrUncheckArray, nil)

    result = toDiagnostic(nil, password, entropy)


  
when isMainModule:
  if paramCount() == 0:
    echo "Usage: passcheck [password] [user word1] [user word2] ...\n"
    echo "  Example: passcheck \"my password\" \"my name\" \"my company\" \"my website\""
    quit(1)
  let password = paramStr(1)
  var userWords = newSeq[string]()
  for i in 2 ..< paramCount():
    userWords.add(paramStr(i))

  let diagnostic = evaluatePassword(password, userWords, true)

  echo $diagnostic
