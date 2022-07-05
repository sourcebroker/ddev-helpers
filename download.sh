cd .ddev
if [[ -e .ddev-helpers-config ]]; then source .ddev-helpers-config; fi
if [[ ! -e .ddev-helpers ]]; then git clone https://github.com/sourcebroker/ddev-helpers/ .ddev-helpers; fi
cd .ddev-helpers
git fetch --all && git reset --hard origin/${version:-latest}
git checkout ${version:-latest}
cd bin
bash ./sb--ddev-hook--pre-start--${system:-typo3}
