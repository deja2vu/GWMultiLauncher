unit MutexHelper;

interface
uses
SyncObjs,Generics.Collections;
type
  TRecursiveMutex = class;

  TRecursiveMutex = class
  strict private
    mapMutex: TCriticalSection;
    recursiveMutex: TCriticalSection;
    lockNums: TDictionary<THandle, Integer>;
  public
    constructor Create; overload;
    destructor Destroy; override;
  public
    procedure Enter;
    procedure Leave;
  end;
var
mutex:TRecursiveMutex;
implementation
uses
Windows;
{ TRecursiveMutex }

    constructor TRecursiveMutex.Create;
    begin
      Self.mapMutex := TCriticalSection.Create;
      Self.recursiveMutex := TCriticalSection.Create;
      Self.lockNums := TDictionary<THandle, Integer>.Create;
    end;

    destructor TRecursiveMutex.Destroy;
    begin
      Self.mapMutex.Free;
      Self.recursiveMutex.Free;
      Self.lockNums.Free;
      inherited;
    end;

    procedure TRecursiveMutex.Enter;
    var
      threadID: THandle;
    begin
      mapMutex.Enter;
      threadID := GetCurrentThreadId;
      if lockNums.ContainsKey(threadID) then
      begin
        if lockNums[threadID] = 0 then
        begin
          lockNums[threadID] := 1;
          mapMutex.Leave;
          recursiveMutex.Enter;
        end
        else
        begin
          lockNums[threadID] := lockNums[threadID] + 1;
          mapMutex.Leave;
        end;
      end
      else
      begin
        lockNums.Add(threadID, 1);
        mapMutex.Leave;
        recursiveMutex.Enter;
      end;
    end;

    procedure TRecursiveMutex.Leave;
    var
      threadID: THandle;
    begin
      mapMutex.Enter;
      threadID := GetCurrentThreadId;
      if lockNums.ContainsKey(threadID) then
      begin
        if lockNums[threadID] = 0 then
        begin
          mapMutex.Leave;
          Assert('recursive_mutex lock and unlock Not In Matche');
        end
        else
        begin
          case lockNums[threadID] of
            1:
              begin
                lockNums.Remove(threadID);
                recursiveMutex.Leave;
              end
            else
              lockNums[threadID] := lockNums[threadID] - 1;
          end;
          mapMutex.Leave;
        end;
      end
      else
      begin
        mapMutex.Leave;
        Assert('recursive_mutex lock and unlock Not In Matche');
      end;
    end;

initialization
mutex:=TRecursiveMutex.Create;
finalization
mutex.Free;

end.
