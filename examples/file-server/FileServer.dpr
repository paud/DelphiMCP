program FileServer;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.JSON,
  System.Classes,
  MCP.Server in '..\..\src\MCP.Server.pas',
  MCP.Types in '..\..\src\MCP.Types.pas',
  MCP.JSONRPC in '..\..\src\MCP.JSONRPC.pas',
  MCP.Parser in '..\..\src\MCP.Parser.pas',
  MCP.Transport.Stdio in '..\..\src\MCP.Transport.Stdio.pas',
  MCP.Tools in '..\..\src\tools\MCP.Tools.pas',
  MCP.Resources in '..\..\src\resources\MCP.Resources.pas';

var
  LServer: TMcpServer;
  LTool: TMcpTool;
  LRes: TMcpResource;
begin
  try
    LServer := TMcpServer.Create;
    try
      // Register a read_file tool
      LTool.Name := 'read_file';
      LTool.Description := 'Reads content of a file';
      LTool.InputSchema := TJSONObject.Create;
      LTool.InputSchema.AddPair('type', 'object');
      LTool.InputSchema.AddPair('properties', TJSONObject.Create.AddPair('path', TJSONObject.Create.AddPair('type', 'string')));
      
      LServer.RegisterTool(LTool, 
        function(const AArgs: TJSONObject): TJSONObject
        var
          LPath: string;
          LContent: TStringList;
        begin
          LPath := AArgs.GetValue('path').Value;
          Result := TJSONObject.Create;
          if FileExists(LPath) then
          begin
            LContent := TStringList.Create;
            try
              LContent.LoadFromFile(LPath);
              Result.AddPair('content', TJSONArray.Create(
                TJSONObject.Create.AddPair('type', 'text').AddPair('text', LContent.Text)
              ));
            finally
              LContent.Free;
            end;
          end
          else
            Result.AddPair('isError', TJSONBool.Create(True)).AddPair('message', 'File not found');
        end
      );

      // Register a resource
      LRes.Uri := 'file://README.md';
      LRes.Name := 'Project README';
      LRes.MimeType := 'text/markdown';
      LServer.ResourceManager.RegisterResource(LRes);
      
      LServer.Start;
      
      while True do
        Sleep(100);
        
    finally
      LServer.Free;
    end;
  except
    on E: Exception do
      Writeln(ErrOutput, E.ClassName, ': ', E.Message);
  end;
end.
