# Shrinkpdf: shrink PDF files with Ghostscript

[![Shellcheck](https://github.com/aklomp/shrinkpdf/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/aklomp/shrinkpdf/actions/workflows/shellcheck.yml)
[![Test](https://github.com/aklomp/shrinkpdf/actions/workflows/test.yml/badge.svg)](https://github.com/aklomp/shrinkpdf/actions/workflows/test.yml)

A simple wrapper around Ghostscript to shrink PDFs (as in reduce filesize)
under Linux. Inspired by some code I found in an OpenOffice Python script (I
think). The script feeds a PDF through Ghostscript, which performs lossy
recompression by such methods as downsampling the images to 72dpi. The result
should be (but not always is) a much smaller file.

## Usage

Download the script and make it executable:

```sh
chmod +x shrinkpdf.sh
```

If you run it with no arguments, it prints a usage summary. If you run it with a
single argument -- the name of the pdf to shrink -- it writes the result to
`stdout`:

```sh
./shrinkpdf.sh in.pdf > out.pdf
```

You can provide an output file with the `-o` option:

```sh
./shrinkpdf.sh -o out.pdf in.pdf
```

And an output resolution in DPI (default is 72 DPI) with the `-r` option:

```sh
./shrinkpdf.sh -r 90 -o out.pdf in.pdf
```

Color-to-grayscale conversion can be enabled with the `-g` flag. This can
sometimes further reduce the output size:

```
./shrinkpdf.sh -g -r 90 -o out.pdf in.pdf
```

Set the threshold at which an image would be downsampled with the `-t` flag.
The default of 1.5 means that images which are already less than 1.5x the
desired dpi will not be resized. (Using `-r 300` and `-t 1.5` would not resize
images unless they were > 300 * 1.5 dpi, or 450 dpi.) Use lower numbers for
less leniency and higher numbers for more leniency.
```sh
./shrinkpdf.sh -r 300 -t 1.1 -o out.pdf in.pdf
```

Due to limitations of shell option handling, options must always come before
the input file.

If both the input and the output are regular files, the script checks if the
output is actually smaller. If not, it writes a message to `stderr` and copies
the input over the output.

Sorry, Windows users; this one is Linux only. A Windows adaptation of this
script can be found [on this blog](http://dcm684.us/wp/2013/10/pdf-shrink/).
It's a bit more user-friendly than my barebones version and also supports
drag-and-drop.

## License and acknowledgements

The script is licensed under the
[BSD 3-clause](http://opensource.org/licenses/BSD-3-Clause) license.

I didn't invent the wheel, just packaged it nicely. All credits go to the
[Ghostscript](http://www.ghostscript.com) team.
