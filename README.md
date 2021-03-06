# phxBB
[![Elixir CI](https://github.com/APB9785/phxBB/actions/workflows/elixir.yml/badge.svg)](https://github.com/APB9785/phxBB/actions/workflows/elixir.yml)
[![codecov](https://codecov.io/gh/APB9785/phxBB/branch/master/graph/badge.svg?token=TCSP07KB1F)](https://codecov.io/gh/APB9785/phxBB)
![GitHub](https://img.shields.io/github/license/APB9785/phxBB)
![GitHub last commit](https://img.shields.io/github/last-commit/APB9785/phxBB)

**phxBB** is a re-imagining of classic message board software such as phpBB and vBulletin.  It uses Phoenix LiveView to establish a persistent WebSocket connection with each user, providing real-time updates, navigation, and interaction without any full page reloads after the user is logged in.  

## Features

- Server-side caching of user and post data within LiveView assigns
- Real-time content updates via `Phoenix.PubSub`
- Upload your own image for a user avatar
- User authentication with `phx.gen.auth`
- Email address confirmation via `Swoosh` + `Mailjet`
- Live form validations
- All site navigation (minus login) done via LiveView patching - no page reloads!
- Markdown parsing in posts with `Earmark` + `PhoenixHtmlSanitizer`
- See who's online with `Phoenix.Presence`
- Full test suite

## What's New - v0.5

- Administrator account: can edit and delete posts
- Admin Panel: allows administrator to disable unwanted user accounts
- Users can now edit and delete their own posts
- Main Index now shows other users who are currently online

See [CHANGELOG.md](https://github.com/APB9785/phxBB/blob/master/CHANGELOG.md) for the full list of changes

## Installation   

To start a local phxBB server:
  * [Ensure that your system has Phoenix and its dependencies installed](https://hexdocs.pm/phoenix/installation.html)
  * Install app dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Install Node.js dependencies with `npm install` inside the `assets` directory
  * Create a [Mailjet](http://www.mailjet.com/) account for sending account confirmation emails
  * Set [environment variables](https://en.wikipedia.org/wiki/Environment_variable) `MAILJET_API_KEY` and `MAILJET_SECRET_KEY`
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Check out the [Phoenix deployment guides](https://hexdocs.pm/phoenix/deployment.html).
