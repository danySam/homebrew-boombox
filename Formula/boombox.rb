class Boombox < Formula
  desc "Spotify client for the terminal: a TUI and a scriptable CLI over the same core"
  homepage "https://github.com/danySam/boombox"
  version "0.2.1"
  license "MIT"

  # One tarball per architecture, built by the release workflow. This used
  # to be a source build, which meant every install fetched a Rust
  # toolchain and LLVM -- about two gigabytes -- to produce an 18 MB binary
  # and then throw the toolchain away.
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
    # Audio comes out of this machine, so streaming is compiled in. On Linux
    # that links ALSA, and a prebuilt binary needs it at run time -- not just
    # at build time, as the source formula did.
    depends_on "alsa-lib"

    on_arm do
      url "https://github.com/danySam/boombox/releases/download/v0.2.1/boombox-v0.2.1-aarch64-unknown-linux-gnu.tar.gz"
      sha256 "87f895bc30b008b9b2bd5a98abd71ed9350e5432a3222ec8253d4445c100d183"
    end
    on_intel do
      url "https://github.com/danySam/boombox/releases/download/v0.2.1/boombox-v0.2.1-x86_64-unknown-linux-gnu.tar.gz"
      sha256 "784080fcd98306ed1efd069db0d439cea4bdcb065de264b90f6b960cf9b9e408"
    end
  end

  livecheck do
    url :stable
    strategy :github_latest
  end

  # `brew install --HEAD` still builds from source: there is no tarball for
  # a commit nobody tagged.
  head do
    url "https://github.com/danySam/boombox.git", branch: "main"
    depends_on "pkgconf" => :build
    depends_on "rust" => :build
  end

  def install
    if build.head?
      system "cargo", "install", "--features", "streaming", *std_cargo_args(path: "crates/boombox")
      doc.install "README.md", "LICENSE"
    else
      bin.install "boombox"
      # The licence texts of everything compiled into the binary travel with
      # it, which is the obligation a binary release carries.
      doc.install "README.md", "LICENSE", "THIRD_PARTY_LICENSES.html"
    end
  end

  test do
    # Spotify is not reachable from a sandbox, so prove the binary runs and
    # reports itself rather than pretending to test playback.
    assert_match "boombox", shell_output("#{bin}/boombox --version")

    # A prebuilt binary can be the wrong architecture or miss a library in a
    # way a source build cannot, and --version alone would not notice.
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
