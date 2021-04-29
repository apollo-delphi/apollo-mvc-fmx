unit Apollo_MVC_FMX;

interface

uses
  Apollo_MVC_Core,
  FireDAC.Comp.UI,
  FireDAC.FMXUI.Wait,
  FireDAC.Stan.Intf,
  FireDAC.UI.Intf,
  FMX.Controls,
  FMX.Dialogs,
  FMX.Forms,
  FMX.Graphics,
  FMX.Types,
  System.Classes,
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Variants;

  type
  TControllerFMX = class;

  TViewFMXBase = class abstract(TForm, IViewBase)
    WaitCursor: TFDGUIxWaitCursor;
    procedure FormClose(Sender: TObject; var Action: TCloseAction); virtual;
  private
    FBaseView: IViewBase;
    function GetBaseView: IViewBase;
    property BaseView: IViewBase read GetBaseView implements IViewBase;
  protected
    function EmbedFrame<T: TFrame>(var aFrameKeeper: TFrame; aOwner: TFmxObject): T;
    procedure Recover(const aPropName: string; aValue: string); virtual;
    procedure FireEvent(const aEventName: string);
    procedure Remember(const aPropName: string; const aValue: Variant);
  public
    constructor CreateByController(aViewEventProc: TViewEventProc; aRememberEventProc: TRememberEventProc);
  end;

  TViewFMXMain = class abstract(TViewFMXBase)
  protected
    function SubscribeController: TControllerFMX; virtual; abstract;
  public
    constructor Create(AOwner: TComponent); override;
  end;

  TControllerFMX = class abstract(TControllerAbstract)
  private
    //FRememberList: TStringList;
    function GetRememberFilePath: string;
    //function GetRememberList: TStringList;
    function GetRowKey(const aViewName, aPropName: string): string;
    procedure RecoverRemembers(aView: TViewFMXBase);
    procedure RegisterMainView(aMainView: TViewFMXMain);
    procedure ViewRememberObserver(aView: TObject; const aPropName: string; const aValue: Variant);
  protected
    function CreateView<T: TViewFMXBase, constructor>: T;
    procedure BeforeDestroy; override;
  end;

implementation

{$R *.fmx}

uses
  System.IOUtils,
  System.Rtti;

 { TViewFMXBase }

constructor TViewFMXBase.CreateByController(aViewEventProc: TViewEventProc;
  aRememberEventProc: TRememberEventProc);
begin
  Create(nil);

  BaseView.EventProc := aViewEventProc;
  BaseView.RememberEventProc := aRememberEventProc;
end;

function TViewFMXBase.EmbedFrame<T>(var aFrameKeeper: TFrame;
  aOwner: TFmxObject): T;
begin
  if Assigned(aFrameKeeper) then
    FreeAndNil(aFrameKeeper);

  Result := T.Create(Self);
  Result.Parent := aOwner;
  Result.Align := TAlignLayout.Client;

  aFrameKeeper := Result;
end;

procedure TViewFMXBase.FireEvent(const aEventName: string);
begin
  BaseView.FireEvent(aEventName);
end;

procedure TViewFMXBase.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := TCloseAction.caFree;
  FireEvent('ViewClose');
end;

function TViewFMXBase.GetBaseView: IViewBase;
begin
  if not Assigned(FBaseView) then
    FBaseView := MakeViewBase(Self);
  Result := FBaseView;
end;

procedure TViewFMXBase.Recover(const aPropName: string; aValue: string);
var
  RttiContext: TRttiContext;
  RttiProperty: TRttiProperty;
  RttiType: TRttiType;
  Value: TValue;
begin
  RttiContext := TRttiContext.Create;
  try
    RttiType := RttiContext.GetType(ClassType);
    RttiProperty := RttiType.GetProperty(aPropName);
    if Assigned(RttiProperty) then
    begin
      case RttiProperty.PropertyType.TypeKind of
        tkInteger: Value := TValue.From<Integer>(aValue.ToInteger);
      else
        Value := TValue.From<string>(aValue);
      end;

      RttiProperty.SetValue(Self, Value);
    end;
  finally
    RttiContext.Free;
  end;
end;

procedure TViewFMXBase.Remember(const aPropName: string; const aValue: Variant);
begin
  BaseView.Remember(aPropName, aValue);
end;

{ TControllerFMX }

procedure TControllerFMX.BeforeDestroy;
begin
  inherited;

  if Assigned(FRememberList) then
    FRememberList.Free;
end;

function TControllerFMX.CreateView<T>: T;
begin
  Result := T.CreateByController(ViewEventsObserver, ViewRememberObserver);
  FViews.AddOrSetValue(T, Result);
  RecoverRemembers(Result);
end;

function TControllerFMX.GetRememberFilePath: string;
begin
  Result := TPath.Combine(GetCurrentDir, 'app.ini');
end;

function TControllerFMX.GetRememberList: TStringList;
begin
  if not Assigned(FRememberList) then
    FRememberList := TStringList.Create;

  Result := FRememberList;
end;

function TControllerFMX.GetRowKey(const aViewName, aPropName: string): string;
begin
  Result := Format('%s.%s', [aViewName, aPropName]);
end;

procedure TControllerFMX.RecoverRemembers(aView: TViewFMXBase);
var
  i: Integer;
  Key: TArray<string>;
begin
  if TFile.Exists(GetRememberFilePath) then
    GetRememberList.LoadFromFile(GetRememberFilePath);

  for i := 0 to GetRememberList.Count - 1 do
  begin
    Key := GetRememberList.KeyNames[i].Split(['.']);
    if Key[0] = aView.Name then
      aView.Recover(Key[1], GetRememberList.ValueFromIndex[i]);
  end;
end;

procedure TControllerFMX.RegisterMainView(aMainView: TViewFMXMain);
begin
  FViews.AddOrSetValue(aMainView.ClassType, aMainView);
end;

procedure TControllerFMX.ViewRememberObserver(aView: TObject;
  const aPropName: string; const aValue: Variant);
var
  View: TViewFMXBase;
begin
  View := aView as TViewFMXBase;

  GetRememberList.Values[GetRowKey(View.Name, aPropName)] := aValue;
  GetRememberList.SaveToFile(GetRememberFilePath);
end;

{ TViewFMXMain }

constructor TViewFMXMain.Create(AOwner: TComponent);
var
  Controller: TControllerFMX;
begin
  inherited;

  try
    Controller := SubscribeController as TControllerFMX;
  except
    on E: EAbstractError do
      raise Exception.CreateFmt('MVC_FMX: %s should override SubscribeController virtual function', [ClassName]);
  else
    raise;
  end;

  Controller.RegisterMainView(Self);
  Controller.RecoverRemembers(Self);
  BaseView.EventProc := Controller.ViewEventsObserver;
  BaseView.RememberEventProc := Controller.ViewRememberObserver;
end;

end.
