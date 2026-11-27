#!/usr/bin/env bash
set -euo pipefail

log() { local color=$1; shift; if [ -t 2 ]; then echo "$(tput setaf "$color")$*$(tput sgr0)" >&2; else echo "$*" >&2; fi; }
info() { log 2 "[info] $*"; }
error() { log 1 "[error] $*"; exit 2; }
usage() {
    cat >&2 <<EOF
Build and test box64 in a container, locally or in CI.

  $0 <distro> <arch> <libc> <toolchain> <command> [args...]

  distro libc toolchain  alpine musl gcc|llvm
                         gentoo glibc|musl gcc|llvm
                         ubuntu glibc gcc|llvm
                         termux bionic llvm

  arch                   x86_64 aarch64 riscv64 loongarch64 ppc64le

  image         build the image from .github/docker/<distro>.Dockerfile
                (UPDATE=1 pulls the base image)

  build         configure and build box64 (BOX32=ON, CMAKE_ARGS, BUILD_DIR)

  test [args]   ctest with the dynarec, then with the interpreter (not on x86_64),
                args go to ctest, e.g. -R printf

  bash [cmd]    run cmd or run smoke test if none given

  run <cmd>     run a command in the container

  libc-test build
                fetch and build musl's libc-test in LIBC_TEST_DIR (default:
                libc-test-<distro>-<libc>-<toolchain>), then run it natively
                for the baseline. LIBC_TEST_REV: the libc-test commit to fetch
                (default: master), an existing LIBC_TEST_DIR is reused

  libc-test run <dir>
                run the libc-test of <dir> (built by "libc-test build", maybe
                for another libc) with box64, fail on tests that pass in the
                baseline but not with box64, unless contrib/libc-test.xfail
                lists them (LIBC_TEST_TIMEOUT: per test, 10s; LIBC_TEST_XFAIL:
                another list, empty for none)

  libc-test fetch [run]
                download the libc-test of <libc> that CI built and ran natively on
                x86_64, from a run of libc-test.yml (default: the last successful
                one of this branch), into LIBC_TEST_DIR. Needs the GitHub CLI (gh).
                A baseline run under qemu differs from a native one, use this
                one to compare with CI. GH_REPO: the repository (default: the one
                the branch is pushed to)

  libc-test rev print the commit LIBC_TEST_REV is at upstream (no container)

  install       install the image's packages (used by the dockerfiles)

e.g.  $0 alpine riscv64 musl llvm image
      BOX32=ON $0 alpine riscv64 musl llvm build
      $0 gentoo x86_64 glibc gcc libc-test build
      $0 alpine aarch64 musl gcc libc-test run libc-test-gentoo-glibc-gcc
      $0 ubuntu x86_64 glibc gcc libc-test fetch
EOF
    exit 2
}

# --- configuration ----------------------------------------------------------

[ $# -ge 5 ] || usage
distro=$1 arch=$2 libc=$3 toolchain=$4 command=$5
shift 5

case $distro/$libc/$toolchain in
    alpine/musl/gcc | alpine/musl/llvm) ;;
    gentoo/glibc/gcc)  stage3=latest ;;
    gentoo/glibc/llvm) stage3=llvm ;;
    gentoo/musl/gcc)   stage3=musl ;;
    gentoo/musl/llvm)  stage3=musl-llvm ;;
    ubuntu/glibc/gcc | ubuntu/glibc/llvm) ;;
    termux/bionic/llvm) ;;
    *) error "unsupported target: $distro $libc $toolchain" ;;
esac

case $arch in
    x86_64)      cmake_flags="-DLD80BITS=1 -DNOALIGN=1" ;;
    aarch64)     cmake_flags="-DARM64=1" ;;
    riscv64)     cmake_flags="-DRV64=ON" ;;
    loongarch64) cmake_flags="-DLARCH64=ON" ;;
    ppc64le)     cmake_flags="-DPPC64LE=ON -DBAD_SIGNAL=ON" ;;
    *) error "unsupported arch: $arch" ;;
esac
# TERMUX implies ANDROID
if [ "$distro" = termux ]; then cmake_flags+=" -DTERMUX=ON"; fi

# a foreign arch (in "install": foreign to the image) is cross-compiled
cross=false
# libc-test fetch and rev run no image
if [ "$arch" != "$(uname -m)" ] && [ "$command ${1:-}" != "libc-test fetch" ] && [ "$command ${1:-}" != "libc-test rev" ]; then
    cross=true
    case $distro/$libc/$toolchain in
        alpine/musl/llvm) ;;
        *) error "$distro $libc $toolchain cannot cross-compile for $arch, use alpine musl llvm" ;;
    esac
fi

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
image=box64-$distro-$libc-$toolchain:$arch
build_dir=${BUILD_DIR:-build-$distro-$libc-$toolchain-$arch}
box32=${BOX32:-OFF}
libc_test_dir=${LIBC_TEST_DIR:-libc-test-$distro-$libc-$toolchain}

# --- install, run by the Dockerfiles ----------------------------------------

toolchain_file=/usr/share/cmake/box64-ci.cmake
# Android has no /usr
if [ "$distro" = termux ]; then toolchain_file=/data/data/com.termux/files/usr/share/cmake/box64-ci.cmake; fi
triple=${arch/ppc64le/powerpc64le}-alpine-linux-musl

install_alpine() {
    local tools=(cmake git make python3)
    local libs=(musl-dev linux-headers argp-standalone libucontext-dev musl-fts-dev
                musl-legacy-error musl-obstack-dev libncursesw)
    case $toolchain in
        gcc)  tools+=(gcc) ;;
        # compiler-rt: clang's builtins, used instead of libgcc
        llvm) tools+=(clang lld llvm) libs+=(compiler-rt) ;;
    esac

    apk add --no-cache "${tools[@]}"
    if $cross; then
        # apk installs the target's libraries into /sysroot, nothing is emulated
        apk add --no-cache "qemu-$arch"
        apk add --no-cache --initdb --root /sysroot --arch "$arch" \
            --keys-dir "/usr/share/apk/keys/$arch" \
            --repositories-file /etc/apk/repositories \
            "${libs[@]}"
        # clang looks for the target's builtins in its own resource dir
        local resource_dir
        resource_dir=$(clang -print-resource-dir)
        cp -a "/sysroot$resource_dir/lib/." "$resource_dir/lib/"
    else
        apk add --no-cache "${libs[@]}"
    fi

    if [ "$arch/$toolchain" = ppc64le/llvm ]; then rebuild_argp; fi
}

# Workaround: Alpine's libargp.a is built with gcc -Os, which on ppc64 calls
# out-of-line FPR save/restore routines (_restfpr_*) that GNU ld synthesizes
# but lld does not. Rebuild the installed version with clang, like Alpine's
# APKBUILD does. Drop this once lld or Alpine handles it.
rebuild_argp() {
    local root=/ version src
    if $cross; then root=/sysroot; fi
    version=$(apk list --root "$root" --installed argp-standalone |
              sed -n 's/^argp-standalone-\([^-]*\)-r.*/\1/p')
    src=/tmp/argp-standalone-$version
    info "rebuilding argp-standalone $version with clang"

    apk add --no-cache --virtual .argp-build autoconf automake
    wget -q -O- "https://github.com/argp-standalone/argp-standalone/archive/refs/tags/$version.tar.gz" |
        tar -xz -C /tmp
    (
        cd "$src"
        autoreconf -if
        # -fgnu89-inline: what Alpine's gnu89-inline.patch adds
        ./configure --host="$triple" \
            CC="clang --target=$triple --sysroot=$root" \
            CFLAGS="-O2 -fPIC -fgnu89-inline" \
            LDFLAGS="-fuse-ld=lld -rtlib=compiler-rt"
        make -j"$(nproc)" AR=llvm-ar RANLIB=llvm-ranlib libargp.a
        install -m644 libargp.a "$root/usr/lib/libargp.a"
    )
    rm -r "$src"
    apk del --no-cache .argp-build
}

install_ubuntu() {
    local packages=(ca-certificates cmake git make python3)
    case $toolchain in
        gcc)  packages+=(gcc libc6-dev) ;;
        llvm) packages+=(clang lld llvm libclang-rt-dev) ;;
    esac
    packages+=(libcrypt-dev)

    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y --no-install-recommends "${packages[@]}"
    rm -rf /var/lib/apt/lists/*
}

# libc and toolchain come with the stage3 image
install_gentoo() {
    local packages=(dev-build/cmake dev-vcs/git)
    if [ "$libc" = musl ]; then
        # glibc extensions as standalone libraries on musl
        packages+=(sys-libs/argp-standalone sys-libs/error-standalone sys-libs/fts-standalone
                   sys-libs/libucontext sys-libs/obstack-standalone)
    fi

    eselect profile show
    echo 'FEATURES="getbinpkg -ipc-sandbox -network-sandbox -pid-sandbox"' >> /etc/portage/make.conf
    # git without rust, which would pull in rust-bin and gcc on llvm profiles
    echo 'dev-vcs/git -rust' > /etc/portage/package.use/box64
    MAKEOPTS="-j$(nproc)" emerge --oneshot --verbose --changed-use "${packages[@]}"
    rm -rf /var/cache/distfiles/* /var/cache/binpkgs/* /var/tmp/portage/*
}

install_termux() {
    apt-get update
    apt-get install -y clang lld llvm cmake make python git libandroid-sysv-semaphore
}

# the Dockerfiles point CMAKE_TOOLCHAIN_FILE here
write_toolchain_file() {
    local cc=${toolchain/llvm/clang}
    mkdir -p "$(dirname "$toolchain_file")"
    {
        echo "set(CMAKE_C_COMPILER $cc)"
        echo "set(CMAKE_ASM_COMPILER $cc)"
        if [ "$toolchain" = llvm ]; then
            echo 'set(CMAKE_EXE_LINKER_FLAGS_INIT "-fuse-ld=lld -rtlib=compiler-rt")'
            echo 'set(CMAKE_SHARED_LINKER_FLAGS_INIT "-fuse-ld=lld -rtlib=compiler-rt")'
        fi
        if $cross; then
            printf '%s\n' \
                "set(CMAKE_SYSTEM_NAME Linux)" \
                "set(CMAKE_SYSTEM_PROCESSOR $arch)" \
                "set(CMAKE_C_COMPILER_TARGET $triple)" \
                "set(CMAKE_ASM_COMPILER_TARGET $triple)" \
                "set(CMAKE_SYSROOT /sysroot)" \
                "set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)" \
                "set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)" \
                "set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)" \
                "set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)"
        fi
    } | tee "$toolchain_file"
}

cmd_install() {
    if $cross; then
        info "installing $distro $libc $toolchain, cross-compiling for $arch"
    else
        info "installing $distro $libc $toolchain for $arch"
    fi
    "install_$distro"
    write_toolchain_file
    git config --system --add safe.directory '*'
}

# --- commands, run on the host ----------------------------------------------

# docker run in the image, as the calling user, with the repository in /src
docker_run() {
    local args=(--rm --user "$(id -u):$(id -g)" -e HOME=/tmp -v "$repo:/src" -w /src)
    # rootless podman maps the user to a subordinate uid, which cannot write to the mounted tree
    if [ "$(docker info --format '{{.Host.Security.Rootless}}' 2>/dev/null)" = true ]; then
        args+=(--userns=keep-id)
    fi
    if [ -t 0 ] && [ -t 1 ]; then args+=(-it); fi
    # runTest.cmake runs the tests through $INTERPRETER
    if $cross; then args+=(-e INTERPRETER="qemu-$arch" -e QEMU_LD_PREFIX=/sysroot); fi
    docker run "${args[@]}" "$image" "$@"
}

cmd_image() {
    local args=(--build-arg ARCH="$arch" --build-arg LIBC="$libc" --build-arg TOOLCHAIN="$toolchain")
    if [ -n "${stage3:-}" ]; then args+=(--build-arg STAGE3="$stage3"); fi
    if [ -n "${UPDATE:-}" ]; then args+=(--pull); fi
    info "building $image"
    docker build "${args[@]}" -t "$image" -f "$repo/.github/docker/$distro.Dockerfile" "$repo/contrib"
}

cmd_build() {
    local cc=${toolchain/llvm/clang} ld=ld
    if [ "$toolchain" = llvm ]; then ld=ld.lld; fi

    # shellcheck disable=SC2016
    docker_run sh -c 'name=$1; shift
                      if [ -r /etc/os-release ]; then . /etc/os-release; name=$PRETTY_NAME; fi
                      echo "$name"
                      for tool; do "$tool" --version | head -1; done' \
        sh "$distro" "$cc" "$ld" cmake

    info "building box64 for $arch in $build_dir (Box32: $box32)"
    # shellcheck disable=SC2086
    docker_run cmake -S . -B "$build_dir" $cmake_flags \
        -DCMAKE_BUILD_TYPE=Release -DBOX32="$box32" -DCI=ON ${CMAKE_ARGS:-}
    docker_run cmake --build "$build_dir" -j"$(nproc)"
}

cmd_test() {
    # runTest.cmake forces BOX64_LOG=0, but segfaults and backtraces still go to
    # stderr, which it prints for failing tests
    local env=(BOX64_SHOWSEGV=1 BOX64_SHOWBT=1)
    local ctest=(ctest --test-dir "$build_dir" -j"$(nproc)" --timeout 300
                 --output-on-failure --no-tests=error)

    case $arch in loongarch64 | ppc64le) ctest+=(-E nocosim) ;; esac
    ctest+=("$@")

    info "ctest"
    docker_run env "${env[@]}" "${ctest[@]}"
    # x86_64 has no dynarec, the first run already used the interpreter
    if [ "$arch" != x86_64 ]; then
        info "ctest with the interpreter (BOX64_DYNAREC=0)"
        docker_run env "${env[@]}" BOX64_DYNAREC=0 "${ctest[@]}"
    fi
}

# cmd_bash [cmd...]: run cmd in the x86_64 bash, without cmd the smoke test
cmd_bash() {
    local qemu=()
    if $cross; then qemu=("qemu-$arch"); fi
    local bash=(env BOX64_NOBANNER=1 "${qemu[@]}" "$build_dir/box64" tests/box64-bash)
    if [ $# -gt 0 ]; then
        docker_run "${bash[@]}" -c "$*"
        return
    fi

    local out expected=$'hello from bash 5\n00042\n/tmp'
    # shellcheck disable=SC2016
    out=$(docker_run "${bash[@]}" -c 'echo "hello from bash ${BASH_VERSINFO[0]}"; printf "%05d\n" 42; cd /tmp && pwd')
    printf '%s\n' "$out"
    [ "$out" = "$expected" ] || error "bash smoke test: expected $(printf '%q' "$expected")"
}

# --- libc-test --------------------------------------------------------------

libc_test_repo=https://repo.or.cz/libc-test.git
# a commit, branch or tag; CI pins a commit
libc_test_rev=${LIBC_TEST_REV:-master}

libc_test=(env "LIBC_TEST_TIMEOUT=${LIBC_TEST_TIMEOUT:-}" sh contrib/libc-test.sh)

cmd_libc_test_build() {
    local dir=$libc_test_dir cc=${toolchain/llvm/clang} ar=ar ranlib=ranlib
    if [ "$arch" != x86_64 ] || $cross; then
        error "libc-test build: the tests are x86_64 binaries, run natively for the baseline"
    fi
    if [ "$toolchain" = llvm ]; then
        cc+=" -fuse-ld=lld -rtlib=compiler-rt"
        # no binutils in the llvm images, and alpine has no llvm-ranlib in PATH
        ar=llvm-ar ranlib="llvm-ar s"
    fi

    if [ ! -d "$repo/$dir" ]; then
        info "fetching libc-test $libc_test_rev into $dir"
        # REVISION: the commit the tests are built from
        # shellcheck disable=SC2016
        docker_run sh -euc 'git clone -q "$1" "$3" && git -C "$3" checkout -q "$2" &&
                            git -C "$3" rev-parse HEAD > "$3/REVISION"' \
            sh "$libc_test_repo" "$libc_test_rev" "$dir"
    fi
    info "building libc-test $(cat "$repo/$dir/REVISION" 2>/dev/null || echo "(unknown revision)") in $dir"
    docker_run env CC="$cc" AR="$ar" RANLIB="$ranlib" "${libc_test[@]}" build "$dir"
    info "running libc-test natively, for the baseline"
    docker_run "${libc_test[@]}" run "$dir" "$dir/baseline.txt"
    # the guest of contrib/libc-test.xfail
    echo "$libc" > "$repo/$dir/LIBC"
}

cmd_libc_test_run() {
    [ $# -eq 1 ] || usage
    local dir=$1 tag=$distro-$libc-$toolchain-$arch qemu=() guest xfail=()
    [ -f "$repo/$dir/baseline.txt" ] || error "no $dir/baseline.txt, run \"libc-test build\" first"
    guest=$(cat "$repo/$dir/LIBC" 2>/dev/null) || error "no $dir/LIBC, run \"libc-test build\" again"
    if [ -n "${LIBC_TEST_XFAIL-contrib/libc-test.xfail}" ]; then
        xfail=("${LIBC_TEST_XFAIL-contrib/libc-test.xfail}" "$guest" "$tag")
    fi
    if $cross; then qemu=("qemu-$arch"); fi

    info "running the libc-test of $dir with box64 ($build_dir)"
    docker_run env BOX64_NOBANNER=1 BOX64_LOG=0 "${libc_test[@]}" run "$dir" "$dir/box64-$tag.txt" \
        "${qemu[@]}" "/src/$build_dir/box64"
    info "comparing with the baseline ($guest guest, $tag host)"
    docker_run "${libc_test[@]}" compare "$dir/baseline.txt" "$dir/box64-$tag.txt" "${xfail[@]}" |
        tee "$repo/$dir/compare-$tag.txt"
}

# runs on the host: CI uses the commit as cache key, before any image is built
cmd_libc_test_rev() {
    if [[ $libc_test_rev =~ ^[0-9a-f]{40}$ ]]; then
        echo "$libc_test_rev"
        return
    fi
    local rev
    rev=$(git ls-remote "$libc_test_repo" "$libc_test_rev" | awk 'NR == 1 { print $1 }')
    [ -n "$rev" ] || error "libc-test: no branch or tag $libc_test_rev in $libc_test_repo"
    echo "$rev"
}

# runs on the host
cmd_libc_test_fetch() {
    [ $# -le 1 ] || usage
    local run=${1:-} dir=$libc_test_dir tmp branch remote
    command -v gh > /dev/null || error "libc-test fetch: needs the GitHub CLI (gh)"
    [ ! -e "$repo/$dir" ] || error "libc-test fetch: $dir exists, remove it or set LIBC_TEST_DIR"
    branch=$(git -C "$repo" branch --show-current)
    # GH_REPO (read by gh): default to the repository the branch is pushed to
    if [ -z "${GH_REPO:-}" ]; then
        remote=$(git -C "$repo" config "branch.$branch.remote" || echo origin)
        GH_REPO=$(git -C "$repo" remote get-url "$remote" | sed -E 's#^(git@|https?://)github\.com[:/]##; s#\.git$##')
        export GH_REPO
    fi
    if [ -z "$run" ]; then
        run=$(gh run list --workflow libc-test.yml --branch "$branch" \
              --status success --limit 1 --json databaseId --jq '.[0].databaseId')
        [ -n "$run" ] || error "libc-test fetch: no successful libc-test run on this branch, give a run id"
    fi
    tmp=$(mktemp -d)
    info "fetching the $libc libc-test of $GH_REPO run $run into $dir"
    gh run download "$run" --name "libc-test-guest-$libc" --dir "$tmp" &&
        tar xzf "$tmp/libc-test-$libc.tar.gz" -C "$tmp" &&
        mv "$tmp/libc-test-$libc" "$repo/$dir" || { rm -rf "$tmp"; error "libc-test fetch: failed"; }
    rm -rf "$tmp"
}

cmd_libc_test() {
    case ${1:-} in
        build) cmd_libc_test_build ;;
        run)   shift; cmd_libc_test_run "$@" ;;
        fetch) shift; cmd_libc_test_fetch "$@" ;;
        rev)   cmd_libc_test_rev ;;
        *)     usage ;;
    esac
}

case $command in
    install)   cmd_install ;;
    image)     cmd_image ;;
    build)     cmd_build ;;
    test)      cmd_test "$@" ;;
    bash)      cmd_bash "$@" ;;
    run)       docker_run "$@" ;;
    libc-test) cmd_libc_test "$@" ;;
    *)         usage ;;
esac
