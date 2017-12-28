class Llvm50 < Formula
  desc "Next-gen compiler infrastructure"
  homepage "http://llvm.org/"

  version = "5.0.1"

  stable do
    url "http://releases.llvm.org/#{version}/llvm-#{version}.src.tar.xz"
    sha256 "5fa7489fc0225b11821cab0362f5813a05f2bcf2533e8a4ea9c9c860168807b0"

    resource "clang" do
      url "http://releases.llvm.org/#{version}/cfe-#{version}.src.tar.xz"
      sha256 "135f6c9b0cd2da1aff2250e065946258eb699777888df39ca5a5b4fe5e23d0ff"
    end

    resource "clang-tools-extra" do
      url "http://releases.llvm.org/#{version}/clang-tools-extra-#{version}.src.tar.xz"
      sha256 "9aada1f9d673226846c3399d13fab6bba4bfd38bcfe8def5ee7b0ec24f8cd225"
    end

    resource "compiler-rt" do
      url "http://releases.llvm.org/#{version}/compiler-rt-#{version}.src.tar.xz"
      sha256 "4edd1417f457a9b3f0eb88082530490edf3cf6a7335cdce8ecbc5d3e16a895da"
    end

    resource "polly" do
      url "http://releases.llvm.org/#{version}/polly-#{version}.src.tar.xz"
      sha256 "9dd52b17c07054aa8998fc6667d41ae921430ef63fa20ae130037136fdacf36e"
    end

    resource "lld" do
      url "http://releases.llvm.org/#{version}/lld-#{version}.src.tar.xz"
      sha256 "d5b36c0005824f07ab093616bdff247f3da817cae2c51371e1d1473af717d895"
    end

    resource "openmp" do
      url "http://releases.llvm.org/#{version}/openmp-#{version}.src.tar.xz"
      sha256 "adb635cdd2f9f828351b1e13d892480c657fb12500e69c70e007bddf0fca2653"
    end

    resource "libcxx" do
      url "http://releases.llvm.org/#{version}/libcxx-#{version}.src.tar.xz"
      sha256 "fa8f99dd2bde109daa3276d529851a3bce5718d46ce1c5d0806f46caa3e57c00"
    end

    resource "libunwind" do
      url "http://releases.llvm.org/#{version}/libunwind-#{version}.src.tar.xz"
      sha256 "6bbfbf6679435b858bd74bdf080386d084a76dfbf233fb6e47b2c28e0872d0fe"
    end
  end

  bottle do
  end

  head do
    url "http://llvm.org/git/llvm.git", :branch => "release_50"

    resource "clang" do
      url "http://llvm.org/git/clang.git", :branch => "release_50"
    end

    resource "clang-tools-extra" do
      url "http://llvm.org/git/clang-tools-extra.git", :branch => "release_50"
    end

    resource "compiler-rt" do
      url "http://llvm.org/git/compiler-rt.git", :branch => "release_50"
    end

    resource "polly" do
      url "http://llvm.org/git/polly.git", :branch => "release_50"
    end

    resource "lld" do
      url "http://llvm.org/git/lld.git", :branch => "release_50"
    end

    resource "openmp" do
      url "http://llvm.org/git/openmp.git", :branch => "release_50"
    end

    resource "libcxx" do
      url "http://llvm.org/git/libcxx.git", :branch => "release_50"
    end

    resource "libunwind" do
      url "http://llvm.org/git/libunwind.git", :branceh => "release_50"
    end
  end

  # http://releases.llvm.org/5.0.0/docs/GettingStarted.html#requirements
  depends_on "libffi"
  depends_on "cmake" => :build

  # requires gcc >= 4.8
  fails_with :gcc_4_0
  fails_with :gcc
  ("4.3".."4.7").each do |n|
    fails_with :gcc => n
  end

  # version suffix
  def ver
    "5.0"
  end

  # http://releases.llvm.org/5.0.0/docs/CMake.html
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

    # replace the existing "clang -> clang-5.0" symlink
    rm install_prefix/"bin/clang"
    mv install_prefix/"bin/clang-#{ver}", install_prefix/"bin/clang"

    # These versioned .dylib symlinks are missing for some reason
    # Note that we use relative symlinks
    ln_s "libLLVM.dylib", install_prefix/"lib/libLLVM-5.0.dylib"

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

  def caveats; <<-EOS.undent
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
    assert_no_match /PATH\)n/, (lib/"llvm-5.0/share/llvm/cmake/LLVMConfig.cmake").read
    system "#{bin}/llvm-config-#{ver}", "--version"
  end
end
