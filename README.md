# RetroPie Convert Videos

A tool for RetroPie to convert videos.

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
* `--from-color [C.E.S]`: Set Color Encoding System (C.E.S) to convert from.
* `--to-color [C.E.S]`: Set Color Encoding System (C.E.S) to convert to.
* `--convert-all`: Convert videos for all systems.
* `--convert-system`: Select a system (or more) to convert videos.

## Examples

### `--help`

Print the help message and exit.

#### Example

```
./retropie-convert-videos.sh --help
```

### `--from-color [OPTIONS]`

Set Color Encoding System (C.E.S) to convert from.

#### Options

* `C.E.S` - Color Encoding System (C.E.S) to convert from.

#### Example

```
./retropie-convert-videos.sh --from-color yuv444p
```

### `--to-color [OPTIONS]`

Set Color Encoding System (C.E.S) to convert to.

#### Options

* `C.E.S` - Color Encoding System (C.E.S) to convert to.

#### Example

```
./retropie-convert-videos.sh --to-color yuv420p
```

### `--convert-all`

Convert videos for all systems.

#### Example

```
./retropie-convert-videos.sh --convert-all
```

### `--convert-system`

Select a system (or more) to convert videos.

Displays a checklist from which one or more systems can be selected.

#### Example

```
./retropie-convert-videos.sh --convert-system
```
