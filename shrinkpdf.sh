#!/bin/sh

# https://github.com/aklomp/shrinkpdf
# Licensed under the 3-clause BSD license:
#
# Copyright (c) 2014-2025, Alfred Klomp
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

create_tempdir ()
{
	if command -v mktemp >/dev/null 2>&1; then
		# Possibly unportable, but far more secure than the fallback below
		mktemp -d
	else
		# Fallback method
		temp_base="${TMPDIR:-/tmp}"
		# $RANDOM might be undefined, but including a possibly empty string doesn't hurt
		# shellcheck disable=SC3028
		temp_dir="$temp_base/shrinkpdf.sh.$$.$RANDOM.$(date +%s)"

		if mkdir "$temp_dir" 2>/dev/null; then
			chmod 700 "$temp_dir"
			echo "$temp_dir"
		else
			echo "could not create temporary directory $temp_dir." >&2
			exit 1
		fi
	fi
}

cleanup_tempdir ()
{
	if [ -n "$1" ] ; then
		rm -f "$1/output.pdf"
		# ShellCheck complains about ls and weird filenames, but we only care about the number of newlines
		# shellcheck disable=SC2012
		if [ "$( ls -A "$1" 2>/dev/null | wc -l )" -eq 0 ] ; then
			# only rm -fr if the directory is empty to avoid recursive deletion catastrophe bugs
			rm -fr "$1"
		fi
	fi
}

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
	  -dColorImageDownsampleThreshold="$5"	\
	  -dGrayImageDownsampleType=/Bicubic	\
	  -dGrayImageResolution="$3"		\
	  -dGrayImageDownsampleThreshold="$5"	\
	  -dMonoImageDownsampleType=/Subsample	\
	  -dMonoImageResolution="$3"		\
	  -dMonoImageDownsampleThreshold="$5"	\
	  -sOutputFile="$2"			\
	  ${gray_params}			\
	  "$1"
}

get_pdf_version ()
{
	# $1 is the input file. The PDF version is contained in the
	# first 1024 bytes and will be extracted from the PDF file.
	pdf_version=$(head -c 1024 "$1" | LC_ALL=C awk 'BEGIN { found=0 }{ if (match($0, "%PDF-[0-9]\\.[0-9]") && ! found) { print substr($0, RSTART + 5, 3); found=1 } }')
	if [ -z "$pdf_version" ] || [ "${#pdf_version}" != "3" ]; then
		return 1
	fi
}

check_input_file ()
{
	# Check if the given file exists.
	if [ ! -f "$1" ]; then
		echo "Error: Input file does not exist." >&2
		return 1
	fi
}

check_smaller ()
{
	# If $1 and $2 are regular files, we can compare file sizes to
	# see if we succeeded in shrinking.
	if [ ! -f "$1" ] || [ ! -f "$2" ]; then
		echo 0;
		return;
	fi
	ISIZE="$(wc -c "$1" | awk '{ print $1 }')"
	OSIZE="$(wc -c "$2" | awk '{ print $1 }')"
	if [ "$ISIZE" -lt "$OSIZE" ]; then
		echo 1;
	else
		echo 0;
	fi
}

check_overwrite ()
{
	# If $1 and $2 refer to the same file, then the file would get
	# truncated to zero, which is unexpected. Abort the operation.
	# Unfortunately the stronger `-ef` test is not in POSIX.
	if [ "$1" = "$2" ]; then
		echo "The output file is the same as the input file. This would truncate the file." >&2
		echo "Use a temporary file as an intermediate step, or use the -i flag." >&2
		return 1
	fi
}

usage ()
{
	echo "Reduces PDF filesize by lossy recompressing with Ghostscript."
	echo "Not guaranteed to succeed, but usually works."
	echo
	echo "Usage: $1 [-g] [-h] [-o output] [-r res] [-t threshold] infile"
	echo
	echo "Options:"
	echo " -g  Enable grayscale conversion which can further reduce output size."
	echo " -h  Show this help text."
	echo " -o  Output file, default is standard output."
	echo " -r  Resolution in DPI, default is 72."
	echo " -t  Threshold multiplier for an image to qualify for downsampling, default is 1.5"
	echo " -i  Inplace operation: Overwrite the input file with the output if smaller. Use with caution."
}

# Set default option values.
grayscale=""
ofile="-"
res="72"
threshold="1.5"
inplace=0

# Parse command line options.
while getopts ':hgo:ir:t:' flag; do
  case $flag in
    h)
      usage "$0"
      exit 0
      ;;
    g)
      grayscale="YES"
      ;;
    o)
      if [ "-" = "$ofile" ] ; then
      	ofile="${OPTARG}"
      else
      	echo "invalid combination of options -o and -i."
      	exit 1
      fi
      ;;
    i)
      if [ "-" = "$ofile" ] ; then
      	temp_dir=$(create_tempdir)
      	# I actually want this string expanded right here.
      	# shellcheck disable=SC2064
      	trap "cleanup_tempdir \"$temp_dir\"" EXIT INT TERM
      	ofile="$temp_dir/output.pdf"
      	inplace=1
      else
      	echo "invalid combination of options -o and -i."
      	exit 1
      fi
      ;;
    r)
      res="${OPTARG}"
      ;;
    t)
      threshold="${OPTARG}"
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

# Check if input file exists
check_input_file "$ifile" || exit $?

# Check that the output file is not the same as the input file.
check_overwrite "$ifile" "$ofile" || exit $?

# Get the PDF version of the input file.
get_pdf_version "$ifile" || pdf_version="1.5"

# Shrink the PDF.
shrink "$ifile" "$ofile" "$res" "$pdf_version" "$threshold" || exit $?

# Check that the output is actually smaller.
if [ 1 -eq "$(check_smaller "$ifile" "$ofile")" ] ; then
	# file got bigger, just overwrite with the smaller original
	echo "Input smaller than output, doing straight copy" >&2
	cp "$ifile" "$ofile"
else
	# file has shrunk
	if [ 1 -eq "$inplace" ] ; then
		# user requested inplace operation, so overwrite the original
		# input file with the temporary and smaller output
		cp "$ofile" "$ifile"

		# if not inplace:
		# noting to do, output has already been written to the right place
	fi
fi
