#!c:\app\perl\bin\perl.exe -l
#-------------------------------------------------------------------------------
# Copyright (c) 1996-2006, J.C. Roberts <True(@)DigitalLove_org> 
# http://www.DesignTools.org  - All Rights Reserved
#
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
#
#  1.) Redistributions of source code must retain the above copyright notice, 
#      this list of conditions and the following disclaimer.
#
#  2.) Redistributions in binary form must reproduce the above copyright notice, 
#      this list of conditions and the following disclaimer in the documentation 
#      and/or other materials provided with the distribution.
#
#  3.) The names of the copyright holders, the names of contributors and the 
#      name of the organization, DesignTools, may not be used to endorse or 
#      promote products including or derived from this software without specific 
#      prior written consent.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNERS OR CONTRIBUTORS BE LIABLE 
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,OR CONSEQUENTIAL 
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR 
# SERVICES, LOSS OF USE, DATA, OR PROFITS, OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, 
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE 
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#-------------------------------------------------------------------------------

#--------------------------------------------------------------------------------
# This is mad hackery at it's finest, the DesignTools Release Generator.


#--------------------------------------------------------------------------------
# Set Minimum Perl Version
use v5.8.0;
#use strict 'vars';        # allows globals defined with our()
use POSIX;
use File::Spec;
use File::Spec::Win32;
use File::Find;           
use File::Copy;
use IO::Handle;
use Cwd;
use File::Path;
#require File::Spec::Win32;
#require Win32::LFN;
use Win32;


#--------------------------------------------------------------------------------
# Function Declarations
sub _main();
sub show_usage();
sub cp_right($*);           # Comment String, File Handle
sub get_modules($$$);       # LogsFH, Current Date, User Name
sub process_module($$***);  # moudle name, LogsFH, SetsFH, MlibFH, MenuFH
sub gen_skill_file($$);     # file/procedure name, <true | FileHandle>
sub gen_shell_file($$);     # file/procedure name, <true | FileHandle>
sub gen_skill_file($$);     # a safe, cross platform way to copy files

#--------------------------------------------------------------------------------
# Global Variables
our ($reldir, $srcdir, $relver, %menu_item);
$relver = "DesignTools Release Generator v1.0.0";
$srcdir = "_src";
$wwwdir = "_www";
$reldir = "_release/ChaosTools-src";
$arcdir = "_release/ChaosTools-arc";

$up1dir = "_src-arc/";
$up2dir = "_src-arc/";
$up3dir = "_src-arc/";

@bkdirs = ($up1dir, $up2dir, $up3dir);
@bkdirs = ($up1dir);
@archives = ($reldir, $srcdir, $wwwdir);


#--------------------------------------------------------------------------------
# execute main
_main();

#--------------------------------------------------------------------------------
sub _main()
{ # local variables
  my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $cur_date);
  my ($mod_name, @mods_ary, @args, $cur_date, $LogsFH, $SetsFH, $MenuFH, $MlibFH);
  my ($arc_file, $tmp_arch, $tmp_cntr, $filename, $file_ext, @dirs, $lastchunk);
  my ($UserName, $i, $DoArcive, $cur_dir);

  $DoArcive = false;
  $UserName = false;
  # process command line arg input
  for($i=0; $i <= $#ARGV; $i++)
  {
    if(@ARGV[$i] eq "-u") {$UserName = @ARGV[$i + 1]; printf("\nUserName: %s\n", $UserName);}
    if(@ARGV[$i] eq "-a") {$DoArcive = true; printf("\nArchive.: true\n");}
  }
  if(($UserName eq false) || ($UserName eq ""))
  {
    printf("\n\nBad User Name\n");
    show_usage();
    return -1;
  }

	my $curdir=getcwd(); 
	my @Dir = split(/[\/\\]/, $curdir);
	pop(@Dir);
	my $PreviousDir = join("/", @Dir);
	print "The original Directory is $curdir\n";
	print "The new Directory is $PreviousDir\n";
  
  $srcdir = "$PreviousDir"."/$srcdir";
	$wwwdir = "$PreviousDir"."/$wwwdir";
	$reldir = "$PreviousDir"."/$reldir";
	$arcdir = "$PreviousDir"."/$arcdir";
	$up1dir = "$PreviousDir"."/$up1dir";
	$up2dir = "$PreviousDir"."/$up2dir";
	$up3dir = "$PreviousDir"."/$up3dir";		
	print "The srcdir is $srcdir\n";
	print "The wwwdir is $wwwdir\n";
	print "The reldir is $reldir\n";
	print "The arcdir is $arcdir\n";
#  $UserName = chomp($UserName);
  chomp($UserName);
  # get current release build time
  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday) =  gmtime(time);
  # release logging
  open (my $LogsFH, "+> ./_gen/_release.log") || die "\tERROR: Cannot Open File: \"./_gen/_release.log\" \n\t$!\n";
  binmode($LogsFH, ":unix");    # unix LF (0x0A) line endings
  printf $LogsFH ("Release Build Log\nVersion: %s\n", $relver);
  printf $LogsFH ("Release Build Date: %04d.%02d.%02d-%02d:%02d:%02d GMT\n", 
  ($year+=1900), ($mon+=1), $mday, $hour, $min, $sec);
  $cur_date = sprintf("%04d%02d%02d", $year, $mon, $mday);
  # generate skill install sets file
  $SetsFH = gen_skill_file("DT_install_sets", true);
  printf $SetsFH ("  (setq DT_FILE_SETS nil)\n");
  # generate skill menu loader library file
  $MlibFH = gen_skill_file("_DTL_MENUS", true);
  printf $MlibFH ("  (setq PathSet (axlGetVariable \"designtools\"))\n");
  # generate skill menu loader library file
  $MenuFH = gen_skill_file("DT_install_menu", true);
  printf $MenuFH ("  (setq DT_MENU_SETS nil)\n");
  printf $MenuFH ("  (defstruct ZMenuItem name kids text file)\n");
#  printf $MenuFH ("  (setq DT_Version \"%s\")\n"
#  printf $MenuFH ("  (setq DT_UserName
  
  # generate the shell/batch files
  gen_shell_file('UNIX', "DT_install_UNIX.sh");
  gen_shell_file('MSDOS', "DT_install_MSWIN.bat");
  gen_shell_file('SCR', "DT_install.scr");
	
  # delete existing release directory and recreate top level dir
  if(-e $reldir)
  {
    finddepth(sub { unlink $_; rmdir $_;}, $reldir);
  }
  else
  {
  	if (! -d $reldir) 
		{ 
  		mkpath($reldir) or die "Failed to create $directories: $!\n"; 
		}
    #mkdir($reldir) || die sprintf("\tERROR: Could Not Create Directory!\n\t%s\n\t$!\n", $reldir);
  }
  # create destination directory for storing archives
  if( !(-e $arcdir))
  {
    mkdir($arcdir) || die sprintf("\tERROR: Could Not Create Directory!\n\t%s\n\t$!\n", $arcdir);
  }

  
  # process each module
  print "process each module\n";
  @mods_ary = get_modules($LogsFH, $cur_date, $UserName);
  foreach $mod_name (@mods_ary) 
  { 
    process_module($mod_name, $LogsFH, $SetsFH, $MlibFH, $MenuFH);
  }
  # finish and close generated skill files
  print "finish and close generated skill files\n";
  gen_skill_file("DT_install_sets", $SetsFH);
  gen_skill_file("_DTL_MENUS", $MlibFH);
  gen_skill_file("DT_install_menu", $MenuFH);
  
  # process the generated files
  print "process the generated files\n";
  process_module("_gen", $LogsFH, false, false, false);

  # close and copy the last of the generated files, the release log
  close($LogsFH) || die "\n\tERROR: Cannot Close Output File: \"_release.log\" \n\t$!\n";
  copy(($srcdir . "/_gen/_release.log"), ($reldir . "/_release.log"))
    || die "\n\tERROR: Cannot Copy File: \"$srcdir/_gen/_release.log\" \n\t$!\n";

  # execute the installation from the new release directory
  print "execute the installation from the new release directory\n";
  chdir($reldir);
  @args = ();
  @args = ("DT_install_MSWIN.bat", "-s");
  system(@args) == 0 or die "ERROR: System Command Failed:\n\t\"@args\"\n $?\n";
return ;
	chdir($reldir);
  # archive all files and make backup copies
  if($DoArcive ne false)
  {
    if($UserName eq "USER")
    {
      # delete oll archive files from web site directory
      finddepth(sub { unlink $_; rmdir $_;}, ($wwwdir . "/files"));
      # open a *.php file for writing
      open( phpFH, ("+> ". $wwwdir . "/downloads/files.php")) || 
          die sprintf("\tERROR: Cannot Open File: \n\t\"%s\" \n\t$!\n", 
              ($wwwdir . "/downloads/files.php"));
      binmode(phpFH, ":unix");    # unix LF (0x0A) line endings
    }
    #---------------------------------------------------------------------------
    # create a release distribution archive and back them up to multiple places
    foreach(@archives)
    {
      $cur_dir = $_ ;
      my $temp_cur_dir = "$PreviousDir"."/$_";
      chdir($temp_cur_dir)|| die "ERROR: Directory Chance Failed:\n\t\"$_\"\n $?\n";;
      printf( "\n\nCurrentDir.: %s\n", $temp_cur_dir);
      chdir(".."); 
      if( $temp_cur_dir eq $srcdir) { $file_ext = "-src.zip"; }
      elsif( $temp_cur_dir eq $reldir) { $file_ext = "-usr.zip"; }
      elsif( $temp_cur_dir eq $wwwdir) { $file_ext = "-www.zip"; }
      @dirs = split(/\//,$temp_cur_dir);
      $filename = "ChaosTools-" . sprintf("%04d.%02d.%02d-", $year, $mon, $mday);
      $arc_file = $arcdir . "/" . $filename;
      $tmp_arch = "";
      $tmp_cntr = 0;
      while( !($arc_file eq $tmp_arch))
      {
        $tmp_arch = $arc_file . sprintf("%02d", $tmp_cntr) . $file_ext;
        if( !( -e $tmp_arch))
        {
          $arc_file = $tmp_arch;
          $filename = $filename . sprintf("%02d", $tmp_cntr) . $file_ext;
          printf( "Unused.Name: %s\n", $arc_file);
        }
        else
        {
          printf( "_USED_Name: %s\n", $tmp_arch);
        }
        $tmp_cntr = $tmp_cntr +1;
      }
      printf("\n\nCreating Zip Archive: \"%s\"\n\n", $arc_file);
      @args = ();
      @args = ("D:/Progra~1/7-Zip/7z.exe", "a", $arc_file, $dirs[$#dirs]);
      system(@args) == 0 or die "ERROR: System Command Failed:\n\t\"@args\"\n $?\n";
      foreach( @bkdirs ) { safecopy($arc_file, ($temp_cur_dir . $filename)); }
      if($UserName eq "USER")
      {
        if($cur_dir eq $srcdir)
        { 
          printf phpFH ('<?php include("$dot/inc/inc-line.php"); ?>');
          printf phpFH ("\n<p>\n");
          printf phpFH ("Developer Source Code Tree:<br />\n");
          printf phpFH ("<p>\n");
          printf phpFH ("<ul>\n");
          printf phpFH ("  <li><a href=\"<?php echo " . '$dot' . 
              " ?>/files/%s\">%s</a></li>\n", $filename, $filename);
          printf phpFH ("</ul>\n");
          safecopy($arc_file, ($wwwdir . "/files/" . $filename));
        }
        elsif($cur_dir eq $reldir)
        { 
          printf phpFH ("<?php include(\"%s/inc/inc-line.php\"); ?>\n", '$dot');
          printf phpFH ("\n<p>\n");
          printf phpFH ("User Installation Packages:<br />\n");
          printf phpFH ("<p>\n");
          printf phpFH ("<ul>\n");
          printf phpFH ("  <li><a href=\"<?php echo " . '$dot' . 
              " ?>/files/%s\">%s</a></li>\n", $filename, $filename);
          printf phpFH ("</ul>\n");
          safecopy($arc_file, ($wwwdir . "/files/" . $filename));
        }
        elsif($cur_dir eq $wwwdir)
        { 
          printf phpFH ('<?php include("$dot/inc/inc-line.php"); ?>');
          printf phpFH ("\n<p>\n");
          printf phpFH ("Developer Web Site Framework:<br />\n");
          printf phpFH ("<p>\n");
          printf phpFH ("<ul>\n");
          printf phpFH ("  <li><a href=\"<?php echo " . '$dot' . 
              " ?>/files/%s\">%s</a></li>\n", $filename, $filename);
          printf phpFH ("</ul>\n");
          safecopy($arc_file, ($wwwdir . "/files/" . $filename));
        }
      }
    }
    if($UserName eq "USER")
    {
      close(phpFH) || die "\n\tERROR: Cannot Close PHP File: \"files.php\" \n\t$!\n";
    }
  } 
  chdir($srcdir);
} #end sub _main()

#--------------------------------------------------------------------------------
#
sub get_modules($$$)
{
  my $LogsFH = shift;
  my $cur_date = shift;
  my $UserName = shift;
  my ($usr_name, $usr_numb, $usr_dbug, $usr_expr, $i);
  my ($inp_line, $trig, $mod_name, $mod_expr, @mods_ary, @expr_ary, @line_ary);
  # user information database
  open(my $UserFH, '< ListUser.dat') || die "\tERROR: Cannot Open File: \"ListUser.dat\" \n\t$!\n";
  binmode($UserFH, ":unix");    # unix LF (0x0A) line endings
  # Read the user from user file/database and parse for the particular user.
  $trig = false;
  while(($trig eq false) && (!eof($UserFH)))
  {
    $inp_line = readline($UserFH);      # read "!" separated line from file
    @line_ary = split(/!/, $inp_line);  # split line up into an array.
    if(@line_ary[0] eq $UserName) { $trig = true;}
  }
  $usr_name = @line_ary[0];             # get the user name
  $usr_numb = @line_ary[1];             # get the user ID number
  $usr_dbug = @line_ary[2];             # get the user debug identifier

  unless($usr_name eq $UserName)
  {
    die "\tERROR: Cannot Find User Name: \"ListUser.dat\" \n\t$!\n";
  }

  # status printing
  printf $LogsFH ("\n");
  print $LogsFH '-' x 80;
  printf("\nUserName: %s\nUserNumb: %s\nUserDbug: %s\n", 
    $usr_name, $usr_numb, $usr_dbug);
  printf $LogsFH ("UserName: %s\nUserNumb: %s\nUserDbug: %s\n", 
    $usr_name, $usr_numb, $usr_dbug);

  @mods_ary = ();                       # array of module names
  @expr_ary = ();                       # array of expiration dates
  # process modules and check expiry dates  
  for($i = 3; $i < @line_ary; $i++)
  {
    ($mod_name, $mod_expr) = split(/,/, @line_ary[$i]);
    $mod_expr =~ s/\.//g;
    #if($cur_date < $mod_expr)
    if(true)#强制更新
    {
      printf ("module..: %-12s %d\n", $mod_name, $mod_expr);
      printf $LogsFH ("module..: %-12s %d\n", $mod_name, $mod_expr);
      @mods_ary[($i-3)] = $mod_name;
      @expr_ary[($i-3)] = $mod_expr;    # not currently used...
    }
    else
    {
      printf ("module:\t%12s\tEXPIRED!\n", $mod_name);
      printf $LogsFH ("module:\t%12s\tEXPIRED!\n", $mod_name);
    }
  }
  close($UserFH) || die "\n\tERROR: Cannot Close Output File: \"ListUser.dat\" \n\t$!\n";  
  return @mods_ary;
}#end sub get_modules()


#--------------------------------------------------------------------------------
sub process_module($$***)
{
  my $mod_name = shift;     # module name
  my $LogsFH = shift;       # log file handle
  my $SetsFH = shift;       # skill install sets program file handle
  my $MlibFH = shift;       # skill menu library program file handle
  my $MenuFH = shift;       # skill install menu program file handle
  
  my ($inp_line, $dir_str, $fullpath, $src_file, $des_file);
  my ($menu_file, $menu_pars, $menu_dent, $menu_text, $menu_name, $pars_name);
  my ($PathDatFH, $FileDatFH, $MenuDatFH);
  my (@FType, %FName, %FHand, $tmpFH, $DType);
#  my ($fr_file, $to_file, $volume, $directories, $filename);  

  # create full directory string
  $dir_str = $srcdir . "/" . $mod_name;
  chdir($dir_str);
  # status printing
  printf $LogsFH ("\n");
  print $LogsFH '-' x 80;
  printf("\nProc_Mod: %s\n", $mod_name);
  printf $LogsFH ("Proc_Mod: %s\n", $mod_name);
  printf("Curr_Dir: %s\n", $dir_str);
  printf $LogsFH ("\nCurr_Dir: %s\n", $dir_str);
  # open input files for lists of menu items, files and paths  
  $FType[@FType] = 'PATH';
  $FType[@FType] = 'FILE';
  $FType[@FType] = 'MENU';
  $FName{'PATH'} = './_bld/ListPath.dat';
  $FName{'FILE'} = './_bld/ListFile.dat';
  $FName{'MENU'} = './_bld/ListMenu.dat';

  foreach $DType (@FType)
  {
    if( -e $FName{$DType})
    {
      open(my $tmpFH, ("< " . $FName{$DType}))
        || die sprintf("\n\tERROR: Cannot Open File: \"%s\" \n\t$!\n", 
        $FName{$DType});
      $FHand{$DType} = $tmpFH;
      binmode($FHand{$DType}, ":unix") # unix LF (0x0A) line endings
        || die sprintf("\n\tERROR: Cannot Set File Type (line endings): \"%s\" \n\t$!\n",
        $FName{$DType});
      printf("%sData: %s\n", $DType, $FName{$DType});
      printf $LogsFH ("%sData: %s\n", $DType, $FName{$DType});
    }
    else
    {
      if(!($dir_str =~ m/_gen$/))
      {
        printf("%sData: %s - Not Found!\n", $DType, $FName{$DType});
        printf $LogsFH ("%sData: %s - Not Found!\n", $DType, $FName{$DType});
        die sprintf("\n\tERROR: Missing Critical Data File: %s\n\t%s\n", 
        $FName{$DType}, $dir_str);
      }
      else
      {
        printf("%sData: %s - Not Necessary!\n", $DType, $FName{$DType});
        printf $LogsFH ("%sData: %s - Not Necessary!\n", $DType, $FName{$DType});
      }
    }
  }

  # write skill code into DT_install_sets.il
  if ($SetsFH ne false)
  {
    printf $SetsFH ("\n  ;MODULE_NAME: %s\n", $mod_name);
    printf $SetsFH ("  (setq PathSet nil)\n");
    printf $SetsFH ("  (setq FileSet nil)\n");
  }
  if ($MlibFH ne false)
  {
    printf $MlibFH ("\n  ;MODULE_NAME: %s\n", $mod_name);
  }  
  if ($MenuFH ne false)
  {
    printf $MenuFH ("\n  ;MODULE_NAME: %s\n", $mod_name);
  }  
  # process the needed paths
  while (!eof($FHand{'PATH'}))
  {
    $inp_line = readline($FHand{'PATH'});
    chomp($inp_line);
    $fullpath = "";
    $fullpath = $reldir . $inp_line;
    printf("Add_Path: %s\n", $fullpath);
    printf $LogsFH ("Add_Path: %s\n", $fullpath);
    # create release directory
    mkdir($fullpath) || die sprintf("\n\tERROR: Could Not Create Directory!\n\t%s\n\t$!\n", $fullpath);
    # add entry to skill path set
#    if(!($inp_line =~ m*/ins*g) && ($SetsFH ne false))
    if($SetsFH ne false)
    {
      printf $SetsFH ("  (setq PathSet (cons \"%s\" PathSet))\n", $inp_line);
    }
  }
  # process the needed files
  while (!eof($FHand{'FILE'}))
  {
    $inp_line = readline($FHand{'FILE'});
    ($src_file, $des_file) = split( /!/, $inp_line);
    chomp($src_file);
    chomp($des_file);
    $src_file =~ s/ //g;
    $des_file =~ s/ //g;
    printf("cpy_file: %s -> %s\n", $src_file, $des_file);
    printf $LogsFH ("cpy_file: %s -> %s\n", $src_file, $des_file);
    $src_file = $srcdir . $src_file;
#__FIXME__ Need to do DEBUG/NODEBUG processing of skill files

    safecopy($src_file, ($reldir .  $des_file));

    # create entries in skill for non-installation files to be installed from
    # the install media to the users system.
#    if(!($src_file =~ m*/ins/*g) && ($SetsFH ne false))
    if($SetsFH ne false)
    {
      printf $SetsFH ("  (setq FileSet (cons \"%s\" FileSet))\n", $des_file);
      if(($src_file =~ m/\.il$/) && 
        ($MlibFH ne false) && 
        !($src_file =~ m/libMENUS\.il$/) &&
        !($src_file =~ m/_install\.il$/)
      )
      {
        printf $MlibFH ("  (load (strcat PathSet \"%s\"))\n", $des_file);
      }
    }
  }#end file list processing

  # process the needed menu items
  while(!eof($FHand{'MENU'}))
  {
    $inp_line = readline($FHand{'MENU'});
# FIXME -add comment lines
    if(!($inp_line =~ m/^\n/))
    {
      ($menu_file, $menu_pars, $menu_dent, $menu_text) = split(/!/, $inp_line);
      chomp($menu_file, $menu_pars, $menu_dent, $menu_text);
      $menu_text =~ s/"/\\"/g;
      $menu_name = $menu_file . "_" . $mod_name;
      $pars_name = $menu_file . "_" . $menu_pars;
      if (!($menu_item{$menu_name}))
      {
        $menu_item{$menu_name} = true;
        printf $MenuFH ("  (setq %s (make_ZMenuItem))\n", $menu_name);
        if($mod_name eq 'base')
        {
          printf $MenuFH ("  (setq DT_MENU_SETS (cons %s DT_MENU_SETS))\n", $menu_name);
        }
        printf $MenuFH ("  %s->name = \"%s\"\n", $menu_name, $menu_name);       
        printf $MenuFH ("  %s->file = \"%s\"\n", $menu_name, ($menu_file . ".men"));
        printf $MenuFH ("  %s->kids = nil\n", $menu_name);
        printf $MenuFH ("  %s->text = nil\n", $menu_name);
      
        if(!($menu_pars =~ m/nil$/))
        {
          printf $MenuFH ("  %s->kids = (cons %s %s->kids)\n", 
            $pars_name, $menu_name, $pars_name);
        }
      }
      printf $MenuFH ("  %s->text = (append1 %s->text (list %d \"%s\"))\n", 
        $menu_name, $menu_name, $menu_dent, $menu_text);
    }
  }#end menu data file processing
  # finish skill code for path sets
  if ($SetsFH ne false)
  {
    printf $SetsFH ("  (setq PathSet (reverse PathSet))\n");
    printf $SetsFH ("  (setq DT_FILE_SETS (cons (list \"%s\" PathSet FileSet) DT_FILE_SETS))\n", $mod_name);
  }
  # close input files
  foreach $DType (@FType)
  {
    if( -e $FName{$DType})
    {
      close($FHand{$DType}) || 
      die sprintf( "\n\tERROR: Cannot Close Output File: \"%s\" \n\t$!\n", $FName{$DType});
    }
  }
}#end sub process_module()


#--------------------------------------------------------------------------------
# ROUTINE: safecopy($$)
# A safe, cross-platform way to copy files
sub safecopy($$)
{
  my $fr_file = shift;
  my $to_file = shift;
  my($volume, $directories, $filename);

#  $fr_file = $src_file;
  $fr_file =~ s/\//\\/g;
  ($volume, $directories, $filename) = File::Spec->splitpath( $fr_file );
  $fr_file = File::Spec->catpath($volume, $directories, $filename);
  printf("fr_file.: %s\n", $fr_file);

#  $to_file = $reldir . $des_file;
  $to_file =~ s/\//\\/g;
  ($volume, $directories, $filename) = File::Spec->splitpath( $to_file );
  $to_file = File::Spec->catpath($volume, $directories, $filename);
  printf("to_file.: %s\n", $to_file);
  printf("dirs....: %s\n", $directories);
  
  foreach(@directories)
  {
    printf("DIR: %s\n", $_);
  }
  
  if (! -d $directories) 
	{ 
  	mkpath($directories) or die "Failed to create $directories: $!\n"; 
	} 
#  Win32::CopyFile(FROM, TO, OVERWRITE)
#  Win32::CopyFile($fr_file, $to_file, true) || 
#      die sprintf("ERROR: Could Not Copy File:\n  %s\n  %s\n\n\t$!\n", $fr_file, $to_file);
#  Win32::CopyFile(Win32::GetShortPathName($fr_file), Win32::GetShortPathName($to_file), true) || 
#      die sprintf("ERROR: Could Not Copy File:\n  %s\n  %s\n\n\t$!\n", $fr_file, $to_file);
  copy($fr_file, $to_file) || 
      die sprintf("ERROR: Could Not Copy File:\n  %s\n  %s\n\n\t$!\n", $fr_file, $to_file);
}


#--------------------------------------------------------------------------------
# ROUTINE: gen_skill_file($$)
# 
# Generate the start or end of a skill file.
#
# arg #1 is the filename and also function name
# arg #2 is either "true" or the file handle
sub gen_skill_file($$)
{
  my $ProcName = shift;
  my $InArg = shift;
  if( $InArg eq true)
  { # write start of skill file
    my $FileName = "+>". $srcdir . "/_gen/" . $ProcName . ".il";
    open(my $SetsFH, $FileName) || die sprintf("\tERROR: Cannot Open File: \n\t\"%s\" \n\t$!\n", $FileName);
    binmode($SetsFH, ":unix");    # unix LF (0x0A) line endings
    cp_right(";", $SetsFH);       # add copyright statement to file
    # print out start of autogenerated "DT_install_sets.il" file
    printf $SetsFH ("(procedure (%s)\n", $ProcName);  
    printf $SetsFH ("(let (DMSG UsrMsg PathSet FileSet MenuSet LoadSet)\n");
    printf $SetsFH ("  (setq DMSG nil)\n");
    printf $SetsFH ("  (setq UsrMsg (sprintf nil \"MESSAGE: DesignTools File Loaded - %s.il\\n\"))\n", $ProcName);
    printf $SetsFH ("  (printf \"%s\" UsrMsg)\n", '%s');
    return $SetsFH;
  }
  else # write end of skill file
  {
    printf $InArg ("\n));end LET_and_PROCEDURE\n");
    printf $InArg ("\n(%s)\n\n", $ProcName);
    close($InArg) || die "\n\tERROR: Cannot Close Output File: \"./_gen/DT_install_sets.il\" \n\t$!\n";
  }
}#end sub gen_skill_file_start()

#--------------------------------------------------------------------------------
# ROUTINE: gen_shell_file($$)
# This generates the installation shell (UNIX) and batch (MSDOS) files and the
# installation launching script (allegro scripting).
sub gen_shell_file($$)
{
  my $FileType = shift;
  my $FileName = shift;
  $FileName = "+> ". $srcdir . "/_gen/" . $FileName;
  if ( $FileType eq 'UNIX')
  {
    open(my $ShllFH, $FileName) || die sprintf("\tERROR: Cannot Open File: \n\t\"%s\" \n\t$!\n", $FileName);
    binmode($ShllFH, ":unix");    # unix LF (0x0A) line endings
    cp_right("#", $ShllFH); # add copyright statement to file
    printf $ShllFH ("allegro -p \".\" -s \"./base/ins/DT_install.scr\" -j \"\$home/DT_install.jrl\"\n");
    close($ShllFH) || die sprintf("\tERROR: Cannot CLose File:\n\t%s\n\t$!\n", $FileName);
  }
  elsif( $FileType eq 'MSDOS' )
  {
    open(my $ShllFH, $FileName) || die sprintf("\tERROR: Cannot Open File: \n\t\"%s\" \n\t$!\n", $FileName);
    binmode($ShllFH, ":unix:crlf"); # MSDOS CRLF (0x0D 0x0A) line endings
    printf $ShllFH ('@echo off' . "\n");
    cp_right("rem ", $ShllFH);      # add copyright statement to file
    printf $ShllFH ("allegro -p \".\" -s \"./base/ins/DT_install.scr\" -j \"%TEMP%/DT_install.jrl\"\n");
    close($ShllFH) || die sprintf("\tERROR: Cannot CLose File:\n\t%s\n\t$!\n", $FileName);
  }
  elsif ( $FileType eq 'SCR')
  {
    open(my $ShllFH, $FileName) || die sprintf("\tERROR: Cannot Open File: \n\t\"%s\" \n\t$!\n", $FileName);
    binmode($ShllFH, ":unix");    # unix LF (0x0A) line endings
    cp_right("#", $ShllFH);       # add copyright statement to file
    printf $ShllFH ("skill\n");
    printf $ShllFH ("(load \"./base/ins/DT_install.il\")\n");
    close($ShllFH) || die sprintf("\tERROR: Cannot CLose File:\n\t%s\n\t$!\n", $FileName);
  }
}#end sub gen_shell_file($$)


#--------------------------------------------------------------------------------
# printing of copyright statement into generated files
sub cp_right($*)
{
  my $cmt_char = shift;
  my $fileFH  = shift;
  my ($state_line);
  my @statement = (
"-------------------------------------------------------------------------------",
" Copyright (c) 2005, J.C. Roberts <True(@)DigitalLove_org> All Rights Reserved ",
" http://www.DesignTools.org                                                    ",
"                                                                               ",
" Redistribution and use in source and binary forms, with or without            ",
" modification, are permitted provided that the following conditions are met:   ",
"                                                                               ",
"  1.) Redistributions of source code must retain the above copyright notice,   ",
"      this list of conditions and the following disclaimer.                    ",
"                                                                               ",
"  2.) Redistributions in binary form must reproduce the above copyright notice,", 
"      this list of conditions and the following disclaimer in the documentation", 
"      and/or other materials provided with the distribution.                   ",
"                                                                               ",
"  3.) The names of the copyright holders, the names of contributors and the    ",
"      name of the organization, DesignTools, may not be used to endorse or     ",
"      promote products including or derived from this software without specific", 
"      prior written consent.                                                   ",
"                                                                               ",
" THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS \"AS IS\" ",
" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE     ",
" IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE", 
" DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNERS OR CONTRIBUTORS BE LIABLE  ",
" FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,OR CONSEQUENTIAL     ",
" DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR    ",
" SERVICES, LOSS OF USE, DATA, OR PROFITS, OR BUSINESS INTERRUPTION) HOWEVER    ",
" CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, ",
" OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE ",
" OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.          ",
"-------------------------------------------------------------------------------",
  );

  foreach $state_line (@statement)
  {
    printf $fileFH ("%s%s\n", $cmt_char, $state_line);
  }
  printf $fileFH ("\n%s THIS FILE WAS AUTOMATICLY GENERATED - ALL CHANGES WILL BE LOST\n\n", $cmt_char);
}

#--------------------------------------------------------------------------------
sub show_usage()
{
  print("\n\tUsage: perl _release.pl [-a] -u USER_NAME\n")
}













