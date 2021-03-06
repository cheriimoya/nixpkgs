{ lib, stdenv, fetch, cmake, python3, libcxxabi, fixDarwinDylibNames, version
, enableShared ? !stdenv.hostPlatform.isStatic
}:

stdenv.mkDerivation {
  pname = "libc++";
  inherit version;

  src = fetch "libcxx" "0kmhcapm2cjwalyiqasj9dmqbw59mcwdl8fgl951wg7ax84b8hj4";

  postUnpack = ''
    unpackFile ${libcxxabi.src}
    export LIBCXXABI_INCLUDE_DIR="$PWD/$(ls -d libcxxabi-${version}*)/include"
  '';

  patches = lib.optional stdenv.hostPlatform.isMusl ../../libcxx-0001-musl-hacks.patch;

  prePatch = ''
    substituteInPlace lib/CMakeLists.txt --replace "/usr/lib/libc++" "\''${LIBCXX_LIBCXXABI_LIB_PATH}/libc++"
  '';

  preConfigure = ''
    # Get headers from the cxxabi source so we can see private headers not installed by the cxxabi package
    cmakeFlagsArray=($cmakeFlagsArray -DLIBCXX_CXX_ABI_INCLUDE_PATHS="$LIBCXXABI_INCLUDE_DIR")
  '' + lib.optionalString stdenv.hostPlatform.isMusl ''
    patchShebangs utils/cat_files.py
  '';

  nativeBuildInputs = [ cmake ]
    ++ lib.optional stdenv.hostPlatform.isMusl python3
    ++ lib.optional stdenv.hostPlatform.isDarwin fixDarwinDylibNames;

  buildInputs = [ libcxxabi ] ;

  cmakeFlags = [
    "-DLIBCXX_LIBCXXABI_LIB_PATH=${libcxxabi}/lib"
    "-DLIBCXX_LIBCPPABI_VERSION=2"
    "-DLIBCXX_CXX_ABI=libcxxabi"
  ] ++ lib.optional stdenv.hostPlatform.isMusl "-DLIBCXX_HAS_MUSL_LIBC=1"
    ++ lib.optional (stdenv.hostPlatform.useLLVM or false) "-DLIBCXX_USE_COMPILER_RT=ON"
    ++ lib.optional (!enableShared) "-DLIBCXX_ENABLE_SHARED=OFF" ;

  passthru = {
    isLLVM = true;
  };

  meta = {
    homepage = "https://libcxx.llvm.org/";
    description = "A new implementation of the C++ standard library, targeting C++11";
    license = with lib.licenses; [ ncsa mit ];
    platforms = lib.platforms.unix;
  };
}
