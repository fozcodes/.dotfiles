####### PYTHON BULLSHIT #######
# Formula prefixes are stable paths under Homebrew's `opt` directory. Do not
# invoke `brew --prefix` for each formula: that adds hundreds of milliseconds
# to every interactive shell startup.
set brew_prefix /opt/homebrew
set brew_openssl_formula libressl

if set -q USE_LEGACY_BREW
  echo "Setting the LDFLAGS and CPPFLAGS using legacy brew..."
  set brew_prefix /usr/local
  set brew_openssl_formula openssl@1.1
end

set brew_opt "$brew_prefix/opt"
set brew_zlib "$brew_opt/zlib"
set brew_xz "$brew_opt/xz"
set brew_readline "$brew_opt/readline"
set brew_bzip2 "$brew_opt/bzip2"
set brew_openssl "$brew_opt/$brew_openssl_formula"
set brew_libffi "$brew_opt/libffi"
set brew_sqlite "$brew_opt/sqlite"
set brew_libomp "$brew_opt/libomp"

#set python pretty print on everywhere... even though it only works sometimes
set -x TBVACCINE 1

set -x OPENBLAS "$brew_opt/openblas"

set -x LDFLAGS "-L$brew_zlib/lib"
set -x LDFLAGS "-L$brew_xz/lib $LDFLAGS"
set -x LDFLAGS "-L$brew_readline/lib $LDFLAGS"
set -x LDFLAGS "-L$brew_bzip2/lib $LDFLAGS"
set -x LDFLAGS "-L$brew_openssl/lib $LDFLAGS"
set -x LDFLAGS "-L$brew_libffi/lib $LDFLAGS"
set -x LDFLAGS "-L$brew_sqlite/lib $LDFLAGS"
set -x LDFLAGS "-L$brew_libomp/lib $LDFLAGS"
set -x LDFLAGS "-L$OPENBLAS/lib $LDFLAGS"

set -x CPPFLAGS "-I$brew_zlib/include \
-I$brew_xz/include \
-I$brew_readline/include \
-I$brew_bzip2/include \
-I$brew_openssl/include \
-I$brew_sqlite/include \
-I$brew_libomp/include \
-I$brew_libffi/include" 

set -x PKG_CONFIG_PATH "$brew_zlib/lib/pkgconfig $PKG_CONFIG_PATH"
set -x PKG_CONFIG_PATH "$brew_sqlite/lib/pkgconfig $PKG_CONFIG_PATH"

# I removed these because they were causing problems with installing DNL and node-gyp
# set -x CC "$brew_gcc/bin/gcc-14"
# set -x CXX "$brew_gcc/bin/g++-14"

set -x CFLAGS "-falign-functions=8 $CFLAGS"
set -x CFLAGS "-I$OPENBLAS/include -O $CFLAGS"

set -x FFLAGS "-fallow-argument-mismatch"

set -x NPY_LAPACK_ORDER $OPENBLAS
set -x NPY_BLAS_ORDER $OPENBLAS


# search for a activate.fish file UP THE DIRECTORY TREE, starting from the current folder.
# if found, execute it.
# Intended for automatically switching to the python  virtual environment on entering the
# directories.  Can put in other initialization stuff.
function cd --description 'change directory - fish overload'

  builtin cd $param $argv

  emit fish_prompt

  if set -q VIRTUAL_ENV
    source "$VIRTUAL_ENV/bin/activate.fish"
    echo "Activated virtualenv: $VIRTUAL_ENV"
    return
  end

  set -l check_dir (pwd)
  # if myInit.fish is found in the home directory:
  if test -f "$check_dir/activate.fish"
    source $check_dir/myInit.fish
    echo "executed: source $check_dir/activate.fish"
    return
  end

  # Look up the directory tree for activate.fish:
  set check_dir (string split -r -m 1 / $check_dir)[1]

  while test $check_dir
    if test -f "$check_dir/activate.fish"
      source $check_dir/myInit.fish
      echo "executed: source $check_dir/activate.fish"
      break;
    else
      set check_dir (string split -r -m 1 / $check_dir)[1]
    end  # if ... else ...
  end  # while
end  # function

