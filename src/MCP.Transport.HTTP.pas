unit MCP.Transport.HTTP;

interface

uses
  System.Classes, System.SysUtils, System.JSON, MCP.Types, MCP.JSONRPC;

type
  TMcpHttpTransport = class(TInterfacedObject)
  private
    FOnMessage: TProc<IMcpMessage>;
    FEndpoint: string;
  public
    constructor Create(const AEndpoint: string; AOnMessage: TProc<IMcpMessage>);
    procedure SendMessage(const AMessage: IMcpMessage);
    // Placeholder for SSE and HTTP/POST handling
  end;

implementation

{ TMcpHttpTransport }

constructor TMcpHttpTransport.Create(const AEndpoint: string; AOnMessage: TProc<IMcpMessage>);
begin
  inherited Create;
  FEndpoint := AEndpoint;
  FOnMessage := AOnMessage;
end;

procedure TMcpHttpTransport.SendMessage(const AMessage: IMcpMessage);
begin
  // TODO: Implement WinHTTP or NetHTTPClient for SSE and POST
end;

end.
