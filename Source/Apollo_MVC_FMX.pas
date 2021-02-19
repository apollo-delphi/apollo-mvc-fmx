unit Apollo_MVC_FMX;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  Apollo_MVC_Core;

type
  TViewFMXBase = class abstract(TForm, IViewBase)
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    FBaseView: IViewBase;
    function GetBaseView: IViewBase;
    property BaseView: IViewBase read GetBaseView implements IViewBase;
  protected
    procedure FireEvent(const aEventName: string);
  public
    constructor CreateByController(aViewEventProc: TViewEventProc);
  end;

  TViewFMXMain = class abstract(TViewFMXBase, IViewMain)
  protected
    function SubscribeController: TControllerAbstract; virtual; abstract;
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
    FBaseView := TViewBase.Create(Self);
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
begin
  inherited;

  if SubscribeController is TControllerFMX then
    TControllerFMX(SubscribeController).RegisterMainView(Self)
  else
    raise Exception.Create('Error Message');

  BaseView.EventProc := SubscribeController.ViewEventsObserver;
end;

end.
