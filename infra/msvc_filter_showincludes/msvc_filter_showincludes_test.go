// Copyright 2023 EngFlow, Inc. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package main

import (
	"testing"

	"github.com/google/go-cmp/cmp"
)

func TestShowIncludesFilter(t *testing.T) {
	for _, test := range []struct {
		name   string
		output string
		want   string
	}{
		{
			name:   "empty",
			output: "",
			want:   "",
		},
		{
			name:   "in_execroot",
			output: `Note: including file: C:\worker\work\2\exec\hello.h`,
			want:   `Note: including file: hello.h`,
		},
		{
			name:   "in_subdir_backslash",
			output: `Note: including file: C:\worker\work\2\exec\cpp\hello.h`,
			want:   `Note: including file: cpp\hello.h`,
		},
		{
			name:   "in_subdir_slash",
			output: `Note: including file: C:\worker\work\2\exec\cpp/hello.h`,
			want:   `Note: including file: cpp/hello.h`,
		},
		{
			name:   "space_preserved",
			output: `Note: including file:   C:\worker\work\2\exec\cpp/hello.h  `,
			want:   `Note: including file:   cpp/hello.h  `,
		},
		{
			name:   "random_unit_name",
			output: `Note: including file: C:\worker\work\abcd123\exec\cpp/hello.h`,
			want:   `Note: including file: cpp/hello.h`,
		},
		{
			name:   "drive_letter",
			output: `Note: including file: D:\worker\work\2\exec\cpp/hello.h`,
			want:   `Note: including file: cpp/hello.h`,
		},
		{
			name:   "spanish:",
			output: `Nota: inclusión del archivo: C:\worker\work\2\exec\cpp/hola.h`,
			want:   `Nota: inclusión del archivo: cpp/hola.h`,
		},
		{
			name: "realisitc",
			output: `
hello.cc
Note: including file: C:\worker\work\2\exec\cpp/hello.h
Note: including file:  C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\string
Note: including file:   C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\yvals_core.h
Note: including file:    C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\vcruntime.h
Note: including file:     C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\sal.h
Note: including file:      C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\concurrencysal.h
Note: including file:     C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\vadefs.h
Note: including file:    C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\xkeycheck.h
Note: including file:   C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\xstring
Note: including file:    C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\iosfwd
Note: including file:     C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\yvals.h
Note: including file:      C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\ucrt\crtdbg.h
Note: including file:       C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\ucrt\corecrt.h
Note: including file:       C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\vcruntime_new_debug.h
Note: including file:        C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\vcruntime_new.h
Note: including file:      C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\crtdefs.h
Note: including file:      C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\use_ansi.h
Note: including file:     C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\cstdio
Note: including file:      C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\ucrt\stdio.h
Note: including file:       C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\ucrt\corecrt_wstdio.h
Note: including file:        C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\ucrt\corecrt_stdio_config.h
Note: including file:     C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\cstring
Note: including file:      C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\ucrt\string.h
Note: including file:       C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\ucrt\corecrt_memory.h
Note: including file:        C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\ucrt\corecrt_memcpy_s.h
Note: including file:         C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\ucrt\errno.h
Note: including file:         C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\vcruntime_string.h
Note: including file:       C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\ucrt\corecrt_wstring.h
Note: including file:     C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\cwchar
Note: including file:      C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\ucrt\wchar.h
Note: including file:       C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\ucrt\corecrt_wconio.h
Note: including file:       C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\ucrt\corecrt_wctype.h
Note: including file:       C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\ucrt\corecrt_wdirect.h
Note: including file:       C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\ucrt\corecrt_wio.h
Note: including file:        C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\ucrt\corecrt_share.h
Note: including file:       C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\ucrt\corecrt_wprocess.h
Note: including file:       C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\ucrt\corecrt_wstdlib.h
Note: including file:       C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\ucrt\corecrt_wtime.h
Note: including file:       C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\ucrt\sys/stat.h
Note: including file:        C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\ucrt\sys/types.h
Note: including file:     C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\xstddef
Note: including file:      C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\cstddef
Note: including file:       C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\ucrt\stddef.h
Note: including file:       C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\xtr1common
Note: including file:      C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\cstdlib
Note: including file:       C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\ucrt\math.h
Note: including file:        C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\ucrt\corecrt_math.h
Note: including file:       C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\ucrt\stdlib.h
Note: including file:        C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\ucrt\corecrt_malloc.h
Note: including file:        C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\ucrt\corecrt_search.h
Note: including file:        C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\limits.h
Note: including file:      C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\initializer_list
Note: including file:    C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\xmemory
Note: including file:     C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\cstdint
Note: including file:      C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\stdint.h
Note: including file:     C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\limits
Note: including file:      C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\cfloat
Note: including file:       C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\ucrt\float.h
Note: including file:      C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\climits
Note: including file:      C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\intrin0.h
Note: including file:       C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\intrin0.inl.h
Note: including file:      C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\isa_availability.h
Note: including file:     C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\new
Note: including file:      C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\exception
Note: including file:       C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\type_traits
Note: including file:       C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\ucrt\malloc.h
Note: including file:       C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\vcruntime_exception.h
Note: including file:        C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\eh.h
Note: including file:         C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\ucrt\corecrt_terminate.h
Note: including file:     C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\xatomic.h
Note: including file:     C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\xutility
Note: including file:      C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\utility
Note: including file:   C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\cctype
Note: including file:    C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\ucrt\ctype.h
`,
			want: `
hello.cc
Note: including file: cpp/hello.h
Note: including file:  C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\string
Note: including file:   C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\yvals_core.h
Note: including file:    C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\vcruntime.h
Note: including file:     C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\sal.h
Note: including file:      C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\concurrencysal.h
Note: including file:     C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\vadefs.h
Note: including file:    C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\xkeycheck.h
Note: including file:   C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\xstring
Note: including file:    C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\iosfwd
Note: including file:     C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\yvals.h
Note: including file:      C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\ucrt\crtdbg.h
Note: including file:       C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\ucrt\corecrt.h
Note: including file:       C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\vcruntime_new_debug.h
Note: including file:        C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\vcruntime_new.h
Note: including file:      C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\crtdefs.h
Note: including file:      C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\use_ansi.h
Note: including file:     C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\cstdio
Note: including file:      C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\ucrt\stdio.h
Note: including file:       C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\ucrt\corecrt_wstdio.h
Note: including file:        C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\ucrt\corecrt_stdio_config.h
Note: including file:     C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\cstring
Note: including file:      C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\ucrt\string.h
Note: including file:       C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\ucrt\corecrt_memory.h
Note: including file:        C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\ucrt\corecrt_memcpy_s.h
Note: including file:         C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\ucrt\errno.h
Note: including file:         C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\vcruntime_string.h
Note: including file:       C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\ucrt\corecrt_wstring.h
Note: including file:     C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\cwchar
Note: including file:      C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\ucrt\wchar.h
Note: including file:       C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\ucrt\corecrt_wconio.h
Note: including file:       C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\ucrt\corecrt_wctype.h
Note: including file:       C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\ucrt\corecrt_wdirect.h
Note: including file:       C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\ucrt\corecrt_wio.h
Note: including file:        C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\ucrt\corecrt_share.h
Note: including file:       C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\ucrt\corecrt_wprocess.h
Note: including file:       C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\ucrt\corecrt_wstdlib.h
Note: including file:       C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\ucrt\corecrt_wtime.h
Note: including file:       C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\ucrt\sys/stat.h
Note: including file:        C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\ucrt\sys/types.h
Note: including file:     C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\xstddef
Note: including file:      C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\cstddef
Note: including file:       C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\ucrt\stddef.h
Note: including file:       C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\xtr1common
Note: including file:      C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\cstdlib
Note: including file:       C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\ucrt\math.h
Note: including file:        C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\ucrt\corecrt_math.h
Note: including file:       C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\ucrt\stdlib.h
Note: including file:        C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\ucrt\corecrt_malloc.h
Note: including file:        C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\ucrt\corecrt_search.h
Note: including file:        C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\limits.h
Note: including file:      C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\initializer_list
Note: including file:    C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\xmemory
Note: including file:     C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\cstdint
Note: including file:      C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\stdint.h
Note: including file:     C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\limits
Note: including file:      C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\cfloat
Note: including file:       C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\ucrt\float.h
Note: including file:      C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\climits
Note: including file:      C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\intrin0.h
Note: including file:       C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\intrin0.inl.h
Note: including file:      C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\isa_availability.h
Note: including file:     C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\new
Note: including file:      C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\exception
Note: including file:       C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\type_traits
Note: including file:       C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\ucrt\malloc.h
Note: including file:       C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\vcruntime_exception.h
Note: including file:        C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\eh.h
Note: including file:         C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\ucrt\corecrt_terminate.h
Note: including file:     C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\xatomic.h
Note: including file:     C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\xutility
Note: including file:      C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\utility
Note: including file:   C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133\include\cctype
Note: including file:    C:\Program Files (x86)\Windows Kits\10\include\10.0.19041.0\ucrt\ctype.h
`,
		},
	} {
		t.Run(test.name, func(t *testing.T) {
			got := showIncludesRe.ReplaceAllString(test.output, showIncludesReplacement)
			if got != test.want {
				t.Errorf("got:\n%s\n\nwant:\n%s\n\ndiff:%s", got, test.want, cmp.Diff(got, test.want))
			}
		})
	}
}
