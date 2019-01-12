class Llvm60 < Formula
  desc "Next-gen compiler infrastructure"
  homepage "http://llvm.org/"

  version = "6.0.0"

  stable do
    url "http://releases.llvm.org/#{version}/llvm-#{version}.src.tar.xz"
    sha256 "1ff53c915b4e761ef400b803f07261ade637b0c269d99569f18040f3dcee4408"

    resource "clang" do
      url "http://releases.llvm.org/#{version}/cfe-#{version}.src.tar.xz"
      sha256 "e07d6dd8d9ef196cfc8e8bb131cbd6a2ed0b1caf1715f9d05b0f0eeaddb6df32"
    end

    resource "clang-tools-extra" do
      url "http://releases.llvm.org/#{version}/clang-tools-extra-#{version}.src.tar.xz"
      sha256 "053b424a4cd34c9335d8918734dd802a8da612d13a26bbb88fcdf524b2d989d2"
    end

    resource "compiler-rt" do
      url "http://releases.llvm.org/#{version}/compiler-rt-#{version}.src.tar.xz"
      sha256 "d0cc1342cf57e9a8d52f5498da47a3b28d24ac0d39cbc92308781b3ee0cea79a"
    end

    resource "polly" do
      url "http://releases.llvm.org/#{version}/polly-#{version}.src.tar.xz"
      sha256 "47e493a799dca35bc68ca2ceaeed27c5ca09b12241f87f7220b5f5882194f59c"
    end

    resource "lld" do
      url "http://releases.llvm.org/#{version}/lld-#{version}.src.tar.xz"
      sha256 "6b8c4a833cf30230c0213d78dbac01af21387b298225de90ab56032ca79c0e0b"
    end

    resource "openmp" do
      url "http://releases.llvm.org/#{version}/openmp-#{version}.src.tar.xz"
      sha256 "7c0e050d5f7da3b057579fb3ea79ed7dc657c765011b402eb5bbe5663a7c38fc"
    end

    resource "libcxx" do
      url "http://releases.llvm.org/#{version}/libcxx-#{version}.src.tar.xz"
      sha256 "70931a87bde9d358af6cb7869e7535ec6b015f7e6df64def6d2ecdd954040dd9"
    end

    resource "libunwind" do
      url "http://releases.llvm.org/#{version}/libunwind-#{version}.src.tar.xz"
      sha256 "256c4ed971191bde42208386c8d39e5143fa4afd098e03bd2c140c878c63f1d6"
    end
  end

  bottle do
  end

  head do
    url "http://llvm.org/git/llvm.git", :branch => "release_60"

    resource "clang" do
      url "http://llvm.org/git/clang.git", :branch => "release_60"
    end

    resource "clang-tools-extra" do
      url "http://llvm.org/git/clang-tools-extra.git", :branch => "release_60"
    end

    resource "compiler-rt" do
      url "http://llvm.org/git/compiler-rt.git", :branch => "release_60"
    end

    resource "polly" do
      url "http://llvm.org/git/polly.git", :branch => "release_60"
    end

    resource "lld" do
      url "http://llvm.org/git/lld.git", :branch => "release_60"
    end

    resource "openmp" do
      url "http://llvm.org/git/openmp.git", :branch => "release_60"
    end

    resource "libcxx" do
      url "http://llvm.org/git/libcxx.git", :branch => "release_60"
    end

    resource "libunwind" do
      url "http://llvm.org/git/libunwind.git", :branceh => "release_60"
    end
  end

  # http://releases.llvm.org/6.0.0/docs/GettingStarted.html#requirements
  depends_on "libffi"
  depends_on "cmake" => :build

  # requires gcc >= 4.8
  fails_with :gcc_4_2
  ("4.3".."4.7").each do |n|
    fails_with :gcc => n
  end

  # version suffix
  def ver
    "6.0"
  end

  # http://releases.llvm.org/6.0.0/docs/CMake.html
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
    ]

    mktemp do
      system "cmake", buildpath, *(std_cmake_args + args)
      system "cmake", "--build", "."
      system "cmake", "--build", ".", "--target", "install"
    end

    (share/"clang-#{ver}/tools").install Dir["tools/clang/tools/scan-{build,view}"]
    inreplace share/"clang-#{ver}/tools/scan-build/bin/scan-build", "$RealBin/bin/clang", install_prefix/"bin/clang"
    (install_prefix/"bin").install_symlink share/"clang-#{ver}/tools/scan-view/bin/scan-view"
    (install_prefix/"bin").install_symlink share/"clang-#{ver}/tools/scan-build/bin/scan-build"
    (install_prefix/"share/man/man1").install_symlink share/"clang-#{ver}/tools/scan-build/scan-build.1"

    (lib/"python2.7/site-packages").install "bindings/python/llvm" => "llvm-#{ver}",
                                            clang_buildpath/"bindings/python/clang" => "clang-#{ver}"

    # replace the existing "clang -> clang-6.0" symlink
    rm install_prefix/"bin/clang"
    mv install_prefix/"bin/clang-#{ver}", install_prefix/"bin/clang"

    # These versioned .dylib symlinks are missing for some reason
    # Note that we use relative symlinks
    ln_s "libLLVM.dylib", install_prefix/"lib/libLLVM-#{ver}.dylib"

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

