unit MCP.Client;

interface

uses
  System.Classes, System.SysUtils, System.JSON, System.Generics.Collections,
  MCP.Types, MCP.JSONRPC, MCP.Transport.Stdio;

type
  TMcpClient = class
  private
    FTransport: TMcpStdioTransport;
    FRequestId: Integer;
    FPendingRequests: TDictionary<string, TProc<TJsonRpcResponse>>;
    FInitialized: Boolean;
    procedure HandleMessage(const AMessage: IMcpMessage);
    function NextId: TJSONValue;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Start;
    procedure Stop;
    procedure Initialize(ACallback: TProc<TJsonRpcResponse>);
    procedure CallTool(const AName: string; const AArgs: TJSONObject; ACallback: TProc<TJsonRpcResponse>);
    procedure ListTools(ACallback: TProc<TJsonRpcResponse>);
    procedure ListResources(ACallback: TProc<TJsonRpcResponse>);
    procedure ListPrompts(ACallback: TProc<TJsonRpcResponse>);
  end;

implementation

{ TMcpClient }

constructor TMcpClient.Create;
begin
  inherited Create;
  FRequestId := 0;
  FPendingRequests := TDictionary<string, TProc<TJsonRpcResponse>>.Create;
  FTransport := TMcpStdioTransport.Create(
    procedure(AMsg: IMcpMessage)
    begin
      HandleMessage(AMsg);
    end);
  FInitialized := False;
end;

destructor TMcpClient.Destroy;
begin
  FPendingRequests.Free;
  FTransport.Free;
  inherited;
end;

function TMcpClient.NextId: TJSONValue;
begin
  Inc(FRequestId);
  Result := TJSONNumber.Create(FRequestId);
end;

procedure TMcpClient.Start;
begin
  FTransport.Start;
end;

procedure TMcpClient.Stop;
begin
  FTransport.Stop;
end;

procedure TMcpClient.HandleMessage(const AMessage: IMcpMessage);
var
  LResponse: TJsonRpcResponse;
  LId: string;
  LCallback: TProc<TJsonRpcResponse>;
begin
  if AMessage is TJsonRpcResponse then
  begin
    LResponse := AMessage as TJsonRpcResponse;
    if LResponse.GetMessageId <> nil then
    begin
      LId := LResponse.GetMessageId.Value;
      if FPendingRequests.TryGetValue(LId, LCallback) then
      begin
        FPendingRequests.Remove(LId);
        LCallback(LResponse);
      end;
    end;
  end;
end;

procedure TMcpClient.Initialize(ACallback: TProc<TJsonRpcResponse>);
var
  LId: TJSONValue;
  LParams: TJSONObject;
  LRequest: TJsonRpcRequest;
begin
  LId := NextId;
  LParams := TJSONObject.Create;
  LParams.AddPair('protocolVersion', '2024-11-05');
  LParams.AddPair('capabilities', TJSONObject.Create);
  LParams.AddPair('clientInfo', TJSONObject.Create.AddPair('name', 'DelphiMCP-Client').AddPair('version', '0.1.0'));
  
  LRequest := TJsonRpcRequest.Create(LId, 'initialize', LParams);
  FPendingRequests.Add(LId.Value, 
    procedure(AResponse: TJsonRpcResponse)
    begin
      FInitialized := True;
      ACallback(AResponse);
    end);
  FTransport.SendMessage(LRequest);
end;

procedure TMcpClient.CallTool(const AName: string; const AArgs: TJSONObject; ACallback: TProc<TJsonRpcResponse>);
var
  LId: TJSONValue;
  LParams: TJSONObject;
  LRequest: TJsonRpcRequest;
begin
  LId := NextId;
  LParams := TJSONObject.Create;
  LParams.AddPair('name', AName);
  if AArgs <> nil then
    LParams.AddPair('arguments', AArgs.Clone as TJSONObject)
  else
    LParams.AddPair('arguments', TJSONObject.Create);
  
  LRequest := TJsonRpcRequest.Create(LId, 'tools/call', LParams);
  FPendingRequests.Add(LId.Value, ACallback);
  FTransport.SendMessage(LRequest);
end;

procedure TMcpClient.ListTools(ACallback: TProc<TJsonRpcResponse>);
var
  LId: TJSONValue;
  LRequest: TJsonRpcRequest;
begin
  LId := NextId;
  LRequest := TJsonRpcRequest.Create(LId, 'tools/list', nil);
  FPendingRequests.Add(LId.Value, ACallback);
  FTransport.SendMessage(LRequest);
end;

procedure TMcpClient.ListResources(ACallback: TProc<TJsonRpcResponse>);
var
  LId: TJSONValue;
  LRequest: TJsonRpcRequest;
begin
  LId := NextId;
  LRequest := TJsonRpcRequest.Create(LId, 'resources/list', nil);
  FPendingRequests.Add(LId.Value, ACallback);
  FTransport.SendMessage(LRequest);
end;

procedure TMcpClient.ListPrompts(ACallback: TProc<TJsonRpcResponse>);
var
  LId: TJSONValue;
  LRequest: TJsonRpcRequest;
begin
  LId := NextId;
  LRequest := TJsonRpcRequest.Create(LId, 'prompts/list', nil);
  FPendingRequests.Add(LId.Value, ACallback);
  FTransport.SendMessage(LRequest);
end;

end.
