LEADTOOLS Command Line Quick Viewer
================================================================

This is a command line (console) application that allows you to
view any image file.  This application will load the specified
images from the specified folder and view them in “slide-show”
style.  Options are provided for controlling delay, paint
effect, zooming, etc. 

Quick Viewer parameters and switches:
----------------------------------------------------------------

The general syntax for the LQV application command line is:
LQV [Drive:]Source [/E] [/S] [/T] [/K] [/VF] [/VS] [/VZ]

The LQV application always takes at least one parameter, which
is the source image path.  One or more images can be viewed by
specifying a filter in addition to the source path.
	ex “C:\SrcDir\Image1.jpg”	// View Image1.jpg from the source directory
	ex “C:\ SrcDir\*.*		// View all images in the source directory
	ex. “C:\SrcDir\bab*.jpg”	// View all JPEG files that starts with “bab”

The following are descriptions for each of the LQV arguments:
· [Drive:][Source]: Specifies drive, source images directory to
display.

·/S: Specifies sub-directories of the source directory should be
recursed.  All supported images in the root and sub-directories
will be displayed.
	ex. “C:\SrcDir\*.* /S”

·/E: Specifies the paint effect to use when displaying the
images.
	ex. “C:\SrcDir\*.* /E2000	// Wipe left to right
NOTE: For a full list of the available paint effects, use the
(?) with the /E flag.
	ex. /E?

·/T: Specifies the time in milliseconds to wait before
displaying the next image.  If this flag is not specified, the
default sleep time is 2 sec.
	ex. “C:\SrcDir\*.* /T3000	// wait 3 sec.  

·/K: If this flag is specified, then the next image will not
displayed until a key is pressed.
	ex. “C:\SrcDir\*.* /K
NOTE: If the /T flag is specified with the /K flag, then the next
image will be displayed if the sleep time has elapsed before a key
is pressed or if a key is pressed before the sleep time has
elapsed.

·/VZ: Specifies a customized zoom value.
	ex. C:\SrcDir\*.* /VZ50	//Display the image at half size (50%)

·/VF: Specifies the image should be fit to window.
	ex. C:\SrcDir\*.* /VF

·/VS: Specifies the image should be stretched to window.
	ex. C:\SrcDir\*.* /VS

·/NOUI: If this flag is specified, then the application will not wait
for the user to press any key after the WELCOME message is displayed.
It will display the message and continue the rendering process.