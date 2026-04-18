unit MCP.Tools;

interface

uses
  System.Classes, System.SysUtils, System.JSON, MCP.Types;

type
  TToolExecuteFunc =
    reference to function(
      const Args: TJSONObject;
      const RequestId: string;
      const Server: TObject
    ): TJSONObject;

  TMcpToolEntry = class
  private
    FInfo: TMcpTool;
    FExecute: TToolExecuteFunc;
  public
    constructor Create(const AInfo: TMcpTool; const AExecute: TToolExecuteFunc);
    property Info: TMcpTool read FInfo;
    property Execute: TToolExecuteFunc read FExecute;
  end;

implementation

{ TMcpToolEntry }

constructor TMcpToolEntry.Create(const AInfo: TMcpTool; const AExecute: TToolExecuteFunc);
begin
  inherited Create;
  FInfo := AInfo;
  FExecute := AExecute;
end;

end.
