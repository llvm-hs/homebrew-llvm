class Llvm11 < Formula
  desc "Next-gen compiler infrastructure"
  homepage "http://llvm.org/"
  # The LLVM Project is under the Apache License v2.0 with LLVM Exceptions
  license "Apache-2.0" => { with: "LLVM-exception" }
  revision 1

  version = "11.1.0"
  stable do
    url "https://github.com/llvm/llvm-project/releases/download/llvmorg-#{version}/llvm-project-#{version}.src.tar.xz"
    sha256 "74d2529159fd118c3eac6f90107b5611bccc6f647fdea104024183e8d5e25831"

    patch do
      url "https://github.com/llvm/llvm-project/commit/c86f56e32e724c6018e579bb2bc11e667c96fc96.patch?full_index=1"
      sha256 "6e13e01b4f9037bb6f43f96cb752d23b367fe7db4b66d9bf2a4aeab9234b740a"
    end

    patch do
      url "https://github.com/llvm/llvm-project/commit/31e5f7120bdd2f76337686d9d169b1c00e6ee69c.patch?full_index=1"
      sha256 "f025110aa6bf80bd46d64a0e2b1e2064d165353cd7893bef570b6afba7e90b4d"
    end

    patch do
      url "https://github.com/llvm/llvm-project/commit/3c7bfbd6831b2144229734892182d403e46d7baf.patch?full_index=1"
      sha256 "62014ddad6d5c485ecedafe3277fe7978f3f61c940976e3e642536726abaeb68"
    end

    patch do
      url "https://github.com/llvm/llvm-project/commit/c4d7536136b331bada079b2afbb2bd09ad8296bf.patch?full_index=1"
      sha256 "2b894cbaf990510969bf149697882c86a068a1d704e749afa5d7b71b6ee2eb9f"
    end

    # Upstream ARM patch for OpenMP runtime, remove in next version
    # https://reviews.llvm.org/D91002
    # https://bugs.llvm.org/show_bug.cgi?id=47609
    patch do
      url "https://raw.githubusercontent.com/Homebrew/formula-patches/6166a68c/llvm/openmp_arm.patch"
      sha256 "70fe3836b423e593688cd1cc7a3d76ee6406e64b9909f1a2f780c6f018f89b1e"
    end
  end

  # bottle do
  #   root_url "https://github.com/llvm-hs/homebrew-llvm/releases/download/v11.1.0"
  #   sha256 cellar :any, big_sur: ""
  # end

  # Clang cannot find system headers if Xcode CLT is not installed
  pour_bottle? do
    on_macos do
      reason "The bottle needs the Xcode CLT to be installed."
      satisfy { MacOS::CLT.installed? }
    end
  end

  # http://releases.llvm.org/11.0.0/docs/GettingStarted.html#requirements
  depends_on "cmake" => :build

  uses_from_macos "libedit"
  uses_from_macos "libffi", since: :catalina
  uses_from_macos "libxml2"
  uses_from_macos "ncurses"
  uses_from_macos "zlib"

  # version suffix
  def ver
    "11"
  end

  # http://releases.llvm.org/11.0.0/docs/CMake.html
  def install
    projects = %w[
      clang
      clang-tools-extra
      lld
      openmp
      polly
    ]
    runtimes = %w[
      libcxx
      libcxxabi
      libunwind
    ]

    # Apple's libstdc++ is too old to build LLVM
    ENV.libcxx if ENV.compiler == :clang

    # compiler-rt has some iOS simulator features that require i386 symbols. I'm
    # assuming the rest of clang also needs support for 32-bit compilation to
    # work correctly, but if not, perhaps universal binaries could be limited to
    # compiler-rt. LLVM makes this somewhat easier because compiler-rt can
    # almost be treated as an entirely different build from LLVM.
    ENV.permit_arch_flags

    install_prefix = lib/"llvm-#{ver}"

    args = %W[
      -DCMAKE_BUILD_TYPE=Release
      -DCMAKE_INSTALL_PREFIX=#{install_prefix}
      -DLLVM_ENABLE_PROJECTS=#{projects.join(";")}
      -DLLVM_ENABLE_RUNTIMES=#{runtimes.join(";")}
      -DLLVM_TARGETS_TO_BUILD=all
      -DLLVM_ENABLE_ASSERTIONS=ON
      -DLLVM_OPTIMIZED_TABLEGEN=ON
      -DLLVM_INCLUDE_DOCS=OFF
      -DLLVM_INCLUDE_TESTS=OFF
      -DLLVM_ENABLE_RTTI=ON
      -DLLVM_ENABLE_EH=ON
      -DLLVM_INSTALL_UTILS=ON
      -DLLVM_ENABLE_Z3_SOLVER=OFF
      -DLLVM_BUILD_EXTERNAL_COMPILER_RT=ON
      -DLLVM_BUILD_LLVM_C_DYLIB=ON
      -DLLVM_LINK_LLVM_DYLIB=ON
      -DLLVM_ENABLE_LIBCXX=ON
      -DLLVM_ENABLE_FFI=ON
      -DLLVM_CREATE_XCODE_TOOLCHAIN=ON
      -DLLVM_CREATE_XCODE_TOOLCHAIN=#{MacOS::Xcode.installed? ? "ON" : "OFF"}
    ]

    if MacOS.version >= :catalina
      args << "-DFFI_INCLUDE_DIR=#{MacOS.sdk_path}/usr/include/ffi"
      args << "-DFFI_LIBRARY_DIR=#{MacOS.sdk_path}/usr/lib"
    else
      args << "-DFFI_INCLUDE_DIR=#{Formula["libffi"].opt_include}"
      args << "-DFFI_LIBRARY_DIR=#{Formula["libffi"].opt_lib}"
    end

    sdk = MacOS.sdk_path_if_needed
    args << "-DDEFAULT_SYSROOT=#{sdk}" if sdk

    if MacOS.version == :mojave && MacOS::CLT.installed?
      # Mojave CLT linker via software update is older than Xcode.
      # Use it to retain compatibility.
      args << "-DCMAKE_LINKER=/Library/Developer/CommandLineTools/usr/bin/ld"
    end

    llvmpath = buildpath/"llvm"
    mkdir llvmpath/"build" do
      system "cmake", "-G", "Unix Makefiles", "..", *(std_cmake_args + args)
      system "cmake", "--build", "."
      system "cmake", "--build", ".", "--target", "install"
      system "cmake", "--build", ".", "--target", "install-xcode-toolchain" if MacOS::Xcode.installed?
    end

    # replace the existing "clang -> clang-11" symlink
    rm install_prefix/"bin/clang"
    mv install_prefix/"bin/clang-#{ver}", install_prefix/"bin/clang"

    # These versioned .dylib symlinks are missing for some reason
    # Note that we use relative symlinks
    ln_s "libLLVM.dylib", install_prefix/"lib/libLLVM-#{ver}.dylib"

    # Set LC_LOAD_DYLIB entries to absolute paths
    # system "install_name_tool", "-change", "@rpath/libLLVM.dylib", install_prefix/"lib/libLLVM.dylib", install_prefix/"lib/libLTO.dylib"
    # system "install_name_tool", "-change", "@rpath/libLLVM.dylib", install_prefix/"lib/libLLVM.dylib", install_prefix/"lib/libclang.dylib"

    # Set LC_ID_DYLIB entries to absolute paths
    # system "install_name_tool", "-id", install_prefix/"lib/libLLVM.dylib", install_prefix/"lib/libLLVM.dylib"
    # system "install_name_tool", "-id", install_prefix/"lib/libLLVM-C.dylib", install_prefix/"lib/libLLVM-C.dylib"
    # system "install_name_tool", "-id", install_prefix/"lib/libLTO.dylib", install_prefix/"lib/libLTO.dylib"
    # system "install_name_tool", "-id", install_prefix/"lib/libc++.1.0.dylib", install_prefix/"lib/libc++.1.0.dylib"
    # system "install_name_tool", "-id", install_prefix/"lib/libc++abi.1.0.dylib", install_prefix/"lib/libc++abi.1.0.dylib"
    # system "install_name_tool", "-id", install_prefix/"lib/libclang.dylib", install_prefix/"lib/libclang.dylib"
    # system "install_name_tool", "-id", install_prefix/"lib/libclang-cpp.dylib", install_prefix/"lib/libclang-cpp.dylib"
    # system "install_name_tool", "-id", install_prefix/"lib/libomp.dylib", install_prefix/"lib/libomp.dylib"
    # system "install_name_tool", "-id", install_prefix/"lib/libunwind.1.0.dylib", install_prefix/"lib/libunwind.1.0.dylib"

    Dir.glob(install_prefix/"bin/*") do |exec_path|
      basename = File.basename(exec_path)
      bin.install_symlink exec_path => "#{basename}-#{ver}"
    end

    Dir.glob(install_prefix/"share/man/man1/*") do |manpage|
      basename = File.basename(manpage, ".1")
      man1.install_symlink manpage => "#{basename}-#{ver}.1"
    end
  end

  def caveats
    <<~EOS
      Extra tools are installed in #{opt_share}/clang-#{ver}

      To link to libc++, something like the following is required:
        CXX="clang++-#{ver} -stdlib=libc++"
        CXXFLAGS="$CXXFLAGS -nostdinc++ -I#{opt_lib}/llvm-#{ver}/include/c++/v1"
        LDFLAGS="$LDFLAGS -L#{opt_lib}/llvm-#{ver}/lib"
    EOS
  end

  test do
    assert_equal prefix.to_s, shell_output("#{bin}/llvm-config-#{ver} --prefix").chomp

    # test for sed errors since some llvm makefiles assume that sed
    # understands '\n' which is true for gnu sed and not for bsd sed.
    assert_no_match(/PATH\)n/, (lib/"llvm-#{ver}/share/llvm/cmake/LLVMConfig.cmake").read)
    system "#{bin}/llvm-config-#{ver}", "--version"
  end
end

