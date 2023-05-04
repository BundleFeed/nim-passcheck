# Package

version       = "0.1.0"
author        = "Geoffrey Picron"
description   = "Library to test and analyses password strength (mainly using dropbox zxcvbn)"
license       = "(MIT or Apache-2.0)"
srcDir        = "src"
installExt    = @["nim"]
bin           = @["passcheck"]


# Dependencies

requires "nim >= 1.6.12"
requires "nimterop >= 0.6.13"

let projectDir = getCurrentDir()
let tmpDir = projectDir & "/tmp"

# Build
task updateWrapper, "Generate the wrapper":
  echo "Generating wrapper"
  exec "nimble c -o:" & tmpDir & "/generate src/passcheck/private/generate.nim"
  exec tmpDir & "/generate"

taskRequires "configureInstall", "nimterop >= 0.6.13"

task configureInstall, "Download and configure zxcvbn":
  exec "nimble c -o:" & tmpDir & "/configure passcheck/private/configure.nim"
  exec tmpDir & "/configure " & projectDir & "/passcheck/zxcvbn"


before install:
  configureInstallTask()

proc runBrowserWasmTest(test: string, mode = "debug") =
  exec "nim c -d:emscripten -d:" & mode & " --threads:off --passL:'--emrun' -o:build/browser/" & test & ".html tests/" & test & ".nim"
  exec "emrun --browser=chrome --kill_exit --browser_args='--headless  --remote-debugging-port=0 --disable-gpu --disable-software-rasterizer' build/browser/" & test & ".html"

proc runNodeJsWasmTest(test: string, mode = "debug") =
  exec "nim c -d:emscripten -d:" & mode & " --threads:off --passL:'--emrun' -o:build/nodejs/" & test & ".js tests/" & test & ".nim"
  exec "node  build/nodejs/" & test & ".js"

proc runNativeTest(test: string, mode = "debug") =
  exec "nim c -d:" & mode & " --threads:off -o:build/native/" & test & " tests/" & test & ".nim"
  exec "build/native/" & test

import std/[os, strutils]

task test, "Run tests in the all supported environments":
  for test in listFiles("tests"):
    if test.extractFilename.startsWith("test") and test.endsWith(".nim"):
      let name = test.extractFilename.replace(".nim", "")
      runNativeTest(name)
      runNativeTest(name, "release")
  for test in listFiles("tests"):
    if test.extractFilename.startsWith("test") and test.endsWith(".nim"):
      let name = test.extractFilename.replace(".nim", "")
      runNodeJsWasmTest(name)
      runNodeJsWasmTest(name, "release")
  for test in listFiles("tests"):
    if test.extractFilename.startsWith("test") and test.endsWith(".nim"):
      let name = test.extractFilename.replace(".nim", "")
      runBrowserWasmTest(name)
      runBrowserWasmTest(name, "release")
