# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Added

- CHANGELOG.md file now included
- View count for posts

### Changed

- Long topic titles are now shortened in the Main Index links

### Fixed

- Solved possible race condition during post creation
- DB queries reduced by adding new columns for post count and reply count

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

[unreleased]: https://github.com/APB9785/phxBB/compare/0.2...HEAD
[0.2]: https://github.com/APB9785/phxBB/compare/0.1...0.2
[0.1]: https://github.com/APB9785/phxBB/releases/tag/0.1
