# RetroPie Convert Videos

A tool for RetroPie to convert videos.

**WARNING: The Raspberry Pi doesn't have that much power and converting videos is very demanding. It takes about 35 seconds to convert a video, so if you have a lot of videos... Do the math ;)**

## Prerequisites

At this moment this script only works with videos downloaded using [Steven Selph's Scraper](https://github.com/retropie/retropie-setup/wiki/scraper#steven-selphs-scraper).

**Use rom folder for gamelist & images** option in Steven Selph's Scraper must be set to **Enabled**.

## Installation

```
cd /home/pi/
git clone https://github.com/hiulit/RetroPie-Convert-Videos/.git
cd RetroPie-Convert-Videos/
sudo chmod +x retropie-convert-videos.sh
```

## Usage

```
./retropie-convert-videos.sh [OPTIONS]
```

If no options are passed, you will be prompted with a usage example:

```
USAGE: ./retropie-convert-videos.sh [OPTIONS]

Use '--help' to see all the options.
```

## Options

* `--help`: Print the help message and exit.
* `--from-color [OPTIONS]`: Set Color Encoding System (C.E.S) to convert from. **(optional)**
* `--to-color [OPTIONS]`: Set Color Encoding System (C.E.S) to convert to. **(mandatory)**
* `--convert-all`: Convert videos for all systems.
* `--convert-system`: Select a system (or more) to convert videos.

## Examples

### `--help`

Print the help message and exit.

#### Example

```
./retropie-convert-videos.sh --help
```

### `--from-color [OPTIONS]` (optional)

Set Color Encoding System (C.E.S) to convert from.

Target only videos with this particular C.E.S.
If left blank, it will target all videos, regardless of the C.E.S.

#### Options

* `C.E.S` - Color Encoding System (C.E.S) to convert from.

#### Example

```
./retropie-convert-videos.sh --from-color yuv444p
```

### `--to-color [OPTIONS]` (mandatory)

Set Color Encoding System (C.E.S) to convert to.

Convert videos to this particular C.E.S.

#### Options

* `C.E.S` - Color Encoding System (C.E.S) to convert to.

#### Example

```
./retropie-convert-videos.sh --to-color yuv420p
```

### `--convert-all`

Convert videos for all systems.

Checks the [config file](/retropie-convert-videos-settings.cfg) to see if at least the `to_color` key has a value.

#### Example

```
./retropie-convert-videos.sh --convert-all
```

### `--convert-system`

Select a system (or more) to convert videos.

Displays a checklist from which one or more systems can be selected.

Checks the [config file](/retropie-convert-videos-settings.cfg) to see if at least the `to_color` key has a value.

#### Example

```
./retropie-convert-videos.sh --convert-system
```

![RetroPie Convert Videos checklist example](examples/retropie-convert-videos-checklist.jpg)

## Config file

When setting the C.E.S using `--from-color` or `--to-color`, the generated values are stored in `retropie-convert-videos-settings.cfg`.

```
# Settings for RetroPie Convert Videos.
#
# TIP: run the 'avconv -pix_fmts' command to get a full list of Color Encoding Systems (C.E.S).

# From color (optional)
# Target only videos with this particular C.E.S.
# If left blank, it will target all videos, regardless of the C.E.S.
# (e.g. "yuv444p")

from_color = ""

# To color (mandatory)
# Convert videos to this particular C.E.S.
# (e.g. "yuv420p")

to_color = ""
```

You can edit this file directly instead of using `--from-color` or `--to-color`.

## Changelog

See [CHANGELOG](/CHANGELOG.md).

## Contributing

See [CONTRIBUTING](/CONTRIBUTING.md).

## Authors

* Me 😛 [@hiulit](https://github.com/hiulit).

## Credits

Thanks to:

* [Clyde](https://retropie.org.uk/forum/user/clyde) - For [posting the code in the RetroPie forum](https://retropie.org.uk/forum/topic/15362/here-s-a-script-to-batch-convert-yuv-4-4-4-videos-to-yuv-4-2-0-in-retropie-linux) that inspired this script.

## License

[MIT License](/LICENSE).
