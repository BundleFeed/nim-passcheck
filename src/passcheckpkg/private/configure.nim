# Copyright 2023 Geoffrey Picron.
# SPDX-License-Identifier: (MIT or Apache-2.0)
import nimterop/build/shell
import nimterop/cimport
import std/[os, strutils, pathnorm]


proc downloadAndConfigure*(buildDir: string) = 
  let zxcvbnExpandedDir = buildDir / "zxcvbn-c-2.5"

  rmDir(zxcvbnExpandedDir)
  rmFile(buildDir / "v2.5.zip")
  createDir(buildDir)

  downloadUrl("https://github.com/tsyrogit/zxcvbn-c/archive/refs/tags/v2.5.zip", buildDir)

  echo "# Running configure"
  let (output, ret) = execAction("cd " & zxcvbnExpandedDir & " && make dict-src.h")
  if ret != 0:
    raise newException(OSError, "Error running configure")

when isMainModule:
  assert paramCount() == 1, "Expected 1 argument, the install path"
  let installPath = paramStr(1)
  downloadAndConfigure(installPath)
