class ContensisCli < Formula
  # `brew style contensis/cli` is insanely fussy about the order of these parameters
  desc "Fully featured Contensis command-line interface"
  homepage "https://github.com/contensis/node-cli"
  url "https://github.com/contensis/node-cli/releases/download/v1.0.0-beta.85/contensis-cli-mac"
  version "1.0.0-beta.85"
  sha256 "10a332f91251bde6af3c2edee3acd796fd8236b18ea070a9a9916f2e277299d8"
  license "GPL-3.0-or-later"

  # the pull request needs a label of "pr-pull" in order to generate new bottles x
  bottle do
    root_url "https://github.com/contensis/homebrew-cli/releases/download/contensis-cli-1.0.0-beta.85"
    rebuild 2
    sha256 cellar: :any_skip_relocation, monterey: "2d13921113472e2c870564939e661518acc811b46c74ac0c4fdae4a2f5c8d88d"
  end

  def install
    p "Installing binary contensis-cli-mac"
    # install system specific binary downloaded from the specified url
    # renamed to "contensis-cli"
    bin.install "contensis-cli-mac" => "contensis-cli"
    # create a symlink to "contensis-cli" executable called just "contensis"
    ln_s "./contensis-cli", bin/"contensis"

    puts ""
    puts "#{colorize(" >> Try out contensis-cli by typing")} contensis #{colorize("into your terminal")}"
    puts ""
    puts "#{colorize(" >> Use")} contensis --version #{colorize("to check the currently installed cli version")}"
    puts ""
  end

  test do
    # shell_output result = 1 is not correct for this command - probably requires a cli fix
    # assert_match 1 will attempt a regex match on the output of the command - is flaky and should be replaced
    assert_match "1", shell_output("#{bin}/contensis --version", 1)
  end

  # the simplest way I could find to colour the command output
  def colorize(text, color = "34", bg_color = "0")
    "\e[#{bg_color};#{color}m#{text}\e[0m"
  end
end
