class Wfdb < Formula
  desc "a software library for working with physiologic signals"
  homepage "http://physionet.org/physiotools/"
  url "https://github.com/bemoody/wfdb/archive/10.5.24.tar.gz"
  sha256 "be3be34cd1c2c0eaaae56a9987de13f49a3c53bf1539ce7db58f885dc6e34b7b"

  head do
    url "https://github.com/bemoody/wfdb.git"
  end

  depends_on :arch => :intel

  def install
    ENV.deparallelize

    if build.head?
      # We need to set the package version manually, otherwise the configure script will prompt user for it...
      # We'll take the version from the NEWS file:
      news_version = %q(`head -1 ../NEWS | awk '{printf "wfdb-%s", $1}'`)
      inreplace "configure", /^PACKAGE=`.*`$/, "PACKAGE=#{news_version}"
    end

    # Configure paths
    system "./configure", "--prefix=#{prefix}", "--mandir=#{man}"

    # Force compilation, prevent "install up to date"
    system "sh", "-c", "echo '.PHONY: install' >> Makefile"

    # Compile and install
    system "make", "install"

    # Install some example c-code that comes with the package
    (share/"wfdb").install "examples"

    # For some reason the configure script doesn't install the man pages properly
    # even though '--mandir' is used. Manual fix:
    share.install(prefix/"man") if File.exist?(prefix/"man")
  end

  def caveats; <<-EOS.undent
    WFDB Example programs have been installed to:
      #{share}/wfdb/examples
    EOS
  end

  ###
  # Compile and run a small test program from the examples
  test do
    # Use wfdb-config to get the location of headers and libs
    cflags = `#{bin/"wfdb-config"} --cflags`.chomp
    libs = `#{bin/"wfdb-config"} --libs`.chomp

    # Compare them to Homebrew paths
    assert_equal("-I#{include}", cflags, "wrong cflags from wfdb-config")
    assert_equal("-L#{lib} -lwfdb", libs, "wrong libs from wfdb-config")

    # Compile the test program
    system ENV.cc, cflags, "-o", "wfdbversion", share/"wfdb/examples/wfdbversion.c", *libs.split

    # Run the program
    system "./wfdbversion"
  end
end
