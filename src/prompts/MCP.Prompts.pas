unit MCP.Prompts;

interface

uses
  System.Classes, System.SysUtils, System.JSON, System.Generics.Collections, MCP.Types;

type
  TMcpPromptManager = class
  private
    FPrompts: TList<TMcpPrompt>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure RegisterPrompt(const APrompt: TMcpPrompt);
    function ListPrompts: TJSONArray;
  end;

implementation

{ TMcpPromptManager }

constructor TMcpPromptManager.Create;
begin
  inherited Create;
  FPrompts := TList<TMcpPrompt>.Create;
end;

destructor TMcpPromptManager.Destroy;
begin
  FPrompts.Free;
  inherited;
end;

procedure TMcpPromptManager.RegisterPrompt(const APrompt: TMcpPrompt);
begin
  FPrompts.Add(APrompt);
end;

function TMcpPromptManager.ListPrompts: TJSONArray;
var
  LPrompt: TMcpPrompt;
  LObj: TJSONObject;
begin
  Result := TJSONArray.Create;
  for LPrompt in FPrompts do
  begin
    LObj := TJSONObject.Create;
    LObj.AddPair('name', LPrompt.Name);
    LObj.AddPair('description', LPrompt.Description);
    if LPrompt.Arguments <> nil then
      LObj.AddPair('arguments', LPrompt.Arguments.Clone as TJSONArray);
    Result.Add(LObj);
  end;
end;

end.
