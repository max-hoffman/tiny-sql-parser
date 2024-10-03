package tiny_parser

import (
	"fmt"
	"github.com/dolthub/vitess/go/vt/sqlparser"
	"github.com/stretchr/testify/require"
	"log"
	"os"
	"runtime/pprof"
	"testing"
)

var result Statement
var err error

func TestRepeat(t *testing.T) {
	file, err := os.CreateTemp("/tmp", "parser-profile")
	if err != nil {
		log.Fatal(err)
	}

	fmt.Println(file.Name())
	if err := pprof.StartCPUProfile(file); err != nil {
		log.Fatal("could not start CPU profile: ", err)
	}
	defer pprof.StopCPUProfile()

	s := "insert into t values (1, '1'), (2, '2')"
	var r Statement
	for i := 0; i < 1; i++ {
		r, err = Parse(s)
		require.NoError(t, err)
		result = r
	}
}

func BenchmarkParser(b *testing.B) {
	s := "insert into t values (1, 1), (2, 2)"

	var r Statement
	for n := 0; n < b.N; n++ {
		// always record the result of Fib to prevent
		// the compiler eliminating the function call.
		r, err = Parse(s)
		require.NoError(b, err)
	}
	// always store the result to a package level variable
	// so the compiler cannot eliminate the Benchmark itself.
	result = r

}

var result2 sqlparser.Statement

func BenchmarkParser2(b *testing.B) {
	s := "insert into t values (1, '1'), (2, '2')"

	var r2 sqlparser.Statement
	for n := 0; n < b.N; n++ {
		// always record the result of Fib to prevent
		// the compiler eliminating the function call.
		r2, err = sqlparser.Parse(s)
		require.NoError(b, err)
	}
	// always store the result to a package level variable
	// so the compiler cannot eliminate the Benchmark itself.
	result2 = r2

}
