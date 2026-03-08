unit MCP.JSONUtils;

interface

uses
  System.JSON, System.SysUtils;

function JsonObject(const APairs: array of string; const AValues: array of TJSONValue): TJSONObject;
function JsonArray(const AValues: array of TJSONValue): TJSONArray;

implementation

function JsonObject(const APairs: array of string; const AValues: array of TJSONValue): TJSONObject;
var
  i: Integer;
begin
  Result := TJSONObject.Create;
  for i := 0 to High(APairs) do
    Result.AddPair(APairs[i], AValues[i]);
end;

function JsonArray(const AValues: array of TJSONValue): TJSONArray;
var
  i: Integer;
begin
  Result := TJSONArray.Create;
  for i := 0 to High(AValues) do
    Result.Add(AValues[i]);
end;

end.
