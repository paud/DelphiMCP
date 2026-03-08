program ToolTests;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.JSON,
  MCP.Server in '..\src\MCP.Server.pas',
  MCP.Types in '..\src\MCP.Types.pas',
  MCP.Tools in '..\src\tools\MCP.Tools.pas';

procedure TestToolRegistration;
var
  LServer: TMcpServer;
  LTool: TMcpTool;
begin
  Writeln('Testing Tool Registration...');
  LServer := TMcpServer.Create;
  try
    LTool.Name := 'test_tool';
    LTool.Description := 'A test tool';
    LTool.InputSchema := TJSONObject.Create;
    
    LServer.RegisterTool(LTool, 
      function(const AArgs: TJSONObject): TJSONObject
      begin
        Result := TJSONObject.Create.AddPair('status', 'ok');
      end
    );
    Writeln('  Registration: OK');
  finally
    LServer.Free;
  end;
end;

begin
  try
    TestToolRegistration;
    Writeln('Tool tests completed.');
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
  Readln;
end.
