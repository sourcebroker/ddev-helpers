cd .ddev || exit 1
if [[ -e .ddev-helpers-config ]]; then source .ddev-helpers-config; fi
if [[ ! -e .ddev-helpers ]]; then git clone --quiet https://github.com/sourcebroker/ddev-helpers/ .ddev-helpers > /dev/null 2>&1; fi
cd .ddev-helpers || exit 1
git fetch --all --quiet > /dev/null 2>&1 && git reset --hard origin/${version:-latest} > /dev/null 2>&1
git checkout ${version:-latest} --quiet > /dev/null 2>&1
cd bin || exit 1
bash ./sb--ddev-hook--pre-start--${system:-typo3}
