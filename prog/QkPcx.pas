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
Revision 1.13  2007/11/21 00:06:22  danielpharos
BMP and PCX files are now also using DevIL and FreeImage to load and save. Also, fixed some memory-problems causing images to disappear.

Revision 1.12  2005/09/28 10:48:32  peter-b
Revert removal of Log and Header keywords

Revision 1.10  2002/03/07 19:16:02  decker_dk
Removed QImages, as it was just another name for QImage

Revision 1.9  2001/03/20 21:44:37  decker_dk
Updated copyright-header

Revision 1.8  2001/01/21 15:49:30  decker_dk
Moved RegisterQObject() and those things, to a new unit; QkObjectClassList.

Revision 1.7  2001/01/15 19:20:37  decker_dk
Replaced the name: NomClasseEnClair -> FileObjectDescriptionText

Revision 1.6  2000/07/18 19:38:00  decker_dk
Englishification - Big One This Time...

Revision 1.5  2000/07/09 13:20:44  decker_dk
Englishification and a little layout

Revision 1.4  2000/06/03 10:46:49  alexander
added cvs headers
}


unit QkPcx;

interface

uses Classes, QkImages, QkPixelSet, QkObjects, QkFileObjects, QkDevIL, QkFreeImage;

type
 QPcx = class(QImage)
        protected
          procedure SaveFile(Info: TInfoEnreg1); override;
          procedure LoadFile(F: TStream; FSize: Integer); override;
        public
          class function TypeInfo: String; override;
          class procedure FileObjectClassInfo(var Info: TFileObjectClassInfo); override;
        end;

 {------------------------}

implementation

uses SysUtils, Setup, Quarkx, QkObjectClassList, Game, Logging, Windows;

var
  DevILLoaded: Boolean;
  FreeImageLoaded: Boolean;

procedure Fatal(x:string);
begin
  Log(LOG_CRITICAL,'Error during operation on PCX file: %s',[x]);
  Windows.MessageBox(0, pchar(X), PChar(LoadStr1(401)), MB_TASKMODAL or MB_ICONERROR or MB_OK);
  Raise Exception.Create(x);
end;

class function QPcx.TypeInfo: String;
begin
 TypeInfo:='.pcx';
end;

class procedure QPcx.FileObjectClassInfo(var Info: TFileObjectClassInfo);
begin
 inherited;
 Info.FileObjectDescriptionText:=LoadStr1(5137);
 Info.FileExt:=781;
 Info.WndInfo:=[wiWindow];
end;

procedure QPcx.LoadFile(F: TStream; FSize: Integer);
const
  Spec1 = 'Image1=';
//  Spec2 = 'Pal=';
  Spec3 = 'Alpha=';
type
  PRGB = ^TRGB;
  TRGB = array[0..2] of Byte;
  PRGBA = ^TRGBA;
  TRGBA = array[0..3] of Byte;
var
  RawBuffer: String;
  Source, Source2: PByte;
  AlphaData, ImgData: String;
  DestAlpha, DestImg: PChar;
  I, J: Integer;
  LibraryToUse: string;
  Setup: QObject;

  //DevIL:
  DevILImage: Cardinal;

  //FreeImage:
  FIBuffer: FIMEMORY;
  FIImage, FIConvertedImage: FIBITMAP;
  Pitch: Integer;

  Width, Height: Integer;
  PaddingSource, PaddingDest: Integer;
  V: array[1..2] of Single;
begin
  Log(LOG_VERBOSE,'Loading PCX file: %s',[self.name]);;
  case ReadFormat of
  1: begin  { as stand-alone file }
    Setup:=SetupSubSet(ssFiles, 'PCX');
    LibraryToUse:=Setup.Specifics.Values['LoadLibrary'];
    if LibraryToUse='DevIL' then
    begin
      if (not DevILLoaded) then
      begin
        if not LoadDevIL then
          Raise EErrorFmt(5730, ['DevIL library', GetLastError]);
        DevILLoaded:=true;
      end;

      SetLength(RawBuffer, F.Size);
      F.Seek(0, 0);
      F.ReadBuffer(Pointer(RawBuffer)^, Length(RawBuffer));

      ilGenImages(1, @DevILImage);
      CheckDevILError(ilGetError);
      ilBindImage(DevILImage);
      CheckDevILError(ilGetError);

      ilOriginFunc(IL_ORIGIN_LOWER_LEFT);
      CheckDevILError(ilGetError);
      ilEnable(IL_ORIGIN_SET);
      CheckDevILError(ilGetError);

      if ilLoadL(IL_PCX, Pointer(RawBuffer), Length(RawBuffer))=false then
      begin
        ilDeleteImages(1, @DevILImage);
        Fatal('Unable to load PCX file. Call to ilLoadL failed. Please make sure the file is a valid PCX file, and not damaged or corrupt.');
      end;
      CheckDevILError(ilGetError);

      Width:=ilGetInteger(IL_IMAGE_WIDTH);
      CheckDevILError(ilGetError);
      Height:=ilGetInteger(IL_IMAGE_HEIGHT);
      CheckDevILError(ilGetError);
      //DanielPharos: 46340 squared is just below the integer max value.
      if (Width>46340) or (Height>46340) then
      begin
        ilDeleteImages(1, @DevILImage);
        Fatal('Unable to load PCX file. Picture is too large.');
      end;
      V[1]:=Width;
      V[2]:=Height;
      SetFloatsSpec('Size', V);

      //This is the padding for the 'Image1'-RGB array
      PaddingDest:=((((Width * 24) + 31) div 32) * 4) - (Width * 3);

      if ilHasAlpha then
      begin
        //Allocate quarks image buffers
        ImgData:=Spec1;
        AlphaData:=Spec3;
        SetLength(ImgData,   Length(Spec1) + ((Width * 3) + PaddingDest) * Height); //RGB buffer
        SetLength(AlphaData, Length(Spec3) + (Width * Height)); //alpha buffer

        GetMem(Source, Width * Height * 4);
        ilCopyPixels(0, 0, 0, Width, Height, 1, IL_RGBA, IL_UNSIGNED_BYTE, Source);
        CheckDevILError(ilGetError);
        PaddingSource:=0;

        DestImg:=PChar(ImgData) + Length(Spec1);
        DestAlpha:=PChar(AlphaData) + Length(Spec3);
        Source2:=Source;
        for J:=0 to Height-1 do
        begin
          for I:=0 to Width-1 do
          begin
            PRGB(DestImg)^[2]:=PRGBA(Source2)^[0];
            PRGB(DestImg)^[1]:=PRGBA(Source2)^[1];
            PRGB(DestImg)^[0]:=PRGBA(Source2)^[2];
            PByte(DestAlpha)^:=PRGBA(Source2)^[3];
            Inc(Source2, 4);
            Inc(DestImg, 3);
            Inc(DestAlpha, 1);
          end;
          Inc(Source2, PaddingSource);
          for I:=0 to PaddingDest-1 do
          begin
            DestImg^:=#0;
            Inc(DestImg, 1);
          end;
        end;
        FreeMem(Source);

        Specifics.Add(AlphaData);
        Specifics.Add(ImgData);
      end
      else
      begin
        //Allocate quarks image buffers
        ImgData:=Spec1;
        SetLength(ImgData,   Length(Spec1) + ((Width * 3) + PaddingDest) * Height); //RGB buffer

        GetMem(Source, Width * Height * 3);
        ilCopyPixels(0, 0, 0, Width, Height, 1, IL_RGB, IL_UNSIGNED_BYTE, Source);
        CheckDevILError(ilGetError);
        PaddingSource:=0;

        DestImg:=PChar(ImgData) + Length(Spec1);
        Source2:=Source;
        for J:=0 to Height-1 do
        begin
          for I:=0 to Width-1 do
          begin
            PRGB(DestImg)^[2]:=PRGB(Source2)^[0];
            PRGB(DestImg)^[1]:=PRGB(Source2)^[1];
            PRGB(DestImg)^[0]:=PRGB(Source2)^[2];
            Inc(Source2, 3);
            Inc(DestImg, 3);
          end;
          Inc(Source2, PaddingSource);
          for I:=0 to PaddingDest-1 do
          begin
            DestImg^:=#0;
            Inc(DestImg, 1);
          end;
        end;
        FreeMem(Source);

        Specifics.Add(ImgData);
      end;

      ilDisable(IL_ORIGIN_SET);
      CheckDevILError(ilGetError);
      ilDeleteImages(1, @DevILImage);
      CheckDevILError(ilGetError);

    end
    else if LibraryToUse='FreeImage' then
    begin
      if (not FreeImageLoaded) then
      begin
        if not LoadFreeImage then
          Raise EErrorFmt(5730, ['FreeImage library', GetLastError]);
        FreeImageLoaded:=true;
      end;

      SetLength(RawBuffer, F.Size);
      F.Seek(0, 0);
      F.ReadBuffer(Pointer(RawBuffer)^, Length(RawBuffer));

      FIBuffer := FreeImage_OpenMemory(Pointer(RawBuffer), Length(RawBuffer));
      FIImage := FreeImage_LoadFromMemory(FIF_PCX, FIBuffer, PCX_DEFAULT);

      Width:=FreeImage_GetWidth(FIImage);
      Height:=FreeImage_GetHeight(FIImage);
      //DanielPharos: 46340 squared is just below the integer max value.
      if (Width>46340) or (Height>46340) then
      begin
        FreeImage_Unload(FIImage);
        FreeImage_CloseMemory(FIBuffer);
        Fatal('Unable to load PCX file. Picture is too large.');
      end;
      V[1]:=Width;
      V[2]:=Height;
      SetFloatsSpec('Size', V);

      //This is the padding for the 'Image1'-RGB array
      PaddingDest:=((((Width * 24) + 31) div 32) * 4) - (Width * 3);

      if FreeImage_IsTransparent(FIImage) then
      begin
        //Allocate quarks image buffers
        ImgData:=Spec1;
        AlphaData:=Spec3;
        SetLength(ImgData,   Length(Spec1) + ((Width * 3) + PaddingDest) * Height); //RGB buffer
        SetLength(AlphaData, Length(Spec3) + (Width * Height)); //alpha buffer

        FIConvertedImage:=FreeImage_ConvertTo32Bits(FIImage);
        Pitch:=FreeImage_GetPitch(FIConvertedImage);
        GetMem(Source, Height * Pitch);
        FreeImage_ConvertToRawBits(Source, FIConvertedImage, Pitch, 32, FI_RGBA_RED_MASK, FI_RGBA_GREEN_MASK, FI_RGBA_BLUE_MASK, true);
        PaddingSource:=Pitch - (Width * 4);

        DestImg:=PChar(ImgData) + Length(Spec1);
        DestAlpha:=PChar(AlphaData) + Length(Spec3);
        Source2:=Source;
        for J:=0 to Height-1 do
        begin
          for I:=0 to Width-1 do
          begin
            PRGB(DestImg)^[0]:=PRGBA(Source2)^[0];
            PRGB(DestImg)^[1]:=PRGBA(Source2)^[1];
            PRGB(DestImg)^[2]:=PRGBA(Source2)^[2];
            PByte(DestAlpha)^:=PRGBA(Source2)^[3];
            Inc(Source2, 4);
            Inc(DestImg, 3);
            Inc(DestAlpha, 1);
          end;
          Inc(Source2, PaddingSource);
          for I:=0 to PaddingDest-1 do
          begin
            DestImg^:=#0;
            Inc(DestImg, 1);
          end;
        end;

        Specifics.Add(AlphaData);
        Specifics.Add(ImgData);
      end
      else
      begin
        //Allocate quarks image buffers
        ImgData:=Spec1;
        SetLength(ImgData,   Length(Spec1) + ((Width * 3) + PaddingDest) * Height); //RGB buffer

        FIConvertedImage:=FreeImage_ConvertTo24Bits(FIImage);
        Pitch:=FreeImage_GetPitch(FIConvertedImage);
        GetMem(Source, Height * Pitch);
        FreeImage_ConvertToRawBits(Source, FIConvertedImage, Pitch, 24, FI_RGBA_RED_MASK, FI_RGBA_GREEN_MASK, FI_RGBA_BLUE_MASK, true);
        PaddingSource:=Pitch - (Width * 3);

        DestImg:=PChar(ImgData) + Length(Spec1);
        Source2:=Source;
        for J:=0 to Height-1 do
        begin
          for I:=0 to Width-1 do
          begin
            PRGB(DestImg)^[0]:=PRGB(Source2)^[0];
            PRGB(DestImg)^[1]:=PRGB(Source2)^[1];
            PRGB(DestImg)^[2]:=PRGB(Source2)^[2];
            Inc(Source2, 3);
            Inc(DestImg, 3);
          end;
          Inc(Source2, PaddingSource);
          for I:=0 to PaddingDest-1 do
          begin
            DestImg^:=#0;
            Inc(DestImg, 1);
          end;
        end;

        Specifics.Add(ImgData);
      end;

      FreeMem(Source);
      FreeImage_Unload(FIConvertedImage);
      FreeImage_Unload(FIImage);
      FreeImage_CloseMemory(FIBuffer);
    end
    else
    begin
      Fatal('Unable to load PCX file. No valid loading library selected.');
    end;
  end;
  else
    inherited;
  end;
end;

procedure QPcx.SaveFile(Info: TInfoEnreg1);
type
  PRGB = ^TRGB;
  TRGB = array[0..2] of Byte;
  PRGBA = ^TRGBA;
  TRGBA = array[0..3] of Byte;
var
  PSD: TPixelSetDescription;
  RawBuffer: String;
  RawData, RawData2: PByte;
  SourceImg, SourceAlpha, pSourceImg, pSourceAlpha: PChar;
  LibraryToUse: string;
  Setup: QObject;

  //DevIL:
  DevILImage: Cardinal;
  ImageBpp: Byte;
  ImageFormat: DevILFormat;

  //FreeImage:
  FIBuffer: FIMEMORY;
  FIImage: FIBITMAP;
  Pitch: Integer;
  FIbpp: Cardinal;

  Width, Height: Integer;
  PaddingSource, PaddingDest: Integer;
  I, J: Integer;
  OutputSize: Cardinal;
begin
 Log(LOG_VERBOSE,'Saving PCX file: %s',[self.name]);
 with Info do
  case Format of
  1:  begin  { as stand-alone file }
    Setup:=SetupSubSet(ssFiles, 'PCX');
    LibraryToUse:=Setup.Specifics.Values['SaveLibrary'];
    if LibraryToUse='DevIL' then
    begin
      if (not DevILLoaded) then
      begin
        if not LoadDevIL then
          Raise EErrorFmt(5730, ['DevIL library', GetLastError]);
        DevILLoaded:=true;
      end;

      PSD:=Description;
      Width:=PSD.size.x;
      Height:=PSD.size.y;

      //This is the padding for the 'Image1'-RGB array
      PaddingSource:=((((Width * 24) + 31) div 32) * 4) - (Width * 3);

      if PSD.AlphaBits=psa8bpp then
      begin
        ImageBpp:=4;
        ImageFormat:=IL_RGBA;
        PaddingDest:=0;

        GetMem(RawData, ((Width * 4) + PaddingDest) * Height);
        RawData2:=RawData;

        SourceImg:=PChar(PSD.Data);
        SourceAlpha:=PChar(PSD.AlphaData);
        pSourceImg:=SourceImg;
        pSourceAlpha:=SourceAlpha;
        for J:=0 to Height-1 do
        begin
          for I:=0 to Width-1 do
          begin
            PRGBA(RawData2)^[2]:=PRGB(pSourceImg)^[0];
            PRGBA(RawData2)^[1]:=PRGB(pSourceImg)^[1];
            PRGBA(RawData2)^[0]:=PRGB(pSourceImg)^[2];
            PRGBA(RawData2)^[3]:=PByte(pSourceAlpha)^;
            Inc(pSourceImg, 3);
            Inc(pSourceAlpha, 1);
            Inc(RawData2, 4);
          end;
          Inc(pSourceImg, PaddingSource);
          for I:=0 to PaddingDest-1 do
          begin
            RawData2^:=0;
            Inc(RawData2, 1);
          end;
        end;
      end
      else
      begin
        ImageBpp:=3;
        ImageFormat:=IL_RGB;
        PaddingDest:=0;

        GetMem(RawData, ((Width * 3) + PaddingDest) * Height);
        RawData2:=RawData;

        SourceImg:=PChar(PSD.Data);
        pSourceImg:=SourceImg;
        for J:=0 to Height-1 do
        begin
          for I:=0 to Width-1 do
          begin
            PRGB(RawData2)^[2]:=PRGB(pSourceImg)^[0];
            PRGB(RawData2)^[1]:=PRGB(pSourceImg)^[1];
            PRGB(RawData2)^[0]:=PRGB(pSourceImg)^[2];
            Inc(pSourceImg, 3);
            Inc(RawData2, 3);
          end;
          Inc(pSourceImg, PaddingSource);
          for I:=0 to PaddingDest-1 do
          begin
            RawData2^:=0;
            Inc(RawData2, 1);
          end;
        end;
      end;

      ilGenImages(1, @DevILImage);
      CheckDevILError(ilGetError);
      ilBindImage(DevILImage);
      CheckDevILError(ilGetError);

      if ilTexImage(Width, Height, 1, ImageBpp, ImageFormat, IL_UNSIGNED_BYTE, RawData)=false then
      begin
        ilDeleteImages(1, @DevILImage);
        Fatal('Unable to save PCX file. Call to ilTexImage failed.');
      end;

      FreeMem(RawData);

      //DanielPharos: How do we retrieve the correct value of the lump?
      OutputSize:=Width*Height*10;
      SetLength(RawBuffer,OutputSize);

      OutputSize:=ilSaveL(IL_PCX, Pointer(RawBuffer), OutputSize);
      CheckDevILError(ilGetError);
      if OutputSize=0 then
      begin
        ilDeleteImages(1, @DevILImage);
        Fatal('Unable to save PCX file. Call to ilSaveL failed.');
      end;

      F.WriteBuffer(Pointer(RawBuffer)^,OutputSize);

      ilDeleteImages(1, @DevILImage);
      CheckDevILError(ilGetError);
    end
    else if LibraryToUse='FreeImage' then
    begin
      if (not FreeImageLoaded) then
      begin
        if not LoadFreeImage then
          Raise EErrorFmt(5730, ['FreeImage library', GetLastError]);
        FreeImageLoaded:=true;
      end;

      PSD:=Description;
      Width:=PSD.size.x;
      Height:=PSD.size.y;

      //This is the padding for the 'Image1'-RGB array
      PaddingSource:=((((Width * 24) + 31) div 32) * 4) - (Width * 3);

      if PSD.AlphaBits=psa8bpp then
      begin
        FIBpp:=32;
        PaddingDest:=((((Width * 32) + 31) div 32) * 4) - (Width * 4);

        GetMem(RawData, ((Width * 4) + PaddingDest) * Height);
        RawData2:=RawData;

        SourceImg:=PChar(PSD.Data);
        SourceAlpha:=PChar(PSD.AlphaData);
        pSourceImg:=SourceImg;
        pSourceAlpha:=SourceAlpha;
        for J:=0 to Height-1 do
        begin
          for I:=0 to Width-1 do
          begin
            PRGBA(RawData2)^[0]:=PRGB(pSourceImg)^[0];
            PRGBA(RawData2)^[1]:=PRGB(pSourceImg)^[1];
            PRGBA(RawData2)^[2]:=PRGB(pSourceImg)^[2];
            PRGBA(RawData2)^[3]:=PByte(pSourceAlpha)^;
            Inc(pSourceImg, 3);
            Inc(pSourceAlpha, 1);
            Inc(RawData2, 4);
          end;
          Inc(pSourceImg, PaddingSource);
          for I:=0 to PaddingDest-1 do
          begin
            RawData2^:=0;
            Inc(RawData2, 1);
          end;
        end;
      end
      else
      begin
        FIBpp:=24;
        PaddingDest:=((((Width * 24) + 31) div 32) * 4) - (Width * 3);

        GetMem(RawData, ((Width * 3) + PaddingDest) * Height);
        RawData2:=RawData;

        SourceImg:=PChar(PSD.Data);
        pSourceImg:=SourceImg;
        for J:=0 to Height-1 do
        begin
          for I:=0 to Width-1 do
          begin
            PRGB(RawData2)^[0]:=PRGB(pSourceImg)^[0];
            PRGB(RawData2)^[1]:=PRGB(pSourceImg)^[1];
            PRGB(RawData2)^[2]:=PRGB(pSourceImg)^[2];
            Inc(pSourceImg, 3);
            Inc(RawData2, 3);
          end;
          Inc(pSourceImg, PaddingSource);
          for I:=0 to PaddingDest-1 do
          begin
            RawData2^:=0;
            Inc(RawData2, 1);
          end;
        end;
      end;

      Pitch:=Width*Integer(FIBpp div 8) + PaddingDest;
      FIImage:=FreeImage_ConvertFromRawBits(RawData, width, height, pitch, FIBpp, FI_RGBA_RED_MASK, FI_RGBA_GREEN_MASK, FI_RGBA_BLUE_MASK, true);

      FreeMem(RawData);

      FIBuffer := FreeImage_OpenMemory(nil, 0);
      if FreeImage_SaveToMemory(FIF_PCX, FIImage, FIBuffer, PCX_DEFAULT)=false then
      begin
        FreeImage_CloseMemory(FIBuffer);
        Fatal('Unable to save PCX file. Call to FreeImage_SaveToMemory failed.');
      end;

      OutputSize:=FreeImage_TellMemory(FIBuffer);
      SetLength(RawBuffer,OutputSize);
      if FreeImage_SeekMemory(FIBuffer, 0, SEEK_SET)=false then
      begin
        FreeImage_CloseMemory(FIBuffer);
        Fatal('Unable to save PCX file. Call to FreeImage_SeekMemory failed.');
      end;
      OutputSize:=FreeImage_ReadMemory(Pointer(RawBuffer), 1, OutputSize, FIBuffer);
      if OutputSize=0 then
      begin
        FreeImage_CloseMemory(FIBuffer);
        Fatal('Unable to save PCX file. Call to FreeImage_ReadMemory failed.');
      end;

      F.WriteBuffer(Pointer(RawBuffer)^,OutputSize);

      FreeImage_Unload(FIImage);
      FreeImage_CloseMemory(FIBuffer);
    end
    else
      Fatal('Unable to save PCX file. No valid saving library selected.');
  end
  else
    inherited;
  end;
end;

 {------------------------}

initialization
  RegisterQObject(QPcx, 'l');

finalization
  if DevILLoaded then
    UnloadDevIl(false);
  if FreeImageLoaded then
    UnloadFreeImage(false);
end.
