# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Added

- Users can now send messages to other users

## [0.8.2] - 2022-01-04

### Added

- Prompt to fetch new content appears when a new topic is made in the active board

### Changed

- New Topic button moved
- Boards now display their topics in a child LiveView (instead of LiveComponent)
- Deleting posts is now confirmed with Phoenix.HTML's data-confirm prompt
- Disabling and re-enabling users is now confirmed with Phoenix.HTML's data-confirm prompt
- Disabling a user will clear the "user enabled" flash in the Admin panel, and vice versa
- Minor styling changes

## [0.8.1] - 2021-10-08

### Fixed

- CSP headers fixed to allow AWS S3 connections

## [0.8] - 2021-10-07

### Added

- Links to topics will now appear greyed after a user has read the topic

### Security

- Enabled HTTP Content Security Policy

## [0.7.1] - 2021-09-27

### Fixed

- Avatar uploads now work properly over HTTPS

## [0.7] - 2021-09-27

### Added

- AWS S3 integration for user avatars

### Fixed

- Swoosh Mailjet adapter re-enabled
- New Topic validation errors are now properly aligned with the form

## [0.6] - 2021-09-16

### Added

- Pagination of topic list with "infinite scroll"

### Changed

- All html templates upgraded to HEEx
- Post and Topic creation operations are now performed atomically with `Ecto.Multi`
- User info is no longer cached; now efficiently preloaded from the DB as needed
- Post and Topic listings are now temporary assigns to further reduce the amount of data held in memory
- Test suite organized into many smaller modules

### Fixed

- Fixed some links not resetting scroll position upon click

## [0.5.2] - 2021-06-02

### Changed

- Optimized some styling by replacing string interpolation with IO Lists

### Fixed

- Users online list now properly displays all guests
- Fixed a bug where disconnected users would still be shown as online
- Users can now properly reset their avatar even if the file was corrupted or missing

## [0.5.1] - 2021-05-28

### Changed

- Flash messages in User Settings and Admin Panel are now dismissed on click
- Validation of replies now waits for form submit to display error

### Fixed

- Fixed a bug where navigating from the Index directly to a Topic might not cache some necessary user data, causing a LV crash upon returning to the Board

## [0.5] - 2021-05-24

### Added

- Administrator account: can edit and delete posts
- Admin Panel: allows administrator to disable unwanted user accounts
- Users can now edit and delete their own posts
- Timestamp and user attribution is shown below edited posts
- Live updates site-wide after post/reply deletion
- Main Index now shows other users who are currently online

### Changed

- New topics are now shown live to all board viewers

### Fixed

- Login prompt now positioned properly on all screen sizes
- A post and reply with the same database ID will no longer have ID conflicts
- Cancel link on post editor now works properly even when errors are displayed
- Post edit validation no longer undoes changes when the form is completely empty
- Post view/reply counts now use singular grammar when the count is one
- Various styling fixes site-wide
- Post listing now loads properly when returning to board from "create post" form

## [0.4.1] - 2021-05-04

### Fixed

- Markdown is now properly parsed in user profiles' last 5 posts

## [0.4] - 2021-05-03

### Added

- Test suite for all app features
- Email verification implemented with Swoosh's Mailjet adapter
- Clicking a username now shows user's profile with their five most recent posts
- Registered users can now select an alternate "dark" theme in the settings menu
- Users can now use Markdown to format posts and replies
- User post count, avatar, and title updates instantly show site-wide for all users
- New replies to a post are now shown to all viewers instantly

### Changed

- Auto-scroll to the top of the page when clicking a live_patch
- CI checks coverage % of the test suite with codecov.io
- User confirmation moved into the LiveView
- Forum display, user menu, and settings now separated into Live Components
- Changing user settings will no longer re-mount the LiveView

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

[Unreleased]: https://github.com/APB9785/phxBB/compare/0.8.2...HEAD
[0.8.2]: https://github.com/APB9785/phxBB/compare/0.8.1...0.8.2
[0.8.1]: https://github.com/APB9785/phxBB/compare/0.8...0.8.1
[0.8]: https://github.com/APB9785/phxBB/compare/0.7.1...0.8
[0.7.1]: https://github.com/APB9785/phxBB/compare/0.7...0.7.1
[0.7]: https://github.com/APB9785/phxBB/compare/0.6...0.7
[0.6]: https://github.com/APB9785/phxBB/compare/0.5.2...0.6
[0.5.2]: https://github.com/APB9785/phxBB/compare/0.5.1...0.5.2
[0.5.1]: https://github.com/APB9785/phxBB/compare/0.5...0.5.1
[0.5]: https://github.com/APB9785/phxBB/compare/0.4.1...0.5
[0.4.1]: https://github.com/APB9785/phxBB/compare/0.4...0.4.1
[0.4]: https://github.com/APB9785/phxBB/compare/0.3.1...0.4
[0.3.1]: https://github.com/APB9785/phxBB/compare/0.3...0.3.1
[0.3]: https://github.com/APB9785/phxBB/compare/0.2...0.3
[0.2]: https://github.com/APB9785/phxBB/compare/0.1...0.2
[0.1]: https://github.com/APB9785/phxBB/releases/tag/0.1
