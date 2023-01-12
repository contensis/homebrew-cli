
class ContensisCli < Formula
  ## TODO: release uri version does not currently match the binary version - correct this
  @@version = "1.0.0-beta.65"
  @@filename = "contensis-cli-mac"
  @@hash = "06f3d7e85472f1b396adb07052b210c625c8c856ade75c6e6c54814b86ad75b2"
  on_linux do
    @@filename = "contensis-cli-linux"
    @@hash = "69e2aaf9ad8f3ff5c12cd817f96edd1908642ea48893345a9d0c1b6c527a7be3"
  end
  desc "A fully featured Contensis command line interface with a shell UI provides simple and intuitive ways to manage or profile your content in your favourite terminal."
  homepage "https://github.com/contensis/node-cli"
  url "https://github.com/contensis/node-cli/releases/download/v1.0.0-beta.51/#@@filename"
  version @@version
  sha256 @@hash
  license "GPL-3.0-or-later"

  def install
    # install system specific binary downloaded from the specified url
    # renamed to "contensis-cli"
    bin.install @@filename => "contensis-cli"
    # create a symlink to "contensis-cli" executable called just "contensis"
    ln_s "./contensis-cli", bin/"contensis"

    puts ""
    puts "#{colorize(" >> Try out contensis-cli by typing")} contensis #{colorize("into your terminal")}"
    puts ""
    puts "#{colorize(" >> Use")} contensis --version #{colorize("to check the currently installed cli version")}"
    puts ""
  end

  test do
    # result = 1 is not correct for this command - probably requires a cli fix
    # assert_match 1 will attempt a regex match on the output of the command - is flaky and should be replaced
    assert_match "1", shell_output("#{bin}/contensis -V", result = 1)
  end

  # the simplest way I could find to colour the command output
  def colorize(text, color = "34", bgColor = "0")
    return "\e[#{bgColor};#{color}m#{text}\e[0m"
  end
  
end

