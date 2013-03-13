;============================================================================
;  Copyright (C) 2008 Dave Elder. All rights reserved.
;
;  Program Name: logoMaker_lt_public.il
;  Author: Dave Elder. dave.elder@tait.co.nz
;
;  Purpose:
;	Create graphics such as logos in Allegro based on bitmap-type images.
;
;	When using Allegro Layout, scaled and/or mirrored graphics are attached
;	to a mechanical symbol. This symbol may be subsequently moved.
;
;	By running this utility in the Allegro symbol editor you can create a
;	(non-scalable) symbol for placing in your company library.
;
;  Limitations:
;	potrace creates a Scalable Vector Graphics (SVG) file containing lines and
;	bezier curves to define the outline of polygons. This Skill program draws
;	the Bezier curves using a series of straight lines. In some instances this
;	will result in Allegro shapes that do not represent the original image well.
;	I will happily incorporate a circular arc fitting routine if a maths guru
;	has time to develop one and sends it to me.
;
;  Platforms:
;	Windows XP
;
;  Allegro verions:
;	16.x
;
;  Acknowledgements:
;	This utility relies heavily on the potrace open source code generously
;	provided by Peter Selinger.
;		http://potrace.sourceforge.net
;	It uses the LEAD Command Line Image File Converter currently provided
;	as a free download by Lead Technologies.
;		http://leadtools.com/Utilities/Cmd-Line/File-Converter/default.htm
;	
;
;  WARRANTYS:
;	None. This program is free software and is available as-is 
;	It may not work in all environments. There is no formal support.
;
;  Modification and Distribution
;	You may redistribute and/or modify this utility. However, in the open-source
;	spirit in which this is provided to the Cadence community, any improvements
;	and enhancements should be submitted to the originator for inclusion in future
;	releases.
;
;============================================================================
;
;  Installation instructions:

;	Download and install potrace:
;		http://potrace.sourceforge.net/download/potrace-1.8.tar.gz
;	set the POTRACE_PATH environment variable to the path to the executable
;		eg. C:/utils/potrace-1.8.win32-i386
;
;	Download and install lfc:
;		http://leadtools.com/Utilities/Cmd-Line/File-Converter/default.htm
;	You can set the LFC_PATH environment variable to the path to the executable
;	but you must move the files from the bin folder up to the same level.
;		eg. C:/utils/LEADCMD
;
;	Install logoMaker_lt_public.il and logoMaker_ltHelp.txt into your skill folder.
;	Add 'load("logoMaker_lt_public.il")' to the allegro.ilinit file in your pcbenv
;	folder.
;
;  Running within Allegro:
;	Type logoMaker_lt in the command window.
;
;============================================================================
;
;  History:
;
;  1.0	02-Jul-08 DE	Original.
;  1.1	14-Jul-08 DE	Added LFC_PATH. Requires DLL's to be in the same folder (as lfc.exe).
;
;============================================================================
;

axlCmdRegister("logoMaker_lt" 'logoMaker_lt_start); Must be interactive (the default).

defun( logoMaker_lt_start ()
 let((designUnits, p, formFile, (y 1), class, subclass, form)
  defvar(logoMaker_lt_potracePath, getShellEnvVar("POTRACE_PATH") || "C:/utils/potrace-1.8.win32-i386")
  defvar(logoMaker_lt_lfcPath, getShellEnvVar("LFC_PATH"))
  defvar(logoMaker_lt_lfcCmd, strcat(if(logoMaker_lt_lfcPath, strcat(logoMaker_lt_lfcPath, "\\", "")), "lfc.exe"))
  defvar(logoMaker_lt_tempFiles)
  designUnits = car(axlDBGetDesignUnits()), when(designUnits == "millimeters", designUnits = "mm")

  p = logoMaker_lt_formOpenFile("logoMaker_lt"), formFile = get_filename(p)
  
  logoMaker_lt_formHeader(p, 80, "Dave Elder's Logo Maker Utility")
  logoMaker_lt_formMessage(p, "infomsg", ?level 0, ?msgString "%s")
  logoMaker_lt_formMessage(p, "warnmsg", ?level 2, ?msgString "%s")
  logoMaker_lt_formMessage(p, "errormsg", ?level 3, ?msgString "%s")
  logoMaker_lt_formPopupDefine(p, "TURNPOLICY", '("black", "white", "right", "left", "minority", "majority", "random"))
  logoMaker_lt_formPopupDefine(p, "ROTATION", '(0 45 90 135 180 225 270 315))
  logoMaker_lt_formPopupDefine(p, "CLASS")
  logoMaker_lt_formPopupDefine(p, "SUBCLASS")
  logoMaker_lt_formStrFillin(p, "imagefile", 62, 199, 1, y, ?title "Image file:", ?x2 10)
  logoMaker_lt_formButton(p, "imagebrowse", "...", 75, y, 4, 3),  y = y + 3
  logoMaker_lt_formThumbnail(p, "pbmthumbnail", 47, y, 32, 19, ?options "stretch")
  
  logoMaker_lt_formGroup(p, "Pre-processing Settings", 1, y, 44, 19), y = y + 2
  logoMaker_lt_formChecklistItem(p, "makebitmap", 3, y, "Pre-process")
  logoMaker_lt_formButton(p, "mkbitmapdefaults", "Defaults", 36, y, 6, 3), y = y + 2
  logoMaker_lt_formText(p, "Pre-processes colour/greyscale image for improved tracing.", 3, y, ?label "mkbitmapinfo"), y = y + 2
  logoMaker_lt_formChecklistItem(p, "mkbitmapinvert", 3, y, "Invert the input (undo 'blackboard' effect)"), y = y + 2
  logoMaker_lt_formChecklistItem(p, "mkbitmaphipassfilter", 3, y, "Apply High Pass Filtering")
  logoMaker_lt_formText(p, "No Image Selected.", 54, y, ?label "noimage", ?options "CENTER")
  logoMaker_lt_formIntSlideBar(p, "mkbitmapfilterradius", 2, 2, 26, y, 0, 99, ?title "Radius:", ?fillInX 33, ?value 4), y = y + 2
  logoMaker_lt_formIntSlideBar(p, "mkbitmapscale", 2, 2, 3, y, 1, 99, ?title "Pre-scale:", ?fillInX 10, ?value 2), y = y + 2
  logoMaker_lt_formChecklistItem(p, "mkbitmapcubic", 3, y, "Use cubic interpolation", ?radioLabel "mkbitmapinterp")
  logoMaker_lt_formChecklistItem(p, "mkbitmaplinear", 23, y, "Use linear interpolation", ?radioLabel "mkbitmapinterp"), y = y + 2
  logoMaker_lt_formChecklistItem(p, "mkbitmapbilevel", 3, y, "Bilevel conversion", ?radioLabel "mkbitmapconversion")
  logoMaker_lt_formChecklistItem(p, "mkbitmapgrey", 23, y, "Greymap conversion", ?radioLabel "mkbitmapconversion"), y = y + 2
  logoMaker_lt_formRealFillin(p, "mkbitmapthreshold", 4, 4, 3, y, ?title "Bilevel Conversion Threshold:", ?fillInX 24, ?value 0.45)
  logoMaker_lt_formButton(p, "mkbitmaphelp", "Info", 38, y + 1, 4, 2), y = y + 3
  logoMaker_lt_formText(p, "Preview appears distorted if original is not square", 46, y, ?label "distorted"), y = y + 1

  logoMaker_lt_formGroup(p, "Tracing Options", 1, y, 78, 19), y = y + 2
  ;Algorithm options:
  logoMaker_lt_formStrFillin(p, "turnpolicy", 6, 8, 3, y, ?pop "TURNPOLICY", ?title "Turnpolicy:", ?x2 13)
  logoMaker_lt_formText(p, "- How to resolve ambiguities in path decomposition", 26, y)
  logoMaker_lt_formButton(p, "potracedefaults", "Defaults", 70, y, 6, 3), y = y + 2
  logoMaker_lt_formIntSlideBar(p, "turdsize", 3, 3, 3, y, 1, 999, ?title "Speckle Size:", ?fillInX 13, ?value 2, ?units "pixels")
  logoMaker_lt_formText(p, "- Suppress speckles of up to this size", 26, y), y = y + 2
  logoMaker_lt_formRealFillin(p, "alphamax", 5, 5, 3, y, ?title "Corner Threshold:", ?fillInX 16, ?minVal -1, ?maxVal 1.334, ?value 1.0)
  logoMaker_lt_formText(p, "- The smaller this value, the more sharp corners will be produced.", 26, y), y = y + 2
  logoMaker_lt_formChecklistItem(p, "longcurve", 3, y, "Curve Optimisation")
  logoMaker_lt_formText(p, "- Join adjacent Bezier curve segments when possible.", 26, y), y = y + 2
  logoMaker_lt_formRealFillin(p, "opttolerance", 4, 4, 3, y, ?title "Tolerance:", ?fillInX 12, ?minVal 0, ?maxVal 1.0, ?value 0.2)
  logoMaker_lt_formText(p, "- Curve optimization tolerance.", 26, y), y = y + 2
  logoMaker_lt_formIntSlideBar(p, "unitn", 2, 2, 3, y, 1, 99, ?title "Output Quantisation:", ?fillInX 18, ?value 10)
  logoMaker_lt_formText(p, "- Quantize output to 1/unit pixels.", 26, y), y = y + 2
  ;Frontend options:
  logoMaker_lt_formRealFillin(p, "blacklevel", 4, 4, 3, y, ?title "Black Level:", ?fillInX 13, ?minVal 0, ?maxVal 1.0, ?value 0.5)
  logoMaker_lt_formText(p, "- Black/white cutoff in input file.", 26, y), y = y + 2
  logoMaker_lt_formChecklistItem(p, "inverted", 3, y, "Inverted")
  logoMaker_lt_formText(p, "- Invert the input bitmap before processing.", 26, y)
  logoMaker_lt_formButton(p, "potracehelp", "Info", 72, y + 1, 4, 2)
  y = y + 4

  logoMaker_lt_formRealFillin(p, "width",  5, 5,  2, y, ?title "Width:",  ?fillInX  7, ?units designUnits)
  logoMaker_lt_formRealFillin(p, "height", 5, 5, 22, y, ?title "Height:", ?fillInX 27, ?units designUnits)
  logoMaker_lt_formChecklistItem(p, "aspectratio", 42, y, "Maintain Aspect Ratio")
  logoMaker_lt_formButton(p, "defaultsizes", "Default Size", 65, y, 12, 3), y = y + 3
  
  logoMaker_lt_formIntegerFillin(p, "rotation", 3, 4, 2, y, ?pop "ROTATION", ?title "Rotation:", ?fillInX 9, ?minVal -359, ?maxVal 359, ?value 0, ?units "degrees")
  logoMaker_lt_formText(p, "(Anticlockwise)", 25, y)
  logoMaker_lt_formChecklistItem(p, "mirror", 42, y, "Mirror")
  logoMaker_lt_formChecklistItem(p, "fixed", 52, y, "Fix Symbol"), y = y + 2

  logoMaker_lt_formText(p, "Class/Subclass for Graphics:", 2, y), y = y + 2
  logoMaker_lt_formPop(p, "class", "CLASS", 5, y, 19, ?options "prettyprint"), y = y + 2
  logoMaker_lt_formColor(p, "subcolour", 2, y, 2, 1)
  logoMaker_lt_formPop(p, "subclass", "SUBCLASS", 5, y, 19 ?options "prettyprint ownerdrawn")
  
  logoMaker_lt_formStrFillin(p, "symbolname", 27, 27, 30, y, ?title "Symbol Name:", ?x2 41), y = y + 3

  logoMaker_lt_formButton(p, "createlogo", "Place Logo", 30, y, 20, 4), y = y + 1
  logoMaker_lt_formButton(p, "quit", "Exit", 70, y, 8, 3)
  
  logoMaker_lt_formEnd(p)
  axlDMClose(p)
  form = axlFormCreate(gensym(), formFile, '(E INNER), 'logoMaker_lt_formAction, nil)
  deleteFile(formFile)
  
  axlFormColorize(form, "mkbitmapinfo", 'text, 'blue)
  logoMaker_lt_mkBitmapDefaults(form)
  axlFormSetFieldVisible(form, "distorted", 0)
  axlFormColorize(form, "distorted", 'text, 'blue)
  logoMaker_lt_potraceDefaults(form)
  foreach(field, '("width", "height", "defaultsizes", "createlogo"), axlFormSetFieldEditable(form, field, nil))
  axlFormSetField(form, "aspectratio", t)
  class = axlMapClassName("PACKAGE GEOMETRY"); Must be upper case
  subclass = "SILKSCREEN_TOP"
  axlBuildClassPopup(form, "class")
  axlFormSetField(form, "class", class)
  axlBuildSubclassPopup(form, "subclass", class)
  axlFormSetField(form, "subclass", subclass)
  logoMaker_lt_formSetLayerSubColour(form, "subcolour", strcat(class, "/", subclass))
  logoMaker_lt_check4plugins(form)
  axlFormDisplay(form)
))

defun( logoMaker_lt_mkBitmapDefaults (form)
  logoMaker_lt_needMkbitmap(form)
  axlFormSetField(form, "mkbitmapinvert", nil)
  axlFormSetField(form, "mkbitmaphipassfilter", t)
  axlFormSetField(form, "mkbitmapfilterradius", 4)
  axlFormSetFieldEditable(form, "mkbitmapfilterradius", t)
  axlFormSetField(form, "mkbitmapscale", 2)
  axlFormSetField(form, "mkbitmapcubic", t)
  axlFormSetField(form, "mkbitmapbilevel", t)
  axlFormSetField(form, "mkbitmapthreshold", 0.45)
  axlFormSetFieldEditable(form, "mkbitmapthreshold", t)
)

defun( logoMaker_lt_needMkbitmap (form)
 let((bmpFileName, p, nBits, (nColours 999))
  bmpFileName = form ->bmpfile
  when(bmpFileName && isFile(bmpFileName)
    p = infile(bmpFileName)
    for(i, 1, 28, getc(p))
    ;Bits 29 & 30 give the biBitCount:
    nBits = charToInt(getc(p)) + 256 * charToInt(getc(p))
    for(i, 1, 16, getc(p))
    ;Bits 47 - 50 give the biClrUsed:
    nColours = charToInt(getc(p)) + 256 * charToInt(getc(p)) + 256**2 * charToInt(getc(p)) + 256**3 * charToInt(getc(p))
    close(p)
  )
  axlFormSetField(form, "makebitmap", nColours > 0 || nBits > 1)
))

defun( logoMaker_lt_potraceDefaults (form)
  axlFormSetField(form, "turnpolicy", "minority")
  axlFormSetField(form, "turdsize", 2)
  axlFormSetField(form, "alphamax", 1.0)
  axlFormSetField(form, "longcurve", t)
  axlFormSetField(form, "opttolerance", 0.2)
  axlFormSetField(form, "unitn", 10)
  axlFormSetField(form, "blacklevel", 0.5)
  axlFormSetField(form, "inverted", nil)
)

defun( logoMaker_lt_check4plugins (form)
 let((lfcOK, cmd, mkbitmapOK, potraceOK, missingPlugins, msg)
  lfcOK = or(
    logoMaker_lt_lfcPath && isExecutable(logoMaker_lt_lfcCmd) && isFile(strcat(logoMaker_lt_lfcPath, "\\PCDLIB32.DLL"))
    isExecutable(logoMaker_lt_lfcCmd, parseString(getShellEnvVar("path"), ";"))
  )
  sprintf(cmd, "%s/mkbitmap -v", logoMaker_lt_potracePath)
  mkbitmapOK = !numberp(axlRunBatchDBProgram("mkbitmap", cmd, ?noUnload t, ?silent t, ?noProgress t))
  sprintf(cmd, "%s/potrace -v", logoMaker_lt_potracePath)
  potraceOK = !numberp(axlRunBatchDBProgram("potrace", cmd, ?noUnload t, ?silent t, ?noProgress t))
  missingPlugins = remq(t, list(or(lfcOK, "lfc"), or(mkbitmapOK, "mkbitmap"), or(potraceOK, "potrace")))
  when(missingPlugins
    foreach(field, '("imagefile", "imagebrowse", "createlogo"), axlFormSetFieldEditable(form, field, 0))
    logoMaker_lt_Help("Plugins")
    sprintf(msg, "Missing plugins: %s. Contact your administrator", buildString(missingPlugins, ", "))
    axlFormMsg(form, "errormsg", msg)
  )
))

defun( logoMaker_lt_formAction (form)
 let((value, filters, imageFile, bmpFileName, fileInfo, fileName, msg, rawFile, cwd, cmd
      class, subclass, layer, subclasses)
  value = form ->curValue
  case(form ->curField
    ("imagebrowse"
      filters = '(("Bitmap" "bmp")("Jpeg" "jpg")("Compuserve GIF" "gif"))
      filters = mapcar(lambda((f), sprintf(nil, "%s files (*.%s)|*.%s" car(f), cadr(f), cadr(f))), filters)
      imageFile = axlDMFileBrowse(nil, nil, ?title "Select Image file", ?optFilters buildString(filters, "|"))
      when(imageFile && isFile(imageFile)
	fileInfo = axlDMFileParts(imageFile)
	fileName = cadr(fileInfo)
	if(logoMaker_lt_validSymbolName(fileName) then
	  if(lowerCase(cadddr(fileInfo)) == "bmp" then
	    bmpFileName = imageFile
	   else
	    rexMagic(nil), rexCompile("/")
	    rawFile = rexReplace(imageFile, "\\", 0)
	    cwd = rexReplace(getWorkingDir(), "\\", 0)
	    rexMagic(t)
	    sprintf(cmd, "%s \"%s\" \"%s\" /f=FILE_BMP /NOUI", logoMaker_lt_lfcCmd, rawFile, cwd)
	    axlRunBatchDBProgram("lfc", cmd, ?noUnload t, ?silent t, ?noProgress t)
	    sprintf(bmpFileName, "%s\\%s.bmp", cwd, fileName)
	    unless(isFile(bmpFileName), bmpFileName = nil, logoMaker_lt_Help("Valid Image Types"))
	  )
	  axlFormSetField(form, "imagefile", imageFile)
	  form ->bmpfile = bmpFileName
	  if(bmpFileName then
	    logoMaker_lt_needMkbitmap(form)
	    logoMaker_lt_drawPbm(form)
	    axlFormSetField(form, "symbolname", fileName)
	    unless(cadddr(fileInfo) && lowerCase(cadddr(fileInfo)) == "bmp"
	      logoMaker_lt_tempFiles = unique(cons(bmpFileName, logoMaker_lt_tempFiles))
	    )
	   else
	    axlFormSetField(form, "pbmthumbnail", nil)
	    axlFormSetFieldVisible(form, "noimage", 1)
	    axlFormSetFieldVisible(form, "pbmthumbnail", 0)
	    axlFormSetFieldVisible(form, "distorted", 0)
	    axlFormSetField(form, "symbolname", nil)
	    axlFormMsg(form, "warnmsg", "Not a known or valid raster graphics image")
	  )
	  logoMaker_lt_setSizeFields(form)
	 else
	  sprintf(msg, "File name contains invalid characters (%s)", logoMaker_lt_validSymbolName(fileName, t))
	  axlFormMsg(form, "warnmsg", msg)
	); if
      ); when
    )
    ("imagefile"
      unless(value && value != "" && isFile(value) && logoMaker_lt_validSymbolName(cadr(axlDMFileParts(value)))
        axlFormMsg(form, "warnmsg", sprintf(nil, "%s not found.", value))
        value = nil
        axlFormSetField(form, "imagefile", nil)
      )
      form ->bmpfile = value
      if(value
       then axlFormSetField(form, "symbolname", cadr(axlDMFileParts(value)))
       else axlFormSetField(form, "symbolname", nil)
      )
      logoMaker_lt_needMkbitmap(form)
      logoMaker_lt_drawPbm(form)
      logoMaker_lt_setSizeFields(form)
    )
    ("makebitmap", logoMaker_lt_drawPbm(form))
    ("mkbitmapdefaults", logoMaker_lt_mkBitmapDefaults(form), logoMaker_lt_drawPbm(form))
    ("mkbitmapinvert", logoMaker_lt_drawPbm(form))
    ("mkbitmaphipassfilter", axlFormSetFieldEditable(form, "mkbitmapfilterradius", value), logoMaker_lt_drawPbm(form))
    ("mkbitmapfilterradius", logoMaker_lt_drawPbm(form))
    ("mkbitmapscale", logoMaker_lt_drawPbm(form))
    ("mkbitmapcubic", logoMaker_lt_drawPbm(form))
    ("mkbitmapbilevel", axlFormSetFieldEditable(form, "mkbitmapthreshold", value), logoMaker_lt_drawPbm(form))
    ("mkbitmapthreshold", logoMaker_lt_drawPbm(form))
    ("mkbitmaphelp", logoMaker_lt_Help("Pre-processing Options"))
    ("potracehelp", logoMaker_lt_Help("Tracing Options"))
    
    ("width"
      when(axlFormGetField(form, "aspectratio")
        axlFormRestoreField(form, "width")
        axlFormSetField(form, "height", value / axlFormGetField(form, "width") * axlFormGetField(form, "height"))
        axlFormSetField(form, "width", value)
      )
    )
    ("height"
      when(axlFormGetField(form, "aspectratio")
        axlFormRestoreField(form, "height")
        axlFormSetField(form, "width", value / axlFormGetField(form, "height") * axlFormGetField(form, "width"))
        axlFormSetField(form, "height", value)
      )
    )
    ("defaultsizes", logoMaker_lt_setSizeFields(form))
    ("rotation", logoMaker_lt_setDynamicsRotMir(form))
    ("mirror", logoMaker_lt_setDynamicsRotMir(form))
    ("class"
      class = value, subclass = axlFormGetField(form, "subclass")
      layer = strcat(class, "/" subclass)
      axlBuildSubclassPopup(form, "subclass", class)
      unless(axlIsLayer(layer)
        subclasses = axlGetParam(strcat("paramLayerGroup:", class)) ->groupMembers
        subclass = car(setof(sub, subclasses, axlIsVisibleLayer(strcat(class, "/", sub))) || subclasses)
      )
      axlFormSetField(form, "subclass", subclass)
      logoMaker_lt_formSetLayerSubColour(form, "subcolour", strcat(class, "/" subclass))
      logoMaker_lt_setDynamicsRotMir(form)
    )
    ("subclass"
      class = axlFormGetField(form, "class"), subclass = value
      logoMaker_lt_formSetLayerSubColour(form, "subcolour", strcat(class, "/" subclass))
      logoMaker_lt_setDynamicsRotMir(form)
    )
    ("subcolour"
      class = axlFormGetField(form, "class")
      when(class
	subclass = axlFormGetField(form, "subclass")
	layer = strcat(class, "/" subclass)
	when(axlIsLayer(layer), axlVisibleLayer(layer, !axlIsVisibleLayer(layer)), axlVisibleUpdate(t))
	logoMaker_lt_formSetLayerSubColour(form, "subcolour", layer)
      )
    )
    ("symbolname"
      unless(logoMaker_lt_validSymbolName(value)
        axlFormRestoreField(form, "symbolname")
        sprintf(msg, "'%s' contains invalid symbol name characters (%s)", value, logoMaker_lt_validSymbolName(value, t))
        axlFormMsg(form, "warnmsg", msg)
      )
    )
    ("createlogo", logoMaker_lt_create(form))
    ("quit"
      foreach(file, logoMaker_lt_tempFiles, when(isFile(file), deleteFile(file)))
      axlFormClose(form), axlCancelEnterFun()
    )
  )
))

defun( logoMaker_lt_validSymbolName (name @optional returnBadCharacters)
 let((matchStr, chars, result)
  matchStr = "^[-a-zA-Z0-9_]+"
  chars = parseString(name, "")
  result = forall(ch, chars, rexMatchp(matchStr, ch))
  when(returnBadCharacters && !result
    foreach(ch, chars, unless(rexMatchp(matchStr, ch), result = cons(ch, result)))
    result = buildString(mapcar(lambda((ch), sprintf(nil, "'%s'", ch)), unique(result)), ", ")
  )
  result
))

defun( logoMaker_lt_drawPbm (form); Converts the pbm to a bmp using LFC utility before displaying it on the form.
 let((bmpFileName, pbmFileName, cmd, fileParts, thumbnailExists)
  bmpFileName = form ->bmpfile
  if(bmpFileName && isFile(bmpFileName) && axlFormGetField(form, "makebitmap") then
    pbmFileName = logoMaker_lt_mkbitmap(form, bmpFileName)
    if(pbmFileName then
      rexMagic(nil), rexCompile("/"), pbmFileName = rexReplace(pbmFileName, "\\", 0), rexMagic(t)
      sprintf(cmd, "%s \"%s\" /f=FILE_BMP /NOUI", logoMaker_lt_lfcCmd pbmFileName)
      axlRunBatchDBProgram("lfc", cmd, ?noUnload t, ?silent t, ?noProgress t)
      fileParts = axlDMFileParts(pbmFileName)
      sprintf(bmpFileName, "%s\\%s.bmp", car(fileParts), cadr(fileParts))
      if(isFile(bmpFileName) then
	axlFormSetField(form, "pbmthumbnail", bmpFileName)
	logoMaker_lt_tempFiles = unique(cons(bmpFileName, logoMaker_lt_tempFiles))
       else
	logoMaker_lt_Help("lfc bmp conversion failure")
	axlFormMsg(form, "warnmsg", "lfc bmp conversion failed")
      )
     else
      logoMaker_lt_Help("mkbitmap failure")
      axlFormMsg(form, "warnmsg", "mkbitmap command failed")
    )
   else axlFormSetField(form, "pbmthumbnail", bmpFileName)
  )
  thumbnailExists = isFile(axlFormGetField(form, "pbmthumbnail"))
  axlFormSetFieldVisible(form, "noimage", if(thumbnailExists, 0, 1))
  foreach(field, '("pbmthumbnail", "distorted"), axlFormSetFieldVisible(form, field, if(thumbnailExists, 1, 0)))
  pbmFileName
))

defun( logoMaker_lt_setSizeFields (form)
 let((bmpFileName, width, height, p, xPixels, yPixels)
  bmpFileName = form ->bmpfile
  when(bmpFileName && isFile(bmpFileName)
    width = height = axlMKSConvert(25, "mm")
    p = infile(bmpFileName)
    for(i, 1, 18, getc(p))
    xPixels = charToInt(getc(p)) + 256 * charToInt(getc(p)) + 256**2 * charToInt(getc(p)) + 256**3 * charToInt(getc(p))
    yPixels = charToInt(getc(p)) + 256 * charToInt(getc(p)) + 256**2 * charToInt(getc(p)) + 256**3 * charToInt(getc(p))
    close(p)
    if(xPixels >= yPixels, then height = yPixels / float(xPixels) * width, else width = xPixels / float(yPixels) * height)
  )
  axlFormSetField(form, "width", width), axlFormSetField(form, "height", height)
  foreach(field, '("width", "height", "defaultsizes", "createlogo"), axlFormSetFieldEditable(form, field, width))
))

defun( logoMaker_lt_setDynamicsRotMir (form)
 let((rotation, mirror)
  rotation = axlFormGetField(form, "rotation")
  mirror = axlFormGetField(form, "mirror")
  when(substring(axlFormGetField(form, "subclass"), -6) == "BOTTOM", mirror = !mirror)
  _axlSetDynamicsRotation(rotation)
  _axlSetDynamicsMirror(mirror)
))

defun( logoMaker_lt_mkbitmap (form, bmpFile)
 let((invert, hipassfilter, scale, interpolation, threshold, bitmapOutFile, options, cmd)
  invert = if(axlFormGetField(form, "mkbitmapinvert"), "-i ", "")
  if(axlFormGetField(form, "mkbitmaphipassfilter")
    then sprintf(hipassfilter, "-f %d", axlFormGetField(form, "mkbitmapfilterradius"))
    else sprintf(hipassfilter, "-n")
  )
  sprintf(scale, "-s %d", axlFormGetField(form, "mkbitmapscale"))
  sprintf(interpolation, "-%d", if(axlFormGetField(form, "mkbitmapcubic"), 3, 1))
  if(axlFormGetField(form, "mkbitmapbilevel")
    then sprintf(threshold, "-t %2.2f", axlFormGetField(form, "mkbitmapthreshold"))
    else sprintf(threshold, "-g")
  )
  sprintf(bitmapOutFile, "%s/%s_mk.pbm", getWorkingDir(), cadr(axlDMFileParts(bmpFile)))
  sprintf(options "%s%s %s %s %s", invert, hipassfilter, scale, interpolation, threshold)
  sprintf(cmd, "%s/mkbitmap %s \"%s\" -o %s", logoMaker_lt_potracePath, options, bmpFile, bitmapOutFile)
  and(
    !numberp(axlRunBatchDBProgram("mkbitmap", cmd, ?noUnload t, ?silent t, ?noProgress t))
    logoMaker_lt_tempFiles = unique(cons(bitmapOutFile, logoMaker_lt_tempFiles))
    bitmapOutFile
  )
))

defun( logoMaker_lt_create (form)
 let((bitmapFile, symbolName, tad, x, y, symDef, mark, popup, popupGray (continue t), event, pt, rot, mirror, sym, bmpFile)
  bitmapFile = form ->bmpfile
  when(bitmapFile && isFile(bitmapFile)
    symbolName = axlFormGetField(form, "symbolname")
    when(!symbolName || symbolName == "", symbolName = "bitmaplogo")
    when(axlFormGetField(form, "makebitmap")
      sprintf(bitmapFile, "%s/%s_mk.bmp", getWorkingDir(), cadr(axlDMFileParts(bitmapFile)))
    )
  )
  when(bitmapFile && isFile(bitmapFile)
    tad = axlMKSConvert(1, "mils")
    x = axlFormGetField(form, "width") + tad, y = axlFormGetField(form, "height") + tad
    when(axlDesignType(nil) == "LAYOUT"
      symDef = axlDBCreateSymDefSkeleton('("TEMPLOGO", "mechanical"), list(-tad:-tad, x:y))
    )
    logoMaker_lt_createSym(form, bitmapFile, ?symbol symDef)
    _axlSetDynamicsRotation(0)
    _axlSetDynamicsMirror(nil)
    axlDynamicsObject(symDef, 0:0)
    axlDeleteObject(symDef)
    mark = axlDBTransactionStart()
    form ->oopsCount = 0
    popup = axlUIPopupDefine(nil '(
      ("Done", "axlDBTransactionCommit(mark), axlFinishEnterFun(), continue = nil")
      ("Oops", "axlDBTransactionOops(mark), when(zerop(form ->oopsCount = form ->oopsCount - 1), axlUIPopupSet(popupGray))")
      ("Cancel", "axlDBTransactionRollback(mark), axlCancelEnterFun(), continue = nil")
      ("MENU_SEPARATOR", nil)
      ("Rotate 90" "logoMaker_lt_rotate(form)")
      ("Mirror" "logoMaker_lt_mirror(form)")
    ))
    axlUICmdPopupSet(popup)
    popupGray = axlUIPopupDefine(nil, '(
      ("Done", "axlDBTransactionCommit(mark), axlFinishEnterFun(), continue = nil")
      ("Cancel", "axlDBTransactionRollback(mark), axlCancelEnterFun(), continue = nil")
      ("MENU_SEPARATOR", nil)
      ("Rotate 90" "logoMaker_lt_rotate(form)")
      ("Mirror" "logoMaker_lt_mirror(form)")
    ))
    axlUIPopupSet(popupGray)
    logoMaker_lt_setDynamicsRotMir(form)
    while(continue
      event = axlEnterEvent(list('PICK), nil, nil)
      caseq(event ->type
	(PICK
	  pt = event ->xy
	  rot = axlFormGetField(form, "rotation")
	  mirror = axlFormGetField(form, "mirror")
	  when(substring(axlFormGetField(form, "subclass"), -6) == "BOTTOM", mirror = !mirror)
	  axlDBTransactionMark(mark), axlUIPopupSet(popup), form ->oopsCount = form ->oopsCount + 1
	  sym = car(if(axlLoadSymbol("mechanical", symbolName)
	   then axlDBCreateSymbol(list(symbolName, "mechanical"), pt, mirror, rot)
	   else axlDBCreateSymbolSkeleton(list(symbolName, "DRAFTING"), pt, mirror, rot, nil)
	  ))
	  bmpFile = if(axlFormGetField(form, "makebitmap")
	    then sprintf(nil, "%s/%s.bmp", getWorkingDir(), cadr(axlDMFileParts(bitmapFile)))
	    else bitmapFile
	  )
	  when(bmpFile && isFile(bmpFile)
	    logoMaker_lt_createSym(form, bmpFile, ?symbol sym, ?location pt, ?angle float(rot), ?mirror mirror)
	  )
	  when(axlFormGetField(form, "fixed"), axlDBAddProp(sym, list("FIXED" t)))
	)
	(DONE, axlDBTransactionCommit(mark), axlFinishEnterFun(), continue = nil)
	(CANCEL, axlDBTransactionRollback(mark), axlCancelEnterFun(), continue = nil)
      )
    )
    axlUIPopupSet(nil), axlUICmdPopupSet(nil)
    axlClearDynamics()
    gc(); Do a garbage collection in an attempt to save memory.
  )
))

defun( logoMaker_lt_rotate (form)
  axlFormSetField(form, "rotation", mod(axlFormGetField(form, "rotation") + 90, 360))
  logoMaker_lt_setDynamicsRotMir(form)
)

defun( logoMaker_lt_mirror (form)
  axlFormSetField(form, "mirror", !axlFormGetField(form, "mirror"))
  logoMaker_lt_setDynamicsRotMir(form)
)

defun( logoMaker_lt_createSym (form, bitmapFile @key symbol, (location 0:0), (angle 0.0), mirror)
 let((x0, y0, turnPolicy, turdSize, alphaMax, longCurve, unitN, blackLevel, inverted, layer, designUnits
      logoWidth, logoHeight, options, cmd, svgFile, p, ln, data, width, height, (scaleX 1), (scaleY 1)
      pathEnd, void, dx, dy, ch1, x1, y1, x, y, ptR, rpath, oShape, pt1, pt2, pt3, pt4, xb, yb, xc, yc, pts)      
  x0 = car(location), y0 = cadr(location)  
  turnPolicy = axlFormGetField(form, "turnpolicy"); string
  turdSize = axlFormGetField(form, "turdsize"); integer
  alphaMax = axlFormGetField(form, "alphamax"); real
  longCurve = if(axlFormGetField(form, "longcurve"), sprintf(nil, "-O %2.2f", axlFormGetField(form, "opttolerance")), "-n")
  unitN = axlFormGetField(form, "unitn"); integer
  blackLevel = axlFormGetField(form, "blacklevel")
  inverted = if(axlFormGetField(form, "inverted"), "-i", "")
  layer = strcat(axlFormGetField(form, "class"), "/", axlFormGetField(form, "subclass"))
  designUnits = car(axlDBGetDesignUnits())
  sprintf(logoWidth, "%gmm", axlMKSConvert(axlFormGetField(form, "width"), designUnits, "mm"))
  sprintf(logoHeight, "%gmm", axlMKSConvert(axlFormGetField(form, "height"), designUnits, "mm"))
  sprintf(svgFile, "%s.svg", cadr(axlDMFileParts(bitmapFile)))
  sprintf(options "-z %s -t %d -a %2.2f %s -u %d -k %2.2f %s -W %s -H %s"; -A %d
    turnPolicy, turdSize, alphaMax, longCurve, unitN, blackLevel, inverted, logoWidth, logoHeight)
  sprintf(cmd, "%s/potrace -s -o %s %s %s", logoMaker_lt_potracePath, svgFile, options, bitmapFile)
  if(!numberp(axlRunBatchDBProgram("mkbitmap", cmd, ?noUnload t, ?silent t, ?noProgress t)) then
    logoMaker_lt_tempFiles = unique(cons(svgFile, logoMaker_lt_tempFiles))
    p = axlDMOpenFile("MISC", svgFile, "r")
    while(gets(ln, p)
      cond(
	(substring(ln, 1, 13) == "<svg version="
	  data = parseString(substring(ln, 6), " \n")
	  while(substring(ln, -2) != ">\n", gets(ln, p), nconc(data, parseString(ln " >\n")))
	  width  = substring(car(setof(d, data, substring(d, 1, 6) == "width=")),  7)
	  height = substring(car(setof(d, data, substring(d, 1, 7) == "height=")), 8)
	  width = readstring(car(parseString(width, "\"p")))
	  height = readstring(car(parseString(height, "\"p")))
	)
	(substring(ln, 1, 13) == "<g transform="
	  data = parseString(substring(ln, 14), " \"\n")
	  scaleX = readstring(cadr(parseString(cadr(data), "(,)"))) * if(mirror, -1, 1)
	  scaleY = readstring(caddr(parseString(cadr(data), "(,)"))) * -1
	)
	(substring(ln, 1, 9) == "<path d=\""
	  data = parseString(substring(ln, 10), " \"/>\n")
	  while(substring(ln, -4) != "\"/>\n", gets(ln, p), nconc(data, parseString(ln " \"/>\n")))
	  pathEnd = void = nil
	  while(data
	    when(pathEnd, void = t)
	    dx = car(data), dy = cadr(data), data = cddr(data)
	    pathEnd = and(substring(dy, -1) == "z", dy = substring(dy, 1, strlen(dy) - 1))
	    ch1 = substring(dx, 1, 1)
	    unless(ch1 == "-" || numberp(readstring(ch1)), dx = substring(dx, 2), cmd = ch1)
	    dx = readstring(dx), dy = readstring(dy)
	    cond(
	      (cmd == "M"
		x1 = x = dx, y1 = y = dy		
		ptR = axlGeoRotatePt(angle, x0 + logoMaker_lt_PtsToUnits(x) * scaleX:y0 + logoMaker_lt_PtsToUnits(y) * scaleY, x0:y0); [mirror]
		rpath = axlPathStart(list(ptR))
	      )
	      (cmd == "m"
		x1 = x = x + dx, y1 = y = y + dy
		ptR = axlGeoRotatePt(angle, x0 + logoMaker_lt_PtsToUnits(x) * scaleX:y0 + logoMaker_lt_PtsToUnits(y) * scaleY, x0:y0); [mirror]
		rpath = axlPathStart(list(ptR))
	      )
	      (cmd == "c"
		pt1 = x:y, xb = x + dx, yb = y + dy, pt2 = xb:yb
		dx = readstring(car(data)), dy = readstring(cadr(data)), data = cddr(data)
		xc = x + dx, yc = y + dy, pt3 = xc:yc
		dx = readstring(car(data)), dy = cadr(data), data = cddr(data)
		pathEnd = and(substring(dy, -1) == "z", dy = substring(dy, 1, strlen(dy) - 1))
		dy = readstring(dy), x = x + dx, y = y + dy, pt4 = x:y
		pts = logoMaker_lt_BezierToPath(pt1, pt2, pt3, pt4)
		foreach(pt, cdr(pts)
		  ptR = axlGeoRotatePt(angle, x0 + logoMaker_lt_PtsToUnits(car(pt)) * scaleX:y0 + logoMaker_lt_PtsToUnits(cadr(pt)) * scaleY, , x0:y0)
		  axlPathLine(rpath, nil, ptR)
		)
	      )
	      (cmd == "l"
		x = x + dx, y = y + dy
		ptR = axlGeoRotatePt(angle, x0 + logoMaker_lt_PtsToUnits(x) * scaleX:y0 + logoMaker_lt_PtsToUnits(y) * scaleY, x0:y0)
		axlPathLine(rpath, nil, ptR)
	      )
	      (t, warn("Character '%s' in svg file not recognised\n", cmd), x = x + dx, y = y + dy)
	    )
	    when(pathEnd
	      unless(x == x1 && y == y1
	        ptR = axlGeoRotatePt(angle, logoMaker_lt_PtsToUnits(x1) * scaleX:logoMaker_lt_PtsToUnits(y1) * scaleY, x0:y0)
	        axlPathLine(rpath, nil, ptR)
	      )
	      if(void, axlDBCreateVoid(oShape, rpath), oShape = axlDBCreateOpenShape(rpath, t, layer, nil, symbol))
	    )
	  ); while data
	  axlDBCreateCloseShape(oShape)
	);path
      )
    )
    axlDMClose(p)
   else
    logoMaker_lt_Help("potrace failure")
    axlFormMsg(form, "warnmsg", "potrace command failed")
  )
))

defun( logoMaker_lt_Help (section @optional header)
 let((in, ln, filePath, p, (title "Logo Maker Help File"), (author "dave.elder@tait.co.nz"))
  in = infile("logoMaker_ltHelp.txt")
  while(and(gets(ln, in), ln != strcat("*** " section " ***\n")), t)
  when(ln
    rexCompile(" ")
    filePath = getWorkingDir()
    unless(isWritable(filePath), filePath = getShellEnvVar("TEMP"))
    filePath = strcat(filePath, "\\", "taithelp_", rexReplace(section, "", 0), ".txt")
    p = outfile(filePath, "w")
    unless(header, header = section)
    fprintf(p, "%s\n%s\n\n", header, buildString(vectorToList(makeVector(strlen(header), "=")), ""))
    while(and(gets(ln, in), substring(ln, 1, 3) != strcat("***"))
      cond(
        (substring(ln, 1, 7) == "Title: ", title = substring(car(parseString(ln, "\n")), 8))
        (t, fprintf(p, "%s", ln))
      )
    )
    fprintf(p, "\n\nFor further information please email: %s\n", author)
    close(p)
    axlUIViewFileCreate(filePath, title, t)
  )
  close(in)
))

defun( logoMaker_lt_PtsToUnits (pts), axlMKSConvert(pts / 0.072, "mils"))

defun( logoMaker_lt_Lerp (pt1, pt2, dt); Simple linear interpolation between two points. dt between 0 and 1.0
  list(car(pt1) + (car(pt2) - car(pt1)) * dt, cadr(pt1) + (cadr(pt2) - cadr(pt1)) * dt)
)

defun( logoMaker_lt_BezierPt (a, b, c, d, dt) ;Evaluate a point on a bezier-curve. dt between 0 and 1.0
 let((ab, bc, cd, abbc, bccd)
  ab = logoMaker_lt_Lerp(a, b, dt); point between a and b
  bc = logoMaker_lt_Lerp(b, c, dt); point between b and c
  cd = logoMaker_lt_Lerp(c, d, dt); point between c and d
  abbc = logoMaker_lt_Lerp(ab, bc, dt); point between ab and bc
  bccd = logoMaker_lt_Lerp(bc, cd, dt); point between bc and cd
  logoMaker_lt_Lerp(abbc, bccd, dt); point on the bezier-curve
))

defun( logoMaker_lt_BezierToPath (pt1 pt2 pt3 pt4 @optional (n 10))
 let((dt, pts)
  for(i, 1, n - 1
    dt = i / float(n - 1)
    pts = cons(logoMaker_lt_BezierPt(pt1, pt2, pt3, pt4, dt), pts)
  )
  reverse(pts)
))

defun( logoMaker_lt_formOpenFile (name)
 let((tempFolder)
  tempFolder = cond(
    (axlGetVariable("TEMP") && !index(axlGetVariable("TEMP"), "~"), axlGetVariable("TEMP"))
    (getTempDir() && !index(getTempDir(), "~"), getTempDir())
    (isDir("c:\\temp"), "c:\\temp")
    (createDir("c:\\temp"), "c:\\temp")
    (t, ".")
  )
  axlDMOpenFile("FORM", if(tempFolder && isDir(tempFolder), strcat(tempFolder "\\", name), name), "w")
))

;Create HEADER lines on a form:
defun( logoMaker_lt_formHeader (port, formWidth, title)
  fprintf(port, "FILE_TYPE=FORM_DEFN VERSION=2\nFORM\nFIXED\nPORT %d 10\n", formWidth)
  fprintf(port, "HEADER \"%s\"\n", title)
  fprintf(port, "TILE\n")
)

defun( logoMaker_lt_formEnd (port), fprintf(port, "ENDTILE\nENDFORM\n"))

defun( logoMaker_lt_formPopupDefine (port, popupName @optional (popPairs '("")))
 let((pair, (popPairsStr ""), tdisplay, tdispatch)
  while(popPairs
    pair = car(popPairs), popPairs = cdr(popPairs)
    if(listp(pair) then tdisplay = car(pair), tdispatch = cadr(pair) else tdisplay = tdispatch = pair)
    when(numberp(tdisplay), sprintf(tdisplay, "%d", tdisplay))
    when(numberp(tdispatch), sprintf(tdispatch, "%d", tdispatch))
    sprintf(popPairsStr, "%s \"%s\" \"%s\"%s", popPairsStr, tdisplay, tdispatch, if(popPairs, ",", ""))
  )
  fprintf(port, "POPUP <%s>%s.\n", popupName, popPairsStr)
))

defun( logoMaker_lt_formMessage (port, msgLabel @key (level 0), (msgString "%s"))
  sprintf(level, " %d", level)
  msgString = strcat(" \"", msgString, "\"")
  fprintf(port, "MESSAGE %s%s%s\n", msgLabel, level, msgString)
)

;Create a Group on a form:
defun( logoMaker_lt_formGroup (port, displayTxt, x, lineNo, w, h)
  fprintf(port, "GROUP \"%s\"\n\tFLOC %d %d\n\tFSIZE %d %d\nENDGROUP\n", displayTxt, x, lineNo, w, h)
)

;Create a TEXT line on a form:
defun( logoMaker_lt_formText (port, txt, x, lineNo @key options (label ""))
  options = logoMaker_lt_formOptionsString(options)
  fprintf(port, "TEXT \"%s\" %s\n\tTLOC %d %d\n%sENDTEXT\n", txt, label, x, lineNo, options)
)

;Create a Button on a form:
defun( logoMaker_lt_formButton (port, label, txt, x, lineNo, w, h)
  fprintf(port, "FIELD %s\n\tFLOC %d %d\n\tMENUBUTTON \"%s\" %d %d\nENDFIELD\n", label, x, lineNo, txt, w, h)
)

;Create a Checklist item on a form:
defun( logoMaker_lt_formChecklistItem (port, label, x, lineNo, displayTxt @key (radioLabel ""))
  unless(radioLabel == "", radioLabel = strcat(" \"", radioLabel, "\""))
  fprintf(port, "FIELD %s\n\tFLOC %d %d\n\tCHECKLIST \"%s\"%s\nENDFIELD\n", label, x, lineNo, displayTxt, radioLabel)
)

;Create a STRFILLIN line on a form. A title is optional:
defun( logoMaker_lt_formStrFillin (port, label, fillinWidth, fillinLength, x1, lineNo @key title, x2 pop)
  if(title then
    x2 = x2 || strlen(title) + x1 - 2
    logoMaker_lt_formText(port, title, x1, lineNo ?label strcat(label, "_title"))
   else x2 = x1
  )
  pop = logoMaker_lt_formOptionalString("POP", pop)
  fprintf(port, "FIELD %s\n\tFLOC %d %d\n\tSTRFILLIN %d %d\n%sENDFIELD\n"
    label, x2, lineNo, fillinWidth, fillinLength, pop)
)

;Create a REALFILLIN line on a form. A title is optional:
defun( logoMaker_lt_formRealFillin (port, label, fillinWidth, fillinLength, x1, lineNo
  @key title, fillInX, titleLabel, minVal, maxVal, value, decimalPlaces, dp, units)
  if(title then
    fillInX = fillInX || strlen(title) + x1 - 2
    logoMaker_lt_formText(port, title, x1, lineNo, ?label titleLabel || strcat(label, "_title"))
   else fillInX = x1
  )
  if(minVal then sprintf(minVal, "\tMIN %L\n", minVal) else minVal = "")
  if(maxVal then sprintf(maxVal, "\tMAX %L\n", maxVal) else maxVal = "")
  if(value then sprintf(value, "\tVALUE %L\n", value) else value = "")
  sprintf(decimalPlaces, "\tDECIMAL %d\n", decimalPlaces || dp || cadr(axlDBGetDesignUnits()))
  fprintf(port, "FIELD %s\n\tFLOC %d %d\n\tREALFILLIN %d %d\n%s%s%s%sENDFIELD\n",
    label, fillInX, lineNo, fillinWidth, fillinLength, minVal, maxVal, value, decimalPlaces)
  when(units, logoMaker_lt_formText(port, units, fillInX + fillinWidth + 2, lineNo, ?label strcat(label, "Units")))
)

;Create an LONGFILLIN line on a form that only accepts integers. A title is optional:
defun( logoMaker_lt_formIntegerFillin (port, label, fillinWidth, fillinLength, x1, lineNo
    @key title, fillInX, titleLabel, minVal, maxVal, value, pop, units)
  if(title then
    fillInX = fillInX || strlen(title) + x1 - 2
    logoMaker_lt_formText(port, title, x1, lineNo ?label titleLabel || strcat(label, "_title"))
   else fillInX = x1
  )
  if(minVal then sprintf(minVal, "\tMIN %L\n", minVal) else minVal = "")
  if(maxVal then sprintf(maxVal, "\tMAX %L\n", maxVal) else maxVal = "")
  if(value then sprintf(value, "\tVALUE %L\n", value) else value = "")
  pop = logoMaker_lt_formOptionalString("POP", pop)
  fprintf(port, "FIELD %s\n\tFLOC %d %d\n\tLONGFILLIN %d %d\n%s%s%s%sENDFIELD\n"
    label, fillInX, lineNo, fillinWidth, fillinLength, minVal, maxVal, value, pop)
  when(units
    logoMaker_lt_formText(port, units, fillInX + fillinWidth + if(pop == "", 2, 5), lineNo, ?label strcat(label, "Units"))
  )
)

;Create a Coloured box on a form:
defun( logoMaker_lt_formColor (port, label, x, lineNo, w, h)
  fprintf(port, "FIELD %s\n\tFLOC %d %d\n\tCOLOR %d %d\nENDFIELD\n", label, x, lineNo, w, h)
)

;Create a Popup on a form:
defun( logoMaker_lt_formPop (port, label, popDef, titlex, lineNo, enumset @key title, x2, titleLabel, units, options)
  if(title then
    x2 = x2 || titlex + round(strlen(title) * 0.8)
    logoMaker_lt_formText(port, title, titlex, lineNo ?label titleLabel || strcat(label, "_title"))
   else x2 = titlex)
  options = logoMaker_lt_formOptionsString(options)
  fprintf(port, "FIELD %s\n\tFLOC %d %d\n\tENUMSET %d\n\tPOP \"%s\"\n%sENDFIELD\n", label, x2, lineNo, enumset, popDef, options)
  when(units, logoMaker_lt_formText(port, units, x2 + enumset + 3, lineNo, ?label strcat(label, "Units")))
)

;Create a Thumbnail on a form:
defun( logoMaker_lt_formThumbnail (port, label, x, lineNo, w, h @key (bitmap "") options)
 let(((fieldName "THUMBNAIL"))
  unless(bitmap == "", sprintf(fieldName, "THUMBNAIL %s", bitmap))
  options = logoMaker_lt_formOptionsString(options)
  fprintf(port, "FIELD %s\n\t%s\n\tFLOC %d %d\n\tFSIZE %d %d\n%sENDFIELD\n", label, fieldName, x, lineNo, w, h, options)
))

defun( logoMaker_lt_formIntSlideBar (port, label, fillinWidth, fillinLength, x1, lineNo, minVal, maxVal
    @key title, fillInX, titleLabel, value, units)
  if(title then
    fillInX = fillInX || strlen(title) + x1 - 2
    logoMaker_lt_formText(port, title, x1, lineNo ?label titleLabel || strcat(label, "_title"))
   else fillInX = x1
  )
  if(value then sprintf(value, "\tVALUE %L\n", value) else value = "")
  fprintf(port, "FIELD %s\n\tFLOC %d %d\n\tINTSLIDEBAR %d %d\n\tMIN %d\n\tMAX %d\n%sENDFIELD\n"
    label, fillInX, lineNo, fillinWidth, fillinLength, minVal, maxVal, value)
  when(units, logoMaker_lt_formText(port, units, fillInX + fillinWidth + 5, lineNo, ?label strcat(label, "Units")))
)

/****************************************************************/

defun( logoMaker_lt_formSetLayerSubColour (form, field, layer)
  axlFormSetField(form, field, if(axlIsLayer(layer) && axlIsVisibleLayer(layer), axlLayerGet(layer) ->color, 'black))
  axlFormSetField(form, field, axlIsVisibleLayer(layer))
)

/****************************************************************/
/*		Form String creation functions			*/
/****************************************************************/

defun( logoMaker_lt_formOptionsString (options)
  when(listp(options), options = buildString(options, " "))
  unless(options == "", options = strcat("\tOPTIONS ", options, "\n"))
  options
)

defun( logoMaker_lt_formOptionalString (fieldName, value)
  cond(
    (stringp(value), sprintf(nil, "\t%s %s\n", fieldName, value))
    (value, sprintf(nil, "\t%s\n", fieldName))
    (t, "")
  )
)