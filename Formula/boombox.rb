class Boombox < Formula
  desc "Spotify client for the terminal: a TUI and a scriptable CLI over the same core"
  homepage "https://github.com/danySam/boombox"
  version "0.2.1"
  license "MIT"

  # macOS installs the binary the release workflow built. Linux compiles.
  #
  # That asymmetry is measured, not an oversight. Homebrew builds its Linux
  # formulae against its own glibc -- 2.39 here -- so its libasound.so.2
  # requires GLIBC_2.38, while a binary built against a distribution's glibc
  # is loaded by that distribution's libc, 2.35 on Ubuntu 22.04. Point the
  # one at the other and it dies before main():
  #
  #   libasound.so.2: version `GLIBC_2.38' not found
  #
  # Nothing reconciles two libcs from outside: not RUNPATH, not
  # LD_LIBRARY_PATH, not patchelf (whose own bottle cannot run on the older
  # systems that would need it). Homebrew gets away with it only for what it
  # compiles itself, which is the door this takes on Linux. People who would
  # rather not compile can take the tarball from the release page, which is
  # built against the distribution's own ALSA and needs no Homebrew at all.
  on_macos do
    on_arm do
      url "https://github.com/danySam/boombox/releases/download/v0.2.1/boombox-v0.2.1-aarch64-apple-darwin.tar.gz"
      sha256 "95df442a1c749fa4d9b1d1395f82fb83f0255c843d663acc97865226a21e9a12"
    end
    on_intel do
      url "https://github.com/danySam/boombox/releases/download/v0.2.1/boombox-v0.2.1-x86_64-apple-darwin.tar.gz"
      sha256 "9727a29224f13c6a8f0d961fe40144b31e9bd86a709c683b263f565fa68fcf30"
    end
  end

  on_linux do
    url "https://github.com/danySam/boombox/archive/refs/tags/v0.2.1.tar.gz"
    sha256 "059343c6ac5d7780997d0e9934dd1cee3ed91ad569b724665cd9c67f7f22c842"

    depends_on "pkgconf" => :build
    depends_on "rust" => :build
    # Audio comes out of this machine, so streaming is compiled in, and on
    # Linux that means ALSA to build against and to load at run time.
    depends_on "alsa-lib"
  end

  livecheck do
    url :stable
    strategy :github_latest
  end

  # `brew install --HEAD` builds from source on either platform: there is no
  # tarball for a commit nobody tagged.
  head do
    url "https://github.com/danySam/boombox.git", branch: "main"
    depends_on "pkgconf" => :build
    depends_on "rust" => :build
  end

  def install
    # Everything but a tagged macOS install arrives here as source.
    if build.head? || OS.linux?
      system "cargo", "install", "--features", "streaming", *std_cargo_args(path: "crates/boombox")
      doc.install "README.md", "LICENSE"
    else
      bin.install "boombox"
      # The licence texts of everything compiled into the binary travel with
      # it, which is the obligation a binary release carries. Only the
      # release tarball has them; a source build has no such file.
      doc.install "README.md", "LICENSE", "THIRD_PARTY_LICENSES.html"
    end
  end

  test do
    # Spotify is not reachable from a sandbox, so prove the binary runs and
    # reports itself rather than pretending to test playback.
    assert_match "boombox", shell_output("#{bin}/boombox --version")

    # On macOS this is a binary someone else built, so it can be the wrong
    # architecture or miss a library in a way a source build cannot, and
    # `boombox` alone in the output would not notice.
    assert_match version.to_s, shell_output("#{bin}/boombox --version")

    # Pointed at an empty directory so it cannot find a real config: a
    # command needing an account must say so and exit 2, the documented
    # code for "not signed in", rather than hanging or exiting 0.
    ENV["BOOMBOX_CONFIG_DIR"] = testpath
    ENV["BOOMBOX_STATE_DIR"] = testpath
    output = shell_output("#{bin}/boombox now --direct 2>&1", 2)
    assert_match(/not (signed in|set up)/, output)
  end
end
