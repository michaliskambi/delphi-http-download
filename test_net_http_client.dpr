{ Test TNetHttpClient. }
program test_net_http_client;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils, Classes, Math,
  System.Net.HttpClientComponent, System.Net.HttpClient;

var
  Done: Boolean;
  C: TNetHttpClient;

type
  TEventHandler = class
    class procedure ReceiveData(const Sender: TObject;
      AContentLength: Int64; AReadCount: Int64; var AAbort: Boolean);
    class procedure RequestCompleted(const Sender: TObject;
      const AResponse: IHTTPResponse);
    class procedure RequestError(const Sender: TObject;
      const AError: string);
  end;

{ TEventHandler }

class procedure TEventHandler.ReceiveData(const Sender: TObject;
  AContentLength, AReadCount: Int64; var AAbort: Boolean);
var
  Progress: Single;
begin
  if AContentLength > 0 then
  begin
    if AReadCount > AContentLength then
      Writeln('Warning: TNetHttpClient: AReadCount > AContentLength');
    Progress := Min(1.0, AReadCount / AContentLength);
  end else
    Progress := 0.0;

  Writeln(Format('Received data %d / %d, progress %f', [
    AReadCount,
    AContentLength,
    Progress
  ]));
end;

class procedure TEventHandler.RequestCompleted(const Sender: TObject;
  const AResponse: IHTTPResponse);
begin
  Done := true;
  Writeln(Format('RequestCompleted, status %d, length %d, mime %s', [
    AResponse.StatusCode,
    AResponse.ContentLength,
    AResponse.MimeType
  ]));
end;

class procedure TEventHandler.RequestError(const Sender: TObject;
  const AError: string);
begin
  Done := true;
  Writeln(Format('RequestError, %s', [
    AError
  ]));
end;

begin
  try
    var ResponseContent := TMemoryStream.Create;
    try
      C := TNetHttpClient.Create(nil);
      try
        C.Asynchronous := true;
        C.OnRequestCompleted := TEventHandler.RequestCompleted;
        C.OnRequestError := TEventHandler.RequestError;
        C.OnReceiveData := TEventHandler.ReceiveData;
        C.SynchronizeEvents := true;
        Writeln(TimeToStr(Now) + ' sending');
        C.Get(
          'https://castle-engine.io/'
          //'https://castle-engine.io/latest.zip'
          //'https://www.wikipedia.org/'
          //'https://castle-engine.io/test-error.txt'
          , ResponseContent);
        Writeln(TimeToStr(Now) + ' after Get, ', ResponseContent.Size);

        { We set the request to be Asynchronous.
          This means we can do some work in the main thread
          in the meantime. }
        while not Done do
          Sleep(1000);
      finally
        FreeAndNil(C);
      end;
    finally
      FreeAndNil(ResponseContent);
    end;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;

  Readln; // keep terminal, spawned by Delphi IDE, visible until you press Enter
end.
