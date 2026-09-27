class Boombox < Formula
  desc "Spotify client for the terminal: a TUI and a scriptable CLI over the same core"
  homepage "https://github.com/danySam/boombox"
  url "https://github.com/danySam/boombox/archive/refs/tags/v0.2.0.tar.gz"
  sha256 "a6ddcb160cc3dc58d29a85b89543ddcf612356ceea78fb5d7238533d2bcdb1d5"
  license "MIT"
  head "https://github.com/danySam/boombox.git", branch: "main"

  livecheck do
    url :stable
    strategy :github_latest
  end

  depends_on "pkgconf" => :build
  depends_on "rust" => :build
  # Audio comes out of this machine, so the streaming feature is built in.
  # macOS uses CoreAudio and needs nothing; Linux needs ALSA at build time.
  on_linux do
    depends_on "alsa-lib"
  end

  def install
    system "cargo", "install", "--features", "streaming", *std_cargo_args(path: "crates/boombox")
  end

  test do
    # Spotify is not reachable from a sandbox, so prove the binary runs and
    # reports itself rather than pretending to test playback.
    assert_match "boombox", shell_output("#{bin}/boombox --version")

    # Pointed at an empty directory so it cannot find a real config: a
    # command needing an account must say so and exit 2, the documented
    # code for "not signed in", rather than hanging or exiting 0.
    ENV["BOOMBOX_CONFIG_DIR"] = testpath
    ENV["BOOMBOX_STATE_DIR"] = testpath
    output = shell_output("#{bin}/boombox now --direct 2>&1", 2)
    assert_match(/not (signed in|set up)/, output)
  end
end
