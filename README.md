# phxBB
![GitHub](https://img.shields.io/github/license/APB9785/phxBB)
![GitHub last commit](https://img.shields.io/github/last-commit/APB9785/phxBB)

**phxBB** is a re-imagining of classic message board software such as phpBB and   
vBulletin.  It uses Phoenix LiveView to establish a persistent connection with each   
user, holding and updating state for virtually instantaneous navigation and   
interaction without any full page reloads.   

## What's New - v0.3

- Topic view count
- Custom 404 page
- Timezone selection
- User titles
- User avatars
- User settings now handled within the LiveView

See [CHANGELOG.md](https://github.com/APB9785/phxBB/blob/master/CHANGELOG.md) for the full list of changes

## Installation   

To start a local phxBB server:
  * [Ensure that your system has Phoenix and its dependencies installed](https://hexdocs.pm/phoenix/installation.html)
  * Install app dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Install Node.js dependencies with `npm install` inside the `assets` directory
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Check out the [Phoenix deployment guides](https://hexdocs.pm/phoenix/deployment.html).
