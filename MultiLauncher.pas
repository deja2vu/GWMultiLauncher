unit MultiLauncher;

interface
uses
Windows;
type
GWML_FLAGS =(
NO_DATFIX =1,
KEEP_SUSPENDED =2,
NO_LOGIN =4,
ELEVATED =8
);
function  LaunchClient(const path,args:string;datfix:LongBool = False;nologin:LongBool = False;elevated:LongBool = False):LongBool;
function _MCPatch(hProcess:THandle):LongBool;cdecl;
function _DATFix(hProcess:THandle):LongBool;cdecl;
function _LaunchClient(path,args:PWideChar;flags:DWORD;out  hThread:DWORD):DWORD;cdecl;
implementation
uses
SysUtils,Registry,Classes;
type
ProcessHelper = class
private type
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
{$A-}
private
class var
mu32_DataSize:Cardinal;
mp_Data:array of Byte;
mf_NtQueryInfo:Pointer;
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
end;
{$LINK  GWML.obj}
function ConvertStringSidToSidA(StringSid: LPCSTR; var Sid: PSID): BOOL; stdcall;
external 'advapi32.dll' name 'ConvertStringSidToSidA';
function  _swprintf(Output:PWideChar;Format:PWideChar):Integer;cdecl;varargs;
external 'user32.dll' name 'wsprintfW';
function SaferCreateLevel(dwScopeId,dwLevelId,OpenFlags:DWORD;pLevelHandle:Pointer;lpReserved:Pointer):LongBool;stdcall;
external 'Advapi32.dll' name 'SaferCreateLevel';
function SaferComputeTokenFromLevel(LevelHandle:Cardinal;InAccessToken:THandle;
OutAccessToken:PHandle;dwFlags:DWORD;lpReserved:Pointer):LongBool;stdcall;
external 'Advapi32.dll' name 'SaferComputeTokenFromLevel';
function SaferCloseLevel(hLevelHandle:Cardinal):LongBool;stdcall;
external 'Advapi32.dll' name 'SaferCloseLevel';
function NtQuerySystemInformation(
SystemInformationClass:Cardinal;SystemInformation:Pointer;SystemInformationLength:ULONG;ReturnLength:PULONG):LongInt;stdcall;
external 'Ntdll.dll' name 'NtQuerySystemInformation';
function TerminateProcess(hProcess:THandle;uExitCode:Cardinal):LongBool;stdcall;
external 'Kernel32.dll' name 'TerminateProcess';


function _memcmp(const p1,p2:Pointer;size:Cardinal):Integer;cdecl;
begin
           Result:=0;
          if (Cardinal(p1) and Cardinal(p2) and size) = 0 then Exit;
          while  (Result < size) do
          begin
              if ((Pbyte(p1)+Result)^ <> (Pbyte(p2)+Result)^) then
              Exit((Pbyte(p1)+Result)^ - (Pbyte(p2)+Result)^);
              Inc(Result);
          end;
          Result:=0;

end;

procedure _memset(P: Pointer; B: Integer; Count: integer);cdecl;
begin
  FillChar(P^, Count, B);
end;

function _wcsstr(const str,strCharSet:PWideChar):PWideChar;cdecl;
var
index:Cardinal;
begin
      Result:=nil;
      if (Cardinal(str) and Cardinal(strCharSet)) = 0 then  Exit;

     index:=Pos(strCharSet,str);
     if index <> 0 then
     Result:=@str[index-1];
end;

function _MCPatch(hProcess:THandle):LongBool;cdecl;external;
function _DATFix(hProcess:THandle):LongBool;cdecl;external;
function _LaunchClient(path,args:PWideChar;flags:DWORD;out  hThread:DWORD):DWORD;cdecl;external;

function  LaunchClient(const path,args:string;datfix:LongBool = False;nologin:LongBool = False;elevated:LongBool = False):LongBool;
var
reg:TRegistry;
value:string;
hThread:DWORD;
flags:Cardinal;
dwPid:Cardinal;
ret:Cardinal;
pk_Proc:ProcessHelper.PSYSTEM_PROCESS;
begin
reg:=TRegistry.Create;
//try
try
 reg.RootKey:=HKEY_LOCAL_MACHINE;
if reg.OpenKey('\SOFTWARE\ArenaNet\Guild Wars',False) then
begin
  Assert(path <> '');
  value:=reg.ReadString('Src');
  Result:=SameText(value,path);
end
else
Result:=False;
if not Result then
begin
  reg.OpenKey('\SOFTWARE\ArenaNet\Guild Wars',True);
  reg.WriteString('Src',path);
  reg.WriteString('Path',path);
end;
if reg.OpenKey('\SOFTWARE\Wow6432Node\ArenaNet\Guild Wars',False) then
begin
 value:=reg.ReadString('Src');
 Result:=SameText(value,path);
end
else
Result:=False;
if not Result then
begin
  reg.OpenKey('\SOFTWARE\Wow6432Node\ArenaNet\Guild Wars',True);
  reg.WriteString('Src',path);
  reg.WriteString('Path',path);
end;
except
     Exception.Create('perform registry failed');
end;

    flags:=Cardinal(KEEP_SUSPENDED);
    if not datfix then flags :=flags or Cardinal(NO_DATFIX);
    if nologin then flags :=flags or Cardinal(NO_LOGIN);
    if elevated then flags := flags or Cardinal(GWML_FLAGS.elevated);
 dwPid:=0;
 dwPid:= _LaunchClient(@path[1],@args[1],flags,hThread);
if ProcessHelper.IsThreadSuspended(dwPid,0) then
begin
  try
     if  TerminateProcess(dwPid,ret) then
     begin
          dwPid:= _LaunchClient(@path[1],@args[1],flags,hThread);
     end
     else
     Abort;
  except
     MessageBoxW(0,'Do Run As Admin','',0);
     ResumeThread(hThread);
     CloseHandle(hThread);
  end;
end;

ResumeThread(hThread);
CloseHandle(hThread);

Result:=True;
//finally
  reg.Free;
//end;

end;

{ ProcessHelper }

class function ProcessHelper.Capture: DWORD;
var
u32_Needed:Cardinal;
s32_Status:LongInt;
begin
        while True do
        begin
        try
          SetLength(mp_Data,mu32_DataSize);
        except
              Abort;
        end;
        u32_Needed:=0;
        s32_Status:=NtQuerySystemInformation(Cardinal(SystemProcessInformation),mp_Data,mu32_DataSize,@u32_Needed);
        if s32_Status = $c0000004 then
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
end;

class destructor ProcessHelper.Destroy;
begin
if mp_Data <> nil then
SetLength(mp_Data,0);

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

class function ProcessHelper.IsThreadSuspended(const pid,threadIndex:Cardinal): LongBool;
var
u32_Error:Cardinal;
pk_Proc:PSYSTEM_PROCESS;
pk_Thread:PSYSTEM_THREAD;
begin
     u32_Error:=ProcessHelper.Capture;
     if u32_Error <> 0 then Exception.Create('capture failed,errcode:' + IntToStr(u32_Error));
     pk_Proc:=ProcessHelper.FindProcessByPid(pid);
     if pk_Proc = nil then Exception.Create('proc = nil');
     pk_Thread:=ProcessHelper.FindAllThreadsInProcess(pk_Proc);
     Inc(pk_Thread,threadIndex);
     if pk_Thread = nil then  Exception.Create('pk_Thread = nil');
     Assert(ProcessHelper.IsThreadSuspended(pk_Thread,Result)= 0,'ERROR:IsThreadSuspended');
end;

class function ProcessHelper.IsThreadSuspended(const pk_Thread: PSYSTEM_THREAD;
  var pb_Suspended: BOOL): DWORD;
begin
Result:=0;
if pk_Thread = nil then Exit($57);//ERROR_INVALID_PARAMETER
  pb_Suspended:=(pk_Thread.ThreadState = Waiting) and (pk_Thread.WaitReason = Suspended);
end;

end.
