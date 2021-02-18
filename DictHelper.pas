unit DictHelper;

interface
uses
Generics.Collections;
type
{$Z2}
JobStatus =(Ready,Runnning,InQueue,Launching,Deleted,UnKnow,InError,LogOut);
TJobStatus = set of JobStatus;
{$Z-}
TDWData = packed record
Kind:Word;
value:Word;
end;
AccountInfo = record
  status:JobStatus;//就绪,运行中,排队中,启动中,为知,错误
  email,psw,ton,path,ExArgs:string;
  datPath,elevated:LongBool;
  dwPid:Cardinal;
  wHandle:Cardinal;
  mods:Pointer
end;
PAccountInfo = ^AccountInfo;
AccountsInfo = record
  count:Cardinal;
  addr:PAccountInfo
end;
PAccountsInfo = ^AccountsInfo;
type
TTasks = TQueue<AccountInfo>;
var
dataRecords:TDictionary<string,AccountInfo>;
implementation



initialization
dataRecords:=TDictionary<string,AccountInfo>.Create;
finalization
dataRecords.Free;

end.
