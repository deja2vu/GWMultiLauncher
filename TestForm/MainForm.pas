unit MainForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TTestForm = class(TForm)
    Button1: TButton;
    Edit1: TEdit;
    Edit2: TEdit;
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  TestForm: TTestForm;

implementation
uses
NtProcessHelper;
{$R *.dfm}

procedure TTestForm.Button1Click(Sender: TObject);
var
pro:ProcessHelper.PSYSTEM_PROCESS;
th:ProcessHelper.PSYSTEM_THREAD;
begin
GwMemoryHelper.ReSet;
GwMemoryHelper.Capture;
pro:=GwMemoryHelper.FindProcessByPid(StrToInt(Edit1.Text));
if pro <> nil then
begin
 th:=GwMemoryHelper.FindThreadByTid(pro,StrToInt(Edit2.text));
 if th<> nil then
 begin
   ShowMessage(IntToStr(Integer(th.ThreadState)));
 end;
end;
end;

end.
