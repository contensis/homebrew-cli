# SPIKE: Contensis CLI source build (offline experiment).
# Unique class name so it cannot conflict with the real `contensis-cli`
# formula that lives alongside it in this tap.
#
# BOTTLE: this formula carries no `bottle do` block. The blobs published at ghcr
# belong to the tarball the previous version pointed at, so a version bump has to
# delete the block rather than edit it. Tap CI rebuilds it on the PR and
# `pr-pull` commits the new shas — never hand-write one, and keep this note out of
# the class body for the `brew bottle --merge` anchoring reason below.
#
# NOTE: keep comments OUTSIDE the `livecheck do` block below. Homebrew's
# `brew bottle --merge` (FormulaAST#add_stanza) anchors the bottle insertion on
# the livecheck block's inline comments, which nests the generated `bottle do`
# block inside `livecheck` and fails with `undefined method 'bottle' for an
# instance of Livecheck`.
class ContensisCliSpike < Formula
  desc "SPIKE: Contensis CLI source build (offline experiment)"
  homepage "https://github.com/contensis/cli"
  url "https://registry.npmjs.org/contensis-cli/-/contensis-cli-1.7.1.tgz"
  sha256 "1bad4eb47fd67988f0b8ce2552072a173930cc032274fe2cef58aa944ece5ad8"
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

  bottle do
    root_url "https://ghcr.io/v2/contensis/cli"
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "99dc90faeeb735464848575d42e1d00588de8d24c09e3d19dcd0c6b21437eb72"
    sha256 cellar: :any,                 arm64_linux:   "ef3cd14f27e0b78afa872fdea6878916379aa23d13cb3c81e57eec40f76b3ec7"
    sha256 cellar: :any,                 x86_64_linux:  "64d513608c964db241177b3e886b9b8510c54c42eab1e4e75d7393c428904746"
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

    # Restored at 1.7.1, the first release packed after contensis/cli 31398bf.
    # 1.7.0 had the exit code fixed (5b13e2d) but still baked
    # `LIB_VERSION = "1.6.1-beta.25"` into dist/index.js: src/version.ts is
    # generated by the `prebuild` hook, which did not run before packing. Checked
    # against the published 1.7.1 tarball — dist/index.js now carries
    # `LIB_VERSION = "1.7.1"`.
    assert_match version.to_s, shell_output("#{bin}/contensis --version").strip
  end
end
