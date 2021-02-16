unit Add;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, Buttons,JsonHelper,DictHelper;

type
  TFAddForm = class(TForm)
    Panel1: TPanel;
    StaticText1: TStaticText;
    Edit_Account: TEdit;
    StaticText2: TStaticText;
    Edit_password: TEdit;
    StaticText3: TStaticText;
    Edit_tonName: TEdit;
    StaticText4: TStaticText;
    Edit_GamePath: TEdit;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    StaticText5: TStaticText;
    Edit_Ex_Args: TEdit;
    CheckBox_datPatch: TCheckBox;
    CheckBox_ELEVATED: TCheckBox;
    SpeedButton3: TSpeedButton;
    FileOpenDialog1: TFileOpenDialog;
    procedure SpeedButton1Click(Sender: TObject);
    procedure SpeedButton3Click(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
    procedure CheckBox_datPatchClick(Sender: TObject);
  protected
     function CheckNull:LongBool;
     function CheckUserName(const userName:string):LongBool;
     function CheckPath(const path:string):LongBool;
  public
    Key:string;
  end;

  TFModfiForm = class(TFAddForm)
  private
  FName:string;
  info:AccountInfo;
  private
  procedure FormCreate(Sender: TObject);
  procedure OnSave(Sender: TObject);
  public
  constructor Create(AOwner: TComponent;const name:string); overload;
  end;
{
var
  FAddForm: TFAddForm;
}
implementation
uses
RecodHelper,PerlRegEx;
{$R *.dfm}



procedure TFAddForm.CheckBox_datPatchClick(Sender: TObject);
begin
if CheckBox_datPatch.Checked then
begin
if MessageBox(
0, '确定要共享客户端程序吗？'+#13+#10+'此选项一旦选中，多个客户端可以共享一个程序文件'+#13+#10+'同时但是会导致程序不稳定，不建议开启,点[确定]启用', '警告', MB_ICONASTERISK or MB_OKCANCEL) =
1 then
CheckBox_datPatch.Checked:=True
else
CheckBox_datPatch.Checked:=False;
end;

end;

function TFAddForm.CheckNull: LongBool;
begin
Result:=False;
if Self.Edit_Account.Text = '' then
begin
 ShowMessage('账户名不能未空');
 Exit;
end;
if Self.Edit_tonName.Text = '' then
begin
 ShowMessage('角色名不能未空');
 Exit;
end;
if Self.Edit_password.Text = '' then
begin
 ShowMessage('密码不能未空');
 Exit;
end;
if Self.Edit_GamePath.Text = '' then
begin
 ShowMessage('游戏路径不能未空');
 Exit;
end;
 Result:=True;
end;

function TFAddForm.CheckPath(const path: string): LongBool;
var
reg:TPerlRegEx;
begin
   Result:=False;
   reg:=TPerlRegEx.Create;
    try
    reg.Subject:=path;
    reg.RegEx:='^[A-Za-z]{1}:\\([^\\/\:\*\"\<\>\|\?]|[\x{4e00}-\x{9fa5}])*\\([^\\/\:\*\"\<\>\|\?]|[\x{4e00}-\x{9fa5}])+$';
    Result:=reg.Match;
    if not Result then   ShowMessage('路径格式不对');
    finally
     reg.Free;
    end;
end;

function TFAddForm.CheckUserName(const userName: string): LongBool;
var
reg:TPerlRegEx;
begin
   Result:=False;
   reg:=TPerlRegEx.Create;
    try
    reg.Subject:=userName;
    reg.RegEx:='^[a-z0-9A-Z]+@[a-z0-9A-Z]+\.[a-zA-Z]+$';
    Result:=reg.Match;
    if not Result then   ShowMessage('邮箱格式不对');
    finally
     reg.Free;
    end;
end;

procedure TFAddForm.SpeedButton1Click(Sender: TObject);
begin
if Self.Edit_password.PasswordChar = WideChar(#0) then
    Self.Edit_password.PasswordChar :=WideChar('*')
    else
    Self.Edit_password.PasswordChar := WideChar(#0);
end;




procedure TFAddForm.SpeedButton2Click(Sender: TObject);
begin
 FileOpenDialog1.Options:= [fdoStrictFileTypes, fdoPathMustExist, fdoForceFileSystem];
 if FileOpenDialog1.Execute then
 begin
 Edit_GamePath.Text:=FileOpenDialog1.FileName;
 end;
end;

procedure TFAddForm.SpeedButton3Click(Sender: TObject);
var
Local_info:AccountInfo;
begin
   if Not CheckNull then  Exit;
   if not CheckPath(Edit_GamePath.Text) then Exit;
   if not CheckUserName(Edit_Account.Text) then Exit;



     if  DataWalker.TheKeyHasTheValue('email',Edit_account.Text)  then
     begin
     MessageBox(0, PWideChar('账号:' + Edit_account.Text + ',已经存在') , '出错了~!', MB_ICONEXCLAMATION or MB_OK);
     Exit;
     end;
     if  DataWalker.TheKeyHasTheValue('character',Edit_tonName.Text)  then
     begin
     MessageBox(0, PWideChar('角色:' + Edit_tonName.Text + ',已经存在') , '出错了~!', MB_ICONEXCLAMATION or MB_OK);
     Exit;
     end;
        Local_info.email:=Self.Edit_Account.Text;
        Local_info.ton:=Self.Edit_tonName.Text;
        Local_info.path:=Self.Edit_GamePath.Text;
        Local_info.psw:=Self.Edit_password.Text;
        Local_info.ExArgs:=self.Edit_Ex_Args.Text;
        Local_info.datPath:=Self.CheckBox_datPatch.Checked;
        Local_info.elevated:=Self.CheckBox_ELEVATED.Checked;
        Local_info.mods:=nil;
        Local_info.status:=Ready;
        if not DataWalker.Add(Local_info) then
        begin
         Exit;
        end;
      Self.Key:= Edit_tonName.Text;
      ModalResult:=mrOk;

end;

{ TFModfiForm }

constructor TFModfiForm.Create(AOwner: TComponent;const name:string);
begin
  inherited Create(AOwner);
  Self.SpeedButton3.Caption:='修改';
  Self.Caption:='修改账号:' + name;
  Self.FName:=name;
  Self.OnCreate:=Self.FormCreate;
  self.SpeedButton3.OnClick:=Self.OnSave;
end;

procedure TFModfiForm.FormCreate(Sender: TObject);

begin

        Self.Edit_tonName.Text:=Self.FName;
        try
       if  FindAcount(Self.FName,info) then
       begin
        Self.Edit_Account.Text:=info.email;
        Self.Edit_GamePath.Text:=info.path;
        self.Edit_password.Text:=info.psw;
        self.Edit_Ex_Args.Text:=info.ExArgs;
        if info.datPath then
        Self.CheckBox_datPatch.Checked:=True
        else
        Self.CheckBox_datPatch.Checked:=False;
        if info.elevated then
        Self.CheckBox_ELEVATED.Checked:=True
        else
        Self.CheckBox_ELEVATED.Checked:=False;
        end
        else
        ShowMessage('出错了~!');
        except

        end;

end;

procedure TFModfiForm.OnSave(Sender: TObject);
var
Local_info:AccountInfo;
begin
   if Not CheckNull then  Exit;
   if not CheckPath(Edit_GamePath.Text) then Exit;
   if not CheckUserName(Edit_Account.Text) then Exit;

     if   DataWalker.TheKeyHasTheValue('email',Edit_account.Text)  and  (Not SameText(Edit_account.Text,info.email))  then
     begin
     MessageBox(0, PWideChar('账号:' + Edit_account.Text + ',已经存在') , '出错了~!', MB_ICONEXCLAMATION or MB_OK);
     Exit;
     end;
     if  DataWalker.TheKeyHasTheValue('character',Edit_tonName.Text) and (Not SameText(Edit_tonName.Text,info.ton))  then
     begin
     MessageBox(0, PWideChar('角色:' + Edit_tonName.Text + ',已经存在') , '出错了~!', MB_ICONEXCLAMATION or MB_OK);
     Exit;
     end;
        Local_info:=info;
        Local_info.email:=Self.Edit_Account.Text;
        Local_info.ton:=Self.Edit_tonName.Text;
        Local_info.path:=Self.Edit_GamePath.Text;
        Local_info.psw:=Self.Edit_password.Text;
        Local_info.ExArgs:=self.Edit_Ex_Args.Text;
        Local_info.datPath:=Self.CheckBox_datPatch.Checked;
        Local_info.elevated:=Self.CheckBox_ELEVATED.Checked;
        Local_info.mods:=nil;

        if not DataWalker.Modify(info.email,Local_info) then Exit;

      Self.Key:= Edit_tonName.Text;
      ModalResult:=mrOk;

end;

end.
