# Game Console

A touch screen game console for an HP 24-f0024 All-in-One. It boots Debian straight into a full screen launcher of web games.

## Install on the console

1. Install Debian 13 minimal (no desktop; tick only "SSH server" and "standard system utilities"), with a user named `player`.
2. Log in and run:

   ```
   wget -qO- https://raw.githubusercontent.com/t22admin/game-console/main/setup.sh | sudo bash
   ```

   (If you set a root password during install, `sudo` won't exist; use this instead:)

   ```
   wget -qO- https://raw.githubusercontent.com/t22admin/game-console/main/setup.sh | su -c bash
   ```

3. It reboots into the console. Each boot pulls the latest games from this repo.

Admin escape: press Ctrl+Alt+F2 for a login prompt, or SSH in.

## Layout

- `launcher/` the home screen
- `games/games.json` the list of games shown on the launcher
- `games/<folder>/index.html` each game (should include a button back to `/launcher/`)
- `setup.sh` one-time console setup
