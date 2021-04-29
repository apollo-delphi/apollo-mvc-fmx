unit Apollo_MVC_FMX;

interface

uses
  Apollo_MVC_Core,
  FireDAC.FMXUI.Wait,
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
  TViewFMXBase = class abstract(TForm, IViewBase)
  private
    FBaseView: IViewBase;
    function GetBaseView: IViewBase;
    property BaseView: IViewBase read GetBaseView implements IViewBase;
  protected
    procedure DoClose(var Action: TCloseAction); override;
    procedure FireEvent(const aEventName: string);
    procedure Remember(const aPropName: string; const aValue: Variant);
  end;

  TViewFMXMain = class abstract(TViewFMXBase)
  protected
    procedure LinkToController(out aController: TControllerAbstract); virtual; abstract;
  public
    constructor Create(AOwner: TComponent); override;
  end;


implementation

{$R *.fmx}

{ TViewFMXBase }

procedure TViewFMXBase.DoClose(var Action: TCloseAction);
begin
  Action := TCloseAction.caFree;
  inherited;

  FireEvent(mvcViewClose);
end;

procedure TViewFMXBase.FireEvent(const aEventName: string);
begin
  BaseView.FireEvent(aEventName);
end;

function TViewFMXBase.GetBaseView: IViewBase;
begin
  if not Assigned(FBaseView) then
    FBaseView := MakeViewBase(Self);
  Result := FBaseView;
end;

procedure TViewFMXBase.Remember(const aPropName: string; const aValue: Variant);
begin
  BaseView.Remember(aPropName, aValue);
end;

{ TViewFMXMain }

constructor TViewFMXMain.Create(AOwner: TComponent);
var
  Controller: TControllerAbstract;
begin
  inherited;

  try
    LinkToController(Controller);
  except
    on E: EAbstractError do
      raise Exception.CreateFmt('MVC_FMX: %s should override LinkToController virtual procedure', [ClassName]);
  else
    raise;
  end;

  Controller.RegisterView(Self);
end;

end.
