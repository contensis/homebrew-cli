# Contensis CLI Homebrew Tap

Ensure https://brew.sh is installed in your terminal

## Install the package with `brew`

The single `contensis-cli` formula installs the correct prebuilt binary for your
platform (macOS x86_64/arm64, Linux x86_64/arm64).

```sh
brew tap contensis/cli
brew trust contensis/cli # newer brew requires this to install from a tap
brew install contensis-cli
```

## Update the installed package

[Follow the official documentation](https://docs.brew.sh/FAQ#how-do-i-update-my-local-packages)

```sh
brew update
brew upgrade <formula>
```

## Further reading

`brew help`, `man brew` or check [Homebrew's documentation](https://docs.brew.sh).

## Maintaining this Tap

A new release of the cli requires the formulae in this tap repository updating in step
with it: `Formula/contensis-cli.rb` (the prebuilt binaries) and, while it exists,
`Formula/contensis-cli-spike.rb` (the npm source build). Instructions tested with Ubuntu
22.04 running in WSL2.

Ensure git is installed in the terminal and the environment will need to be set up to pull and push to your GitHub repositories

```sh
git config --global user.name "your name"
git config --global user.email "your email"
git config --global user.username "your GitHub username"
```

First retrieve the tap `brew tap contensis/cli`

- `cd` into the tap folder `cd $(brew --repo contensis/cli)`

### Bump the binary formula (`contensis-cli`)

`Formula/contensis-cli.rb` downloads a different asset per platform (macOS
x86_64/arm64, Linux x86_64/arm64), so every release needs all four `url`/`sha256`
pairs — plus the two `version` lines inside the arm64 branches — moved together. The
comments at the top of that file explain why each of those details is there.

Use the script in this repository. It reads the sha256 that GitHub publishes for each
release asset, so nothing is downloaded and no checksum is copied by hand:

```sh
cd "$(brew --repo contensis/cli)"
utils/bump-binary-formula.sh 1.7.1 --dry-run   # show the diff, write nothing
utils/bump-binary-formula.sh 1.7.1 --verify    # rewrite, then run the tap CI checks
git diff -- Formula/contensis-cli.rb
```

Do not use `brew bump-formula-pr` on this formula. It rewrites only the top-level
stable stanza (`FormulaAST#replace_stable_stanza_value` walks `stable_children`), so a
`url` inside `on_linux`/`on_macos` is invisible to it and the result is a half-bump:
one platform on the new release, three on the old one, with CI green because
`tests.yml` bottles only the npm formula. The `mislav/bump-homebrew-formula-action`
step in the CLI repository has the same limitation — it replaces only the first `url`,
`sha256` and `version` line in the file — and it now skips this formula outright,
because its version comparison cannot parse a `contensis-cli-v…` tag and concludes that
every release is older than the formula.

### Bump the npm formula (`contensis-cli-spike`)

This one has a single `url`, so `brew bump-formula-pr` is the right tool:

```sh
brew bump-formula-pr --url https://registry.npmjs.org/contensis-cli/-/contensis-cli-1.7.1.tgz contensis-cli-spike
```

Delete the `bottle do` block in the same commit: the published blobs belong to the
previous tarball and the `pr-pull` run regenerates the block. Never hand-write it.

### Open the pull request

Open a pull request against `contensis/homebrew-cli` — from a fork if you do not have
write access; `brew bump-formula-pr` makes the fork and the PR for you.

Wait for the `brew test-bot` workflow jobs to complete successfully.

You need to add the label `pr-pull` to the pull request - this will trigger a new workflow

Wait for the `brew pr-pull` workflow job to complete and then the pull request will be automatically approved and the changes (and new bottles) added into this tap.

That's it, try updating the package in the normal way on another machine.

### Documentation

https://docs.brew.sh/Formula-Cookbook#updating-formulae - this applies to making pull requests for submission into `homebrew/core` repository, however as we are working in a third-party tap, the pull requests are made to this repository

https://gitlab.com/morpheus.lab/homebrew - contains well documented Maintainer Guidelines for their third-party tap
