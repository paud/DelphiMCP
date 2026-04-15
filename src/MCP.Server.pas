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
    function ExecuteTool(const AName: string;const AArgs: TJSONObject;const ARequestId: TJSONValue): TJSONObject;
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
var
  i: Int64;
begin
  for i := FTools.Count-1 downto 0 do
  begin
    FTools.Items[i].Info.InputSchema.Free;
  end;
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
    TJSONObject(LResult).AddPair('protocolVersion', '2026-04-15');
    // --- add resources ability ---
    var LCapabilities := TJSONObject.Create;
    LCapabilities.AddPair('resources', TJSONObject.Create); // 声明支持资源列表和读取
    TJSONObject(LResult).AddPair('capabilities', LCapabilities);
    // --------------------------------------
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
            Self
          );
        LId.Free;
        Exit;
      end;

    SendError(ARequest.GetMessageId,-32601,'Tool not found');
  end
  else if LMethod = 'resources/list' then
  begin
    SendResponse(ARequest.GetMessageId, TJSONObject.Create.AddPair('resources', FResourceManager.ListResources));
  end
  else if LMethod = 'resources/read' then
  begin
    var LUri := ARequest.Params.GetValue('uri').Value;
    var LContents := FResourceManager.ReadResource(LUri); // 调用刚才写的函数

    if LContents <> nil then
      SendResponse(ARequest.GetMessageId, TJSONObject.Create.AddPair('contents', LContents))
    else
      SendError(ARequest.GetMessageId, -32602, 'Resource not found');
  end
  else if LMethod = 'prompts/list' then  begin
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
  // 2. 关键步骤：手动添加 read_resource 工具，让模型有能力读取资源
  LToolObj := TJSONObject.Create;
  LToolObj.AddPair('type', 'function');

  LFuncObj := TJSONObject.Create;
  LFuncObj.AddPair('name', 'read_resource');
  LFuncObj.AddPair('description', 'Read the content of a specific resource by its URI. Use this to get API definitions or documentation.');

  // 定义参数 Schema: { uri: string }
  var LParams := TJSONObject.Create;
  LParams.AddPair('type', 'object');
  var LProps := TJSONObject.Create;
  var LUri := TJSONObject.Create;
  LUri.AddPair('type', 'string');
  LUri.AddPair('description', 'The URI of the resource to read (e.g., spcom://api/definitions)');
  LProps.AddPair('uri', LUri);
  LParams.AddPair('properties', LProps);

  var LReq := TJSONArray.Create;
  LReq.Add('uri');
  LParams.AddPair('required', LReq);

  LFuncObj.AddPair('parameters', LParams);
  LToolObj.AddPair('function', LFuncObj);

  Result.Add(LToolObj);
end;

function TMcpServer.ExecuteTool(const AName: string;const AArgs: TJSONObject;const ARequestId: TJSONValue): TJSONObject;
var
  LTool: TMcpToolEntry;
  LCleanName: string;
  LPos: Integer;
  LUri: string;
  LContents: TJSONArray;
begin
  Result := nil;
  LCleanName := AName;

  LPos := Pos(':', AName);

  if LPos > 0 then
    LCleanName := Copy(
      AName,
      LPos + 1,
      Length(AName) - LPos
    );

  // --- 核心改动：拦截 read_resource 调用 ---
  if (LCleanName = 'read_resource') then
  begin
    if AArgs.TryGetValue('uri', LUri) then
    begin
      // 从资源管理器读取内容
      LContents := FResourceManager.ReadResource(LUri);

      if Assigned(LContents) then
      begin
        // 构造返回给模型的格式：{ "content": [ { "uri": "...", "text": "..." } ] }
        Result := TJSONObject.Create;
        Result.AddPair('content', LContents);
        Exit; // 成功处理，直接退出
      end;
    end;
  end;

  for LTool in FTools do
    if (LTool.Info.Name = AName)
    or (LTool.Info.Name = LCleanName) then
    begin
      Result := LTool.Execute(
        AArgs,
        ARequestId,
        Self
      );
      Exit;
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
