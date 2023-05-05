# Copyright 2023 Geoffrey Picron.
# SPDX-License-Identifier: (MIT or Apache-2.0)
import std/os
import configure

static:

  # check is zxcvbn is loaded yet
  let path = currentSourcePath().parentDir / ".." / "zxcvbn_abi" / " zxcvbn-c-2.5"
  if not existsDir(path):
    downloadAndConfigure(currentSourcePath().parentDir / ".." / "zxcvbn_abi")  

