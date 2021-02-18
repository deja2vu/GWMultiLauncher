object TestForm: TTestForm
  Left = 0
  Top = 0
  Caption = 'TestForm'
  ClientHeight = 336
  ClientWidth = 635
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Button1: TButton
    Left = 120
    Top = 80
    Width = 75
    Height = 25
    Caption = 'Test'
    TabOrder = 0
    OnClick = Button1Click
  end
  object Edit1: TEdit
    Left = 120
    Top = 32
    Width = 121
    Height = 21
    TabOrder = 1
  end
  object Edit2: TEdit
    Left = 352
    Top = 32
    Width = 121
    Height = 21
    TabOrder = 2
  end
  object Button2: TButton
    Left = 272
    Top = 80
    Width = 75
    Height = 25
    Caption = 'KillProcess'
    TabOrder = 3
  end
  object Button3: TButton
    Left = 510
    Top = 80
    Width = 99
    Height = 25
    Caption = 'GetProcessPath'
    TabOrder = 4
    OnClick = Button3Click
  end
  object Button4: TButton
    Left = 120
    Top = 160
    Width = 75
    Height = 25
    Caption = 'GetProcessExit'
    TabOrder = 5
    OnClick = Button4Click
  end
end
