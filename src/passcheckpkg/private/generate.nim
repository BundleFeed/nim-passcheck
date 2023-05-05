# Copyright 2023 Geoffrey Picron.
# SPDX-License-Identifier: (MIT or Apache-2.0)

import nimterop/build/shell
import nimterop/cimport
import std/[os, strutils, pathnorm]
import configure

const projectDir = pathnorm.normalizePath(gorge("pwd") / ".." / ".." / "..")

echo "projectDir is ", projectDir

const buildDir = projectDir / "src" / "passcheckpkg" / "zxcvbn_abi"
const zxcvbnExpandedDir = buildDir / "zxcvbn-c-2.5"

# this is relative to the current file
  
const zxcvbnSrcDir = zxcvbnExpandedDir


static: 
  downloadAndConfigure(buildDir)


static:
  cDebug()
  
  

cIncludeDir(@[zxcvbnSrcDir])

cCompile(zxcvbnSrcDir / "zxcvbn.c")

const generatedFile = buildDir / "generated.nim"

cImport(zxcvbnSrcDir / "zxcvbn.h", recurse=true, flags="-H", nimfile= generatedFile)


echo "Generated binding for zxcvbn"

const absolutePath = (buildDir / "zxcvbn-c-2.5").normalizePath()


var content = generatedFile.readFile().splitLines()

content[1] = "import std/os"
content[2] = """const zxcvbnPath = currentSourcePath().parentDir() / "zxcvbn-c-2.5""""

for i in 0..<content.len:
  content[i] = content[i].replace(absolutePath, """" & zxcvbnPath & """")
  content[i] = content[i].replace("UserDict: UncheckedArray[cstring]", "UserDict: ptr UncheckedArray[cstring]")


generatedFile.writeFile(content.join("\n"))

