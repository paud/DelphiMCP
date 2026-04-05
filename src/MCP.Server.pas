unit MCP.Server;

interface

uses
  System.Classes, System.SysUtils, System.JSON, System.Generics.Collections,
  MCP.Types, MCP.JSONRPC, MCP.Transport.Stdio, MCP.Tools, MCP.Resources, MCP.Prompts;

type
  TMcpServer = class
  private
    FTransport: TMcpStdioTransport;
    FTools: TObjectList<TMcpToolEntry>;
    FResourceManager: TMcpResourceManager;
    FPromptManager: TMcpPromptManager;
    FInitialized: Boolean;
    procedure HandleMessage(const AMessage: IMcpMessage);
    procedure HandleRequest(const ARequest: TJsonRpcRequest);
    procedure SendResponse(const AId: TJSONValue; const AResult: TJSONValue);   //we also need a fn point to custom sendResponse
    procedure SendError(const AId: TJSONValue; ACode: Integer; const AMessage: string);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Start;
    procedure Stop;
    procedure RegisterTool(const ATool: TMcpTool; AExecute: TToolExecuteFunc);
    function GetToolsAsJson: TJSONArray;
    function ListToolsAsJson: TJSONArray;
    function ExecuteTool(const AName: string;const AArgs: TJSONObject;const ARequestId: TJSONValue;var sync:Boolean): TJSONObject;
    property ResourceManager: TMcpResourceManager read FResourceManager;
    property PromptManager: TMcpPromptManager read FPromptManager;
  end;

implementation

{ TMcpServer }

constructor TMcpServer.Create;
begin
  inherited Create;
  FTools := TObjectList<TMcpToolEntry>.Create;
  FResourceManager := TMcpResourceManager.Create;
  FPromptManager := TMcpPromptManager.Create;
  FTransport := TMcpStdioTransport.Create(
    procedure(AMsg: IMcpMessage)
    begin
      HandleMessage(AMsg);
    end);
  FInitialized := False;
end;

destructor TMcpServer.Destroy;
begin
  FTools.Free;
  FResourceManager.Free;
  FPromptManager.Free;
  FTransport.Free;
  inherited;
end;

procedure TMcpServer.RegisterTool(const ATool: TMcpTool; AExecute: TToolExecuteFunc);
begin
  FTools.Add(TMcpToolEntry.Create(ATool, AExecute));
end;

procedure TMcpServer.Start;
begin
  FTransport.Start;
end;

procedure TMcpServer.Stop;
begin
  FTransport.Stop;
end;

procedure TMcpServer.HandleMessage(const AMessage: IMcpMessage);
begin
  if AMessage is TJsonRpcRequest then
    HandleRequest(AMessage as TJsonRpcRequest);
end;

procedure TMcpServer.HandleRequest(const ARequest: TJsonRpcRequest);
var
  LMethod: string;
  LResult: TJSONValue;
  LTool: TMcpToolEntry;
  LToolObj: TJSONObject;
  LToolsArr: TJSONArray;
  LArgs: TJSONObject;
  LToolName: string;
begin
  LMethod := ARequest.GetMethod;

  if LMethod = 'initialize' then
  begin
    FInitialized := True;
    LResult := TJSONObject.Create;
    TJSONObject(LResult).AddPair('protocolVersion', '2024-11-05');
    TJSONObject(LResult).AddPair('capabilities', TJSONObject.Create);
    TJSONObject(LResult).AddPair('serverInfo', TJSONObject.Create.AddPair('name', 'DelphiMCP').AddPair('version', '0.1.0'));
    SendResponse(ARequest.GetMessageId, LResult);
    exit;
  end;

  if not FInitialized then
  begin
    SendError(ARequest.GetMessageId, -32002, 'Not initialized');
    exit;
  end;

  if LMethod = 'tools/list' then
  begin
    LResult := TJSONObject.Create.AddPair('tools', ListToolsAsJson);
    SendResponse(ARequest.GetMessageId, LResult);
  end
  else if LMethod = 'tools/call' then
  begin
    LToolName :=
      ARequest.Params.GetValue('name').Value;

    LArgs :=
      ARequest.Params.GetValue('arguments')
        as TJSONObject;

    var LSync: Boolean;
    var LId: TJSONValue;

    for LTool in FTools do
      if LTool.Info.Name = LToolName then
      begin
        // 必须 Clone（极重要）
        LId := ARequest.GetMessageId.Clone as TJSONObject;

        // 调用 Tool
        LResult :=
          LTool.Execute(
            LArgs,
            LId,
            Self,
            LSync
          );

        // 如果是同步 → 立即返回
        if LSync then
        begin
          SendResponse(
            ARequest.GetMessageId,
            LResult
          );
        end;

        exit;
      end;

    SendError(ARequest.GetMessageId,-32601,'Tool not found');
  end
  else if LMethod = 'resources/list' then
  begin
    SendResponse(ARequest.GetMessageId, TJSONObject.Create.AddPair('resources', FResourceManager.ListResources));
  end
  else if LMethod = 'prompts/list' then
  begin
    SendResponse(ARequest.GetMessageId, TJSONObject.Create.AddPair('prompts', FPromptManager.ListPrompts));
  end;
end;

function TMcpServer.ListToolsAsJson: TJSONArray;
var
  LTool: TMcpToolEntry;
  LToolObj: TJSONObject;
begin
  Result := TJSONArray.Create;
  for LTool in FTools do
  begin
    LToolObj := TJSONObject.Create;
    LToolObj.AddPair('name', LTool.Info.Name);
    LToolObj.AddPair('description', LTool.Info.Description);
    LToolObj.AddPair('inputSchema', LTool.Info.InputSchema.Clone as TJSONObject);
    Result.Add(LToolObj);
  end;
end;

function TMcpServer.GetToolsAsJson: TJSONArray;
var
  LTool: TMcpToolEntry;
  LToolObj: TJSONObject;
  LFuncObj: TJSONObject;
begin
  Result := TJSONArray.Create;
  for LTool in FTools do
  begin
    LToolObj := TJSONObject.Create;
    LToolObj.AddPair('type', 'function');

    LFuncObj := TJSONObject.Create;
    LFuncObj.AddPair('parameters', LTool.Info.InputSchema.Clone as TJSONObject);
    LFuncObj.AddPair('name', LTool.Info.Name);
    LFuncObj.AddPair('description', LTool.Info.Description);

    LToolObj.AddPair('function', LFuncObj);
    Result.Add(LToolObj);
  end;
end;

function TMcpServer.ExecuteTool(const AName: string;const AArgs: TJSONObject;const ARequestId: TJSONValue;var sync:Boolean): TJSONObject;
var
  LTool: TMcpToolEntry;
  LCleanName: string;
  LPos: Integer;
begin
  LCleanName := AName;

  LPos := Pos(':', AName);

  if LPos > 0 then
    LCleanName := Copy(
      AName,
      LPos + 1,
      Length(AName) - LPos
    );

  Result := nil;
  sync := True;

  for LTool in FTools do
    if (LTool.Info.Name = AName)
    or (LTool.Info.Name = LCleanName) then
    begin
      Result := LTool.Execute(
        AArgs,
        ARequestId,
        Self,
        sync
      );
      if sync and Assigned(Result) then
      begin //if sync, assemble the result completely, or do it in customer caller
        Result.AddPair('name',LTool.Info.Name).AddPair('role', 'tool')
          .AddPair('tool_call_id',ARequestId.Value);
      end;
      exit;
    end;
end;

procedure TMcpServer.SendResponse(const AId: TJSONValue; const AResult: TJSONValue);
var
  LResponse: TJsonRpcResponse;
begin
  LResponse := TJsonRpcResponse.Create(AId, AResult);
  try
    FTransport.SendMessage(LResponse);
  finally
    LResponse.Free;
  end;
end;

procedure TMcpServer.SendError(const AId: TJSONValue; ACode: Integer; const AMessage: string);
var
  LError: TJSONObject;
  LResponse: TJsonRpcResponse;
begin
  LError := TJSONObject.Create;
  LError.AddPair('code', TJSONNumber.Create(ACode));
  LError.AddPair('message', AMessage);
  LResponse := TJsonRpcResponse.Create(AId, nil, LError);
  try
    FTransport.SendMessage(LResponse);
  finally
    LResponse.Free;
  end;
end;

end.
