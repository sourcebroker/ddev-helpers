cd .ddev
if [[ -e .ddev-helpers-config ]]; then source .ddev-helpers-config; fi
if [[ ! -e .ddev-helpers ]]; then git clone https://github.com/sourcebroker/ddev-helpers/ .ddev-helpers > /dev/null; fi
cd .ddev-helpers
git fetch --all > /dev/null && git reset --hard origin/${version:-latest} > /dev/null
git checkout ${version:-latest} > /dev/null
cd bin
bash ./sb--ddev-hook--pre-start--${system:-typo3}
