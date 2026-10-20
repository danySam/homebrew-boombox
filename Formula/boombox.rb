class Boombox < Formula
  desc "Spotify client for the terminal: a TUI and a scriptable CLI over the same core"
  homepage "https://github.com/danySam/boombox"
  version "0.3.2"
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
      url "https://github.com/danySam/boombox/releases/download/v0.3.2/boombox-v0.3.2-aarch64-apple-darwin.tar.gz"
      sha256 "23ac10fd193663f834f005ba0d7ba4efe8709572ae9e3199f80c186aa02942db"
    end
    on_intel do
      url "https://github.com/danySam/boombox/releases/download/v0.3.2/boombox-v0.3.2-x86_64-apple-darwin.tar.gz"
      sha256 "baa7754b1bcd4e99761d8aaf872af4e024df35197b5c089fed73c47fced39e95"
    end
  end

  on_linux do
    url "https://github.com/danySam/boombox/archive/refs/tags/v0.3.2.tar.gz"
    sha256 "a62bd8820ff076111effbc7c2170f3fefa486facc05a023f711dbef522d7dab4"

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
