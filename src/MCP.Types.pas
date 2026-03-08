unit MCP.Types;

interface

uses
  System.JSON, System.SysUtils, System.Generics.Collections;

type
  EMcpException = class(Exception);

  TMcpLogLevel = (
    Default = 0,
    Debug = 1,
    Info = 2,
    Notice = 3,
    Warning = 4,
    Error = 5,
    Critical = 6,
    Alert = 7,
    Emergency = 8
  );

  IMcpMessage = interface
    ['{A9A2E70D-6B5F-4E8B-BD3A-1C5C2B4D5E6F}']
    function GetMessageId: TJSONValue;
    function GetMethod: string;
    function ToJSON: TJSONObject;
  end;

  TMcpTool = record
    Name: string;
    Description: string;
    InputSchema: TJSONObject;
  end;

  TMcpResource = record
    Uri: string;
    Name: string;
    Description: string;
    MimeType: string;
  end;

  TMcpPrompt = record
    Name: string;
    Description: string;
    Arguments: TJSONArray;
  end;

implementation

end.
