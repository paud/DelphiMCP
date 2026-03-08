unit MCP.Streaming;

interface

uses
  System.Classes, System.SysUtils, System.JSON, MCP.Types;

type
  TMcpStreamHandler = class
  private
    FOnChunk: TProc<TJSONValue>;
  public
    constructor Create(AOnChunk: TProc<TJSONValue>);
    procedure HandleStream(const AChunk: TJSONValue);
  end;

implementation

{ TMcpStreamHandler }

constructor TMcpStreamHandler.Create(AOnChunk: TProc<TJSONValue>);
begin
  inherited Create;
  FOnChunk := AOnChunk;
end;

procedure TMcpStreamHandler.HandleStream(const AChunk: TJSONValue);
begin
  if Assigned(FOnChunk) then
    FOnChunk(AChunk);
end;

end.
