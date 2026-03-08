program JsonRpcTests;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.JSON,
  MCP.JSONRPC in '..\src\MCP.JSONRPC.pas',
  MCP.Types in '..\src\MCP.Types.pas';

procedure TestJsonRpcCreation;
var
  LReq: TJsonRpcRequest;
  LJSON: TJSONObject;
begin
  Writeln('Testing JSON-RPC Message Creation...');
  
  LReq := TJsonRpcRequest.Create(TJSONNumber.Create(1), 'test', TJSONObject.Create);
  try
    LJSON := LReq.ToJSON;
    try
      if LJSON.GetValue('method').Value = 'test' then
        Writeln('  Request Creation: OK')
      else
        Writeln('  Request Creation: FAILED');
    finally
      LJSON.Free;
    end;
  finally
    LReq.Free;
  end;
end;

begin
  try
    TestJsonRpcCreation;
    Writeln('JSON-RPC tests completed.');
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
  Readln;
end.
