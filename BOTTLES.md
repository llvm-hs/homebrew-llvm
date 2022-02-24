# Bottles

General instructions for writing formula: https://docs.brew.sh/Formula-Cookbook

## GitHub

GitHub allows attaching up to 2GB to a release, so we can use this as the host
for the bottles.

Example for llvm-10 release

 * Commit llvm-10.rb and add a new tag v10.0.0

 * brew install --build-bottle [--debug --verbose] ./Formula/llvm-10.rb

 * brew bottle --json --force-core-tap --root-url https://github.com/llvm-hs/homebrew-llvm/releases/download/v10.0.0 ./Formula/llvm-10.rb

 * edit llvm-10.rb to add the bottle information and commit

 * The bottle likely has an incorrect name; if it contains a double-dash it
   should be changed to a single dash:
     llvm-10--10.0.0.mojave.bottle.tar.gz  ➜  llvm-10-10.0.0.mojave.bottle.tar.gz

 * Go to https://github.com/llvm-hs/homebrew-llvm/releases and edit tag v10.0.0.
   Attach the binary .bottle


## Bintray

Bintray is the default host used by Homebrew, but limits binary files to 250MB,
which is not large enough for us.

https://jonathanchang.org/blog/maintain-your-own-homebrew-repository-with-binary-bottles/

Set environment variables `HOMEBREW_BINTRAY_USER` and `HOMEBREW_BINTRAY_KEY`
(from bintray.com -> Edit Profile -> API Key)

> brew test-bot --root-url=https://bintray.com/tmcdonell/bottles-llvm --bintray-org=BINTRAY_USER --tap=llvm-hs/llvm llvm-hs/homebrew-llvm/llvm-9
> brew test-bot --ci-upload --git-name=USERNAME --git-email=EMAIL --bintray-org=BINTRAY_USER --root-url=https://bintray.com/tmcdonell/bottles-llvm

Go to the package on bintray.com and hit "Publish".

