;Written by Leon Lee. 2006/02/22
;Modified By Jonathan Dumaresq. 2008/07/17
; Use the new API for 16.x
; Extract XSection
; Copper Layer, interlayer and thinkness of it.
; USE at your own risk. This is my first skill program.
; to use it, Juste type XSection2 in your skill windows. 

axlCmdRegister( "XSection2" `XSection2 ?cmdType "interactive")

defun( XSection2 ()
  stack_layer="MANUFACTURING/STACKUP_FIGURE"
  axlClearSelSet()
  Display=axlVisibleGet()
  axlVisibleDesign(nil)
  axlVisibleLayer(stack_layer t)
  axlDBRefreshId(axlDBGetDesign())
  axlSetFindFilter(?enabled '(noall shapes text) ?onButtons '(noall shapes text))
  axlDeleteObject(axlGetSelSet(axlAddSelectAll()))
  axlVisibleSet(Display)
;  axlShell("redisplay")
l_layer=axlGetXSection()
nbLayer = length(l_layer)
printf("nombre de couche: %d\n" nbLayer)
;printf("%L" l_layer)

l_DBUnits = axlDBGetDesignUnits()
Unit=nth(0 l_DBUnits)
case(Unit
	("millimeters" u=1)
	("mils" u=40)
	("inches" u=0.04)
	("microns" u=1000)
	("centimeters" u=0.1)
);end case
L=66*u	
H=-1*(5+nbLayer*4)*u
s_Accuracy = nth(1 l_DBUnits)

nLayer=nil
declare( layer[nbLayer])
arrayp(layer)
for(lay 0 nbLayer-1 layer[lay]=car( nth( lay l_layer))
	nLayer=append(nLayer list(lay+1 layer[lay]))
	printf("%d  %s \n" lay+1 layer[lay])
	axlClearDynamics()
	mypath = axlPathStart(list( 0:0 L:0 L:H 0:H 0:0))
	axlAddSimpleMoveDynamics(0:0 mypath "path" ?ref_point 0:0)
);for

printf("Enter a point to place the X-Section Figure...\n")

if(axlIsLayer(stack_layer)==nil then
	axlLayerCreateNonConductor(stack_layer)
);if
(axlUIWRedraw nil)
axlVisibleLayer(stack_layer t)

pointStart=nil
declare( point[nbLayer])
declare( bBox[nbLayer])
declare( layerName[nbLayer])

pointStart=axlEnterPoint()
Px=xCoord(pointStart)
Py=yCoord(pointStart)

totalThickness = 0;
for(p 1 nbLayer-2
	if(car( nth( p l_layer)) == "" then
		point[p]=list(Px+37*u Py-(p+2)*4*u)
		bBox[p]=list(list(Px+10*u Py-(p+2.5)*4*u) list(Px+35*u Py-(p+2)*4*u+4.2*u))
		axlDBCreateRectangle(bBox[p], nil, stack_layer)
		f_Thickness = ConvertValue(atof(nth(3 nth( p l_layer))) Unit)
		s_Temp = FormatValue(f_Thickness s_Accuracy Unit)
		layerName[p] = strcat( nth(1 nth( p l_layer)) " (" s_Temp ")") 
		myorient=make_axlTextOrientation(?textBlock "4",?rotation 0., ?mirrored nil, ?justify "left")
		axlDBCreateText(layerName[p], point[p], myorient, stack_layer,nil)
	else	
		point[p]=list(Px+45*u Py-(p+2)*4*u)
		bBox[p]=list(list(Px+5*u Py-(p+1.9)*4*u) list(Px+40*u Py-(p+1.9)*4*u+1.5*u))
		axlDBCreateRectangle(bBox[p], t, stack_layer)
		f_Thickness = ConvertValue(atof(nth(3 nth( p l_layer))) Unit)
		s_Temp = FormatValue(f_Thickness s_Accuracy Unit)
		layerName[p]= strcat( car( nth( p l_layer)) " (" s_Temp ")") 
	);if
	myorient=make_axlTextOrientation(?textBlock "4",?rotation 0., ?mirrored nil, ?justify "left")
	axlDBCreateText(layerName[p], point[p], myorient, stack_layer,nil)
	totalThickness = totalThickness + f_Thickness
);for
	printf("total thickness = %s\n" FormatValue(totalThickness s_Accuracy Unit))
	axlDBCreateText("STACK_UP:",list(Px+3*u Py-4*u), myorient, stack_layer,nil)
	axlDBCreateRectangle(list(list(Px Py) list(Px+100*u yCoord(point[nbLayer-2])-5*u)), nil, stack_layer)
sTotalThickness = FormatValue(totalThickness s_Accuracy Unit)
	axlDBCreateText(strcat("Total Thickness: " sTotalThickness ),list(Px+3*u Py-4*u*(nbLayer+1)), myorient, stack_layer,nil)
);defun
;
; Format a value to string with user Accuracy
defun( FormatValue ( f Accuracy sUnit)
case(Accuracy
	("0" sprintf( nil "%.0f %s" f sUnit) )
	("1" sprintf( nil "%.1f %s" f sUnit) )
	("2" sprintf( nil "%.2f %s" f sUnit) )
	("3" sprintf( nil "%.3f %s" f sUnit) )
	("4" sprintf( nil "%.4f %s" f sUnit) )
	("5" sprintf( nil "%.5f %s" f sUnit) )
	("6" sprintf( nil "%.6f %s" f sUnit) )
	(0 sprintf( nil "%.0f %s" f sUnit) )
	(1 sprintf( nil "%.1f %s" f sUnit) )
	(2 sprintf( nil "%.2f %s" f sUnit) )
	(3 sprintf( nil "%.3f %s" f sUnit) )
	(4 sprintf( nil "%.4f %s" f sUnit) )
	(5 sprintf( nil "%.5f %s" f sUnit) )
	(6 sprintf( nil "%.6f %s" f sUnit) )
);end case
);defun
; Convert the thickness from default, mils, to user units
defun( ConvertValue ( f sUnit)
case(sUnit
	("millimeters" f/39.37)
	("mils" f/1)
	("inches" f/1000)
	("microns" f/39370)
	("centimeters" f/393.7)
);end case
);defun
