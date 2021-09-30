unit uMatching;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, UniProvider, MySQLUniProvider, Data.DB,
  DBAccess, Uni, Vcl.StdCtrls, Vcl.Grids, Vcl.DBGrids, MemDS, Datasnap.DBClient,
  Vcl.ExtCtrls, IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient,
  IdHTTP, Math, INIFiles, ClipBrd, Vcl.ComCtrls;

type
  TForm1 = class(TForm)
    UniConnection1: TUniConnection;
    MySQLUniProvider1: TMySQLUniProvider;
    UniQuery1: TUniQuery;
    Memo1: TMemo;
    DBGrid1: TDBGrid;
    DataSource1: TDataSource;
    Button1: TButton;
    Memo2: TMemo;
    Memo3: TMemo;
    Memo4: TMemo;
    ClientDataSet1: TClientDataSet;
    Edit1: TEdit;
    Timer1: TTimer;
    IdHTTP1: TIdHTTP;
    Panel1: TPanel;
    Memo5: TMemo;
    Memo6: TMemo;
    dt: TDateTimePicker;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    { Private declarations }
    cServer, cUserName, cPassword, cDatabase, DirPath : String;
    cPort : Integer;

  public
    { Public declarations }
  end;

var
  Form1: TForm1;

function Str2Int(S : String) : Integer;
Function Str2Float(S : String) : Double;
Function GetColumn(C : Integer;S : String) : String;
Function GetColumnChar(C : Integer;S : String;Ch : Char) : String;
Function LatLong3Digit(LatLon : String) : String;

implementation

{$R *.dfm}


function Str2Int(S : String) : Integer;
Var Code : Integer;
Begin
   Val(S,Result,Code);
End;

Function Str2Float(S : String) : Double;
Var L1,Code : Integer;
    SS : String;
    HaveDot,HaveMinus : Boolean;
Begin
   SS := '';
   HaveDot := False;
   HaveMinus := False;
   For L1 := 1 To Length(S) Do
   Begin
      If S[L1] In ['0'..'9','.','-'] Then
      Begin
         If (S[L1] = '-')  Then
         Begin
            If (Not HaveMinus) Then
            Begin
               HaveMinus := True;
               SS := SS + S[L1];
            End;
         End Else
         If (S[L1] = '.') Then
         Begin
            If (Not HaveDot) Then
            Begin
               HaveDot := True;
               SS := SS + S[L1];
            End;
         End Else
         Begin
            SS := SS + S[L1];
         End;
      End;
   End;
   Try
      Val(SS,Result,Code);
   Except
      Result := 0;
   End;
End;

Function GetColumn(C : Integer;S : String) : String;
Var CC : Integer;
    L1 : Integer;
Begin
   Dec(C);
   CC := 0;
   S := S + #255;
   Result := '';
   For L1 := 1 To Length(S) Do
   Begin
      If S[L1] = #255 Then
      Begin
         If C = CC Then
         Begin
            Break;
         End;
         Inc(CC);
      End Else
      If C = CC Then
      Begin
         Result := Result + S[L1];
      End;
   End;
End;

Function GetColumnChar(C : Integer;S : String;Ch : Char) : String;
Var CC : Integer;
    L1 : Integer;
Begin
   Dec(C);
   CC := 0;
   S := S + Ch;
   Result := '';
   For L1 := 1 To Length(S) Do
   Begin
      If S[L1] = Ch Then
      Begin
         If C = CC Then
         Begin
            Break;
         End;
         Inc(CC);
      End Else
      If C = CC Then
      Begin
         Result := Result + S[L1];
      End;
   End;
End;

Function LatLong3Digit(LatLon : String) : String;
Var s, ss : String;
    i : Integer;
Begin
  ss := '';
  s := GetColumnChar(2, LatLon, '.');
  for i := 1 to 3 do
  Begin
    if i > Length(s) then
    Begin
      ss := ss + '0';
    End Else
    Begin
      ss := ss + s[i];
    End;
  End;
  Result := GetColumnChar(1, LatLon, '.') + '.' + ss;
End;


Procedure GenSQL(TRIPA : Array Of String;QQ : TUniQuery;O : TStrings; c : TUniConnection);
Const MaxElement=100;
Var CD : TClientDataSet;
    LOCATION : String;
    VOLUME : Integer;
    ORDER : Integer;
    SHARE : Integer;
    TIME : Double;
    WH_TIME : Double;
    ShareList : TStrings;
    Share_Percent : Double;
    Goto_Time : TDateTime;
    WareHouse_ID : Integer;
    TRIP, s, ss, TripRun, Temp, SQL, fCheckIn, fCheckOut, Docking, TempLOCATION, Branch : String;
    TripData : Array[1..20, 1..2] Of String;
    BoardD2CData, BoardWhoData : Array[1..20, 1..2, 0..20] Of String;
    BoardD2CCount, BoardWhoCount, VehVol, LocRun : Integer;
    LocList, DockList : TStrings;
    Q, Q2, QBranch : TUniQuery;
    Morning, LastLoc : Boolean;
    TripDate : TDateTime;
    D, DD, D2COut, B2B : Double;

    VolumeSummary : Array[0..MaxElement] Of
    Record
      Sum : Integer;
      Max : Integer;
      Max_ID : Integer;
      Order_ID : Integer;
    End;

    TimeSummary : Array[0..MaxElement] Of
    Record
      Sum : Integer;
      WH_Sum : Integer;
    End;

    TravelTime : Array[0..MaxElement] Of
    Record
      Location : Integer;
      Time : Integer;
    End;

    TravelTimeCount : Integer;
    Next_Port : Integer;

    LL,L1,L2 : Integer;
    I, I2, I3: Integer;

    Procedure DecTime(T : Integer);
    Begin
      // --- �Թ�ҧ价�Ҩ��¶Ѵ�
      if Q.FieldByName('forder').AsString = '2.7' then
      Begin
        if LastLoc then
        Begin
          LastLoc := False;
        End Else
        Begin
          Goto_Time := Str2Float(TripData[1, 2]);
        End;
      End;

      O.Add('/* ['+Q.FieldByName('forder').AsString+'] '+Q.FieldByName('fname').AsString+' TIME='+FormatDateTime('HH:NN',Goto_Time)+' DEC='+T.ToString+' TYPE='+Q['ftype']+' */');

      // --- Check-in
      if Q.FieldByName('forder').AsString = '2.3' then
        TripData[1, 2]  := FloatToStr(Goto_Time);

      // --- �Ѵ�觻����ö
      if Q.FieldByName('forder').AsString = '3' then
        TripData[2, 2]  := FormatDateTime('HH:NN',Goto_Time);

      // --- Check-out
      if Q.FieldByName('forder').AsString = '4' then
        TripData[3, 2]  := FormatDateTime('HH:NN',Goto_Time);

      // --- ��ѧ��ҷ�Ҩ���
      if Q.FieldByName('forder').AsString = '2.1' then
        BoardWhoData[7, 2, BoardWhoCount] := FormatDateTime('HH:NN',Goto_Time);

      // --- ��ѧ�觢ͧ����Ҩ���
      if Q.FieldByName('forder').AsString = '2.2' then
        BoardWhoData[8, 2, BoardWhoCount] := FormatDateTime('HH:NN',Goto_Time);

      // --- ö��ҷ�Ҩ���
      if Q.FieldByName('forder').AsString = '2.3' then
        BoardD2CData[7, 2, BoardD2CCount] := FormatDateTime('HH:NN',Goto_Time);

      // --- ö�͡��Ҩ���
      if Q.FieldByName('forder').AsString = '2.6' then
        BoardD2CData[8, 2, BoardD2CCount] := FormatDateTime('HH:NN',Goto_Time);

      // --- ö�͡��Ҩ���
      if Q.FieldByName('forder').AsString = '2.5' then
        BoardD2CData[9, 2, BoardD2CCount] := FormatDateTime('HH:NN',Goto_Time);  



      Goto_Time := Goto_Time-T/1440;
    End;

    Procedure IncTime(T : Integer);
    Begin
      // --- �Թ�ҧ价�Ҩ��¶Ѵ�
      if Q.FieldByName('forder').AsString = '2' then
      Begin
        if LastLoc then
        Begin
          LastLoc := False;
        End Else
        Begin
          Goto_Time := D2COut + (5 / 1440);
        End;
      End;

      O.Add('/* ['+Q.FieldByName('forder').AsString+'] '+Q.FieldByName('fname').AsString+' TIME='+FormatDateTime('HH:NN',Goto_Time)+' DEC='+T.ToString+' TYPE='+Q['ftype']+' */');

      // --- ö��ҷ�Ҩ���
      if Q.FieldByName('forder').AsString = '2' then
        BoardD2CData[7, 2, BoardD2CCount] := FormatDateTime('HH:NN',Goto_Time);

      // --- ö�͡��Ҩ���
      if Q.FieldByName('forder').AsString = '3' then
      Begin
        BoardD2CData[8, 2, BoardD2CCount] := FormatDateTime('HH:NN',Goto_Time);
        BoardD2CData[9, 2, BoardD2CCount] := FormatDateTime('HH:NN',Goto_Time);
        D2COut := Goto_Time;
      End;

      // --- ��ѧ��ҷ�Ҩ���
      if Q.FieldByName('forder').AsString = '4' then
        BoardWhoData[7, 2, BoardWhoCount] := FormatDateTime('HH:NN',Goto_Time);

      // --- ��ѧ�͡�ҡ��Ҩ���
      if Q.FieldByName('forder').AsString = '5' then
        BoardWhoData[8, 2, BoardWhoCount] := FormatDateTime('HH:NN',Goto_Time);


      Goto_Time := Goto_Time+T/1440;
    End;

    Function GetTravelTime(FromLocation,ToLocation : Integer) : Integer;
    Var L1 : Integer;
        Start : Boolean;
    Begin
      Start := False;
      Result := 0;
      for L1 := 0 to TravelTimeCount-1 do
      Begin
        if TravelTime[L1].Location = ToLocation then
        Begin
          Break;
        End;
        if TravelTime[L1].Location = FromLocation then
        Begin
          Start := True;
        End;
        if Start then
        Begin
          Result := Result + TravelTime[L1].Time;
        End;
      End;
    End;

    function Select(sql : String):String;
    var Q : TUniQuery;
        i : integer;
    begin
      Q := TUniQuery.Create(nil);
      Q.Connection := c;
      Q.SQL.Text := sql;
      Q.Open;
      Result := '';
      if not Q.Eof then
      begin
        for i := 0 to Q.FieldCount-1 do
        begin
          Result := Result+Q.Fields[i].AsString+#255;
        end;
        Q.Next;
      end;
      Q.Close;
      Q.Free;
      SetLength(Result,Length(Result)-1);
    end;

    Procedure ExecSQL(SQL : String);
    Var Q : TUniQuery;
    begin
      Q := TUniQuery.Create(NIl);
      Q.Connection := c;
      Q.SQL.Text := SQL;
      Q.ExecSQL;
      Q.Close;
      Q.Free;
    end;

    Function MaxCode(Head, Table, Warehouse, D : String) : String;
    Var Q : TUniQuery;
        WCode, Code : String;
    begin
      Result := '';
      Head := Trim(Head);
      Table := Trim(Table);
      Warehouse := Trim(Warehouse);
      D := Trim(D);

      if (Table = '') or (Warehouse = '') then
      Begin

      End Else
      Begin
        Try
          Q := TUniQuery.Create(NIl);
          Q.Connection := c;

          if D = '' then
            D := FormatDateTime('YYMMDD',Now);

          Head  := Head + D;
          Wcode := Select('select fabb from twarehouse where frun = '''+Warehouse+'''');
          code  := Select('select max(fcode) from ' + Table + ' where fCode like ''%' + head + '___' + Wcode+'''');
          if code = '' then
          begin
            code := head + '001' + Wcode;
          end else
          begin
            code := copy(code,8,3);
            code := head + FormatFloat('000',StrToFloat(code)+1) + Wcode;
          end;

          Result := Code;
        Except

        End;

        Q.Close;
        Q.Free;
      End;
    end;

    Function Distance(Lat1,Lon1,Lat2,Lon2 : Double) : Double;
    Var Theta : Double;

       Function Deg2Rad(Deg : Double) : Double;
       Begin
          Result := Deg*Pi/180;
       End;

       Function Rad2Deg(Rad : Double) : Double;
       Begin
         Result := rad / PI * 180;
       End;

    Begin
       Theta := Lon1-Lon2;
       Result := Sin(Deg2Rad(Lat1))*Sin(Deg2Rad(Lat2))+Cos(Deg2Rad(Lat1))*Cos(Deg2Rad(Lat2))*Cos(deg2rad(theta));
       Result := ArcCos(Result);
       Result := Rad2Deg(Result);

       Result := Result * 60 * 1.1515;
       Result := Result * 1.609344;   // Mile To KM.
    End;

    //Procedure FindDistance(fLat, fLon, tLat, tLon : String);
    Function FindDistance(Trip : String) : Integer;
    Var Coor, Latlon, DirPath, DistS, s : String;
        fLat, fLon, tLat, tLon : String;
        i, idx, Speed : Integer;
        FindLongdo : Boolean;
        RouteFile : TStrings;
        idHTTP1 : TIdHTTP;
        D : Double;
    Begin
      FindLongdo := True;
      Dirpath := form1.DirPath;

      Speed := Str2Int(Select('Select v.fAverage_Speed From tTrip t, tVehicle_Type v ' +
              'Where t.fVehicle_Type = v.fRun and t.fcode = ''' + Trip + ''' '));

      S := Select('Select fLat, fLong from tWareHouse Where fRun = ' + WareHouse_ID.ToString);
      fLat := GetColumn(1, s);
      fLon := GetColumn(2, s);

      S := Select('Select s.fShip_To_Latitude, s.fShip_To_Longtitude ' +
          'from tShipment s, tTrip t, tTrip_Detail td ' +
          'Where t.fRun = td.fMaster and td.fShipment = s.fRun and t.fCode = ''' + Trip + ''' ' +
          'Order by td.fOrder Limit 1');
      tLat := GetColumn(1, s);
      tLon := GetColumn(2, s);

      fLat := LatLong3Digit(fLat);
      fLon := LatLong3Digit(fLon);
      tLat := LatLong3Digit(tLat);
      tLon := LatLong3Digit(tLon);

      if FileExists(DirPath + '\RouteFile\' + fLat + 'x' + fLon + '-' + tLat + 'x' + tLon + '.txt') then
      Begin
        RouteFile := TStringList.Create;
        RouteFile.LoadFromFile(DirPath + '\RouteFile\' + fLat + 'x' + fLon + '-' + tLat + 'x' + tLon + '.txt');

        if RouteFile.Count > 2 then
          FindLongdo := False;

        RouteFile.Clear;
        RouteFile.Free;
      End;

      if FindLongdo Then
      Begin
        RouteFile := TStringList.Create;
        Try
          idHTTP1 := TIdHTTP.Create(Nil);

          DistS := idHTTP1.Get('http://api.longdo.com/RouteService/geojson/route?flon='+fLon+'&flat='+fLat+'&' +
            'tlon='+tLon+'&tlat='+tLat+'&mode=t&type=17&locale=th&key=d8516c2e67c227733b9a0105514e30d1');

          idx := Pos('"coordinates":', DistS);
          while idx > 0 do
          Begin
            DistS := Copy(DistS, idx + 14, Length(DistS));
            Coor := GetColumnChar(1, DistS, '}');

            i := 1;
            Latlon := GetColumnChar(i, Coor, ']');
            while Length(LatLon) > 5 do
            Begin
              Delete(LatLon, 1, 2);
              RouteFile.Add(LatLon);
              inc(i);
              Latlon := GetColumnChar(i, Coor, ']');
            End;

            idx := Pos('"coordinates":', DistS);
          End;

          idx := DistS.LastIndexOf('distance');
          DistS := Copy(DistS, idx, 100);
          DistS := GetColumnChar(2, DistS, ':');
          DistS := GetColumnChar(1, DistS, ',');
          D := Str2Float(DistS);
          D := D / 1000;
          idHTTP1.Free;
        Except
          D := Distance(Str2Float(fLon), Str2Float(fLat), Str2Float(tLon), Str2Float(tLat));
        End;

        RouteFile.Insert(0, D.ToString);
        RouteFile.SaveToFile(DirPath + '\RouteFile\' + fLat + 'x' + fLon + '-' + tLat + 'x' + tLon + '.txt');
        RouteFile.Clear;
        RouteFile.Free;

      End Else
      Begin
        RouteFile := TStringList.Create;
        RouteFile.LoadFromFile(DirPath + '\RouteFile\' + fLat + 'x' + fLon + '-' + tLat + 'x' + tLon + '.txt');
        D := RouteFile.Strings[0].ToDouble;
        RouteFile.Clear;
        RouteFile.Free;
      End;

      Result := 0;

      if Speed > 0 then
      Begin
        Result := Floor(D / Speed * 60);
      End;
    End;

Begin
  CD := TClientDataSet.Create(Nil);
  CD.FieldDefs.Add('ORDER', ftInteger);
  CD.FieldDefs.Add('LOCATION', ftString,10);
  CD.FieldDefs.Add('VOLUME', ftInteger);
  CD.FieldDefs.Add('TIME', ftFloat);
  CD.FieldDefs.Add('WH_TIME', ftFloat);
  CD.FieldDefs.Add('SHARE', ftInteger);
  CD.FieldDefs.Add('PERCENT', ftFloat);
  CD.FieldDefs.Add('LOCATION_FROM', ftInteger);
  CD.FieldDefs.Add('LOCATION_TO', ftInteger);
  CD.CreateDataSet;

  O.Clear;
  O.Add('/* TRIP COUNT='+Length(TRIPA).ToString+' */');
  O.Add(''); 

  Q := TUniQuery.Create(Nil);
  Q2 := TUniQuery.Create(Nil);
  QBranch := TUniQuery.Create(Nil);
  Q.Connection := C;
  Q2.Connection := C;
  QBranch.Connection := C;

  LocList := TStringList.Create;
  DockList := TStringList.Create;

  TripData[1, 1]  := 'FCHECKIN_DATETIME_PLAN';
  TripData[2, 1]  := 'FFINALCHECK_DATETIME_PLAN';
  TripData[3, 1]  := 'FCHECKOUT_DATETIME_PLAN';

  BoardD2CData[1, 1, 0]  := 'FCODE';
  BoardD2CData[2, 1, 0]  := 'FDATETIME';
  BoardD2CData[3, 1, 0]  := 'FTYPE';          
  BoardD2CData[4, 1, 0]  := 'FREFERENCE';
  BoardD2CData[5, 1, 0]  := 'FORDER';
  BoardD2CData[6, 1, 0]  := 'FDOCKING';
  BoardD2CData[7, 1, 0]  := 'FDOCKIN_DATETIME_PLAN';
  BoardD2CData[8, 1, 0]  := 'FDOCKOUT_DATETIME_PLAN'; 
  BoardD2CData[9, 1, 0]  := 'FWAREHOUSE_DATETIME_PLAN';
  BoardD2CData[10, 1, 0] := 'FSTATUS';           

  BoardWhoData[1, 1, 0] := 'FCODE';
  BoardWhoData[2, 1, 0] := 'FDATETIME';
  BoardWhoData[3, 1, 0] := 'FTYPE';         
  BoardWhoData[4, 1, 0] := 'FREFERENCE';
  BoardWhoData[5, 1, 0] := 'FORDER';
  BoardWhoData[6, 1, 0] := 'FDOCKING';
  BoardWhoData[7, 1, 0] := 'FDOCKIN_DATETIME_PLAN';
  BoardWhoData[8, 1, 0] := 'FDOCKOUT_DATETIME_PLAN';
  BoardWhoData[9, 1, 0] := 'FSTATUS';

  {Q.SQL.Text := 'Select fRun From tLocation ';
  Q.Open;
  while Not Q.Eof do
  Begin
    s := Select('Select b.fDocking From tBoarding_Pass b, tLocation l, tDocking d ' + 
      'where l.frun = d.fLocation and d.fRun = b.fDocking and l.fRun = ' + Q.FieldByName('FRUN').AsString + ' ' +
        'and b.fDateTime >= ''' + FormatDateTime('YYYY-MM-DD', Date) + ''' and b.fDateTime <= ''' + FormatDateTime('YYYY-MM-DD', Date) + ' 23:59:59 '' ' +
      'Order by b.fDateTime Desc Limit 1');

    LocList.Add(Q.FieldByName('FRUN').AsString);
    DockList.Add(s);
    Q.Next;
  End;
  Q.Close;}

  for LL := 0 to Length(TRIPA)-1 do
  Begin
    BoardD2CCount := 0;
    BoardWhoCount := 0;
    LastLoc := True;
  
    TRIP := TRIPA[LL];
    O.Add('/* BEGIN TRIP['+(LL+1).ToString+']='+TRIP+' */');
    Q.SQL.Text := 'select fshare_percent from tsetting';
    Q.Open;
    Share_Percent := Q.Fields[0].AsFloat;

    Q.SQL.Text := 'Select l.fcode l_fcode,l.forder l_forder,l.fshare l_fshare, sd.fvolume sd_fvolume,tds.fquantity tds_fquantity,tds.frun tds_frun, '+
      'tds.flocation tds_flocation,l.frun l_frun,il.flocation il_flocation,td.fdistance, v.fspeed , l.fwarehouse l_fwarehouse, t.fRun t_frun, '+
      'i.fwh_time i_fwh_time, i.fwh_quantity i_fwh_quantity, i.ftime i_ftime, i.fquantity i_fquantity, v.fVehicle_Type v_fVehicle_Type, i.fCode i_fcode '+
    'from ttrip t , ttrip_detail td , tshipment s , ttrip_detail_shipment tds , tshipment_detail sd , titem i , titem_location il , tlocation l , tvehicle v '+
    'where t.frun=td.fmaster and td.fshipment=s.frun and td.frun=tds.fmaster and tds.fshipment = sd.frun and i.fcode=sd.fitemnumber ' +
      'and il.fitem=i.frun and l.frun=il.flocation and l.fwarehouse=t.fwarehouse and  t.fcode = '''+TRIP+'''   and t.fvehicle <> '''' and v.frun = t.fvehicle ' +
      'and l.fRun in (Select d.fLocation from tdocking d where d.fOut = ''1'' and d.FLOCATION = l.frun) ' +
    'order by l_forder';

    Q.SQL.Text := 'Select l.fcode l_fcode,l.forder l_forder,l.fshare l_fshare, sd.fvolume sd_fvolume,tds.fquantity tds_fquantity,tds.frun tds_frun, '+
      'tds.flocation tds_flocation,l.frun l_frun,il.flocation il_flocation,td.fdistance, l.fwarehouse l_fwarehouse, t.fRun t_frun, '+
      'i.fwh_time i_fwh_time, i.fwh_quantity i_fwh_quantity, i.ftime i_ftime, i.fquantity i_fquantity, t.fVehicle_Type t_fVehicle_Type, i.fCode i_fcode '+
    'from ttrip t , ttrip_detail td , tshipment s , ttrip_detail_shipment tds , tshipment_detail sd , titem i , titem_location il , tlocation l '+
    'where t.frun=td.fmaster and td.fshipment=s.frun and td.frun=tds.fmaster and tds.fshipment = sd.frun and i.fcode=sd.fitemnumber ' +
      'and il.fitem=i.frun and l.frun=il.flocation and l.fwarehouse=t.fwarehouse and  t.fcode = '''+TRIP+''' ' +
      'and l.fRun in (Select d.fLocation from tdocking d where d.fOut = ''1'' and d.FLOCATION = l.frun) ' +
    'order by l_forder';

    Form1.Memo1.Lines.Text := Q.SQL.Text;
    Q.Open;

    if Q.Eof then
    Begin
      O.Add('/* No Data */');
      //ShowMessage(Trip + ' No data');
    End Else
    Begin
      LocList.Clear;
      WareHouse_ID := Q.FieldByName('l_fwarehouse').AsInteger;
      TripRun := Q.FieldByName('t_frun').AsString;
      VehVol := Str2Int(Select('Select fVolume From tVehicle_Type Where fRun = ' + Q.FieldByName('t_fVehicle_Type').AsString));

      O.Add('/* WAREHOUSE='+WareHouse_ID.ToString+' */');

      ShareList := TStringList.Create;
      CD.EmptyDataSet;
      CD.Open;
      CD.IndexFieldNames := 'ORDER';
      for L1 := 0 to MaxElement do
      Begin
        VolumeSummary[L1].Sum := 0;
        VolumeSummary[L1].Max := 0;
        VolumeSummary[L1].Max_ID := 0;
        TimeSummary[L1].Sum := -1;
        TimeSummary[L1].WH_Sum := -1;
        TravelTime[L1].Location := -1;
      End;
      Q.First;
      O.Add('/* BEGIN VOLUME-TIME */');    
      while Not Q.EOF do
      Begin
        LOCATION := Q.FieldByName('l_fcode').AsString;
        VOLUME := Q.FieldByName('sd_fvolume').AsInteger*Q.FieldByName('tds_fquantity').AsInteger;
        O.Add('/* LOC='+Q.FieldByName('l_frun').AsString+',VOL='+Q.FieldByName('sd_fvolume').AsString+'*'+Q.FieldByName('tds_fquantity').AsString+'='+VOLUME.ToString+' */');
        //TIME := Q.FieldByName('i_fwh_time').AsInteger*Q.FieldByName('i_fwh_quantity').AsInteger;

        if (Q.FieldByName('i_ftime').AsInteger = 0) or (Q.FieldByName('i_fquantity').AsInteger = 0) then
        Begin
          TIME := Q.FieldByName('tds_fquantity').AsInteger;;
        End Else
        Begin
          TIME := Q.FieldByName('tds_fquantity').AsInteger * Q.FieldByName('i_ftime').AsInteger / Q.FieldByName('i_fquantity').AsInteger;
        ENd;

        if (Q.FieldByName('i_fwh_time').AsInteger = 0) or (Q.FieldByName('i_fwh_quantity').AsInteger = 0) then
        Begin
          WH_TIME := Q.FieldByName('tds_fquantity').AsInteger;;
        End Else
        Begin
          WH_TIME := Q.FieldByName('tds_fquantity').AsInteger * Q.FieldByName('i_fwh_time').AsInteger / Q.FieldByName('i_fwh_quantity').AsInteger;
        ENd;

        O.Add('/* LOC='+Q.FieldByName('l_frun').AsString+',TIME='+Q.FieldByName('i_fwh_time').AsString+'*'+Q.FieldByName('i_fwh_quantity').AsString+'='+TIME.ToString+' */');
        ORDER := Q.FieldByName('l_forder').AsInteger;
        SHARE := Q.FieldByName('l_fshare').AsInteger;
        if SHARE > 0 then
        Begin
          VolumeSummary[SHARE].Sum := VolumeSummary[SHARE].Sum+VOLUME;
          If VOLUME > VolumeSummary[SHARE].Max Then
          Begin
            VolumeSummary[SHARE].Max := VOLUME;
            VolumeSummary[SHARE].Max_ID := Q.FieldByName('l_frun').AsInteger;
            VolumeSummary[SHARE].Order_ID := Q.FieldByName('l_forder').AsInteger;
          End;
        End;      
      
        If Not CD.Locate('LOCATION',LOCATION,[]) Then
        Begin
          CD.Append;
          CD.FieldByName('LOCATION').AsString := LOCATION;
          CD.FieldByName('VOLUME').AsInteger := VOLUME;
          CD.FieldByName('TIME').AsFloat := TIME;
          CD.FieldByName('WH_TIME').AsFloat := WH_TIME;
          CD.FieldByName('ORDER').AsInteger := ORDER;
          CD.FieldByName('SHARE').AsInteger := SHARE;
          CD.FieldByName('LOCATION_FROM').AsInteger := Q.FieldByName('l_frun').AsInteger;
          CD.Post;
          LocList.Add(Q.FieldByName('l_frun').AsString);
        End Else
        Begin
          CD.Edit;
          CD.FieldByName('VOLUME').AsInteger := CD.FieldByName('VOLUME').AsInteger+VOLUME;
          CD.FieldByName('TIME').AsFloat := CD.FieldByName('TIME').AsFloat+TIME;
          CD.FieldByName('WH_TIME').AsFloat := CD.FieldByName('WH_TIME').AsFloat+WH_TIME;
          CD.Post;
        End;
        Q.Next;
      End;

      // select l.fcode,count(d.fcode) from tdocking d , tlocation l where l.frun=d.flocation and l.fwarehouse = 2 group by l.fcode
      O.Add('/* END VOLUME-TIME */');
      CD.First;
      while Not CD.EOF do
      Begin
        SHARE := CD.FieldByName('SHARE').AsInteger;
        CD.Edit;
        if SHARE > 0 then
        Begin
          TempLOCATION := CD.FieldByName('LOCATION').AsString;
          CD.FieldByName('PERCENT').AsFloat := Round((CD.FieldByName('VOLUME').AsInteger/VolumeSummary[SHARE].Sum)*1000000)/10000;
          If CD.FieldByName('PERCENT').AsFloat < Share_Percent Then
          Begin
            O.Add('/* CHANGE LOCATION FROM '+CD.FieldByName('LOCATION_FROM').AsString+'->'+VolumeSummary[SHARE].Max_ID.ToString+' */');
            CD.FieldByName('LOCATION_TO').AsInteger := VolumeSummary[SHARE].Max_ID;
            //CD.FieldByName('ORDER').AsInteger := VolumeSummary[SHARE].Order_ID;
            Q.First;
            while Not Q.EOF do
            Begin
              if Q.FieldByName('l_frun').AsInteger = CD.FieldByName('LOCATION_FROM').AsInteger then
              Begin
                O.Add('update ttrip_detail_shipment set flocation = '+VolumeSummary[SHARE].Max_ID.ToString+' where frun = '+Q.FieldByName('tds_frun').AsString+';');
              End;
              Q.Next;
            End;
          End Else
          Begin
            CD.FieldByName('LOCATION_TO').AsInteger := CD.FieldByName('LOCATION_FROM').AsInteger;
          End;
        End Else
        Begin
          CD.FieldByName('LOCATION_TO').AsInteger := CD.FieldByName('LOCATION_FROM').AsInteger;
        End;
        CD.Post;
        CD.Next;
      End;




      Q.SQL.Text := 'select frun, ftravel_time, fNext_Location_Time from tlocation where fwarehouse = '+WareHouse_ID.ToString+' order by forder';
      Q.Open;

      O.Add('/* BEGIN TRAVEL TIME */');
      TravelTimeCount := 0;
      while Not Q.EOF do
      Begin
        TravelTime[TravelTimeCount].Location := Q.FieldByName('frun').AsInteger;
        TravelTime[TravelTimeCount].Time := Q.FieldByName('fNext_Location_Time').AsInteger;
        O.Add('/* LOC='+TravelTime[TravelTimeCount].Location.ToString+' TIME='+TravelTime[TravelTimeCount].Time.ToString+' */');
        Inc(TravelTimeCount);
        Q.Next;
      End;
      O.Add('/* END TRAVEL TIME */');
      CD.First;
      while Not CD.EOF do
      Begin
        if TimeSummary[CD.FieldByName('LOCATION_TO').AsInteger].Sum = -1 then
        Begin
          TimeSummary[CD.FieldByName('LOCATION_TO').AsInteger].Sum := 0;
          TimeSummary[CD.FieldByName('LOCATION_TO').AsInteger].WH_Sum := 0;
        End;
        TimeSummary[CD.FieldByName('LOCATION_TO').AsInteger].Sum := TimeSummary[CD.FieldByName('LOCATION_TO').AsInteger].Sum+CD.FieldByName('TIME').AsInteger;
        TimeSummary[CD.FieldByName('LOCATION_TO').AsInteger].WH_Sum := TimeSummary[CD.FieldByName('LOCATION_TO').AsInteger].WH_Sum+CD.FieldByName('WH_TIME').AsInteger;
        CD.Next;
      End;

      Q.SQL.Text := 'Select * from tstep where fShipment_Type = ''Sales order'' order by forder desc';
      Q.Open;

      //Form1.DataSource1.DataSet := Q;

      O.Add('/* MAIN 1 */');
      Goto_Time := 13/24; // ����ŧ�ͧ����á

      //if WareHouse_ID = 2 then
      if True then
      Begin
        S := Select('Select s.fShip_From_Time ' +
            'from tShipment s, tTrip t, tTrip_Detail td ' +
            'Where t.fRun = td.fMaster and td.fShipment = s.fRun and t.fCode = ''' + Trip + ''' ' +
            'Order by td.fOrder Limit 1');

        // --- ���    
        If Str2Int(GetColumnChar(1, s, ':')) <= 12 Then
        Begin
          Morning := True;
          Goto_Time := EncodeTime(Str2Int(GetColumnChar(1, s, ':')), Str2Int(GetColumnChar(2, s, ':')), 0, 0);
        End Else

        // --- ����
        Begin
          Morning := False;
          Goto_Time := EncodeTime(Str2Int(GetColumnChar(1, s, ':')), Str2Int(GetColumnChar(2, s, ':')), 0, 0);
        End;         

      End Else
      Begin
        Goto_Time := 8.5/24;
      End;

      Q.First;
      while Not Q.EOF do
      Begin
        if Q.FieldByName('forder').AsString = '4' then
        Begin
          if Morning then
          Begin
            Goto_Time := 18 / 24;
          End;        
        End;
      
    
        if Q['ftype'] = 2 then // �������Թ�ҧ�ŧ�ͧ����á
        Begin
          DecTime(FindDistance(Trip));
        End Else
        Begin
          DecTime(Q.FieldByName('fdetail').AsInteger);
        End;
        Q.Next;
        if Q.FieldByName('floop').AsInteger = 1 then
        Begin
          Break;
        End;
      End;
      O.Add('/* BEGIN LOOP */');

      //for L1 := MaxElement DownTo 0 Do // SUB LOOP
      for LocRun := LocList.Count - 1 Downto 0 do
      Begin
        L1 := LocList.Strings[LocRun].ToInteger;
        if TimeSummary[L1].Sum > -1  then
        Begin
          {Next_Port := TravelTime[TravelTimeCount-1].Location;
          for L2 := L1+1 To MaxElement do
          Begin
            if TimeSummary[L2].Sum > -1  then
            Begin
              Next_Port := L2;
              Break;
            End;
          End;}

          Next_Port := L1;
          if LocRun < LocList.Count - 1 then
            Next_Port := LocList.Strings[LocRun + 1].ToInteger;

          Inc(BoardD2CCount);
          Inc(BoardWhoCount);

          BoardD2CData[2, 2, BoardD2CCount] := FormatDateTime('YYYY-MM-DD HH:NN', now);
          BoardD2CData[3, 2, BoardWhoCount] := 'D2C';
          BoardD2CData[4, 2, BoardWhoCount] := TripRun;
          BoardD2CData[6, 2, BoardWhoCount] := L1.ToString;
          BoardD2CData[10, 2, BoardWhoCount] := '0';

          BoardWhoData[2, 2, BoardWhoCount] := FormatDateTime('YYYY-MM-DD HH:NN', now);
          BoardWhoData[3, 2, BoardWhoCount] := 'WHO';
          BoardWhoData[4, 2, BoardWhoCount] := TripRun;
          BoardWhoData[6, 2, BoardWhoCount] := L1.ToString;
          BoardWhoData[9, 2, BoardWhoCount] := '0';
        

          O.Add('/* LOOP LOC='+L1.ToString+'->'+Next_Port.ToString+' T='+GetTravelTime(L1,Next_Port).ToString+' */');
          Q.First;
          While Not Q.EOF Do
          Begin
            if Q['floop'] = 1 then
            Begin
              if Q['ftype'] = 1 then // ������Ңͧ���
              Begin
                if Pos('��ѧ', Q['fname']) > 0 then
                Begin
                  DecTime(TimeSummary[L1].WH_Sum);
                End Else
                Begin
                  DecTime(TimeSummary[L1].Sum);
                End;
              End Else
              if Q['ftype'] = 3 then // �����Թ�ҧ��ѧ��ҶѴ�
              Begin
                DecTime(GetTravelTime(L1,Next_Port));
              End Else
              Begin
                DecTime(Q.FieldByName('fdetail').AsInteger);
              End;
            End;
            Q.Next;
          End;
        End;
      End;

      O.Add('/* END LOOP */');
      O.Add('/* MAIN 2 */');
      Q.First;
      while Not Q.EOF do
      Begin
        if Q.FieldByName('forder').AsString < '2' then
        Begin
          Break;
          DecTime(Q.FieldByName('fdetail').AsInteger);
        End;
        Q.Next;
      End;

      DD := Str2Float(Select('Select fDetail from tStep Where fShipment_Type = ''Sales order'' and fOrder = 1'));
      Goto_Time := Str2Float(TripData[1, 2]) - (DD / 1440);
      DecTime(Floor(DD));

      O.Add('/* END TRIP['+(LL+1).ToString+']='+TRIP+' */');
      O.Add('');

      // ------------------------ Trip -------------------------
      D := Str2Float(TripData[1, 2]);
      DD := DD / 1440;
      TripData[1, 2] := FormatDateTime('HH:NN', D - DD);
      for I := 1 to 3 do
      Begin
        Form1.Memo6.Lines.Add(TripData[i, 1] + ' = ' + TripData[i, 2]);
      End;
      Form1.Memo6.Lines.Add('');

      Q.SQL.Text := 'Select * from tTrip Where fCode = ''' + Trip + ''' ';
      Q.Open;

      TripDate := Q.FieldByName('FSHIPDATE').AsDateTime;
      if Morning then
        TripDate := TripDate - 1;

      SQL := 'Update tTrip set FCHECKIN_DATETIME_PLAN = ''' + FormatDateTime('YYYY-MM-DD', TripDate) + ' ' + TripData[1, 2] + ''', ' +
                              'FFINALCHECK_DATETIME_PLAN = ''' + FormatDateTime('YYYY-MM-DD', TripDate) + ' ' + TripData[2, 2] + ''', ' +
                              'FCHECKOUT_DATETIME_PLAN = ''' + FormatDateTime('YYYY-MM-DD', TripDate) + ' ' + TripData[3, 2] + ''' ' +
             'Where fCode = ''' + Trip + ''' Limit 1';
         
      Form1.Memo6.Lines.Add(SQL);
      Form1.Memo6.Lines.Add('');
      ExecSQL(SQL);
    
      // ------------------------ D2C -------------------------
      I3 := 0;
      for I := BoardD2CCount Downto 1 do
      Begin
        Temp := '';
        SQL := 'Insert into tBoarding_Pass (';
        for I2 := 1 to 10 do
        Begin
          Temp := Temp + BoardD2CData[i2, 1, 0] + ',';
          if BoardD2CData[i2, 1, 0] = 'FCODE' then
          Begin
            BoardD2CData[i2, 2, i] := MaxCode('B', 'tboarding_pass', WareHouse_ID.ToString, '');
          End Else
          if BoardD2CData[i2, 1, 0] = 'FORDER' then
          Begin
            Inc(I3);
            BoardD2CData[i2, 2, i] := I3.ToString;
          End Else
          if BoardD2CData[i2, 1, 0] = 'FDOCKIN_DATETIME_PLAN' then
          Begin
            BoardD2CData[i2, 2, i] := FormatDateTime('YYYY-MM-DD', TripDate) + ' ' + BoardD2CData[i2, 2, i];
            fCheckIn := BoardD2CData[i2, 2, i];
          End Else
          if BoardD2CData[i2, 1, 0] = 'FDOCKOUT_DATETIME_PLAN' then
          Begin
            BoardD2CData[i2, 2, i] := FormatDateTime('YYYY-MM-DD', TripDate) + ' ' + BoardD2CData[i2, 2, i];
            fCheckOut := BoardD2CData[i2, 2, i];
          End Else
          if BoardD2CData[i2, 1, 0] = 'FWAREHOUSE_DATETIME_PLAN' then
          Begin
            BoardD2CData[i2, 2, i] := FormatDateTime('YYYY-MM-DD', TripDate) + ' ' + BoardD2CData[i2, 2, i];
          End;
        End;

        for I2 := 1 to 10 do
        Begin
          if BoardD2CData[i2, 1, 0] = 'FDOCKING' then
          Begin
            ss := 'Select d.fRun, dd.fTime from tDocking d left join tDocking_Detail dd on d.fRun = dd.fMaster ' +
                    'and dd.fCheckIn >= ''' + FormatDateTime('YYYY-MM-DD', TripDate) + ''' and dd.fCheckIn <= ''' + FormatDateTime('YYYY-MM-DD', TripDate) + ' 23:59:59'' '+
                  'where d.fOut = ''1'' and  d.fLocation = ' + BoardD2CData[i2, 2, i] + ' and d.fMax_Volume >= ' + VehVol.ToString + ' ' +
                  'order by dd.ftime, d.fcode limit 1';

            ss := 'Select d.fRun, dd.fTime from tDocking d left join tDocking_Detail dd on d.fRun = dd.fMaster ' +
                  //  'and ((dd.fCheckIn >= ''' + fCheckIn + ''' and dd.fCheckIn < ''' + fCheckOut + ''') or (dd.fCheckOut >= ''' + fCheckIn + ''' and dd.fCheckOut <= ''' + fCheckOut + '''))'+
                    'and dd.fCheckIn < ''' + fCheckOut + ''' and dd.fCheckOut > ''' + fCheckIn + ''' ' +
                  'where d.fName not like ''%�����%'' and d.fOut = ''1'' and d.fLocation = ' + BoardD2CData[i2, 2, i] + ' and d.fMax_Volume >= ' + VehVol.ToString + ' ' +
                  'order by dd.ftime, d.fcode limit 1';

            Form1.Memo6.Lines.Add(ss);
            Docking := Select(ss);
            if (GetColumn(1, Docking) = '') or (GetColumn(2, Docking) <> '') then
            Begin
              ss := 'Select fRun from tDocking where fName like ''%�����%'' and fOut = ''1'' and fLocation = ' + BoardD2CData[i2, 2, i] + ' and fMax_Volume >= ' + VehVol.ToString;
              Form1.Memo6.Lines.Add(ss);
              Docking := Select(ss);
            End;
            BoardD2CData[i2, 2, i] := GetColumn(1, Docking);
          End;
        End;

        Delete(Temp, Length(Temp), 1);
        SQL := SQL + Temp + ') Values(';
        Temp := '';
        for I2 := 1 to 10 do
        Begin
          Temp := Temp + '''' + BoardD2CData[i2, 2, i] + ''',';
        End;
        Delete(Temp, Length(Temp), 1);
        SQL := SQL + Temp + ')';
        Form1.Memo6.Lines.Add(SQL);
        Form1.Memo6.Lines.Add('');
        ExecSQL(SQL);

        SQL := 'Insert into tDocking_Detail (fMaster, fTrip, fCheckIn, fCheckOut, fTime) ' +
               'Values (' + GetColumn(1, Docking) + ', ' + TripRun + ', ''' + fCheckIn + ''', ''' + fCheckOut + ''', ' +
                     '''' + FormatDateTime('YYMMDD', TripDate) +FormatDateTime('HHNNSSZZZ', Now) + ''') ';
        Form1.Memo6.Lines.Add(SQL);
        Form1.Memo6.Lines.Add('');
        ExecSQL(SQL);
      End;

      // ---------------------- WHO ------------------------
      I3 := 0;
      for I := BoardWhoCount Downto 1 do
      Begin      
        Temp := '';
        SQL := 'Insert into tBoarding_Pass (';      
        for I2 := 1 to 9 do
        Begin
          Temp := Temp + BoardWhoData[i2, 1, 0] + ',';
          if BoardWhoData[i2, 1, 0] = 'FCODE' then
          Begin          
            BoardWhoData[i2, 2, i] := MaxCode('B', 'tboarding_pass', WareHouse_ID.ToString, '');
          End Else
          if BoardWhoData[i2, 1, 0] = 'FORDER' then
          Begin
            Inc(I3);
            BoardWhoData[i2, 2, i] := I3.ToString;
          End Else
          if BoardWhoData[i2, 1, 0] = 'FDOCKIN_DATETIME_PLAN' then
          Begin
            BoardWhoData[i2, 2, i] := FormatDateTime('YYYY-MM-DD', TripDate) + ' ' + BoardWhoData[i2, 2, i];
          End Else
          if BoardWhoData[i2, 1, 0] = 'FDOCKOUT_DATETIME_PLAN' then
          Begin
            BoardWhoData[i2, 2, i] := FormatDateTime('YYYY-MM-DD', TripDate) + ' ' + BoardWhoData[i2, 2, i];
          End Else
          if BoardWhoData[i2, 1, 0] = 'FDOCKING' then
          Begin          
            BoardWhoData[i2, 2, i] := BoardD2CData[i2, 2, i]
          End;
        End;
        Delete(Temp, Length(Temp), 1);
        SQL := SQL + Temp + ') Values(';
        Temp := '';
        for I2 := 1 to 9 do
        Begin        
          Temp := Temp + '''' + BoardWhoData[i2, 2, i] + ''',';        
        End;
        Delete(Temp, Length(Temp), 1);
        SQL := SQL + Temp + ')';      
        Form1.Memo6.Lines.Add(SQL);
        Form1.Memo6.Lines.Add('');
        ExecSQL(SQL);
      End;
    
      for I := BoardD2CCount Downto 1 do
      Begin
        for I2 := 1 to 10 do
        Begin               
          Form1.Memo6.Lines.Add(BoardD2CData[i2, 1, 0] + ' = ' + BoardD2CData[i2, 2, i]);        
        End;
        Form1.Memo6.Lines.Add('');
      End;

      Form1.Memo6.Lines.Add('---------------------');
      for I := BoardWhoCount Downto 1 do
      Begin
        for I2 := 1 to 8 do
        Begin                
          Form1.Memo6.Lines.Add(BoardWhoData[i2, 1, 0] + ' = ' + BoardWhoData[i2, 2, i]);
        End;
        Form1.Memo6.Lines.Add('');
      End;




      // -------------------- Transfer Shipment ------------------
      LastLoc := True;
      BoardD2CCount := 0;
      BoardWhoCount := 0;
      QBranch.SQL.Text := 'Select s.FDELIVERY_ADDRESSDESCRIPTION from ttrip t , ttrip_detail td , tshipment s ' +
      'where t.frun=td.fmaster and td.fshipment=s.frun and s.fReference = ''Transfer order shipment'' and t.fcode = '''+TRIP+''' ' +
      'Group by s.FDELIVERY_ADDRESSDESCRIPTION';
      QBranch.Open;

      while Not QBranch.Eof do
      Begin
        Branch := QBranch.FieldByName('FDELIVERY_ADDRESSDESCRIPTION').AsString;

        Q.SQL.Text := 'Select l.fcode l_fcode,l.forder l_forder,l.fshare l_fshare, sd.fvolume sd_fvolume,tds.fquantity tds_fquantity,tds.frun tds_frun, '+
          'tds.flocation tds_flocation,l.frun l_frun,il.flocation il_flocation,td.fdistance, l.fwarehouse l_fwarehouse, t.fRun t_frun, '+
          'i.fwh_time i_fwh_time, i.fwh_quantity i_fwh_quantity, i.ftime i_ftime, i.fquantity i_fquantity, t.fVehicle_Type t_fVehicle_Type, i.fCode i_fcode '+
        'from ttrip t , ttrip_detail td , tshipment s , ttrip_detail_shipment tds , tshipment_detail sd , titem i , titem_location il , tlocation l '+
        'where t.frun=td.fmaster and td.fshipment=s.frun and td.frun=tds.fmaster and tds.fshipment = sd.frun and i.fcode=sd.fitemnumber ' +
          'and il.fitem=i.frun and l.frun=il.flocation and l.fwarehouse=3 ' +
          'and t.fcode = '''+TRIP+''' and s.FDELIVERY_ADDRESSDESCRIPTION = ''' + Branch + ''' ' +
          'and l.fRun in (Select d.fLocation from tdocking d where d.fIn = ''1'' and d.FLOCATION = l.frun) ' +
        'order by l_forder';

        Q.Open;
        if Q.Eof then
        Begin
          O.Add('/* No Data */');
        End Else
        Begin
          LocList.Clear;
          WareHouse_ID := Q.FieldByName('l_fwarehouse').AsInteger;
          TripRun := Q.FieldByName('t_frun').AsString;
          VehVol := Str2Int(Select('Select fVolume From tVehicle_Type Where fRun = ' + Q.FieldByName('t_fVehicle_Type').AsString));

          O.Add('/* WAREHOUSE='+WareHouse_ID.ToString+' */');

          ShareList := TStringList.Create;
          CD.EmptyDataSet;
          CD.Open;
          CD.IndexFieldNames := 'ORDER';
          for L1 := 0 to MaxElement do
          Begin
            VolumeSummary[L1].Sum := 0;
            VolumeSummary[L1].Max := 0;
            VolumeSummary[L1].Max_ID := 0;
            TimeSummary[L1].Sum := -1;
            TimeSummary[L1].WH_Sum := -1;
            TravelTime[L1].Location := -1;
          End;
          Q.First;
          O.Add('/* BEGIN VOLUME-TIME */');
          while Not Q.EOF do
          Begin
            LOCATION := Q.FieldByName('l_fcode').AsString;
            VOLUME := Q.FieldByName('sd_fvolume').AsInteger*Q.FieldByName('tds_fquantity').AsInteger;
            O.Add('/* LOC='+Q.FieldByName('l_frun').AsString+',VOL='+Q.FieldByName('sd_fvolume').AsString+'*'+Q.FieldByName('tds_fquantity').AsString+'='+VOLUME.ToString+' */');
            //TIME := Q.FieldByName('i_fwh_time').AsInteger*Q.FieldByName('i_fwh_quantity').AsInteger;

            if (Q.FieldByName('i_ftime').AsInteger = 0) or (Q.FieldByName('i_fquantity').AsInteger = 0) then
            Begin
              TIME := Q.FieldByName('tds_fquantity').AsInteger;;
            End Else
            Begin
              TIME := Q.FieldByName('tds_fquantity').AsInteger * Q.FieldByName('i_ftime').AsInteger / Q.FieldByName('i_fquantity').AsInteger;
            ENd;

            if (Q.FieldByName('i_fwh_time').AsInteger = 0) or (Q.FieldByName('i_fwh_quantity').AsInteger = 0) then
            Begin
              WH_TIME := Q.FieldByName('tds_fquantity').AsInteger;;
            End Else
            Begin
              WH_TIME := Q.FieldByName('tds_fquantity').AsInteger * Q.FieldByName('i_fwh_time').AsInteger / Q.FieldByName('i_fwh_quantity').AsInteger;
            ENd;

            O.Add('/* LOC='+Q.FieldByName('l_frun').AsString+',TIME='+Q.FieldByName('i_fwh_time').AsString+'*'+Q.FieldByName('i_fwh_quantity').AsString+'='+TIME.ToString+' */');
            ORDER := Q.FieldByName('l_forder').AsInteger;
            SHARE := Q.FieldByName('l_fshare').AsInteger;
            if SHARE > 0 then
            Begin
              VolumeSummary[SHARE].Sum := VolumeSummary[SHARE].Sum+VOLUME;
              If VOLUME > VolumeSummary[SHARE].Max Then
              Begin
                VolumeSummary[SHARE].Max := VOLUME;
                VolumeSummary[SHARE].Max_ID := Q.FieldByName('l_frun').AsInteger;
                VolumeSummary[SHARE].Order_ID := Q.FieldByName('l_forder').AsInteger;
              End;
            End;

            If Not CD.Locate('LOCATION',LOCATION,[]) Then
            Begin
              CD.Append;
              CD.FieldByName('LOCATION').AsString := LOCATION;
              CD.FieldByName('VOLUME').AsInteger := VOLUME;
              CD.FieldByName('TIME').AsFloat := TIME;
              CD.FieldByName('WH_TIME').AsFloat := WH_TIME;
              CD.FieldByName('ORDER').AsInteger := ORDER;
              CD.FieldByName('SHARE').AsInteger := SHARE;
              CD.FieldByName('LOCATION_FROM').AsInteger := Q.FieldByName('l_frun').AsInteger;
              CD.Post;
              LocList.Add(Q.FieldByName('l_frun').AsString);
            End Else
            Begin
              CD.Edit;
              CD.FieldByName('VOLUME').AsInteger := CD.FieldByName('VOLUME').AsInteger+VOLUME;
              CD.FieldByName('TIME').AsFloat := CD.FieldByName('TIME').AsFloat+TIME;
              CD.FieldByName('WH_TIME').AsFloat := CD.FieldByName('WH_TIME').AsFloat+WH_TIME;
              CD.Post;
            End;
            Q.Next;
          End;

          // select l.fcode,count(d.fcode) from tdocking d , tlocation l where l.frun=d.flocation and l.fwarehouse = 2 group by l.fcode
          O.Add('/* END VOLUME-TIME */');
          CD.First;
          while Not CD.EOF do
          Begin
            SHARE := CD.FieldByName('SHARE').AsInteger;
            CD.Edit;
            if SHARE > 0 then
            Begin
              TempLOCATION := CD.FieldByName('LOCATION').AsString;
              CD.FieldByName('PERCENT').AsFloat := Round((CD.FieldByName('VOLUME').AsInteger/VolumeSummary[SHARE].Sum)*1000000)/10000;
              If CD.FieldByName('PERCENT').AsFloat < Share_Percent Then
              Begin
                O.Add('/* CHANGE LOCATION FROM '+CD.FieldByName('LOCATION_FROM').AsString+'->'+VolumeSummary[SHARE].Max_ID.ToString+' */');
                CD.FieldByName('LOCATION_TO').AsInteger := VolumeSummary[SHARE].Max_ID;
                //CD.FieldByName('ORDER').AsInteger := VolumeSummary[SHARE].Order_ID;
                Q.First;
                while Not Q.EOF do
                Begin
                  if Q.FieldByName('l_frun').AsInteger = CD.FieldByName('LOCATION_FROM').AsInteger then
                  Begin
                    O.Add('update ttrip_detail_shipment set flocation = '+VolumeSummary[SHARE].Max_ID.ToString+' where frun = '+Q.FieldByName('tds_frun').AsString+';');
                  End;
                  Q.Next;
                End;
              End Else
              Begin
                CD.FieldByName('LOCATION_TO').AsInteger := CD.FieldByName('LOCATION_FROM').AsInteger;
              End;
            End Else
            Begin
              CD.FieldByName('LOCATION_TO').AsInteger := CD.FieldByName('LOCATION_FROM').AsInteger;
            End;
            CD.Post;
            CD.Next;
          End;

          Q.SQL.Text := 'select frun,ftravel_time from tlocation where fwarehouse = '+WareHouse_ID.ToString+' order by forder';
          Q.Open;

          O.Add('/* BEGIN TRAVEL TIME */');
          TravelTimeCount := 0;
          while Not Q.EOF do
          Begin
            TravelTime[TravelTimeCount].Location := Q.FieldByName('frun').AsInteger;
            TravelTime[TravelTimeCount].Time := Q.FieldByName('ftravel_time').AsInteger;
            O.Add('/* LOC='+TravelTime[TravelTimeCount].Location.ToString+' TIME='+TravelTime[TravelTimeCount].Time.ToString+' */');
            Inc(TravelTimeCount);
            Q.Next;
          End;
          O.Add('/* END TRAVEL TIME */');
          CD.First;
          while Not CD.EOF do
          Begin
            if TimeSummary[CD.FieldByName('LOCATION_TO').AsInteger].Sum = -1 then
            Begin
              TimeSummary[CD.FieldByName('LOCATION_TO').AsInteger].Sum := 0;
              TimeSummary[CD.FieldByName('LOCATION_TO').AsInteger].WH_Sum := 0;
            End;
            TimeSummary[CD.FieldByName('LOCATION_TO').AsInteger].Sum := TimeSummary[CD.FieldByName('LOCATION_TO').AsInteger].Sum+CD.FieldByName('TIME').AsInteger;
            TimeSummary[CD.FieldByName('LOCATION_TO').AsInteger].WH_Sum := TimeSummary[CD.FieldByName('LOCATION_TO').AsInteger].WH_Sum+CD.FieldByName('WH_TIME').AsInteger;
            CD.Next;
          End;

          Q.SQL.Text := 'Select * from tstep where fShipment_Type = ''Transfer order shipment'' order by forder';
          Q.Open;

          O.Add('/* MAIN 1 */');
          S := Select('Select s.fShip_From_Time ' +
              'from tShipment s, tTrip t, tTrip_Detail td ' +
              'Where t.fRun = td.fMaster and td.fShipment = s.fRun and t.fCode = ''' + Trip + ''' and s.FDELIVERY_ADDRESSDESCRIPTION = ''' + Branch + ''' ' +
              'Order by td.fOrder Limit 1');

          Goto_Time := EncodeTime(Str2Int(GetColumnChar(1, s, ':')), Str2Int(GetColumnChar(2, s, ':')), 0, 0);

          Q.First;
          while Not Q.EOF do
          Begin
            IncTime(Q.FieldByName('fdetail').AsInteger);

            Q.Next;
            if Q.FieldByName('floop').AsInteger = 1 then
            Begin
              Break;
            End;
          End;
          O.Add('/* BEGIN LOOP */');

          //for LocRun := LocList.Count - 1 Downto 0 do
          for LocRun := 0 To LocList.Count - 1 do
          Begin
            L1 := LocList.Strings[LocRun].ToInteger;
            if TimeSummary[L1].Sum > -1  then
            Begin
              Next_Port := L1;
              if LocRun < LocList.Count - 1 then
                Next_Port := LocList.Strings[LocRun + 1].ToInteger;

              Inc(BoardD2CCount);
              Inc(BoardWhoCount);

              BoardD2CData[2, 2, BoardD2CCount] := FormatDateTime('YYYY-MM-DD HH:NN', now);
              BoardD2CData[3, 2, BoardWhoCount] := 'BBI';
              BoardD2CData[4, 2, BoardWhoCount] := TripRun;
              BoardD2CData[6, 2, BoardWhoCount] := L1.ToString;
              BoardD2CData[10, 2, BoardWhoCount] := '0';

              BoardWhoData[2, 2, BoardWhoCount] := FormatDateTime('YYYY-MM-DD HH:NN', now);
              BoardWhoData[3, 2, BoardWhoCount] := 'WHI';
              BoardWhoData[4, 2, BoardWhoCount] := TripRun;
              BoardWhoData[6, 2, BoardWhoCount] := L1.ToString;
              BoardWhoData[9, 2, BoardWhoCount] := '0';

              O.Add('/* LOOP LOC='+L1.ToString+'->'+Next_Port.ToString+' T='+GetTravelTime(L1,Next_Port).ToString+' */');

              if LocRun = 0 then
              Begin
                B2B := 0;
                IncTime(GetTravelTime(L1,L1));
              End;

              Q.First;
              While Not Q.EOF Do
              Begin
                if Q['floop'] = 1 then
                Begin
                  if Q['ftype'] = 1 then // ������Ңͧ���
                  Begin
                    if Pos('��ѧ', Q['fname']) > 0 then
                    Begin
                      IncTime(TimeSummary[L1].WH_Sum);
                    End Else
                    Begin
                      IncTime(TimeSummary[L1].Sum);
                    End;
                  End Else
                  if Q['ftype'] = 3 then // �����Թ�ҧ��ѧ��ҶѴ�
                  Begin
                    IncTime(GetTravelTime(L1,Next_Port));
                  End Else
                  Begin
                    IncTime(Q.FieldByName('fdetail').AsInteger);
                  End;
                End;
                Q.Next;
              End;
            End;
          End;

          O.Add('/* END LOOP */');
          O.Add('/* MAIN 2 */');
          Q.First;
          while Not Q.EOF do
          Begin
            if Q.FieldByName('forder').AsString < '2' then
            Begin
              Break;
              IncTime(Q.FieldByName('fdetail').AsInteger);
            End;
            Q.Next;
          End;

          DD := Str2Float(Select('Select fDetail from tStep Where fShipment_Type = ''Transfer order shipment'' and fOrder = 1'));
          Goto_Time := Str2Float(TripData[1, 2]) - (DD / 1440);
          DecTime(Floor(DD));

          O.Add('/* END TRIP['+(LL+1).ToString+']='+TRIP+' */');
          O.Add('');
        End;

        QBranch.Next;
      End;
      ShareList.Free;


      // ------------------------ BBI -------------------------
      Q.SQL.Text := 'Select * from tTrip Where fCode = ''' + Trip + ''' ';
      Q.Open;
      TripDate := Q.FieldByName('FSHIPDATE').AsDateTime;
      Q.Close;

      I3 := 0;
      for I := BoardD2CCount Downto 1 do
      Begin
        Temp := '';
        SQL := 'Insert into tBoarding_Pass (';
        for I2 := 1 to 10 do
        Begin
          Temp := Temp + BoardD2CData[i2, 1, 0] + ',';
          if BoardD2CData[i2, 1, 0] = 'FCODE' then
          Begin
            BoardD2CData[i2, 2, i] := MaxCode('B', 'tboarding_pass', WareHouse_ID.ToString, '');
          End Else
          if BoardD2CData[i2, 1, 0] = 'FORDER' then
          Begin
            Inc(I3);
            BoardD2CData[i2, 2, i] := I3.ToString;
          End Else
          if BoardD2CData[i2, 1, 0] = 'FDOCKIN_DATETIME_PLAN' then
          Begin
            BoardD2CData[i2, 2, i] := FormatDateTime('YYYY-MM-DD', TripDate) + ' ' + BoardD2CData[i2, 2, i];
            fCheckIn := BoardD2CData[i2, 2, i];
          End Else
          if BoardD2CData[i2, 1, 0] = 'FDOCKOUT_DATETIME_PLAN' then
          Begin
            BoardD2CData[i2, 2, i] := FormatDateTime('YYYY-MM-DD', TripDate) + ' ' + BoardD2CData[i2, 2, i];
            fCheckOut := BoardD2CData[i2, 2, i];
          End Else
          if BoardD2CData[i2, 1, 0] = 'FWAREHOUSE_DATETIME_PLAN' then
          Begin
            BoardD2CData[i2, 2, i] := FormatDateTime('YYYY-MM-DD', TripDate) + ' ' + BoardD2CData[i2, 2, i];
          End;
        End;

        for I2 := 1 to 10 do
        Begin
          if BoardD2CData[i2, 1, 0] = 'FDOCKING' then
          Begin
            ss := 'Select d.fRun, dd.fTime from tDocking d left join tDocking_Detail dd on d.fRun = dd.fMaster ' +
                    'and dd.fCheckIn < ''' + fCheckOut + ''' and dd.fCheckOut > ''' + fCheckIn + ''' ' +
                  'where d.fName not like ''%�����%'' and d.fIn = ''1'' and d.fLocation = ' + BoardD2CData[i2, 2, i] + ' and d.fMax_Volume >= ' + VehVol.ToString + ' ' +
                  'order by dd.ftime, d.fcode limit 1';

            Form1.Memo6.Lines.Add(ss);
            Docking := Select(ss);
            if (GetColumn(1, Docking) = '') or (GetColumn(2, Docking) <> '') then
            Begin
              ss := 'Select fRun from tDocking where fName like ''%�����%'' and fIn = ''1'' and fLocation = ' + BoardD2CData[i2, 2, i] + ' and fMax_Volume >= ' + VehVol.ToString;
              Form1.Memo6.Lines.Add(ss);
              Docking := Select(ss);
            End;
            BoardD2CData[i2, 2, i] := GetColumn(1, Docking);
          End;
        End;

        Delete(Temp, Length(Temp), 1);
        SQL := SQL + Temp + ') Values(';
        Temp := '';
        for I2 := 1 to 10 do
        Begin
          Temp := Temp + '''' + BoardD2CData[i2, 2, i] + ''',';
        End;
        Delete(Temp, Length(Temp), 1);
        SQL := SQL + Temp + ')';
        Form1.Memo6.Lines.Add(SQL);
        Form1.Memo6.Lines.Add('');
        ExecSQL(SQL);

        SQL := 'Insert into tDocking_Detail (fMaster, fTrip, fCheckIn, fCheckOut, fTime) ' +
               'Values (' + GetColumn(1, Docking) + ', ' + TripRun + ', ''' + fCheckIn + ''', ''' + fCheckOut + ''', ' +
                     '''' + FormatDateTime('YYMMDD', TripDate) +FormatDateTime('HHNNSSZZZ', Now) + ''') ';
        Form1.Memo6.Lines.Add(SQL);
        Form1.Memo6.Lines.Add('');
        ExecSQL(SQL);
      End;

      // ---------------------- WHI ------------------------
      I3 := 0;
      for I := BoardWhoCount Downto 1 do
      Begin
        Temp := '';
        SQL := 'Insert into tBoarding_Pass (';
        for I2 := 1 to 9 do
        Begin
          Temp := Temp + BoardWhoData[i2, 1, 0] + ',';
          if BoardWhoData[i2, 1, 0] = 'FCODE' then
          Begin
            BoardWhoData[i2, 2, i] := MaxCode('B', 'tboarding_pass', WareHouse_ID.ToString, '');
          End Else
          if BoardWhoData[i2, 1, 0] = 'FORDER' then
          Begin
            Inc(I3);
            BoardWhoData[i2, 2, i] := I3.ToString;
          End Else
          if BoardWhoData[i2, 1, 0] = 'FDOCKIN_DATETIME_PLAN' then
          Begin
            BoardWhoData[i2, 2, i] := FormatDateTime('YYYY-MM-DD', TripDate) + ' ' + BoardWhoData[i2, 2, i];
          End Else
          if BoardWhoData[i2, 1, 0] = 'FDOCKOUT_DATETIME_PLAN' then
          Begin
            BoardWhoData[i2, 2, i] := FormatDateTime('YYYY-MM-DD', TripDate) + ' ' + BoardWhoData[i2, 2, i];
          End Else
          if BoardWhoData[i2, 1, 0] = 'FDOCKING' then
          Begin
            BoardWhoData[i2, 2, i] := BoardD2CData[i2, 2, i]
          End;
        End;
        Delete(Temp, Length(Temp), 1);
        SQL := SQL + Temp + ') Values(';
        Temp := '';
        for I2 := 1 to 9 do
        Begin
          Temp := Temp + '''' + BoardWhoData[i2, 2, i] + ''',';
        End;
        Delete(Temp, Length(Temp), 1);
        SQL := SQL + Temp + ')';
        Form1.Memo6.Lines.Add(SQL);
        Form1.Memo6.Lines.Add('');
        ExecSQL(SQL);
      End;

      for I := BoardD2CCount Downto 1 do
      Begin
        for I2 := 1 to 10 do
        Begin
          Form1.Memo6.Lines.Add(BoardD2CData[i2, 1, 0] + ' = ' + BoardD2CData[i2, 2, i]);
        End;
        Form1.Memo6.Lines.Add('');
      End;

      Form1.Memo6.Lines.Add('---------------------');
      for I := BoardWhoCount Downto 1 do
      Begin
        for I2 := 1 to 8 do
        Begin
          Form1.Memo6.Lines.Add(BoardWhoData[i2, 1, 0] + ' = ' + BoardWhoData[i2, 2, i]);
        End;
        Form1.Memo6.Lines.Add('');
      End;

    End;
  End; // --- End For Trip
  
  CD.Free;
  //ShowMessage(TravelTimeCount.ToString);
//  ShowMessage('');
  //Form1.DataSource1.DataSet := CD;
  {while Not MemDS.EOF do
  Begin
    ShowMessage(MemDS.FieldByName('LOCATION').AsString);
    MemDS.Next;
  End;}
  //ShowMessage(MemDS.RecordCount.ToString);

  //MemDS.Free;
End;

procedure TForm1.Button1Click(Sender: TObject);
Var C : TUniConnection;
    Q : TUniQuery;
    s, Code : String;
    Trip : TArray<String>;


  Procedure InsertData;
  Var Data : Array[1..30] Of String;
      s : String;
  Begin
    //Q.SQL.Text := 'Select fRun From tTrip Where fCode = ''' + + ''' ';
    //Q.Open;


  End;

begin
  //UniQuery1.SQL.Text := Memo1.Lines.Text;
  //UniQuery1.Open;
  //GenSQL(['T210723001','T210723003','T210723006','T210723007'],UniQuery1,Memo5.Lines);

  Trip := [];
  C := TUniConnection.Create(Nil);
  C.Server := cServer;
  C.Port := cPort;
  c.Database := cDatabase;
  C.Username := cUserName;
  C.Password := cPassword;
  C.ProviderName := 'MySQL';
  C.Connected := True;

  Q := TUniQuery.Create(Nil);
  Q.Connection := c;
  Q.SQL.Text := 'Select t.fCode from tTrip t left join tboarding_pass b on t.fRun = b.FREFERENCE Where t.fVehicle > 0 and b.fRun is null ' +
                'order by t.fcode ;';

  Q.SQL.Text := 'Select fCode From tTrip where fShipDate = ''' + FormatDateTime('YYYY-MM-DD', DT.Date) + ''' Order by fCode';
  Q.Open;
  while Not Q.Eof do
  Begin
    Trip := Trip + [Q.FieldByName('FCODE').AsString];
    Q.Next;
    Break;
  End;
  Q.Close;

  if Edit1.Text <> '' then
    Trip := [Edit1.Text];  
  
  GenSQL(Trip ,Q, Memo5.Lines, c);
  UniQuery1.Close;

  Q.Close;
  Q.Free;
  C.Free;
end;

procedure TForm1.FormCreate(Sender: TObject);
Var fn : String;
begin
  Caption := Caption + '   [ Last modify 23/09/64 15:45 ]';

  fn := ExtractFilePath(ParamStr(0))+'config.ini';
  if FileExists(fn)  then
  begin
    with TINIFile.Create(fn) do
    begin
      DirPath := ReadString('CONFIG','DIRPATH','');
      cServer := ReadString('MySQL','host','202.44.53.36');
      cPort := ReadInteger('MySQL','port',63308);
      cUsername := ReadString('MySQL','username','admindb');
      cPassword := ReadString('MySQL','password','1msPassw0rd#');
      cDatabase := ReadString('MySQL','database','dos');
    end;
  end;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  Timer1.Enabled := False;
  Button1.Click;
end;

end.
