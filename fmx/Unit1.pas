{ Test TNetHttpClient in FMX application. }
unit Unit1;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Edit,
  System.Net.HttpClientComponent, System.Net.HttpClient;

type
  TForm1 = class(TForm)
    EditUrl: TEdit;
    ButtonDownload: TButton;
    ProgressBar1: TProgressBar;
    LabelStatus: TLabel;
    ButtonUrlCgeDownload: TButton;
    ButtonUrl404: TButton;
    ButtonUrlCgeWebpage: TButton;
    ButtonUrlNeverssl: TButton;
    procedure ButtonDownloadClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure ButtonUrlCgeDownloadClick(Sender: TObject);
    procedure ButtonUrlCgeWebpageClick(Sender: TObject);
    procedure ButtonUrlNeversslClick(Sender: TObject);
    procedure ButtonUrl404Click(Sender: TObject);
  private
    Done: Boolean;
    C: TNetHttpClient;
    ResponseContent: TMemoryStream;
    Response: IHTTPResponse;
    procedure StopDownload;
    procedure ReceiveData(const Sender: TObject;
      AContentLength: Int64; AReadCount: Int64; var AAbort: Boolean);
    procedure RequestCompleted(const Sender: TObject;
      const AResponse: IHTTPResponse);
    procedure RequestError(const Sender: TObject;
      const AError: string);
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

uses Math;

{$R *.fmx}

procedure TForm1.StopDownload;
var
  Waited: Int64;
begin
  if (Response <> nil) and
     (not Response.AsyncResult.IsCompleted) then
  begin
    // TNetHttpClient causes exceptions if freed without properly closing the connection
    // Luckily, usually it can be cancelled immediately.
    if not Response.AsyncResult.Cancel then
      ShowMessage('Operation cannot be cancelled, ignoring');
    Waited := 0;
    while not Response.AsyncResult.IsCancelled do
    begin
      Sleep(100);
      Waited := Waited + 100;
    end;
    if Waited <> 0 then
      ShowMessage(Format('Waited to cancel for %f seconds', [Waited / 1000]));
  end;

  FreeAndNil(C);
  FreeAndNil(ResponseContent);
  Response := nil;
end;

procedure TForm1.ButtonDownloadClick(Sender: TObject);
begin
  StopDownload;

  ResponseContent := TMemoryStream.Create;

  C := TNetHttpClient.Create(Self);
  C.Asynchronous := true;
  C.OnRequestCompleted := RequestCompleted;
  C.OnRequestError := RequestError;
  C.OnReceiveData := ReceiveData;
  C.SynchronizeEvents := true;
  Response := C.Get(EditUrl.Text, ResponseContent);
end;

procedure TForm1.ButtonUrl404Click(Sender: TObject);
begin
  EditUrl.Text := 'https://castle-engine.io/test-error.txt';
end;

procedure TForm1.ButtonUrlCgeDownloadClick(Sender: TObject);
begin
  EditUrl.Text := 'https://castle-engine.io/latest.zip';
end;

procedure TForm1.ButtonUrlCgeWebpageClick(Sender: TObject);
begin
  EditUrl.Text := 'https://castle-engine.io/';
end;

procedure TForm1.ButtonUrlNeversslClick(Sender: TObject);
begin
  EditUrl.Text := 'http://neverssl.com/';
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  // TNetHttpClient causes exceptions if freed without properly closing the connection
  StopDownload;
end;

procedure TForm1.ReceiveData(const Sender: TObject;
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

  ProgressBar1.Value := Round(Progress * 100);
  LabelStatus.Text := Format('Received data %d / %d, progress %f', [
    AReadCount,
    AContentLength,
    Progress
  ]);
  LabelStatus.FontColor := TColorRec.Green;
end;

procedure TForm1.RequestCompleted(const Sender: TObject;
  const AResponse: IHTTPResponse);
begin
  Done := true;
  ProgressBar1.Value := 100;
  LabelStatus.Text := Format('RequestCompleted, status %d, length %d, mime %s', [
    AResponse.StatusCode,
    AResponse.ContentLength,
    AResponse.MimeType
  ]);
  LabelStatus.FontColor := TColorRec.Green;
end;

procedure TForm1.RequestError(const Sender: TObject;
  const AError: string);
begin
  Done := true;
  LabelStatus.Text := Format('RequestError, %s', [
    AError
  ]);
  LabelStatus.FontColor := TColorRec.Red;
end;

end.
