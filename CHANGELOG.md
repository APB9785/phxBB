# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Added

- Email verification implemented with Swoosh's Mailjet adapter
- LiveView test suite - covers most major features
- Clicking a username now shows user's profile with their five most recent posts

### Changed

- JS Hook auto-scrolls to the top of the page when clicking a live_patch
- CI checks coverage % of the test suite with codecov.io
- User confirmation moved into the LiveView

## [0.3.1] - 2021-04-10

### Added

- Users can now remove their avatar if they wish not to have one
- Elixir CI with GitHub Actions

### Fixed

- Avatars are now deleted from the server when no longer in use
- Attempting to upload an avatar without first selecting a file will no longer crash the LiveView

## [0.3] - 2021-04-09

### Added

- CHANGELOG.md file now included
- Topics now track and display their view count
- Custom 404 page for all bad routes and params
- Users can now select a timezone and see timestamps adjusted accordingly
- Users can now choose a custom title to display beneath their username
- Readme now includes badges from shields.io
- Users can now upload an avatar to display with their posts

### Changed

- Long topic titles are now shortened in the Main Index links
- Postgres now handles sorting content by date (instead of Elixir process)
- Usernames are now stored with citext to ensure unique names
- User registration moved into the LiveView
- User settings moved into the LiveView
- Socket assigns now holds active User struct instead of user token
- Users must now log in before they will be allowed to see the New Topic form

### Fixed

- Solved possible race condition during post creation
- DB queries reduced by adding new columns for post count and reply count
- Tests updated to handle foreign key constraints
- Fixed a bug where a user's first reply could crash and re-mount the LiveView
- Page margins are now symmetrical at all screen sizes
- New Post and New Reply forms now have proper styling to match other forms

## [0.2] - 2021-03-25

### Added

- Live Navigation updates URL and page title but remains within the LiveView
- Latest post for each board is shown in the Main Index with a direct link
- GNU GPL-3.0 License file added
- Timestamp formatting made much more readable
- Author details and original post time now shown under each topic

### Changed

- New topic creation moved from the bottom of the board to its own view
- All views have updated styling including user account pages

### Fixed

- Fixed a bug with URLs leading directly to a post
- Alert width now matches content width

## [0.1] - 2021-03-16

### Added

- LiveView forum with Boards, Posts, and Replies
- Topic count and post count for each board
- User account authentication
- Tailwind CSS styling
- User cache for reduced DB queries
- Page title updates to reflect current view

[Unreleased]: ttps://github.com/APB9785/phxBB/compare/0.3.1...HEAD
[0.3.1]: https://github.com/APB9785/phxBB/compare/0.3...0.3.1
[0.3]: https://github.com/APB9785/phxBB/compare/0.2...0.3
[0.2]: https://github.com/APB9785/phxBB/compare/0.1...0.2
[0.1]: https://github.com/APB9785/phxBB/releases/tag/0.1
