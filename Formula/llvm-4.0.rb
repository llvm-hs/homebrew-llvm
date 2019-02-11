class Llvm40 < Formula
  desc "Next-gen compiler infrastructure"
  homepage "http://llvm.org/"

  stable do
    url "http://releases.llvm.org/4.0.1/llvm-4.0.1.src.tar.xz"
    sha256 "da783db1f82d516791179fe103c71706046561f7972b18f0049242dee6712b51"

    resource "clang" do
      url "http://releases.llvm.org/4.0.1/cfe-4.0.1.src.tar.xz"
      sha256 "61738a735852c23c3bdbe52d035488cdb2083013f384d67c1ba36fabebd8769b"
    end

    resource "clang-tools-extra" do
      url "http://releases.llvm.org/4.0.1/clang-tools-extra-4.0.1.src.tar.xz"
      sha256 "35d1e64efc108076acbe7392566a52c35df9ec19778eb9eb12245fc7d8b915b6"
    end

    resource "compiler-rt" do
      url "http://releases.llvm.org/4.0.1/compiler-rt-4.0.1.src.tar.xz"
      sha256 "a3c87794334887b93b7a766c507244a7cdcce1d48b2e9249fc9a94f2c3beb440"
    end

    resource "polly" do
      url "http://releases.llvm.org/4.0.1/polly-4.0.1.src.tar.xz"
      sha256 "b443bb9617d776a7d05970e5818aa49aa2adfb2670047be8e9f242f58e84f01a"
    end

    resource "lld" do
      url "http://releases.llvm.org/4.0.1/lld-4.0.1.src.tar.xz"
      sha256 "63ce10e533276ca353941ce5ab5cc8e8dcd99dbdd9c4fa49f344a212f29d36ed"
    end

    resource "openmp" do
      url "http://releases.llvm.org/4.0.1/openmp-4.0.1.src.tar.xz"
      sha256 "ec693b170e0600daa7b372240a06e66341ace790d89eaf4a843e8d56d5f4ada4"
    end

    resource "libcxx" do
      url "http://releases.llvm.org/4.0.1/libcxx-4.0.1.src.tar.xz"
      sha256 "520a1171f272c9ff82f324d5d89accadcec9bc9f3c78de11f5575cdb99accc4c"
    end

    resource "libunwind" do
      url "http://releases.llvm.org/4.0.1/libunwind-4.0.1.src.tar.xz"
      sha256 "3b072e33b764b4f9b5172698e080886d1f4d606531ab227772a7fc08d6a92555"
    end
  end

  bottle do
  end

  head do
    url "http://llvm.org/git/llvm.git", :branch => "release_40"

    resource "clang" do
      url "http://llvm.org/git/clang.git", :branch => "release_40"
    end

    resource "clang-tools-extra" do
      url "http://llvm.org/git/clang-tools-extra.git", :branch => "release_40"
    end

    resource "compiler-rt" do
      url "http://llvm.org/git/compiler-rt.git", :branch => "release_40"
    end

    resource "polly" do
      url "http://llvm.org/git/polly.git", :branch => "release_40"
    end

    resource "lld" do
      url "http://llvm.org/git/lld.git", :branch => "release_40"
    end

    resource "openmp" do
      url "http://llvm.org/git/openmp.git", :branch => "release_40"
    end

    resource "libcxx" do
      url "http://llvm.org/git/libcxx.git", :branch => "release_40"
    end

    resource "libunwind" do
      url "http://llvm.org/git/libunwind.git", :branceh => "release_40"
    end
  end

  # http://releases.llvm.org/4.0.1/docs/GettingStarted.html#requirements
  depends_on "libffi"
  depends_on "cmake" => :build

  # version suffix
  def ver
    "4.0"
  end

  # http://releases.llvm.org/4.0.1/docs/CMake.html
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
    (buildpath/"projects/libcxx").install resource("libcxx")
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

    # replace the existing "clang -> clang-4.0" symlink
    rm install_prefix/"bin/clang"
    mv install_prefix/"bin/clang-#{ver}", install_prefix/"bin/clang"

    # These versioned .dylib symlinks are missing for some reason
    # Note that we use relative symlinks
    ln_s "libLLVM.dylib", install_prefix/"lib/libLLVM-4.0.dylib"

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
    assert_no_match /PATH\)n/, (lib/"llvm-4.0/share/llvm/cmake/LLVMConfig.cmake").read
    system "#{bin}/llvm-config-#{ver}", "--version"
  end
end
