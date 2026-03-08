unit MCP.Log;

interface

uses
  System.SysUtils, MCP.Types;

type
  TMcpLog = class
  public
    class procedure Log(const ALevel: TMcpLogLevel; const AMessage: string);
  end;

implementation

{ TMcpLog }

class procedure TMcpLog.Log(const ALevel: TMcpLogLevel; const AMessage: string);
var
  LPrefix: string;
begin
  case ALevel of
    Debug: LPrefix := '[DEBUG] ';
    Info: LPrefix := '[INFO]  ';
    Warning: LPrefix := '[WARN]  ';
    Error: LPrefix := '[ERROR] ';
    Critical: LPrefix := '[CRIT]  ';
  else
    LPrefix := '[LOG]   ';
  end;
  Writeln(ErrOutput, LPrefix + AMessage);
end;

end.
