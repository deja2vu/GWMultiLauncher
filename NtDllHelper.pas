unit NtDllHelper;

interface
uses
Windows;

type
     _CLIENT_ID = record
       UniqueProcess: tHANDLE;
       UniqueThread: tHANDLE;
     end;
     CLIENT_ID = _CLIENT_ID;
     PCLIENT_ID = ^CLIENT_ID;
     TClientID = CLIENT_ID;
     PClientID = ^TClientID;

  PUNICODE_STRING = ^UNICODE_STRING;

  UNICODE_STRING = record
    Length: Word;
    MaximumLength: Word;
    Buffer: pwidechar;
  end;
  {$MINENUMSIZE 4}
  TSecurityImpersonationLevel = (SecurityAnonymous,
  SecurityIdentification, SecurityImpersonation, SecurityDelegation);
  {$MINENUMSIZE 1}
  PSecurityQualityOfService = ^TSecurityQualityOfService;
  SECURITY_CONTEXT_TRACKING_MODE = Boolean;
  _SECURITY_QUALITY_OF_SERVICE = record
    Length: Cardinal;
    ImpersonationLevel: TSecurityImpersonationLevel;
    ContextTrackingMode: SECURITY_CONTEXT_TRACKING_MODE;
    EffectiveOnly: Boolean;
  end;

  TSecurityQualityOfService = _SECURITY_QUALITY_OF_SERVICE;
  SECURITY_QUALITY_OF_SERVICE = _SECURITY_QUALITY_OF_SERVICE;
  PSecurityDescriptor = Pointer;

    _OBJECT_ATTRIBUTES = record
    Length: Cardinal;
    RootDirectory: THandle;
    ObjectName: PUNICODE_STRING;
    Attributes: Cardinal;
    SecurityDescriptor: PSecurityDescriptor;
    SecurityQualityOfService: PSecurityQualityOfService;
  end;

  OBJECT_ATTRIBUTES = _OBJECT_ATTRIBUTES;
  POBJECT_ATTRIBUTES = ^OBJECT_ATTRIBUTES;

  NtCreateThreadExBuffer = record
    Size:ULONG;
    Unknown1:ULONG;
    Unknown2:ULONG;
    Unknown3:PULONG;
    Unknown4:ULONG;
    Unknown5:ULONG;
    Unknown6:ULONG;
    Unknown7:PULONG;
    Unknown8:ULONG
  end;
  PNtCreateThreadExBuffer = ^NtCreateThreadExBuffer;

function DynNtVirtualProtect(
var BaseAddress:Pointer;var RegionSize:Cardinal;NewProtect:Cardinal;OldProtect:PULONG
):LongBool;

function DynNtCreateRemoteThread(
Out remoteHandle:THandle;
ProcessHandle:THandle;
lpStartAddress:Pointer;
lpParameter:Pointer;
DesiredAccess:DWORD = $1FFFFF;
ObjectAttributes:POBJECT_ATTRIBUTES = nil;
createSuspended:LongBool = False;
StackZeroBits:Cardinal = 0;
SizeOfStackCommit:Cardinal = 4096*2;
SizeOfStackReserve:Cardinal = 4096*2;
lpBytesBuffer:PNtCreateThreadExBuffer = nil
):LongBool;

function DynNtOpenProcess(
OpenedToken: PHANDLE; DesiredAccess: Cardinal;
Pid:THandle
):LongBool;

function DynNtAllocateVirtualMemory(
OpenedToken: THandle; BaseAddress: PPointer; RegionSize: PCardinal;
  ZeroBits: PCardinal =nil;  AllocationType: Cardinal = MEM_COMMIT or MEM_RESERVE;
  Protect: Cardinal = PAGE_EXECUTE_READWRITE
):LongBool;

function DynNtFreeVirtualMemory(
OPenedToken: THandle; BaseAddress: PPointer;
  RegionSize: PCardinal; FreeType: Cardinal = $8000):LongBool;

function DynNtWriteVirtualMemory(
  OpenedToken: THandle; BaseAddress: Pointer;
  buffer: Pointer; bufferSize: Cardinal;
  var NumberOfBytesWritten: Cardinal):LongBool;

function DynNtReadVirtualMemory(
  OpenedToken: THandle; BaseAddress: Pointer;
  buffer: Pointer; bufferSize: Cardinal;var NumberOfBytesRead: Cardinal): LongBool;

function DynNtQueryInformationProcess(
ProcessHandle:THandle;
ProcessInformationClass:Cardinal;
ProcessInformation:Pointer;
ProcessInformationLength:Cardinal;
var ReturnLength:Cardinal
):LongBool;

function DynNtQuerySystemInformation(
SystemInformationClass:Cardinal;
SystemInformation:Pointer;
SystemInformationLength:ULONG;
ReturnLength:PULONG):LongBool;

function EnableDebug(out hToken: THandle): Boolean;
implementation
uses
Logger;

function DynNtVirtualProtect(
var BaseAddress:Pointer;var RegionSize:Cardinal;NewProtect:Cardinal;OldProtect:PULONG
):LongBool;
var
hLib: THandle;
Caller:function(
ProcessHandle:THandle;var BaseAddress:Pointer;var RegionSize:Cardinal;NewProtect:Cardinal;OldProtect:PULONG
):LongInt;
begin
    Result:=False;
    hLib := LoadLibraryW('ntdll.dll');
    if hLib <> 0 then
    begin
    try
       Caller:=GetProcAddress(hLib, 'NtProtectVirtualMemory');
       if Assigned(Caller) then
     Result:=Caller(GetCurrentProcess,BaseAddress,RegionSize,NewProtect,OldProtect) = 0;
    finally
      FreeLibrary(hLib);
    end;
    end;
end;

function DynNtCreateRemoteThread(
Out remoteHandle:THandle;
ProcessHandle:THandle;
lpStartAddress:Pointer;
lpParameter:Pointer;
DesiredAccess:DWORD = $1FFFFF;
ObjectAttributes:POBJECT_ATTRIBUTES = nil;
createSuspended:LongBool = False;
StackZeroBits:Cardinal = 0;
SizeOfStackCommit:Cardinal = 4096*2;
SizeOfStackReserve:Cardinal = 4096*2;
lpBytesBuffer:PNtCreateThreadExBuffer = nil
):LongBool;
var
hLib: THandle;
Caller:function(
remoteHandle:PHandle;
DesiredAccess:DWORD;
ObjectAttributes:POBJECT_ATTRIBUTES;
ProcessHandle:THandle;
lpStartAddress:Pointer;
lpParameter:Pointer;
createSuspended:LongBool;
StackZeroBits:Cardinal;
SizeOfStackCommit:Cardinal;
SizeOfStackReserve:Cardinal;
//var lpBytesBuffer:NtCreateThreadExBuffer
lpBytesBuffer:Pointer
):LongInt;stdcall;
var
ret:Integer;
begin
    Result:=False;
    hLib := LoadLibraryW('ntdll.dll');
    if hLib <> 0 then
    begin
    try
       Caller:=GetProcAddress(hLib, 'NtCreateThreadEx');
       if Assigned(Caller) then
       begin
     ret:=Caller(
     @remoteHandle,
     DesiredAccess,
     ObjectAttributes,
     ProcessHandle,
     lpStartAddress,
     lpParameter,
     createSuspended,
     StackZeroBits,
     SizeOfStackCommit,
     SizeOfStackReserve,
    nil
     );
     Logger.Printf(ret);
     Result:=ret = 0;
       end;
    finally
      FreeLibrary(hLib);
    end;
    end;
end;

function DynNtOpenProcess(
OpenedToken: PHANDLE; DesiredAccess: Cardinal;
Pid:THandle
):LongBool;
var
hLib: THandle;
Caller:function(
ProcessHandle: PHANDLE; DesiredAccess: Cardinal;
  ObjectAttributes: POBJECT_ATTRIBUTES;
  ClientId: PClientID
):LongInt;stdcall;
oa:OBJECT_ATTRIBUTES;
cid:TClientID;
begin
    Result:=False;
    hLib := LoadLibraryW('ntdll.dll');
    if hLib <> 0 then
    begin
    try
       Caller:=GetProcAddress(hLib, 'NtOpenProcess');
       if Assigned(Caller) then
      FillChar(oa,SizeOf(OBJECT_ATTRIBUTES),#0);
      oa.Length:=SizeOf(OBJECT_ATTRIBUTES);
      cid.UniqueProcess:=Pid;
      cid.UniqueThread:=0;
     Result:=Caller(OpenedToken,DesiredAccess,@oa,@cid) = 0;
    finally
      FreeLibrary(hLib);
    end;
    end;
end;

function DynNtAllocateVirtualMemory(
OpenedToken: THandle; BaseAddress: PPointer; RegionSize: PCardinal;
  ZeroBits: PCardinal =nil;  AllocationType: Cardinal = MEM_COMMIT or MEM_RESERVE;
  Protect: Cardinal = PAGE_EXECUTE_READWRITE
):LongBool;
var
hLib: THandle;
Caller:function(
ProcessHandle: THandle;BaseAddress: PPointer;
  ZeroBits: PCardinal; RegionSize: PCardinal; AllocationType: Cardinal;
  Protect: Cardinal
):LongInt;stdcall;
begin
    Result:=False;
    hLib := LoadLibraryW('ntdll.dll');
    if hLib <> 0 then
    begin
    try
       Caller:=GetProcAddress(hLib, 'NtAllocateVirtualMemory');
       if Assigned(Caller) then
    Result:=Caller(OpenedToken,BaseAddress,ZeroBits,RegionSize,AllocationType,Protect) = 0;
    finally
      FreeLibrary(hLib);
    end;
    end;
    end;

function DynNtFreeVirtualMemory(
OPenedToken: THandle; BaseAddress: PPointer;
  RegionSize: PCardinal; FreeType: Cardinal = $8000):LongBool;
 var
 hLib: THandle;
 Caller:function(
OPenedToken: THandle; BaseAddress: PPointer;
  RegionSize: PCardinal; FreeType: Cardinal
):LongInt;stdcall;
begin
         Result:=False;
    hLib := LoadLibraryW('ntdll.dll');
    if hLib <> 0 then
    begin
    try
       Caller:=GetProcAddress(hLib, 'NtFreeVirtualMemory');
       if Assigned(Caller) then
    Result:=Caller(OPenedToken, BaseAddress,
   RegionSize,FreeType) = 0;
    finally
      FreeLibrary(hLib);
    end;
    end;
    end;

function DynNtWriteVirtualMemory(
  OpenedToken: THandle; BaseAddress: Pointer;
  buffer: Pointer; bufferSize: Cardinal;
  var NumberOfBytesWritten: Cardinal):LongBool;
var
hLib: THandle;
Caller:function(
  OpenedToken: THandle; BaseAddress: Pointer;
  buffer: Pointer; bufferSize: Cardinal;
  var NumberOfBytesWritten: Cardinal
):LongInt;stdcall;
begin
    Result:=False;
    hLib := LoadLibraryW('ntdll.dll');
    if hLib <> 0 then
    begin
    try
       Caller:=GetProcAddress(hLib, 'NtWriteVirtualMemory');
       if Assigned(Caller) then
    Result:=Caller(OpenedToken, BaseAddress,
  buffer,bufferSize,NumberOfBytesWritten) = 0;
    finally
      FreeLibrary(hLib);
    end;
    end;
    end;

function DynNtReadVirtualMemory(
  OpenedToken: THandle; BaseAddress: Pointer;
  buffer: Pointer; bufferSize: Cardinal;var NumberOfBytesRead: Cardinal): LongBool;
var
hLib: THandle;
Caller:function(
  OpenedToken: THandle; BaseAddress: Pointer;
  buffer: Pointer; bufferSize: Cardinal;var NumberOfBytesRead: Cardinal
):LongInt;stdcall;
begin
    Result:=False;
    hLib := LoadLibraryW('ntdll.dll');
    if hLib <> 0 then
    begin
    try
       Caller:=GetProcAddress(hLib, 'NtReadVirtualMemory');
       if Assigned(Caller) then
    Result:=Caller(OpenedToken,BaseAddress,buffer,bufferSize,NumberOfBytesRead) = 0;
    finally
      FreeLibrary(hLib);
    end;
    end;
    end;

function DynNtOpenProcessToken(ProcessID: THandle; DesiredAccess: Cardinal;
  TokenHandle: PCardinal):LongBool;
  var
  hLib: THandle;
  Caller:function(
ProcessID: THandle; DesiredAccess: Cardinal;
  TokenHandle: PCardinal
):LongInt;stdcall;
begin
    Result:=False;
    hLib := LoadLibraryW('ntdll.dll');
    if hLib <> 0 then
    begin
    try
       Caller:=GetProcAddress(hLib, 'NtOpenProcessToken');
       if Assigned(Caller) then
    Result:=Caller(ProcessID,DesiredAccess,TokenHandle) = 0;
    finally
      FreeLibrary(hLib);
    end;
    end;
    end;


function DynNtQuerySystemInformation(
SystemInformationClass:Cardinal;SystemInformation:Pointer;SystemInformationLength:ULONG;ReturnLength:PULONG):LongBool;
  var
  hLib: THandle;
  Caller:function(
SystemInformationClass:Cardinal;SystemInformation:Pointer;SystemInformationLength:ULONG;ReturnLength:PULONG
):LongInt;stdcall;
begin
    Result:=False;
    hLib := LoadLibraryW('ntdll.dll');
    if hLib <> 0 then
    begin
    try
       Caller:=GetProcAddress(hLib, 'NtQuerySystemInformation');
       if Assigned(Caller) then
    Result:=Caller(SystemInformationClass,SystemInformation,SystemInformationLength,ReturnLength) = 0;
    finally
      FreeLibrary(hLib);
    end;
    end;
    end;

function DynNtQueryInformationProcess(
ProcessHandle:THandle;
ProcessInformationClass:Cardinal;
ProcessInformation:Pointer;
ProcessInformationLength:Cardinal;
var ReturnLength:Cardinal
):LongBool;
  var
  hLib: THandle;
  Caller:function(
ProcessHandle:THandle;
ProcessInformationClass:Cardinal;
ProcessInformation:Pointer;
ProcessInformationLength:Cardinal;
var ReturnLength:Cardinal
):LongInt;stdcall;
var
ret:LongInt;
begin
    Result:=False;
    hLib := LoadLibraryW('ntdll.dll');
    if hLib <> 0 then
    begin
    try
       Caller:=GetProcAddress(hLib, 'NtQueryInformationProcess');
       if Assigned(Caller) then
    ret:=Caller(
    ProcessHandle,
    ProcessInformationClass,
    ProcessInformation,
    ProcessInformationLength,
    ReturnLength
    );
    Result:=ret = 0;
    finally
      FreeLibrary(hLib);
    end;
    end;
    end;


function EnableDebug(out hToken: THandle): Boolean;
Const
  SE_DEBUG_NAME:PWideChar = 'SeDebugPrivilege';
var
  _Luit: LUID;
  TP,_TP: TOKEN_PRIVILEGES;
  RetLen: Cardinal;
begin
  Result := False;
  hToken := 0;
  if DynNtOpenProcessToken(GetCurrentProcess(), TOKEN_ADJUST_PRIVILEGES, @hToken)
    <> True then
    Exit;

  if not LookupPrivilegeValueW(nil, SE_DEBUG_NAME, Int64(_Luit)) then
  begin
    Exit;
  end;

  TP.PrivilegeCount := 1;
  TP.Privileges[0].Attributes := SE_PRIVILEGE_ENABLED;
  TP.Privileges[0].LUID := Int64(_Luit);
  RetLen := 0;
  FillChar(_TP,sizeof(TOKEN_PRIVILEGES),#0);
  Result := AdjustTokenPrivileges(hToken, False, TP, SizeOf(TOKEN_PRIVILEGES), nil, RetLen);

end;



end.
