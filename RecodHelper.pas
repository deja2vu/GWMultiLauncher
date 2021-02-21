unit RecodHelper;

interface
uses
JsonHelper,SyncObjs,DictHelper;
type
TemailName = string;
type
DataWalker = class
public
class var Tasks:TTasks;
class var isJobHung:LongBool;
class var MainUIHandle:Cardinal;
class var JsonFile:string;
private
//class procedure CallMainUI(const msg: string;method:Cardinal = 0);static;
public
class constructor Create;
class destructor Destroy;
public
class function Modify(const orginKey:string;var info:AccountInfo):LongBool;static;
class function Remove(const key:TemailName):LongBool;static;
class function Add(var info:AccountInfo):LongBool;static;
class function TheKeyHasTheValue(const key,value:string):LongBool;static;
class function TheKeyHasTheValueEx(const key, value: string): LongBool;static;
class procedure UpStatus(const email:string;const status:JobStatus);static;
class function GetStatus(const charName:string;out info:AccountInfo):LongBool;static;
class function InitJob(const charName:string;out info:AccountInfo):LongBool;static;
class procedure ReflushStatus;static;
class procedure LoadJsonConfig;static;
class procedure VerifyStatus;static;
class procedure CloseClient(const charName:string);static;
class function IsPending(const tonName:string):LongBool;static;
end;

MyStatus = class
  const NotRdy =0;
  const Running =1;
  const InQueue =2;
  const Launching =3;
  const UnKnow =4;
  const ERROR =5;
end;

implementation
uses
MutexHelper,Windows,Messages,SysUtils,NtProcessHelper,MessageHelper;



{ DataWalker }

class procedure DataWalker.ReflushStatus;
var
email,ton:string;
dwId,whandle:Cardinal;
local_info:AccountInfo;
begin
     mutex.Enter;
     try
     try
      GwMemoryHelper.ReSet;
      GwMemoryHelper.Capture;
      GwMemoryHelper.GetRunningStatus;
      for email in dataRecords.Keys do
      begin

         if  GwMemoryHelper.IsGwClientExist(email,dwId,whandle,ton) then
         begin
               local_info:=dataRecords[email];
               local_info.wHandle:=whandle;
               if ton = '' then
               begin
                if Not (local_info.status  In [LogOut]) then
                begin
                   local_info.status:=LogOut;
                   local_info.dwPid:=dwId;
                   dataRecords.AddOrSetValue(email,local_info);
                   UIMessage.Update(local_info.ton,LogOut);
                end;

               end
               else
               begin
               if  SameText(local_info.ton,ton) then
               begin
                if Not (local_info.status  In [JobStatus.Runnning]) then
                begin
                   local_info.status:=Runnning;
                   local_info.dwPid:=dwId;
                   local_info.ton:=ton;
                   dataRecords.AddOrSetValue(email,local_info);
                   UIMessage.Update(local_info.ton,Runnning);
                end;
               end
                 else
                  begin
                   UIMessage.Update(local_info.ton + '#' + ton,TonChanged);
                   //local_info.status:=Runnning;
                   local_info.dwPid:=dwId;
                   local_info.ton:=ton;
                   dataRecords.AddOrSetValue(email,local_info);
                  end;
               end;


         end
         else       //process no exist

         begin

              if Not (dataRecords[email].status  In [Ready]) then
              begin

                   local_info:=dataRecords[email];
                   local_info.status:=Ready;
                   local_info.dwPid:=0;
                   dataRecords.AddOrSetValue(email,local_info);
                   UIMessage.Update(local_info.ton,Ready);
              end
              else
              begin

              end;
         end;
      end;
     except

     end;
     finally
     mutex.Leave;
     end;
end;

class function DataWalker.Remove(const key: TemailName):LongBool;
var
email:string;
begin
Result:=False;
mutex.Enter;
try
   for email in dataRecords.Keys do
   begin
    if  SameText(dataRecords[email].ton,key) then
    begin
       if ((dataRecords[email].status) in [Ready,UnKnow,InError]) then
       begin
         if dataRecords[email].dwPid <> 0 then
         begin
        if not  ProcessHelper.KillProcess(dataRecords[email].dwPid) then
         begin
           UIMessage.RaiseError(Process_Cannot_Closed);
           Exit;
         end;
         end;
        JsonHelper.DelAccount(email);
        dataRecords.Remove(email);
        Exit(True);
       end
       else
       begin
       UIMessage.RaiseError(Job_HadHung);
       Exit;
       end;
    end;
   end;


finally
   mutex.Leave;
end;
end;

class function DataWalker.TheKeyHasTheValue(const key, value: string): LongBool;
begin
  begin
Result:=False;
mutex.Enter;
try
  if dataRecords.ContainsKey(key) then
  begin
    Result:=SameText(dataRecords[key].email,value);
  end;
finally
  mutex.Leave;
end;
end;
end;

class function DataWalker.TheKeyHasTheValueEx(const key, value: string): LongBool;
begin
  begin
Result:=False;
mutex.Enter;
try
  if dataRecords.ContainsKey(key) then
  begin
    Result:=SameText(dataRecords[key].email,value);
  end;
finally
  mutex.Leave;
end;
end;
end;

class procedure DataWalker.UpStatus(const email:string;const status: JobStatus);
var
local_info:AccountInfo;
begin
     mutex.Enter;
     try
        if dataRecords.ContainsKey(email) then
        begin
           local_info:=dataRecords[email];
           local_info.status:=status;
           dataRecords.AddOrSetValue(email,local_info);
        end;
     finally
     mutex.Leave;
     end;
end;

class procedure DataWalker.VerifyStatus;
const
STILL_ACTIVE = 259;
var
email:string;
code:Cardinal;
info:AccountInfo;
begin
 mutex.Enter;
 try
   for email in dataRecords.Keys do
   begin
       if dataRecords[email].dwPid <> 0 then
       begin
        if   GetExitCodeProcess(dataRecords[email].dwPid,code) then
        begin
                 info:=dataRecords[email];
                 if code = STILL_ACTIVE then
                 begin
                     // not termainted
                     info.status:=InError;
                     UIMessage.Update(info.ton,InError);
                 end
                 else
                 begin
                     //  termainted
                     info.status:=Deleted;
                     UIMessage.Update(info.ton,Deleted);
                 end;
        end
        else
        begin
                      //  termainted
                     info.status:=Deleted;
                     UIMessage.Update(info.ton,Deleted);
        end;

       end;

   end;
 finally
   mutex.Leave;
 end;
end;

class function DataWalker.Add(var info: AccountInfo): LongBool;
begin
 Result:=False;
 mutex.Enter;
 try
  if Not dataRecords.ContainsKey(info.email) then
begin
      if  JsonHelper.AddAccount(info) then
      begin
      dataRecords.Add(info.email,info);
      Result:=True;
      end;
end;
 finally
 mutex.Leave;
 end;
end;

//class procedure DataWalker.CallMainUI(const msg: string;method:Cardinal = 0);
//var
//Buffer:WideString;
//cds:COPYDATASTRUCT;
//begin
//    Buffer:=msg;
//    cds.dwData:=method;
//    cds.cbData:=(Length(Buffer) + 1)*SizeOf(Buffer[1]);
//    cds.lpData:=@Buffer[1];
//    SendMessageW(MainUIHandle,WM_COPYDATA,MainUIHandle,Integer(@cds));
//end;

class procedure DataWalker.CloseClient(const charName: string);
var
info:AccountInfo;
begin
       mutex.Enter;
       try
            if DataWalker.GetStatus(charName,info) then
            SendMessageW(info.wHandle,WM_CLOSE,0,0);
       finally
          mutex.Leave;
       end;
end;

class constructor DataWalker.Create;
begin
    Tasks:=TTasks.Create;
end;

class destructor DataWalker.Destroy;
begin
      if Assigned(DataWalker.Tasks) then
       DataWalker.Tasks.free;

end;

class function DataWalker.GetStatus(const charName:string;out info:AccountInfo): LongBool;
var
email:string;
begin
       Result:=False;
        mutex.Enter;
        try
         for email in dataRecords.Keys do
         begin
             if SameText(dataRecords[email].ton,charName) then
             begin
            info:=dataRecords[email];
            Result:=True;
             end;
         end;
        finally
        mutex.Leave;
        end;
end;

class function DataWalker.InitJob(const charName: string;
  out info: AccountInfo): LongBool;
var
email:string;
begin
       Result:=False;
        mutex.Enter;
        try
         for email in dataRecords.Keys do
         begin
             if SameText(dataRecords[email].ton,charName) then
             begin
            info:=dataRecords[email];
            case info.status of
              Ready:
              begin
               DataWalker.Tasks.Enqueue(info);
               info.status:=InQueue;
               Result:=True;
              end;
              Runnning:
              begin
               UIMessage.RaiseError(Job_HadRunning);
              end;
              InQueue:
              begin
               UIMessage.RaiseError(Job_HadInQueue);
              end;
              Launching:
              begin
              UIMessage.RaiseError(Job_HadLaunching);
              end;
              Deleted:
              begin
              UIMessage.RaiseError(Job_HadDeleted);
              end;
              UnKnow:
              begin
               UIMessage.RaiseError(Job_Unknow);
              end;
              InError:
              begin
               UIMessage.RaiseError(Job_InError);
              end;
              else
              begin

              end;
            end;

         end;
         end;
        finally
        mutex.Leave;
        end;
end;

class function DataWalker.IsPending(const tonName: string): LongBool;
var
info:AccountInfo;
key:string;
begin
mutex.Enter;
try
   for key in dataRecords.Keys do
  begin
     info:=dataRecords[key];
     if SameText(tonName,info.ton) then
   Exit(info.status in [Runnning,InQueue,Launching,Deleted,UnKnow,InError,Join,TonChanged]);

  end;
   Result:=False;
finally
  mutex.Leave;
end;
end;

class procedure DataWalker.LoadJsonConfig;
begin
       JsonHelper.LoadJsonConfig;
end;


class function DataWalker.Modify(const orginKey:string;var info: AccountInfo):LongBool;
var
newKey:string;
begin
Result:=False;
mutex.Enter;
try
if dataRecords.ContainsKey(orginKey) then
begin
   if JsonHelper.FindAcount(orginKey,info) then
   begin
     if NOT (info.status in [Ready]) then
     begin
         UIMessage.RaiseError(Job_HadHung);
         Exit;
     end;
     if SameText(orginKey,info.email) then
     begin
        if JsonHelper.ModifyAccount(info) then
        begin
          dataRecords.AddOrSetValue(orginKey,info);
        end;

     end
     else
     begin
       JsonHelper.DelAccount(orginKey);
       if JsonHelper.AddAccount(info) then
       begin
           dataRecords.Remove(orginKey);
           dataRecords.Add(info.email,info);
       end;
     end;
     Result:=True;
   end;
end;
finally
mutex.Leave;
end;
end;


end.
