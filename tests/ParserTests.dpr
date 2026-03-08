program McpTests;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.JSON,
  MCP.Parser in '..\src\MCP.Parser.pas',
  MCP.JSONRPC in '..\src\MCP.JSONRPC.pas',
  MCP.Types in '..\src\MCP.Types.pas';

procedure TestParser;
var
  LMsg: IMcpMessage;
begin
  Writeln('Testing Parser...');
  
  // Test Request
  LMsg := TMcpParser.ParseMessage('{"jsonrpc": "2.0", "id": 1, "method": "test", "params": {}}');
  if (LMsg <> nil) and (LMsg.GetMethod = 'test') then
    Writeln('  Request Parse: OK')
  else
    Writeln('  Request Parse: FAILED');

  // Test Response
  LMsg := TMcpParser.ParseMessage('{"jsonrpc": "2.0", "id": 1, "result": "ok"}');
  if (LMsg <> nil) and (LMsg is TJsonRpcResponse) then
    Writeln('  Response Parse: OK')
  else
    Writeln('  Response Parse: FAILED');
end;

begin
  try
    TestParser;
    Writeln('All tests completed.');
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
  Readln;
end.
