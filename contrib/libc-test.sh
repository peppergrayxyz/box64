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
        *musl*)
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

cmd_compare() {
    base=$1
    res=$2
    # an empty baseline has no regressions to find
    grep -q '^PASS' "$base" || die "no test passes in the baseline $base"
    regressions=$(awk 'NR == FNR { if ($1 == "PASS") ok[$2] = 1; next }
                       $1 == "PASS" { delete ok[$2] }
                       END { for (t in ok) print t }' "$base" "$res" | sort)
    fixed=$(awk 'NR == FNR { if ($1 != "PASS") bad[$2] = 1; next }
                 $1 == "PASS" && ($2 in bad) { print $2 }' "$base" "$res" | sort)

    echo "baseline: $(grep -c '^PASS' "$base") passed, $(grep -c '^FAIL' "$base") failed"
    echo "result:   $(grep -c '^PASS' "$res") passed, $(grep -c '^FAIL' "$res") failed"
    if [ -n "$fixed" ]; then
        echo "failing in the baseline, passing in the result:"
        echo "$fixed" | sed 's/^/  /'
    fi
    if [ -n "$regressions" ]; then
        echo "passing in the baseline, not in the result:"
        echo "$regressions" | sed 's/^/  /'
        exit 1
    fi
    echo "no regressions"
}

[ $# -ge 1 ] || die "usage: $0 build|run|compare ..."
action=$1
shift
case $action in
    build)   [ $# -eq 1 ] || die "usage: $0 build <libc-test-dir>"; cmd_build "$@" ;;
    run)     [ $# -ge 2 ] || die "usage: $0 run <libc-test-dir> <result-file> [wrapper...]"; cmd_run "$@" ;;
    compare) [ $# -eq 2 ] || die "usage: $0 compare <baseline-file> <result-file>"; cmd_compare "$@" ;;
    *)       die "unknown action: $action" ;;
esac
