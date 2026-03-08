unit MCP.Transport.Stdio;

interface

uses
  System.Classes, System.SysUtils, System.JSON, MCP.Types, MCP.JSONRPC, MCP.Parser;

type
  TMcpStdioTransport = class
  private
    FOnMessage: TProc<IMcpMessage>;
    FRunning: Boolean;
    procedure ReadLoop;
  public
    constructor Create(AOnMessage: TProc<IMcpMessage>);
    procedure Start;
    procedure Stop;
    procedure SendMessage(const AMessage: IMcpMessage);
    property Running: Boolean read FRunning;
  end;

implementation

{ TMcpStdioTransport }

constructor TMcpStdioTransport.Create(AOnMessage: TProc<IMcpMessage>);
begin
  inherited Create;
  FOnMessage := AOnMessage;
  FRunning := False;
end;

procedure TMcpStdioTransport.SendMessage(const AMessage: IMcpMessage);
var
  LJSON: string;
begin
  LJSON := AMessage.ToJSON.ToJSON;
  WriteLn(LJSON);
  Flush(Output);
end;

procedure TMcpStdioTransport.Start;
begin
  FRunning := True;
  TThread.CreateAnonymousThread(ReadLoop).Start;
end;

procedure TMcpStdioTransport.Stop;
begin
  FRunning := False;
end;

procedure TMcpStdioTransport.ReadLoop;
var
  LLine: string;
  LMessage: IMcpMessage;
begin
  while FRunning do
  begin
    if not EOF(Input) then
    begin
      ReadLn(LLine);
      if LLine <> '' then
      begin
        LMessage := TMcpParser.ParseMessage(LLine);
        if (LMessage <> nil) and Assigned(FOnMessage) then
          FOnMessage(LMessage);
      end;
    end
    else
      Sleep(10);
  end;
end;

end.
