(**************************************************************************
QuArK -- Quake Army Knife -- 3D game editor
Copyright (C) QuArK Development Team

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

https://quark.sourceforge.io/ - Contact information in AUTHORS.TXT
**************************************************************************)
unit QConsts;

interface

{$I DelphiVer.inc}

const
  QuArKVersion            = 'QuArK 6.6';
  QuArKMinorVersion       = 'Beta 8';
  QuArKCopyright          = 'Copyright (C) 1996-2022 Armin Rigo and others';
{$IFDEF CompiledWithDelphi1}
  QuArKUsedCompiler       = 'Delphi 1.0';
{$ELSE}
{$IFDEF CompiledWithDelphi2}
  QuArKUsedCompiler       = 'Delphi 2.0';
{$ELSE}
{$IFDEF CompiledWithDelphi3}
  QuArKUsedCompiler       = 'Delphi 3.0';
{$ELSE}
{$IFDEF CompiledWithDelphi4}
  QuArKUsedCompiler       = 'Delphi 4.0';
{$ELSE}
{$IFDEF CompiledWithDelphi5}
  QuArKUsedCompiler       = 'Delphi 5.0';
{$ELSE}
{$IFDEF CompiledWithDelphi6}
  QuArKUsedCompiler       = 'Delphi 6.0';
{$ELSE}
{$IFDEF CompiledWithDelphi7}
  QuArKUsedCompiler       = 'Delphi 7.0';
{$ELSE}
{$IFDEF CompiledWithDelphi8}
  QuArKUsedCompiler       = 'Delphi 8.0';
{$ELSE}
{$IFDEF CompiledWithDelphi2005}
  QuArKUsedCompiler       = 'Delphi 2005';
{$ELSE}
{$IFDEF CompiledWithDelphi2006}
  QuArKUsedCompiler       = 'Delphi 2006';
{$ELSE}
{$IFDEF CompiledWithDelphi2007}
  QuArKUsedCompiler       = 'Delphi 2007';
{$ELSE}
{$IFDEF CompiledWithDelphi2009}
  QuArKUsedCompiler       = 'Delphi 2009';
{$ELSE}
{$IFDEF CompiledWithDelphi2010}
  QuArKUsedCompiler       = 'Delphi 2010';
{$ELSE}
{$IFDEF CompiledWithDelphiXE}
  QuArKUsedCompiler       = 'Delphi XE1';
{$ELSE}
{$IFDEF CompiledWithDelphiXE2}
  QuArKUsedCompiler       = 'Delphi XE2';
{$ELSE}
{$IFDEF CompiledWithDelphiXE2}
  QuArKUsedCompiler       = 'Delphi XE3';
{$ELSE}
{$IFDEF CompiledWithDelphiXE4}
  QuArKUsedCompiler       = 'Delphi XE4';
{$ELSE}
{$IFDEF CompiledWithDelphiXE5}
  QuArKUsedCompiler       = 'Delphi XE5';
{$ELSE}
{$IFDEF CompiledWithDelphiXE6}
  QuArKUsedCompiler       = 'Delphi XE6';
{$ELSE}
{$IFDEF CompiledWithDelphiXE7}
  QuArKUsedCompiler       = 'Delphi XE7';
{$ELSE}
{$IFDEF CompiledWithDelphiXE8}
  QuArKUsedCompiler       = 'Delphi XE8';
{$ELSE}
{$IFDEF CompiledWithDelphi10_0}
  QuArKUsedCompiler       = 'Delphi 10.0';
{$ELSE}
{$IFDEF CompiledWithDelphi10_1}
  QuArKUsedCompiler       = 'Delphi 10.1';
{$ELSE}
{$IFDEF CompiledWithDelphi10_2}
  QuArKUsedCompiler       = 'Delphi 10.2';
{$ELSE}
{$IFDEF CompiledWithDelphi10_3}
  QuArKUsedCompiler       = 'Delphi 10.3';
{$ELSE}
{$IFDEF CompiledWithDelphi10_4}
  QuArKUsedCompiler       = 'Delphi 10.4';
{$ELSE}
{$IFDEF CompiledWithDelphi111}
  QuArKUsedCompiler       = 'Delphi 11';
{$ELSE}
  QuArKUsedCompiler       = 'Delphi';
{$ENDIF}
{$ENDIF}
{$ENDIF}
{$ENDIF}
{$ENDIF}
{$ENDIF}
{$ENDIF}
{$ENDIF}
{$ENDIF}
{$ENDIF}
{$ENDIF}
{$ENDIF}
{$ENDIF}
{$ENDIF}
{$ENDIF}
{$ENDIF}
{$ENDIF}
{$ENDIF}
{$ENDIF}
{$ENDIF}
{$ENDIF}
{$ENDIF}
{$ENDIF}
{$ENDIF}
{$ENDIF}
{$ENDIF}
{$ENDIF}
  QuArKCompileDate        = 44750;   //This is the compiled date
  { Amount of days that have passed after 30 Dec 1899 (Delphi 2+).
    You can use EncodeDate(Year, Month, Day) to compute it, but this value
    really needs to be a constant, so put the resulting value in here.
    The result can be checked in the About form. }
  QuArKDaysOld            = 270;     //About a 9 month difference...
  { This is the amount of days after which a certain build is considered
    old by the update-check. }
  QuArKWebsite            = 'https://quark.sourceforge.io/';
  QuArKRepository         = 'https://sourceforge.net/projects/quark/';
  QuArKForum              = 'https://quark.sourceforge.io/forums/';
  QuArKInfobase           = 'https://quark.sourceforge.io/infobase/';
  QuArKDefaultHelpPage    = 'index.html'; 
  QuArKUpdateSite         = 'quark.sourceforge.io';
  QuArKUpdateFile         = '/update/index.dat';

implementation

end.
