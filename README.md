Assorted scripts for elmer development
--------------------------------------

## Contents

* `build.sh`: script that eases creating elmer builds given precache/toolchain etc.
  Usage: see `./build.sh -h`.
  Dependencies: bash, getopt, cmake, make.
* `packtests.sh`: pack ctest output in a minimal uniform manner.
  Usage: Run `packtests.sh <buildname>` in build directory to produce `.tar.gz` file.
  Dependencies: bash, tar, gzip.
* `get_times.py`: read tests packed with `packtests.sh`.
  Usage: `get_times.py <tests.tar.gz>`.
  Dependencies: python3, tarfile package.


## License


```
Copyright (c) 2017 CSC - IT Center for Science

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
