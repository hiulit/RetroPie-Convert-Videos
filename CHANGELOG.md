# Changelog

## [Unreleased]

### Added

* New option `--path` to set the path to the ROMs folder. By default it's `/home/pi/RetroPie/roms`.
* Warning dialog when using the `--convert-all` option saying that it can take a lot of time to convert all the videos.

### Changed

* Better detection of dependencies.

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
