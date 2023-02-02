cd .ddev
if [[ -e .ddev-helpers-config ]]; then source .ddev-helpers-config; fi
if [[ ! -e .ddev-helpers ]]; then git clone https://github.com/sourcebroker/ddev-helpers/ .ddev-helpers --quiet; fi
cd .ddev-helpers
git fetch --all --quiet  && git reset --hard origin/${version:-latest} --quiet
git checkout ${version:-latest} --quiet
cd bin
bash ./sb--ddev-hook--pre-start--${system:-typo3}
