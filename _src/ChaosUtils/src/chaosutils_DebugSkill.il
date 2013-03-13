;============================================================================
;  Copyright (C) 2011 Chaos. All rights reserved.
;
;  Program Name: chaosutils_DebugSkill.il
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
;  Platforms tested (It should work on others too):
;	Windows XP, Linux RH
;
;  Allegro verions:
;	16.x
;
;  Acknowledgements:
;	This utility relies heavily on the potrace open source code generously
;	provided by Peter Selinger.
;		http://potrace.sourceforge.net
;	It uses the open source ImageMagick Command Line Image File Converter
;	available as a free download.
;		http://www.imagemagick.org
;	
;
;  WARRANTY:
;	None. This program is free software and is available as-is 
;	It may not work in all environments. There is no formal support.
;
;  Modification and Distribution
;	You may redistribute and/or modify this utility. However, in the open-source
;	spirit in which this is provided to the Cadence community, any improvements
;	and enhancements should be submitted to the originator for inclusion in future
;	releases.
;

axlCmdRegister("chaosutils_DebugSkill" 'chaosutils_DebugSkill_start); Must be interactive (the default).

defun( chaosutils_DebugSkill_start ()
 prog((magickHome, p, formFile, y, class, subclass, form)
  defvar(chaosutils_DebugSkill_tempFiles)
  defvar(logoMaker_potracePath, getShellEnvVar("POTRACE_PATH"))
  defvar(logoMaker_MagickConvertEXE)
  magickHome = getShellEnvVar("MAGICK_HOME")
  logoMaker_MagickConvertEXE = cond(
    (!magickHome && zerop(system("convert -version")), "convert")
    (!magickHome, nil)
    (axlVersion('isWindows) && isFile(strcat(magickHome, "/convert.exe")), strcat(magickHome, "/convert.exe"))
    (!axlVersion('isWindows) && isFile(strcat(magickHome, "/convert")), strcat(magickHome, "/convert"))
  )
  unless(logoMaker_check4plugins(), return())
  
  defvar(logoMaker_designUnits)
  logoMaker_designUnits = car(axlDBGetDesignUnits()), when(logoMaker_designUnits == "millimeters", logoMaker_designUnits = "mm")

  p = logoMaker_formOpenFile("logomaker")
  if(p then
    formFile = get_filename(p)
    y = 1
    logoMaker_formHeader(p, 80, "Dave Elder's Logo Maker Utility v2.8")
    AFn_formMessage(p, "infomsg", ?level 0, ?msgString "%s")
    AFn_formMessage(p, "warnmsg", ?level 2, ?msgString "%s")
    AFn_formMessage(p, "errormsg", ?level 3, ?msgString "%s")
    logoMaker_formPopupDefine(p, "TURNPOLICY", '("black", "white", "right", "left", "minority", "majority", "random"))
    logoMaker_formPopupDefine(p, "ROTATION", '(0 45 90 135 180 225 270 315))
    logoMaker_formPopupDefine(p, "CLASS")
    logoMaker_formPopupDefine(p, "SUBCLASS")
    AFn_formStrFillin(p, "imagefile", 62, 199, 1, y, ?title "Image file:", ?x2 10)
    AFn_formButton(p, "imagebrowse", "...", 75, y, 4, 3),  y = y + 2
    AFn_formChecklistItem(p, "viewadvancedoptions", 2, y + 1, "View advanced options")
    AFn_formText(p, "Note: File path and name must not include spaces or any special characters", 22, y, ?label "nospaces"),  y = y + 1
    AFn_formThumbnail(p, "pbmthumbnail_small", 46, y, 33, 21, ?options "stretch")
    AFn_formThumbnail(p, "pbmthumbnail_big", 17, y + 2, 62, 38, ?options "stretch")

    y = y + 2
    AFn_formGroup(p, "Pre-processing Settings", 1, y, 43, 19 ?label "mkbitmapgrp"), y = y + 2
    AFn_formChecklistItem(p, "mkbitmap", 2, y, "Pre-process")
    AFn_formButton(p, "mkbitmapdefaults", "Defaults", 35, y, 6, 3), y = y + 2
    AFn_formText(p, "Pre-processes colour/greyscale image for improved tracing.", 2, y, ?label "mkbitmapinfo"), y = y + 2
    AFn_formChecklistItem(p, "mkbitmapinvert", 3, y, "Invert the input (undo 'blackboard' effect)"), y = y + 2
    AFn_formChecklistItem(p, "mkbitmaphipassfilter", 3, y, "Apply High Pass Filtering")
    AFn_formText(p, "No Image Selected.", 54, y, ?label "noimage_small", ?options "CENTER")
    AFn_formIntSlideBar(p, "mkbitmapfilterradius", 2, 2, 26, y, 0, 99, ?title "Radius:", ?fillInX 33, ?value 4), y = y + 2
    AFn_formIntSlideBar(p, "mkbitmapscale", 2, 2, 3, y, 1, 99, ?title "Pre-scale:", ?fillInX 10, ?value 2), y = y + 2
    AFn_formChecklistItem(p, "mkbitmapcubic", 3, y, "Use cubic interpolation", ?radioLabel "mkbitmapinterp")
    AFn_formChecklistItem(p, "mkbitmaplinear", 23, y, "Use linear interpolation", ?radioLabel "mkbitmapinterp"), y = y + 2
    AFn_formChecklistItem(p, "mkbitmapbilevel", 3, y, "Bilevel conversion", ?radioLabel "mkbitmapconversion")
    AFn_formChecklistItem(p, "mkbitmapgrey", 23, y, "Greymap conversion", ?radioLabel "mkbitmapconversion"), y = y + 2
    AFn_formRealFillin(p, "mkbitmapthreshold", 4, 4, 3, y, ?title "Bilevel Conversion Threshold:", ?fillInX 24, ?value 0.45)
    AFn_formText(p, "No Image Selected.", 28, y, ?label "noimage_big", ?options "CENTER")
    AFn_formButton(p, "mkbitmaphelp", "Info", 37, y + 1, 4, 2), y = y + 3

    AFn_formGroup(p, "Tracing Options", 1, y, 78, 19 ?label "potracegrp"), y = y + 2
    ;Algorithm options:
    AFn_formStrFillin(p, "turnpolicy", 6, 8, 3, y, ?pop "TURNPOLICY", ?title "Turnpolicy:", ?x2 13)
    AFn_formText(p, "- How to resolve ambiguities in path decomposition", 26, y, ?label "turnpolicy_note")
    AFn_formButton(p, "potracedefaults", "Defaults", 70, y, 6, 3), y = y + 2
    AFn_formIntSlideBar(p, "turdsize", 3, 3, 3, y, 1, 999, ?title "Speckle Size:", ?fillInX 13, ?value 2, ?units "pixels")
    AFn_formText(p, "- Suppress speckles of up to this size", 26, y, ?label "turdsize_note"), y = y + 2
    AFn_formRealFillin(p, "alphamax", 5, 5, 3, y, ?title "Corner Threshold:", ?fillInX 16, ?minVal -1, ?maxVal 1.334, ?value 1.0)
    AFn_formText(p, "- The smaller this value, the more sharp corners will be produced.", 26, y, ?label "alphamax_note"), y = y + 2
    AFn_formChecklistItem(p, "longcurve", 3, y, "Curve Optimisation")
    AFn_formText(p, "- Join adjacent Bezier curve segments when possible.", 26, y, ?label "longcurve_note"), y = y + 2
    AFn_formRealFillin(p, "opttolerance", 4, 4, 3, y, ?title "Tolerance:", ?fillInX 12, ?minVal 0, ?maxVal 1.0, ?value 0.2)
    AFn_formText(p, "- Curve optimisation tolerance.", 26, y, ?label "opttolerance_note"), y = y + 2
    AFn_formIntSlideBar(p, "unitn", 2, 2, 3, y, 1, 99, ?title "Output Quantisation:", ?fillInX 18, ?value 10)
    AFn_formText(p, "- Quantise output to 1/unit pixels.", 26, y, ?label "unitn_note"), y = y + 2
    ;Frontend options:
    AFn_formRealFillin(p, "blacklevel", 4, 4, 3, y, ?title "Black Level:", ?fillInX 13, ?minVal 0, ?maxVal 1.0, ?value 0.5)
    AFn_formText(p, "- Black/white cutoff in input file.", 26, y, ?label "blacklevel_note"), y = y + 2
    AFn_formChecklistItem(p, "inverted", 3, y, "Inverted")
    AFn_formText(p, "- Invert the input bitmap before processing.", 26, y, ?label "inverted_note")
    AFn_formButton(p, "potracehelp", "Info", 72, y + 1, 4, 2), y = y + 4

    AFn_formRealFillin(p, "width",  5, 5,  2, y, ?title "Width:",  ?fillInX  7, ?units logoMaker_designUnits)
    AFn_formRealFillin(p, "height", 5, 5, 22, y, ?title "Height:", ?fillInX 27, ?units logoMaker_designUnits)
    AFn_formChecklistItem(p, "aspectratio", 42, y, "Maintain Aspect Ratio")
    AFn_formButton(p, "defaultsizes", "Default Size", 65, y, 12, 3), y = y + 3
  
    AFn_formIntegerFillin(p, "rotation", 3, 4, 2, y, ?pop "ROTATION", ?title "Rotation:", ?fillInX 9, ?minVal -359, ?maxVal 359, ?value 0, ?units "degrees")
    AFn_formText(p, "(Anticlockwise)", 25, y)
    AFn_formChecklistItem(p, "mirror", 42, y, "Mirror")
    AFn_formChecklistItem(p, "fixed", 52, y, "Fix Symbol"), y = y + 2

    AFn_formText(p, "Class/Subclass for Graphics:", 2, y), y = y + 2
    AFn_formPop(p, "class", "CLASS", 5, y, 19, ?options "prettyprint"), y = y + 2
    AFn_formColor(p, "subcolour", 2, y, 2, 1)
    AFn_formPop(p, "subclass", "SUBCLASS", 5, y, 19 ?options "prettyprint ownerdrawn")
  
    AFn_formStrFillin(p, "symbolname", 27, 27, 30, y, ?title "Symbol Name:", ?x2 41), y = y + 3

    ;AFn_formChecklistItem(p, "viewadvancedoptions", 2, y + 1, "View advanced options")
    AFn_formButton(p, "createlogo", "Place Logo", 30, y, 20, 4), y = y + 1
    AFn_formButton(p, "generalinfo", "Info", 60, y, 8, 3)
    AFn_formButton(p, "quit", "Exit", 70, y, 8, 3)
  
    AFn_formEnd(p)
    axlDMClose(p)
    form = axlFormCreate(gensym(), formFile, '(E INNER), 'logoMaker_formAction, nil)
    deleteFile(formFile)

    axlFormColorize(form, "nospaces", 'text, 'blue)
    axlFormColorize(form, "mkbitmapinfo", 'text, 'blue)
    logoMaker_mkBitmapDefaults(form)
    logoMaker_potraceDefaults(form)
    logoMaker_setOptionsLevelVisibility(form)
    foreach(field, '("width", "height", "defaultsizes", "createlogo"), axlFormSetFieldEditable(form, field, nil))
    axlFormSetField(form, "aspectratio", t)
    class = axlMapClassName("PACKAGE GEOMETRY"); Must be upper case
    subclass = "SILKSCREEN_TOP"
    axlBuildClassPopup(form, "class")
    axlFormSetField(form, "class", class)
    axlBuildSubclassPopup(form, "subclass", class)
    axlFormSetField(form, "subclass", subclass)
    AFn_formSetLayerSubColour(form, "subcolour", strcat(class, "/", subclass))
    logoMaker_check4plugins(form)
    axlFormDisplay(form)
   else
    axlUIConfirm("Error: Could not write the form file - check your write access to the temp folder")
  )
))

defun( logoMaker_mkBitmapDefaults (form)
  logoMaker_needMkbitmap(form)
  axlFormSetField(form, "mkbitmapinvert", nil); Invert the input (undo 'blackboard' effect).
  axlFormSetField(form, "mkbitmaphipassfilter", t); Apply highpass filter with radius n.
  axlFormSetField(form, "mkbitmapfilterradius", 4)
  axlFormSetFieldEditable(form, "mkbitmapfilterradius", t)
  axlFormSetField(form, "mkbitmapscale", 2); Scale by integer factor n.
  axlFormSetField(form, "mkbitmapcubic", t); Use cubic interpolation (else use linear interpolation).
  axlFormSetField(form, "mkbitmapbilevel", t); Enable bilevel conversion (or output a greymap).
  axlFormSetField(form, "mkbitmapthreshold", 0.45); Set threshold for bilevel conversion.
  axlFormSetFieldEditable(form, "mkbitmapthreshold", t)
)

defun( logoMaker_setOptionsLevelVisibility (form)
 let((smallView, vis, fields)
  smallView = axlFormGetField(form, "viewadvancedoptions")
  vis = if(smallView, 1, 0)
  fields = '("grp", "defaults", "info", "invert", "hipassfilter", "filterradius", "filterradius_title"
    "scale", "scale_title", "cubic", "linear", "bilevel", "grey", "threshold", "threshold_title", "help")
  foreach(field, fields, axlFormSetFieldVisible(form, strcat("mkbitmap", field), vis))
  fields = '("potracegrp", "potracedefaults", "turnpolicy", "turnpolicy_title", "turnpolicy_note", "turdsize", "turdsizeUnits", "turdsize_title", "turdsize_note"
    "alphamax", "alphamax_title", "alphamax_note", "longcurve", "longcurve_note", "opttolerance", "opttolerance_title", "opttolerance_note"
    "unitn", "unitn_title", "unitn_note", "blacklevel", "blacklevel_title", "blacklevel_note", "inverted_note", "potracehelp"
  )
  foreach(field, fields, axlFormSetFieldVisible(form, field, vis))
  vis = form ->bmpfile
  axlFormSetFieldVisible(form, "nospaces", if(vis, 0, 1))
  axlFormSetFieldVisible(form, "pbmthumbnail_small", if(smallView && vis, 1, 0))
  axlFormSetFieldVisible(form, "noimage_small", if(smallView && !vis, 1, 0))
  axlFormSetFieldVisible(form, "pbmthumbnail_big", if(!smallView && vis, 1, 0))
  axlFormSetFieldVisible(form, "noimage_big", if(!smallView && !vis, 1, 0))
))

defun( logoMaker_checkImageFile (form, imageFile)
 let((bmpFileName, fileInfo, pathName, fileName, extn, msg, cwd, cmd)
  form ->bmpfile = nil
  if(imageFile && isFile(imageFile) then
    fileInfo = axlDMFileParts(imageFile)
    pathName = car(fileInfo)
    fileName = cadr(fileInfo)
    extn = cadddr(fileInfo)
    when(extn, extn = lowerCase(extn))
    form ->extn = extn
    cond(
      (pathName && !logoMaker_validPathName(pathName)
	sprintf(msg, "Path name contains invalid characters (%s)", logoMaker_validPathName(pathName, t))
      )
      (!logoMaker_validSymbolName(fileName)
	sprintf(msg, "File name contains invalid characters (%s)", logoMaker_validSymbolName(fileName, t))
      )
      (t
        if(extn == "bmp" then
	  bmpFileName = imageFile
	 else
	  cwd = getWorkingDir()
	  sprintf(bmpFileName, "%s/%s.bmp", cwd, fileName)
	  sprintf(cmd, "%s \"%s\" -format bmp -strip -resize \"2400x2400\" -colors 256 \"%s\"", logoMaker_MagickConvertEXE, imageFile, bmpFileName)
	  axlRunBatchDBProgram("convert", cmd, ?noUnload t, ?startMsg "Converting to bmp", ?silent t, ?noProgress t)
	)
	axlFormSetField(form, "imagefile", imageFile)
	form ->bmpfile = bmpFileName
	if(bmpFileName then
	  logoMaker_needMkbitmap(form); sets/unsets the pre-processing radio button
	  if(logoMaker_drawPbm(form) then
	    axlFormSetField(form, "symbolname", fileName)
	    unless(extn == "bmp", logoMaker_tempFiles = unique(cons(bmpFileName, logoMaker_tempFiles)))
	   else form ->bmpfile = bmpFileName = nil
	  )
	 else msg = "Not a known or valid raster graphics image"
	)
      )
    ); cond
   else
    when(imageFile && imageFile != "", sprintf(msg, "File (%s) does not exist", imageFile))
  ); if
  when(msg, axlFormMsg(form, "warnmsg", msg))
  logoMaker_setSizeFields(form)
  unless(bmpFileName
    axlFormSetField(form, "imagefile", nil)
    axlFormSetFieldVisible(form, "nospaces", 1)
    axlFormSetField(form, "pbmthumbnail_small", nil)
    axlFormSetField(form, "pbmthumbnail_big", nil)
    axlFormSetFieldVisible(form, "noimage_small", if(axlFormGetField(form, "viewadvancedoptions"), 1, 0))
    axlFormSetFieldVisible(form, "noimage_big", if(axlFormGetField(form, "viewadvancedoptions"), 0, 1))
    axlFormSetFieldVisible(form, "pbmthumbnail_small", 0)
    axlFormSetFieldVisible(form, "pbmthumbnail_big", 0)
    axlFormSetField(form, "symbolname", nil)
  )
))

defun( logoMaker_needMkbitmap (form)
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
  axlFormSetField(form, "mkbitmap", nColours > 0 || nBits > 1)
))

defun( logoMaker_potraceDefaults (form)
  axlFormSetField(form, "turnpolicy", "minority"); How to resolve ambiguities in path decomposition.
  axlFormSetField(form, "turdsize", 2);	Suppress speckles of up to this size.
  axlFormSetField(form, "alphamax", 1.0); Corner threshold parameter.
  axlFormSetField(form, "longcurve", t); Turn on curve optimization.
  axlFormSetField(form, "opttolerance", 0.2); Curve optimization tolerance.
  axlFormSetField(form, "unitn", 10); Quantize output to 1/unit pixels.
  axlFormSetField(form, "blacklevel", 0.5); Black/white cutoff in input file.
  axlFormSetField(form, "inverted", nil); Invert bitmap off.
)

defun( logoMaker_check4plugins (@optional form)
 let((converterOK, cmd, mkbitmapOK, potraceOK, missingPlugins, msg)
  converterOK = and(logoMaker_MagickConvertEXE, isExecutable(car(parseString(logoMaker_MagickConvertEXE))))
  when(logoMaker_potracePath
    sprintf(cmd, "%s/mkbitmap -v", logoMaker_potracePath)
    mkbitmapOK = !numberp(axlRunBatchDBProgram("makebitmap", cmd, ?noUnload t, ?silent t, ?noProgress t))
    sprintf(cmd, "%s/potrace -v", logoMaker_potracePath)
    potraceOK = !numberp(axlRunBatchDBProgram("potrace", cmd, ?noUnload t, ?silent t, ?noProgress t))
  )
  missingPlugins = remq(t, list(or(converterOK, "ImageMagick convert"), or(mkbitmapOK, "makebitmap"), or(potraceOK, "potrace")))
  when(missingPlugins
    when(form
      foreach(field, '("imagefile", "imagebrowse", "createlogo"), axlFormSetFieldEditable(form, field, 0))
      sprintf(msg, "Missing plugins: %s. Contact your administrator", buildString(missingPlugins, ", "))
      axlFormMsg(form, "errormsg", msg)
    )
    logoMaker_Help("Plugins")
  )
  !missingPlugins
))

defun( logoMaker_formAction (form)
 let((value, mkBitmap, filters, extn, imageFile, msg, class, subclass, layer, subclasses)
  value = form ->curValue
  mkBitmap = axlFormGetField(form, "mkbitmap")
  case(form ->curField
    ("imagebrowse"
      filters = '(("bmp", "Bitmap")("jpg", "Jpeg")("gif", "Compuserve GIF"))
      and(
	extn = form ->extn
	extn != caar(filters)
	extn = assoc(extn, filters)
	filters = cons(extn, remove(extn, filters)); Make the previously selected image type the default.
      )  
      filters = mapcar(lambda((f), sprintf(nil, "%s files (*.%s)|*.%s" car(f), cadr(f), cadr(f))), mapcar('reverse, filters))
      imageFile = axlDMFileBrowse(nil, nil, ?title "Select Image file", ?optFilters buildString(filters, "|"))
      logoMaker_checkImageFile(form, imageFile)
    )
    ("imagefile", logoMaker_checkImageFile(form, value))
    ("mkbitmap", logoMaker_drawPbm(form))
    ("mkbitmapdefaults", logoMaker_mkBitmapDefaults(form), when(axlFormGetField(form, "mkbitmap"), logoMaker_drawPbm(form)))
    ("mkbitmapinvert", when(mkBitmap, logoMaker_drawPbm(form)))
    ("mkbitmaphipassfilter", axlFormSetFieldEditable(form, "mkbitmapfilterradius", value), when(mkBitmap, logoMaker_drawPbm(form)))
    ("mkbitmapfilterradius", when(mkBitmap, logoMaker_drawPbm(form)))
    ("mkbitmapscale", when(mkBitmap, logoMaker_drawPbm(form)))
    ("mkbitmapcubic", when(mkBitmap, logoMaker_drawPbm(form)))
    ("mkbitmapbilevel", axlFormSetFieldEditable(form, "mkbitmapthreshold", value), when(mkBitmap, logoMaker_drawPbm(form)))
    ("mkbitmapthreshold", when(mkBitmap, logoMaker_drawPbm(form)))
    ("mkbitmaphelp", logoMaker_Help("Pre-processing Options"))
    ("potracehelp", logoMaker_Help("Tracing Options"))
    
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
    ("defaultsizes", logoMaker_setSizeFields(form))
    ("rotation", logoMaker_setDynamicsRotMir(form))
    ("mirror", logoMaker_setDynamicsRotMir(form))
    ("class"
      class = value, subclass = axlFormGetField(form, "subclass")
      layer = strcat(class, "/" subclass)
      axlBuildSubclassPopup(form, "subclass", class)
      unless(axlIsLayer(layer)
        subclasses = axlGetParam(strcat("paramLayerGroup:", class)) ->groupMembers
        subclass = car(setof(sub, subclasses, axlIsVisibleLayer(strcat(class, "/", sub))) || subclasses)
      )
      axlFormSetField(form, "subclass", subclass)
      AFn_formSetLayerSubColour(form, "subcolour", strcat(class, "/" subclass))
      logoMaker_setDynamicsRotMir(form)
    )
    ("subclass"
      class = axlFormGetField(form, "class"), subclass = value
      AFn_formSetLayerSubColour(form, "subcolour", strcat(class, "/" subclass))
      logoMaker_setDynamicsRotMir(form)
    )
    ("subcolour"
      class = axlFormGetField(form, "class")
      when(class
	subclass = axlFormGetField(form, "subclass")
	layer = strcat(class, "/" subclass)
	when(axlIsLayer(layer), axlVisibleLayer(layer, !axlIsVisibleLayer(layer)), axlVisibleUpdate(t))
	AFn_formSetLayerSubColour(form, "subcolour", layer)
      )
    )
    ("symbolname"
      unless(logoMaker_validSymbolName(value)
        axlFormRestoreField(form, "symbolname")
        sprintf(msg, "'%s' contains invalid symbol name characters (%s)", value, logoMaker_validSymbolName(value, t))
        axlFormMsg(form, "warnmsg", msg)
      )
    )
    ("viewadvancedoptions", logoMaker_setOptionsLevelVisibility(form))
    ("createlogo"
      axlUIWShow(form, 'hide)
      logoMaker_create(form)
      axlUIWShow(form, 'show)
    )
    ("generalinfo", logoMaker_Help("About This Utility"))
    ("quit"
      foreach(file, logoMaker_tempFiles, when(isFile(file), deleteFile(file)))
      axlFormClose(form), axlCancelEnterFun()
    )
  )
))

defun( logoMaker_validSymbolName (name @optional returnBadCharacters)
  logoMaker_validName(name, "^[-a-zA-Z0-9_]+", returnBadCharacters)
)

defun( logoMaker_validPathName (name @optional returnBadCharacters)
  logoMaker_validName(name, "^[-.a-zA-Z0-9_:/\\]+", returnBadCharacters)
)

defun( logoMaker_validName (name, matchStr @optional returnBadCharacters)
 let((chars, result)
  chars = parseString(name, "")
  result = forall(ch, chars, rexMatchp(matchStr, ch))
  when(returnBadCharacters && !result
    foreach(ch, chars, unless(rexMatchp(matchStr, ch), result = cons(ch, result)))
    result = buildString(mapcar(lambda((ch), sprintf(nil, "'%s'", ch)), unique(result)), ", ")
  )
  result
))

defun( logoMaker_drawPbm (form); Converts the pbm to a bmp using ImageMagick utility before displaying it on the form.
 let((bmpFileName, pbmFileName, mk_bmpFileName, cmd, fileParts, thumbnailExists)
  bmpFileName = form ->bmpfile
  if(bmpFileName && isFile(bmpFileName) && axlFormGetField(form, "mkbitmap") then
    pbmFileName = logoMaker_mkbitmap(form, bmpFileName)
    if(pbmFileName then
      fileParts = axlDMFileParts(pbmFileName)
      sprintf(mk_bmpFileName, "%s/%s.bmp", car(fileParts), cadr(fileParts))
      sprintf(cmd, "%s \"%s\" -format bmp -strip -resize \"2400x2400\" \"%s\"", logoMaker_MagickConvertEXE, pbmFileName, mk_bmpFileName)
      axlRunBatchDBProgram("convert", cmd, ?noUnload t, ?startMsg "Converting to suitable bmp for form display", ?silent t, ?noProgress t)
      if(isFile(mk_bmpFileName) then
	logoMaker_tempFiles = unique(cons(mk_bmpFileName, logoMaker_tempFiles))
	sprintf(cmd, "%s \"%s\" -strip -resize \"1200x1200\" -extent \"1200x1200\" tempLogoForm.bmp", logoMaker_MagickConvertEXE, pbmFileName)
	axlRunBatchDBProgram("convert", cmd, ?noUnload t, ?startMsg "Converting to suitable bmp for form display", ?silent t, ?noProgress t)
	if(isFile("tempLogoForm.bmp") then
	  axlFormSetField(form, "pbmthumbnail_small", "tempLogoForm.bmp")
	  axlFormSetField(form, "pbmthumbnail_big", "tempLogoForm.bmp")
	  logoMaker_tempFiles = unique(cons("tempLogoForm.bmp", logoMaker_tempFiles))
         else
	  logoMaker_Help("ImageMagick bmp conversion failure")
	  axlFormMsg(form, "warnmsg", "ImageMagick conversion, from mkbitmap pbm file to bitmap for form display, failed")
	)
      ); if
     else
      logoMaker_Help("mkbitmap failure")
      axlFormMsg(form, "warnmsg", "mkbitmap command failed")
    )
   else
    sprintf(cmd, "%s \"%s\" -strip -resize \"1200x1200\" -extent \"1200x1200\" tempLogoForm.bmp", logoMaker_MagickConvertEXE, bmpFileName)
    axlRunBatchDBProgram("convert", cmd, ?noUnload t, ?startMsg "Converting to suitable bmp for form display", ?silent t, ?noProgress t)
    if(isFile("tempLogoForm.bmp") then
      axlFormSetField(form, "pbmthumbnail_small", "tempLogoForm.bmp")
      axlFormSetField(form, "pbmthumbnail_big", "tempLogoForm.bmp")
      logoMaker_tempFiles = unique(cons("tempLogoForm.bmp", logoMaker_tempFiles))
     else
      logoMaker_Help("ImageMagick bmp conversion failure")
      axlFormMsg(form, "warnmsg", "ImageMagick conversion, from original bitmap file to bitmap for form display, failed")
    )
    pbmFileName = bmpFileName
  )
  axlFormSetFieldVisible(form, "nospaces", if(bmpFileName, 0, 1))
  thumbnailExists = isFile(axlFormGetField(form, "pbmthumbnail_small"))
  axlFormSetFieldVisible(form, "noimage_small", if(thumbnailExists || !axlFormGetField(form, "viewadvancedoptions"), 0, 1))
  axlFormSetFieldVisible(form, "pbmthumbnail_small", if(thumbnailExists && axlFormGetField(form, "viewadvancedoptions"), 1, 0))
  thumbnailExists = isFile(axlFormGetField(form, "pbmthumbnail_big"))
  axlFormSetFieldVisible(form, "noimage_big", if(thumbnailExists || axlFormGetField(form, "viewadvancedoptions"), 0, 1))
  axlFormSetFieldVisible(form, "pbmthumbnail_big", if(thumbnailExists && !axlFormGetField(form, "viewadvancedoptions"), 1, 0)) 
  pbmFileName
))

defun( logoMaker_setSizeFields (form)
 let((bmpFileName, width, height, p, xPixels, yPixels)
  bmpFileName = form ->bmpfile
  when(bmpFileName && isFile(bmpFileName)
    width = height = if(member(logoMaker_designUnits, '("mils", "inches")), axlMKSConvert(1 "inches"), axlMKSConvert(25 "mm"))
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

defun( logoMaker_setDynamicsRotMir (form)
 let((rotation, mirror)
  rotation = axlFormGetField(form, "rotation")
  mirror = axlFormGetField(form, "mirror")
  when(substring(axlFormGetField(form, "subclass"), -6) == "BOTTOM", mirror = !mirror)
  axlSetDynamicsRotation(rotation)
  axlSetDynamicsMirror(mirror)
))

defun( logoMaker_mkbitmap (form, bmpFile)
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
  sprintf(cmd, "%s/mkbitmap %s \"%s\" -o \"%s\"", logoMaker_potracePath, options, bmpFile, bitmapOutFile)
  and(
    !numberp(axlRunBatchDBProgram("makebitmap", cmd, ?noUnload t, ?silent t, ?noProgress t))
    logoMaker_tempFiles = unique(cons(bitmapOutFile, logoMaker_tempFiles))
    bitmapOutFile
  )
))

defun( logoMaker_create (form)
 let((bitmapFile, symbolName, tad, x, y, symDef, mark, popup, popupGray (continue t), event, pt, rot, mirror, sym, bmpFile)
  bitmapFile = form ->bmpfile
  when(bitmapFile && isFile(bitmapFile)
    symbolName = axlFormGetField(form, "symbolname")
    when(!symbolName || symbolName == "", symbolName = "bitmaplogo")
    when(axlFormGetField(form, "mkbitmap")
      sprintf(bitmapFile, "%s/%s_mk.bmp", getWorkingDir(), cadr(axlDMFileParts(bitmapFile)))
    )
  )
  when(bitmapFile && isFile(bitmapFile)
    tad = axlMKSConvert(1, "mils")
    x = axlFormGetField(form, "width") + tad, y = axlFormGetField(form, "height") + tad
    when(axlDesignType(nil) == "LAYOUT"
      symDef = axlDBCreateSymDefSkeleton('("TEMPLOGO", "mechanical"), list(-tad:-tad, x:y))
    )
    logoMaker_createSym(form, bitmapFile, ?symbol symDef)
    axlSetDynamicsRotation(0)
    axlSetDynamicsMirror(nil)
    axlDynamicsObject(symDef, 0:0)
    axlDeleteObject(symDef)
    mark = axlDBTransactionStart()
    form ->oopsCount = 0
    popup = axlUIPopupDefine(nil '(
      ("Done", "axlDBTransactionCommit(mark), axlFinishEnterFun(), continue = nil")
      ("Oops", "axlDBTransactionOops(mark), when(zerop(form ->oopsCount = form ->oopsCount - 1), axlUIPopupSet(popupGray))")
      ("Cancel", "axlDBTransactionRollback(mark), axlCancelEnterFun(), continue = nil")
      ("MENU_SEPARATOR", nil)
      ("Rotate 90" "logoMaker_rotate(form)")
      ("Mirror" "logoMaker_mirror(form)")
    ))
    axlUICmdPopupSet(popup)
    popupGray = axlUIPopupDefine(nil, '(
      ("Done", "axlDBTransactionCommit(mark), axlFinishEnterFun(), continue = nil")
      ("Cancel", "axlDBTransactionRollback(mark), axlCancelEnterFun(), continue = nil")
      ("MENU_SEPARATOR", nil)
      ("Rotate 90" "logoMaker_rotate(form)")
      ("Mirror" "logoMaker_mirror(form)")
    ))
    axlUIPopupSet(popupGray)
    logoMaker_setDynamicsRotMir(form)
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
	  bmpFile = if(axlFormGetField(form, "mkbitmap")
	    then sprintf(nil, "%s/%s.bmp", getWorkingDir(), cadr(axlDMFileParts(bitmapFile)))
	    else bitmapFile
	  )
	  when(bmpFile && isFile(bmpFile)
	    logoMaker_createSym(form, bmpFile, ?symbol sym, ?location pt, ?angle float(rot), ?mirror mirror)
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

defun( logoMaker_rotate (form)
  axlFormSetField(form, "rotation", mod(axlFormGetField(form, "rotation") + 90, 360))
  logoMaker_setDynamicsRotMir(form)
)

defun( logoMaker_mirror (form)
  axlFormSetField(form, "mirror", !axlFormGetField(form, "mirror"))
  logoMaker_setDynamicsRotMir(form)
)

defun( logoMaker_createSym (form, bitmapFile @key symbol, (location 0:0), (angle 0.0), mirror)
 let((x0, y0, turnPolicy, turdSize, alphaMax, longCurve, unitN, blackLevel, inverted, layer
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
  sprintf(logoWidth, "%gmm", axlMKSConvert(axlFormGetField(form, "width"), logoMaker_designUnits, "mm"))
  sprintf(logoHeight, "%gmm", axlMKSConvert(axlFormGetField(form, "height"), logoMaker_designUnits, "mm"))
  sprintf(svgFile, "%s.svg", cadr(axlDMFileParts(bitmapFile)))
  sprintf(options "-z %s -t %d -a %2.2f %s -u %d -k %2.2f %s -W %s -H %s"; -A %d
    turnPolicy, turdSize, alphaMax, longCurve, unitN, blackLevel, inverted, logoWidth, logoHeight)
  sprintf(cmd, "%s/potrace -s -o %s %s %s", logoMaker_potracePath, svgFile, options, bitmapFile)
  if(!numberp(axlRunBatchDBProgram("potrace", cmd, ?noUnload t, ?silent t, ?noProgress t)) then
    logoMaker_tempFiles = unique(cons(svgFile, logoMaker_tempFiles))
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
		ptR = axlGeoRotatePt(angle, x0 + PtsToUnits(x) * scaleX:y0 + PtsToUnits(y) * scaleY, x0:y0); [mirror]
		rpath = axlPathStart(list(ptR))
	      )
	      (cmd == "m"
		x1 = x = x + dx, y1 = y = y + dy
		ptR = axlGeoRotatePt(angle, x0 + PtsToUnits(x) * scaleX:y0 + PtsToUnits(y) * scaleY, x0:y0); [mirror]
		rpath = axlPathStart(list(ptR))
	      )
	      (cmd == "c"
		pt1 = x:y, xb = x + dx, yb = y + dy, pt2 = xb:yb
		dx = readstring(car(data)), dy = readstring(cadr(data)), data = cddr(data)
		xc = x + dx, yc = y + dy, pt3 = xc:yc
		dx = readstring(car(data)), dy = cadr(data), data = cddr(data)
		pathEnd = and(substring(dy, -1) == "z", dy = substring(dy, 1, strlen(dy) - 1))
		dy = readstring(dy), x = x + dx, y = y + dy, pt4 = x:y
		pts = BezierToPath(pt1, pt2, pt3, pt4)
		foreach(pt, cdr(pts)
		  ptR = axlGeoRotatePt(angle, x0 + PtsToUnits(car(pt)) * scaleX:y0 + PtsToUnits(cadr(pt)) * scaleY, , x0:y0)
		  axlPathLine(rpath, nil, ptR)
		)
	      )
	      (cmd == "l"
		x = x + dx, y = y + dy
		ptR = axlGeoRotatePt(angle, x0 + PtsToUnits(x) * scaleX:y0 + PtsToUnits(y) * scaleY, x0:y0)
		axlPathLine(rpath, nil, ptR)
	      )
	      (t, warn("Character '%s' in svg file not recognised\n", cmd), x = x + dx, y = y + dy)
	    )
	    when(pathEnd
	      unless(x == x1 && y == y1
	        ptR = axlGeoRotatePt(angle, PtsToUnits(x1) * scaleX:PtsToUnits(y1) * scaleY, x0:y0)
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
    logoMaker_Help("potrace failure")
    axlFormMsg(form, "warnmsg", "potrace command failed")
  )
))

defun( logoMaker_Help (section @optional header)
 let((helpTxt, sectionList, title, filePath, p, (author "dave.elder@tait.co.nz"))
  helpTxt = logoMaker_helpTxt()
  sectionList = assoc(section, helpTxt)
  if(sectionList then
    title = cadr(sectionList) || "Logo Maker Help File"
    rexCompile(" ")
    filePath = getWorkingDir()
    unless(isWritable(filePath), filePath = getShellEnvVar("TEMP"))
    filePath = strcat(filePath, "/", "taithelp_", rexReplace(section, "", 0), ".txt")
    p = outfile(filePath, "w")
    if(p then
      unless(header, header = section)
      fprintf(p, "%s\n%s\n\n", header, buildString(vectorToList(makeVector(strlen(header), "=")), ""))
      foreach(ln, caddr(sectionList), fprintf(p, "%s\n", ln))
      fprintf(p, "\n\nFor further information please email: %s\n", author)
      close(p)
      axlUIViewFileCreate(filePath, title, t)
     else axlUIConfirm("Could not create help text temporary file")
    )
   else axlUIConfirm("Help text not found")
  )
))

defun( logoMaker_helpTxt ()
  list(
    list("About This Utility", "General Information"
      list(
	"Purpose:"
	"	Create graphics such as logos in Allegro based on bitmap-type images."
	""
	"	When using Allegro Layout, scaled and/or mirrored graphics are attached"
	"	to a mechanical symbol. This symbol may be subsequently moved."
	""
	"	By running this utility in the Allegro symbol editor you can create a"
	"	(non-scalable) symbol for placing in your company library."
	""
	"Limitations:"
	"	potrace creates a Scalable Vector Graphics (SVG) file containing lines and"
	"	bezier curves to define the outline of polygons. This Skill program draws"
	"	the Bezier curves using a series of straight lines. In some instances this"
	"	will result in Allegro shapes that do not represent the original image well."
	"	I will happily incorporate a circular arc fitting routine if a maths guru"
	"	has time to develop one and sends it to me."
	""
	"Platforms tested (It should work on others too):"
	"	Windows XP, Linux RH"
	""
	"Allegro verions:"
	"	16.x"
	""
	"Acknowledgements:"
	"	This utility relies heavily on the potrace open source code generously"
	"	provided by Peter Selinger."
	"		http://potrace.sourceforge.net"
	"	It uses:"
	"	The ImageMagick Command Line Image File Converter available as a"
	"	free download from ImageMagick. It is pre-installed on many systems."
	"		http://www.imagemagick.org"
	""
	"WARRANTY:"
	"	None. This program is free software and is available as-is"
	"	It may not work in all environments. There is no formal support."
	""
	"Modification and Distribution"
	"	You may redistribute and/or modify this utility. However, in the open-source"
	"	spirit in which this is provided to the Cadence community, any improvements"
	"	and enhancements should be submitted to the originator for inclusion in future"
	"	releases."
      )
    )
    list("Pre-processing Options", "Pre-process Image"
      list(
	"This section uses the mkbitmap program."
	""
	"Mkbitmap is a program distributed with Potrace which can be used to pre-process"
	"the input for better tracing behavior on greyscale and color images."
	""
	"mkbitmap reads an image, and applies one or more of the following operations to"
	"it, in this order: inversion, highpass filtering, scaling, and thresholding."
	"Each operation can be individually controlled and turned on or off."
	""
	"The principal use of mkbitmap is to convert color or greyscale images into a"
	"format suitable as input for other programs, particularly the tracing program"
	"potrace."
	""
	"It is particularly useful for converting scanned line art, such as cartoons,"
	"handwritten text, etc., to high-resolution bilevel images."
	""
	"Highpass filtering can be used to ensure that features such as lines and text"
	"are preserved, while at the same time compensating for uneven background."
	""
	"Scaling is important because a scanned greyscale image contains more visual"
	"detail than a bilevel image at the same resolution. By scaling the image to"
	"a higher resolution (using interpolation) before thresholding it, some of this"
	"detail is preserved."
	""
	"Thresholding means converting a greyscale image to a bilevel image using only"
	"black and white pixels. Pixels that are darker than a certain threshold value"
	"are converted to black."
	""
	"Optional inversion is useful if the input image shows bright features on dark"
	"background, such as a picture of chalk drawings on a blackboard."
	""
	"Invert"
	"	Invert the input image."
	"	If this option is chosen, it is applied to the image before any other"
	"	operation. It is used to deal with white-on-black images, such as"
	"	photographs of chalk drawings on a blackboard."
	"	Note that the behavior of this option is not in general the same as"
	"	inverting the output bitmap, unless the thresholding value is also"
	"	inverted."
	""
	"Apply Highpass filtering"
	"	Apply a highpass filter to the image."
	"	This filter is approximately Gaussian and non-directional."
	"	The effect is to preserve small detail while compensating for unevenness"
	"	in the background. The parameter n is a radius (in pixels) which"
	"	corresponds approximately to the size of details which should be"
	"	preserved. More precisely, the filter is implemented by subtracting a"
	"	blurred version of the image from the original image."
	"	The parameter n is equal to the standard deviation of the blur."
	"	The output of the filtering step is a normalized image whose average"
	"	brightness is exactly 0.5."
	"	The default filter radius is 4."
	""
	"Scale"
	"	Scale the image by an integer factor n>0."
	"	Scaling is done after highpass filtering, but before the thresholding"
	"	step."
	"	A scaling factor of 1 indicates that no scaling is to be done."
	"	Otherwise, interpolation is used to fill in the in-between pixels."
	"	If the output of mkbitmap is to be used as input to a tracing program"
	"	such as potrace, a scaling factor of 2 is recommended. This preserves"
	"	the right amount of detail for the tracing algorithm to work well."
	"	If a scaling factor of 1 is used, too much detail is lost."
	"	If a scaling factor of 3 or higher is used, the interpolation tends to"
	"	\"invent\" detail which was not present in the original image, thus"
	"	preventing potrace from doing a good job."
	""
	"Cubic interpolation"
	"	Use cubic interpolation when scaling to a higher resolution."
	"	It is slower than linear interpolation, but leads to better results."
	""
	"Linear interpolation"
	"	Use linear interpolation when scaling to a higher resolution."
	"	This is slightly faster, but less nice, than the default cubic"
	"	interpolation."
	""
	"Bilevel conversion"
	"	If this option is selected, processing continues using the conversion"
	"	threshold."
	""
	"Greymap conversion"
	"	Disable bilevel conversion."
	"	If this option is selected, processing stops after the scaling step"
	"	and a greymap is output."
	""
	"Bilevel conversion threshold"
	"	Set the threshold grey value for bilevel conversion."
	"	The parameter n is a brightness value between 0 for black and 1 for"
	"	white. Any pixels below this brightness will be converted to black"
	"	(thus, smaller values of n will lead to whiter output)."
	""
	"http://potrace.sourceforge.net/mkbitmap.1.html"
      )
    )
    list("Tracing Options", "Potrace utility options"
      list(
	"This section uses the Potrace program."
	""
	"Potrace is a utility for tracing a bitmap, which means, transforming a bitmap"
	"into a smooth, scalable image."
	"The input is a bitmap, which means, a pixel-based image composed of the two"
	"colors black and white only. The resulting image is not \"jaggy\" like a bitmap,"
	"but smooth. It can then be rendered at any resolution." 
	""
	"The input image should only use the two colors black and white. If other pixel"
	"values appear in the input, they will be converted to black and white using a"
	"simple threshold method."
	""
	"Algorithm options:"
	"------------------"
	"Turnpolicy"
	"	Specifies how to resolve ambiguities in path decomposition."
	"	Must be one of black, white, right, left, minority, majority, or random."
	"	Default is minority."
	""
	"Speckle size"
	"	Suppress speckles of up to this many pixels."
	""
	"Corner threshold"
	"	Set the corner threshold parameter. The default value is 1."
	"	The smaller this value, the more sharp corners will be produced."
	"	If this parameter is negative, then no smoothing will be performed and"
	"	the output is a polygon. The largest useful value is 4/3 or 1.334,"
	"	which suppresses all corners and leads to completely smooth output."
	""
	"Curve optimization"
	"	Normally potrace tries to join adjacent Bezier curve segments when this"
	"	is possible. Disabling this behavior, results in a larger file size."
	""
	"Curve optimization tolerance"
	"	The default value is 0.2. Larger values allow more consecutive Bezier"
	"	curve segments to be joined together in a single segment, at the expense"
	"	of accuracy."
	""
	"Output quantization"
	"	Coordinates in the output are rounded to 1/unit pixels."
	"	The default of 10 usually gives good results."
	""
	"Output options:"
	"---------------"
	"Blacklevel"
	"	Set the threshold level for converting input images to bitmaps."
	"	The potrace algorithm expects a bitmap, thus all pixels of the input"
	"	images are converted to black or white before processing begins. Pixels"
	"	whose brightness is less than n are converted to black, all other pixels"
	"	to white."
	"	Here n is a number between 0 and 1. One case is treated specially: if"
	"	the input is in an indexed color format with exactly 2 colors, then the"
	"	blacklevel is ignored and the darker of the two colors is mapped to"
	"	black."
	"	Note: the method used by potrace for converting greymaps to bitmaps is"
	"	very crude; much better results can be obtained if a separate program,"
	"	such as mkbitmap, is used for this purpose. In particular, mkbitmap,"
	"	which is distributed with potrace, has the ability to scale and"
	"	interpolate the image before thresholding, which results in much better"
	"	preservation of detail."
	""
	"Invert"
	"	Invert the input bitmap before processing."
	""
	"http://potrace.sourceforge.net/potrace.1.html"
      )
    )
    list("Plugins", "Plugin Options"
      (list
	"The LogoMaker Skill utility makes use of three free utilities that need to be"
	"installed before use:"
	""
	"1/ potrace - Download the executable from:"
	"	http://potrace.sourceforge.net/download"
	"	http://potrace.sourceforge.net/download/potrace-1.8.win32-i386.zip (Windows)"
	""
	"	set the POTRACE_PATH environment variable to the path to the executable"
	"	eg. C:\\utils\\potrace"
	""
	"2/ mkbitmap - Distributed with the potrace utility"
	""
	"3/ ImageMagick"
	"	- Download and install the precompiled release suitable for your platform from:"
	"	This may not be necessary as ImageMagick is pre-installed on many systems"
	"	http://www.imagemagick.org/script/binary-releases.php"
	"	http://www.imagemagick.org/download/binaries/ImageMagick-6.5.3-Q16-windows.zip"
	""
	"	set the MAGICK_HOME environment variable to the path to the convert executable"
	"	eg. C:\\utils\\ImageMagick\\ImageMagick-6.5.1-3"
      )
    )
    list("Valid Image Types", nil
      list(
        "Over 100 bitmap image types (such as jpeg and gif) can be processed."
        "However, this image type could not be converted to a bitmap."
        "Try opening the file in a graphics tool and saving it as a simple bitmap."
      )
    )
    list("mkbitmap failure", nil
      list(
	"The mkbitmap utility failed to convert this image to a portable bitmap format."
	"The most likely explanation is that the source file is too large, invalid or corrupt."
	"Try opening it in a graphics editor such as MS paint and saving it as a monochrome bitmap"
      )
    )
    list("potrace failure", nil
      list("The potrace utility failed to convert this image to svg.")
    )
    list("ImageMagick bmp conversion failure", nil
      list("The ImageMagick utility failed to convert this image to a bmp.")
    )
  )
)

defun( PtsToUnits (pts), axlMKSConvert(pts / 0.072, "mils"))

defun( Lerp (pt1, pt2, dt); Simple linear interpolation between two points. dt between 0 and 1.0
  list(car(pt1) + (car(pt2) - car(pt1)) * dt, cadr(pt1) + (cadr(pt2) - cadr(pt1)) * dt)
)

defun( BezierPt (a, b, c, d, dt) ;Evaluate a point on a bezier-curve. dt between 0 and 1.0
 let((ab, bc, cd, abbc, bccd)
  ab = Lerp(a, b, dt); point between a and b
  bc = Lerp(b, c, dt); point between b and c
  cd = Lerp(c, d, dt); point between c and d
  abbc = Lerp(ab, bc, dt); point between ab and bc
  bccd = Lerp(bc, cd, dt); point between bc and cd
  Lerp(abbc, bccd, dt); point on the bezier-curve
))

defun( BezierToPath (pt1 pt2 pt3 pt4 @optional (n 10))
 let((dt, pts)
  for(i, 1, n - 1
    dt = i / float(n - 1)
    pts = cons(BezierPt(pt1, pt2, pt3, pt4, dt), pts)
  )
  reverse(pts)
))

unless(fboundp('axlSetDynamicsRotation), defun( axlSetDynamicsRotation (angle, "n"), _axlSetDynamicsRotation(angle))); Public command unavailable before 16.3
unless(fboundp('axlSetDynamicsMirror), defun( axlSetDynamicsMirror (mir, "g"), _axlSetDynamicsMirror(mir))); Public command unavailable before 16.3

defun( logoMaker_formOpenFile (name)
 let((tempFolder)
  tempFolder = cond(
    (axlGetVariable("TEMP") && !index(axlGetVariable("TEMP"), "~"), axlGetVariable("TEMP"))
    (getTempDir() && !index(getTempDir(), "~"), getTempDir())
    (axlVersion('isWindows) && isDir("c:\\temp"), "c:\\temp")
    (axlVersion('isWindows) && createDir("c:\\temp"), "c:\\temp")
    (!axlVersion('isWindows) && isDir("/tmp"), "/tmp")
    (t, ".")
  )
  axlDMOpenFile("FORM", if(tempFolder && isDir(tempFolder), strcat(tempFolder "/", name), name), "w")
))

;Create HEADER lines on a form:
defun( logoMaker_formHeader (port @optional (formWidth 36), (title "My Form"), options)
  when(listp(options), options = buildString(options))
  fprintf(port, "FILE_TYPE=FORM_DEFN VERSION=2\nFORM %s\nFIXED\nPORT %d 10\n", options, formWidth)
  fprintf(port, "HEADER \"%s\"\n", title)
  fprintf(port, "TILE\n")
)

defun( AFn_formEnd (port), fprintf(port, "ENDTILE\nENDFORM\n"), drain(port))

defun( logoMaker_formPopupDefine (port, popupName @optional (popPairs '("")))
 let((pair, (popPairsStr ""), tdisplay, tdispatch, (chCount 0))
  fprintf(port, "POPUP <%s> ", popupName)
  while(popPairs && chCount < 6000
    pair = car(popPairs), popPairs = cdr(popPairs)
    if(listp(pair) then tdisplay = car(pair), tdispatch = cadr(pair) else tdisplay = tdispatch = pair) 
    when(numberp(tdisplay), sprintf(tdisplay, "%d", tdisplay))
    when(numberp(tdispatch), sprintf(tdispatch, "%d", tdispatch))
    sprintf(popPairsStr, "%s \"%s\" \"%s\"", popPairsStr, tdisplay, tdispatch)
    chCount = chCount + strlen(popPairsStr)
    when(popPairs && chCount < 6000, sprintf(popPairsStr, "%s%s", popPairsStr, ","))
    when(strlen(popPairsStr) > 60 && popPairs
      fprintf(port, "%s\\\n", popPairsStr)
      popPairsStr = ""
    )
  )
  fprintf(port, "%s.\n", popPairsStr)
))

defun( AFn_formMessage (port, msgLabel @key (level 0), (msgString "%s"))
  sprintf(level, " %d", level)
  msgString = strcat(" \"", msgString, "\"")
  fprintf(port, "MESSAGE %s%s%s\n", msgLabel, level, msgString)
)

;Create a Group on a form:
defun( AFn_formGroup (port, displayTxt, x, lineNo, w, h @key (label "") infoLabel)
  unless(label == "", label = strcat(" ", label))
  infoLabel = AFn_formOptionalString("INFO", infoLabel)
  fprintf(port, "GROUP \"%s\"%s\n\tFLOC %d %d\n\tFSIZE %d %d\n%sENDGROUP\n", displayTxt, label, x, lineNo, w, h, infoLabel)
)

;Create a TEXT line on a form:
defun( AFn_formText (port, txt, x, lineNo @key info, fsize, options (label ""))
  info = AFn_formOptionalString("INFO", info)
  fsize = AFn_formSizeString(fsize)
  options = AFn_formOptionsString(options)
  fprintf(port, "TEXT \"%s\" %s\n\tTLOC %d %d\n%s%s%sENDTEXT\n", txt, label, x, lineNo, info, fsize, options)
)

;Create a Button on a form:
defun( AFn_formButton (port, label, txt, x, lineNo, w, h @key fsize, options, pop)
  fsize = AFn_formSizeString(fsize)
  options = AFn_formOptionsString(options)
  pop = AFn_formOptionalString("POP", pop)
  fprintf(port, "FIELD %s\n\tFLOC %d %d\n%s\tMENUBUTTON \"%s\" %d %d\n%s%sENDFIELD\n", label, x, lineNo, fsize, txt, w, h, options, pop)
)

;Create a Checklist item on a form:
defun( AFn_formChecklistItem (port, label, x, lineNo, displayTxt @key (radioLabel ""))
  unless(radioLabel == "", radioLabel = strcat(" \"", radioLabel, "\""))
  fprintf(port, "FIELD %s\n\tFLOC %d %d\n\tCHECKLIST \"%s\"%s\nENDFIELD\n", label, x, lineNo, displayTxt, radioLabel)
)

;Create a STRFILLIN line on a form. A title is optional:
defun( AFn_formStrFillin (port, label, fillinWidth, fillinLength, x1, lineNo
    @key, title, x2, titleLabel pop, fsize, options, infoOnly, (value ""))
  if(title then
    x2 = x2 || strlen(title) + x1 - 2
    AFn_formText(port, title, x1, lineNo ?label titleLabel || strcat(label, "_title"))
   else x2 = x1
  )
  pop = AFn_formOptionalString("POP", pop)
  infoOnly = AFn_formOptionalString("INFO_ONLY", infoOnly)
  fsize = AFn_formSizeString(fsize)
  unless(value == "", sprintf(value, "\tVALUE \"%s\"\n", value))
  options = AFn_formOptionsString(options)
  fprintf(port, "FIELD %s\n\tFLOC %d %d\n\tSTRFILLIN %d %d\n%s%s%s%s%sENDFIELD\n"
    label, x2, lineNo, fillinWidth, fillinLength, fsize, value, options, pop, infoOnly)
)

;Create a REALFILLIN line on a form. A title is optional:
defun( AFn_formRealFillin (port, label, fillinWidth, fillinLength, x1, lineNo
  @key title, fillInX, titleLabel, minVal, maxVal, value, decimalPlaces, dp, pop, units, options, infoOnly)
  if(title then
    fillInX = fillInX || strlen(title) + x1 - 2
    AFn_formText(port, title, x1, lineNo, ?label titleLabel || strcat(label, "_title"))
   else fillInX = x1
  )
  if(minVal then sprintf(minVal, "\tMIN %L\n", minVal) else minVal = "")
  if(maxVal then sprintf(maxVal, "\tMAX %L\n", maxVal) else maxVal = "")
  if(value then sprintf(value, "\tVALUE %L\n", value) else value = "")
  infoOnly = AFn_formOptionalString("INFO_ONLY", infoOnly); if(infoOnly, "\tINFO_ONLY\n", "")
  sprintf(decimalPlaces, "\tDECIMAL %d\n", decimalPlaces || dp || cadr(axlDBGetDesignUnits()))
  pop = AFn_formOptionalString("POP", pop)
  options = AFn_formOptionsString(options)
  fprintf(port, "FIELD %s\n\tFLOC %d %d\n\tREALFILLIN %d %d\n%s%s%s%s%s%s%sENDFIELD\n",
    label, fillInX, lineNo, fillinWidth, fillinLength, options, minVal, maxVal, value, decimalPlaces, pop, infoOnly)
  when(units
    AFn_formText(port, units, fillInX + fillinWidth + if(pop == "", 2, 5), lineNo, ?label strcat(label, "Units"))
  )
)

;Create an LONGFILLIN line on a form that only accepts integers. A title is optional:
defun( AFn_formIntegerFillin (port, label, fillinWidth, fillinLength, x1, lineNo
    @key title, fillInX, titleLabel, minVal, maxVal, value, pop, units, options, infoOnly)
  if(title then
    fillInX = fillInX || strlen(title) + x1 - 2
    AFn_formText(port, title, x1, lineNo ?label titleLabel || strcat(label, "_title"))
   else fillInX = x1
  )
  if(minVal then sprintf(minVal, "\tMIN %L\n", minVal) else minVal = "")
  if(maxVal then sprintf(maxVal, "\tMAX %L\n", maxVal) else maxVal = "")
  if(value then sprintf(value, "\tVALUE %L\n", value) else value = "")
  infoOnly = AFn_formOptionalString("INFO_ONLY", infoOnly); infoOnly = if(infoOnly, "\tINFO_ONLY\n", "")
  pop = AFn_formOptionalString("POP", pop)
  options = AFn_formOptionsString(options)
  fprintf(port, "FIELD %s\n\tFLOC %d %d\n\tLONGFILLIN %d %d\n%s%s%s%s%s%sENDFIELD\n"
    label, fillInX, lineNo, fillinWidth, fillinLength, options, minVal, maxVal, value, pop, infoOnly)
  when(units
    AFn_formText(port, units, fillInX + fillinWidth + if(pop == "", 2, 5), lineNo, ?label strcat(label, "Units"))
  )
)

;Create a Coloured box on a form:
defun( AFn_formColor (port, label, x, lineNo, w, h)
  fprintf(port, "FIELD %s\n\tFLOC %d %d\n\tCOLOR %d %d\nENDFIELD\n", label, x, lineNo, w, h)
)

;Create a Popup on a form:
defun( AFn_formPop (port, label, popDef, titlex, lineNo, enumset @key title, x2, titleLabel, units, options)
  if(title then
    x2 = x2 || titlex + round(strlen(title) * 0.8)
    AFn_formText(port, title, titlex, lineNo ?label titleLabel || strcat(label, "_title"))
   else x2 = titlex)
  options = AFn_formOptionsString(options)
  fprintf(port, "FIELD %s\n\tFLOC %d %d\n\tENUMSET %d\n\tPOP \"%s\"\n%sENDFIELD\n", label, x2, lineNo, enumset, popDef, options)
  when(units, AFn_formText(port, units, x2 + enumset + 3, lineNo, ?label strcat(label, "Units")))
)

;Create a Thumbnail on a form:
defun( AFn_formThumbnail (port, label, x, lineNo, w, h @key (bitmap "") options)
 let(((fieldName "THUMBNAIL"))
  unless(bitmap == "", sprintf(fieldName, "THUMBNAIL %s", bitmap))
  options = AFn_formOptionsString(options)
  fprintf(port, "FIELD %s\n\t%s\n\tFLOC %d %d\n\tFSIZE %d %d\n%sENDFIELD\n", label, fieldName, x, lineNo, w, h, options)
))

defun( AFn_formIntSlideBar (port, label, fillinWidth, fillinLength, x1, lineNo, minVal, maxVal
    @key title, fillInX, titleLabel, value, units)
  if(title then
    fillInX = fillInX || strlen(title) + x1 - 2
    AFn_formText(port, title, x1, lineNo ?label titleLabel || strcat(label, "_title"))
   else fillInX = x1
  )
  if(value then sprintf(value, "\tVALUE %L\n", value) else value = "")
  fprintf(port, "FIELD %s\n\tFLOC %d %d\n\tINTSLIDEBAR %d %d\n\tMIN %d\n\tMAX %d\n%sENDFIELD\n"
    label, fillInX, lineNo, fillinWidth, fillinLength, minVal, maxVal, value)
  when(units, AFn_formText(port, units, fillInX + fillinWidth + 5, lineNo, ?label strcat(label, "Units")))
)

/****************************************************************/

defun( AFn_formSetLayerSubColour (form, field, layer)
  axlFormSetField(form, field, if(axlIsLayer(layer) && axlIsVisibleLayer(layer), axlLayerGet(layer) ->color, 'black))
  axlFormSetField(form, field, axlIsVisibleLayer(layer))
)

/****************************************************************/
/*		Form String creation functions			*/
/****************************************************************/

defun( AFn_formOptionsString (options)
  when(listp(options), options = buildString(options, " "))
  unless(options == "", options = strcat("\tOPTIONS ", options, "\n"))
  options
)

defun( AFn_formSizeString (fsize)
  cond(
    ((fsize == "") || !fsize, "")
    (listp(fsize), sprintf(nil, "\tFSIZE %d %d\n", car(fsize), cadr(fsize)))
    (t, sprintf(nil, "\tFSIZE %s\n", fsize))
  )
)

defun( AFn_formOptionalString (fieldName, value)
  cond(
    (stringp(value), sprintf(nil, "\t%s %s\n", fieldName, value))
    (value, sprintf(nil, "\t%s\n", fieldName))
    (t, "")
  )
)