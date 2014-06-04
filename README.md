# Shrinkpdf: shrink PDF files with Ghostscript

A simple wrapper around Ghostscript to shrink PDFs (as in reduce filesize)
under Linux. Inspired by some code I found in an OpenOffice Python script (I
think). The script feeds a PDF through Ghostscript, which performs lossy
recompression by such methods as downsampling the images to 72dpi. The result
should be (but not always is) a much smaller file.

## Usage

Download the script by clicking the filename at the top of the box. Make it
executable. If you run it with no arguments, it prints a usage summary. If you
run it with a single argument -- the name of the pdf to shrink -- it writes the
result to `stdout`:

```sh
./shrinkpdf.sh in.pdf > out.pdf
```

You can also provide a second filename for the output:

```sh
./shrinkpdf.sh in.pdf out.pdf
```

If both the input and the output are regular files, the script checks if the
output is actually smaller. If not, it writes a message to `stderr` and copies
the input over the output.

Sorry, Windows users; this one is Linux only. A Windows adaptation of this
script can be found [on this blog](http://dcm684.us/wp/2013/10/pdf-shrink/).
It's a bit more user-friendly than my barebones version and also supports
drag-and-drop.

## License and acknowledgements

The script is licensed under the [BSD
3-clause](http://opensource.org/licenses/BSD-3-Clause) license.

I didn't invent the wheel, just packaged it nicely. All credits go to the
[Ghostscript](http://www.ghostscript.com) team.

Many thanks to Dr. Alun J. Carr for fixing a portability issue on Mac OS X
regarding leading whitespace in the output of `wc`.
