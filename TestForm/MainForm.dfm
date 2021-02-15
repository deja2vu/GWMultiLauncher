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
    Left = 216
    Top = 152
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
end
