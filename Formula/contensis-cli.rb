class ContensisCli < Formula
  # `brew style contensis/cli` is insanely fussy about the order of these parameters
  desc "Fully featured Contensis command-line interface"
  homepage "https://github.com/contensis/cli"
  # Homebrew derives the version from whichever `url` is active on the host
  # platform, so every URL here must point at the SAME release tag. A platform
  # block left on an older tag silently keeps serving the old release on that
  # platform (and `brew livecheck` reports it outdated forever) while CI stays
  # green: tests.yml bottles only the npm formula, so this file is never
  # installed or `brew test`ed there. Check all four url/sha256 pairs on a bump.
  #
  # Do not add a top-level `version` stanza: `brew audit` rejects it as
  # "redundant with version scanned from URL", and that is the exact command tap
  # CI runs (`brew audit --except=installed --tap=contensis/cli`). The two
  # `-arm64` branches below are the deliberate exception — see the note there.
  url "https://github.com/contensis/cli/releases/download/contensis-cli-v1.7.1/contensis-cli-mac"
  sha256 "a16fe55e584af3c39c4a74a9c6997bfc1f601ddd219bfec4703de078f851bcb3"
  license "GPL-3.0"

  livecheck do
    # Each release publishes per-platform binary assets under tags of the form
    # `contensis-cli-v<VERSION>`. `strategy :github_latest` reads the GitHub API's
    # latest-release endpoint, which excludes prereleases, so `brew livecheck`
    # reports the newest stable CLI without chasing the `prerelease` dist-tag betas.
    url "https://github.com/contensis/cli/releases/latest"
    strategy :github_latest
  end

  # Both `-arm64` branches below carry an explicit `version` (order matters to
  # `brew style`: url, version, sha256). Homebrew's URL version parser takes the
  # trailing digits of the asset stem, so `.../contensis-cli-mac-arm64` scans as
  # version 64 — and 64 sorts above every future release, so arm64 installs are
  # never offered an upgrade. The tag is unreadable too: the parser's
  # GitHub-release pattern wants `releases/download/v<digits.dots>/`, and the
  # `contensis-cli-` prefix breaks it, so nothing else in the URL is usable.
  # Declaring `version` inside the branch fixes the scan, and `brew audit` only
  # calls it redundant when it equals the version scanned from that same URL
  # (ResourceAuditor#audit_version), so no CI leg trips. Renaming the assets
  # upstream (e.g. a `-v1.7.0` suffix) or dropping the tag prefix would let all
  # of this go away.
  #
  # macOS arm64 assets ship from contensis-cli-v1.7.0 onwards (arm64 support
  # added in contensis/cli 4a08aef). Earlier releases published no mac-arm64
  # asset, so Apple Silicon installs fell back to the x86_64 binary above and ran
  # under Rosetta. `stable.url` is re-resolved per platform, so `install` needs
  # no change.
  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/contensis/cli/releases/download/contensis-cli-v1.7.1/contensis-cli-mac-arm64"
      version "1.7.1"
      sha256 "e21f2a4d07bacc2f4b30b8cb163f9a485ee8a55d5ec2c65c82a219de89e633cd"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/contensis/cli/releases/download/contensis-cli-v1.7.1/contensis-cli-linux-arm64"
      version "1.7.1"
      sha256 "ac108b34a2d0234354d6bfbc3fc4a63d94b422d585398afa7c9cc8f56c19f139"
    else
      url "https://github.com/contensis/cli/releases/download/contensis-cli-v1.7.1/contensis-cli-linux"
      sha256 "bd77c6da6db06c32840e028fd7a6e6acd639cb86ae349ab3286e4c4fc9d91df3"
    end
  end

  def install
    # `stable.url` is the active platform's download URL; its basename is the asset file.
    asset = File.basename(stable.url)
    bin.install asset => "contensis-cli"
    # relocatable `contensis` alias
    bin.install_symlink "contensis-cli" => "contensis"

    puts ""
    puts "#{colorize(" >> Installed")} #{asset} #{colorize("as")} contensis"
    puts "#{colorize(" >> Try it out by typing")} contensis #{colorize("into your terminal")}"
    puts "#{colorize(" >> Use")} contensis --version #{colorize("to check the currently installed cli version")}"
    puts ""
  end

  # the simplest way I could find to colour the command output
  def colorize(text, color = "34", bg_color = "0")
    "\e[#{bg_color};#{color}m#{text}\e[0m"
  end

  test do
    # 1. Presence & executability — fail fast if the install step misbehaved.
    assert_path_exists bin/"contensis-cli"
    assert_predicate bin/"contensis-cli", :executable?
    assert_predicate bin/"contensis", :symlink?

    # Restored in 1.7.0 (contensis/cli 5b13e2d fixed the exit code) and re-verified
    # for 1.7.1 against the contensis-cli-linux asset: `--version` prints 1.7.1 and
    # exits 0. The pkg-built binaries bake the version string correctly because the
    # release workflow runs `npm run build`, whose prebuild regenerates
    # src/version.ts. The npm tarball did not run that hook until contensis/cli
    # 31398bf, which is why the npm formula carried a stale version string one
    # release longer than this one did.
    #
    # Not exercised by tap CI — tests.yml bottles only the npm formula, so this
    # file gets `brew style`/`audit` only. Run `brew test contensis-cli` locally.
    #
    # 2. Version — `shell_output` fails the test if the command exits non-zero;
    #    assert the output equals the formula's declared version.
    assert_match version.to_s, shell_output("#{bin}/contensis-cli --version").strip

    # 3. The `contensis` alias behaves identically.
    assert_match version.to_s, shell_output("#{bin}/contensis --version").strip

    # 4. Help — exits 0 and names the tool; exercises argument parsing.
    assert_match "contensis", shell_output("#{bin}/contensis --help")
  end
end
