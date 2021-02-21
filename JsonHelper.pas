unit JsonHelper;

interface
uses
JsonDataObjects,Windows,SysUtils,SyncObjs,DictHelper;

function HasTheKey(const O:TJDOJsonObject;const key:string):LongBool;overload;
function HasTheKey(const A:TJDOJsonArray;const key:string):LongBool;overload;
function FindAcount(const key:string;var info:AccountInfo):LongBool;
function FindJsonObject(const src:TJsonArray;const key,value:string):TJsonObject;
procedure DelAccount(const key:string);
function AddAccount(var info:AccountInfo):LongBool;
function ModifyAccount(var info:AccountInfo):LongBool;
procedure LoadJsonConfig;
implementation
procedure InitAccount;
var
Obj: TJsonBaseObject;
Ar:TJsonArray;
begin
    if Not FileExists('.\Accounts.json') then
    begin
     Obj := TJsonBaseObject.ParseUtf8('[]');
     Ar:= Obj as TJsonArray;
     try
        Ar.SaveToFile('.\Accounts.json',False,TEncoding.UTF8,True);
     finally
         Obj.Free;
     end;
    end;

end;

function HasTheKey(const O:TJDOJsonObject;const key:string):LongBool;
var
I:Cardinal;
begin
     Result:=True;
     if O.Count = 0 then Exit(False);

     for I := 0 to O.Count - 1 do
     begin
         if O.Items[I].Typ = jdtString then
         begin
           if  SameText(O.Items[I].Value,key) then Exit;
         end;
     end;
     Result:=False;

end;

function HasTheKey(const A:TJDOJsonArray;const key:string):LongBool;
var
I:Cardinal;
begin
     Result:=True;
     if A.Count = 0 then Exit(False);
     for I := 0 to A.Count - 1 do
       begin
         if A.Items[I].Typ = jdtObject then
         begin
          if  HasTheKey(A.Items[I].ObjectValue,Key) then Exit;
         end;

       end;
       Result:=False;
end;

function FindAcount(const key:string;var info:AccountInfo):LongBool;
var
  B:TJsonBaseObject;
  A:TJsonObject;
  C:TJsonArray;
  I:Cardinal;
begin
    Result:=False;
  //  mutex.Enter;
   try
      B:=TJsonBaseObject.ParseFromFile('.\Accounts.json');
      C:=B as TJsonArray;
      if C.Count = 0 then Exit;
      for I := 0 to C.Count -1 do
      begin
          if  c.Items[I].Typ = jdtObject then
          begin
            if SameText(c.Items[I].ObjectValue.S['character'],key) then
            begin
              info.email:= c.Items[I].ObjectValue.S['email'];
              info.psw:=c.Items[I].ObjectValue.S['password'];
              info.ton:=c.Items[I].ObjectValue.S['character'];
              info.path:=c.Items[I].ObjectValue.S['gwpath'];
              info.ExArgs:=c.Items[I].ObjectValue.S['extraargs'];
              info.datPath:= c.Items[I].ObjectValue.B['datfix'];
               info.elevated:= c.Items[I].ObjectValue.B['elevated'];
               //info.mods:=Pointer(Integer(c.Items[I].ObjectValue.Values['mods'].VariantValue));
            end;

          end;
      end;
      Result:=True;
   finally
 //    mutex.Leave;
     B.Free;
   end;
end;



procedure DelAccount(const key:string);
var
  B:TJsonBaseObject;
  A:TJsonObject;
  C:TJsonArray;
  I:Cardinal;
begin
  // mutex.Enter;
   try
      B:=TJsonBaseObject.ParseFromFile('.\Accounts.json');
      C:=B as TJsonArray;
      if C.Count = 0 then Exit;
      for I := 0 to C.Count -1 do
      begin
      if  c.Items[I].Typ = jdtObject then
          begin
            if SameText(c.Items[I].ObjectValue.S['email'],key) then
            begin
              C.Delete(I);
              Break;
            end;
          end;
      end;
      C.SaveToFile('.\Accounts.json');
   finally
     B.Free;
  //   mutex.Leave;
    end;

end;

function FindJsonObject(const src:TJsonArray;const key,value:string):TJsonObject;
var
I:Cardinal;
begin
      Result:=nil;
      if src.Count = 0 then Exit;
      for I := 0 to src.Count - 1 do
      begin
        if   src.Items[I].Typ = jdtObject  then
        begin
         if  SameText( src.Items[I].ObjectValue.S[key] ,value) then
         Exit(src.Items[I].ObjectValue);
        end;
      end;

end;




function AddAccount(var info:AccountInfo):LongBool;
var
  B:TJsonBaseObject;
  C:TJsonArray;
  ret:TJsonObject;
begin
    Result:=False;
   //  mutex.Enter;
     try
      B:=TJsonBaseObject.ParseFromFile('.\Accounts.json');
      C:=B as TJsonArray;
      ret:=C.AddObject;
     if Not HasTheKey(C,info.email) then ret.S['email']:=info.email
     else
     Exit;
      ret.S['password'] :=info.psw;
     if Not HasTheKey(C,info.ton) then ret.S['character'] :=info.ton
     else
     Exit;
      ret.S['gwpath'] :=info.path;
      ret.B['datfix']:=info.datPath;
      ret.B['elevated']:=info.elevated;
      ret.S['extraargs'] :=info.ExArgs;
      ret.I['mods']:=0;
      C.SaveToFile('.\Accounts.json',False,TEncoding.UTF8,True);
      Result:=True;
     finally
       B.Free;
   //    mutex.Leave;
     end;
end;


function ModifyAccount(var info:AccountInfo):LongBool;
var
  B:TJsonBaseObject;
  C:TJsonArray;
  ret:TJsonObject;
begin
    Result:=False;
   //  mutex.Enter;
     try
      B:=TJsonBaseObject.ParseFromFile('.\Accounts.json');
      C:=B as TJsonArray;
      ret := FindJsonObject(C,'email',info.email);
      if ret <> nil then
      begin
      ret.S['gwpath'] :=info.path;
      ret.B['datfix']:=info.datPath;
      ret.B['elevated']:=info.elevated;
      ret.S['extraargs'] :=info.ExArgs;
      ret.I['mods']:=0;
      c.SaveToFile('.\Accounts.json',False,TEncoding.UTF8,True);
      Result:=True;
      end;
     finally
       B.Free;
   //    mutex.Leave;
     end;
end;

procedure LoadJsonConfig;
var
  B: TJsonBaseObject;
  A: TJsonObject;
  C: TJsonArray;
  I: Cardinal;
  info:AccountInfo;
begin
  try
    B := TJsonBaseObject.ParseFromFile('.\Accounts.json');
    C := B as TJsonArray;
    if C.Count = 0 then
      Exit;
    for I := 0 to C.Count - 1 do
    begin
      if C.Items[I].Typ = jdtObject then
      begin
        if dataRecords.ContainsKey(info.email) then  Continue;
        info.email:=C.Items[I].ObjectValue.S['email'];
        info.psw:=C.Items[I].ObjectValue.S['password'];
        info.ton:=C.Items[I].ObjectValue.S['character'];
        info.path:=C.Items[I].ObjectValue.S['gwpath'];
        info.ExArgs:=C.Items[I].ObjectValue.S['extraargs'];
        info.datPath:=C.Items[I].ObjectValue.B['datfix'];
        info.elevated:=C.Items[I].ObjectValue.B['elevated'];
        info.status:=Ready;
        info.dwPid:=0;
        dataRecords.AddOrSetValue(info.email,info);
      end;
    end;
  finally
    B.Free;
  end;
end;
initialization
InitAccount;
end.
