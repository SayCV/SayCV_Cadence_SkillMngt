LEADTOOLS Command Line File Converter
================================================================

This is a command line (console) application that allows you to
convert any image file format to any other image file format.
Options are provided for single or batch image file conversion.
The application also provides options to change the image’s Bits
Per Pixel (Pixel-Depth) or resolution (Width x Height) during
the conversion.


File converter parameters and switches:
----------------------------------------------------------------
The general syntax for the LFC application command line is:
LFC [Drive:]Source [Drive:][Target] [/F] [/B] [/Q] [/S] [/L] [/R]

The file converter always takes at least one parameter, which is
the path for the source image(s) for the conversion.  When only
the source directory/image is specified, the destination
directory will be the same as the source directory.  The
destination directory for the converted image(s) can be
specified by inserting a space between the source and
destination directories.
	ex. “C:\SrcDir” or “C:\ SrcDir C:\DestDir”

Specify a filter in the syntax of the source directory to limit
the files for the conversion.  In this case, only the files with
the user specified filter will be converted.
 	ex. “C:\SrcDir\bab*.jpg”

The following are descriptions for each of the LFC arguments:
·[Drive:][Source]: Specifies drive, source images directory to
convert.
·[Drive:][Target]: Specifies drive, target images directory for
output.
·/S: Specifies sub-directories of the source directory should be
recursed.  All supported images in the root and sub-directories
of the source directory will be converted.  In this case, the
directory tree from the source directory will be re-created in
the target directory.
	ex. “C:\SrcDir C:\DestDir /S”

·/B: Specifies the target images BitsPerPixel.  If this flag is
not specified, the image(s) will be saved with the original
image BPP.  Valid values for BPP depend on the target output
format.
NOTE: If the specified BPP is not supported for the target file
format, then the nearest smaller supported BPP will be used as
the target BPP.
	ex. “C:\SrcDir C:\DestDir /B24”

·/F: Specifies the output format for the conversion.  Can be
specified with either an integer value (ex. /F2) or friendly
name of one of the LEAD supported file formats (ex. /F=FILE_GIF).
When the friendly name is used, the (=) must be inserted between
the flag and the friendly name (ex. /F=FILE_BMP).  If this flag
is not specified, FILE_CMP (5) will be used as the default output
format.
NOTE: For a full list of LEAD supported file formats and their
friendly names, use the (?) with the /F flag (ex. /F?).
	ex. “C:\SrcDir C:\DestDir /F2”			//for GIF
	ex. “C:\SrcDir C:\DestDir /F=FILE_GIF”		//for GIF
	ex. “C:\SrcDir C:\DestDir /F25”			//for CCITT TIFF
	ex. “C:\SrcDir C:\DestDir /F=FILE_CCITT”	//for CCITT TIFF
	ex. “C:\SrcDir C:\DestDir /F10”			//for JPEG
	ex. “C:\SrcDir C:\DestDir /F=FILE_JFIF”	//for JPEG

·/Q: Specifies the target image quality factor, when the output
format supports compression.  Valid values are in the range 2-255.
If this flag is not specified, 120 will be used as the default
value.
	ex. “C:\SrcDir C:\DestDir /Q255”

·/R: Specifies target image dimensions (ex. /R800x600).  The
original image aspect ratio can be maintained by specifying only
one dimension or by entering (?) or (0) for  the image width or
height argument.
	ex. “C:\SrcDir C:\DestDir /R???x600”	//width auto-calculated to maintain aspect
	ex. “C:\SrcDir C:\DestDir /R800		//height auto-calculated to maintain aspect

·/L: Specifies to create a log file that contains each file
conversion result.  If you do not specify a location, the default
log file will be (C:\ConvLog.txt).
	ex. C:\SrcDir C:\DestDir /L“C:\LogDir\LogFile.txt”
	ex. C:\SrcDir C:\DestDir /L

·/NOUI: If this flag is specified, then the application will not wait for the user to press
any key after the WELCOME message is displayed.  It will display the message and continue
the conversion process.