# Dotfiles

My dotfiles setup using [Dotbot](https://github.com/anishathalye/dotbot/).


## Setup

```
git clone git@github.com:hmajid2301/dotfiles.git
cd dotfiles 
make install profile=devcontainer
```

### VSCode

To use with VSCode devcontainers, add the following to your `settings.json` file.


```json
"dotfiles.repository": "hmajid2301/dotfiles",
"dotfiles.targetPath": "~/dotfiles",
"dotfiles.installCommand": "~/dotfiles/install.devcontainer.sh",
```

## Appendix

- <a href="https://www.flaticon.com/free-icons/dot" title="dot icons">Dot icons created by Roundicons - Flaticon</a>
