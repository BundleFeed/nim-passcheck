# nim-passcheck

[![License: Apache](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

![Stability: beta](https://img.shields.io/badge/stability-beta-yellow.svg)


This library provides a function to check the strength of a password based on the [Dropbox zxcvbn c implementation](https://github.com/tsyrogit/zxcvbn-c).

It offers too a commnd line tool 'passcheck' to check the strength of a password.

The library is building with emscripten to be used in the browser and nodejs.

## Usage

### Library

```nim
import passcheck

echo evaluatePassword("password", @["my name","my company","my website"])
```

### Command line tool

```bash
$ passcheck "password" "my name" "my company" "my website"
Entropy: 9.63 bits
Crack in seconds
  USER       'my' (entropy: 0.00 bits, multipart entropy: 0.00 bits, repeated: false)
  BRUTE      ' ' (entropy: 5.88 bits, multipart entropy: 7.63 bits, repeated: false)
  DICTIONARY 'password' (entropy: 1.00 bits, multipart entropy: 2.00 bits, repeated: false)
```

## License

### Wrapper License

This repository is licensed and distributed under either of

* MIT license: [LICENSE-MIT](LICENSE-MIT) or http://opensource.org/licenses/MIT

or

* Apache License, Version 2.0, ([LICENSE-APACHEv2](LICENSE-APACHEv2) or http://www.apache.org/licenses/LICENSE-2.0)

at your option. This file may not be copied, modified, or distributed except according to those terms.

### Dependency License

libsodium is licensed under the ISC license. See [their licensing page](https://github.com/jedisct1/libsodium) for further information.

