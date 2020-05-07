# albumart-üeber
A fun little bash project.

## Rationale
I was inspired by reddit [thread](https://www.reddit.com/r/unixporn/comments/3q4y1m/openbox_music_now_with_tmux_and_album_art/) but I quickly realised I could have something more robust if I used überzug instead of w3m.

### Use case

### Credits
I particularly credit these two redditors for inspiring this project:
* [u/Dylan112](https://www.reddit.com/user/Dylan112/) — also on GitHub: [dylan](https://github.com/dylanaraps), https://github.com/dylanaraps/dotfiles/commit/c89b7da3d5dba54e36629dce0ab792a61fc575ec
* [u/drunkangel](https://www.reddit.com/user/drunkangel/) in this [comment](https://www.reddit.com/r/unixporn/comments/3q4y1m/openbox_music_now_with_tmux_and_album_art/cwdld2t/) — who suggested pathfinding logic I still use in a modified form

## Currently tested terminals
* [Alacritty](https://github.com/alacritty/alacritty)
* Xfce4-terminal
* Xfce4-terminal with `tmux`


## Dependencies
* `mpd` — the music player
* `ueberzug` — a library for viewing images in the terminal
* `bash` — the shell for this project, mandated by `ueberzug`

## To-Dos
* [ ] Add screenshots to the repo
* [ ] Code cleanup
* [ ] Remove hardcoded paths
