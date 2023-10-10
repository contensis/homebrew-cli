# Contensis CLI Homebrew Tap

Ensure https://brew.sh is installed in your terminal

## Install the package with `brew`

### MacOS

```sh
brew tap contensis/cli
brew install contensis-cli
```

### Linux

```sh
brew tap contensis/cli
brew install contensis-cli-linux --build-bottle
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

A new release of the cli will require both formulae updating in this tap repository (instructions tested with Ubuntu 22.04 running in WSL2)

Ensure git is installed in the terminal and the environment will need to be set up to pull and push to your GitHub repositories

```sh
git config --global user.name "your name"
git config --global user.email "your email"
git config --global user.username "your GitHub username"
```

First retrieve the tap `brew tap contensis/cli`

- `cd` into the tap folder `cd $(brew --repo contensis/cli)`

### Use the command `brew bump-formula-pr`

- add `--dry-run` option to test the version bump
- add `--url` option to supply download path to the platform-specific release asset/executable
- add `--version` option with the release version number
- add `<formula>` as the final argument e.g. `contensis-cli` or `contensis-cli-linux`

### Mac version bump

```sh
brew bump-formula-pr --dry-run --url https://github.com/contensis/cli/releases/download/v{$VERSION}/contensis-cli-mac contensis-cli
```

### Linux version bump

```sh
brew bump-formula-pr --dry-run --url https://github.com/contensis/cli/releases/download/v{$VERSION}/contensis-cli-linux contensis-cli-linux
```

Remove `--dry-run` to make the version bump. Follow on screen prompts, you may be required to install build tools which brew should indicate in the output.

It will make a fork of the `contensis/homebrew-cli` repository in your GitHub profile e.g. `nflatley-zengent/homebrew-cli`, commit the indicated version bump changes to the `<formula>.rb` file then submit a pull request back to the original `contensis/homebrew-cli` repository.

Wait for the `brew test-bot` workflow jobs to complete successfully.

You need to add the label `pr-pull` to the pull request - this will trigger a new workflow

Wait for the `brew pr-pull` workflow job to complete and then the pull request will be automatically approved and the changes (and new bottles) added into this tap.

That's it, try updating the package in the normal way on another machine.

### Documentation

https://docs.brew.sh/Formula-Cookbook#updating-formulae - this applies to making pull requests for submission into `homebrew/core` repository, however as we are working in a third-party tap, the pull requests are made to this repository

https://gitlab.com/morpheus.lab/homebrew - contains well documented Maintainer Guidelines for their third-party tap
