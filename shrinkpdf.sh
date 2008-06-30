#!/bin/sh

gs	-q -dNOPAUSE -dBATCH -dSAFER \
	-sDEVICE=pdfwrite \
	-dCompatibilityLevel=1.3 \
	-dPDFSETTINGS=/screen \
	-dEmbedAllFonts=true \
	-dSubsetFonts=true \
	-dColorImageDownsampleType=/Bicubic \
	-dColorImageResolution=72 \
	-dGrayImageDownsampleType=/Bicubic \
	-dGrayImageResolution=72 \
	-dMonoImageDownsampleType=/Bicubic \
	-dMonoImageResolution=72 \
	-sOutputFile=out.pdf \
	 $1
