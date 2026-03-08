unit MCP.Parser;

interface

uses
  System.JSON, System.SysUtils, MCP.Types, MCP.JSONRPC;

type
  TMcpParser = class
  public
    class function ParseMessage(const AJson: string): IMcpMessage;
  end;

implementation

{ TMcpParser }

class function TMcpParser.ParseMessage(const AJson: string): IMcpMessage;
var
  LJSON: TJSONObject;
  LId: TJSONValue;
  LMethod: string;
  LParams: TJSONObject;
  LResult: TJSONValue;
  LError: TJSONObject;
begin
  Result := nil;
  LJSON := TJSONObject.ParseJSONValue(AJson) as TJSONObject;
  if LJSON = nil then
    exit;

  try
    LId := LJSON.GetValue('id');
    if LJSON.TryGetValue('method', LMethod) then
    begin
      // Request or Notification
      LParams := LJSON.GetValue('params') as TJSONObject;
      if LId <> nil then
        Result := TJsonRpcRequest.Create(LId, LMethod, LParams)
      else
        Result := TJsonRpcNotification.Create(LMethod, LParams);
    end
    else if (LId <> nil) and (LJSON.TryGetValue('result', LResult) or LJSON.TryGetValue('error', LError)) then
    begin
      // Response
      Result := TJsonRpcResponse.Create(LId, LResult, LError);
    end;
  finally
    LJSON.Free;
  end;
end;

end.
