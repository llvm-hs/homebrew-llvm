class Llvm70 < Formula
  desc "Next-gen compiler infrastructure"
  homepage "http://llvm.org/"

  version = "7.0.0"

  stable do
    url "http://releases.llvm.org/#{version}/llvm-#{version}.src.tar.xz"
    sha256 "8bc1f844e6cbde1b652c19c1edebc1864456fd9c78b8c1bea038e51b363fe222"

    resource "clang" do
      url "http://releases.llvm.org/#{version}/cfe-#{version}.src.tar.xz"
      sha256 "550212711c752697d2f82c648714a7221b1207fd9441543ff4aa9e3be45bba55"
    end

    resource "clang-tools-extra" do
      url "http://releases.llvm.org/#{version}/clang-tools-extra-#{version}.src.tar.xz"
      sha256 "937c5a8c8c43bc185e4805144744799e524059cac877a44d9063926cd7a19dbe"
    end

    resource "compiler-rt" do
      url "http://releases.llvm.org/#{version}/compiler-rt-#{version}.src.tar.xz"
      sha256 "bdec7fe3cf2c85f55656c07dfb0bd93ae46f2b3dd8f33ff3ad6e7586f4c670d6"
    end

    resource "polly" do
      url "http://releases.llvm.org/#{version}/polly-#{version}.src.tar.xz"
      sha256 "919810d3249f4ae79d084746b9527367df18412f30fe039addbf941861c8534b"
    end

    resource "lld" do
      url "http://releases.llvm.org/#{version}/lld-#{version}.src.tar.xz"
      sha256 "fbcf47c5e543f4cdac6bb9bbbc6327ff24217cd7eafc5571549ad6d237287f9c"
    end

    resource "openmp" do
      url "http://releases.llvm.org/#{version}/openmp-#{version}.src.tar.xz"
      sha256 "30662b632f5556c59ee9215c1309f61de50b3ea8e89dcc28ba9a9494bba238ff"
    end

    resource "libcxx" do
      url "http://releases.llvm.org/#{version}/libcxx-#{version}.src.tar.xz"
      sha256 "9b342625ba2f4e65b52764ab2061e116c0337db2179c6bce7f9a0d70c52134f0"
    end

    resource "libunwind" do
      url "http://releases.llvm.org/#{version}/libunwind-#{version}.src.tar.xz"
      sha256 "50aee87717421e70450f1e093c6cd9a27f2b111025e1e08d64d5ace36e338a9c"
    end
  end

  bottle do
  end

  head do
    url "http://llvm.org/git/llvm.git", :branch => "release_70"

    resource "clang" do
      url "http://llvm.org/git/clang.git", :branch => "release_70"
    end

    resource "clang-tools-extra" do
      url "http://llvm.org/git/clang-tools-extra.git", :branch => "release_70"
    end

    resource "compiler-rt" do
      url "http://llvm.org/git/compiler-rt.git", :branch => "release_70"
    end

    resource "polly" do
      url "http://llvm.org/git/polly.git", :branch => "release_70"
    end

    resource "lld" do
      url "http://llvm.org/git/lld.git", :branch => "release_70"
    end

    resource "openmp" do
      url "http://llvm.org/git/openmp.git", :branch => "release_70"
    end

    resource "libcxx" do
      url "http://llvm.org/git/libcxx.git", :branch => "release_70"
    end

    resource "libunwind" do
      url "http://llvm.org/git/libunwind.git", :branch => "release_70"
    end
  end

  # http://releases.llvm.org/7.0.0/docs/GettingStarted.html#requirements
  depends_on "libffi"
  depends_on "cmake" => :build

  # requires gcc >= 4.8
  fails_with :gcc_4_2
  ("4.3".."4.7").each do |n|
    fails_with :gcc => n
  end

  # version suffix
  def ver
    "7.0"
  end

  # http://releases.llvm.org/7.0.0/docs/CMake.html
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

    # replace the existing "clang -> clang-7" symlink
    rm install_prefix/"bin/clang"
    mv install_prefix/"bin/clang-7", install_prefix/"bin/clang"

    # These versioned .dylib symlinks are missing for some reason
    # Note that we use relative symlinks
    ln_s "libLLVM.dylib", install_prefix/"lib/libLLVM-7.dylib"

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

