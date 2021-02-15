unit GWML;

interface
uses
NtDllHelper;
function LaunchClient(const path,args:PWideChar;const flags:Cardinal;out hThread:Cardinal):Cardinal;
implementation
uses SysUtils,Windows,Classes;


type
{$A8+}
{Process Environment Block}
    TPEB = record
       InheritedAddressSpace,
       ReadImageFileExecOptions,
       BeingDebugged,
       BitField:Byte;
       Mutant,
       ImageBaseAddress:Pointer;
    end;
    PPEB = ^TPEB;

    PROCESS_BASIC_INFORMATION = record
        Reserved1:Pointer;
        PebBaseAddress:PPEB;
        Reserved2:array[0..1] of Pointer;
        UniqueProcessId:PCardinal;
        Reserved3:Pointer;
    end;
    SID_AND_ATTRIBUTES = record
      Sid:Pointer;
      Attributes:Cardinal
    end;
TOKEN_MANDATORY_LABEL = record
  _Label:SID_AND_ATTRIBUTES
end;
{$A-}
const GWML_NO_DATFIX=1;
const GWML_KEEP_SUSPENDED=2;
const GWML_ELEVATED=8;
const
payload:array[0..172] of Byte =(
    $51,                                   // | PUSH ECX
    $52,                                   // | PUSH EDX
    $50,                                   // | PUSH EAX
    $3E, $8B, $4C, $24, $10,                         // | MOV ECX, DWORD PTR DS:[ESP + 10]
    $33, $D2,                                 // | XOR EDX, EDX
    $33, $C0,                                 // | XOR EAX, EAX
    $3E, $66, $8B, $04, $11,                          // | MOV AX, WORD PTR DS:[ECX + EDX]
    $66, $83, $F8, $00,                           // | CMP AX, 0
    $74, $05,                                // | JE <gwml.getbackslash>
    $83, $C2, $02,                              // | ADD EDX, 2
    $EB, $F0,                                // | JMP <gwml.getlen>
    $83, $EA, $02,                              // | SUB EDX, 2
    $3E, $66, $8B, $04, $11,                          // | MOV AX, WORD PTR DS:[ECX + EDX]
    $66, $83, $F8, $5C,                           // | CMP AX, 5C
    $74, $02,                                // | JE <gwml.checkifdat>
    $EB, $F0,                                // | JMP <gwml.getbackslash>
    $83, $C2, $02,                              // | ADD EDX, 2
    $3E, $66, $8B, $04, $11,                          // | MOV AX, WORD PTR DS:[ECX + EDX]
    $66, $83, $F8, $47,                           // | CMP AX, 47
    $75, $66,                                // | JNE <gwml.exitwithoutset>
    $83, $C2, $02,                              // | ADD EDX, 2
    $3E, $66, $8B, $04, $11,                          // | MOV AX, WORD PTR DS:[ECX + EDX]
    $66, $83, $F8, $77,                           // | CMP AX, 77
    $75, $58,                                // | JNE <gwml.exitwithoutset>
    $83, $C2, $02,                              // | ADD EDX, 2
    $3E, $66, $8B, $04, $11,                          // | MOV AX, WORD PTR DS:[ECX + EDX]
    $66, $83, $F8, $2E,                           // | CMP AX, 2E
    $75, $4A,                                // | JNE <gwml.exitwithoutset>
    $83, $C2, $02,                              // | ADD EDX, 2
    $3E, $66, $8B, $04, $11,                          // | MOV AX, WORD PTR DS:[ECX + EDX]
    $66, $83, $F8, $64,                           // | CMP AX, 64
    $75, $3C,                                // | JNE <gwml.exitwithoutset>
    $83, $C2, $02,                              // | ADD EDX, 2
    $3E, $66, $8B, $04, $11,                          // | MOV AX, WORD PTR DS:[ECX + EDX]
    $66, $83, $F8, $61,                           // | CMP AX, 61
    $75, $2E,                                // | JNE <gwml.exitwithoutset>
    $83, $C2, $02,                              // | ADD EDX, 2
    $3E, $66, $8B, $04, $11,                          // | MOV AX, WORD PTR DS:[ECX + EDX]
    $66, $83, $F8, $74,                           // | CMP AX, 74
    $75, $20,                                // | JNE <gwml.exitwithoutset>
    $58,                                   // | POP EAX
    $5A,                                   // | POP EDX
    $59,                                   // | POP ECX
    $36, $C7, $44, $24, $08, $00, $00, $00, $80,                // | MOV DWORD PTR SS:[ESP + 8], 80000000
    $36, $C7, $44, $24, $0C, $03, $00, $00, $00,                // | MOV DWORD PTR SS:[ESP + C], 3
    $36, $C7, $44, $24, $18, $01, $00, $00, $00,                // | MOV DWORD PTR SS:[ESP + 18], 1
    $EB, $03,                                // | JMP <gwml.end>
    $58,                                   // | POP EAX
    $5A,                                   // | POP EDX
    $59,       // | POP ECX
    $55,
    $8B, $EC,
    $81, $EC, $14, $01, $00, $00,
    $E9
);
var
MyToken:Cardinal;
g_moduleBase:PByte;
g_gwdata:array[0..$48D000-1] of Byte;


function SaferCreateLevel(dwScopeId,dwLevelId,OpenFlags:DWORD;pLevelHandle:Pointer;lpReserved:Pointer):LongBool;stdcall;
external 'Advapi32.dll' name 'SaferCreateLevel';
function SaferComputeTokenFromLevel(LevelHandle:Cardinal;InAccessToken:THandle;
OutAccessToken:PHandle;dwFlags:DWORD;lpReserved:Pointer):LongBool;stdcall;
external 'Advapi32.dll' name 'SaferComputeTokenFromLevel';
function SaferCloseLevel(hLevelHandle:Cardinal):LongBool;stdcall;
external 'Advapi32.dll' name 'SaferCloseLevel';
function ConvertStringSidToSidW(const StringSid:PWideChar;var Sid:Pointer):LongBool;stdcall;
external 'Advapi32.dll' name 'ConvertStringSidToSidW';
function SetTokenInformation(
TokenHandle:THandle;
TokenInformationClass:Cardinal;
TokenInformation:Pointer;
TokenInformationLength:Cardinal
):LongBool;stdcall;
external 'Advapi32.dll' name 'SetTokenInformation';
function GetLengthSid(psid:Pointer):Cardinal;stdcall;
external 'Advapi32.dll' name 'GetLengthSid';
function  swprintf(Output:PWideChar;Format:PWideChar):Integer;cdecl;varargs;
external 'user32.dll' name 'wsprintfW';

function GetProcessModuleBase(const hProcess:Cardinal):PByte;
var
pbi:PROCESS_BASIC_INFORMATION;
peb:TPEB;
retLen:Cardinal;
begin
       Result:=nil;
       retLen:=0;
       if Not DynNtQueryInformationProcess(
       hProcess,0,@pbi,SizeOf(PROCESS_BASIC_INFORMATION),retLen) then Exit;
       if not DynNtReadVirtualMemory(
       hProcess,
       pbi.PebBaseAddress,
       @peb,
       SizeOf(TPEB),
       retLen
       ) then Exit;
      Result:=pbyte(peb.ImageBaseAddress) + $1000;

end;

function MCPatch(hProcess:THandle):LongBool;
const
sig_patch:array[0..18] of Byte =
(
$56, $57, $68, $00, $01, $00, $00, $89, $85, $F4, $FE, $FF, $FF, $C7, $00, $00, $00, $00, $00
);
_payload:array[0..3] of Byte =
(
$31, $C0, $90, $C3
);
var
retLen:Cardinal;
I:Cardinal;
pMcpatch:PByte;
begin
Result:=False;
if not DynNtReadVirtualMemory(
hProcess,
g_moduleBase,
@g_gwdata[0],
$48D000,
retLen
) then Exit;

pMcpatch:=nil;
for I := 0 to $48D000 - 1 do
  begin
       if CompareMem(@g_gwdata[I],@sig_patch[0],SizeOf(sig_patch)) then
       begin
       pMcpatch:=g_moduleBase + I - $1A;
       Break;
       end;

  end;
 if pMcpatch = nil then Exit;
 retLen:=0;

 Result:=WriteProcessMemory(hProcess,pMcpatch, @_payload[0],
 SizeOf(_payload),
 retLen);
 {
 Result:=DynNtWriteVirtualMemory(
 hProcess,
 pMcpatch,
 @_payload[0],
 SizeOf(_payload),
 retLen
 );
 }
end;

function DATFix(const hProcess:Cardinal):LongBool;
const
sig_datfix:array[0..6] of Byte =($8B, $4D, $18, $8B, $55, $1C, $8B);
{$j+}
jmpencoding:array[0..4] of Byte = ($E9, 0, 0, 0, 0);
{$J-}
var
pDatFix:PByte;
I:Cardinal;
asmbuffer:Pointer;
regSize:Cardinal;
retLen:Cardinal;
asmend:Pointer;
rva_payload:Pointer;
begin
    Result:=False;
    for I := 0 to $48D000 - 1 do
    begin
      if CompareMem(@g_gwdata[I],@sig_datfix[0],SizeOf(sig_datfix)) then
       begin
       pDatFix:=g_moduleBase + I - $1A;
       Break;
       end;
    end;
    regSize:= sizeof(payload) + $20;
  if not  DynNtAllocateVirtualMemory(
  hProcess,
  @asmbuffer,
  @regSize,
  nil,
  MEM_COMMIT or MEM_RESERVE,
  PAGE_EXECUTE_READWRITE
  ) then Exit;
 if not DynNtWriteVirtualMemory(
  hProcess,
  asmbuffer,
  @payload[0],
  sizeof(payload),
  retLen
  ) then Exit;
  asmend:=pbyte(pbyte(asmbuffer) + sizeof(payload));
  rva_payload:= Pbyte(pDatFix + 9 - ( PByte(asmbuffer) + sizeof(payload) - 1 ));
  if not DynNtWriteVirtualMemory(
  hProcess,
  asmend,
  rva_payload,
  4,
  retLen
  )
   then Exit;

   PCardinal(@jmpencoding[1])^:=  Cardinal(asmbuffer) - (Cardinal(pdatfix) - 5);
   Result:=DynNtWriteVirtualMemory(
   hProcess,
   pDatFix,
   @jmpencoding[0],
   SizeOf(jmpencoding),
   retLen
   );
end;

function LaunchClient(const path,args:PWideChar;const flags:Cardinal;out hThread:Cardinal):Cardinal;
var
commandLine:array[0..100 -1] of WideChar;
startinfo:STARTUPINFOW;
procinfo:PROCESS_INFORMATION;
last_directory:array[0..MAX_PATH -1] of WideChar;
retLen:Cardinal;
hLevel:Cardinal;
hRestrictedToken:THandle;
tml:TOKEN_MANDATORY_LABEL;
orginChar:WideChar;
begin
swprintf(@commandLine,'"%s" %s',path,args);
retLen:=GetCurrentDirectoryW(MAX_PATH,@last_directory[0]);
Assert(retLen <> 0,'GetCurrentDirectoryW');
retLen:=0;
while (PWideChar(Cardinal(path) + retLen*2)^  <> WideChar(#0)) do
  begin
     if (PWideChar(Cardinal(path) + retLen*2)^ = WideChar('\')) or (PWideChar(Cardinal(path) + retLen*2)^ = WideChar('/')) then
     begin
     Result:=retLen;
     end;
     Inc(retLen);
  end;
  orginChar:= (PWideChar(Cardinal(path) + (Result+1)*2))^;
  (PWideChar(Cardinal(path) + (Result+1)*2))^:=WideChar(#0);
  SetCurrentDirectoryW(path);
  FillChar(startinfo,SizeOf(STARTUPINFOW),#0);
  FillChar(procinfo,SizeOf(PROCESS_INFORMATION),#0);
  if not ((flags and 8) = 8) then     {GWML_ELEVATED}
  begin
        if not SaferCreateLevel(2,131072,1,@hLevel,nil) then
        Exception.Create('SaferCreateLevel');
        if not SaferComputeTokenFromLevel(hLevel, 0, @hRestrictedToken, 0, nil) then
         begin
           SaferCloseLevel(hLevel);
           Exception.Create('SaferComputeTokenFromLevel');
         end;
         SaferCloseLevel(hLevel);
        FillChar(tml,SizeOf(TOKEN_MANDATORY_LABEL),#0);
        tml._Label.Attributes := $20;
        if not ConvertStringSidToSidW('S-1-16-8192',tml._Label.Sid) then
        begin
          CloseHandle(hRestrictedToken);
          Exception.Create('ConvertStringSidToSidW');
        end;
       if not SetTokenInformation(
       hRestrictedToken,
       Cardinal(TokenIntegrityLevel),
       @tml,
       sizeof(TOKEN_MANDATORY_LABEL) + GetLengthSid(tml._Label.Sid)
       ) then
       begin
           LocalFree(Cardinal(tml._Label.Sid));
          CloseHandle(hRestrictedToken);
          Exit(0);
       end;
       FillChar(procinfo,SizeOf(PROCESS_INFORMATION),#0);
       if not CreateProcessAsUserW(
        hRestrictedToken,
        nil,
        @commandLine,
        nil,
        nil,
        FALSE,
        CREATE_SUSPENDED ,
        nil,
        nil,
        startinfo,
        procinfo
       ) then
       begin
         Exception.Create('CreateProcessAsUserW');
       end;


       CloseHandle(hRestrictedToken);

  end
  else
  begin
   if not CreateProcessW(
   nil, @commandLine, nil, nil, FALSE, CREATE_SUSPENDED, nil, nil, startinfo, procinfo
   ) then RaiseLastOSError;
  end;

  SetCurrentDirectoryW(last_directory);
  (PWideChar(Cardinal(path) + (Result+1)*2))^:=orginChar;

  g_moduleBase := GetProcessModuleBase(procinfo.hProcess);
  if not MCPatch(procinfo.hProcess) then
  begin
      ResumeThread(procinfo.hThread);
      CloseHandle(procinfo.hThread);
      CloseHandle(procinfo.hProcess);
      Exception.Create('MCPatch');
  end;

  if (( flags and 1 ) = 0)then
  begin
    if not DATFix(procinfo.hProcess) then
    begin
               ResumeThread(procinfo.hThread);
            CloseHandle(procinfo.hThread);
            CloseHandle(procinfo.hProcess);
            Exception.Create('DATFix');
    end;
  end;

    hThread:=procinfo.hThread;
    CloseHandle(procinfo.hProcess);
    Result:=procinfo.dwProcessId;



end;

initialization
Assert(EnableDebug(MyToken));
finalization
if MyToken <> 0 then CloseHandle(MyToken);

end.
