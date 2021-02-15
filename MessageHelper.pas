unit MessageHelper;

interface
uses
DictHelper;
const
MsgOnError = $0400 + $64;
type
{$Z2}
ErrorType =(
User_Duplicate_Name = 0,
User_NoExist_Name,
Character_Duplicate_Name,
Character_NoExist_Name,
Job_HadInQueue,
Job_HadRunning,
Job_HadLaunching,
Job_NoExist,
Job_HadDeleted,
Job_Unknow,
Job_InError,
Job_HadHung,
Process_Cannot_Closed,
Login_MainWindows_Failed,
Login_CannotLogAsUser,
Login_Sucessfull,
Login_Launch_Failure,
Login_Launch_Failure2,
Delete_Failure
);
MessageType =(HandleError,UpdateStatus);
TMessageType = set of MessageType;
{$Z-}
UIMessage = class
private
class var FDefalutHandle:Cardinal;
private
class procedure PostUIMessage(const Context:Integer;const msgID:Cardinal;const msgType: MessageType; UIHandle: Cardinal = 0);static;
public
class procedure SendString(const msg: string;var action:TDWData;UIHandle: Cardinal = 0);overload;static;
class procedure RaiseError(const ErrorCode:ErrorType;UIHandle: Cardinal = 0);static;
public
class property DefalutHandle:Cardinal  read FDefalutHandle write FDefalutHandle default 0;
end;

implementation
uses
Windows,Messages;
{ UIMessage }

class procedure UIMessage.PostUIMessage(const Context:Integer;const msgID:Cardinal;const msgType: MessageType; UIHandle: Cardinal);
var
lHandle:Cardinal;
begin
      if UIHandle = 0 then
      lHandle:=UIMessage.FDefalutHandle
      else
      lHandle:=UIHandle;
      PostMessageW(lHandle,msgID,Integer(msgType),Context);
end;

class procedure UIMessage.RaiseError(const ErrorCode: ErrorType; UIHandle: Cardinal);
begin
     UIMessage.PostUIMessage(Integer(ErrorCode),MsgOnError,HandleError,UIHandle);
end;

class procedure UIMessage.SendString(const msg: string; var action:TDWData;
  UIHandle: Cardinal);
var
lHandle:Cardinal;
cds:COPYDATASTRUCT;
Buffer:String;
begin
      if UIHandle = 0 then
      lHandle:=UIMessage.FDefalutHandle
      else
      lHandle:=UIHandle;
      Buffer:=msg;
      cds.dwData:=Cardinal(action);
      cds.cbData:=(Length(Buffer) + 1)*SizeOf(Buffer[1]);
      cds.lpData:=@Buffer[1];
      SendMessageW(lHandle,WM_COPYDATA,lHandle,Integer(@cds));
end;



end.
