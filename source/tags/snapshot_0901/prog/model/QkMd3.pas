unit QkMd3;

interface

uses Windows, SysUtils, Classes, QkObjects, Qk3D, QkForm, Graphics,
     QkImages, qmath, QkTextures, PyMath, Python, QkFileObjects, Dialogs, QkPcx,
     QkModelFile, QkModelRoot, QkFrame, QkComponent, QkMdlObject, QkModelTag, QkModelBone,
     QkMiscGroup;

type
  QMd3File = class(QModelFile)
  protected
    procedure LoadFile(F: TStream; Taille: Integer); override;
    procedure SaveFile(Info: TInfoEnreg1); override;
    Procedure ReadMesh(fs: TStream; Root: QModelRoot);
  public
    class function TypeInfo: String; override;
    class procedure FileObjectClassInfo(var Info: TFileObjectClassInfo); override;
  end;
  TMD3Header = packed record
    id: array[1..4] of char;       //id of file, always "IDP3"
    version: longint;              //version number, always 15
    filename: array[1..68] of char;//sometimes left Blank...
    BoneFrame_num: Longint;        //number of BoneFrames
    Tag_num: Longint;              //number of 'tags' per BoneFrame
    Mesh_num: Longint;             //number of meshes/skins
    MaxSkin_num: Longint;          //maximum number of unique skins
                                   //used in md3 file
    HeaderLength: Longint;         //always equal to the length of
                                   //this header
    Tag_Start: Longint;            //starting position of
                                   //tag-structures
    Tag_End: Longint;              //ending position of
                                   //tag-structures/starting
                                   //position of mesh-structures
    FileSize: Longint;             //size of file
  end;
  {
     If Tag_Start is the same as Tag_End then there are no tags.

     Tag_Num is sometimes 0, this is alright it means that there are no tags...
     i'm not sure what Tags are used for, altough there is a clear connection
     with boneframe, together they're probably used for bone based animations
     (where you rotate meshes around eachother to create animations).



     After the header comes a list of tags, if available.
     The ammount of tags is the header variable Tag_num times the header variable BoneFrame_num.
     So it is highly probably that tags have something to do with boneframes and that objects
     can have 0 to n tags 'attached' to them.
     Note: We call them 'Tags' because the name in tag usually starts with "tag_".
  }
  TMD3Tag = packed record
    Name: array[1..64] of char;    //name of 'tag' as it's usually
                                   //called in the md3 files try to
                                   //see it as a sub-mesh/seperate
                                   //mesh-part.
                                   //sometimes this 64 string may
                                   //contain some garbage, but
                                   //i've been told this is because
                                   //some tools leave garbage in
                                   //those strings, but they ARE
                                   //strings...
    Position: vec3_t;               //relative position of tag
    Rotation: array[1..3] of vec3_t;              //the direction the tag is facing relative to the rest of the model
  end;
  {
     fairly obvious i think, the name is the name of the tag.
     "position" is the relative position and "rotation" is the relative rotation to the rest of the model.

     After the tags come the 'boneframes', frames in the bone animation.
     The number of meshframes is usually identical to this number or simply 1.
     The header variable BoneFrame_num holds the ammount of BoneFrame..
  }
  TMD3BoneFrame = packed record
    //unverified:
    Mins: vec3_t;
    Maxs: vec3_t;
    Position: vec3_t;
    scale: single;
    Creator: array[1..16]of char; //i think this is the
                                  //"creator" name..
                                  //but i'm only guessing.
  end;
  {
     Mins, Maxs, and position are very likely to be correct, scale is just a guess.
     If you divide the maximum and minimum xyz values of all the vertices from each meshframe you get
     the exact values as mins and maxs..
     Position is the exact center of mins and maxs, most of the time anyway.

     Creator is very probably just the name of the program or file of which it (the boneframe?) was created..
     sometimes it's "(from ASE)" sometimes it's the name of a .3ds file.
  }
  TMD3Mesh = packed record
    ID: array[1..4] of char;          //id, must be IDP3
    Name: array[1..68] of char;       //name of mesh
    MeshFrame_num: Longint;           //number of meshframes
                                      //in mesh
    Skin_num: Longint;                //number of skins in mesh
    Vertex_num: Longint;              //number of vertices
    Triangle_num: Longint;            //number of Triangles
    Triangle_Start: Longint;          //starting position of
                                      //Triangle data, relative
                                      //to start of Mesh_Header
    HeaderSize: Longint;              //size of header
    TexVec_Start: Longint;            //starting position of
                                      //texvector data, relative
                                      //to start of Mesh_Header
    Vertex_Start: Longint;            //starting position of
                                      //vertex data,relative
                                      //to start of Mesh_Header
    MeshSize: Longint;                //size of mesh
  end;
  {
     Meshframe_num is the number of quake1/quake2 type frames in the mesh.
     (these frames work on a morph like way, the vertices are moved from one position to another instead of rotated around
     eachother like in bone-based-animations)
     Skin_num is the number of skins in the md3 file..
     These skins are animated.
     Triangle_Start, TexVec_Start & Vertex_Start are the number of bytes in the file from the start of the mesh header to the
     start of the triangle, texvec and vertex data (in that order).
  }
  TMD3Skin = packed record
    Name: array[1..68] of char; //name of skin used by mesh
  end;
  {
     Name holds the name of the texture, relative to the baseq3 path.
     Q3 has a peculiar way of handling textures..
     The scripts in the /script directory in the baseq3 directory contain scripts that hold information about how some
     surfaces are drawn and animate (and out of how many layers it consist etc.)
     Now the strange thing is, if you remove the ".tga" at the end of the skin, and that name is used in the script files, than
     that scripted surface is used.
     If it isn't mentioned in the script files then the filename is used to load the
     tga file.
  }
  PMD3Triangle = ^TMD3Triangle;
  TMD3Triangle = packed record
    Triangle: array[1..3] of longint; //vertex 1,2,3 of triangle
  end;
  {
     This is the simplest of structures.
     A triangle has 3 points which make up the triangle, each point is a vertex and the three ints that the triangle has point
     to those vertices.
     So you have a list of vertices, for example you have a list of 28 vertices and the triangle uses 3 of them: vertex 1, vertex
     14 and vertex 7.
     Then the ints contain 1, 14 and 7.
  }
  PMD3TexVec = ^TMD3TexVec;
  TMD3TexVec = packed record
    Vec: array[1..2] of single;
  end;
  {
     U/V coordinates are basically the X/Y coordinates on the texture.
     This is used by the triangles to know which part of the skin to display.
  }
  PMD3Vertex = ^TMD3Vertex;
  TMD3Vertex = packed record
    Vec: array[1..3]of smallint; //vertex X/Y/Z coordinate
    envtex: array[1..2]of byte;
  end;
  {
     Vec contains the 3d xyz coordinates of the vertices that form the model.EnvTex contains the texture coordinates for the
     enviromental mapping.
     Why does md3 have a second set of texture coordinates?
     Because:
     1. these texture coordinates need to be interpolated when the model changes shape,
     2. these texture coordinates are different from the normal texture coordinates but still both need to be used (with shaders you can
     have multi-layered surfaces, one could be an enviromental map, an other could be a transparent texture)   }

implementation

uses QuarkX, Setup;

class function QMd3File.TypeInfo;
begin
 Result:='.md3';
end;

class procedure QMd3File.FileObjectClassInfo(var Info: TFileObjectClassInfo);
begin
 inherited;
 Info.NomClasseEnClair:=LoadStr1(5176);
 Info.FileExt:=805;
end;

Procedure QMD3File.ReadMesh(fs: TStream; Root: QModelRoot);
const
  Spec1 = 'Tris=';
  Spec2 = 'Vertices=';
type
  PVertxArray = ^TVertxArray;
  TVertxArray = array[0..0] of TMD3TexVec;
var
  mhead: TMD3Mesh;
  tex: TMD3Skin;
  i, j: Integer;
  Skin: QImages;
  Frame: QFrame;
  s: String;
  size: TPoint;
  sizeset: Boolean;
  org: Longint;
  fsize: array[1..2] of Single;
  mn: String;
  Comp: QComponent;
  t, base_tex_name: string;
  //------ Pointers from here
  Tris, Tris2: PMD3Triangle;
  TexCoord: PVertxArray;
  Vertexes, Vertexes2: PMD3Vertex;
  CTris: PComponentTris;
  CVert: vec3_p;
begin
  org:=fs.position;
  fs.readbuffer(mhead, sizeof(mhead));
  //-----------------------------------------------------------
  //-- LOAD SKINS + GET SIZE OF FIRST
  //-----------------------------------------------------------
  mn:= trim(Mhead.name);
  Comp:=Loaded_Component(Root, mn);
  sizeset:=false;
  size.x:=0;
  size.y:=0;
  for i:=1 to mhead.skin_Num do begin
    fs.readbuffer(tex, sizeof(tex));
    base_tex_name:=trim(string(tex.Name));
    Skin:=Loaded_SkinFile(Comp, base_tex_name, false);
    if skin=nil then
      skin:=Loaded_SkinFile(Comp, ChangeFileExt(base_tex_name,'.jpg'), false);
    if skin=nil then begin
      t:=FmtLoadStr1(5575, [base_tex_name+' or '+ChangeFileExt(base_tex_name,'.jpg'), LoadName]);
      GlobalWarning(t);
      skin:=CantFindTexture(Comp, base_tex_name, Size);
      end;
    if skin<>nil then begin
      if (not sizeset) then begin
        Size:=Skin.GetSize;
        Sizeset:=true;
      end;
    end;
  end;
  fSize[1]:=size.x;
  fSize[2]:=size.y;
  Comp.SetFloatsSpec('skinsize', fSize);
  //-----------------------------------------------------------
  //-- LOAD TRIANGLES
  //-----------------------------------------------------------
  fs.seek(org+mhead.triangle_start, sofrombeginning);
  getmem(tris, mhead.triangle_num*sizeof(TMD3Triangle));
  fs.readbuffer(tris^, mhead.triangle_num*sizeof(TMD3Triangle));

  //-----------------------------------------------------------
  //-- LOAD TEXTURE CO-ORDS
  //-----------------------------------------------------------
  fs.seek(org+mhead.TexVec_Start, sofrombeginning);
  getmem(texCoord, mhead.vertex_num*sizeof(TMD3TexVec));
  fs.readbuffer(texCoord^, mhead.vertex_num*sizeof(TMD3TexVec));

  //-----------------------------------------------------------
  //-- PROCESS TRIANGLES + TEXTURE CO-ORDS
  //-----------------------------------------------------------
  try
    S:=Spec1;
    SetLength(S, Length(Spec1)+mhead.Triangle_num*SizeOf(TComponentTris));
    Tris2:=Tris;
    PChar(CTris):=PChar(S)+Length(Spec1);
    for I:=1 to mhead.Triangle_num do begin
      for J:=0 to 2 do begin
        with CTris^[J] do begin
          VertexNo:=Tris2^.triangle[J+1];
          with texCoord^[Tris2^.triangle[J+1]] do begin
            S:=round(vec[1]*Size.X);
            T:=round(vec[2]*Size.Y);
          end;
        end;
      end;
      Inc(CTris);
      Inc(Tris2);
    end;
    Comp.Specifics.Add(S); {tris=...}
  finally
    freemem(Tris);
    freemem(texcoord);
  end;
  //-----------------------------------------------------------
  //-- LOAD FRAMES + VERTEXES
  //-----------------------------------------------------------
  fs.seek(org+mhead.Vertex_Start, sofrombeginning);
  for i:=1 to mhead.MeshFrame_num do begin
    Frame:=Loaded_Frame(Comp, format('Frame %d',[i]));
    GetMem(Vertexes, mhead.vertex_Num * Sizeof(TMD3Vertex));
    try
      fs.readbuffer(Vertexes^, mhead.vertex_Num * Sizeof(TMD3Vertex));
      //-----------------------------------------------------------
      //-- PROCESS VERTEXES
      //-----------------------------------------------------------
      S:=FloatSpecNameOf(Spec2);
      SetLength(S, Length(Spec2)+mhead.Vertex_num*SizeOf(vec3_t));
      PChar(CVert):=PChar(S)+Length(Spec2);
      Vertexes2:=Vertexes;
      for J:=0 to mhead.vertex_Num-1 do begin
        with Vertexes2^ do begin
          CVert^[0]:=Vec[1] / 64;
          CVert^[1]:=Vec[2] / 64;
          CVert^[2]:=Vec[3] / 64;
        end;
        Inc(Vertexes2);
        Inc(CVert);
      end;
      Frame.Specifics.Add(S);
    finally
      FreeMem(Vertexes);
    end;
  end;
end;

Function BeforeZero(s:String): string;
var
  i: Integer;
begin
  result:='';
  for i:=1 to length(s) do
    if s[i]=#0 then
      break
    else
      result:=result+s[i];
end;

procedure QMd3File.LoadFile(F: TStream; Taille: Integer);
var
  i, org, org2: Longint;
  head: TMD3Header;
  tag: TMD3Tag;
  boneframe: TMD3BoneFrame;
  //---
  Root: QModelRoot;
  OTag: QModelTag;
  OBone: QModelBone;
  misc: QMiscGroup;
begin
 case ReadFormat of
  1: begin  { as stand-alone file }
      if Taille<SizeOf(TMD3Header) then
       Raise EError(5519);
      org:=f.position;
      f.readbuffer(head,sizeof(head));
      org2:=f.position;
      if (head.id<>'IDP3') or (head.version<>15) then
        raise Exception.Create('Not a valid MD3 File!');

      Root:=Loaded_Root;
      ObjectGameCode:=mjQ3A;
      Misc:=Root.GetMisc;
      if not((head.Tag_num=0) or (head.Tag_Start=head.Tag_End)) then begin
        f.seek(head.Tag_Start + org,soFromBeginning);
        for i:=1 to head.tag_num do begin
          fillchar(tag, sizeof(tag), #0);
          f.readbuffer(tag,sizeof(tag));
          OTag:=QModelTag.Create(beforezero(tag.name), Misc);
          Misc.SubElements.Add(OTag);
        end;
        f.seek(org2, sofrombeginning);
      end;
    if head.BoneFrame_num<>0 then begin
      for i:=1 to head.boneframe_num do begin
        f.readbuffer(boneframe,sizeof(boneframe));
        OBone:=QModelBone.Create(beforezero(boneframe.creator), Misc);
        Misc.SubElements.Add(OBone);
      end;
    end;
    if head.Mesh_num<>0 then begin
      f.seek(org + head.tag_end, sofrombeginning);
      for i:=1 to head.Mesh_num do begin
        ReadMesh(f, Root);
      end;
    end;
   end;
 else inherited;
 end;
end;

procedure QMd3File.SaveFile(Info: TInfoEnreg1);
var
  Root: QModelRoot;
  SkinObj: QImage;
  Components: TQList;
  Comp: QComponent;
  Skins: TQList;
  I, J: Longint;
begin
  with Info do begin
    case Format of
      rf_Siblings: begin  { write the skin files }
        if Flags and ofSurDisque <> 0 then
          Exit;
        Root:=Saving_Root;
        Info.TempObject:=Root;
        Components:=Root.BuildCOmponentList;
        try
          for I:=0 to Components.Count-1 do begin
            Comp:=QComponent(Components.Items1[I]);
            Skins:=Comp.BuildSkinList;
            try
              for J:=0 to Skins.Count-1 do begin
                SkinObj:=QImage(Skins.Items1[J]);
                Info.WriteSibling(SkinObj.Name+SkinObj.TypeInfo, SkinObj);
              end;
            finally
              skins.free;
            end;
          end;
        finally
          Components.free;
        end;
      end;
      1: begin  { write the .md3 file }
        raise exception.create('Unsupported!');
      end;
      else
        inherited;
    end;
  end;
end;

initialization
  RegisterQObject(QMd3File, 'v');
end.
