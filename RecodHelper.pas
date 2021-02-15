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
email:string;
dwId:Cardinal;
local_info:AccountInfo;
action:TDWData;
begin
     mutex.Enter;
     try
     try
      GwMemoryHelper.ReSet;
      GwMemoryHelper.Capture;
     if GwMemoryHelper.GetRunningStatus = 0 then Exit;
      for email in dataRecords.Keys do
      begin
         if  GwMemoryHelper.IsLogIn(email,dwId) then
         begin

              if dataRecords[email].status In [Ready,InQueue,Launching] then
              begin

                   local_info:=dataRecords[email];
                   local_info.status:= Runnning;
                   dataRecords.AddOrSetValue(email,local_info);
                   action.Kind:= Word(UpdateStatus);
                   action.value:=Word(Runnning);
                   UIMessage.SendString(local_info.ton,action);
              end
              else
              begin

              end;

         end
         else

         begin

              if Not (dataRecords[email].status  In [Ready]) then
              begin

                   local_info:=dataRecords[email];
                   local_info.status:=Ready;
                   dataRecords.AddOrSetValue(email,local_info);
                   action.Kind:= Word(UpdateStatus);
                   action.value:=Word(Ready);
                   UIMessage.SendString(local_info.ton,action);
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
        JsonHelper.DelAccount(dataRecords[email].ton);
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
action:TDWData;
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
                     action.Kind:=word(UpdateStatus);
                     action.value:=word(InError);
                     UIMessage.SendString(info.ton,action);
                 end
                 else
                 begin
                     //  termainted
                     info.status:=Deleted;
                     action.Kind:=word(UpdateStatus);
                     action.value:=word(Deleted);
                     UIMessage.SendString(info.ton,action);
                 end;
        end
        else
        begin
                      //  termainted
                     info.status:=Deleted;
                     action.Kind:=word(UpdateStatus);
                     action.value:=word(Deleted);
                     UIMessage.SendString(info.ton,action);
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

class procedure DataWalker.LoadJsonConfig;
begin
       JsonHelper.LoadJsonConfig;
end;


class function DataWalker.Modify(const orginKey:string;var info: AccountInfo):LongBool;
var
temp:AccountInfo;
begin
Result:=False;
mutex.Enter;
try
if dataRecords.ContainsKey(orginKey) then
begin
   if JsonHelper.FindAcount(orginKey,temp) then
   begin
     if NOT (temp.status in [Ready]) then
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