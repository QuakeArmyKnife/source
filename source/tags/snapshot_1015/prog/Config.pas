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
Revision 1.2  2000/06/03 10:46:49  alexander
added cvs headers


}


unit Config;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  QkObjects, QkExplorer, ExtCtrls, FormCfg, QkFileObjects, TB97,
  StdCtrls, QkForm, Setup;

type
  TConfigExplorer = class(TQkExplorer)
  public
   {function AfficherObjet(Parent, Enfant: QObject) : Integer; override;}
    procedure InvalidatePaintBoxes(ModifSel: Integer); override;
  end;

  TConfigDlg = class(TQkForm)
    Timer1: TTimer;
    Panel1: TPanel;
    CancelBtn: TToolbarButton97;
    OkBtn: TToolbarButton97;
    ApplyBtn: TToolbarButton97;
    Button1: TButton;
    Button2: TButton;
    TrashBtn: TToolbarButton97;
    procedure FormCreate(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ApplyBtnClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure OkBtnClick(Sender: TObject);
    procedure CancelBtnClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure TrashBtnClick(Sender: TObject);
  private
    SetupQrk: QFileObject;
    AncienSel: String;
    IsModal, ClickedOk: Boolean;
   {InternalOnly: Boolean;}
    procedure FormCfg1Change(Sender: TObject);
    procedure MAJAffichage(T: QObject);
    procedure FillExplorer(Empty: Boolean);
    procedure CancelOn;
    procedure CancelOff;
    procedure CancelNow;
    procedure InsertNewObj(Sender: TObject);
  protected
    procedure wmInternalMessage(var Msg: TMessage); message wm_InternalMessage;
  public
    Explorer: TConfigExplorer;
    FormCfg1: TFormCfg;
  end;

 {------------------------}

var
  ConfigDlg: TConfigDlg;

procedure ShowConfigDlg(const Source: String);
function LatestConfigInfo(T: TSetupSet): QObject;
function ShowAltConfigDlg(Racine: QObject; const Titre: String; NewObjList: TQList) : Boolean;

 {------------------------}

implementation

uses Qk1, Game, Quarkx, QkGroup, QkTreeView;

{$R *.DFM}

 {------------------------}

procedure ShowConfigDlg;
begin
 if ConfigDlg=Nil then
  ConfigDlg:=TConfigDlg.Create(Application);
 if Source<>'' then
  begin
   ConfigDlg.Explorer.TMSelUnique:=Nil;
   if Source[1]=':' then
    ConfigDlg.AncienSel:=SetupSet[ssGames].Name+':'+SetupGameSet.Name+Source
   else
    ConfigDlg.AncienSel:=Source;
  end;
 ConfigDlg.FillExplorer(False);
 ActivateNow(ConfigDlg);
 ConfigDlg.Timer1Timer(Nil);
end;

function ShowAltConfigDlg(Racine: QObject; const Titre: String; NewObjList: TQList) : Boolean;
var
 CfgDlg: TConfigDlg;
 X, I: Integer;
 Tpb: TToolbarButton97;
begin
 CfgDlg:=TConfigDlg.Create(Application); try
 with CfgDlg do
  begin
   IsModal:=True;
   Caption:=Titre;
   FillExplorer(False);
   Explorer.AddRoot(Racine);
   ApplyBtn.Hide;
   BorderIcons:=BorderIcons-[biMinimize];
   CancelBtn.Left:=ApplyBtn.Left;
   if NewObjList<>Nil then
    begin
     Explorer.AllowEditing:=aeFree;
     TrashBtn.Visible:=True;
     X:=TrashBtn.Left+TrashBtn.Width;
     for I:=0 to NewObjList.Count-1 do
      begin
       Tpb:=TToolbarButton97.Create(CfgDlg);
       Tpb.Parent:=Panel1;
       Tpb.Caption:=NewObjList[I].Name;
       Inc(X, 2);
       Tpb.SetBounds(X, TrashBtn.Top, Canvas.TextWidth(Tpb.Caption)+16, TrashBtn.Height);
       Tpb.Tag:=LongInt(NewObjList[I]);
       Tpb.OnClick:=InsertNewObj;
       Tpb.Hint:=NewObjList[I].Specifics.Values[';desc'];
       Inc(X, Tpb.Width);
      end;
    end;
   ShowModal;
  end;
 Result:=CfgDlg.ClickedOk;
 finally CfgDlg.Free; end;
end;

procedure TConfigDlg.InsertNewObj(Sender: TObject);
var
 Q: QObject;
 Gr: QExplorerGroup;
begin
 LongInt(Q):=(Sender as TControl).Tag;
 Gr:=ClipboardGroup;
 Gr.AddRef(+1); try
 Q:=Q.Clone(Nil, False);
 Gr.SubElements.Add(Q);
 Q.Specifics.Values[';desc']:='';
 Explorer.DropObjectsNow(Gr, '', True);
 finally Gr.AddRef(-1); end;
end;

 {------------------------}

(*function TConfigExplorer.AfficherObjet(Parent, Enfant: QObject) : Integer;
begin
 if Enfant is QConfig then
  Result:=ofTreeViewSubElement
 else
  Result:=0;
end;*)

procedure TConfigExplorer.InvalidatePaintBoxes(ModifSel: Integer);
begin
 with (ValidParentForm(Self) as TConfigDlg) do
  begin
   Timer1.Enabled:=False;
   Timer1.Enabled:=True;
  end;
end;

 {------------------------}

procedure TConfigDlg.FormCreate(Sender: TObject);
begin
 Explorer:=TConfigExplorer.Create(Self);
 Explorer.Parent:=Self;
 Explorer.Width:=166;
 Explorer.Align:=alLeft;
 Explorer.CreateSplitter;
{FillExplorer(False);}
 Caption:=LoadStr1(5376);
 RestorePositionTb('Config', False, Explorer);
 MarsCap.ActiveBeginColor:=clBlack;
 MarsCap.ActiveEndColor:=clGray;
 SetFormIcon(iiCfg);
end;

procedure TConfigDlg.FillExplorer;
var
 T: TSetupSet;
 I: Integer;
 SourceSel, Q: QObject;
 DestSel: TQList;
 Source: String;
begin
 Source:='';
 SourceSel:=Explorer.TMSelUnique;
 while SourceSel<>Nil do
  begin
   Source:=SourceSel.Name+':'+Source;
   SourceSel:=SourceSel.TvParent;
  end;
 if Source<>'' then
  AncienSel:=Source;
 Explorer.ClearView;
 if Empty then
  Exit;
 SetupQrk.AddRef(-1);
 SetupQrk:=Nil;
 SetupQrk:=MakeAddOnsList;
 if IsModal then
  Exit;
 for T:=Low(T) to High(T) do
  Explorer.AddRoot(SetupSet[T].Clone(Nil, False));
 Source:=AncienSel;
 if Source='' then
  Source:=SetupSet[Low(SetupSet)].Name;
 SourceSel:=Nil;
 DestSel:=Explorer.Roots;
 while Source<>'' do
  begin
   I:=Pos(':', Source);
   if I=0 then I:=Length(Source)+1;
   Q:=DestSel.FindName(Copy(Source, 1, I-1)+':config');
   if Q=Nil then Break;
   SourceSel:=Q;
   DestSel:=SourceSel.SubElements;
   Delete(Source, 1, I);
  end;
 Explorer.TMSelUnique:=SourceSel; 
end;

procedure TConfigDlg.Timer1Timer(Sender: TObject);
begin
 MAJAffichage(Explorer.TMSelUnique);
end;

procedure TConfigDlg.MAJAffichage(T: QObject);
var
{nFormCfg: TFormCfg;}
 S: String;
 Q: QObject;
 L: TList;
begin
 Timer1.Enabled:=False;
{nFormCfg:=Nil;}
 if T<>Nil then
  begin
   S:=T.Specifics.Values['Form'];
   if S<>'' then
    begin
         { builds a FormCfg based on this form }
     Q:=SetupQrk.FindSubObject(S, QFormCfg, QFileObject);
     if FormCfg1=Nil then
      begin
       FormCfg1:=TFormCfg.Create(Self);
       FormCfg1.Left:=Width;
       FormCfg1.Parent:=Self;
       FormCfg1.OnChange:=FormCfg1Change;
      {FormCfg1.Delta:=0.57;}
      end;
     FormCfg1.Show;
     L:=TList.Create; try
     L.Add(T);
     L.Add(Nil);
     FormCfg1.SetFormCfg(L, Q as QFormCfg);
     finally L.Free; end;
    {nFormCfg.Left:=-ScrollBox1.HorzScrollBar.Position;
     nFormCfg.Top:=-ScrollBox1.VertScrollBar.Position;}
     Exit;
    end;
  end;
 if FormCfg1<>Nil then
  begin
   FormCfg1.Hide;
   FormCfg1.SetFormCfg(Nil, Nil);
  end;
{FormCfg1.Free;
 FormCfg1:=nFormCfg;}
end;

procedure TConfigDlg.FormDestroy(Sender: TObject);
begin
 MAJAffichage(Nil);
 SetupQrk.AddRef(-1);
 SetupQrk:=Nil;
 if not IsModal then
  begin
   ConfigDlg:=Nil;
   SavePositionTb('Config', False, Explorer);
  end;
end;

procedure TConfigDlg.FormCfg1Change(Sender: TObject);
begin
{PostMessage(Handle, wm_InternalMessage, wp_AfficherInfos, 0);}
{Timer1.Enabled:=False;
 Timer1.Enabled:=True;}
 if FormCfg1.Modified or FormCfg1.InternalEditing then
  CancelOn
 else
  CancelOff;
end;

procedure TConfigDlg.wmInternalMessage(var Msg: TMessage);
begin
 case Msg.wParam of
 {wp_AfficherInfos: Timer1Timer(Nil);}
  wp_FormButton:
    Timer1Timer(Nil);
  (*case Msg.lParam of
     Ord('g'):
       begin
        ApplyBtnClick(Nil);
        GameCfgDlg;
       end;
    else Timer1Timer(Nil);
    end;*)
  wp_SetupChanged:
    if Msg.lParam<>scConfigDlg then
     FillExplorer(False);
 end;
 inherited;
end;

procedure TConfigDlg.ApplyBtnClick(Sender: TObject);
var
 T: TSetupSet;
 Q: QObject;
begin
 if ApplyBtn.Enabled then
  begin
   GlobalDoAccept{(Self)};
   if not IsModal then
    begin
     for T:=Low(T) to High(T) do
      begin
       Q:=Explorer.Roots[Ord(T)].Clone(Nil, False);
       SetupSet[T].AddRef(-1);
       SetupSet[T]:=Q;
       SetupSet[T].AddRef(+1);
      end;
    {InternalOnly:=True;}
     UpdateSetup(scConfigDlg);
    end; 
   CancelOff;
  {Timer1Timer(Nil);}
  end;
end;

function LatestConfigInfo(T: TSetupSet): QObject;
begin
 if (ConfigDlg=Nil) or not ConfigDlg.ApplyBtn.Enabled then
  Result:=SetupSet[T]
 else
  Result:=ConfigDlg.Explorer.Roots[Ord(T)];
end;

procedure TConfigDlg.CancelOff;
begin
 if ApplyBtn.Enabled then
  begin
   ApplyBtn.Enabled:=False;
   CancelBtn.Caption:=LoadStr1(5378);
  end;
end;

procedure TConfigDlg.CancelOn;
begin
 if not ApplyBtn.Enabled then
  begin
   ApplyBtn.Enabled:=True;
   CancelBtn.Caption:=LoadStr1(5377);
  end;
end;

procedure TConfigDlg.CancelNow;
begin
 GlobalDoCancel{(Self)};
 if ApplyBtn.Enabled then
  begin
   MAJAffichage(Nil);
   FillExplorer(True);
   CancelOff;
  end;
end;

procedure TConfigDlg.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 GlobalDoAccept{(Self)};
 if ApplyBtn.Enabled then
  begin
   ActivateNow(Self);
   case MessageDlg(LoadStr1(5642), mtConfirmation, mbYesNoCancel, 0) of
    mrYes: ApplyBtnClick(Nil);
    mrNo: CancelNow;
    else Abort;
   end;
  end;
 MAJAffichage(Nil);
end;

procedure TConfigDlg.OkBtnClick(Sender: TObject);
begin
 ApplyBtnClick(Nil);
 ClickedOk:=True;
 Close;
end;

procedure TConfigDlg.CancelBtnClick(Sender: TObject);
begin
 CancelNow;
 Close;
end;

procedure TConfigDlg.Button1Click(Sender: TObject);
begin
 if not GlobalDoAccept{(Self)} then
  if ApplyBtn.Enabled and not IsModal then
   ApplyBtnClick(Nil)
  else
   begin
    ClickedOk:=True;
    Close;
   end;
end;

procedure TConfigDlg.Button2Click(Sender: TObject);
begin
 if not GlobalDoCancel{(Self)} then
  Close;
end;

procedure TConfigDlg.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
 if (Key=Ord('Q')) and (ssCtrl in Shift) then
  begin
   Key:=0;
   OkBtnClick(Nil);
  end
 else
  if (Key=vk_Delete) and TrashBtn.Visible
  and (ActiveControl=Explorer) and not Explorer.Editing then
   TrashBtn.Click;
end;

procedure TConfigDlg.TrashBtnClick(Sender: TObject);
var
 Q: QObject;
begin
 Q:=Explorer.TMSelFocus;
 if (Q<>Nil) and (Explorer.Roots.IndexOf(Q)<0) and (MessageDlg(LoadStr1(4457), mtConfirmation, mbOkCancel, 0)=mrOk) then
  Explorer.DeleteSelection(0);
end;

end.
