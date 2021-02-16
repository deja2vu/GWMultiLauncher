unit MainUI;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, ComCtrls, Menus, CoolTrayIcon, MessageHelper;

type
  TMainForm = class(TForm)
    MainPan: TPanel;
    ListView1: TListView;
    PopupMenu1: TPopupMenu;
    N1: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    N4: TMenuItem;
    N5: TMenuItem;
    CoolTrayIcon1: TCoolTrayIcon;
    N6: TMenuItem;
    PopupMenu2: TPopupMenu;
    N7: TMenuItem;
    N8: TMenuItem;
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure N2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ListView1DblClick(Sender: TObject);
    procedure N4Click(Sender: TObject);
    procedure N3Click(Sender: TObject);
    procedure N1Click(Sender: TObject);
    procedure N5Click(Sender: TObject);
    procedure N6Click(Sender: TObject);
    procedure CoolTrayIcon1Click(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure N8Click(Sender: TObject);
    procedure N7Click(Sender: TObject);
  private
    procedure OnError(var msg: TMessage); message MsgOnError;
  private
    procedure AddAccount(const tonName: string; newName: string = '';
      states: string = '');
    procedure LoadJsonConfig;
  private
    function FindKey(const pid: Cardinal): string;
  private
    procedure WndProc(var _message: TMessage); override;

  end;

var
  MainForm: TMainForm;
procedure PostKeyExHWND(hWindow: HWnd; key: Word; const shift: TShiftState;
  specialkey: Boolean);

implementation

uses
  GWML, Registry, NtProcessHelper, Add, DictHelper, RecodHelper, MutexHelper;
{$R *.dfm}

type
  GWML_FLAGS = (NO_DATFIX = 1, KEEP_SUSPENDED = 2, LOGIN = 4, ELEVATED = 8);

type
  TMainRun = class(TThread)
  private
    FScanTimeeScapedWithOutJobs, FScanTimeeScapedWithJobs: Cardinal;
    FlaunchDelayTime: Cardinal;
    FscanTimer: Cardinal;
    FlaunchTimer: Cardinal;
  private
    function scanTime: Cardinal; inline;
    procedure scanReset; inline;
    function GetlaunchDelayTime: Cardinal; inline;
    procedure launchDelayReSet; inline;
    procedure reflushStatus;
    function wait(const count: Cardinal; PerDelay: Cardinal = 50): LongBool;
      inline;
  protected
    procedure execute; override;
  public
    class function ForamtArgs(var info: AccountInfo): string; static;
  public
    constructor Create(CreateSuspended: Boolean); overload;
    destructor Destroy;
  public
    property ScanTimeeScapedWithOutJobs
      : Cardinal read FScanTimeeScapedWithOutJobs write
      FScanTimeeScapedWithOutJobs;
    property ScanTimeeScapedWithJobs
      : Cardinal read FScanTimeeScapedWithJobs write
      FScanTimeeScapedWithJobs;
    property launchDelayTime
      : Cardinal read FlaunchDelayTime write FlaunchDelayTime;
  end;

var
  MainRun: TMainRun;
  CurrPid: Cardinal;

function MyLaunchClient(const path, args: WideString; datfix: LongBool = False;
  Dologin: LongBool = False; ELEVATED: LongBool = False): LongBool;
var
  reg: TRegistry;
  value: string;
  hThread: DWORD;
  flags: Cardinal;
  ret: Cardinal;
begin
  reg := TRegistry.Create;
  try
    try
      reg.RootKey := HKEY_LOCAL_MACHINE;
      if reg.OpenKey('\SOFTWARE\ArenaNet\Guild Wars', False) then
      begin
        Assert(path <> '');
        value := reg.ReadString('Src');
        Result := SameText(value, path);
      end
      else
        Result := False;
      if not Result then
      begin
        reg.OpenKey('\SOFTWARE\ArenaNet\Guild Wars', True);
        reg.WriteString('Src', path);
        reg.WriteString('Path', path);
      end;
      if reg.OpenKey('\SOFTWARE\Wow6432Node\ArenaNet\Guild Wars', False) then
      begin
        value := reg.ReadString('Src');
        Result := SameText(value, path);
      end
      else
        Result := False;
      if not Result then
      begin
        reg.OpenKey('\SOFTWARE\Wow6432Node\ArenaNet\Guild Wars', True);
        reg.WriteString('Src', path);
        reg.WriteString('Path', path);
      end;
    except
      Exception.Create('perform registry failed');
    end;

    flags := Cardinal(KEEP_SUSPENDED);
    if not datfix then
      flags := flags or Cardinal(NO_DATFIX);
    if Dologin then
      flags := flags or Cardinal(LOGIN);
    if ELEVATED then
      flags := flags or Cardinal(GWML_FLAGS.ELEVATED);
    CurrPid := 0;
    CurrPid := LaunchClient(@path[1], @args[1], flags, hThread);
    if ProcessHelper.IsThreadSuspended(CurrPid, 0) then
    begin
      try

        if ProcessHelper.KillProcess(CurrPid) then
        begin
          CurrPid := LaunchClient(@path[1], @args[1], flags, hThread);
        end
        else
          Abort;
      except
        MessageBoxW(0, 'Do Run As Admin', 'Error', 0);
        ResumeThread(hThread);
        CloseHandle(hThread);
      end;
    end;

    ResumeThread(hThread);
    CloseHandle(hThread);

    Result := True;
  finally
    reg.Free;

  end;

end;

procedure TMainForm.AddAccount(const tonName: string; newName: string = '';
  states: string = '');
var
  Item: TListItem;
begin
  if ListView1.FindCaption(0, Trim(tonName), True, True, True) = nil then
  begin
    ListView1.Items.BeginUpdate;
    Item := ListView1.Items.Add;
    Item.Caption := tonName;
    // Item.SubItems.Add('初始化');
    Item.SubItems.Add(states);
    ListView1.Items.EndUpdate;
  end
  else
  begin
    Item := (ListView1.FindCaption(0, Trim(tonName), True, True, True));
    ListView1.Items.BeginUpdate;
    if newName <> '' then
      Item.Caption := newName;
    if states <> '' then
      Item.SubItems.Strings[0] := states;
    ListView1.Items.EndUpdate;
  end;
end;

procedure TMainForm.CoolTrayIcon1Click(Sender: TObject);
begin
  if Application.MainForm.Visible then
    CoolTrayIcon1.HideMainForm
  else
    CoolTrayIcon1.ShowMainForm;
end;

function TMainForm.FindKey(const pid: Cardinal): string;
begin

end;

procedure TMainForm.FormActivate(Sender: TObject);
begin
  ShowWindow(Application.Handle, SW_HIDE);
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CoolTrayIcon1.HideMainForm;
  CanClose := False;

end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  CoolTrayIcon1.IconVisible := True;
  CoolTrayIcon1.HideMainForm;
  CoolTrayIcon1.Hint := '激战客户端多开';
  CoolTrayIcon1.ShowHint := True;
  CoolTrayIcon1.MinimizeToTray := True;
  UIMessage.DefalutHandle := Self.Handle;
  LoadJsonConfig;
  MainRun.Resume;
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  ShowWindow(Application.Handle, SW_HIDE);
end;

procedure TMainForm.LoadJsonConfig;
var
  email: string;
begin
  DataWalker.LoadJsonConfig;
  for email in dataRecords.Keys do
  begin
    Self.AddAccount(dataRecords[email].ton, '', '已就绪');
  end;
  DataWalker.reflushStatus;
end;

procedure TMainForm.ListView1DblClick(Sender: TObject);
var
  info: AccountInfo;
begin
  mutex.Enter;
  try
    if DataWalker.InitJob(Self.ListView1.Selected.Caption, info) then
    begin
      UIMessage.Update(Self.ListView1.Selected.Caption, InQueue);
    end;
  finally
    mutex.Leave;
  end;
end;

procedure TMainForm.N1Click(Sender: TObject);
begin
  Self.ListView1.Clear;
  LoadJsonConfig;
end;

procedure TMainForm.N2Click(Sender: TObject);
var
  f: TFAddForm;
begin
  f := TFAddForm.Create(Self);
  try
    f.ShowModal;
    if f.ModalResult = mrOk then
    begin
      AddAccount(f.key,'','已就绪');
    end;

  finally
    f.Free;
  end;
end;

procedure TMainForm.N3Click(Sender: TObject);
var
  m: TFModfiForm;
begin
  case Self.ListView1.SelCount of
    0:
      Exit;
    1:
      begin

        m := TFModfiForm.Create(Self, Self.ListView1.Selected.Caption);
        try
          m.ShowModal;
          if m.ModalResult = mrOk then
          begin
            Self.ListView1.Selected.Caption := m.key;
            ShowMessage('修改成功');
          end;
        finally
          m.Free;
        end;
      end;
  else
    begin
      MessageBox(0, '不支持批量修改账号!', '出错啦~!', MB_ICONERROR or MB_OK);
    end;
  end;
end;

procedure TMainForm.N4Click(Sender: TObject);
var
  I: Cardinal;
  DoJob:LongBool;
begin
  if Self.ListView1.Items.count = 0 then
    Exit;

  try
    Self.ListView1.Items.BeginUpdate;
    while Self.ListView1.Items.Count > 0 do
    begin
      DoJob:=False;
      for I := 0 to Self.ListView1.Items.count - 1 do
      begin
        if Self.ListView1.Items.Item[I].Selected then
        begin
          if DataWalker.Remove(Self.ListView1.Items.Item[I].Caption) then
          begin
            Self.ListView1.Items.Delete(I);
            DoJob:=True;
            Break;
          end
          else
          begin
            UIMessage.RaiseError(Delete_Failure);
            DoJob:=False;
            Break;
          end;
        end;
      end;
      if not DoJob  then Break;
    end;
    Self.ListView1.Items.EndUpdate;
  except

  end;
end;

procedure TMainForm.N5Click(Sender: TObject);
var
  info: AccountInfo;
  path: WideString;
  args: WideString;
  I: Cardinal;
begin
  if Self.ListView1.Items.count = 0 then
    Exit;
  for I := 0 to Self.ListView1.Items.count - 1 do
  begin
    if Self.ListView1.Items.Item[I].Selected then
    begin
      if DataWalker.InitJob(Self.ListView1.Items.Item[I].Caption, info) then
      begin
        UIMessage.Update(Self.ListView1.Items.Item[I].Caption, InQueue);
      end
      else
        Break;
    end;
  end;

end;

procedure TMainForm.N6Click(Sender: TObject);
var
  info: AccountInfo;
  path: WideString;
  args: WideString;
  I: Cardinal;
  action: TDWData;
begin
  if Self.ListView1.Items.count = 0 then
    Exit;
  for I := 0 to Self.ListView1.Items.count - 1 do
  begin
    if DataWalker.InitJob(Self.ListView1.Items.Item[I].Caption, info) then
    begin
      UIMessage.Update(Self.ListView1.Items.Item[I].Caption, InQueue);
    end
    else
      Break;
  end;

end;

procedure TMainForm.N7Click(Sender: TObject);
begin
  MessageDlg('激战多开器Ver1.0 ' + #13 + #10 + 'By Ranger', mtInformation, [mbOK],
    0);
end;

procedure TMainForm.N8Click(Sender: TObject);
begin
  MainRun.Terminate;
  MainRun.Free;
  Application.Terminate;
end;

procedure TMainForm.OnError(var msg: TMessage);
var
  ErrorMsg: ErrorType;
begin
  ErrorMsg := ErrorType(msg.LParam);
  case ErrorMsg of
    User_Duplicate_Name:
      begin
      end;
    User_NoExist_Name:
      begin

      end;
    Character_Duplicate_Name:
      begin

      end;
    Character_NoExist_Name:
      begin

      end;
    Job_HadInQueue:
      begin

      end;
    Job_HadRunning:
      begin

      end;
    Job_HadLaunching:
      begin

      end;
    Job_NoExist:
      begin

      end;
    Job_HadDeleted:
      begin

      end;
    Job_Unknow:
      begin

      end;
    Job_InError:
      begin

      end;
    Job_HadHung:
      begin

      end;
    Process_Cannot_Closed:
      begin
        ShowMessage('无法结束进程');
      end;
  else
    begin

    end;

  end;
end;

procedure TMainForm.WndProc(var _message: TMessage);
var
  cds: PCopyDataStruct;
  action: TDWData;
begin
  if _message.msg = WM_COPYDATA then
  begin
    if _message.WParam = Self.Handle then
    begin
      cds := PCopyDataStruct(_message.LParam);
      action := TDWData(cds.dwData);
      case MessageType(action.Kind) of
        UpdateStatus:
          begin
            case JobStatus(action.value) of
              Runnning:
                begin
                  Self.AddAccount(PWideChar(cds.lpData), '', '运行中');
                end;
              InQueue:
                begin
                  Self.AddAccount(PWideChar(cds.lpData), '', '排队中');
                end;
              Launching:
                begin
                  Self.AddAccount(PWideChar(cds.lpData), '', '启动中');
                end;
              Ready:
                begin
                  Self.AddAccount(PWideChar(cds.lpData), '', '已就绪');
                end;
              Deleted:
                begin
                  Self.AddAccount(PWideChar(cds.lpData), '', '没任务');
                end;
              UnKnow:
                begin
                  Self.AddAccount(PWideChar(cds.lpData), '', '没状态');
                end;
              InError:
                begin
                  Self.AddAccount(PWideChar(cds.lpData), '', '已出错');
                end;
            else
              begin
                { TODO : do something }
              end;
            end;
          end;
      else
        begin

          //
        end;
      end;
    end
    else
    begin
      inherited WndProc(_message);
    end;
  end
  else
    inherited WndProc(_message);

end;

{ TMainRun }

constructor TMainRun.Create(CreateSuspended: Boolean);
begin
  inherited;
  FreeOnTerminate := False;
  Self.FScanTimeeScapedWithJobs := 5000;
  Self.FScanTimeeScapedWithOutJobs := 2000;
  Self.FlaunchDelayTime := 5000;
end;

destructor TMainRun.Destroy;
begin

end;

procedure TMainRun.execute;
var
  info: AccountInfo;
  path: WideString;
  args: WideString;
  IsJobHung: LongBool;
  deadLock: Cardinal;
  isTimeOut: LongBool;
  GwMainHandle: Cardinal;
begin

  try
    Self.scanReset;
    Self.launchDelayReSet;
    IsJobHung := False;
    while not Terminated do
    begin
      SleepEx(200, False);
      if not IsJobHung then
      begin
        mutex.Enter;
        if DataWalker.Tasks.count > 0 then
        begin
          if scanTime > FScanTimeeScapedWithJobs then
          begin
            mutex.Leave;
            reflushStatus;
            scanReset;
            Continue;
          end
          else
          begin
            info := DataWalker.Tasks.Extract;
            DataWalker.Tasks.TrimExcess;
            info.status := Launching;
            dataRecords.AddOrSetValue(info.email, info);
            UIMessage.Update(dataRecords[info.email].ton, Launching);
            IsJobHung := True;
            mutex.Leave;
          end;
        end
        else
        begin
          mutex.Leave;
          if scanTime > FScanTimeeScapedWithOutJobs then
          begin
            reflushStatus;
            scanReset;
            Continue;
          end;
        end;
      end
      else
      begin
        if GetlaunchDelayTime > FlaunchDelayTime then
        begin
          path := info.path;
          args := ForamtArgs(info);
          if not MyLaunchClient(path, args, info.datPath, True, info.ELEVATED)
            then
          begin
            info.status := InError;
            dataRecords.AddOrSetValue(info.email, info);
            UIMessage.Update(dataRecords[info.email].ton, InError);
            launchDelayReSet;
            IsJobHung := False;
            Continue;
          end;
          deadLock := GetTickCount;
          isTimeOut := False;

          repeat
            if (GetTickCount - deadLock) < 1000 * 20 then
            begin
              if not Self.wait(20) then
                Exit;
            end
            else
            begin
              isTimeOut := True;
              Break;
            end;
          until ProcessHelper.find_main_window(CurrPid) <> 0;
          if Not isTimeOut then
          begin
           deadLock := GetTickCount;
           isTimeOut := False;
            repeat
            if (GetTickCount - deadLock) < 1000 * 10 then
              begin
                PostKeyExHWND(GwMainHandle, 80, [], False);
                if not Self.wait(20) then
                  Exit;
              end
              else
              begin
                isTimeOut := True;
                Break;
              end;
            GwMainHandle := GwMemoryHelper.FindWinHandle(CurrPid);
             until GwMainHandle <> 0;
            if GwMainHandle = 0 then
            begin
              info.status := InError;
              dataRecords.AddOrSetValue(info.email, info);
              UIMessage.Update(dataRecords[info.email].ton, InError);
              launchDelayReSet;
              IsJobHung := False;
              Continue;
            end;


            deadLock := GetTickCount;
            isTimeOut := False;
            repeat
              if (GetTickCount - deadLock) < 1000 * 10 then
              begin
                PostKeyExHWND(GwMainHandle, 80, [], False);
                if not Self.wait(20) then
                  Exit;
              end
              else
              begin
                isTimeOut := True;
                Break;
              end;
            until (GwMemoryHelper.getCharName(CurrPid) <> '') and GwMemoryHelper.IsInGame(CurrPid);
            if isTimeOut then
            begin
              info.status := InError;
              dataRecords.AddOrSetValue(info.email, info);
              UIMessage.Update(dataRecords[info.email].ton, InError);
            end
            else
            begin
              info.status := Runnning;
              dataRecords.AddOrSetValue(info.email, info);
              UIMessage.Update(dataRecords[info.email].ton, Runnning);
            end;
          end
          else
          begin
            info.status := InError;
            dataRecords.AddOrSetValue(info.email, info);
            UIMessage.Update(dataRecords[info.email].ton, InError);
          end;
          launchDelayReSet;
          IsJobHung := False;
        end;
      end;
    end;
  finally
    try
      mutex.Leave;
    except

    end;
  end;

end;

procedure TMainRun.reflushStatus;
begin
  DataWalker.reflushStatus;
end;

procedure TMainRun.scanReset;
begin
  Self.FscanTimer := GetTickCount;
end;

function TMainRun.scanTime: Cardinal;
begin
  Result := GetTickCount - Self.FscanTimer;
end;

function TMainRun.wait(const count: Cardinal;
  PerDelay: Cardinal = 50): LongBool;
var
  lCount: Cardinal;
begin
  Result := True;
  lCount := count;
  if lCount = 0 then
    Exit;
  for lCount := 0 to lCount - 1 do
  begin
    if Terminated then
      Exit(False)
    else
      Sleep(PerDelay);
  end;

end;

class function TMainRun.ForamtArgs(var info: AccountInfo): string;
begin
  Result := '-email "' + info.email + '" -password "' + info.psw +
    '" -character "' + info.ton + '"';
end;

function TMainRun.GetlaunchDelayTime: Cardinal;
begin
  Result := GetTickCount - Self.FlaunchTimer;
end;

procedure TMainRun.launchDelayReSet;
begin
  Self.FlaunchTimer := GetTickCount;
end;

procedure PostKeyExHWND(hWindow: HWnd; key: Word; const shift: TShiftState;
  specialkey: Boolean);
type
  TBuffers = array [0 .. 1] of TKeyboardState;
var
  pKeyBuffers: ^TBuffers;
  LParam: LongInt;
begin
  if IsWindow(hWindow) then
  begin
    pKeyBuffers := nil;
    LParam := MakeLong(0, MapVirtualKey(key, 0));
    if specialkey then
      LParam := LParam or $1000000;
    New(pKeyBuffers);
    try
      GetKeyboardState(pKeyBuffers^[1]);
      FillChar(pKeyBuffers^[0], SizeOf(TKeyboardState), 0);
      if ssShift in shift then
        pKeyBuffers^[0][VK_SHIFT] := $80;
      if ssAlt in shift then
      begin
        pKeyBuffers^[0][VK_MENU] := $80;
        LParam := LParam or $20000000;
      end;
      if ssCtrl in shift then
        pKeyBuffers^[0][VK_CONTROL] := $80;
      if ssLeft in shift then
        pKeyBuffers^[0][VK_LBUTTON] := $80;
      if ssRight in shift then
        pKeyBuffers^[0][VK_RBUTTON] := $80;
      if ssMiddle in shift then
        pKeyBuffers^[0][VK_MBUTTON] := $80;
      SetKeyboardState(pKeyBuffers^[0]);
      if ssAlt in shift then
      begin
        PostMessage(hWindow, WM_SYSKEYDOWN, key, LParam);
        PostMessage(hWindow, WM_SYSKEYUP, key, LParam or $C0000000);
      end
      else
      begin
        PostMessage(hWindow, WM_KEYDOWN, key, LParam);
        PostMessage(hWindow, WM_KEYUP, key, LParam or $C0000000);
      end;
      Application.ProcessMessages;
      SetKeyboardState(pKeyBuffers^[1]);
    finally
      if pKeyBuffers <> nil then
        Dispose(pKeyBuffers);
    end;
  end;
end; { PostKeyEx }

initialization

MainRun := TMainRun.Create(True);

finalization

end.
