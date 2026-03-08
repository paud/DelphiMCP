unit MCP;

interface

uses
  MCP.Types, MCP.Server, MCP.Client, MCP.Transport.Stdio;

type
  TMcp = class
  public
    class function CreateServer: TMcpServer;
    class function CreateClient: TMcpClient;
  end;

implementation

{ TMcp }

class function TMcp.CreateClient: TMcpClient;
begin
  Result := TMcpClient.Create;
end;

class function TMcp.CreateServer: TMcpServer;
begin
  Result := TMcpServer.Create;
end;

end.
