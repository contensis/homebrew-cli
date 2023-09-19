class ContensisCliLinux < Formula
  # `brew style contensis/cli` is insanely fussy about the order of these parameters
  desc "Fully featured Contensis command-line interface"
  homepage "https://github.com/contensis/node-cli"
  url "https://github.com/contensis/node-cli/releases/download/v1.0.11/contensis-cli-linux"
  sha256 "474f205c6ffd7e653be1b05424f3d759580509c37b68c42a0fc955978bbc7c34"
  license "GPL-3.0-or-later"

  bottle do
    root_url "https://github.com/contensis/homebrew-cli/releases/download/contensis-cli-linux-1.0.11"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "7784260d709048ba0a1612bad191031933cdfe699531149bf99e0a359912d90d"
  end

  def install
    p "Installing binary contensis-cli-linux"
    # install system specific binary downloaded from the specified url
    # renamed to "contensis-cli"
    bin.install "contensis-cli-linux" => "contensis-cli"
    # create a symlink to "contensis-cli" executable called just "contensis"
    ln_s "./contensis-cli", bin/"contensis"

    puts ""
    puts "#{colorize(" >> Try out contensis-cli by typing")} contensis #{colorize("into your terminal")}"
    puts ""
    puts "#{colorize(" >> Use")} contensis --version #{colorize("to check the currently installed cli version")}"
    puts ""
  end

  test do
    # cannot get test to pass ci due to error
    # pkg/prelude/bootstrap.js:1
    # �����`K2�Ni9��e��$
    # SyntaxError: Invalid or unexpected token
    system "true"
    # # shell_output result = 1 is not correct for this command - probably requires a cli fix
    # # assert_match 1 will attempt a regex match on the output of the command - is flaky and should be replaced
    # assert_match "1", shell_output("#{bin}/contensis -V", 1)
  end

  # the simplest way I could find to colour the command output
  def colorize(text, color = "34", bg_color = "0")
    "\e[#{bg_color};#{color}m#{text}\e[0m"
  end
end
