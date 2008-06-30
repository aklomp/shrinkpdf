# Shrinkpdf: shrink PDF files with Ghostscript

The simplest shell script in the world to shrink your PDFs (as in reduce
filesize) under Linux with Ghostscript. Inspired by some code I found in an
OpenOffice Python script (I think). It feeds an existing PDF through
Ghostscript, downsamples the images to 72dpi, and does some other stuff. Pretty
straightforward.

## Usage

Download the script by clicking the filename at the top of the box. Then run:

```sh
# sh shrinkpdf.sh yourfile.pdf
```

This produces a shrunken file named `out.pdf` in the current directory.

Sorry, Windows users; this one is Linux only. Ghostscript does run under
Windows, but I don't know much about Windows scripting. You could try typing
all these parameters on the commandline by hand.
