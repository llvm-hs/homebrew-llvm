class Llvm40 < Formula
  desc "Next-gen compiler infrastructure"
  homepage "http://llvm.org/"

  stable do
    url "http://releases.llvm.org/4.0.0/llvm-4.0.0.src.tar.xz"
    sha256 "8d10511df96e73b8ff9e7abbfb4d4d432edbdbe965f1f4f07afaf370b8a533be"

    resource "clang" do
      url "http://releases.llvm.org/4.0.0/cfe-4.0.0.src.tar.xz"
      sha256 "cea5f88ebddb30e296ca89130c83b9d46c2d833685e2912303c828054c4dc98a"
    end

    resource "clang-tools-extra" do
      url "http://releases.llvm.org/4.0.0/clang-tools-extra-4.0.0.src.tar.xz"
      sha256 "41b7d37eb128fd362ab3431be5244cf50325bb3bb153895735c5bacede647c99"
    end

    resource "compiler-rt" do
      url "http://releases.llvm.org/4.0.0/compiler-rt-4.0.0.src.tar.xz"
      sha256 "d3f25b23bef24c305137e6b44f7e81c51bbec764c119e01512a9bd2330be3115"
    end

    resource "polly" do
      url "http://releases.llvm.org/4.0.0/polly-4.0.0.src.tar.xz"
      sha256 "27a5dbf95e8aa9e0bbe3d6c5d1e83c92414d734357aa0d6c16020a65dc4dcd97"
    end

    resource "lld" do
      url "http://releases.llvm.org/4.0.0/lld-4.0.0.src.tar.xz"
      sha256 "33e06457b9ce0563c89b11ccc7ccabf9cff71b83571985a5bf8684c9150e7502"
    end

    resource "openmp" do
      url "http://releases.llvm.org/4.0.0/openmp-4.0.0.src.tar.xz"
      sha256 "db55d85a7bb289804dc42fc5c8e35ca24dfc3885782261b675a194fd7e206e26"
    end

    resource "libcxx" do
      url "http://releases.llvm.org/4.0.0/libcxx-4.0.0.src.tar.xz"
      sha256 "4f4d33c4ad69bf9e360eebe6b29b7b19486948b1a41decf89d4adec12473cf96"
    end

    resource "libunwind" do
      url "http://releases.llvm.org/4.0.0/libunwind-4.0.0.src.tar.xz"
      sha256 "0755efa9f969373d4d543123bbed4b3f9a835f6302875c1379c5745857725973"
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

  # http://releases.llvm.org/4.0.0/docs/GettingStarted.html#requirements
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
    "4.0"
  end

  # http://releases.llvm.org/4.0.0/docs/CMake.html
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
    assert_no_match /PATH\)n/, (lib/"llvm-4.0/share/llvm/cmake/LLVMConfig.cmake").read
    system "#{bin}/llvm-config-#{ver}", "--version"
  end
end
