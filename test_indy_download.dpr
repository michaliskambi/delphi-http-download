program test_indy_download;

uses
  System.SysUtils, Classes,
  IdHttp, IdSSL, IdSSLOpenSSL, IdSSLOpenSSLHeaders, IdCTypes;

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
  end;

class procedure TEventHandler.StatusInfoEx(ASender: TObject; const AsslSocket: PSSL;
  const AWhere, Aret: TIdC_INT; const AType, AMsg: String);
begin
  SSL_set_tlsext_host_name(AsslSocket, IdHttp.Request.Host);
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

        IdHttp.Get('https://castle-engine.io/', Contents);

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

    Readln;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
