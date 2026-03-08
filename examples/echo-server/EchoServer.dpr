program EchoServer;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.JSON,
  MCP.Server in '..\..\src\MCP.Server.pas',
  MCP.Types in '..\..\src\MCP.Types.pas',
  MCP.JSONRPC in '..\..\src\MCP.JSONRPC.pas',
  MCP.Parser in '..\..\src\MCP.Parser.pas',
  MCP.Transport.Stdio in '..\..\src\MCP.Transport.Stdio.pas';

var
  LServer: TMcpServer;
  LTool: TMcpTool;
begin
  try
    LServer := TMcpServer.Create;
    try
      LTool.Name := 'echo';
      LTool.Description := 'Echoes back the input';
      LTool.InputSchema := TJSONObject.Create;
      LTool.InputSchema.AddPair('type', 'object');
      LTool.InputSchema.AddPair('properties', TJSONObject.Create.AddPair('message', TJSONObject.Create.AddPair('type', 'string')));
      
      LServer.RegisterTool(LTool, 
        function(const AArgs: TJSONObject): TJSONObject
        var
          LMsg: string;
        begin
          LMsg := AArgs.GetValue('message').Value;
          Result := TJSONObject.Create;
          Result.AddPair('content', TJSONArray.Create(
            TJSONObject.Create.AddPair('type', 'text').AddPair('text', LMsg)
          ));
        end
      );
      
      LServer.Start;
      
      while True do
        Sleep(100);
        
    finally
      LServer.Free;
    end;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
