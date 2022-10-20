#!/bin/sh

# https://github.com/aklomp/shrinkpdf
# Licensed under the 3-clause BSD license:
#
# Copyright (c) 2014-2022, Alfred Klomp
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
# 3. Neither the name of the copyright holder nor the names of its contributors
#    may be used to endorse or promote products derived from this software
#    without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.


shrink ()
{
	if [ "$grayscale" = "YES" ]; then
		gray_params="-sProcessColorModel=DeviceGray \
		             -sColorConversionStrategy=Gray \
		             -dOverrideICC"
	else
		gray_params=""
	fi

	# Allow unquoted variables; we want word splitting for $gray_params.
	# shellcheck disable=SC2086
	gs					\
	  -q -dNOPAUSE -dBATCH -dSAFER		\
	  -sDEVICE=pdfwrite			\
	  -dCompatibilityLevel="$4"		\
	  -dPDFSETTINGS=/screen			\
	  -dEmbedAllFonts=true			\
	  -dSubsetFonts=true			\
	  -dAutoRotatePages=/None		\
	  -dColorImageDownsampleType=/Bicubic	\
	  -dColorImageResolution="$3"		\
	  -dGrayImageDownsampleType=/Bicubic	\
	  -dGrayImageResolution="$3"		\
	  -dMonoImageDownsampleType=/Subsample	\
	  -dMonoImageResolution="$3"		\
	  -sOutputFile="$2"			\
	  ${gray_params}			\
	  "$1"
}

get_pdf_version ()
{
	# $1 is the input file. The PDF version is contained in the
	# first 1024 bytes and will be extracted from the PDF file.
	pdf_version=$(cut -b -1024 "$1" | awk '{ if (match($0, "%PDF-[0-9]\\.[0-9]")) { print substr($0, RSTART + 5, 3); exit } }')
	if [ -z "$pdf_version" ] || [ "${#pdf_version}" != "3" ]; then
		return 1
	fi
}

check_smaller ()
{
	# If $1 and $2 are regular files, we can compare file sizes to
	# see if we succeeded in shrinking. If not, we copy $1 over $2:
	if [ ! -f "$1" ] || [ ! -f "$2" ]; then
		return 0;
	fi
	ISIZE="$(wc -c "$1" | awk '{ print $1 }')"
	OSIZE="$(wc -c "$2" | awk '{ print $1 }')"
	if [ "$ISIZE" -lt "$OSIZE" ]; then
		echo "Input smaller than output, doing straight copy" >&2
		cp "$1" "$2"
	fi
}

check_overwrite ()
{
	# If $1 and $2 refer to the same file, then the file would get
	# truncated to zero, which is unexpected. Abort the operation.
	# Unfortunately the stronger `-ef` test is not in POSIX.
	if [ "$1" = "$2" ]; then
		echo "The output file is the same as the input file. This would truncate the file." >&2
		echo "Use a temporary file as an intermediate step." >&2
		return 1
	fi
}

usage ()
{
	echo "Reduces PDF filesize by lossy recompressing with Ghostscript."
	echo "Not guaranteed to succeed, but usually works."
	echo
	echo "Usage: $1 [-g] [-h] [-o output] [-r res] infile"
	echo
	echo "Options:"
	echo " -g  Enable grayscale conversion which can further reduce output size."
	echo " -h  Show this help text."
	echo " -o  Output file, default is standard output."
	echo " -r  Resolution in DPI, default is 72."
}

# Set default option values.
grayscale=""
ofile="-"
res="72"

# Parse command line options.
while getopts ':hgo:r:' flag; do
  case $flag in
    h)
      usage "$0"
      exit 0
      ;;
    g)
      grayscale="YES"
      ;;
    o)
      ofile="${OPTARG}"
      ;;
    r)
      res="${OPTARG}"
      ;;
    \?)
      echo "invalid option (use -h for help)"
      exit 1
      ;;
  esac
done
shift $((OPTIND - 1))

# An input file is required.
if [ -z "$1" ]; then
	usage "$0"
	exit 1
else
	ifile="$1"
fi

# Check that the output file is not the same as the input file.
check_overwrite "$ifile" "$ofile" || exit $?

# Get the PDF version of the input file.
get_pdf_version "$ifile" || pdf_version="1.5"

# Shrink the PDF.
shrink "$ifile" "$ofile" "$res" "$pdf_version" || exit $?

# Check that the output is actually smaller.
check_smaller "$ifile" "$ofile"
