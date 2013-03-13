   ;			artwork setup Designators           
;	  	-------------------------------------------  
                                                             
;File name: dsy_extract.il                                 
;Revision:0	                                             
;date:05/29/2002                                             
;Writen by: daishiyan/22863                                  
;tel: 6540572                                                
;e_mail: daishiyan@huawei.com                                
                                                             
;This routine allowes the user to delete dangline .          
                                                             

;==================================================================
;			Main Function
;==================================================================
axlCmdRegister("artwork setup" '_DSY_Extract)
defun( _DSY_Extract ()
    Extract_Form_Ptr  = nil
    Extract_Form_Data = nil
         when(axlOKToProceed()
           when(  _DSY_Extract_Creatform()
                  _DSY_Extract_Displayform()
               );end-when
         );end-when
);end-defun _DSY_Extract 
;==================================================================
;                  _DSY_Extract_Creatform
;==================================================================
(defun _DSY_Extract_Creatform ()
prog( ()
    form_file = outfile("extract.form")
    fprintf( form_file "FILE_TYPE = FORM_DEFN VERSION=2      \n")
    fprintf( form_file "FORM                                 \n") 
    fprintf( form_file "FIXED                                \n")
    fprintf( form_file "PORT 52 50                           \n")
    fprintf( form_file "HEADER \"Parameter Extractor\"       \n")
    fprintf( form_file "TILE                                 \n")
    fprintf( form_file "POPUP <pcb_type> \"General\"\"General\",\"RF\" \"RF\",\"HDI\" \"HDI\",\"Mother\" \"Mother\".  \n")
    fprintf( form_file "TEXT \"Board name:\"                 \n")
    fprintf( form_file "TLOC 3 1                             \n")
    fprintf( form_file "ENDTEXT                              \n")
    fprintf( form_file "FIELD b_name                      \n")
    fprintf( form_file "FLOC 12 1                            \n")
    fprintf( form_file "STRFILLIN 16 28                      \n")
    fprintf( form_file "ENDFIELD                             \n")
    fprintf( form_file "TEXT \"Spell Mode:\"                 \n")
    fprintf( form_file "TLOC 3 4                             \n")
    fprintf( form_file "ENDTEXT                              \n")
    fprintf( form_file "FIELD spellmode                      \n")
    fprintf( form_file "FLOC 12 4                            \n")
    fprintf( form_file "STRFILLIN 10 10                      \n")
    fprintf( form_file "ENDFIELD                             \n")
    fprintf( form_file "TEXT \"PCB Type\"                    \n")
    fprintf( form_file "TLOC 28 4                            \n")
    fprintf( form_file "ENDTEXT                              \n")
    fprintf( form_file "FIELD pcbtype                        \n")
    fprintf( form_file "FLOC 36 4                            \n")
    fprintf( form_file "ENUMSET 12                           \n")
    fprintf( form_file "POP  \"pcb_type\"                    \n")
    fprintf( form_file "ENDFIELD                             \n")
    fprintf( form_file "GROUP \"CAM:\"                       \n")
    fprintf( form_file "FLOC 2 6                             \n")
    fprintf( form_file "FSIZE 22 24                          \n")
    fprintf( form_file "INFO group                           \n")
    fprintf( form_file "ENDGROUP                             \n")
    fprintf( form_file "FIELD cam                            \n")
    fprintf( form_file "FLOC 4 9                             \n")
    fprintf( form_file "LIST \"\" 18 11                      \n")
    ;fprintf( form_file "OPTIONS sort                         \n")
    fprintf( form_file "ENDFIELD                             \n")
    fprintf( form_file "GROUP \"CLP:\"                       \n")
    fprintf( form_file "FLOC 26 6                            \n")
    fprintf( form_file "FSIZE 26 24                          \n")
    fprintf( form_file "INFO group                           \n")
    fprintf( form_file "ENDGROUP                             \n")
    fprintf( form_file "FIELD subdrawing                     \n")
    fprintf( form_file "FLOC 28 9                            \n")
    fprintf( form_file "LIST \"\" 22 11                      \n")
    ;fprintf( form_file "OPTIONS sort                         \n")
    fprintf( form_file "ENDFIELD                             \n")
    fprintf( form_file "FIELD run                            \n")
    fprintf( form_file "FLOC 8 32                            \n")
    fprintf( form_file "MENUBUTTON \"Run\" 7 3               \n")
    fprintf( form_file "ENDFIELD                             \n")
    fprintf( form_file "FIELD del                            \n")
    fprintf( form_file "FLOC 22 32                           \n")
    fprintf( form_file "MENUBUTTON \"Delete\" 5 3            \n")
    fprintf( form_file "ENDFIELD                             \n")
    fprintf( form_file "FIELD exit                         \n")
    fprintf( form_file "FLOC 40 32                           \n")
    fprintf( form_file "MENUBUTTON \"Exit\" 5 3              \n")
    fprintf( form_file "ENDFIELD                             \n")
    fprintf( form_file "ENDTILE                              \n")
    fprintf( form_file "ENDFORM                              \n")
    close( form_file )
       if( isFile("extract.form") 
          then
            return( t )
          else
            axlMsgPut("ERROR 01: Unable to Open .form file")
            return( nil )
          );end-if
));end_defun  _DSY_Extract_Creatform         
;==================================================================
;			_DSY_Extract_Displayform()
;==================================================================
defun( _DSY_Extract_Displayform ()
prog( ()
let( ( form )
     form = axlFormCreate( (gensym) "extract.form" '(se outer) '_DSY_Extract_CallBack t)
     Extract_Form_Ptr = form
     if((Extract_Form_Data == nil) then
         setq( Extract_Form_Data t)
         sprintf(b_name "%s." upperCase(axlCurrentDesign()))
         spellmode = strcat("")
         pcbtype = strcat("General")
         axlFormSetField( form "b_name" b_name)
         ;putprop( Extract_Form_Data b_name 'b_name)
         axlFormSetField( form "spellmode" spellmode)
         axlFormSetField( form "pcbtype" pcbtype)
        ;--------------------------------------
         camgh_initlist = list("gh--adt" "gh--adb" "gh--silktop" "gh--silkbotm" "gh--pasttop" "gh--pastbotm" "gh--soldtop" "gh--soldbotm" "gh--drill")
         ;displayerlist=nil
         camgh_dislist=camgh_initlist
         displayerlist=_DSY_Extract_Changname()
         camdis_list=append( displayerlist camgh_dislist)
         axlFormSetField( form "cam" camdis_list)
        ;--------------------------------------
         
         clpgh_initlist=nil
         sprintf(ghctemp "%s SILKSCREEN TOP" upperCase(b_name))
         clpgh_initlist = cons(ghctemp clpgh_initlist)
         
         sprintf(ghctemp "%s SILKSCREEN BOTTOM" upperCase(b_name))
         clpgh_initlist = cons(ghctemp clpgh_initlist)
         
         sprintf(ghctemp "%s PASTEMASK TOP" upperCase(b_name))
         clpgh_initlist = cons(ghctemp clpgh_initlist)
         
         sprintf(ghctemp "%s PASTEMASK BOTTOM" upperCase(b_name))
         clpgh_initlist = cons(ghctemp clpgh_initlist)
         
         sprintf(ghctemp "%s SOLDMASK TOP" upperCase(b_name))
         clpgh_initlist = cons(ghctemp clpgh_initlist)
         
         sprintf(ghctemp "%s SOLDMASK BOTTOM" upperCase(b_name))
         clpgh_initlist = cons(ghctemp clpgh_initlist)
         
         sprintf(ghctemp "%s DRILL CHART" upperCase(b_name))
         clpgh_initlist = cons(ghctemp clpgh_initlist)
         clpdis_list=_DSY_Extract_DisCLP(camgh_initlist)
         axlFormSetField( form "subdrawing" clpdis_list)
         axlFormDisplay( form )
       );end-if
   );end-let
));end-defun _DSY_Extract_Displayform
;==================================================================
;			 _DSY_Extract_CallBack();------------clpdis_list/camdis_list/camgh_dislist是全局变量
;==================================================================
defun( _DSY_Extract_CallBack (form)
prog( ()
    case( form->curField
         ("b_name"	
            b_name = form->curValue
            axlFormListDeleteAll(form "subdrawing")
            clpdis_list=_DSY_Extract_DisCLP(camgh_initlist)
            axlFormSetField( form "subdrawing" clpdis_list)
            axlFormSetField(form "subdrawing" nil)
         t)   
         ("spellmode"
            spellmode = form->curValue
            axlFormListDeleteAll(form "subdrawing")
            clpdis_list=_DSY_Extract_DisCLP(camgh_dislist)
            axlFormSetField( form "subdrawing" clpdis_list)
            axlFormSetField(form "subdrawing" nil)
         t)   
         ("pcbtype"
            pcbtype = form->curValue
         t)   
         ("subdrawing"
            subdrawing = form->curValue
         t)   
         ("cam"
            cam = form->curValue
         t)
         ("run"	
            _DSY_Extract_Creatcam(camgh_dislist)
            _DSY_Extract_Creatclp(camgh_dislist)
         t)            
        ("del"
            del = form->curValue
            axlFormListDeleteAll(form "cam")
            camgh_listtemp=camgh_dislist
            if(cam=="gh--adt" then
               camgh_listtemp=remove(cam camgh_listtemp)
               );end_if
            if(cam=="gh--adb" then
               camgh_listtemp=remove(cam camgh_listtemp)
               );end_if
            if(cam=="gh--silktop" then
               camgh_listtemp=remove(cam camgh_listtemp)
               );end_if
            if(cam=="gh--silkbotm" then
               camgh_listtemp=remove(cam camgh_listtemp)
               );end_if
            if(cam=="gh--pasttop" then
               camgh_listtemp=remove(cam camgh_listtemp)
               );end_if
            if(cam=="gh--pastbotm" then
               camgh_listtemp=remove(cam camgh_listtemp)
               );end_if
            camgh_dislist=camgh_listtemp
            camdis_list=append( displayerlist camgh_dislist)
            axlFormSetField( form "cam" camdis_list)
            axlFormSetField(form "cam" nil)

            axlFormListDeleteAll(form "subdrawing")
            clpdis_list=_DSY_Extract_DisCLP(camgh_dislist)
            axlFormSetField( form "subdrawing" clpdis_list)
            axlFormSetField(form "subdrawing" nil)
            
         t)   
        ("exit" 
            _DSY_Extract_Cancel() 
         nil)   
	);end-case
    );end_prog	
);end-defunction _SL_State_CallBack()
;==================================================================
;			 _DSY_Extract_Cancel()
;==========================================================================
defun( _DSY_Extract_Cancel ()
        when( isFile( "extract.form" )  deleteFile("extract.form"))
        when( Extract_Form_Ptr axlFormClose( Extract_Form_Ptr ))
        axlClearSelSet()
        axlCancelEnterFun()
);end-defun _DSY_Extract_Cancel
;====================================================================================
                      ;_DSY_Extract_Changname()--------dislayer_list
;====================================================================================
(defun _DSY_Extract_Changname ()
prog( ()  
   _DSY_layername=nil
   _DSY_layername=axlGetParam("paramLayerGroup:etch")->groupMembers
   i=0
   dislayer_listtemp=nil
   dislayer_list=nil
   foreach(dislayer _DSY_layername
           case(car(parseString(dislayer ""))
                  ("T"
                   i=i+1
                   sprintf(dis_layer "01--%s",dislayer)
                   dislayer_listtemp=cons(dis_layer dislayer_listtemp)
                  t)
                  ("A"
                   i=i+1
                   if(i<10
                      then
                        sprintf(dis_layer "0%d--%s",i,dislayer)
                        dislayer_listtemp=cons(dis_layer dislayer_listtemp)
                      else
                        sprintf(dis_layer "%d--%s",i,dislayer)
                        dislayer_listtemp=cons(dis_layer dislayer_listtemp)
                     );end_if
                  t)
                  ("P"
                   i=i+1
                   if(i<10
                      then
                        sprintf(dis_layer "0%d--%s",i,dislayer)
                        dislayer_listtemp=cons(dis_layer dislayer_listtemp)
                      else
                        sprintf(dis_layer "%d--%s",i,dislayer)
                        dislayer_listtemp=cons(dis_layer dislayer_listtemp)
                     );end_if
                  t)         
                  ("G"
                   i=i+1
                   if(i<10
                      then
                        sprintf(dis_layer "0%d--%s",i,dislayer)
                        dislayer_listtemp=cons(dis_layer dislayer_listtemp)
                      else
                        sprintf(dis_layer "%d--%s",i,dislayer)
                        dislayer_listtemp=cons(dis_layer dislayer_listtemp)
                     );end_if
                  t)         
                  ("B"
                   i++
                   if(i<10
                      then
                        sprintf(dis_layer "0%d--%s",i,dislayer)
                        dislayer_listtemp=cons(dis_layer dislayer_listtemp)
                      else
                        sprintf(dis_layer "%d--%s",i,dislayer)
                        dislayer_listtemp=cons(dis_layer dislayer_listtemp)
                     );end_if
                  t)   
                );end_case
           );end_foreach
           dislayer_list=reverse(dislayer_listtemp)
           return(dislayer_list)
));end_defun _DSY_Extract_Changname
;====================================================================                                                                               
               ;_DSY_Extract_DisCLP (nGhlist) 
               ;nGhlist指camgh_list里的内容，以判断clpgh_list应有的内容
               ;该函数返回一个list---nClplist
;====================================================================                                                                               
(defun _DSY_Extract_DisCLP (nGhlist)
prog( ()
   _DSY_layername=nil
   _DSY_layername=axlGetParam("paramLayerGroup:etch")->groupMembers
   i=0 
   routelisttemp=nil
   dimenlisttemp=nil
   foreach(everylayer _DSY_layername 
           i=i+1
           when(car(parseString(everylayer ""))=="T"
                sprintf(disclp "%s ARTWORK TOP",upperCase(b_name))
                sprintf(dimen "%d--ARTWORK TOP",i)
                routelisttemp=cons(disclp routelisttemp)
                dimenlisttemp=cons(dimen dimenlisttemp)
              );end_when
           when(car(parseString(everylayer ""))=="A"
                if(i<10
                   then 
                      sprintf(disclp "%s ARTWORK LAYER0%d",upperCase(b_name),i)
                      sprintf(dimen "%d--ARTWORK LAYER0%d",i,i)
                   else
                      sprintf(disclp "%s ARTWORK LAYER%d",upperCase(b_name),i)
                      sprintf(dimen "%d--ARTWORK LAYER%d",i,i)
                  );end_if
                routelisttemp=cons(disclp routelisttemp)
                dimenlisttemp=cons(dimen dimenlisttemp)
              );end_when    
           when(car(parseString(everylayer ""))=="P"
                if(i<10
                   then 
                      sprintf(disclp "%s POWER PLANE0%d",upperCase(b_name),i)
                      sprintf(dimen "%d--POWER PLANE0%d",i,i)
                   else
                      sprintf(disclp "%s POWER PLANE%d",upperCase(b_name),i)
                      sprintf(dimen "%d--POWER PLANE%d",i,i)
                  );end_if
                routelisttemp=cons(disclp routelisttemp)
                dimenlisttemp=cons(dimen dimenlisttemp)
              );end_when
           when(car(parseString(everylayer ""))=="G"
                if(i<10
                   then 
                      sprintf(disclp "%s GROUND PLANE0%d",upperCase(b_name),i)
                      sprintf(dimen "%d--GROUND PLANE0%d",i,i)
                   else
                      sprintf(disclp "%s GROUND PLANE%d",upperCase(b_name),i)
                      sprintf(dimen "%d--GROUND PLANE%d",i,i)
                  );end_if
                routelisttemp=cons(disclp routelisttemp)
                dimenlisttemp=cons(dimen dimenlisttemp)
              );end_when
           when(car(parseString(everylayer ""))=="B"
                sprintf(disclp "%s ARTWORK BOTTOM",upperCase(b_name))
                sprintf(dimen "%d--ARTWORK BOTTOM",i)
                routelisttemp=cons(disclp routelisttemp)
                dimenlisttemp=cons(dimen dimenlisttemp)
              );end_when
           routelist=reverse(routelisttemp)
           dimenlist=reverse(dimenlisttemp)
           );end_foreach 
   if(length(nGhlist) == 9  
      then
         nGhlist=remove("gh--adt" nGhlist)  ;clp中显示时没有adt和adb的丝印层
         nGhlist=remove("gh--adb" nGhlist)  
         nGhlistTemp=nil
         if(spellmode!=""
            then
               sprintf(spell_mode "SPELL MODE: %s(adb)",spellmode)
               nGhlistTemp=cons(spell_mode nGhlistTemp)
               sprintf(spell_mode "SPELL MODE: %s(adt)",spellmode)
               nGhlistTemp=cons(spell_mode nGhlistTemp)
            );end_if 
         nGhlistVTemp=reverse(nGhlist)
         foreach(everygh nGhlistVTemp
                 case(everygh
                     ("gh--silktop"
                       sprintf(everyghTemp "%s SILKSCREEN TOP",upperCase(b_name))
                       nGhlistTemp=cons(everyghTemp nGhlistTemp)
                     t)
                     ("gh--silkbotm"
                        sprintf(everyghTemp "%s SILKSCREEN BOTTOM",upperCase(b_name))
                        nGhlistTemp=cons(everyghTemp nGhlistTemp)
                     t)
                     ("gh--pasttop" 
                        sprintf(everyghTemp "%s PASTEMASK TOP",upperCase(b_name))
                        nGhlistTemp=cons(everyghTemp nGhlistTemp)
                     t)
                     ("gh--pastbotm"
                        sprintf(everyghTemp "%s PASTEMASK BOTTOM",upperCase(b_name))
                        nGhlistTemp=cons(everyghTemp nGhlistTemp)
                     t)
                     ("gh--soldtop" 
                        sprintf(everyghTemp "%s SOLDMASK TOP",upperCase(b_name))
                        nGhlistTemp=cons(everyghTemp nGhlistTemp)
                     t)
                     ("gh--soldbotm"
                        sprintf(everyghTemp "%s SOLDMASK BOTTOM",upperCase(b_name))
                        nGhlistTemp=cons(everyghTemp nGhlistTemp)
                     t)
                     ("gh--drill"
                        sprintf(everyghTemp "%s DRILL CHART",upperCase(b_name))
                        nGhlistTemp=cons(everyghTemp nGhlistTemp)
                     t)
                     );end_case
                 );end_foreach 
         nclplisttemp=append(routelist nGhlistTemp)
         nClplist=append(nclplisttemp dimenlist)
         return(nClplist)
      else
         adt_flag=0
         adb_flag=0
         silktop_flag=0
         silkbotm_flag=0
         pasttop_flag=0
         pastbotm_flag=0
         foreach(ghevery nGhlist  
                 if(nthelem(2 parseString(ghevery "-"))=="adt" then
                    adt_flag=1
                    );end_if adt
                 if(nthelem(2 parseString(ghevery "-"))=="adb" then
                    adb_flag=1
                    );end_if adb
                 if(nthelem(2 parseString(ghevery "-"))=="silktop" then
                    silktop_flag=1
                    );end_if silktop
                 if(nthelem(2 parseString(ghevery "-"))=="silkbotm" then
                    silkbotm_flag=1
                    );end_if silkbotm
                 if(nthelem(2 parseString(ghevery "-"))=="pasttop" then
                    pasttop_flag=1
                    );end_if pasttop
                 if(nthelem(2 parseString(ghevery "-"))=="pastbotm" then
                    pastbotm_flag=1
                    );end_if pastbotm
                 );end_foreach   
         nGhlist=remove("gh--adt" nGhlist)  
         nGhlist=remove("gh--adb" nGhlist)  
         if(silktop_flag==0
           Ghlist=remove("gh--silktop" nGhlist)  
            );end_if
         if(silkbotm_flag==0
            nGhlist=remove("gh--silkbotm" nGhlist)  
            );end_if
         if(pasttop_flag==0
            nGhlist=remove("gh--pasttop" nGhlist)  
            );end_if
         if(pastbotm_flag==0
            nGhlist=remove("gh--pastbotm" nGhlist)  
            );end_if
         nGhlistTemp=nil
         if(adb_flag==1
            then 
               if(spellmode!=""
                  then
                    sprintf(spell_mode "SPELL MODE: %s(adb)",spellmode)
                    nGhlistTemp=cons(spell_mode nGhlistTemp)
                 );end_if 
            );end_if
         if(adt_flag==1 
            then 
               if(spellmode!=""
                  then
                     sprintf(spell_mode "SPELL MODE: %s(adt)",spellmode)
                     nGhlistTemp=cons(spell_mode nGhlistTemp)
                  );end_if
            );end_if
         nGhlistVTemp=reverse(nGhlist)
         foreach(everygh nGhlistVTemp
                 case(everygh
                     ("gh--silktop"
                       sprintf(everyghTemp "%s SILKSCREEN TOP",upperCase(b_name))
                       nGhlistTemp=cons(everyghTemp nGhlistTemp)
                     t)
                     ("gh--silkbotm"
                        sprintf(everyghTemp "%s SILKSCREEN BOTTOM",upperCase(b_name))
                        nGhlistTemp=cons(everyghTemp nGhlistTemp)
                     t)
                     ("gh--pasttop" 
                        sprintf(everyghTemp "%s PASTEMASK TOP",upperCase(b_name))
                        nGhlistTemp=cons(everyghTemp nGhlistTemp)
                     t)
                     ("gh--pastbotm"
                        sprintf(everyghTemp "%s PASTEMASK BOTTOM",upperCase(b_name))
                        nGhlistTemp=cons(everyghTemp nGhlistTemp)
                     t)
                     ("gh--soldtop" 
                        sprintf(everyghTemp "%s SOLDMASK TOP",upperCase(b_name))
                        nGhlistTemp=cons(everyghTemp nGhlistTemp)
                     t)
                     ("gh--soldbotm"
                        sprintf(everyghTemp "%s SOLDMASK BOTTOM",upperCase(b_name))
                        nGhlistTemp=cons(everyghTemp nGhlistTemp)
                     t)
                     ("gh--drill"
                        sprintf(everyghTemp "%s DRILL CHART",upperCase(b_name))
                        nGhlistTemp=cons(everyghTemp nGhlistTemp)
                     t)
                     );end_case
                 );end_foreach 
         nclplisttemp=append(routelist nGhlistTemp)
         nClplist=append(nclplisttemp dimenlist)
         return(nClplist)
     );end_if     
));defun _DSY_Extract_DisCLP
;====================================================================                                                                               
;                    _DSY_Extract_Creatcam(nGhlist)
;====================================================================                                                                               
(defun _DSY_Extract_Creatcam (nGhlist)
prog( ()
let( (layername)
     deleteFile("./cam.txt")
     extrac_accuracy=nthelem(2 axlDBGetDesignUnits())
     if(extrac_accuracy==0||extrac_accuracy==1||extrac_accuracy==2||extrac_accuracy==3 
        then
           case(extrac_accuracy
               (0
               ExtraAccuracy=8
               )
               (1
                ExtraAccuracy=80
               t)
               (2
                ExtraAccuracy=800
               t)
               (3
                ExtraAccuracy=8000
               t)
               );end_case
           layename=nil
           layername=axlGetParam("paramLayerGroup:etch")->groupMembers
           rpt=outfile("./cam.txt")
           i=0
           foreach(eachname layername
              case(car(parseString(eachname ""))
                  ("T"
                   i=i+1
                   fprintf(rpt "(axlfcreate \"art01\" '(0 0 0 %d 0 1 0 0 0 0 0 0 0) '(\"VIA CLASS/TOP\" \"PIN/TOP\" \"ETCH/TOP\" \"BOARD GEOMETRY/OUTLINE\" ))\n",ExtraAccuracy)
                  t)
                  ("B"
                   i=i+1
                   if(i<10
                      then
                        sprintf(camlayer,"%s%d","art0",i)
                        fprintf(rpt "(axlfcreate \"%s\" '(0 0 0 %d 0 1 1 0 0 0 0 0 0) '(\"VIA CLASS/BOTTOM\" \"PIN/BOTTOM\" \"ETCH/BOTTOM\" \"BOARD GEOMETRY/OUTLINE\" ))\n",camlayer,ExtraAccuracy)
                      else                    
                        sprintf(camlayer,"%s%d","art",i)                    
                        fprintf(rpt "(axlfcreate \"%s\" '(0 0 0 %d 0 1 1 0 0 0 0 0 0) '(\"VIA CLASS/BOTTOM\" \"PIN/BOTTOM\" \"ETCH/BOTTOM\" \"BOARD GEOMETRY/OUTLINE\" ))\n",camlayer,ExtraAccuracy)
                     );end_if
                  t)   
                  ("A"
                   i=i+1
                   if(i<10
                      then
                        sprintf(camlayer,"%s%d","art0",i)
                        fprintf(rpt "(axlfcreate \"%s\" '(0 0 0 %d 0 1 0 0 0 0 0 0 0) '(\"VIA CLASS/%s\" \"PIN/%s\" \"ETCH/%s\" \"BOARD GEOMETRY/OUTLINE\" ))\n",camlayer,ExtraAccuracy,eachname,eachname,eachname,eachname)
                      else                                       
                        sprintf(camlayer,"%s%d","art",i)         
                        fprintf(rpt "(axlfcreate \"%s\" '(0 0 0 %d 0 1 0 0 0 0 0 0 0) '(\"VIA CLASS/%s\" \"PIN/%s\" \"ETCH/%s\" \"BOARD GEOMETRY/OUTLINE\" ))\n",camlayer,ExtraAccuracy,eachname,eachname,eachname,eachname)
                     );end_if
                  t)
                  ("P"
                   i=i+1
                   if(i<10
                      then
                        sprintf(camlayer,"%s%d","pgp0",i)
                        fprintf(rpt "(axlfcreate \"%s\" '(0 0 0 %d 0 0 0 0 0 0 0 0 0) '(\"ANTI ETCH/%s\" \"VIA CLASS/%s\" \"PIN/%s\" \"ETCH/%s\" \"BOARD GEOMETRY/OUTLINE\" \"ANTI ETCH/ALL\" ))\n",camlayer,ExtraAccuracy,eachname,eachname,eachname,eachname)
                      else                                       
                        sprintf(camlayer,"%s%d","pgp",i)         
                        fprintf(rpt "(axlfcreate \"%s\" '(0 0 0 %d 0 0 0 0 0 0 0 0 0) '(\"ANTI ETCH/%s\" \"VIA CLASS/%s\" \"PIN/%s\" \"ETCH/%s\" \"BOARD GEOMETRY/OUTLINE\" \"ANTI ETCH/ALL\" ))\n",camlayer,ExtraAccuracy,eachname,eachname,eachname,eachname)
                     );end_if
                  t)         
                  ("G"
                   i=i+1
                   if(i<10
                      then
                        sprintf(camlayer,"%s%d","pgp0",i)
                        fprintf(rpt "(axlfcreate \"%s\" '(0 0 0 %d 0 0 0 0 0 0 0 0 0) '(\"ANTI ETCH/%s\" \"VIA CLASS/%s\" \"PIN/%s\" \"ETCH/%s\" \"BOARD GEOMETRY/OUTLINE\" \"ANTI ETCH/ALL\" ))\n",camlayer,ExtraAccuracy,eachname,eachname,eachname,eachname)
                      else                                       
                        sprintf(camlayer,"%s%d","pgp",i)         
                        fprintf(rpt "(axlfcreate \"%s\" '(0 0 0 %d 0 0 0 0 0 0 0 0 0) '(\"ANTI ETCH/%s\" \"VIA CLASS/%s\" \"PIN/%s\" \"ETCH/%s\" \"BOARD GEOMETRY/OUTLINE\" \"ANTI ETCH/ALL\" ))\n",camlayer,ExtraAccuracy,eachname,eachname,eachname,eachname)
                     );end_if
                  t)         
                );end_case
                );end_foreach   
           adt_flag=0　　　　　　　
           adb_flag=0
           silktop_flag=0
           silkbotm_flag=0
           pasttop_flag=0
           pastbotm_flag=0
           foreach(ghevery nGhlist  
                   if(nthelem(2 parseString(ghevery "-"))=="adt" then
                      adt_flag=1
                      );end_if adt
                   if(nthelem(2 parseString(ghevery "-"))=="adb" then
                      adb_flag=1
                      );end_if adb
                   if(nthelem(2 parseString(ghevery "-"))=="silktop" then
                      silktop_flag=1
                      );end_if silktop
                   if(nthelem(2 parseString(ghevery "-"))=="silkbotm" then
                      silkbotm_flag=1
                      );end_if silkbotm
                   if(nthelem(2 parseString(ghevery "-"))=="pasttop" then
                      pasttop_flag=1
                      );end_if pasttop
                   if(nthelem(2 parseString(ghevery "-"))=="pastbotm" then
                      pastbotm_flag=1
                      );end_if pastbotm
                   );end_foreach   
           if(adt_flag==1 then
                 fprintf(rpt "(axlfcreate \"adt\" '(0 0 0 %d 0 1 0 0 0 0 0 0 0) '(\"REF DES/SILKSCREEN_TOP\" \"PIN/TOP\" \"PACKAGE GEOMETRY/ASSEMBLY_TOP\" \"PACKAGE GEOMETRY/SILKSCREEN_TOP\" \"BOARD GEOMETRY/SILKSCREEN_TOP\" \"BOARD GEOMETRY/OUTLINE\" ))\n",ExtraAccuracy)
             );end_if                                      
           if(adb_flag==1 then                             
                 fprintf(rpt "(axlfcreate \"adb\" '(0 0 0 %d 0 1 1 0 0 0 0 0 0) '(\"REF DES/SILKSCREEN_BOTTOM\" \"PIN/BOTTOM\" \"PACKAGE GEOMETRY/ASSEMBLY_BOTTOM\" \"PACKAGE GEOMETRY/SILKSCREEN_BOTTOM\" \"BOARD GEOMETRY/SILKSCREEN_BOTTOM\" \"BOARD GEOMETRY/OUTLINE\" ))\n",ExtraAccuracy)
             );end_if
           if(silktop_flag==1 then
                 fprintf(rpt "(axlfcreate \"silktop\" '(0 0 0 %d 0 1 0 0 0 0 0 0 0) '(\"REF DES/SILKSCREEN_TOP\" \"PACKAGE GEOMETRY/SILKSCREEN_TOP\" \"BOARD GEOMETRY/SILKSCREEN_TOP\" \"BOARD GEOMETRY/OUTLINE\" ))\n",ExtraAccuracy)
             );end_if
           if(silkbotm_flag==1 then
                 fprintf(rpt "(axlfcreate \"silkbotm\" '(0 0 0 %d 0 1 1 0 0 0 0 0 0) '(\"REF DES/SILKSCREEN_BOTTOM\" \"PACKAGE GEOMETRY/SILKSCREEN_BOTTOM\" \"BOARD GEOMETRY/SILKSCREEN_BOTTOM\" \"BOARD GEOMETRY/OUTLINE\" ))\n",ExtraAccuracy)
             );end_if
           if(pasttop_flag==1 then
                 fprintf(rpt "(axlfcreate \"pasttop\" '(0 0 0 %d 0 1 0 0 0 0 0 0 0) '(\"PIN/PASTEMASK_TOP\" \"PACKAGE GEOMETRY/DISPLAY_TOP\" \"BOARD GEOMETRY/OUTLINE\" ))\n",ExtraAccuracy)
             );end_if
           if(pastbotm_flag==1 then
                 fprintf(rpt "(axlfcreate \"pastbotm\" '(0 0 0 %d 0 1 1 0 0 0 0 0 0) '(\"PIN/PASTEMASK_BOTTOM\" \"PACKAGE GEOMETRY/DISPLAY_BOTTOM\" \"BOARD GEOMETRY/OUTLINE\" ))\n",ExtraAccuracy)
             );end_if
           fprintf(rpt "(axlfcreate \"soldtop\" '(0 0 0 %d 0 1 0 0 0 0 0 0 0) '(\"VIA CLASS/SOLDERMASK_TOP\" \"PIN/SOLDERMASK_TOP\" \"PACKAGE GEOMETRY/SOLDERMASK_TOP\" \"BOARD GEOMETRY/OUTLINE\" \"BOARD GEOMETRY/SOLDERMASK_TOP\" ))\n",ExtraAccuracy)
           fprintf(rpt "(axlfcreate \"soldbotm\" '(0 0 0 %d 0 1 1 0 0 0 0 0 0) '(\"VIA CLASS/SOLDERMASK_BOTTOM\" \"PIN/SOLDERMASK_BOTTOM\" \"PACKAGE GEOMETRY/SOLDERMASK_BOTTOM\" \"BOARD GEOMETRY/OUTLINE\" \"BOARD GEOMETRY/SOLDERMASK_BOTTOM\" ))\n",ExtraAccuracy)
           fprintf(rpt "(axlfcreate \"drill\" '(0 0 0 %d 0 1 0 0 0 0 0 1 1) '(\"MANUFACTURING/NCDRILL_LEGEND\" \"MANUFACTURING/NCDRILL_FIGURE\" \"BOARD GEOMETRY/OUTLINE\" \"BOARD GEOMETRY/DIMENSION\" ))\n",ExtraAccuracy)
           close(rpt) 
      else
        axlMsgPut("Please set accuracy with 0 1 2 3") 
      );end_if
  );end_let   
));end_defun _DSY_Extract_Creatcam 
;====================================================================                                                                               
;                    _DSY_Extract_Creatclp(nGhlist)
;                    ;nGhlist指camgh_list里的内容，以判断应创建哪些光绘层
;==================================================================== 
(defun _DSY_Extract_Creatclp (nGhlist) 
prog( ()
     sprintf(clptxt,"./%s.clp",upperCase(axlCurrentDesign()))
     rpt=outfile(clptxt)
     fprintf(rpt "(setq _clp_lay_drw (axlDesignType nil))                                                             \n")
     fprintf(rpt "(setq _clp_sym nil)                                                                                 \n")
     fprintf(rpt "(setq _clp_pbuf nil)                                                                                \n")
     fprintf(rpt "(setq _clp_cinfo (make_clp_coord_info))                                                             \n")
     fprintf(rpt "(putprop _clp_cinfo 0.0 'f_rotation)                                                                \n")
     fprintf(rpt "(putprop _clp_cinfo '(0.0 0.0) 'l_origin)                                                           \n")
     fprintf(rpt "(setq _clp_text_orient (make_axlTextOrientation))                                                   \n")
     fprintf(rpt "(setq _clp_pin_text (make_axlPinText))                                                              \n")
     fprintf(rpt "(putprop _clp_cinfo  \"mils\" 't_from_units)                                                        \n")
     fprintf(rpt "(putprop _clp_cinfo (car (axlDBGetDesignUnits)) 't_to_units)                                        \n")
     fprintf(rpt "(setq _clp_group_info (make_clp_group_info))                                                        \n")
     fprintf(rpt "(putprop _clp_cinfo _clp_group_info 'group_info)                                                    \n")
     fprintf(rpt "(setq _clp_accuracy 1)                                                                              \n")
     fprintf(rpt "(_clpCheckAccuracy _clp_accuracy (get _clp_cinfo 't_from_units)	 (get _clp_cinfo 't_to_units))\n")
     fprintf(rpt "(putprop _clp_cinfo (list (_clpAdjustPt -2275:-948.3 _clp_cinfo)                                \n")
     fprintf(rpt "	(_clpAdjustPt 2175:600 _clp_cinfo)) 'l_extents)                                         \n")
     fprintf(rpt "(putprop _clp_cinfo (_clpAdjustPt '(12300.0 11600.0) _clp_cinfo) 'l_zeropt)                  \n")
     fprintf(rpt "(unless (_clpSelectRotOrg _clp_cinfo)                                                               \n")
     fprintf(rpt " (error \"CANCEL\"))                                                                                  \n")
     fprintf(rpt " (setq _clp_clip_prop_value (_clpGetClipPropValue))                                                 \n")

     case( pcbtype
         ("General" 
         fprintf(rpt "(_clpInitTextOrientation _clp_text_orient \"LEFT\" nil (get _clp_cinfo 'f_rotation) + 0.000000 \"8\" )  \n")
         fprintf(rpt "(setq _clp_dbid (_clpDBCreateText \"%s\"                                                           \n",upperCase(b_name))
         fprintf(rpt "(_clpAdjustPt 100:300 _clp_cinfo)  _clp_text_orient                                                \n")
         fprintf(rpt "\"PACKAGE GEOMETRY/SILKSCREEN_TOP\" _clp_sym))                                                        \n")
         t)
         ("RF"
         fprintf(rpt "(_clpInitTextOrientation _clp_text_orient \"LEFT\" nil (get _clp_cinfo 'f_rotation) + 0.000000 \"8\" )  \n")
         fprintf(rpt "(setq _clp_dbid (_clpDBCreateText \"%s\"                                                           \n",upperCase(b_name))
         fprintf(rpt "(_clpAdjustPt 100:300 _clp_cinfo)  _clp_text_orient                                                \n")
         fprintf(rpt "\"PACKAGE GEOMETRY/SILKSCREEN_TOP\" _clp_sym))                                                        \n")

         fprintf(rpt "(_clpInitTextOrientation _clp_text_orient \"LEFT\" nil (get _clp_cinfo 'f_rotation) + 0.000000 \"8\" )  \n")
         fprintf(rpt "(setq _clp_dbid (_clpDBCreateText \"RF\"                                                           \n")
         fprintf(rpt "(_clpAdjustPt 700:300 _clp_cinfo)  _clp_text_orient                                                \n")
         fprintf(rpt "\"PACKAGE GEOMETRY/SILKSCREEN_TOP\" _clp_sym))                                                        \n")
         t)
         ("HDI"
         fprintf(rpt "(_clpInitTextOrientation _clp_text_orient \"LEFT\" nil (get _clp_cinfo 'f_rotation) + 0.000000 \"8\" )  \n")
         fprintf(rpt "(setq _clp_dbid (_clpDBCreateText \"%s\"                                                           \n",upperCase(b_name))
         fprintf(rpt "(_clpAdjustPt 100:300 _clp_cinfo)  _clp_text_orient                                                \n")
         fprintf(rpt "\"PACKAGE GEOMETRY/SILKSCREEN_TOP\" _clp_sym))                                                        \n")

         fprintf(rpt "(_clpInitTextOrientation _clp_text_orient \"LEFT\" nil (get _clp_cinfo 'f_rotation) + 0.000000 \"8\" )  \n")
         fprintf(rpt "(setq _clp_dbid (_clpDBCreateText \"HDI\"                                                           \n")
         fprintf(rpt "(_clpAdjustPt 700:300 _clp_cinfo)  _clp_text_orient                                                \n")
         fprintf(rpt "\"PACKAGE GEOMETRY/SILKSCREEN_TOP\" _clp_sym))                                                        \n")

         fprintf(rpt "(_clpInitTextOrientation _clp_text_orient \"LEFT\" nil (get _clp_cinfo 'f_rotation) + 0.000000 \"8\" )  \n")
         fprintf(rpt "(setq _clp_dbid (_clpDBCreateText \"ncdrill1.tap---holes connecting art02 and art03\"         \n")
         fprintf(rpt "(_clpAdjustPt 100:700 _clp_cinfo)  _clp_text_orient                                                 \n")
         fprintf(rpt "\"BOARD GEOMETRY/DIMENSION\" _clp_sym))                                                             \n")                                 
         t)
         ("Mother"
         fprintf(rpt "(_clpInitTextOrientation _clp_text_orient \"LEFT\" nil (get _clp_cinfo 'f_rotation) + 0.000000 \"8\" )  \n")
         fprintf(rpt "(setq _clp_dbid (_clpDBCreateText \"%s F\"                                                           \n",upperCase(b_name))
         fprintf(rpt "(_clpAdjustPt 100:300 _clp_cinfo)  _clp_text_orient                                                \n")
         fprintf(rpt "\"PACKAGE GEOMETRY/SILKSCREEN_TOP\" _clp_sym))                                                        \n")

         fprintf(rpt "(_clpInitTextOrientation _clp_text_orient \"LEFT\" t (get _clp_cinfo 'f_rotation) + 0.000000 \"8\" )  \n")
         fprintf(rpt "(setq _clp_dbid (_clpDBCreateText \"%s B\"                                                           \n",upperCase(b_name))
         fprintf(rpt "(_clpAdjustPt -100:300 _clp_cinfo)  _clp_text_orient                                                \n")
         fprintf(rpt "\"PACKAGE GEOMETRY/SILKSCREEN_BOTTOM\" _clp_sym))                                                        \n")
         t)
         );end_case
     _DSY_layername=nil
     _DSY_layername=axlGetParam("paramLayerGroup:etch")->groupMembers
     i=0 
     j=300
     foreach(everylayer _DSY_layername 
            i=i+1                
             j=j-200
             if(car(parseString(everylayer ""))=="T"
                then 
                   ;fprintf(rpt "(_clpInitTextOrientation _clp_text_orient \"LEFT\" nil (get _clp_cinfo 'f_rotation) + 0.000000 \"8\" )  \n")
                   fprintf(rpt "(_clpInitTextOrientation _clp_text_orient \"LEFT\" nil (get _clp_cinfo 'f_rotation) + 0.000000 \"8\" )  \n")
                   fprintf(rpt "(setq _clp_dbid (_clpDBCreateText \"%s ARTWORK TOP\"                                  \n",upperCase(b_name))
                   fprintf(rpt "(_clpAdjustPt 100:%d _clp_cinfo)  _clp_text_orient                                                   \n",j)
                   fprintf(rpt "\"ETCH/TOP\" _clp_sym))                                                                               \n")
               );end_if
               
             if(car(parseString(everylayer ""))=="A" 
                then 
                  fprintf(rpt "(_clpInitTextOrientation _clp_text_orient \"LEFT\" nil (get _clp_cinfo 'f_rotation) + 0.000000 \"8\" )  \n")
                  if(i<10
                     then 
                       sprintf(camlayer,"%s%d","LAYER0",i)  
                     else
                       sprintf(camlayer,"%s%d","LAYER",i)  
                    );end_if
                  fprintf(rpt "(setq _clp_dbid (_clpDBCreateText \"%s ARTWORK %s\"                                             \n",upperCase(b_name),camlayer)
                   fprintf(rpt "(_clpAdjustPt 100:%d _clp_cinfo)  _clp_text_orient                                                   \n",j)
                  fprintf(rpt "\"ETCH/%s\" _clp_sym))                                                                             \n",everylayer)
                );end_if
                
             if(car(parseString(everylayer ""))=="P"
                then 
                  fprintf(rpt "(_clpInitTextOrientation _clp_text_orient \"LEFT\" nil (get _clp_cinfo 'f_rotation) + 0.000000 \"8\" )  \n")
                  if(i<10
                     then 
                       sprintf(camlayer,"%s%d","PLANE0",i)  
                     else
                       sprintf(camlayer,"%s%d","PLANE",i)  
                    );end_if
                   fprintf(rpt "(setq _clp_dbid (_clpDBCreateText \"%s POWER %s\"                                             \n",upperCase(b_name),camlayer)
                   fprintf(rpt "(_clpAdjustPt 100:%d _clp_cinfo)  _clp_text_orient                                                   \n",j)
                   fprintf(rpt "\"ETCH/%s\" _clp_sym))                                                                           \n",everylayer)
                );end_if
                
             if(car(parseString(everylayer ""))=="G"
                then 
                  fprintf(rpt "(_clpInitTextOrientation _clp_text_orient \"LEFT\" nil (get _clp_cinfo 'f_rotation) + 0.000000 \"8\" )  \n")
                  if(i<10
                     then 
                       sprintf(camlayer,"%s%d","PLANE0",i)  
                     else
                       sprintf(camlayer,"%s%d","PLANE",i)  
                    );end_if
                   fprintf(rpt "(setq _clp_dbid (_clpDBCreateText \"%s GROUND %s\"                                              \n",upperCase(b_name),camlayer)
                   fprintf(rpt "(_clpAdjustPt 100:%d _clp_cinfo)  _clp_text_orient                                                   \n",j)
                   fprintf(rpt "\"ETCH/%s\" _clp_sym))                                                                             \n",everylayer)
                );end_if
                
             if(car(parseString(everylayer ""))=="B" 
                then                
                   fprintf(rpt "(_clpInitTextOrientation _clp_text_orient \"LEFT\" t (get _clp_cinfo 'f_rotation) + 0.000000 \"8\" )  \n")
                   fprintf(rpt "(setq _clp_dbid (_clpDBCreateText \"%s ARTWORK BOTTOM\"                                            \n",upperCase(b_name))
                   fprintf(rpt "(_clpAdjustPt -100:%d _clp_cinfo)  _clp_text_orient                                                   \n",j)
                   fprintf(rpt "\"ETCH/BOTTOM\" _clp_sym))                                                                            \n")
                );end_if
          );end_foreach
     adt_flag=0
     adb_flag=0
     silktop_flag=0
     silkbotm_flag=0
     pasttop_flag=0
     pastbotm_flag=0
     foreach(ghevery nGhlist  
             if(nthelem(2 parseString(ghevery "-"))=="adt" then
                adt_flag=1
                );end_if silktop
             if(nthelem(2 parseString(ghevery "-"))=="adb" then
                adb_flag=1
                );end_if silkbotm
             if(nthelem(2 parseString(ghevery "-"))=="silktop" then
                silktop_flag=1
                );end_if silktop
             if(nthelem(2 parseString(ghevery "-"))=="silkbotm" then
                silkbotm_flag=1
                );end_if silkbotm
             if(nthelem(2 parseString(ghevery "-"))=="pasttop" then
                pasttop_flag=1
                );end_if pasttop
             if(nthelem(2 parseString(ghevery "-"))=="pastbotm" then
                pastbotm_flag=1
                );end_if pastbotm
             );end_foreach   

     j=j-200                               
     fprintf(rpt "(_clpInitTextOrientation _clp_text_orient \"LEFT\" nil (get _clp_cinfo 'f_rotation) + 0.000000 \"8\" )  \n")
     fprintf(rpt "(setq _clp_dbid (_clpDBCreateText \"%s SOLDMASK TOP\"                                              \n",upperCase(b_name))
     fprintf(rpt "(_clpAdjustPt 100:%d _clp_cinfo)  _clp_text_orient                                                 \n",j)
     fprintf(rpt "\"PACKAGE GEOMETRY/SOLDERMASK_TOP\" _clp_sym))                                                        \n")

     fprintf(rpt "(_clpInitTextOrientation _clp_text_orient \"LEFT\" t (get _clp_cinfo 'f_rotation) + 0.000000 \"8\" )    \n")
     fprintf(rpt "(setq _clp_dbid (_clpDBCreateText \"%s SOLDMASK BOTTOM\"                                           \n",upperCase(b_name))
     fprintf(rpt "(_clpAdjustPt -100:%d _clp_cinfo)  _clp_text_orient                                                 \n",j)
     fprintf(rpt "\"PACKAGE GEOMETRY/SOLDERMASK_BOTTOM\" _clp_sym))                                                     \n")

     j=j-200
     if(pasttop_flag==1 then
        fprintf(rpt "(_clpInitTextOrientation _clp_text_orient \"LEFT\" nil (get _clp_cinfo 'f_rotation) + 0.000000 \"8\" )  \n")
        fprintf(rpt "(setq _clp_dbid (_clpDBCreateText \"%s PASTEMASK TOP\"                                             \n",upperCase(b_name))
        fprintf(rpt "(_clpAdjustPt 100:%d _clp_cinfo)  _clp_text_orient                                                 \n",j)
        fprintf(rpt "\"PACKAGE GEOMETRY/DISPLAY_TOP\" _clp_sym))                                                           \n")
        );end_if                                      

     if(pastbotm_flag==1 then
        fprintf(rpt "(_clpInitTextOrientation _clp_text_orient \"LEFT\" t (get _clp_cinfo 'f_rotation) + 0.000000 \"8\" )    \n")
        fprintf(rpt "(setq _clp_dbid (_clpDBCreateText \"%s PASTEMASK BOTTOM\"                                          \n",upperCase(b_name))
        fprintf(rpt "(_clpAdjustPt -100:%d _clp_cinfo)  _clp_text_orient                                                 \n",j)
        fprintf(rpt "\"PACKAGE GEOMETRY/DISPLAY_BOTTOM\" _clp_sym))                                                      \n")
        );end_if                                      

     j=j-200
     if(silktop_flag==1 then
        fprintf(rpt "(_clpInitTextOrientation _clp_text_orient \"LEFT\" nil (get _clp_cinfo 'f_rotation) + 0.000000 \"8\" )  \n")
        fprintf(rpt "(setq _clp_dbid (_clpDBCreateText \"%s SILKSCREEN TOP\"                                            \n",upperCase(b_name))
        fprintf(rpt "(_clpAdjustPt 100:%d _clp_cinfo)  _clp_text_orient                                                 \n",j)
        fprintf(rpt "\"PACKAGE GEOMETRY/SILKSCREEN_TOP\" _clp_sym))                                                        \n")
        );end_if                                      

     if(silkbotm_flag==1 then
        fprintf(rpt "(_clpInitTextOrientation _clp_text_orient \"LEFT\" t (get _clp_cinfo 'f_rotation) + 0.000000 \"8\" )    \n")
        fprintf(rpt "(setq _clp_dbid (_clpDBCreateText \"%s SILKSCREEN BOTTOM\"                                         \n",upperCase(b_name))
        fprintf(rpt "(_clpAdjustPt -100:%d _clp_cinfo)  _clp_text_orient                                                 \n",j)
        fprintf(rpt "\"PACKAGE GEOMETRY/SILKSCREEN_BOTTOM\" _clp_sym))                                                     \n")
        );end_if                                      

     j=j-200
     fprintf(rpt "(_clpInitTextOrientation _clp_text_orient \"LEFT\" nil (get _clp_cinfo 'f_rotation) + 0.000000 \"8\" )  \n")
     fprintf(rpt "(setq _clp_dbid (_clpDBCreateText \"%s DRILL CHART\"                                        \n",upperCase(b_name))
     fprintf(rpt "(_clpAdjustPt 100:%d _clp_cinfo)  _clp_text_orient                                                 \n",j)
     fprintf(rpt "\"BOARD GEOMETRY/DIMENSION\" _clp_sym))                                                             \n")                                 
     
     if(adt_flag==1 then
        if(spellmode!="" then
           fprintf(rpt "(_clpInitTextOrientation _clp_text_orient \"LEFT\" nil (get _clp_cinfo 'f_rotation) + 0.000000 \"8\" )  \n")
           fprintf(rpt "(setq _clp_dbid (_clpDBCreateText \"SPELL MODE: %s \"                                        \n",spellmode)
           fprintf(rpt "(_clpAdjustPt 100:500 _clp_cinfo)  _clp_text_orient                                                 \n")         
           fprintf(rpt "\"PACKAGE GEOMETRY/ASSEMBLY_TOP\" _clp_sym))                                                             \n")                                 
           );end_if 
        );end_if                                                                                                                          
     if(adb_flag==1 then
        if(spellmode!="" then
           fprintf(rpt "(_clpInitTextOrientation _clp_text_orient \"LEFT\" t (get _clp_cinfo 'f_rotation) + 0.000000 \"8\" )  \n")
           fprintf(rpt "(setq _clp_dbid (_clpDBCreateText \"SPELL MODE: %s \"                                        \n",spellmode)
           fprintf(rpt "(_clpAdjustPt -100:500 _clp_cinfo)  _clp_text_orient                                                 \n")         
           fprintf(rpt "\"PACKAGE GEOMETRY/ASSEMBLY_BOTTOM\" _clp_sym))                                                             \n")                                 
           );end_if 
        );end_if                                                                                                                          
     i=0 
     foreach(everylayer _DSY_layername 
             i=i+1
             j=j-200
             fprintf(rpt "(_clpInitTextOrientation _clp_text_orient \"LEFT\" nil (get _clp_cinfo 'f_rotation) + 0.000000 \"8\" )  \n")
             when(car(parseString(everylayer ""))=="T"
                fprintf(rpt "(setq _clp_dbid (_clpDBCreateText \"%d--ARTWORK TOP\"                                                  \n",i)
                );end_when
             when(car(parseString(everylayer ""))=="A"
                  if(i<10
                     then 
                       sprintf(camlayer,"%s%d","LAYER0",i)  
                     else
                       sprintf(camlayer,"%s%d","LAYER",i)  
                    );end_if
                fprintf(rpt "(setq _clp_dbid (_clpDBCreateText \"%d--ARTWORK %s\"                                                  \n",i,camlayer)
                );end_when    
             when(car(parseString(everylayer ""))=="P"
                  if(i<10
                     then 
                       sprintf(camlayer,"%s%d","PLANE0",i)  
                     else
                       sprintf(camlayer,"%s%d","PLANE",i)  
                    );end_if
                   fprintf(rpt "(setq _clp_dbid (_clpDBCreateText \"%d--POWER %s\"                                                  \n",i,camlayer)
                );end_when
             when(car(parseString(everylayer ""))=="G"
                  if(i<10
                     then 
                       sprintf(camlayer,"%s%d","PLANE0",i)  
                     else
                       sprintf(camlayer,"%s%d","PLANE",i)  
                    );end_if
                   fprintf(rpt "(setq _clp_dbid (_clpDBCreateText \"%d--GROUND %s\"                                                  \n",i,camlayer)
                );end_when
             when(car(parseString(everylayer ""))=="B"
                fprintf(rpt "(setq _clp_dbid (_clpDBCreateText \"%d--ARTWORK BOTTOM\"                                                  \n",i)
                );end_when
             fprintf(rpt "(_clpAdjustPt 100:%d _clp_cinfo)  _clp_text_orient                                               \n",j)
             fprintf(rpt "\"BOARD GEOMETRY/DIMENSION\" _clp_sym))                                                               \n")
             );end_foreach        
    ; -------------------------------------      
     fprintf(rpt "(axlMsgPut (list \"Text pasted without CLIP_DRAWING property.\" _clpAxlMsg.classWarn))                \n")
     fprintf(rpt "(_clpDisplayMessage)                                                                                \n")
     fprintf(rpt "(axlFlushDisplay)                                                                                    \n")
     
  close(rpt)                                                                                            
));end_defun   _DSY_Extract_Creatclp                                                                                   
