unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  {$IFDEF UNIX}
  // cthreads,
  {$ENDIF}
  JsonTools,
  CastleParameters, CastleClassUtils,
  CastleControl, CastleTimeUtils, CastleURIUtils,
  MiscSupportFunctions;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Memo1: TMemo;
    Panel1: TPanel;
    Panel2: TPanel;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private

  public

  end;

var
  Form1: TForm1;

procedure DebugMessage(const msg: String);

implementation

{$R *.lfm}

procedure DebugMessage(const msg: String);
begin
  {$ifdef useLog}
  WriteLnLog(msg);
  {$endif}
  Form1.Memo1.Lines.Add(msg);
  Application.ProcessMessages;
end;

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  Memo1.Clear;
end;

procedure TForm1.Button1Click(Sender: TObject);
var
  Stream: TStream;
  DownloadList: TCardDownloadList;
  i: Integer;
begin
  Stream := DownloadFileList;
  try
    if not (Stream = nil) then
      begin
        DebugMessage('Download list loaded');
        DownloadList := ExtractJsonData(Stream);
        PrintDownloadList(DownloadList);
      end;
  finally
    FreeAndNil(Stream);
  end;
end;



end.

