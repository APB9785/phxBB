# phxBB
[![Elixir CI](https://github.com/APB9785/phxBB/actions/workflows/elixir.yml/badge.svg)](https://github.com/APB9785/phxBB/actions/workflows/elixir.yml)
[![Coverage Status](https://coveralls.io/repos/github/APB9785/phxBB/badge.svg?branch=master)](https://coveralls.io/github/APB9785/phxBB?branch=master)
![GitHub](https://img.shields.io/github/license/APB9785/phxBB)
![GitHub last commit](https://img.shields.io/github/last-commit/APB9785/phxBB)

**phxBB** is a re-imagining of classic message board software such as phpBB and vBulletin.  It uses Phoenix LiveView to establish a persistent WebSocket connection with each user, providing real-time updates, navigation, and interaction without any full page reloads after the user is logged in.  

## Features

- Real-time content updates via `Phoenix.PubSub`
- Upload your own image for a user avatar via AWS S3
- User authentication with `phx.gen.auth`
- Live form validations
- All site navigation (minus login) done via LiveView patching - no page reloads!
- Markdown parsing in posts with `Earmark` + `PhoenixHtmlSanitizer`
- See who's online with `Phoenix.Presence`
- Full test suite

## What's New - v0.7

- User avatars hosted on AWS S3

See [CHANGELOG.md](https://github.com/APB9785/phxBB/blob/master/CHANGELOG.md) for the full list of changes

## Demo

You can try a demo of phxBB [here](https://phxbb.herokuapp.com/forum)! Note that you must register and login before making any new posts.

## Installation   

To start a local phxBB server:
  * [Ensure that your system has Phoenix and its dependencies installed](https://hexdocs.pm/phoenix/installation.html)
  * Install app dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Install Node.js dependencies with `npm install` inside the `assets` directory
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Check out the [Phoenix deployment guides](https://hexdocs.pm/phoenix/deployment.html).
