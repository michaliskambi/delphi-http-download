# Simple tests of Delphi http(s) downloading

Done to test the underlying implementation of _Castle Game Engine_'s TCastleDownload class on Delphi, that should be able to do asynchronous downloads of http / https.

## Version 1: TNetHTTPClient

Test Delphi TNetHTTPClient ( https://docwiki.embarcadero.com/Libraries/Sydney/en/System.Net.HttpClientComponent.TNetHTTPClient , https://docwiki.embarcadero.com/RADStudio/Sydney/en/Using_an_HTTP_Client#Handling_Client-side_Certificates ).

Note that this doesn't require OpenSSL DLLs. It uses SSL libraries built into Windows. It uses `winhttp.dll` on Windows.

## Version 2: TIdHttp (Indy)

Test Indy's `TIdHttp`.

This requires OpenSSL DLLs. They are distributed also in this repo, for convenience. But you should rather take the latest ones:

- From Indy: https://indy.fulgan.com/SSL/ , https://github.com/IndySockets/OpenSSL-Binaries

- Or from Castle Game Engine: https://github.com/castle-engine/castle-engine/tree/master/tools/build-tool/data/external_libraries

It uses socket access to perform HTTP(S) query. So it does more work in Pascal compared to TNetHTTPClient, TNetHTTPClient delegates more work to the Windows libraries.