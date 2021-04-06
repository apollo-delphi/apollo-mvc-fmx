unit Apollo_MVC_FMX;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  Apollo_MVC_Core;

type
  TControllerFMX = class;

  TViewFMXBase = class abstract(TForm, IViewBase)
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    FBaseView: IViewBase;
    function GetBaseView: IViewBase;
    property BaseView: IViewBase read GetBaseView implements IViewBase;
  protected
    function EmbedFrame<T: TFrame>(var aFrameKeeper: TFrame; aOwner: TFmxObject): T;
    procedure FireEvent(const aEventName: string);
  public
    constructor CreateByController(aViewEventProc: TViewEventProc);
  end;

  TViewFMXMain = class abstract(TViewFMXBase)
  protected
    function SubscribeController: TControllerFMX; virtual; abstract;
  public
    constructor Create(AOwner: TComponent); override;
  end;

  TControllerFMX = class abstract(TControllerAbstract)
  private
    procedure RegisterMainView(aMainView: TViewFMXMain);
  protected
    function CreateView<T: TViewFMXBase, constructor>: T;
  end;

implementation

{$R *.fmx}

{ TViewFMXBase }

constructor TViewFMXBase.CreateByController(aViewEventProc: TViewEventProc);
begin
  Create(nil);

  BaseView.EventProc := aViewEventProc;
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
end;

function TViewFMXBase.GetBaseView: IViewBase;
begin
  if not Assigned(FBaseView) then
    FBaseView := MakeViewBase(Self);
  Result := FBaseView;
end;

{ TControllerFMX }

function TControllerFMX.CreateView<T>: T;
begin
  Result := T.CreateByController(ViewEventsObserver);
  FViews.AddOrSetValue(T, Result);
end;

procedure TControllerFMX.RegisterMainView(aMainView: TViewFMXMain);
begin
  FViews.AddOrSetValue(aMainView.ClassType, aMainView);
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
  BaseView.EventProc := Controller.ViewEventsObserver;
end;

end.
