# Contensis Cli Homebrew Tap

Ensure https://brew.sh is installed in your terminal

## How do I install these formulae?

`brew install contensis/cli/<formula>`

Or `brew tap contensis/cli` and then `brew install <formula>`.

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

## Documentation

`brew help`, `man brew` or check [Homebrew's documentation](https://docs.brew.sh).

## Updating the Tap

A new release of the cli will require both formulae updating

Tested with WSL running Ubuntu 22.04

Ensure git is installed in the terminal and the environment will need to be set up to pull and push to your GitHub repositories

```sh
git config --global user.name "your name"
git config --global user.email "your email"
git config --global user.username "your GitHub username"
```

First retrieve the tap `brew tap contensis/cli`

- `cd` into the tap folder

### Use the command `brew bump-formula-pr`

- add `--dry-run` option to test the version bump
- add `--url` option to supply download path to the platform-specific release asset/executable
- add `--version` option with the release version number
- add `<formula>` as the final argument e.g. `contensis-cli` or `contensis-cli-linux`

### Mac version bump

```sh
brew bump-formula-pr --dry-run --url https://github.com/contensis/node-cli/releases/download/_ADDVERSION_/contensis-cli-mac --version _ADD_VERSION_ contensis-cli
```

### Linux version bump

```sh
brew bump-formula-pr --dry-run --url https://github.com/contensis/node-cli/releases/download/_ADDVERSION_/contensis-cli-linux --version _ADD_VERSION_ contensis-cli-linux
```

Remove `--dry-run` to make the version bump. Follow on screen prompts, you may be required to install build tools which brew should indicate in the output.

It will make a fork of the `contensis/homebrew-cli` repository in your GitHub profile e.g. `nflatley-zengent/homebrew-cli`, commit the indicated version bump changes to the `<formula>.rb` file then submit a pull request back to the original `contensis/homebrew-cli` repository.

You need to approve the new pull request in this repository to merge the version bump change into this tap.
