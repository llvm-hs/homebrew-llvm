class Llvm8 < Formula
  desc "Next-gen compiler infrastructure"
  homepage "http://llvm.org/"

  version = "8.0.0"

  stable do
    url "http://releases.llvm.org/#{version}/llvm-#{version}.src.tar.xz"
    sha256 "8872be1b12c61450cacc82b3d153eab02be2546ef34fa3580ed14137bb26224c"

    resource "clang" do
      url "http://releases.llvm.org/#{version}/cfe-#{version}.src.tar.xz"
      sha256 "084c115aab0084e63b23eee8c233abb6739c399e29966eaeccfc6e088e0b736b"
    end

    resource "clang-tools-extra" do
      url "http://releases.llvm.org/#{version}/clang-tools-extra-#{version}.src.tar.xz"
      sha256 "4f00122be408a7482f2004bcf215720d2b88cf8dc78b824abb225da8ad359d4b"
    end

    resource "compiler-rt" do
      url "http://releases.llvm.org/#{version}/compiler-rt-#{version}.src.tar.xz"
      sha256 "b435c7474f459e71b2831f1a4e3f1d21203cb9c0172e94e9d9b69f50354f21b1"
    end

    resource "polly" do
      url "http://releases.llvm.org/#{version}/polly-#{version}.src.tar.xz"
      sha256 "e3f5a3d6794ef8233af302c45ceb464b74cdc369c1ac735b6b381b21e4d89df4"
    end

    resource "lld" do
      url "http://releases.llvm.org/#{version}/lld-#{version}.src.tar.xz"
      sha256 "9caec8ec922e32ffa130f0fb08e4c5a242d7e68ce757631e425e9eba2e1a6e37"
    end

    resource "openmp" do
      url "http://releases.llvm.org/#{version}/openmp-#{version}.src.tar.xz"
      sha256 "f7b1705d2f16c4fc23d6531f67d2dd6fb78a077dd346b02fed64f4b8df65c9d5"
    end

    resource "libcxx" do
      url "http://releases.llvm.org/#{version}/libcxx-#{version}.src.tar.xz"
      sha256 "c2902675e7c84324fb2c1e45489220f250ede016cc3117186785d9dc291f9de2"
    end

    resource "libunwind" do
      url "http://releases.llvm.org/#{version}/libunwind-#{version}.src.tar.xz"
      sha256 "ff243a669c9cef2e2537e4f697d6fb47764ea91949016f2d643cb5d8286df660"
    end
  end

  bottle do
  end

  head do
    url "http://llvm.org/git/llvm.git", :branch => "release_80"

    resource "clang" do
      url "http://llvm.org/git/clang.git", :branch => "release_80"
    end

    resource "clang-tools-extra" do
      url "http://llvm.org/git/clang-tools-extra.git", :branch => "release_80"
    end

    resource "compiler-rt" do
      url "http://llvm.org/git/compiler-rt.git", :branch => "release_80"
    end

    resource "polly" do
      url "http://llvm.org/git/polly.git", :branch => "release_80"
    end

    resource "lld" do
      url "http://llvm.org/git/lld.git", :branch => "release_80"
    end

    resource "openmp" do
      url "http://llvm.org/git/openmp.git", :branch => "release_80"
    end

    resource "libcxx" do
      url "http://llvm.org/git/libcxx.git", :branch => "release_80"
    end

    resource "libunwind" do
      url "http://llvm.org/git/libunwind.git", :branch => "release_80"
    end
  end

  # http://releases.llvm.org/8.0.0/docs/GettingStarted.html#requirements
  depends_on "libffi"
  depends_on "cmake" => :build
  depends_on :xcode => :build

  # version suffix
  def ver
    "8"
  end

  # http://releases.llvm.org/8.0.0/docs/CMake.html
  def install
    # Apple's libstdc++ is too old to build LLVM
    ENV.libcxx if ENV.compiler == :clang

    # compiler-rt has some iOS simulator features that require i386 symbols. I'm
    # assuming the rest of clang also needs support for 32-bit compilation to
    # work correctly, but if not, perhaps universal binaries could be limited to
    # compiler-rt. LLVM makes this somewhat easier because compiler-rt can
    # almost be treated as an entirely different build from LLVM.
    ENV.permit_arch_flags

    clang_buildpath  = buildpath/"tools/clang"
    libcxx_buildpath = buildpath/"projects/libcxx"

    clang_buildpath.install resource("clang")
    libcxx_buildpath.install resource("libcxx")
    (buildpath/"tools/lld").install resource("lld")
    (buildpath/"tools/polly").install resource("polly")
    (buildpath/"tools/clang/tools/extra").install resource("clang-tools-extra")
    (buildpath/"projects/openmp").install resource("openmp")
    (buildpath/"projects/libunwind").install resource("libunwind")
    (buildpath/"projects/compiler-rt").install resource("compiler-rt")

    install_prefix = lib/"llvm-#{ver}"

    args = %W[
      -DCMAKE_INSTALL_PREFIX=#{install_prefix}
      -DCMAKE_BUILD_TYPE=Release
      -DLLVM_ENABLE_ASSERTIONS=ON
      -DLLVM_OPTIMIZED_TABLEGEN=ON
      -DLLVM_INCLUDE_DOCS=OFF
      -DLLVM_ENABLE_RTTI=ON
      -DLLVM_ENABLE_EH=ON
      -DLLVM_INSTALL_UTILS=ON
      -DWITH_POLLY=ON
      -DLINK_POLLY_INTO_TOOLS=ON
      -DLLVM_TARGETS_TO_BUILD=all
      -DLIBOMP_ARCH=x86_64
      -DLLVM_BUILD_EXTERNAL_COMPILER_RT=ON
      -DLLVM_BUILD_LLVM_DYLIB=ON
      -DLLVM_LINK_LLVM_DYLIB=ON
      -DLLVM_ENABLE_LIBCXX=ON
      -DLLVM_ENABLE_FFI=ON
      -DFFI_INCLUDE_DIR=#{Formula["libffi"].opt_lib}/libffi-#{Formula["libffi"].version}/include
      -DFFI_LIBRARY_DIR=#{Formula["libffi"].opt_lib}
      -DLLVM_CREATE_XCODE_TOOLCHAIN=ON
    ]

    mkdir "build" do
      system "cmake", "-G", "Unix Makefiles", "..", *(std_cmake_args + args)
      system "make"
      system "make", "install"
      system "make", "install-xcode-toolchain"
    end

    (share/"clang-#{ver}/tools").install Dir["tools/clang/tools/scan-{build,view}"]
    inreplace share/"clang-#{ver}/tools/scan-build/bin/scan-build", "$RealBin/bin/clang", install_prefix/"bin/clang"
    (install_prefix/"bin").install_symlink share/"clang-#{ver}/tools/scan-view/bin/scan-view"
    (install_prefix/"bin").install_symlink share/"clang-#{ver}/tools/scan-build/bin/scan-build"
    (install_prefix/"share/man/man1").install_symlink share/"clang-#{ver}/tools/scan-build/scan-build.1"

    (lib/"python2.7/site-packages").install "bindings/python/llvm" => "llvm-#{ver}",
                                            clang_buildpath/"bindings/python/clang" => "clang-#{ver}"

    # replace the existing "clang -> clang-8" symlink
    rm install_prefix/"bin/clang"
    mv install_prefix/"bin/clang-8", install_prefix/"bin/clang"

    # These versioned .dylib symlinks are missing for some reason
    # Note that we use relative symlinks
    ln_s "libLLVM.dylib", install_prefix/"lib/libLLVM-8.dylib"

    # Set LC_LOAD_DYLIB entries to absolute paths
    system "install_name_tool", "-change", "@rpath/libLLVM.dylib", install_prefix/"lib/libLLVM.dylib", install_prefix/"lib/libLTO.dylib"
    system "install_name_tool", "-change", "@rpath/libLLVM.dylib", install_prefix/"lib/libLLVM.dylib", install_prefix/"lib/libclang.dylib"

    # Set LC_ID_DYLIB entries to absolute paths
    system "install_name_tool", "-id", install_prefix/"lib/libLLVM.dylib", install_prefix/"lib/libLLVM.dylib"
    system "install_name_tool", "-id", install_prefix/"lib/libLTO.dylib", install_prefix/"lib/libLTO.dylib"
    system "install_name_tool", "-id", install_prefix/"lib/libc++.1.0.dylib", install_prefix/"lib/libc++.1.0.dylib"
    system "install_name_tool", "-id", install_prefix/"lib/libclang.dylib", install_prefix/"lib/libclang.dylib"
    system "install_name_tool", "-id", install_prefix/"lib/libomp.dylib", install_prefix/"lib/libomp.dylib"
    system "install_name_tool", "-id", install_prefix/"lib/libunwind.1.0.dylib", install_prefix/"lib/libunwind.1.0.dylib"

    Dir.glob(install_prefix/"bin/*") do |exec_path|
      basename = File.basename(exec_path)
      bin.install_symlink exec_path => "#{basename}-#{ver}"
    end

    Dir.glob(install_prefix/"share/man/man1/*") do |manpage|
      basename = File.basename(manpage, ".1")
      man1.install_symlink manpage => "#{basename}-#{ver}.1"
    end
  end

  def caveats; <<~EOS
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
    assert_no_match /PATH\)n/, (lib/"llvm-#{ver}/share/llvm/cmake/LLVMConfig.cmake").read
    system "#{bin}/llvm-config-#{ver}", "--version"
  end
end

