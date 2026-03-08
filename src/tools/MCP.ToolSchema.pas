unit MCP.ToolSchema;

interface

uses
  System.JSON, System.SysUtils;

type
  TMcpToolSchema = class
  public
    class function CreateObjectSchema: TJSONObject;
    class function AddProperty(const ASchema: TJSONObject; const AName, AType, ADescription: string): TJSONObject;
  end;

implementation

{ TMcpToolSchema }

class function TMcpToolSchema.CreateObjectSchema: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('type', 'object');
  Result.AddPair('properties', TJSONObject.Create);
  Result.AddPair('required', TJSONArray.Create);
end;

class function TMcpToolSchema.AddProperty(const ASchema: TJSONObject; const AName, AType, ADescription: string): TJSONObject;
var
  LProps: TJSONObject;
  LProp: TJSONObject;
begin
  LProps := ASchema.GetValue('properties') as TJSONObject;
  LProp := TJSONObject.Create;
  LProp.AddPair('type', AType);
  LProp.AddPair('description', ADescription);
  LProps.AddPair(AName, LProp);
  Result := ASchema;
end;

end.
