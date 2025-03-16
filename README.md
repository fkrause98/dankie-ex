# Dankie

## Setup

1. Install nix:
```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | \
  sh -s -- install
```
2. [Install direnv](https://direnv.net/docs/installation.html) and run the following inside the root folder
```bash
direnv allow .
```
3. Get a token from the [BotFather](https://telegram.me/BotFather)
4. Set this token as an env var:
```bash
export BOT_TOKEN=<your-token>
```
5. Now you can start the bot with a repl:
```bash
iex -S mix
```
## Deploy
1. Follow the steps 1, 2, 3 and 4 from above.
2. Generate a release with `mix deps.get && MIX_ENV=prod mix env release` and follow the
   steps to start the bot.
