# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import unittest

import passcheck
test "call evaluatePassword with a password with no details":
  let diagnostic = evaluatePassword("my password", @["my name","my company","my website"])

  check diagnostic.password == "my password"
  check diagnostic.estimation > 9.6 and diagnostic.estimation < 9.7
  check diagnostic.timeToCrack == RangeOfDuration.Seconds
  check diagnostic.entries.len == 0

test "call evaluatePassword with a password with details":
  let diagnostic = evaluatePassword("my password", @["my name","my company","my website"], true)

  check diagnostic.password == "my password"
  check diagnostic.estimation > 9.6 and diagnostic.estimation < 9.7
  check diagnostic.timeToCrack == RangeOfDuration.Seconds
  check diagnostic.entries.len == 3
