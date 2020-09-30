unit DownloadQueue;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  {$ifndef VER3_0} OpenSSLSockets, {$endif}
  CastleDownload;

type
  TDownloadQueue = class(TObject)
  private
    FHeadObj: PDownloadItem;
    FTailObj: PDownloadItem;
  public
  end;

  PDownloadItem = ^TDownloadItem;
  TDownloadItem = class(TCastleDownload)
  private
    FNextObj: PDownloadItem;
    FPrevObj: PDownloadItem;
  public
  end;

implementation
{ Notes / ToDo

  LinkedList - Ref https://www.pascal-programming.info/articles/linkedlists.php
  FileSetDate on cache - https://www.freepascal.org/docs-html/rtl/sysutils/filesetdate.html
  Use TURI to check for domain restrictions - https://www.freepascal.org/docs-html/current/fcl/uriparser/turi.html

}

{ TDownloadObjectQueue ------------------------------------------------------ }

{ TDownloadItem ------------------------------------------------------------- }


end.

