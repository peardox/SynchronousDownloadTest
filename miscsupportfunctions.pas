unit MiscSupportFunctions;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  {$ifndef VER3_0} OpenSSLSockets, {$endif}
  JsonTools,
  TypInfo,
  CastleDownload;

type
  TFormat = Record
    width: Integer;
    height: Integer;
  end;

  TSource = Record
    protocol: String;
    server: String;
    path: String;
    key: String;
    mimetype: String;
    append: String;
    format: TFormat;
    local: Boolean;
    notes: String;
  end;
  TSourceArray = Array of TSource;

  TLimit = Record
    protocol: String;
    server: String;
    ratelimit: Integer;
    error_code: Integer;
    notes: String;
  end;
  TLimitsArray = Array of TLimit;

  TFileDetail = Record
    uuid: String;
    cardname: String;
    setcode: String;
    cardtype: String;
    cardnum: String;
    side: String;
    rarity: String;
    scryfall: String;
    hasprice: Boolean;
  end;
  TFileDetailsArray = Array of TFileDetail;

  TCardDownloadList = Record
    Sources: TSourceArray;
    Limits: TLimitsArray;
    FileDetails: TFileDetailsArray;
  end;

const
  FILELIST_URI = 'https://api.peardox.co.uk/cards.php';

function JSONKindToString(Node: TJsonNode): string;
procedure MapJsonObject(Json: TJsonNode);
function CreateFormat(Json: TJsonNode): TFormat;
function CreateSource(Json: TJsonNode): TSource;
function CreateLimit(Json: TJsonNode): TLimit;
function CreateFileDetail(Json: TJsonNode): TFileDetail;
function ExtractJsonData(Stream: TStream; FreeStream: Boolean = False): TCardDownloadList;
procedure PrintDownloadList(downloadList: TCardDownloadList);
function DownloadFileList: TStream;

implementation

uses
  Unit1; // For DebugMessage

function JSONKindToString(Node: TJsonNode): string;
begin
  result := GetEnumName(TypeInfo(TJsonNodeKind), ord(Node.&Kind));
end;

procedure MapJsonObject(Json: TJsonNode);
var
  Node: TJsonNode;
  Txt: String;
begin
  for Node in Json do
    begin
      case Node.Name of
      'dummyField':
        begin
          // Just a dummy field
        end;
      else
          begin
            Txt := Chr(39) + Node.Name + Chr(39) + ':' + LineEnding +
            '  begin' + LineEnding +
            '    if not(Node.Kind = ' + JSONKindToString(Node) + ') then' + LineEnding +
            '      DebugMessage(' + Chr(39) +  'TypeError for ' +
              Node.Name + ' expected '  + JSONKindToString(Node) +
              ' got ' + Chr(39) + ' + JSONKindToString(Node)' + ')' + LineEnding +
            '    else' + LineEnding;
            if Node.Kind = nkString then
              Txt += '      Rec.' + Node.Name + ' := Node.AsString;' + LineEnding
            else if Node.Kind = nkNumber then
              Txt += '      Rec.' + Node.Name + ' := Trunc(Node.AsNumber);' + LineEnding
            else if Node.Kind = nkBool then
              Txt += '      Rec.' + Node.Name + ' := Node.AsBoolean;' + LineEnding
            else if Node.Kind = nkObject then
              Txt += '      // Rec.' + Node.Name + ' := MapJsonObject(Node); // *** FIXME ***' + LineEnding
            else if Node.Kind = nkArray then
              Txt += '      // Rec.' + Node.Name + ' := MapJsonArray(Node); // *** FIXME ***' + LineEnding
            else
              Txt += '      Rec.' + Node.Name + ' := Node.AsString; // *** FIXME ***' + LineEnding;
            Txt += '  end;';
            DebugMessage(Txt);
          end;
      end;
    end;
end;

function CreateFormat(Json: TJsonNode): TFormat;
var
  Node: TJsonNode;
  Rec: TFormat;
begin
  Rec := Default(TFormat);
  for Node in Json do
    begin
      case Node.Name of
        'width':
          begin
            if not(Node.Kind = nkNumber) then
              DebugMessage('TypeError for width expected nkNumber got ' + JSONKindToString(Node))
            else
              Rec.width := Trunc(Node.AsNumber);
          end;
        'height':
          begin
            if not(Node.Kind = nkNumber) then
              DebugMessage('TypeError for height expected nkNumber got ' + JSONKindToString(Node))
            else
              Rec.height := Trunc(Node.AsNumber);
          end;
        else
          DebugMessage('Unexpected data - ' + Node.Name + ' -> ' + JSONKindToString(Node));
      end;
    end;
  Result := Rec;
end;

function CreateSource(Json: TJsonNode): TSource;
var
  Node: TJsonNode;
  Rec: TSource;
begin
  Rec := Default(TSource);
  for Node in Json do
    begin
      case Node.Name of
        'protocol':
          begin
            if not(Node.Kind = nkString) then
              DebugMessage('TypeError for protocol expected nkString got ' + JSONKindToString(Node))
            else
              Rec.protocol := Node.AsString;
          end;
        'server':
          begin
            if not(Node.Kind = nkString) then
              DebugMessage('TypeError for server expected nkString got ' + JSONKindToString(Node))
            else
              Rec.server := Node.AsString;
          end;
        'path':
          begin
            if not(Node.Kind = nkString) then
              DebugMessage('TypeError for path expected nkString got ' + JSONKindToString(Node))
            else
              Rec.path := Node.AsString;
          end;
        'key':
          begin
            if not(Node.Kind = nkString) then
              DebugMessage('TypeError for key expected nkString got ' + JSONKindToString(Node))
            else
              Rec.key := Node.AsString;
          end;
        'mimetype':
          begin
            if not(Node.Kind = nkString) then
              DebugMessage('TypeError for mimetype expected nkString got ' + JSONKindToString(Node))
            else
              Rec.mimetype := Node.AsString;
          end;
        'append':
          begin
            if not(Node.Kind = nkString) then
              DebugMessage('TypeError for append expected nkString got ' + JSONKindToString(Node))
            else
              Rec.append := Node.AsString;
          end;
        'format':
          begin
            if not(Node.Kind = nkObject) then
              DebugMessage('TypeError for format expected nkObject got ' + JSONKindToString(Node))
            else
              Rec.format := CreateFormat(Node);
          end;
        'local':
          begin
            if not(Node.Kind = nkBool) then
              DebugMessage('TypeError for local expected nkBool got ' + JSONKindToString(Node))
            else
              Rec.local := Node.AsBoolean;
          end;
        'notes':
          begin
            if not(Node.Kind = nkString) then
              DebugMessage('TypeError for notes expected nkString got ' + JSONKindToString(Node))
            else
              Rec.notes := Node.AsString;
          end;
        else
          DebugMessage('Unexpected data - ' + Node.Name + ' -> ' + JSONKindToString(Node));
      end;
    end;
  Result := Rec;
end;

function CreateLimit(Json: TJsonNode): TLimit;
var
  Node: TJsonNode;
  Rec: TLimit;
begin
  Rec := Default(TLimit);
  for Node in Json do
    begin
      case Node.Name of
        'protocol':
          begin
            if not(Node.Kind = nkString) then
              DebugMessage('TypeError for protocol expected nkString got ' + JSONKindToString(Node))
            else
              Rec.protocol := Node.AsString;
          end;
        'server':
          begin
            if not(Node.Kind = nkString) then
              DebugMessage('TypeError for server expected nkString got ' + JSONKindToString(Node))
            else
              Rec.server := Node.AsString;
          end;
        'ratelimit':
          begin
            if not(Node.Kind = nkNumber) then
              DebugMessage('TypeError for ratelimit expected nkNumber got ' + JSONKindToString(Node))
            else
              Rec.ratelimit := Trunc(Node.AsNumber);
          end;
        'error_code':
          begin
            if not(Node.Kind = nkNumber) then
              DebugMessage('TypeError for error_code expected nkNumber got ' + JSONKindToString(Node))
            else
              Rec.error_code := Trunc(Node.AsNumber);
          end;
        'notes':
          begin
            if not(Node.Kind = nkString) then
              DebugMessage('TypeError for notes expected nkString got ' + JSONKindToString(Node))
            else
              Rec.notes := Node.AsString;
          end;
        else
          DebugMessage('Unexpected data - ' + Node.Name + ' -> ' + JSONKindToString(Node));
      end;
    end;
  Result := Rec;
end;

function CreateFileDetail(Json: TJsonNode): TFileDetail;
var
  Node: TJsonNode;
  Rec: TFileDetail;
begin
  Rec := Default(TFileDetail);
  for Node in Json do
    begin
      case Node.Name of
        'uuid':
          begin
            if not(Node.Kind = nkString) then
              DebugMessage('TypeError for uuid expected nkString got ' + JSONKindToString(Node))
            else
              Rec.uuid := Node.AsString;
          end;
        'cardname':
          begin
            if not(Node.Kind = nkString) then
              DebugMessage('TypeError for cardname expected nkString got ' + JSONKindToString(Node))
            else
              Rec.cardname := Node.AsString;
          end;
        'setcode':
          begin
            if not(Node.Kind = nkString) then
              DebugMessage('TypeError for setcode expected nkString got ' + JSONKindToString(Node))
            else
              Rec.setcode := Node.AsString;
          end;
        'cardtype':
          begin
            if not(Node.Kind = nkString) then
              DebugMessage('TypeError for cardtype expected nkString got ' + JSONKindToString(Node))
            else
              Rec.cardtype := Node.AsString;
          end;
        'cardnum':
          begin
            if not(Node.Kind = nkString) then
              DebugMessage('TypeError for cardnum expected nkString got ' + JSONKindToString(Node))
            else
              Rec.cardnum := Node.AsString;
          end;
        'side':
          begin
            if not(Node.Kind = nkString) then
              DebugMessage('TypeError for side expected nkString got ' + JSONKindToString(Node))
            else
              Rec.side := Node.AsString;
          end;
        'rarity':
          begin
            if not(Node.Kind = nkString) then
              DebugMessage('TypeError for rarity expected nkString got ' + JSONKindToString(Node))
            else
              Rec.rarity := Node.AsString;
          end;
        'scryfall':
          begin
            if not(Node.Kind = nkString) then
              DebugMessage('TypeError for scryfall expected nkString got ' + JSONKindToString(Node))
            else
              Rec.scryfall := Node.AsString;
          end;
        'hasprice':
          begin
            if not(Node.Kind = nkNumber) then
              DebugMessage('TypeError for hasprice expected nkNumber got ' + JSONKindToString(Node))
            else
              Rec.hasprice := Node.AsBoolean;
          end;
        else
          DebugMessage('Unexpected data - ' + Node.Name + ' -> ' + JSONKindToString(Node));
      end;
    end;
  Result := Rec;
end;

function ExtractJsonData(Stream: TStream; FreeStream: Boolean = False): TCardDownloadList;
var
  Json: TJsonNode;
  Node: TJsonNode;
  CardData: TCardDownloadList;
  Idx: Integer;
begin
  CardData := Default(TCardDownloadList);
  Json := TJsonNode.Create;
  Json.LoadFromStream(Stream);
  try
    try
      for Node in Json do
        begin
          if Node.Kind = nkArray then
            begin
              DebugMessage(Node.Name + ' -> ' + JSONKindToString(Node) +
                ' has ' + IntToStr(Node.Count) + ' records');
              case Node.Name of
                'source':
                  begin
                    SetLength(CardData.Sources, Node.Count);
                    for Idx := 0 to Node.Count - 1 do
                      begin
                        CardData.Sources[Idx] := CreateSource(Node.Child(Idx));
                      end;
                  end;
                'limits':
                  begin
                    SetLength(CardData.Limits, Node.Count);
                    for Idx := 0 to Node.Count - 1 do
                      begin
                        CardData.Limits[Idx] := CreateLimit(Node.Child(Idx));
                      end;
                  end;
                'data':
                  begin
                    SetLength(CardData.FileDetails, Node.Count);
                    for Idx := 0 to Node.Count - 1 do
                      begin
//                        if Idx = 0 then
//                          MapJsonObject(Node.Child(Idx));
                        CardData.FileDetails[Idx] := CreateFileDetail(Node.Child(Idx));
                      end;
                  end;
                else
                  begin
                    DebugMessage('Unexpected data - ' + Node.Name + ' -> ' + JSONKindToString(Node));
                  end;
              end;
            end
          else
            DebugMessage('Unexpected data - ' + Node.Name + ' -> ' + JSONKindToString(Node));
        end;
    except
      on E : Exception do
        begin
          DebugMessage('Oops' + LineEnding +
                      'Trying to download : ' + FILELIST_URI + LineEnding +
                       E.ClassName + LineEnding +
                       E.Message);
          Json := nil;
         end;
    end;
  finally
    FreeAndNil(Json);
    if FreeStream then
      FreeAndNil(Stream);
  end;
  Result := CardData;
end;

procedure PrintDownloadList(downloadList: TCardDownloadList);
var
  i: Integer;
begin
  DebugMessage('Servers');
  DebugMessage('=======');
  for i := 0 to Length(DownloadList.Sources) - 1 do
    begin
      with DownloadList.Sources[i] do
        begin
          DebugMessage('Protocol    : ' + protocol);
          DebugMessage('Server      : ' + server);
          DebugMessage('Path        : ' + path);
          DebugMessage('Key         : ' + key);
          DebugMessage('Mimetype    : ' + mimetype);
          DebugMessage('Append      : ' + append);
          DebugMessage('Format(W)   : ' + IntToStr(format.width));
          DebugMessage('Format(H)   : ' + IntToStr(format.height));
          if local then
            DebugMessage('Local       : Yes')
          else
            DebugMessage('Local       : No');
          DebugMessage('Notes       : ' + notes);
        end;
      DebugMessage('=====');
    end;
  DebugMessage(LineEnding);

  DebugMessage('Limits');
  DebugMessage('======');
  for i := 0 to Length(DownloadList.Limits) - 1 do
    begin
      with DownloadList.Limits[i] do
        begin
          DebugMessage('Protocol    : ' + protocol);
          DebugMessage('Server      : ' + server);
          DebugMessage('Rate Limit  : ' + IntToStr(ratelimit));
          DebugMessage('Error Code  : ' + IntToStr(error_code));
          DebugMessage('Notes       : ' + notes);
        end;
      DebugMessage('=====');
    end;
  DebugMessage(LineEnding);

  DebugMessage('File Details');
  DebugMessage('============');
  for i := 0 to Length(DownloadList.FileDetails) - 1 do
    begin
      with DownloadList.FileDetails[i] do
        begin
          DebugMessage('MTGJSON ID  : ' + uuid);
          DebugMessage('CardName    : ' + cardname);
          DebugMessage('SetCode     : ' + setcode);
          DebugMessage('CardType    : ' + cardtype);
          DebugMessage('CardNumber  : ' + cardnum);
          DebugMessage('CardSide    : ' + side);
          DebugMessage('Rarity      : ' + rarity);
          DebugMessage('Scryfall ID : ' + scryfall);
          if hasprice then
            DebugMessage('HasPrice    : Yes')
          else
            DebugMessage('HasPrice    : No');
        end;
      DebugMessage('================');
    end;
  DebugMessage(LineEnding);
end;

function DownloadFileList: TStream;
var
  Stream: TStream;
begin
  Result := nil;
  EnableBlockingDownloads := True;
  Stream := Download(FILELIST_URI, [soForceMemoryStream]);
  try
    try
    except
      on E : Exception do
        begin
          DebugMessage('Oops' + LineEnding +
                      'Trying to download : ' + FILELIST_URI + LineEnding +
                       E.ClassName + LineEnding +
                       E.Message);
          Stream := nil;
         end;
    end;
  finally
    Result := Stream;
    EnableBlockingDownloads := False;
  end;
end;

end.

