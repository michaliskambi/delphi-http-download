{ Test TIdHttp. }
program test_indy_download;

uses
  System.SysUtils, Classes,
  IdHttp, IdSSL, IdSSLOpenSSL, IdSSLOpenSSLHeaders, IdCTypes,
  IdHeaderList, IdTCPConnection, IdComponent;

var
  IdHttp: TIdHttp;
  MyIOHandler: TIdSSLIOHandlerSocketOpenSSL;

type
  TEventHandler = class
    { Use with special IO handler to do SSL_set_tlsext_host_name,
      otherwise accessing sites behind Cloudflare will fail,
      see https://stackoverflow.com/questions/29875664/eidosslunderlyingcryptoerror-exception }
    class procedure StatusInfoEx(ASender: TObject; const AsslSocket: PSSL;
      const AWhere, Aret: TIdC_INT; const AType, AMsg: String);
    class procedure Redirect(Sender: TObject;
      var Dest: string; var NumRedirect: Integer; var Handled: boolean; var VMethod: TIdHTTPMethod);
    class procedure HeadersAvailable(Sender: TObject;
      AHeaders: TIdHeaderList; var VContinue: Boolean);
    class procedure Work(ASender: TObject;
      AWorkMode: TWorkMode; AWorkCount: Int64);
  end;

class procedure TEventHandler.StatusInfoEx(ASender: TObject; const AsslSocket: PSSL;
  const AWhere, Aret: TIdC_INT; const AType, AMsg: String);
begin
  SSL_set_tlsext_host_name(AsslSocket, IdHttp.Request.Host);
end;

class procedure TEventHandler.Redirect(Sender: TObject;
  var Dest: string; var NumRedirect: Integer; var Handled: boolean; var VMethod: TIdHTTPMethod);
begin
  Writeln('Redirected to ', Dest);
end;

class procedure TEventHandler.HeadersAvailable(Sender: TObject;
  AHeaders: TIdHeaderList; var VContinue: Boolean);
var
  ContentType, ContentLength: String;
  ContentLengthInt: Int64;
begin
  ContentType := AHeaders.Values['Content-Type'];
  if ContentType <> '' then
    Writeln('Content type (with MIME type): ', ContentType);

  ContentLength := AHeaders.Values['Content-Length'];
  if TryStrToInt64(ContentLength, ContentLengthInt) then
    Writeln('Content length ', ContentLengthInt);
end;

class procedure TEventHandler.Work(ASender: TObject;
  AWorkMode: TWorkMode; AWorkCount: Int64);
begin
  Writeln('Work ', AWorkCount);
end;

var
  Contents: TMemoryStream;
begin
  try
    Contents := TMemoryStream.Create;
    try
      IdHttp := TIdHTTP.Create(nil);
      try
        IdHttp.HandleRedirects := true;

        { We need to pass User-Agent to avoid Cloudflare answering with 403 Forbidden.
          See https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/User-Agent
          about User-Agent. }
        IdHttp.Request.UserAgent :=  'Mozilla/5.0 (compatible; CastleGameEngine/1.0; https://castle-engine.io/manual_network.php)';

        { Set special IO handler to do SSL_set_tlsext_host_name,
          otherwise accessing sites behind Cloudflare will fail,
          see https://stackoverflow.com/questions/29875664/eidosslunderlyingcryptoerror-exception }
        MyIOHandler := TIdSSLIOHandlerSocketOpenSSL.Create(IdHttp);
        MyIOHandler.OnStatusInfoEx := TEventHandler.StatusInfoEx;
        MyIOHandler.SSLOptions.Method := sslvSSLv23;
        MyIOHandler.SSLOptions.SSLVersions := [sslvTLSv1_2, sslvTLSv1_1, sslvTLSv1];
        IdHttp.IOHandler := MyIOHandler;

        IdHttp.OnRedirect := TEventHandler.Redirect;
        IdHttp.OnHeadersAvailable := TEventHandler.HeadersAvailable;
        IdHttp.OnWork := TEventHandler.Work;

        // This is synchronous, we wait for download to be finished
        IdHttp.Get(
          // test http error
//          'https://castle-engine.io/test-error.txt'
          'https://castle-engine.io/'
          // test redirect, and larger file download
//          'https://castle-engine.io/latest.zip'
          , Contents);

        Writeln('Done');
        Writeln('Response code: ', IdHttp.ResponseCode);
        Writeln('Size: ', Contents.Size);

        // TODO: get from server, also DwonloadedBytes, TotalBytes - using crit section
        // MimeType := URIMimeType(Url);
      finally
        FreeAndNil(MyIOHandler); // must be freed before IdHttp
        FreeAndNil(IdHttp);
      end;
    finally FreeAndNil(Contents) end;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;

  Readln; // keep terminal, spawned by Delphi IDE, visible until you press Enter
end.
