unit MCP.SSEParser;
{SSE:Server-Sent Events}
{Author:Simpower}
{Date:2026-03-14}
{Version:1.0}
{Description:This unit provides a simple way to parse Server-Sent Events (SSE) data.}

interface

uses
  System.SysUtils, System.Classes, System.JSON, DateUtils, System.TimeSpan;

type
  TSSEMessageEvent = reference to procedure(Sender: TObject; const Event, Data, ID: string);

  TSSEParser = class(TObject)
  private
    FBuffer: string;
    FCurrentEvent: string;
    FCurrentData: string;
    FCurrentID: string;
    FOnMessage: TSSEMessageEvent;
    procedure ParseLine(const Line: string);
    procedure DispatchMessage;
  public
    constructor Create;
    procedure Feed(const Data: TBytes);
    procedure Clear;
    property OnMessage: TSSEMessageEvent read FOnMessage write FOnMessage;
    
    // Quick helpers
    class function ParseData(const ARawSSE: string): string; static;
    class function ParseAIContent(const ARawSSE: string): string; static;
    class function OpenAIToOllama(const AOpenAIJson: string): string; static;
    class procedure GetLastUserMessage(const JsonText: string; out LastUser, LastTool: string); static;
    procedure FeedString(const S: string);
  end;

implementation

{ TSSEParser }

constructor TSSEParser.Create;
begin
  inherited Create;
  Clear;
end;

procedure TSSEParser.Clear;
begin
  FBuffer := '';
  FCurrentEvent := '';
  FCurrentData := '';
  FCurrentID := '';
end;

procedure TSSEParser.Feed(const Data: TBytes);
begin
  if Length(Data) = 0 then Exit;
  FeedString(TEncoding.UTF8.GetString(Data));
end;

procedure TSSEParser.FeedString(const S: string);
var
  Line: string;
  P: Integer;
begin
  if S = '' then Exit;
  
  FBuffer := FBuffer + S;

  // Process lines
  while True do
  begin
    P := Pos(#10, FBuffer);
    if P = 0 then Break;

    Line := Copy(FBuffer, 1, P - 1);
    Delete(FBuffer, 1, P);
    
    // Trim CR if present (\r\n)
    if (Line <> '') and (Line[Length(Line)] = #13) then
      Delete(Line, Length(Line), 1);

    if Line = '' then
    begin
      // Message boundary (\n\n)
      DispatchMessage;
    end
    else
    begin
      ParseLine(Line);
    end;
  end;
end;

//获取最后一条continue.dev发送的json中的role:user的content，即用户输入消息
class procedure TSSEParser.GetLastUserMessage(const JsonText: string; out LastUser, LastTool: string);
var
  Root: TJSONObject;
  Messages: TJSONArray;
  Msg: TJSONObject;
  i: Integer;
begin
  LastUser := '';
  LastTool := '';
  Root := TJSONObject.ParseJSONValue(JsonText) as TJSONObject;
  if not Assigned(Root) then
    Exit;

  try
    if Root.TryGetValue<TJSONArray>('messages', Messages) then
    begin
      for i := Messages.Count - 1 downto 0 do
      begin
        Msg := Messages.Items[i] as TJSONObject;
        if Assigned(Msg) and (Msg.GetValue<string>('role') = 'user') then
        begin
          if not Msg.TryGetValue<string>('content', LastUser) then
            Continue;
        end;
        if Assigned(Msg) and (Msg.GetValue<string>('role') = 'tool') then
        begin
          Msg.TryGetValue<string>('content', Lasttool);
        end;
        if (LastUser <> '') then
          Break;
      end;
    end;
  finally
    Root.Free;
  end;
end;

class function TSSEParser.ParseData(const ARawSSE: string): string;
var
  Parser: TSSEParser;
  CombinedData: string;
begin
  Result := '';
  CombinedData := '';
  
  Parser := TSSEParser.Create;
  try
    Parser.OnMessage := procedure(Sender: TObject; const Event, Data, ID: string)
    begin
      // Standard SSE specifies multiple 'data' lines should be joined with newline
      if (Data <> '') and (Data <> '[DONE]') then
      begin
        if CombinedData <> '' then CombinedData := CombinedData + #10;
        CombinedData := CombinedData + Data;
      end;
    end;
    
    Parser.FeedString(ARawSSE);
    if (Parser.FCurrentData <> '') or (Parser.FCurrentEvent <> '') then
      Parser.DispatchMessage;
      
    Result := CombinedData;
  finally
    Parser.Free;
  end;
end;

class function TSSEParser.ParseAIContent(const ARawSSE: string): string;
var
  Parser: TSSEParser;
  FullContent: string;
begin
  Result := '';
  FullContent := '';
  
  Parser := TSSEParser.Create;
  try
    Parser.OnMessage := procedure(Sender: TObject; const Event, Data, ID: string)
    var
      JSON, ItemObj, MessageObj, ContentObj, DeltaObj: TJSONObject;
      ItemsArr, PartsArr, PatchArr: TJSONArray;
      V, ChildV: TJSONValue;
      S: string;
      I: Integer;
    begin
      if (Data = '') or (Data = '[DONE]') then Exit;
      
      V := TJSONObject.ParseJSONValue(Data);
      if not Assigned(V) then Exit;
      try
        if not (V is TJSONObject) then Exit;
        JSON := TJSONObject(V);

        // --- PATTERN 1: Standard OpenAI/DeepSeek (choices[0].delta.content) ---
        if JSON.TryGetValue('choices', ItemsArr) and (ItemsArr.Count > 0) then
        begin
          ItemObj := ItemsArr.Items[0] as TJSONObject;
          if ItemObj.TryGetValue('delta', DeltaObj) then
          begin
            if DeltaObj.TryGetValue('content', S) then
              FullContent := FullContent + S;
          end
          else if ItemObj.TryGetValue('text', S) then 
            FullContent := FullContent + S;
        end
        // --- PATTERN 2: ChatGPT Web Patch (o: patch, v: [{p: '/message/...', v: 'text'}]) ---
        else if JSON.TryGetValue('v', ChildV) then
        begin
          if ChildV is TJSONArray then
          begin
            PatchArr := TJSONArray(ChildV);
            for I := 0 to PatchArr.Count - 1 do
            begin
              ItemObj := PatchArr.Items[I] as TJSONObject;
              if (ItemObj.Values['o'].Value = 'append') and 
                 (Pos('parts/0', ItemObj.Values['p'].Value) > 0) then
              begin
                FullContent := FullContent + ItemObj.Values['v'].Value;
              end;
            end;
          end
          // --- PATTERN 3: ChatGPT Web Message Start (v: {message: {content: {parts: [...]}}}) ---
          else if ChildV is TJSONObject then
          begin
            if TJSONObject(ChildV).TryGetValue('message', MessageObj) then
            begin
              if MessageObj.TryGetValue('content', ContentObj) then
              begin
                if ContentObj.TryGetValue('parts', PartsArr) and (PartsArr.Count > 0) then
                begin
                   S := PartsArr.Items[0].Value;
                   // Just following user sample logic
                end;
              end;
            end;
          end;
        end
        // --- PATTERN 4: Simple Fallbacks (Anthropic/Ollama) ---
        else if JSON.TryGetValue('content', S) then
          FullContent := FullContent + S
        else if JSON.TryGetValue('response', S) then
          FullContent := FullContent + S;
          
      finally
        V.Free;
      end;
    end;
    
    Parser.FeedString(ARawSSE);
    if (Parser.FCurrentData <> '') or (Parser.FCurrentEvent <> '') then
      Parser.DispatchMessage;
      
    Result := FullContent;
  finally
    Parser.Free;
  end;
end;

class function TSSEParser.OpenAIToOllama(const AOpenAIJson: string): string;
var
  Lines: TArray<string>;
  Line, CleanLine, Content, ModelName, S, ISOTime: string;
  V, TempV, ValV: TJSONValue;
  Arr: TJSONArray;
  Item, Delta, OllamaObj, MsgObj, OpenAIObj: TJSONObject;
  I: Integer;
  IsDone: Boolean;
  ResList: TStringList;
begin
  Result := '';
  if AOpenAIJson.Trim.IsEmpty then Exit;

  ResList := TStringList.Create;
  try
    Lines := AOpenAIJson.Split([#10]);
    for Line in Lines do
    begin
      CleanLine := Line.Trim;
      if CleanLine.IsEmpty or (CleanLine = ':') or CleanLine.StartsWith('event:') then Continue;

      // Strip SSE prefix
      if CleanLine.StartsWith('data:') then
        CleanLine := Copy(CleanLine, 6, MaxInt).Trim;

      // Handle termination
      if (CleanLine = '[DONE]') then
      begin
        ISOTime := FormatDateTime('yyyy-mm-dd"T"HH:nn:ss.zzz', TTimeZone.Local.ToUniversalTime(Now)) + '000000Z';
        ResList.Add('{"model":"gpt-5","created_at":"' + ISOTime + '","message":{"role":"assistant","content":""},"done":true}');
        Continue;
      end;

      V := TJSONObject.ParseJSONValue(CleanLine);
      if not Assigned(V) then Continue;
      
      try
        if not (V is TJSONObject) then Continue;
        OpenAIObj := TJSONObject(V);
        
        IsDone := False;
        Content := '';
        ModelName := 'gpt-5';
        OpenAIObj.TryGetValue('model', ModelName);

        if OpenAIObj.TryGetValue('choices', Arr) and (Arr.Count > 0) then
        begin
          Item := Arr.Items[0] as TJSONObject;
          if Item.TryGetValue('delta', Delta) then
          begin
            if Delta.TryGetValue('content', S) then Content := S;
          end
          else if Item.TryGetValue('text', S) then Content := S;
          
          if Item.TryGetValue('finish_reason', S) and (S <> '') and (S <> 'null') then
            IsDone := True;
        end
        else if OpenAIObj.TryGetValue('v', TempV) then
        begin
          if TempV is TJSONArray then
          begin
            for I := 0 to TJSONArray(TempV).Count - 1 do
            begin
              Item := TJSONArray(TempV).Items[I] as TJSONObject;
              if Assigned(Item.Values['o']) and (Item.Values['o'].Value = 'append') and 
                 Assigned(Item.Values['p']) and (Pos('parts/0', Item.Values['p'].Value) > 0) then
              begin
                if Item.TryGetValue('v', ValV) then Content := Content + ValV.Value;
              end
              else if Assigned(Item.Values['p']) and (Item.Values['p'].Value = '/status') and
                      Assigned(Item.Values['v']) and (Item.Values['v'].Value = 'finished_successfully') then
                IsDone := True;
            end;
          end
          else if TempV is TJSONObject then
          begin
            if TJSONObject(TempV).TryGetValue('message', Delta) then 
            begin
              if Delta.TryGetValue('content', Item) then 
              begin
                if Item.TryGetValue('parts', Arr) and (Arr.Count > 0) then
                  Content := Arr.Items[0].Value;
              end;
            end;
          end;
        end
        else if OpenAIObj.TryGetValue('type', S) then
        begin
          if (S = 'message_stream_complete') or (S = 'conversation_detail_metadata') then IsDone := True;
        end
        else if OpenAIObj.TryGetValue('content', S) then Content := S;

        if (Content = '') and (not IsDone) then Continue;

        OllamaObj := TJSONObject.Create;
        try
          OllamaObj.AddPair('model', ModelName);
          ISOTime := FormatDateTime('yyyy-mm-dd"T"HH:nn:ss.zzz', TTimeZone.Local.ToUniversalTime(Now)) + '000000Z';
          OllamaObj.AddPair('created_at', ISOTime);
          
          MsgObj := TJSONObject.Create;
          MsgObj.AddPair('role', 'assistant');
          MsgObj.AddPair('content', Content);
          OllamaObj.AddPair('message', MsgObj);
          OllamaObj.AddPair('done', TJSONBool.Create(IsDone)); 
          
          ResList.Add(OllamaObj.ToJSON);
        finally
          OllamaObj.Free;
        end;
      finally
        V.Free;
      end;
    end;
    
    Result := ResList.Text.Trim; 
  finally
    ResList.Free;
  end;
end;

procedure TSSEParser.ParseLine(const Line: string);
var
  Key, Value: string;
  P: Integer;
begin
  if (Line = '') or (Line[1] = ':') then Exit;

  P := Pos(':', Line);
  if P > 0 then
  begin
    Key := Copy(Line, 1, P - 1).Trim.ToLower;
    Value := Copy(Line, P + 1, MaxInt);
    if (Value <> '') and (Value[1] = ' ') then
      Delete(Value, 1, 1);

    if Key = 'data' then
    begin
      if FCurrentData <> '' then
        FCurrentData := FCurrentData + #10;
      FCurrentData := FCurrentData + Value;
    end
    else if Key = 'event' then
      FCurrentEvent := Value
    else if Key = 'id' then
      FCurrentID := Value;
  end;
end;

procedure TSSEParser.DispatchMessage;
begin
  if (FCurrentData = '') and (FCurrentEvent = '') then Exit;

  if Assigned(FOnMessage) then
    FOnMessage(Self, FCurrentEvent, FCurrentData, FCurrentID);

  FCurrentData := '';
  FCurrentEvent := '';
end;

end.
