#!/bin/sh
# Build and run musl's libc-test (https://repo.or.cz/libc-test.git)
set -eu

die() { echo "libc-test.sh: $*" >&2; exit 2; }

cmd_build() {
    dir=$1
    CC=${CC:-cc}
    AR=${AR:-ar}
    RANLIB=${RANLIB:-ranlib}
    cd "$dir"

    cp config.mak.def config.mak
    case $($CC -dumpmachine) in
        *musl* | *android*)
            # drop the "glibc specific settings" block
            sed -i '/^# glibc specific settings/,$d' config.mak ;;
    esac
    printf '%s\n' "CC = $CC" "AR = $AR" "RANLIB = $RANLIB" >> config.mak

    # libc-test has no build-only target: build the binaries and shared
    # objects make would run the tests with. Failing builds are reported as
    # BUILDERROR and skipped, like libc-test does.
    targets=$(make -s debug | sed -n -e 's/^BINS //p' -e 's/^LIBS //p')
    # shellcheck disable=SC2086
    make -k -j"$(nproc)" $targets > build.log 2>&1 || true
    grep '^BUILDERROR' build.log || true

    for t in $(make -s debug | sed -n 's/^BINS //p'); do
        [ -x "$t" ] && echo "$t"
    done | sort > tests.list
    echo "$(wc -l < tests.list) tests built"
    # e.g. no libtest.a: every test fails to link
    if [ ! -s tests.list ]; then
        grep -E '^make: |error:' build.log | grep -v 'not remade' | head -n 20 >&2
        die "no test built, see $dir/build.log"
    fi
}

cmd_run() {
    dir=$1
    out=$(realpath "$2")
    shift 2
    timeout=${LIBC_TEST_TIMEOUT:-10}
    cd "$dir"
    # a glibc guest's own C.UTF-8 (see ci.sh)
    if [ -d locale ]; then LOCPATH=$PWD/locale; export LOCPATH; fi

    : > "$out"
    : > "$out.log"
    while read -r t; do
        # some tests are timing sensitive: a failing test gets one retry
        for try in 1 2; do
            # </dev/null: a test must not read the test list
            rc=0
            timeout -s KILL "$timeout" "$@" "./$t" > "$out.tmp" 2>&1 < /dev/null || rc=$?
            if [ "$rc" -eq 0 ]; then break; fi
        done
        if [ "$rc" -eq 0 ]; then
            echo "PASS $t" >> "$out"
            if [ "$try" -eq 2 ]; then echo "==== $t passed on retry" >> "$out.log"; fi
            continue
        fi
        # math tests exit with their error count, so a status > 128 is not
        # necessarily a signal
        reason="exit $rc"
        if [ "$rc" -eq 137 ]; then reason="$reason, timeout?"; fi
        echo "FAIL $t [$reason]" | tee -a "$out"
        { echo "==== $t [$reason]"; cat "$out.tmp"; } >> "$out.log"
    done < tests.list
    rm -f "$out.tmp"
    echo "$(grep -c '^PASS' "$out") passed, $(grep -c '^FAIL' "$out") failed"
}

# The tests an expected failures file lists for a guest and a host, one
# "<guest> <host> <test> [flaky]" per line: <guest> and <host> are globs on the
# guest's libc and on the host tag (<distro>-<libc>-<toolchain>-<arch>), a flaky
# test is not reported when it passes
expected_failures() {
    sed 's/#.*//' "$1" | while read -r guest host test flag; do
        [ -n "$test" ] || continue
        # shellcheck disable=SC2254 # the columns are globs
        case $2 in $guest) ;; *) continue ;; esac
        # shellcheck disable=SC2254
        case $3 in $host) echo "$test${flag:+ $flag}" ;; esac
    done
}

# compare <baseline> <result> [<xfail> <guest> <host>]
cmd_compare() {
    base=$1
    res=$2
    # an empty baseline has no regressions to find
    grep -q '^PASS' "$base" || die "no test passes in the baseline $base"
    : > "$res.xfail"
    if [ $# -eq 5 ]; then expected_failures "$3" "$4" "$5" > "$res.xfail"; fi
    flaky=$(awk '$2 == "flaky" { print $1 }' "$res.xfail")
    sed -i 's/ .*//' "$res.xfail"

    regressions=$(awk 'NR == FNR { if ($1 == "PASS") ok[$2] = 1; next }
                       $1 == "PASS" { delete ok[$2] }
                       END { for (t in ok) print t }' "$base" "$res" | sort)
    fixed=$(awk 'NR == FNR { if ($1 != "PASS") bad[$2] = 1; next }
                 $1 == "PASS" && ($2 in bad) { print $2 }' "$base" "$res" | sort)
    xfail=$(echo "$regressions" | grep -xF -f "$res.xfail" || true)
    regressions=$(echo "$regressions" | grep -vxF -f "$res.xfail" || true)
    xpass=$(awk '$1 == "PASS" { print $2 }' "$res" | grep -xF -f "$res.xfail" | sort || true)
    if [ -n "$flaky" ]; then xpass=$(echo "$xpass" | grep -vxF "$flaky" || true); fi

    echo "baseline: $(grep -c '^PASS' "$base") passed, $(grep -c '^FAIL' "$base") failed"
    echo "result:   $(grep -c '^PASS' "$res") passed, $(grep -c '^FAIL' "$res") failed"
    list() { if [ -n "$2" ]; then echo "$1"; echo "$2" | sed 's/^/  /'; fi; }
    list "failing in the baseline, passing in the result:" "$fixed"
    list "expected failures (${3:-}):" "$xfail"
    list "expected failures, but passing: remove them from ${3:-}" "$xpass"
    list "passing in the baseline, not in the result:" "$regressions"
    if [ -n "$regressions" ]; then exit 1; fi
    echo "no regressions"
}

[ $# -ge 1 ] || die "usage: $0 build|run|compare ..."
action=$1
shift
case $action in
    build)   [ $# -eq 1 ] || die "usage: $0 build <libc-test-dir>"; cmd_build "$@" ;;
    run)     [ $# -ge 2 ] || die "usage: $0 run <libc-test-dir> <result-file> [wrapper...]"; cmd_run "$@" ;;
    compare) [ $# -eq 2 ] || [ $# -eq 5 ] ||
                 die "usage: $0 compare <baseline-file> <result-file> [<xfail-file> <guest> <host>]"
             cmd_compare "$@" ;;
    *)       die "unknown action: $action" ;;
esac
