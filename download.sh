cd .ddev || exit 1

if [[ -e .ddev-helpers-config ]]; then
  source .ddev-helpers-config
fi

if [[ ! -d .ddev-helpers/.git ]]; then
  rm -rf .ddev-helpers
  git clone --quiet https://github.com/sourcebroker/ddev-helpers/ .ddev-helpers >/dev/null 2>&1 || exit 1
fi

cd .ddev-helpers || exit 1

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 1
repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 1
[[ "$repo_root" == "$(pwd)" ]] || exit 1

branch="${version:-latest}"

git fetch origin --prune --quiet >/dev/null 2>&1 || exit 1
git reset --hard "origin/$branch" >/dev/null 2>&1 || exit 1
git clean -fd >/dev/null 2>&1 || exit 1

cd bin || exit 1
bash "./sb--ddev-hook--pre-start--${system:-typo3}"