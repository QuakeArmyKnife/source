(**************************************************************************
QuArK -- Quake Army Knife -- 3D game editor
Copyright (C) 1996-99 Armin Rigo

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

Contact the author Armin Rigo by e-mail: arigo@planetquake.com
or by mail: Armin Rigo, La Cure, 1854 Leysin, Switzerland.
See also http://www.planetquake.com/quark
**************************************************************************)

{

$Header$
 ----------- REVISION HISTORY ------------
$Log$
Revision 1.11  2001/03/09 00:01:31  aiv
added texture linking to entity tool.

Revision 1.10  2001/03/08 23:22:53  aiv
entity tool finished completly i think.

Revision 1.9  2001/01/21 15:49:48  decker_dk
Moved RegisterQObject() and those things, to a new unit; QkObjectClassList.

Revision 1.8  2001/01/15 19:21:27  decker_dk
Replaced the name: NomClasseEnClair -> FileObjectDescriptionText

Revision 1.7  2000/08/25 17:57:24  decker_dk
Layout indenting

Revision 1.6  2000/07/18 19:38:01  decker_dk
Englishification - Big One This Time...

Revision 1.5  2000/07/16 16:34:51  decker_dk
Englishification

Revision 1.4  2000/07/09 13:20:44  decker_dk
Englishification and a little layout

Revision 1.3  2000/06/03 10:46:49  alexander
added cvs headers


}


unit QkQuakeCtx;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  QkObjects, QkFileObjects, TB97, QkFormVw, Python, PyObjects;

type
 QQuakeCtx = class(QFormObject)
             protected
               function GetConfigStr1: String; override;
             public
               class function TypeInfo: String; override;
               procedure ObjectState(var E: TEtatObjet); override;
               class procedure FileObjectClassInfo(var Info: TFileObjectClassInfo); override;
               Procedure MakeAddonFromQctx;
               function PyGetAttr(attr: PChar) : PyObject; override;
             end;

 QFormContext = class(QQuakeCtx)
             protected
               function GetConfigStr1: String; override;
             public
               class function TypeInfo: String; override;
               class procedure FileObjectClassInfo(var Info: TFileObjectClassInfo); override;
             end;
 {------------------------}

function GetQuakeContext: TQList;
function BuildQuakeCtxObjects(nClass: QObjectClass; const nName: String) : TQList;
procedure ClearQuakeContext;

function OpacityFromFlags(Flags: Integer) : Integer;
function OpacityToFlags(Flags: Integer; Alpha: Integer) : Integer;

 {------------------------}

implementation

uses Setup, QkGroup, Quarkx, QkObjectClassList, QuickWal, QkPak, QkBSP, ToolBox1,
     ToolBoxGroup, ExtraFunctionality, Game, QkMapObjects, FormCfg, QkExplorer,
     QkForm;

 {------------------------}

type
 TTexOpacityInfo = record
                    Loaded: Boolean;
                    Count: Byte;
                    Reserved1, Reserved2: Byte;
                    Opacity: array[0..31] of Byte;
                   end;

var
 TInfo: TTexOpacityInfo;

procedure LoadTInfo;
var
 I, J, K, L, M: Integer;
 Li: TQList;
 Val32: array[0..63] of Single;
begin
 FillChar(TInfo.Opacity, SizeOf(TInfo.Opacity), 255);
 TInfo.Loaded:=True;
 Li:=GetQuakeContext;
 for J:=0 to Li.Count-1 do
  begin
   K:=Li[J].GetFloatsSpecPartial('TexFlagsTransparent', Val32);
   for I:=0 to K div 2 - 1 do
    begin
     M:=Round(Val32[I*2]);
     L:=0;
     while not Odd(M) and (M<>0) do
      begin
       Inc(L);
       M:=M shr 1;
      end;
     if M=1 then
      begin
       M:=Round((1-Val32[I*2+1])*255);
       if M<0 then M:=0 else if M>255 then M:=255;
       TInfo.Opacity[L]:=M;
      end;
    end;
  end;
end;

function OpacityFromFlags(Flags: Integer) : Integer;
var
 L: Integer;
begin
 Result:=255;
 if Flags=0 then Exit;

 if not TInfo.Loaded then
  LoadTInfo;

 L:=0;
 repeat
  if Odd(Flags) and (TInfo.Opacity[L]<Result) then
   Result:=TInfo.Opacity[L];
  Flags:=Flags shr 1;
  Inc(L);
 until Flags=0;
end;

function OpacityToFlags(Flags: Integer; Alpha: Integer) : Integer;
var
 L, Best, DistMin, Dist: Integer;
begin
 if not TInfo.Loaded then
  LoadTInfo;
 Best:=0;
 DistMin:=255-Alpha;
 for L:=Low(TInfo.Opacity) to High(TInfo.Opacity) do
  if TInfo.Opacity[L]<255 then
   begin
    Dist:=Abs(Alpha-Integer(TInfo.Opacity[L]));
    if Dist<DistMin then
     begin
      DistMin:=Dist;
      Best:=1 shl L;
     end;
    Flags:=Flags and not (1 shl L);
   end;
 Result:=Flags or Best;
end;

 {------------------------}

var
 QuakeContext: TQList = Nil;

procedure ClearQuakeContext;
begin
 QuakeContext.Free;
 QuakeContext:=Nil;
 TInfo.Loaded:=False;
end;

function GetQuakeContext: TQList;
var
 Addons: QFileObject;
 I: Integer;
 Q: QObject;
 S: String;
begin
 if QuakeContext=Nil then
  begin
   Addons:=MakeAddOnsList;
   try
    QuakeContext:=TQList.Create;
    Addons.FindAllSubObjects('', QQuakeCtx, Nil, QuakeContext);
    for I:=QuakeContext.Count-1 downto 0 do
     begin
      Q:=QuakeContext[I];
      Q.Acces;
      if not GameModeOk((Q as QQuakeCtx).ObjectGameCode) then
       begin
        while (Q<>Nil) and (Q.Flags and ofFileLink = 0) do
         Q:=Q.FParent;
        if (Q=Nil) or not (Q is QFileObject) then
         S:=LoadStr1(5552)
        else
         S:=QFileObject(Q).Filename;
        GlobalWarning(FmtLoadStr1(5582, [S, SetupGameSet.Name, QuakeContext[I].Specifics.Values['Game']]));
        QuakeContext.Delete(I);
       end;
     end;
   finally
    Addons.AddRef(-1);
   end;
  end;
 GetQuakeContext:=QuakeContext;
end;

function BuildQuakeCtxObjects(nClass: QObjectClass; const nName: String) : TQList;
var
 L: TQList;
 I, J: Integer;
 Q, Q1: QObject;
begin
 Result:=TQList.Create;
 try
  L:=GetQuakeContext;
  for I:=0 to L.Count-1 do
   begin
    Q:=L[I];
    for J:=0 to Q.SubElements.Count-1 do
     begin
      Q1:=Q.SubElements[J];
      if (Q1 is nClass)
      and ((nName='') or (CompareText(Q1.Name, nName) = 0)) then
       begin
        {Q1.Acces;}
        Result.Add(Q1);
       end;
     end;
   end;
 except
  Result.Free;
  Raise;
 end;
end;

 {------------------------}

class function QQuakeCtx.TypeInfo;
begin
 TypeInfo:='.qctx';
end;

function QQuakeCtx.GetConfigStr1: String;
begin
 Result:='QuakeCtx';
end;

procedure QQuakeCtx.ObjectState(var E: TEtatObjet);
begin
 inherited;
 E.IndexImage:=iiQCtx;
 E.MarsColor:=clMaroon;
end;

class procedure QQuakeCtx.FileObjectClassInfo(var Info: TFileObjectClassInfo);
begin
 inherited;
 Info.FileObjectDescriptionText:=LoadStr1(5155);
{Info.FileExt:=779;
 Info.WndInfo:=[wiWindow];}
end;

Function OpenFiles(dir: String; L: TStringList): TQList;
var
  i: Integer;
begin
  Result:=TQList.Create;
  For i:=0 to l.count-1 do
  begin
    Result.Add(ExactFileLink(dir+'\'+l.strings[i], nil, false));
  end;
end;

Function FindFiles(dir, filter: String): TQList;
var
  f: TSearchRec;
  f_e: Integer;
begin
  Result:=TQList.Create;
  f_e:=FindFirst(filter, faAnyFile, F);
  while f_e=0 do
  begin
    Result.add(ExactFileLink(dir+'\'+f.name, nil, false));
    f_e:=FindNext(F);
  end;
end;

function qMakeAddonFromQctx(self, args: PyObject) : PyObject; cdecl;
begin
   with QkObjFromPyObj(self) as QQuakeCtx do
     MakeAddonFromQctx;
   Result:=PyNoResult;
end;

const
  MethodTable: array[0..0] of TyMethodDef =
   ((ml_name: 'makeaddonfromqctx';      ml_meth: qMakeAddonFromQctx;      ml_flags: METH_VARARGS));

function QQuakeCtx.PyGetAttr(attr: PChar) : PyObject;
var
  I: Integer;
begin
  Result:=inherited PyGetAttr(attr);
  if Result<>Nil then Exit;
  for I:=Low(MethodTable) to High(MethodTable) do
  begin
    if StrComp(attr, MethodTable[I].ml_name) = 0 then
    begin
      Result:=PyCFunction_New(MethodTable[I], @PythonObj);
      Exit;
    end;
  end;
end;

Procedure QQuakeCtx.MakeAddonFromQctx;
var
  i,j,k,l: integer;
  tb: string;
  // Objects for getting bsp list
  paks: TQList;
  bsps: TQList;
  Pak, ExistingAddons: QFileObject;
  p_f: QPakFolder;
  bsp: QBsp;
  NewAddonsList: TQList;
  // Objects for creating new addon
  addonRoot: QFileObject;
  TBX, TexRoot: QToolBox;
  entityTBX: QToolBoxGroup;
  entityTBX_2: QToolBoxGroup;
  Group: QToolBoxGroup;
  OldEntity, Entity: TTreeMapSpec;
  Entities, Forms: TQList;
  entityForms:QFormContext;
  OldForm, Form: QFormCfg;
  OldFormEl, FormEl, TexFolders: QObject;
  // updating tree view at end
  F, FF: TQForm1;
  (*
    Get all .bsp files in & out of pak's
  *)
  procedure GetBSPFiles;
  var
    i,j: Integer;
    dir: String;
  begin
    dir:=IncludeTrailingBackslash(QuakeDir)+Specifics.Values['GameDir'];
    paks:=OpenFiles(dir, ListPakFiles(dir));
    bsps:=FindFiles(dir+'\maps', IncludeTrailingBackslash(QuakeDir)+Specifics.Values['GameDir']+'\maps\*.bsp');
    for i:=0 to paks.count-1 do
    begin
      pak:=QFileObject(paks[i]);
      pak.acces;
      p_f:=QPakFolder(pak.FindSubObject('maps', QPakFolder, QPakFolder));
      if p_f=nil then continue;
      for j:=0 to p_f.subelements.count-1 do
      begin
        if p_f.subelements[j] is QBsp then
          bsps.add(p_f.subelements[i]);
      end;
    end;
  end;
  (*
    Go through list of .bsps and create addon based on each
  *)
  Procedure CreateAddons;
  var
    i: integer;
  begin
    ExistingAddons:=MakeAddonsList;
    for i:=0 to bsps.count-1 do
    begin
      if not (bsps[i] is QBsp) then
        raise exception.create('Error: bsp list contains non QBSP object!');
      bsp := QBsp(bsps[i]);
      NewAddonsList.Add(bsp.CreateAddonFromEntities(ExistingAddons));
    end;
    ExistingAddons.AddRef(-1);
  end;
begin
  NewAddonsList:=TQList.Create; // a list of AddonRoot (.qrk objects)
  GetBSPFiles;
  CreateAddons;

  addonRoot:=QFileObject(FParent);
  if addonRoot = nil then
  begin
    raise Exception.Create('addonRoot = nil');
  end;

  TBX:=QToolBox.Create('Toolbox Folders', addonRoot);
  addonRoot.Subelements.Add(TBX);
  TBX.Specifics.Add('ToolBox=New map items...');
  EntityTBX:=QToolBoxGroup.Create(Format('%s', [Specifics.Values['GameDir']]), TBX);
  TBX.Subelements.Add(EntityTBX);
  TBX.Specifics.Add('Root='+EntityTBX.GetFullName);
  EntityTBX_2:=QToolBoxGroup.Create(Format('%s entities',[Specifics.Values['GameDir']]), EntityTBX);
  EntityTBX_2.SpecificsAdd(format(';desc=Created for %s',[Specifics.Values['GameDir']]));
  EntityTBX.Subelements.Add(EntityTBX_2);
  entityForms:=QFormContext.Create('Entity forms', addonRoot);
  addonRoot.SubElements.Add(entityForms);

  for i:=0 to NewAddonsList.Count-1 do
  begin
    Entities:=TQList.Create;
    NewAddonsList.Items1[i].FindAllSubObjects('', TTreeMapSpec, QObject, Entities);
    for j:=0 to Entities.Count-1 do
    begin
      OldEntity:=TTreeMapSpec(Entities.Items1[j]);
      Entity:=TTreeMapSpec(EntityTBX_2.FindSubObject(OldEntity.Name, TTreeMapSpec, QObject));
      if (Entity = nil) then
      begin
        if pos('_',OldEntity.name)<>0 then
        begin
          tb:=copy(OldEntity.name, 1,pos('_', OldEntity.Name))+'* entities';
          Group:=QToolboxGroup(EntityTBX_2.SubElements.FindName(tb+EntityTBX_2.typeinfo));
          if (Group = nil) then
          begin
            Group:=QToolBoxGroup.Create(tb, EntityTBX_2);
            EntityTBX_2.Subelements.add(Group);
          end
        end
        else
        begin
          Group:=EntityTBX_2;
        end;
        Entity:=TTreeMapSpec(ConstructQObject(OldEntity.GetFullName, Group));
        Group.SubElements.Add(Entity);
      end;
      for k:=0 to OldEntity.Specifics.Count-1 do
      begin
        if Entity.Specifics.IndexOfName(OldEntity.Specifics.Names[k])=-1 then
        begin
          Entity.Specifics.Add(OldEntity.Specifics[k]);
        end;
      end;
    end;
    Entities.Free;
    Forms:=TQList.Create;
    NewAddonsList.Items1[i].FindAllSubObjects('', QFormCfg, QObject, Forms);
    for j:=0 to Forms.Count-1 do
    begin
      OldForm:=QFormCfg(Forms.Items1[j]);
      Form:=QFormCfg(entityForms.FindSubObject(OldForm.Name, QFormCfg, QObject));
      if (Form = nil) then
      begin
        Form:=QFormCfg(ConstructQObject(OldForm.GetFullName, entityForms));
        entityForms.SubElements.Add(Form);
      end;
      for k:=0 to OldForm.Subelements.Count-1 do
      begin
        OldFormEl:=OldForm.Subelements[k];
        FormEl:=Form.FindSubObject(OldFormEl.Name, QObject, QObject);
        if FormEl=nil then
        begin
          FormEl:=ConstructQObject(OldFormEl.GetFullName, Form);
          Form.Subelements.Add(FormEl);
        end;
        for l:=0 to OldFormEl.Specifics.Count-1 do
        begin
          if FormEl.Specifics.IndexOfName(OldFormEl.Specifics.Names[l])=-1 then
          begin
            FormEl.Specifics.Add(OldFormEl.Specifics[l]);
          end;
        end;
      end;
    end;
    Forms.Free;
  end;
  TexFolders:=nil;
  BuildDynamicFolders(Specifics.Values['GameDir'], TexFolders, false, false, '');

  if TexFolders<>nil then
  begin
    TexFolders.Name:=Specifics.Values['GameDir']+' textures';
    TexRoot:=QToolBox.Create('Textures', addonRoot);
    AddonRoot.Subelements.Add(TexRoot);
    TexRoot.Flags := TexRoot.Flags or ofTreeViewSubElement;
    TexRoot.SpecificsAdd('ToolBox=Texture Browser...');
    TexRoot.SpecificsAdd('Root='+TexFolders.GetFullName);
    TexRoot.SubElements.Add(TexFolders);
    TexFolders.FParent:=TexRoot;
  end;

  NewAddonsList.free;
  bsps.free;
  paks.free;

  TBX.Flags := TBX.flags or ofTreeViewSubElement;
  entityForms.Flags := entityForms.flags or ofTreeViewSubElement;
  ExplorerFromObject(FParent).Refresh;
end;

 {------------------------}

class function QFormContext.TypeInfo;
begin
 TypeInfo:='.fctx';
end;

function QFormContext.GetConfigStr1: String;
begin
 Result:='FormContext';
end;

class procedure QFormContext.FileObjectClassInfo(var Info: TFileObjectClassInfo);
begin
 inherited;
 Info.FileObjectDescriptionText:=LoadStr1(5179);
{Info.FileExt:=779;
 Info.WndInfo:=[wiWindow];}
end;

 {------------------------}

initialization
  RegisterQObject(QQuakeCtx, 'a');
  RegisterQObject(QFormContext, 'a');
end.
