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
Revision 1.8  2005/09/28 10:49:02  peter-b
Revert removal of Log and Header keywords

Revision 1.6  2001/06/05 18:42:41  decker_dk
Prefixed interface global-variables with 'g_', so its clearer that one should not try to find the variable in the class' local/member scope, but in global-scope maybe somewhere in another file.

Revision 1.5  2001/03/20 21:36:53  decker_dk
Updated copyright-header

Revision 1.4  2001/02/05 20:03:52  aiv
Fixed stupid bug when displaying texture vertices

Revision 1.3  2001/02/01 22:00:56  aiv
Remove Vertex code now in python.

Revision 1.2  2001/01/21 15:51:31  decker_dk
Moved RegisterQObject() and those things, to a new unit; QkObjectClassList.

Revision 1.1  2000/10/11 18:58:21  aiv
Initial Release
}

unit qkskindrawobject;

interface

uses Windows, SysUtils, Classes, QkObjects, Qk3D, QkForm, Graphics,
     QkImages, qmath, QkTextures, PyMath, Python, dialogs, QkMdlObject;

type
  QSkinDrawObject = class(QMdlObject)
  public
    class function TypeInfo: String; override;
    procedure Dessiner; override;
    procedure CouleurDessin(var C: TColor);
  end;

implementation

uses EdSoftware, PyMapView, quarkx, travail, pyobjects, QkModelRoot, qkComponent, setup, QkObjectClassList;

procedure QSkinDrawObject.CouleurDessin;
var
  S: String;
begin
  S:=Specifics.Values['_color'];
  if S<>'' then begin
    C:=clNone;
    try
      C:=vtocol(ReadVector(S));
    except
      {rien}
    end;
  end;
end;

class function QSkinDrawObject.Typeinfo:string;
begin
  result:=':sdo';
end;

// Modified from QuArK 4.08b source (qmmdl_?.pas) - i knew that would
// come in useful somewhere...

type
  TTriPoint = array[0..2] of tpoint;
  PTriTable = ^TTriPoint;

Function ReadTrianglePosition(Comp: QComponent; var Tris: PTriTable): Integer;
var
  I, j: Integer;
  skin_dims: array[1..2] of single;
  numtris: Integer;
  triangles: PComponentTris;
  aTris: PTriTable;
begin
  comp.GetFloatsSpec('skinsize', skin_dims);
  numtris:=comp.Triangles(triangles);
  GetMem(Tris, sizeof(TTriPoint)*NumTris);
  aTris:=Tris;
  result:=numtris;
  for I:=0 to numtris-1 do begin
    for j:=0 to 2 do begin
      aTris^[j].X:=Triangles^[j].S;
      aTris^[j].Y:=Triangles^[j].T;
    end;
    inc(aTris);
    inc(Triangles);
  end;
end;

type
  TTableauInt = Integer;
  PTableauInt = ^TTableauInt;

procedure QSkinDrawObject.Dessiner;
var
  Tris, Tris_O: PTriTable;
  I, J: Integer;
  numtris: integer;
  c: qcomponent;
  va: tvect;
  pa, pa_o: PPointProj;
begin
  if not(CCoord is T2DCoordinates) then exit;
  if not (md2dOnly in g_DrawInfo.ModeDessin) then exit;
  c:=QComponent(Self.FParent);
  if (c = nil) or not(c is QComponent) then
    Raise Exception.Create('QSkinDrawObject.Dessiner - Internal Error: C');
  numtris:=ReadTrianglePosition(c, Tris_O);
  //  draw 'c.currentskin' on canvas
    { don't know how }
  //  draw net connecting vertices
  try
    tris:=tris_o;
    getmem(pa_o, sizeof(TPOintProj)*3);
    for i:=0 to numtris-1 do begin
      pa:=pa_o;
      for j:=0 to 2 do begin
        va.x:=tris^[j].X;
        va.y:=tris^[j].Y;
        va.z:=0;
        pA^:=CCoord.Proj(vA);
        inc(pa);
      end;
      CCoord.Polygon95f(pa_o^,3, false);
      inc(tris);
    end;
    freemem(pa_o);
  finally
    FreeMem(Tris_o);
  end;
end;

initialization
  RegisterQObject(QSkinDrawObject, 'a');
end.
