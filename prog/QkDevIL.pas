(**************************************************************************
QuArK -- Quake Army Knife -- 3D game editor
Copyright (C) Armin Rigo

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
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

http://www.planetquake.com/quark - Contact information in AUTHORS.TXT
**************************************************************************)

{
$Header$
 ----------- REVISION HISTORY ------------
$Log$
Revision 1.2  2007/05/02 22:34:50  danielpharos
Added DDS file support. Fixed wrong (but unused then) DevIL DDL interface. DDS file saving not supported at the moment.

Revision 1.1  2007/04/30 21:52:55  danielpharos
Added basic interface to DevIL.



}

unit QkDevIL;

interface
uses Windows, SysUtils, QkObjects;

function LoadDevIL : Boolean;
procedure UnloadDevIL(ForceUnload: boolean);

{-------------------}

const
// Image types
  IL_TYPE_UNKNOWN= 0;
  IL_BMP= 1056;
  IL_CHEAD= 1071;
  IL_CUT= 1057;
  IL_DCX= 1080;
  IL_DDS= 1079;
  IL_DOOM= 1058;
  IL_DOOM_FLAT= 1059;
  IL_EXIF= 1082;
  IL_GIF= 1078;
  IL_HDR= 1087;
  IL_ICO= 1060;
  IL_JFIF= 1061;
  IL_JNG= 1077;
  IL_JPG= 1061;
  IL_LBM= 1062;
  IL_LIF= 1076;
  IL_MDL= 1073;
  IL_MNG= 1077;
  IL_PCD= 1063;
  IL_PCX= 1064;
  IL_PIC= 1065;
  IL_PIX= 1084;
  IL_PNG= 1066;
  IL_PNM= 1067;
  IL_PSD= 1081;
  IL_PSP= 1083;
  IL_PXR= 1085;
  IL_RAW= 1072;
  IL_SGI= 1068;
  IL_TGA= 1069;
  IL_TIF= 1070;
  IL_WAL= 1074;
  IL_XPM= 1086;
  IL_JASC_PAL= 1141;

// Mode types
  IL_ORIGIN_SET= $0600;
  IL_ORIGIN_MODE= $0603;
  IL_ORIGIN_LOWER_LEFT= $0601;
  IL_ORIGIN_UPPER_LEFT= $0602;
  IL_FORMAT_SET= $0610;
  IL_FORMAT_MODE= $0611;
  IL_TYPE_SET= $0612;
  IL_TYPE_MODE= $0613;
  IL_FILE_MODE= $0621;
  IL_CONV_PAL= $0630;
  IL_USE_KEY_COLOUR= $0635;
  IL_USE_KEY_COLOR= $0635;
  IL_VERSION_NUM= $0DE2;
  IL_IMAGE_WIDTH= $0DE4;
  IL_IMAGE_HEIGHT= $0DE5;
  IL_IMAGE_DEPTH= $0DE6;
  IL_IMAGE_SIZE_OF_DATA= $0DE7;
  IL_IMAGE_BPP= $0DE8;
  IL_IMAGE_BYTES_PER_PIXEL= $0DE8;
  IL_IMAGE_BITS_PER_PIXEL= $0DE9;
  IL_IMAGE_FORMAT= $0DEA;
  IL_IMAGE_TYPE= $0DEB;
  IL_PALETTE_TYPE= $0DEC;
  IL_PALETTE_SIZE= $0DED;
  IL_PALETTE_BPP= $0DEE;
  IL_PALETTE_NUM_COLS= $0DEF;
  IL_NUM_IMAGES= $0DF1;
  IL_NUM_MIPMAPS= $0DF2;
  IL_NUM_LAYERS= $0DF3;
  IL_ACTIVE_IMAGE= $0DF4;
  IL_ACTIVE_MIPMAP= $0DF5;
  IL_ACTIVE_LAYER= $0DF6;
  IL_CUR_IMAGE= $0DF7;

// Mode types (file specific):
  IL_TGA_CREATE_STAMP        =$0710;
  IL_JPG_QUALITY             =$0711;
  IL_PNG_INTERLACE           =$0712;
  IL_TGA_RLE                 =$0713;
  IL_BMP_RLE                 =$0714;
  IL_SGI_RLE                 =$0715;
  IL_TGA_ID_STRING           =$0717;
  IL_TGA_AUTHNAME_STRING     =$0718;
  IL_TGA_AUTHCOMMENT_STRING  =$0719;
  IL_PNG_AUTHNAME_STRING     =$071A;
  IL_PNG_TITLE_STRING        =$071B;
  IL_PNG_DESCRIPTION_STRING  =$071C;
  IL_TIF_DESCRIPTION_STRING  =$071D;
  IL_TIF_HOSTCOMPUTER_STRING =$071E;
  IL_TIF_DOCUMENTNAME_STRING =$071F;
  IL_TIF_AUTHNAME_STRING     =$0720;
  IL_JPG_SAVE_FORMAT         =$0721;
  IL_CHEAD_HEADER_STRING     =$0722;
  IL_PCD_PICNUM              =$0723;
  IL_PNG_ALPHA_INDEX         =$0724;

// Error types
  IL_NO_ERROR=             $0000;
  IL_INVALID_ENUM=         $0501;
  IL_OUT_OF_MEMORY=        $0502;
  IL_FORMAT_NOT_SUPPORTED= $0503;
  IL_INTERNAL_ERROR=       $0504;
  IL_INVALID_VALUE=        $0505;
  IL_ILLEGAL_OPERATION=    $0506;
  IL_ILLEGAL_FILE_VALUE=   $0507;
  IL_INVALID_FILE_HEADER=  $0508;
  IL_INVALID_PARAM=        $0509;
  IL_COULD_NOT_OPEN_FILE=  $050A;
  IL_INVALID_EXTENSION=    $050B;
  IL_FILE_ALREADY_EXISTS=  $050C;
  IL_OUT_FORMAT_SAME=      $050D;
  IL_STACK_OVERFLOW=       $050E;
  IL_STACK_UNDERFLOW=      $050F;
  IL_INVALID_CONVERSION=   $0510;
  IL_BAD_DIMENSIONS=       $0511;
  IL_FILE_READ_ERROR=      $0512;
  IL_FILE_WRITE_ERROR=     $0512;
  IL_LIB_GIF_ERROR=  $05E1;
  IL_LIB_JPEG_ERROR= $05E2;
  IL_LIB_PNG_ERROR=  $05E3;
  IL_LIB_TIFF_ERROR= $05E4;
  IL_LIB_MNG_ERROR=  $05E5;
  IL_UNKNOWN_ERROR=  $05FF;

// Format types:
  IL_COLOUR_INDEX     =$1900;
  IL_COLOR_INDEX      =$1900;
  IL_RGB              =$1907;
  IL_RGBA             =$1908;
  IL_BGR              =$80E0;
  IL_BGRA             =$80E1;
  IL_LUMINANCE        =$1909;
  IL_LUMINANCE_ALPHA  =$190A;

// Format type types:
  IL_BYTE           =$1400;
  IL_UNSIGNED_BYTE  =$1401;
  IL_SHORT          =$1402;
  IL_UNSIGNED_SHORT =$1403;
  IL_INT            =$1404;
  IL_UNSIGNED_INT   =$1405;
  IL_FLOAT          =$1406;
  IL_DOUBLE         =$140A;

type
  DevILType = Integer;
  DevILMode = Integer;
  DevILError = Integer;
  DevILFormat = Integer;
  DevILFormatType = Integer;

var
  ilInit: procedure; stdcall;
  ilShutDown: procedure; stdcall;
  ilGetError: function : DevILError; stdcall;
  ilGetBoolean: function (Mode : DevILMode) : Boolean; stdcall;
  //ilGetBooleanv: procedure (Mode : DevILMode; Param : PBoolean); stdcall;
  ilGetInteger: function (Mode : DevILMode) : Integer; stdcall;
  //ilGetIntegerv: procedure (Mode : DevILMode; Param : PInteger); stdcall;
  ilSetInteger: procedure (Mode : DevILMode; Param : Integer); stdcall;

  //DanielPharos: I'm guessing this is a mistake in DevIL. The return should be a Cardinal!
  //ilGenImage: function : Integer; stdcall;
  ilGenImages: procedure (Num : Integer; Images : PCardinal); stdcall;
  ilBindImage: procedure (Image : Cardinal); stdcall;
  //ilDeleteImage: procedure (Num : Integer); stdcall;
  ilDeleteImages: procedure (Num : Integer; Images : PCardinal); stdcall;

  { DanielPharos: The first parameter should be named Type, but since this is
  a statement in Delphi, we can't use that name }
  ilLoadL: function (xType : DevILType; Lump : PByte; Size : Cardinal) : Boolean; stdcall;
  ilSaveL: function (xType : DevILType; Lump : PByte; Size : Cardinal) : Integer; stdcall;
  //ilConvertImage: function (DestFormat : DevILFormat; DestType : DevILFormatType) : Boolean; stdcall;
  //ilGetData: function : PByte; stdcall;
  //ilSetData: function (Data : PByte) : Boolean; stdcall;
  ilCopyPixels: procedure (XOff : Cardinal; YOff : Cardinal; ZOff : Cardinal; Width : Cardinal; Height : Cardinal; Depth : Cardinal; Format : DevILFormat; xType : DevILFormatType; Data : PByte); stdcall;

  //ilSetPixels: procedure (XOff : Cardinal; YOff : Cardinal; ZOff : Cardinal; Width : Cardinal; Height : Cardinal; Depth : Cardinal; Format : DevILFormat; xType : DevILFormatType; Data : PByte); stdcall;
  ilTexImage: function (Width : Cardinal; Height : Cardinal; Depth : Cardinal; Bpp : Byte; Format : DevILFormat; xType : DevILType; Data : PByte) : Boolean; stdcall;


implementation

uses Setup, Quarkx, Logging;

var
  TimesLoaded: Integer;
  HDevIL  : HMODULE;

procedure LogError(x:string);
begin
  Log(LOG_CRITICAL, x);
  Windows.MessageBox(0, pchar(X), 'Fatal Error', MB_TASKMODAL or MB_ICONERROR or MB_OK);
end;

function InitDllPointer(DLLHandle: HMODULE;APIFuncname:PChar):Pointer;
begin
   result:= GetProcAddress(DLLHandle, APIFuncname);
   if result=Nil then
     LogError('API Func "'+APIFuncname+ '" not found in dlls/DevIL.dll');
end;

function LoadDevIL : Boolean;
begin
  if (TimesLoaded=0) then
  begin
    Result:=False;

    if (HDevIL = 0) then
    begin
      HDevIL := LoadLibrary('dlls/DevIL.dll');
      if HDevIL = 0 then
      begin
        LogError('Unable to load dlls/DevIL.dll');
        Exit;
      end;

      ilInit            := InitDllPointer(HDevIL, 'ilInit');
      ilShutDown        := InitDllPointer(HDevIL, 'ilShutDown');
      ilGetError        := InitDllPointer(HDevIL, 'ilGetError');
      ilGetBoolean      := InitDllPointer(HDevIL, 'ilGetBoolean');
      //ilGetBooleanv     := InitDllPointer(HDevIL, 'ilGetBooleanv');
      ilGetInteger      := InitDllPointer(HDevIL, 'ilGetInteger');
      //ilGetIntegerv     := InitDllPointer(HDevIL, 'ilGetIntegerv');
      ilSetInteger      := InitDllPointer(HDevIL, 'ilSetInteger');
      //ilGenImage        := InitDllPointer(HDevIL, 'ilGenImage');
      ilGenImages       := InitDllPointer(HDevIL, 'ilGenImages');
      ilBindImage       := InitDllPointer(HDevIL, 'ilBindImage');
      //ilDeleteImage     := InitDllPointer(HDevIL, 'ilDeleteImage');
      ilDeleteImages    := InitDllPointer(HDevIL, 'ilDeleteImages');
      ilLoadL           := InitDllPointer(HDevIL, 'ilLoadL');
      ilSaveL           := InitDllPointer(HDevIL, 'ilSaveL');
      //ilConvertImage    := InitDllPointer(HDevIL, 'ilConvertImage');
      //ilGetData         := InitDllPointer(HDevIL, 'ilGetData');
      //ilSetData         := InitDllPointer(HDevIL, 'ilSetData');
      ilCopyPixels      := InitDllPointer(HDevIL, 'ilCopyPixels');
      //ilSetPixels       := InitDllPointer(HDevIL, 'ilSetPixels');
      ilTexImage        := InitDllPointer(HDevIL, 'ilTexImage');
      //DanielPharos: If one of the API func's fails, we should stop loading, and return False!

      if ilGetInteger(IL_VERSION_NUM) < 168 then
      begin
        LogError('DevIL library version mismatch!');
        Exit;
      end;

      ilInit;

    end;

    TimesLoaded := 1;
    Result:=true;
  end
  else
  begin
    TimesLoaded := TimesLoaded + 1;
    Result := True;
  end;
end;

procedure UnloadDevIL(ForceUnload: boolean);
begin
  if (TimesLoaded = 1) or ForceUnload then
  begin
    if HDevIL <> 0 then
    begin
      ilShutdown;

      if FreeLibrary(HDevIL) = false then
        LogError('Unable to unload dlls/DevIL.dll');
      HDevIL := 0;

      ilInit                := nil;
      ilShutDown            := nil;
      ilGetError            := nil;
      ilGetBoolean          := nil;
      //ilGetBooleanv         := nil;
      ilGetInteger          := nil;
      //ilGetIntegerv         := nil;
      ilSetInteger          := nil;
      //ilGenImage            := nil;
      ilGenImages           := nil;
      ilBindImage           := nil;
      //ilDeleteImage         := nil;
      ilDeleteImages        := nil;
      ilLoadL               := nil;
      ilSaveL               := nil;
      //ilConvertImage        := nil;
      //ilGetData             := nil;
      //ilSetData             := nil;
      ilCopyPixels          := nil;
      //ilSetPixels           := nil;
      ilTexImage            := nil;
    end;

    TimesLoaded := 0;
  end
  else
    if TimesLoaded>1 then
      TimesLoaded := TimesLoaded - 1;
end;

{-------------------}

initialization
begin
  HDevIL:=0;
end;

end.
