unit MCP.JSONRPC;

interface

uses
  System.JSON, System.SysUtils, MCP.Types;

type
  TJsonRpcMessage = class(TInterfacedObject, IMcpMessage)
  private
    FId: TJSONValue;
    FMethod: string;
  public
    constructor Create(const AId: TJSONValue; const AMethod: string);
    destructor Destroy; override;
    function GetMessageId: TJSONValue;
    function GetMethod: string;
    function ToJSON: TJSONObject; virtual; abstract;
  end;

  TJsonRpcRequest = class(TJsonRpcMessage)
  private
    FParams: TJSONObject;
  public
    constructor Create(const AId: TJSONValue; const AMethod: string; const AParams: TJSONObject);
    destructor Destroy; override;
    function ToJSON: TJSONObject; override;
    property Params: TJSONObject read FParams;
  end;

  TJsonRpcResponse = class(TJsonRpcMessage)
  private
    FResult: TJSONValue;
    FError: TJSONObject;
  public
    constructor Create(const AId: TJSONValue; const AResult: TJSONValue; const AError: TJSONObject = nil);
    destructor Destroy; override;
    function ToJSON: TJSONObject; override;
    property Result: TJSONValue read FResult;
    property Error: TJSONObject read FError;
  end;

  TJsonRpcNotification = class(TJsonRpcMessage)
  private
    FParams: TJSONObject;
  public
    constructor Create(const AMethod: string; const AParams: TJSONObject);
    destructor Destroy; override;
    function ToJSON: TJSONObject; override;
    property Params: TJSONObject read FParams;
  end;

implementation

{ TJsonRpcMessage }

constructor TJsonRpcMessage.Create(const AId: TJSONValue; const AMethod: string);
begin
  inherited Create;
  if AId <> nil then
    FId := AId.Clone as TJSONValue
  else
    FId := nil;
  FMethod := AMethod;
end;

destructor TJsonRpcMessage.Destroy;
begin
  if FId <> nil then FId.Free;
  inherited;
end;

function TJsonRpcMessage.GetMessageId: TJSONValue;
begin
  Result := FId;
end;

function TJsonRpcMessage.GetMethod: string;
begin
  Result := FMethod;
end;

{ TJsonRpcRequest }

constructor TJsonRpcRequest.Create(const AId: TJSONValue; const AMethod: string; const AParams: TJSONObject);
begin
  inherited Create(AId, AMethod);
  if AParams <> nil then
    FParams := AParams.Clone as TJSONObject
  else
    FParams := nil;
end;

destructor TJsonRpcRequest.Destroy;
begin
  if FParams <> nil then FParams.Free;
  inherited;
end;

function TJsonRpcRequest.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('jsonrpc', '2.0');
  if GetMessageId <> nil then
    Result.AddPair('id', GetMessageId.Clone as TJSONValue);
  Result.AddPair('method', GetMethod);
  if FParams <> nil then
    Result.AddPair('params', FParams.Clone as TJSONObject);
end;

{ TJsonRpcResponse }

constructor TJsonRpcResponse.Create(const AId: TJSONValue; const AResult: TJSONValue; const AError: TJSONObject);
begin
  inherited Create(AId, '');
  if AResult <> nil then
    FResult := AResult.Clone as TJSONValue
  else
    FResult := nil;
  if AError <> nil then
    FError := AError.Clone as TJSONObject
  else
    FError := nil;
end;

destructor TJsonRpcResponse.Destroy;
begin
  if FResult <> nil then FResult.Free;
  if FError <> nil then FError.Free;
  inherited;
end;

function TJsonRpcResponse.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('jsonrpc', '2.0');
  if GetMessageId <> nil then
    Result.AddPair('id', GetMessageId.Clone as TJSONValue);
  if FResult <> nil then
    Result.AddPair('result', FResult.Clone as TJSONValue);
  if FError <> nil then
    Result.AddPair('error', FError.Clone as TJSONObject);
end;

{ TJsonRpcNotification }

constructor TJsonRpcNotification.Create(const AMethod: string; const AParams: TJSONObject);
begin
  inherited Create(nil, AMethod);
  if AParams <> nil then
    FParams := AParams.Clone as TJSONObject
  else
    FParams := nil;
end;

destructor TJsonRpcNotification.Destroy;
begin
  if FParams <> nil then FParams.Free;
  inherited;
end;

function TJsonRpcNotification.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('jsonrpc', '2.0');
  Result.AddPair('method', GetMethod);
  if FParams <> nil then
    Result.AddPair('params', FParams.Clone as TJSONObject);
end;

end.
