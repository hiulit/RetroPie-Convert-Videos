# Changelog

## [Unreleased]

* Up to date

## [3.1.0] - 2020-25-02

### Fixed

* Replaced legacy `libav-tools` (~~`avprobe`~~) commands for the new `ffmpeg`'s equivalents (`ffprobe`).

## [3.0.0] - 2020-20-02

**NOTE:** This release may contain breaking changes!

### Deprecated

* ~~`libav-tools`~~ for `ffmpeg`.

### Added

* New option `--gui` to start the GUI. It lets you perform all the functions, but in a more friendly manner. If `standalone` is passed as a parameter, the script doesn't check if RetroPie is installed, which it does by default.

## [2.1.2] - 2019-12-28

### Fixed

* The `check_CES()` function was checking incorrectly if the C.E.S from the video was equal to `from_ces` and thus not converting the videos.

## [2.1.1] - 2019-12-26

### Fixed

* Skyscraper's videos path in [#5](https://github.com/hiulit/RetroPie-Convert-Videos/pull/5).

## [2.1.0] - 2019-04-17

### Added

* New option `--path` to set the path to the ROMs folder. By default it's `/home/pi/RetroPie/roms`.
* Warning dialog when using the `--convert-all` option saying that it can take a lot of time to convert all the videos.
* Better detection of dependencies.
* Better error outputs.

## [2.0.0] - 2019-04-15

**NOTE:** This release contains breaking changes!

### Deprecated

* ~~`--convert-system`~~ now is `--convert-systems`.
* ~~`--from-color`~~ now is `--from-ces`.
* ~~`--to-color`~~ now is `--to-ces`.

### Added

* Support for [Lars Muldjord's Skyscraper](https://github.com/retropie/retropie-setup/wiki/scraper#lars-muldjords-skyscraper).
* New option `--scraper` to set the scraper. Available scrapers: `sselph` and `skyscraper`.
* `--convert-systems` now accepts systems as (optional) arguments (e.g. `--convert-systems "nes snes"`).
* The script now detects the **C.E.S** of the video and if it is the same as the `from_ces` value, it won't convert the video.
* New log system. Log files are stored in `logs/`.
* Print script version with `--version`.
* Added a progress bar!

### Changed

* Search for all `.mp4` video files instead of just `-video.mp4` so the script can work with many scrapers.

## [1.0.2] - 2018-02-06

### Fixed

* Fixed some outputs.
* Fixed git clone URL in `README.md`.

### Added

* Merged [#3](https://github.com/hiulit/RetroPie-Convert-Videos/pull/3) - Thanks to [Dan Edwards](https://github.com/edwardsd97) 

## [1.0.1] - 2018-01-11

### Fixed

* Changed `--from_color` option to `--from-color`.

## [1.0.0] - 2018-01-10

* Released version [1.0.0](https://github.com/hiulit/RetroPie-Fun-Facts-Splashscreens/releases/tag/1.0.0).
