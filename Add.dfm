object FAddForm: TFAddForm
  Left = 0
  Top = 0
  BorderStyle = bsSingle
  Caption = #26032#22686#36134#25143
  ClientHeight = 275
  ClientWidth = 259
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 259
    Height = 275
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    object SpeedButton1: TSpeedButton
      Left = 223
      Top = 55
      Width = 23
      Height = 22
      Caption = '*'
      OnClick = SpeedButton1Click
    end
    object SpeedButton2: TSpeedButton
      Left = 223
      Top = 135
      Width = 23
      Height = 22
      Glyph.Data = {
        36030000424D3603000000000000360000002800000010000000100000000100
        18000000000000030000C40E0000C40E00000000000000000000FACEBCFBCDB6
        FACDB5FBCDB9FBCDB6FACDB5FBCDB6FACDB5FBCDB6FACDB5FBCDB6FACDB5FBCD
        B9F2C4B0FFFFFFB99D7FFCD3C2FBCEB6FCCFB3FCCDB7FBCEB6FCCFB3FBCEB6FC
        CFB3FBCEB6FCCFB3FBCEB6FCCFB3FCCDB7F3C6B1FFFFFFB99D7FFDD9CAFCD1BA
        FCD3BAFCD0BAFCD1BAFCD3BAFCD1BAFCD3BAFCD1BAFCD3BAFCD1BAFCD3BAFCD0
        BAF5C8B3FFFFFFB99D7FFDD9CAFCD1BAFCD3BA3399CC00669900669900669900
        6699006699006699006699FCD3BAFCD0BAF5C8B3FFFFFFB99D7FFDDBCEFCD3C2
        3399CC66CCFF3399CC99FFFF66CCFF66CCFF66CCFF66CCFF3399CC006699FBD3
        C1F2C9B8FFFFFFB99D7FFDDBCEFCD3C23399CC66CCFF3399CC99FFFF99FFFF99
        FFFF99FFFF99FFFF66CCFF006699FBD3C1F2C9B8FFFFFFB99D7FFCDDD0FDD5C3
        3399CC66CCFF3399CC99FFFF99FFFF99FFFF99FFFF99FFFF66CCFF006699FDD3
        C3F3C9B9FFFFFFB99D7FFCDDD0FDD5C33399CC66CCFF3399CCCCFFFFCCFFFFCC
        FFFFCCFFFFCCFFFF99FFFF006699FDD3C3F3C9B9FFFFFFB99D7FFCDDD0FDD5C3
        3399CC99FFFF99FFFF3399CC3399CC3399CC3399CC3399CC3399CC3399CCFDD3
        C3F3C9B9FFFFFFB99D7FFDE0D1FDD6C63399CCCCFFFF99FFFF99FFFF99FFFFCC
        FFFFCCFFFFCCFFFF006699FCD6C5FDD5C6F3C9B9FFFFFFB99D7FFDE0D1FDD6C6
        FCD6C53399CCCCFFFFCCFFFFCCFFFF3399CC3399CC3399CCFDD6C6FCD6C5FDD5
        C6F3C9B9FFFFFFB99D7FFCE1D4FBD6C8FBD6C8FBD8C83399CC3399CC3399CCFB
        D6C8FBD6C8FBD6C8FBD6C8FBD6C8FBD8C8F3C9B9FFFFFFB99D7FFCE1D4FBD6C8
        FBD6C8FBD8C8FBD6C8FBD6C8FBD6C8FBD6C8FBD6C8FBD6C8FBD6C8FBD6C8FBD8
        C8F3C9B9FFFFFFB99D7FFEE6DAFBD8C8FBD6C8FDD8CAFBD8C8FBD6C8FBD8C8FB
        D6C8FBD8C8FBD6C8FBD8C8FBD6C8FDD8CAF2C9B8FFFFFFB99D7FFEEAE1FBD6C8
        FCD5C5FCD8C9FBD6C8FCD5C5FBD6C8FCD5C5FBD6C8FCD5C5FBD6C8FCD5C5FCD8
        C9F1C6B7FFFFFFB99D7FFCDFD0F5CAB7F6C8B4F6CBB8F5CAB7F6C8B4F5CAB7F6
        C8B4F5CAB7F6C8B4F5CAB7F6C8B4F6CBB8F8E3DBFFFFFFB99D7F}
      OnClick = SpeedButton2Click
    end
    object SpeedButton3: TSpeedButton
      Left = 165
      Top = 241
      Width = 81
      Height = 22
      Caption = #26032#22686
      OnClick = SpeedButton3Click
    end
    object StaticText1: TStaticText
      Left = 16
      Top = 16
      Width = 56
      Height = 17
      Caption = #36134#21495#21517#31216':'
      TabOrder = 0
    end
    object Edit_Account: TEdit
      Left = 72
      Top = 16
      Width = 177
      Height = 21
      TabOrder = 1
      TextHint = #35831#36755#20837#36134#21495#30340#21517#31216
    end
    object StaticText2: TStaticText
      Left = 16
      Top = 59
      Width = 56
      Height = 17
      Caption = #36134#21495#23494#30721':'
      TabOrder = 2
    end
    object Edit_password: TEdit
      Left = 72
      Top = 55
      Width = 145
      Height = 21
      AutoSelect = False
      BevelEdges = [beBottom]
      BevelInner = bvNone
      BevelOuter = bvNone
      HideSelection = False
      PasswordChar = '*'
      TabOrder = 3
      TextHint = #35831#36755#20837#28608#25112#30340#23494#30721
    end
    object StaticText3: TStaticText
      Left = 16
      Top = 99
      Width = 56
      Height = 17
      Caption = #35282#33394#21517#31216':'
      TabOrder = 4
    end
    object Edit_tonName: TEdit
      Left = 72
      Top = 99
      Width = 177
      Height = 21
      TabOrder = 5
      TextHint = #35831#36755#20837#35282#33394#21517
    end
    object StaticText4: TStaticText
      Left = 16
      Top = 139
      Width = 56
      Height = 17
      Caption = #28216#25103#36335#24452':'
      TabOrder = 6
    end
    object Edit_GamePath: TEdit
      Left = 72
      Top = 135
      Width = 145
      Height = 21
      TabOrder = 7
      TextHint = #35831#36755#20837#28608#25112#23458#25143#31471#30340#36335#24452
    end
    object StaticText5: TStaticText
      Left = 16
      Top = 180
      Width = 56
      Height = 17
      Caption = #21551#21160#21442#25968':'
      TabOrder = 8
    end
    object Edit_Ex_Args: TEdit
      Left = 72
      Top = 180
      Width = 177
      Height = 21
      TabOrder = 9
    end
    object CheckBox_datPatch: TCheckBox
      Left = 16
      Top = 215
      Width = 97
      Height = 17
      Hint = #20849#20139#28608#25112#30340'dat'#25991#20214
      Caption = #20849#20139'.dat'#25991#20214
      TabOrder = 10
      OnClick = CheckBox_datPatchClick
    end
    object CheckBox_ELEVATED: TCheckBox
      Left = 16
      Top = 246
      Width = 97
      Height = 17
      Hint = #21551#29992#31649#29702#21592#26435#38480
      Caption = #31649#29702#21592#26435#38480
      TabOrder = 11
    end
  end
  object FileOpenDialog1: TFileOpenDialog
    FavoriteLinks = <>
    FileTypes = <>
    Options = []
    Left = 112
    Top = 208
  end
end
