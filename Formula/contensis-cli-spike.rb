# SPIKE: Contensis CLI source build (offline experiment).
# Unique class name so it cannot conflict with the real `contensis-cli`
# formula that lives alongside it in this tap.
#
# BOTTLE: this formula carries no `bottle do` block right now. The three blobs
# published at ghcr were built from the 1.6.0 tarball, so they are not valid for
# 1.7.0 and the block was dropped with the version bump. Tap CI rebuilds it on
# the PR and `pr-pull` commits the new shas — do not hand-write one, and keep
# this note out of the class body for the `brew bottle --merge` anchoring reason
# below.
#
# NOTE: keep comments OUTSIDE the `livecheck do` block below. Homebrew's
# `brew bottle --merge` (FormulaAST#add_stanza) anchors the bottle insertion on
# the livecheck block's inline comments, which nests the generated `bottle do`
# block inside `livecheck` and fails with `undefined method 'bottle' for an
# instance of Livecheck`.
class ContensisCliSpike < Formula
  desc "SPIKE: Contensis CLI source build (offline experiment)"
  homepage "https://github.com/contensis/cli"
  url "https://registry.npmjs.org/contensis-cli/-/contensis-cli-1.7.0.tgz"
  sha256 "7846ec2cee42b745b0b4c8e50c6d1f56ae4ac216340da288dce261ec5681088f"
  # Project license (GPL-3.0, per the repo LICENSE file) applies regardless of
  # whether we install the binary release asset or this npm source build; both are
  # the same software. As of contensis-cli@1.7.0 the npm package agrees: its
  # package.json declares GPL-3.0 and the tarball ships a LICENSE file, so the
  # stale `ISC` default that made this a tap-side override is gone upstream.
  license "GPL-3.0"

  # The `latest` dist-tag (not `prerelease`) is what users get by default, so
  # tracking it keeps livecheck reporting the stable CLI and ignoring the
  # 1.x.y-beta pre-releases published under the `prerelease` dist-tag. Explicit
  # rather than guessed so the intent survives any future URL-guessing change.
  livecheck do
    url "https://registry.npmjs.org/contensis-cli/latest"
    regex(/["']version["']:\s*["'](\d+(?:\.\d+)+)["']/i)
  end

  depends_on "node"

  on_linux do
    # keytar's binding.gyp shells out to `pkg-config --cflags libsecret-1` and
    # links against libsecret. macOS builds link AppKit instead and need neither.
    depends_on "pkgconf" => :build
    # keytar.node links libglib/libgio/libgobject/libgmodule transitively via
    # libsecret. `brew linkage --test` fails on an indirect dependency with
    # linkage, so glib has to be declared even though libsecret already pulls
    # it in — this costs no extra download, it just makes the edge explicit.
    depends_on "glib"
    depends_on "libsecret"
  end

  def install
    # Lifecycle scripts stay disabled (the `std_npm_args` default) so install
    # hooks for the ~295 packages in the dependency tree never execute.
    system "npm", "install", *std_npm_args(prefix: libexec)

    # keytar@7.9.0 is the one prod dependency needing a native build. With
    # scripts disabled its `prebuild-install || npm run build` install hook
    # never runs, leaving no build/Release/keytar.node — and that is not
    # benign. CredentialProvider catches the failed `require` but installs a
    # stub whose every method rethrows the original MODULE_NOT_FOUND (see
    # dist/providers/CredentialProvider.js), so any credential read that has
    # no inline password fails with
    #   Cannot find module '../build/Release/keytar.node'
    # Build this one module rather than enabling scripts tree-wide, which
    # would run untrusted install hooks for the whole tree.
    #
    # `npm run build` is `node-gyp rebuild`; npm supplies node-gyp on PATH for
    # run-scripts, and npm_config_nodedir points it at Homebrew's node headers
    # so it does not fetch its own copy mid-build.
    ENV["npm_config_nodedir"] = formula_opt_prefix("node")
    cd libexec/"lib/node_modules/contensis-cli/node_modules/keytar" do
      system "npm", "run", "build"
    end

    # Symlink the generated executables to Homebrew's root path
    bin.install_symlink libexec.glob("bin/*")

    puts ""
    puts "#{colorize(" >> Installed")} contensis-cli #{colorize("as")} contensis"
    puts "#{colorize(" >> Try it out by typing")} contensis #{colorize("into your terminal")}"
    puts "#{colorize(" >> Use")} contensis --version #{colorize("to check the currently installed cli version")}"
    puts ""
  end

  # the simplest way I could find to colour the command output
  def colorize(text, color = "34", bg_color = "0")
    "\e[#{bg_color};#{color}m#{text}\e[0m"
  end

  test do
    # Presence & executability — fail fast if the install step misbehaved.
    # Both names are symlinks into libexec, created by `bin.install_symlink`.
    assert_path_exists bin/"contensis"
    assert_predicate bin/"contensis", :executable?
    assert_path_exists bin/"contensis-cli"
    assert_predicate bin/"contensis-cli", :executable?

    # Guards the keytar build above: without this artefact the CLI raises
    # MODULE_NOT_FOUND on every credential read that has no inline password.
    assert_path_exists libexec/"lib/node_modules/contensis-cli/node_modules/keytar/build/Release/keytar.node"

    # Still commented at 1.7.0, but for a different reason than before. The exit
    # code is fixed (contensis/cli 5b13e2d is in this release), so `--version`
    # exits 0. The version STRING is not: the published tarball bakes
    # `LIB_VERSION = "1.6.1-beta.25"`, because src/version.ts is generated by the
    # `prebuild` hook and that did not fire before packing, so the shipped
    # dist/index.js reports the old string. (The pkg-built binaries are correct —
    # the release workflow runs `npm run build`, which regenerates it first.)
    # contensis/cli 31398bf fixes the ordering; restore this — without the
    # inverted `, 1` exit code — against the first release packed from it (1.7.1+).
    # assert_match version.to_s, shell_output("#{bin}/contensis --version").strip
  end
end
