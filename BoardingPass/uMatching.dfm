object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'DOS Truck & Port Matching'
  ClientHeight = 824
  ClientWidth = 1107
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  WindowState = wsMaximized
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Memo1: TMemo
    Left = 8
    Top = 8
    Width = 1600
    Height = 49
    Lines.Strings = (
      
        'Select  t.fwarehouse, t.frun , t.fvehicle_type , t.fshipdate, s.' +
        'fship_from_time , td.fdistance from tTrip t , tTrip_Detail td , ' +
        'tshipment s'
      
        'where t.frun=td.fmaster and td.fshipment=s.frun and t.fwarehouse' +
        ' = 2'
      
        'order by t.fwarehouse,t.fshipdate ,t.frun, s.fship_from_time , t' +
        '.frun and td.forder =1 and t.fvehicle <> '#39#39';')
    TabOrder = 0
  end
  object DBGrid1: TDBGrid
    Left = 8
    Top = 261
    Width = 1600
    Height = 148
    DataSource = DataSource1
    TabOrder = 1
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'Tahoma'
    TitleFont.Style = []
  end
  object Button1: TButton
    Left = 8
    Top = 230
    Width = 75
    Height = 25
    Caption = 'Generate'
    TabOrder = 2
    OnClick = Button1Click
  end
  object Memo2: TMemo
    Left = 8
    Top = 63
    Width = 1600
    Height = 49
    Lines.Strings = (
      
        'Select il.flocation , sum(sd.fvolume*tds.fquantity) from ttrip t' +
        ' , ttrip_detail td , tshipment s , ttrip_detail_shipment tds , t' +
        'shipment_detail sd , titem i , titem_location il , tlocation l'
      
        'where t.frun=td.fmaster and td.fshipment=s.frun and td.frun=tds.' +
        'fmaster and tds.fshipment = sd.frun and i.fcode=sd.fitemnumber a' +
        'nd il.fitem=i.frun and l.frun=i.flocation and '
      'l.fwarehouse=t.fwarehouse and t.frun= 676 group by il.flocation;')
    TabOrder = 3
  end
  object Memo3: TMemo
    Left = 8
    Top = 120
    Width = 1600
    Height = 49
    Lines.Strings = (
      
        'Select  t.fwarehouse, t.frun , t.fvehicle_type , t.fshipdate, s.' +
        'fship_from_time , td.fdistance from tTrip t , tTrip_Detail td , ' +
        'tshipment s'
      
        'where t.frun=td.fmaster and td.fshipment=s.frun and t.frun = 676' +
        ' '
      
        'order by t.fwarehouse,t.fshipdate , s.fship_from_time , t.frun a' +
        'nd td.forder =1 and t.fvehicle <> '#39#39';')
    TabOrder = 4
  end
  object Memo4: TMemo
    Left = 8
    Top = 175
    Width = 1600
    Height = 49
    Lines.Strings = (
      
        'Select il.flocation , sum(sd.fvolume*tds.fquantity) from ttrip t' +
        ' , ttrip_detail td , tshipment s , ttrip_detail_shipment tds , t' +
        'shipment_detail sd , titem i , titem_location il , tlocation l'
      
        'where t.frun=td.fmaster and td.fshipment=s.frun and td.frun=tds.' +
        'fmaster and tds.fshipment = sd.frun and i.fcode=sd.fitemnumber a' +
        'nd il.fitem=i.frun and l.frun=i.flocation and '
      'l.fwarehouse=t.fwarehouse and t.frun= 676 group by il.flocation;')
    TabOrder = 5
  end
  object Edit1: TEdit
    Left = 89
    Top = 230
    Width = 121
    Height = 25
    AutoSize = False
    TabOrder = 6
    Text = 'T210924001'
  end
  object Panel1: TPanel
    Left = 0
    Top = 415
    Width = 1107
    Height = 409
    Align = alBottom
    TabOrder = 7
    object Memo5: TMemo
      Left = 1
      Top = 1
      Width = 737
      Height = 407
      Align = alLeft
      Lines.Strings = (
        'Memo5')
      ScrollBars = ssBoth
      TabOrder = 0
    end
    object Memo6: TMemo
      Left = 738
      Top = 1
      Width = 368
      Height = 407
      Align = alClient
      ScrollBars = ssBoth
      TabOrder = 1
      ExplicitLeft = 744
      ExplicitTop = 0
    end
  end
  object dt: TDateTimePicker
    Left = 216
    Top = 232
    Width = 113
    Height = 21
    Date = 44439.000000000000000000
    Time = 0.490718356479192200
    TabOrder = 8
  end
  object UniConnection1: TUniConnection
    ProviderName = 'MySQL'
    Port = 63308
    Database = 'dos'
    Username = 'admindb'
    Server = '147.50.139.163'
    LoginPrompt = False
    Left = 8
    Top = 464
    EncryptedPassword = 'CEFF92FF8CFFAFFF9EFF8CFF8CFF88FFCFFF8DFF9BFFDCFF'
  end
  object MySQLUniProvider1: TMySQLUniProvider
    Left = 40
    Top = 464
  end
  object UniQuery1: TUniQuery
    Connection = UniConnection1
    Left = 72
    Top = 464
  end
  object DataSource1: TDataSource
    DataSet = UniQuery1
    Left = 104
    Top = 464
  end
  object ClientDataSet1: TClientDataSet
    Aggregates = <>
    Params = <>
    Left = 408
    Top = 304
  end
  object Timer1: TTimer
    Enabled = False
    Interval = 30000
    OnTimer = Timer1Timer
    Left = 8
    Top = 520
  end
  object IdHTTP1: TIdHTTP
    AllowCookies = True
    ProxyParams.BasicAuthentication = False
    ProxyParams.ProxyPort = 0
    Request.ContentLength = -1
    Request.ContentRangeEnd = -1
    Request.ContentRangeStart = -1
    Request.ContentRangeInstanceLength = -1
    Request.Accept = 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
    Request.BasicAuthentication = False
    Request.UserAgent = 'Mozilla/3.0 (compatible; Indy Library)'
    Request.Ranges.Units = 'bytes'
    Request.Ranges = <>
    HTTPOptions = [hoForceEncodeParams]
    Left = 8
    Top = 584
  end
end
