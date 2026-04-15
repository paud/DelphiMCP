unit MCP.Resources;

interface

uses
  System.Classes, System.SysUtils, System.JSON, System.Generics.Collections, MCP.Types;

type
  TMcpResourceManager = class
  private
    FResources: TList<TMcpResource>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure RegisterResource(const AResource: TMcpResource);
    function ListResources: TJSONArray;
    // --- 新增：根据 URI 读取具体内容 ---
    function ReadResource(const AUri: string): TJSONArray;
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

// --- 新增实现 ---
function TMcpResourceManager.ReadResource(const AUri: string): TJSONArray;
var
  LRes: TMcpResource;
  LObj: TJSONObject;
begin
  Result := nil;
  for LRes in FResources do
  begin
    if LRes.Uri = AUri then
    begin
      Result := TJSONArray.Create;
      LObj := TJSONObject.Create;
      LObj.AddPair('uri', LRes.Uri);
      LObj.AddPair('mimeType', LRes.MimeType);
      // 这里放入资源的内容，模型读的就是这个 text 字段
      LObj.AddPair('text', LRes.Content);
      Result.Add(LObj);
      Break;
    end;
  end;
end;

end.
