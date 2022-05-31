cd .ddev
source .ddev-helpers-config
git clone https://github.com/sourcebroker/ddev-helpers/ .ddev-helpers
cd .ddev-helpers
git checkout ${version:-4}
git pull
cd bin
bash ./sb--ddev-hook--pre-start--${system:-typo3}
