// Command msvc_filter_showincludes relativizes output of cl.exe /showincludes.
//
// Work around for https://github.com/bazelbuild/bazel/issues/19733.
//
// Bazel's CppCompile action performs header validation as part of each compile.
// Bazel causes the compiler to dump a complete list of headers included in each
// compilation. Bazel post-processes this output to verify that the action
// did not include files that weren't part of the provided inputs and
// aren't listed in the toolchain's system include directories.
//
// When building with MSVC, Bazel enables the /showincludes flag, which prints
// the list of includes on stdout or stderr (not sure which; Bazel reads both).
// The output contains absolute paths, which is non-hermetic for remote
// execution.
//
// Before performing header validation, Bazel pre-processes the output to
// remove anything that looks like an execroot prefix. Unfortunately,
// Bazel's idea of an execroot prefix doesn't match EngFlow's. Bazel's
// prefix also includes a workspace name, which is not transmitted as part of
// the remote execution protocol, so we can't work around this problem
// on the server side.
//
// Instead, we can configure the C++ toolchain to invoke
// msvc_filter_showincludes instead of cl.exe. This program wraps MSVC,
// invoking it with a hard-coded absolute path. This program filters
// /showincludes output, removing parts of directory paths that look like
// EngFlow Windows execroot directories.
//
// For example, this line:
//
//	Note: including file: C:\worker\work\2\exec\cpp/hello.h
//
// is replaced with:
//
//	Note: including file: cpp/hello.h
//
// Bazel's validation code (HeaderDiscover.java) can still use this output.
// This wrapper makes the action somewhat more hermetic.
package main

import (
	"bytes"
	"context"
	"fmt"
	"os"
	"os/exec"
	"regexp"
	"strings"
)

// MSVCPath is the absolute path to MSVC's cl.exe. It should be set with a -X
// linker flag. With rules_go, that can be done with an x_defs attribute.
var MSVCPath string

func main() {
	if err := run(context.Background(), os.Args[1:]); err != nil {
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		os.Exit(1)
	}
}

func run(ctx context.Context, args []string) error {
	cmd := exec.CommandContext(ctx, MSVCPath, args...)
	stdoutBuf := &bytes.Buffer{}
	stderrBuf := &bytes.Buffer{}
	cmd.Stdout = stdoutBuf
	cmd.Stderr = stderrBuf

	if err := cmd.Run(); err != nil {
		return err
	}

	stdoutFiltered := showIncludesRe.ReplaceAll(stdoutBuf.Bytes(), []byte(showIncludesReplacement))
	stderrFiltered := showIncludesRe.ReplaceAll(stderrBuf.Bytes(), []byte(showIncludesReplacement))
	if _, err := os.Stdout.Write(stdoutFiltered); err != nil {
		return err
	}
	if _, err := os.Stderr.Write(stderrFiltered); err != nil {
		return err
	}

	return nil
}

// showIncludesReplacement is the string to pass to regexp.Regexp.ReplaceAll
// when filtering output. Substrings like $1 expand to numbered match groups.
// This basically drops $2, the EngFlow execroot directory.
var showIncludesReplacement = `$1$3`

// showIncludesRe is the regular expression to match in the output.
// It consists of three match groups with no text in between.
//
// Group 1 matches a prefix like "Note: including file:" followed by
// whitespace. The prefix is translated into 14 languages. The bytes are
// copied from Bazel's ShowIncludesFilter.java.
//
// Group 2 matches the EngFlow execroot directory prefix, ending with \.
// It should be removed.
//
// Group 3 matches the include path within the execroot.
//
// For example, the line:
//
//	Note: including file: C:\worker\work\2\exec\cpp/hello.h
//
// is split into groups:
//
// 1. "Note: including file: "
// 2. "C:\worker\work\2\exec\"
// 3. "cpp/hello.h\n"
var showIncludesRe = (func() *regexp.Regexp {
	if MSVCPath == "" {
		panic("MSVCPath was not set; expected it to be set with -X linker flag (x_defs in Bazel)")
	}

	// Flags:
	// i: case sensitive
	// m: ^ and $ match begin/end of line in addition to begin/end of text.
	buf := &strings.Builder{}
	buf.WriteString("(?im)")

	// Group 1: "Note: including file:"
	buf.WriteString("^((?:")
	sep := ""
	for _, prefixInt8 := range showIncludesPrefixes {
		buf.WriteString(sep)
		sep = "|"
		prefixBytes := make([]byte, len(prefixInt8))
		for i, b := range prefixInt8 {
			prefixBytes[i] = byte(b)
		}
		prefixStr := regexp.QuoteMeta(string(prefixBytes))
		buf.WriteString(prefixStr)
	}
	buf.WriteString(`)[ \t]*)`)

	// Group 2: EngFlow execroot directory.
	buf.WriteString(`([A-Z]:\\.*?\\exec\\)`)

	// Group 3: Path within execroot.
	buf.WriteString(`(.*\n?)`)
	return regexp.MustCompile(buf.String())
})()

// showIncludesPrefixes is "Note: including file:" translated into 14 languages
// and encoded in signed UTF-8. The bytes are copied from Bazel's
// ShowIncludesFilter.java.
var showIncludesPrefixes = [][]int8{
	// English
	{
		78, 111, 116, 101, 58, 32, 105, 110, 99, 108, 117, 100, 105, 110, 103, 32, 102,
		105, 108, 101, 58,
	},
	// Traditional Chinese
	{
		-26, -77, -88, -26, -124, -113, 58, 32, -27, -116, -123, -27, -112, -85, -26, -86,
		-108, -26, -95, -120, 58,
	},
	// Czech
	{
		80, 111, 122, 110, -61, -95, 109, 107, 97, 58, 32, 86, -60, -115, 101, 116, 110,
		-60, -101, 32, 115, 111, 117, 98, 111, 114, 117, 58,
	},
	// German
	{
		72, 105, 110, 119, 101, 105, 115, 58, 32, 69, 105, 110, 108, 101, 115, 101, 110,
		32, 100, 101, 114, 32, 68, 97, 116, 101, 105, 58,
	},
	// French
	{
		82, 101, 109, 97, 114, 113, 117, 101, -62, -96, 58, 32, 105, 110, 99, 108, 117,
		115, 105, 111, 110, 32, 100, 117, 32, 102, 105, 99, 104, 105, 101, 114, -62, -96,
		58,
	},
	// Italian
	{
		78, 111, 116, 97, 58, 32, 102, 105, 108, 101, 32, 105, 110, 99, 108, 117, 115, 111,
	},
	// Japanese
	{
		-29, -125, -95, -29, -125, -94, 58, 32, -29, -126, -92, -29, -125, -77, -29, -126,
		-81, -29, -125, -85, -29, -125, -68, -29, -125, -119, 32, -29, -125, -107, -29,
		-126, -95, -29, -126, -92, -29, -125, -85, 58,
	},
	// Korean
	{
		-20, -80, -72, -22, -77, -96, 58, 32, -19, -113, -84, -19, -107, -88, 32, -19,
		-116, -116, -20, -99, -68, 58,
	},
	// Polish
	{
		85, 119, 97, 103, 97, 58, 32, 119, 32, 116, 121, 109, 32, 112, 108, 105, 107, 117,
		58,
	},
	// Portugeuse
	{
		79, 98, 115, 101, 114, 118, 97, -61, -89, -61, -93, 111, 58, 32, 105, 110, 99,
		108, 117, 105, 110, 100, 111, 32, 97, 114, 113, 117, 105, 118, 111, 58,
	},
	// Russian
	{
		-48, -97, -47, -128, -48, -72, -48, -68, -48, -75, -47, -121, -48, -80, -48, -67,
		-48, -72, -48, -75, 58, 32, -48, -78, -48, -70, -48, -69, -47, -114, -47, -121,
		-48, -75, -48, -67, -48, -72, -48, -75, 32, -47, -124, -48, -80, -48, -71, -48,
		-69, -48, -80, 58,
	},
	// Turkish
	{
		78, 111, 116, 58, 32, 101, 107, 108, 101, 110, 101, 110, 32, 100, 111, 115, 121,
		97, 58,
	},
	// Simplified Chinese
	{
		-26, -77, -88, -26, -124, -113, 58, 32, -27, -116, -123, -27, -112, -85, -26,
		-106, -121, -28, -69, -74, 58,
	},
	// Spanish
	{
		78, 111, 116, 97, 58, 32, 105, 110, 99, 108, 117, 115, 105, -61, -77, 110, 32,
		100, 101, 108, 32, 97, 114, 99, 104, 105, 118, 111, 58,
	},
}
