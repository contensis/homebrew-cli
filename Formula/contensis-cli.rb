class ContensisCli < Formula
  # `brew style contensis/cli` is insanely fussy about the order of these parameters
  desc "Fully featured Contensis command-line interface"
  homepage "https://github.com/contensis/node-cli"
  url "https://github.com/contensis/node-cli/releases/download/v1.0.0-beta.51/contensis-cli-mac"
  version "1.0.0-beta.65"
  sha256 "06f3d7e85472f1b396adb07052b210c625c8c856ade75c6e6c54814b86ad75b2"
  license "GPL-3.0-or-later"

  bottle do
    root_url "https://github.com/contensis/homebrew-cli/releases/download/contensis-cli-1.0.0-beta.65"
    rebuild 1
    sha256 cellar: :any_skip_relocation, monterey: "907d028b1898674f789e1a1f7fb394ad001da38de780a53b502d0eba42a3cab5"
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
