unit NtProcessHelper;

interface
uses
windows,SysUtils,NtDllHelper,Classes,Messages;
type
ProcessHelper = class
public type
{$MINENUMSIZE 4}
KWAIT_REASON =(
    Executive,
    FreePage,
    PageIn,
    PoolAllocation,
    DelayExecution,
    Suspended,
    UserRequest,
    WrExecutive,
    WrFreePage,
    WrPageIn,
    WrPoolAllocation,
    WrDelayExecution,
    WrSuspended,
    WrUserRequest,
    WrEventPair,
    WrQueue,
    WrLpcReceive,
    WrLpcReply,
    WrVirtualMemory,
    WrPageOut,
    WrRendezvous,
    Spare2,
    Spare3,
    Spare4,
    Spare5,
    Spare6,
    WrKernel,
    MaximumWaitReason
);
THREAD_STATE =(
Running =2,
Waiting =5
);
 SYSTEM_INFORMATION_CLASS = (
                               SystemBasicInformation,
                               SystemProcessorInformation,
                               SystemPerformanceInformation,
                               SystemTimeOfDayInformation,
                               SystemPathInformation,
                               SystemProcessInformation,
                               SystemCallCountInformation,
                               SystemDeviceInformation,
                               SystemProcessorPerformanceInformation,
                               SystemFlagsInformation,
                               SystemCallTimeInformation,
                               SystemModuleInformation,
                               SystemLocksInformation,
                               SystemStackTraceInformation,
                               SystemPagedPoolInformation,
                               SystemNonPagedPoolInformation,
                               SystemHandleInformation,
                               SystemObjectInformation,
                               SystemPageFileInformation,
                               SystemVdmInstemulInformation,
                               SystemVdmBopInformation,
                               SystemFileCacheInformation,
                               SystemPoolTagInformation,
                               SystemInterruptInformation,
                               SystemDpcBehaviorInformation,
                               SystemFullMemoryInformation,
                               SystemLoadGdiDriverInformation,
                               SystemUnloadGdiDriverInformation,
                               SystemTimeAdjustmentInformation,
                               SystemSummaryMemoryInformation,
                               SystemMirrorMemoryInformation,
                               SystemPerformanceTraceInformation,
                               SystemObsolete0,
                               SystemExceptionInformation,
                               SystemCrashDumpStateInformation,
                               SystemKernelDebuggerInformation
                              );
{$MINENUMSIZE 1}
{$A8+}
CLIENT_ID = record
  UniqueProcess,UniqueThread:THandle;
end;
SYSTEM_THREAD = record
    KernelTime,
    UserTime,
    CreateTime:LARGE_INTEGER;
    WaitTime:ULONG;
    StartAddress:Pointer;
    ClientID:CLIENT_ID;           // process/thread ids
    Priority,
    BasePriority:LongInt;
    ContextSwitches:ULONG;
    ThreadState:THREAD_STATE;
    WaitReason:KWAIT_REASON;
end;
PSYSTEM_THREAD = ^SYSTEM_THREAD;

VM_COUNTERS = record
    PeakVirtualSize,
    VirtualSize:PULONG;
    PageFaultCount:ULONG;
    PeakWorkingSetSize,
    WorkingSetSize,
    QuotaPeakPagedPoolUsage,
    QuotaPagedPoolUsage,
    QuotaPeakNonPagedPoolUsage,
    QuotaNonPagedPoolUsage,
    PagefileUsage,
    PeakPagefileUsage:PULONG;
end;
PUNICODE_STRING = ^UNICODE_STRING;

  UNICODE_STRING = record
    Length: Word;
    MaximumLength: Word;
    Buffer: pwidechar;
  end;

   IO_COUNTERS = record
ReadOperationCount,
WriteOperationCount,
OtherOperationCount,
ReadTransferCount,
WriteTransferCount,
OtherTransferCount:UInt64;
end;
SYSTEM_PROCESS = record
    NextEntryOffset, // relative offset
    ThreadCount:ULONG;
    WorkingSetPrivateSize:LARGE_INTEGER;
    HardFaultCount,
    NumberOfThreadsHighWatermark:ULONG;
    CycleTime:UInt64;
    CreateTime,
    UserTime,
    KernelTime:LARGE_INTEGER;
    ImageName:UNICODE_STRING;
    BasePriority:LongInt;
    UniqueProcessId,
    InheritedFromUniqueProcessId:Pointer;
    HandleCount,
    SessionId:ULONG;
    UniqueProcessKey:PULONG;
    VmCounters:VM_COUNTERS;
    PrivatePageCount:PULONG;
    IoCounters:IO_COUNTERS;   // defined in winnt.h
end;
PSYSTEM_PROCESS = ^SYSTEM_PROCESS;

handle_data = record
  process_id:Cardinal;
  window_handle:THandle;
  thread_id:THandle;
end;
Phandle_data = ^handle_data;
{$A-}
  TQueryFullProcessImageNameW = function(AProcess: THANDLE; AFlags: DWORD;
    AFileName: PWideChar; var ASize: DWORD): BOOL; stdcall;
  TGetModuleFileNameExW = function(AProcess: THANDLE; AModule: HMODULE;
    AFilename: PWideChar; ASize: DWORD): DWORD; stdcall;
private
class var
mu32_DataSize:Cardinal;
mp_Data:array of Byte;
PsapiLib:HMODULE;
GetModuleFileNameExW:TGetModuleFileNameExW;
fullPath:array[0..MAX_PATH-1]of WideChar;
private
class function enum_windows_callback(handle:THandle;lParam:LPARAM):LongBool;stdcall;static;
class function is_main_window(handle:Cardinal):LongBool;static;
class function Find(const buffer:array of byte;const pattern:array of byte;const  mask: AnsiString;
  offset: Integer):Integer;static;
class function GetProcessPath(hProcess:Cardinal):string;static;
class function IsWindows200OrLater: Boolean;static;inline;
class function IsWindowsVistaOrLater: Boolean;static;inline;
class procedure DonePsapiLib;static;
class procedure InitPsapiLib;static;
protected
class procedure ReSet;static;
public
class constructor Create;
class destructor Destroy;
public
class function Capture:DWORD;static;
class function FindProcessByPid(u32_PID:DWORD):PSYSTEM_PROCESS;static;
class function FindThreadByTid(const pk_Proc:PSYSTEM_PROCESS;const u32_TID:DWORD):PSYSTEM_THREAD;static;
class function IsThreadSuspended(const  pk_Thread:PSYSTEM_THREAD;var pb_Suspended:BOOL):DWORD;overload;static;
class function IsThreadSuspended(const pid,threadIndex:Cardinal):LongBool;overload;static;
class function FindAllThreadsInProcess(const pk_Proc:PSYSTEM_PROCESS):PSYSTEM_THREAD;static;
class function KillProcess(dwPid:Cardinal):LongBool;static;
class function MainWindowHandle(dwPid:Cardinal):Cardinal;static;
class function find_main_window(const process_id:Cardinal):THandle;static;
class function GetFileNameByProcessID(AProcessID: DWORD): UnicodeString;static;
end;

GwMemoryHelper =class(ProcessHelper)
private type
{$A8+}
  TEXEVersionData = record
    CompanyName, FileDescription, FileVersion, InternalName, LegalCopyright,
      LegalTrademarks, OriginalFileName, ProductName, ProductVersion, Comments,
      PrivateBuild, SpecialBuild: string;
  end;
TGwClient = record
 gwPid:Cardinal;
 email:WideString;
 path:WideString;
 ton:WideString
end;
TGwClients = array of TGwClient;
    TPEB = record
       InheritedAddressSpace,
       ReadImageFileExecOptions,
       BeingDebugged,
       BitField:Byte;
       Mutant,
       ImageBaseAddress:Pointer;
    end;
    PPEB = ^TPEB;

    PROCESS_BASIC_INFORMATION = packed record
        Reserved1:Pointer;
        PebBaseAddress:PPEB;
        Reserved2:array[0..1] of Pointer;
        UniqueProcessId:PCardinal;
        Reserved3:Pointer;
    end;
{$A-}
private
class var
GwClients:TGwClients;
private
class function GetProcessModuleBase(const hProcess:Cardinal):PByte;static;
class function VeryiStrBuffer(const addr:PWideChar;const size:Cardinal):Cardinal;overload;static;
class function VeryiStrBuffer(const addr: PAnsiChar;const size: Cardinal): Cardinal;overload;static;
class function IsMainUIThread(const pk_Proc: ProcessHelper.PSYSTEM_PROCESS;Out tid:Cardinal):LongBool;static;
class function enum_windows_callback(handle:THandle;lParam:LPARAM):LongBool;stdcall;static;
public
class procedure ReSet;static;
class function GetRunningStatus:Cardinal;static;// reflush GwClients
class function IsGwClientExist(const email: string;out Pid:Cardinal;out ton:string):LongBool;static;
class function IsSpecialDescription(const fullFilePath:string): LongBool;static;
class function getCharName(const hProcess:Cardinal):string;static;
class function getEmailName(const hProcess:Cardinal):string;static;
class function FindWinHandle(const hProcess:Cardinal):Cardinal;static;
class function FindGwWinHandle(const hProcess:Cardinal):Cardinal;static;
class function IsInGame(const hProcess:Cardinal):LongBool;static;
end;

implementation

function NtQuerySystemInformation(
SystemInformationClass:Cardinal;
SystemInformation:Pointer;
SystemInformationLength:ULONG;
var ReturnLength:ULONG):LongInt;stdcall;
external 'ntdll.dll' name 'NtQuerySystemInformation';
function NtQueryInformationProcess(
ProcessHandle:THandle;
ProcessInformationClass:Cardinal;
ProcessInformation:Pointer;
ProcessInformationLength:Cardinal;
var ReturnLength:Cardinal
):LongInt;stdcall;
external 'ntdll.dll' name 'NtQueryInformationProcess';

{ ProcessHelper }

class function ProcessHelper.Capture: DWORD;
var
u32_Needed:Cardinal;
s32_Status:LongInt;
ss:Cardinal;
begin

        while True do
        begin
        try
          SetLength(mp_Data,mu32_DataSize);
        except
              Abort;
        end;
        u32_Needed:=0;

        s32_Status:=NtQuerySystemInformation(Cardinal(SystemProcessInformation),@mp_Data[0],mu32_DataSize,u32_Needed);
        //s32_Status:=NtQueryInformationProcess(dwPid,Cardinal(SystemProcessInformation),mp_Data,mu32_DataSize,u32_Needed);
        if  s32_Status = -1073741820 then
        begin
             mu32_DataSize := u32_Needed + 4000;
                SetLength(mp_Data,0);
                mp_Data:=nil;
                continue;
        end;
        Exit(s32_Status);
        end;
end;

class constructor ProcessHelper.Create;
begin
{$IFDEF X64}
Assert(SizeOf(SYSTEM_THREAD) = $50,'SYSTEM_THREAD<>$50');
Assert(SizeOf(SYSTEM_PROCESS)= $100,'SYSTEM_PROCESS<>$100');
{$ELSE}
Assert(SizeOf(SYSTEM_THREAD) = $40,'SYSTEM_THREAD:' + IntToHex(SizeOf(SYSTEM_THREAD),8) + '<>$40');
Assert(SizeOf(SYSTEM_PROCESS)= $B8,'SYSTEM_PROCESS:' + IntToHex(SizeOf(SYSTEM_PROCESS),8) + '<>$B8');
{$ENDIF}
mp_Data:=nil;
mu32_DataSize:=1000;
PsapiLib := 0;
end;

class destructor ProcessHelper.Destroy;
begin
if mp_Data <> nil then
SetLength(mp_Data,0);
DonePsapiLib;
end;

class procedure ProcessHelper.DonePsapiLib;
begin
  if PsapiLib = 0 then Exit;
  FreeLibrary(PsapiLib);
  PsapiLib := 0;
  @GetModuleFileNameExW := nil;
end;

class function ProcessHelper.enum_windows_callback(handle: THandle;
  lParam: LPARAM): LongBool;stdcall;
  var
  data:Phandle_data;
  process_id:Cardinal;
  thread_id:Cardinal;
begin
   data:=Phandle_data(lParam);
   process_id:=0;
   thread_id:=0;
   thread_id:=GetWindowThreadProcessId(handle, @process_id);
   if  (data.process_id <> process_id) or (Not is_main_window(handle)) then  Exit(True);
   data.thread_id:=thread_id;
   data.window_handle:=handle;
   Result:=False;

end;

class function ProcessHelper.Find(const buffer:array of byte;const pattern:array of Byte;const mask: AnsiString;
  offset: Integer): Integer;
var
found:BOOL;
first:Byte;
patternSize:Cardinal;
I,idx:Cardinal;
begin
first:=pattern[0];//first ansichar
patternSize:=StrLen(PAnsiChar(@mask[1]));
found:=False;
for I := 0 to  SizeOf(buffer) - patternSize  do
begin
     if buffer[0]  <> first then Continue;
     found:=True;
     for idx := 1 to  patternSize do
     begin
           if (mask[idx] = AnsiChar('x')) and (pattern[idx - 1] <> buffer[I + idx -1]) then
           begin
                found:=False;
                Break;
           end;

     end;
     if found then Exit(offset + I);
end;
Result:=0;
end;

class function ProcessHelper.FindAllThreadsInProcess(
  const pk_Proc:PSYSTEM_PROCESS): PSYSTEM_THREAD;
  var
  pk_Thread:PSYSTEM_THREAD;
  I:Cardinal;
begin
   Result:=nil;
  if not Assigned(pk_Proc) then Exception.Create('pk_Proc = nil');
  pk_Thread:=PSYSTEM_THREAD(pbyte(pk_Proc) + sizeof(SYSTEM_PROCESS));
  Result:=pk_Thread;
end;

class function ProcessHelper.FindProcessByPid(u32_PID: DWORD): PSYSTEM_PROCESS;
var
pk_Proc:PSYSTEM_PROCESS;
begin
      if not Assigned(mp_Data) then  Exception.Create('m_Data = nil');
      pk_Proc:=@mp_Data[0];
      while True do
      begin
       if Cardinal(pk_Proc.UniqueProcessId) = u32_PID then Exit(pk_Proc);
       if pk_Proc.NextEntryOffset = 0 then  Exit(nil);
       pk_Proc:=PSYSTEM_PROCESS(pbyte(pk_Proc) + pk_Proc.NextEntryOffset);
      end;
end;

class function ProcessHelper.FindThreadByTid(const pk_Proc: PSYSTEM_PROCESS;
  const u32_TID: DWORD): PSYSTEM_THREAD;
  var
  pk_Thread:PSYSTEM_THREAD;
  I:Cardinal;
begin
   Result:=nil;
  if not Assigned(pk_Proc) then Exception.Create('pk_Proc = nil');
  pk_Thread:=PSYSTEM_THREAD(pbyte(pk_Proc) + sizeof(SYSTEM_PROCESS));
  for I := 0 to pk_Proc.ThreadCount - 1 do
  begin
            if pk_Thread.ClientID.UniqueThread = u32_TID then Exit(pk_Thread);
            Inc(pk_Thread);
  end;

end;



class function ProcessHelper.find_main_window(const process_id: Cardinal): THandle;
var
data:handle_data;
begin
     data.process_id:=process_id;
     data.window_handle:=0;
     EnumWindows(@ProcessHelper.enum_windows_callback,LPARAM(@data));
     Result:=data.window_handle;
end;

class function ProcessHelper.GetFileNameByProcessID(
  AProcessID: DWORD): UnicodeString;
const
  PROCESS_QUERY_LIMITED_INFORMATION = $00001000; //Vista and above
  PROCESS_NAME_NATIVE = $00000001;
var
  HProcess: THandle;
  Lib: HMODULE;
  QueryFullProcessImageNameW: TQueryFullProcessImageNameW;
  S: DWORD;
begin
  if IsWindowsVistaOrLater then
    begin
      Lib := GetModuleHandle('kernel32.dll');
      if Lib = 0 then RaiseLastOSError;
      @QueryFullProcessImageNameW := GetProcAddress(Lib, 'QueryFullProcessImageNameW');
      if not Assigned(QueryFullProcessImageNameW) then RaiseLastOSError;
      HProcess := OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, False, AProcessID);
      if HProcess = 0 then RaiseLastOSError;
      try
        S := MAX_PATH;
        SetLength(Result, S + 1);
        while not QueryFullProcessImageNameW(HProcess, 0, PWideChar(Result), S) and (GetLastError = ERROR_INSUFFICIENT_BUFFER) do
          begin
            S := S * 2;
            SetLength(Result, S + 1);
          end;
        SetLength(Result, S);
        Inc(S);
        if not QueryFullProcessImageNameW(HProcess, 0, PWideChar(Result), S) then
          Result:='';
      finally
        CloseHandle(HProcess);
      end;
    end
  else
    if IsWindows200OrLater then
      begin
        InitPsapiLib;
        HProcess := OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, False, AProcessID);
        if HProcess = 0 then RaiseLastOSError;
        try
          S := MAX_PATH;
          SetLength(Result, S + 1);
          if GetModuleFileNameExW(HProcess, 0, PWideChar(Result), S) = 0 then
            RaiseLastOSError;
          Result := PWideChar(Result);
        finally
          CloseHandle(HProcess);
        end;
      end;
end;

class function ProcessHelper.GetProcessPath(hProcess:Cardinal): string;
begin

end;

class procedure ProcessHelper.InitPsapiLib;
begin
      if PsapiLib <> 0 then Exit;
  PsapiLib := LoadLibrary('psapi.dll');
  if PsapiLib = 0 then RaiseLastOSError;
  @GetModuleFileNameExW := GetProcAddress(PsapiLib, 'GetModuleFileNameExW');
  if not Assigned(GetModuleFileNameExW) then
    try
      RaiseLastOSError;
    except
      DonePsapiLib;
      raise;
    end;
end;

class function ProcessHelper.IsThreadSuspended(const pid,threadIndex:Cardinal): LongBool;
var
u32_Error:Cardinal;
pk_Proc:PSYSTEM_PROCESS;
pk_Thread:PSYSTEM_THREAD;
begin
     Result:=True;
     u32_Error:=ProcessHelper.Capture;
     if u32_Error <> 0 then Exception.Create('capture failed,errcode:' + IntToStr(u32_Error));
     pk_Proc:=ProcessHelper.FindProcessByPid(pid);
     if pk_Proc = nil then Exception.Create('proc = nil');
     pk_Thread:=ProcessHelper.FindAllThreadsInProcess(pk_Proc);
     Inc(pk_Thread,threadIndex);
     if pk_Thread = nil then  Exception.Create('pk_Thread = nil');
     Assert(ProcessHelper.IsThreadSuspended(pk_Thread,Result)= 0,'ERROR:IsThreadSuspended');
end;

class function ProcessHelper.IsWindows200OrLater: Boolean;
begin
   Result := Win32MajorVersion >= 5;
end;

class function ProcessHelper.IsWindowsVistaOrLater: Boolean;
begin
      Result := Win32MajorVersion >= 6;
end;

class function ProcessHelper.is_main_window(handle: Cardinal): LongBool;
begin
          Result:=(GetWindow(handle, GW_OWNER) = 0) and IsWindowVisible(handle);
end;

class function ProcessHelper.KillProcess(dwPid: Cardinal): LongBool;
var
OpenedToken:Cardinal;
ret:Cardinal;
begin
        Result:=DynNtOpenProcess(@OpenedToken,PROCESS_TERMINATE,dwPid);
        if Result then
        Result:=TerminateProcess(OpenedToken,ret);
end;

class function ProcessHelper.MainWindowHandle(dwPid: Cardinal): Cardinal;
begin

end;

class procedure ProcessHelper.ReSet;
begin
       mu32_DataSize:=1000;
       SetLength(ProcessHelper.mp_Data,mu32_DataSize);
end;

class function ProcessHelper.IsThreadSuspended(const pk_Thread: PSYSTEM_THREAD;
  var pb_Suspended: BOOL): DWORD;
begin
Result:=0;
if pk_Thread = nil then Exit($57);//ERROR_INVALID_PARAMETER
  //pb_Suspended:=(pk_Thread.ThreadState = Waiting) and (pk_Thread.WaitReason = Suspended);
    pb_Suspended:=(pk_Thread.ThreadState = Waiting) and ((pk_Thread.WaitReason = Suspended) or (pk_Thread.WaitReason = DelayExecution));
end;


class function GwMemoryHelper.getCharName(const hProcess:Cardinal): string;
const
sig:array[0..11] of Byte = ($8B,$F8,$6A,$03,$68,$0F,$00,$00,$C0,$8B,$CF,$E8);
var
g_moduleBase:PByte;
buffer:array of Byte;
retLen,I:Cardinal;
ret:array[0..31]of WideChar;
OpenedHandle:Cardinal;
found:LongBool;
strlen:Cardinal;
begin
  Result:='';
  OpenedHandle:=0;
 if not  DynNtOpenProcess(@OpenedHandle,PROCESS_ALL_ACCESS,hProcess) then Exit;
  g_moduleBase:= GwMemoryHelper.GetProcessModuleBase(OpenedHandle);
  if g_moduleBase = nil then  Exit;
  SetLength(buffer,$48D000);
  try
  if not DynNtReadVirtualMemory(
OpenedHandle,
g_moduleBase,
@buffer[0],
$48D000,
retLen
) then Exit;

found:=False;
for I := 0 to $48D000 - 1 do
  begin
       if CompareMem(@buffer[I],@sig[0],SizeOf(sig)) then
       begin
       g_moduleBase:=g_moduleBase + I - $42;
       found:=True;
       Break;
       end;
  end;
 if not found then Exit;
 if not DynNtReadVirtualMemory(
OpenedHandle,
g_moduleBase,
@g_moduleBase,
4,
retLen
) then Exit;

    if not DynNtReadVirtualMemory(
OpenedHandle,
g_moduleBase,
@ret[0],
32*2,
retLen
) then Exit;
strlen:=VeryiStrBuffer(PWideChar(@ret[0]),32);
if (retLen > 0) and (strlen>0) then
begin
  SetString(Result,PWideChar(@ret[0]),strlen+1);
end;
  finally
   SetLength(buffer,0);
   if OpenedHandle <> 0 then
   CloseHandle(OpenedHandle);
  end;
end;

class function GwMemoryHelper.getEmailName(const hProcess:Cardinal): string;
const
sig:array[0..11] of Byte = ($33,$C0,$5D,$C2,$10,$0,$CC,$68,$80,$0,$0,$0);
var
g_moduleBase:PByte;
buffer:array of Byte;
retLen,I:Cardinal;
ret:array[0..31]of AnsiChar;
OpenedHandle:Cardinal;
found:LongBool;
strlen:Cardinal;
begin
  Result:='';
  OpenedHandle:=0;
 if not  DynNtOpenProcess(@OpenedHandle,PROCESS_ALL_ACCESS,hProcess) then Exit;
  g_moduleBase:= GwMemoryHelper.GetProcessModuleBase(OpenedHandle);
  if g_moduleBase = nil then  Exit;
  SetLength(buffer,$48D000);
  try
  if not DynNtReadVirtualMemory(
OpenedHandle,
g_moduleBase,
@buffer[0],
$48D000,
retLen
) then Exit;

found:=False;
for I := 0 to $48D000 - 1 do
  begin
       if CompareMem(@buffer[I],@sig[0],SizeOf(sig)) then
       begin
       g_moduleBase:=g_moduleBase + I + $E;
       found:=True;
       Break;
       end;
  end;
 if not found then Exit;

 if not DynNtReadVirtualMemory(
OpenedHandle,
g_moduleBase,
@g_moduleBase,
4,
retLen
) then Exit;



    if not DynNtReadVirtualMemory(
OpenedHandle,
g_moduleBase,
@ret[0],
32,
retLen
) then Exit;
strlen:=VeryiStrBuffer(PAnsiChar(@ret[0]),32);
if (retLen > 0) and (strlen>0) then
begin
  SetString(Result,PAnsiChar(@ret[0]),strlen+1);
end;
  finally
   SetLength(buffer,0);
   if OpenedHandle <> 0 then
   CloseHandle(OpenedHandle);
  end;
end;

class function GwMemoryHelper.enum_windows_callback(handle: THandle;
  lParam: LPARAM): LongBool;
  var
  data:Phandle_data;
  name:array[0..255]of WideChar;
begin
   Result:=True;
   data:=Phandle_data(lParam);
  if GetClassNameW(handle,PWideChar(@name),256) <> 0 then
  begin
     if  SameText('ArenaNet_Dx_Window_Class',PWideChar(@name)) then
     begin
      data.window_handle:=handle;
      Exit(False);
     end;
  end;
end;


class function GwMemoryHelper.FindGwWinHandle(
  const hProcess: Cardinal): Cardinal;
  var
  pro:PSYSTEM_PROCESS;
begin
Result:=0;
try
ProcessHelper.ReSet;
ProcessHelper.Capture;
pro:=nil;
pro:=ProcessHelper.FindProcessByPid(hProcess);
if pro = nil then Exit;
if not GwMemoryHelper.IsMainUIThread(pro,Result) then
Result:=0;
except

end;
end;

class function GwMemoryHelper.FindWinHandle(const hProcess:Cardinal): Cardinal;
const
//aob:array[0..11] of Byte = ($20,$EA,0,$01,0,0,0,0,$3F,$FF,$FF,$FF);
//pat:AnsiString ='xx?xx????xxx';
fixedoffset = $635C6C;
var
g_moduleBase:PByte;
retLen:Cardinal;
ret:Cardinal;
OpenedHandle:Cardinal;
begin
  Result:=0;
  OpenedHandle:=0;
 if not  DynNtOpenProcess(@OpenedHandle,PROCESS_ALL_ACCESS,hProcess) then Exit;
  g_moduleBase:= GwMemoryHelper.GetProcessModuleBase(OpenedHandle);
  if g_moduleBase = nil then  Exit;
  try
  if not DynNtReadVirtualMemory(
OpenedHandle,
g_moduleBase + fixedoffset,
@ret,
4,
retLen
) then Exit;

Result:=ret;
  finally
   if OpenedHandle <> 0 then
   CloseHandle(OpenedHandle);
  end;
end;

class function GwMemoryHelper.GetRunningStatus: Cardinal;
var
pk_Proc:PSYSTEM_PROCESS;
path:string;
begin
      Result:=0;
      if not Assigned(mp_Data) then  Exception.Create('m_Data = nil');
      pk_Proc:=@mp_Data[0];
      SetLength(GwMemoryHelper.GwClients,0);
      while True do
      begin
       if pk_Proc.ImageName.Length <> 0 then
       begin
      path:=ProcessHelper.GetFileNameByProcessID(Cardinal(pk_Proc.UniqueProcessId));
       if  path <> ''  then
       begin
         if GwMemoryHelper.IsSpecialDescription(path) then
          begin
            if  GwMemoryHelper.getCharName(Cardinal(pk_Proc.UniqueProcessId)) <> '' then
            begin
              SetLength(GwMemoryHelper.GwClients,Result + 1);
              GwMemoryHelper.GwClients[Result].gwPid:=Cardinal(pk_Proc.UniqueProcessId);
              GwMemoryHelper.GwClients[Result].path:=path;
              GwMemoryHelper.GwClients[Result].email:= GwMemoryHelper.getEmailName(Cardinal(pk_Proc.UniqueProcessId));
              GwMemoryHelper.GwClients[Result].ton:= GwMemoryHelper.getCharName(Cardinal(pk_Proc.UniqueProcessId));
              Inc(Result);
            end;
          end;
       end;
       end;
       if pk_Proc.NextEntryOffset = 0 then  Break;
       pk_Proc:=PSYSTEM_PROCESS(pbyte(pk_Proc) + pk_Proc.NextEntryOffset);
      end;
end;

class function GwMemoryHelper.IsInGame(const hProcess: Cardinal): LongBool;
const
//aob:array[0..11] of Byte = ($20,$EA,0,$01,0,0,0,0,$3F,$FF,$FF,$FF);
//pat:AnsiString ='xx?xx????xxx';
fixedoffset = $94964C;
var
g_moduleBase:PByte;
retLen:Cardinal;
ret:Cardinal;
OpenedHandle:Cardinal;
begin
  Result:=False;
  OpenedHandle:=0;
 if not  DynNtOpenProcess(@OpenedHandle,PROCESS_ALL_ACCESS,hProcess) then Exit;
  g_moduleBase:= GwMemoryHelper.GetProcessModuleBase(OpenedHandle);
  if g_moduleBase = nil then  Exit;
  try
  if not DynNtReadVirtualMemory(
OpenedHandle,
g_moduleBase + fixedoffset,
@ret,
4,
retLen
) then Exit;

Result:=ret <> 0;
  finally
   if OpenedHandle <> 0 then
   CloseHandle(OpenedHandle);
  end;
end;

class function GwMemoryHelper.IsGwClientExist(const email: string;out Pid:Cardinal;out ton:string): LongBool;
var
I:Cardinal;
begin
Result:=False;
if Length(GwMemoryHelper.GwClients) > 0 then
begin
    for I := Low(GwMemoryHelper.GwClients) to High(GwMemoryHelper.GwClients) do
    begin
      if SameText(email,GwMemoryHelper.GwClients[I].email) then
      begin
      Pid:=GwMemoryHelper.GwClients[I].gwPid;
      ton:=GwMemoryHelper.GwClients[I].ton;
      Exit(True);
      end;
    end;
end;

end;

class function GwMemoryHelper.IsMainUIThread(const pk_Proc: ProcessHelper.PSYSTEM_PROCESS;Out tid:Cardinal): LongBool;
const
gwCln:string ='ArenaNet_Dx_Window_Class';
  var
  pk_Thread:PSYSTEM_THREAD;
  I:Cardinal;
  name:array[0..255]of WideChar;
  data:handle_data;
begin
   Result:=True;
  if not Assigned(pk_Proc) then Exception.Create('pk_Proc = nil');
  pk_Thread:=PSYSTEM_THREAD(pbyte(pk_Proc) + sizeof(SYSTEM_PROCESS));
  for I := 0 to pk_Proc.ThreadCount - 1 do
  begin
           if Not EnumThreadWindows(pk_Thread.ClientID.UniqueThread,@GwMemoryHelper.enum_windows_callback,lparam(@data)) then
           begin
           tid:=data.window_handle;
           Exit;
           end;
            Inc(pk_Thread);
  end;
  Result:=False;
end;

class function GwMemoryHelper.IsSpecialDescription(const fullFilePath:string): LongBool;
    type
      PLandCodepage = ^TLandCodepage;

      TLandCodepage = record
        wLanguage, wCodePage: Word;
      end;
    var
      dummy, len: Cardinal;
      buf, pntr: Pointer;
      lang: string;
      info:TEXEVersionData;
    begin
      Result:=False;
      len := GetFileVersionInfoSizeW(@fullFilePath[1], dummy);
      if len = 0 then
        Exit;
      GetMem(buf, len);
      try
      try
        if not GetFileVersionInfoW(@fullFilePath[1], 0, len, buf) then
          Exit;
        if not VerQueryValueW(buf, '\VarFileInfo\Translation\', pntr, len) then
          Exit;
        lang := Format('%.4x%.4x', [PLandCodepage(pntr)^.wLanguage,
          PLandCodepage(pntr)^.wCodePage]);

    if VerQueryValueW(buf, PWideChar('\StringFileInfo\' + lang + '\FileDescription'), pntr, len){ and (@len <> nil)} then
      info.FileDescription := PWideChar(pntr);
          if  SameText(info.FileDescription,'Guild Wars Game Client') then
          begin
             Result:=True;
          end;
      finally
        FreeMem(buf);
      end;
      except

      end;
    end;

class procedure GwMemoryHelper.ReSet;
begin
  ProcessHelper.ReSet;
  if Assigned(GwMemoryHelper.GwClients) then
  SetLength(GwMemoryHelper.GwClients,0);

end;

class function GwMemoryHelper.VeryiStrBuffer(const addr: PWideChar;
  const size: Cardinal): Cardinal;
  var
  pScan:PWORD;
  I:Cardinal;
begin
      Result:=0;
      if size = 0 then Exit;
      if addr = nil then Exit;
      pScan:=PWord(addr);
      for I := 0 to size - 1 do
      begin
           if pScan^ = 0 then
           begin
           Result:=I-1;
           Exit;
           end;
           Inc(pScan);
      end;

end;


class function GwMemoryHelper.VeryiStrBuffer(const addr: PAnsiChar;
  const size: Cardinal): Cardinal;
var
  pScan:PByte;
  I:Cardinal;
begin
      Result:=0;
      if size = 0 then Exit;
      if addr = nil then Exit;
      pScan:=Pbyte(addr);
      for I := 0 to size - 1 do
      begin
           if pScan^ = 0 then
           begin
           Result:=I-1;
           Exit;
           end;
           Inc(pScan);
      end;

end;

class function GwMemoryHelper.GetProcessModuleBase(const hProcess:Cardinal):PByte;
var
pbi:PROCESS_BASIC_INFORMATION;
peb:TPEB;
retLen:Cardinal;
begin
       Result:=nil;
       retLen:=0;
       if Not DynNtQueryInformationProcess(
       hProcess,0,@pbi,SizeOf(PROCESS_BASIC_INFORMATION),retLen) then exit;
       if not DynNtReadVirtualMemory(
       hProcess,
       pbi.PebBaseAddress,
       @peb,
       SizeOf(TPEB),
       retLen
       ) then Exit;
      Result:=pbyte(peb.ImageBaseAddress) + $1000;
end;


end.
