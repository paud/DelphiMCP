unit MCP.Resources;

interface

uses
  System.Classes, System.SysUtils, System.JSON, MCP.Types;

type
  TMcpResourceManager = class
  private
    FResources: TList<TMcpResource>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure RegisterResource(const AResource: TMcpResource);
    function ListResources: TJSONArray;
  end;

implementation

{ TMcpResourceManager }

constructor TMcpResourceManager.Create;
begin
  inherited Create;
  FResources := TList<TMcpResource>.Create;
end;

destructor TMcpResourceManager.Destroy;
begin
  FResources.Free;
  inherited;
end;

procedure TMcpResourceManager.RegisterResource(const AResource: TMcpResource);
begin
  FResources.Add(AResource);
end;

function TMcpResourceManager.ListResources: TJSONArray;
var
  LRes: TMcpResource;
  LObj: TJSONObject;
begin
  Result := TJSONArray.Create;
  for LRes in FResources do
  begin
    LObj := TJSONObject.Create;
    LObj.AddPair('uri', LRes.Uri);
    LObj.AddPair('name', LRes.Name);
    LObj.AddPair('description', LRes.Description);
    LObj.AddPair('mimeType', LRes.MimeType);
    Result.Add(LObj);
  end;
end;

end.
