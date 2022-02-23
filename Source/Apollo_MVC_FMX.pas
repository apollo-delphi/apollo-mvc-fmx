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
    FViewBase: IViewBase;
    function GetViewBase: IViewBase;
    property ViewBase: IViewBase read GetViewBase implements IViewBase;
  protected
    procedure DoClose(var Action: TCloseAction); override;
    procedure FireEvent(const aEventName: string);
    procedure InitControls; virtual;
    procedure InitVariables; virtual;
    procedure Recover(const aPropName: string; aValue: Variant); virtual;
    procedure Remember(const aPropName: string; const aValue: Variant);
    procedure ValidateControls; virtual;
  end;

  TViewFMXMain = class abstract(TViewFMXBase)
  protected
    procedure LinkToController(out aController: TControllerAbstract); virtual; abstract;
  public
    constructor Create(AOwner: TComponent); override;
  end;

  TFrameHelper = class helper for TFrame
  protected
    function GetOwnerViewBase: IViewBase;
    procedure FireEvent(var aViewBase: IViewBase; const aEventName: string);
    procedure RegisterFrame(var aViewBase: IViewBase);
  end;

implementation

{$R *.fmx}

{ TViewFMXBase }

procedure TViewFMXBase.DoClose(var Action: TCloseAction);
begin
  if ModalResult = mrOK then
    ValidateControls;
  Action := TCloseAction.caFree;
  inherited;

  FireEvent(mvcViewClose);
end;

procedure TViewFMXBase.FireEvent(const aEventName: string);
begin
  ViewBase.FireEvent(aEventName);
end;

function TViewFMXBase.GetViewBase: IViewBase;
begin
  if not Assigned(FViewBase) then
  begin
    FViewBase := MakeViewBase(Self);
    FViewBase.OnRecover := Recover;
    FViewBase.OnInitControls := InitControls;
    FViewBase.OnInitVariables := InitVariables;
  end;
  Result := FViewBase;
end;

procedure TViewFMXBase.InitControls;
begin
end;

procedure TViewFMXBase.InitVariables;
begin
end;

procedure TViewFMXBase.Recover(const aPropName: string; aValue: Variant);
begin
end;

procedure TViewFMXBase.Remember(const aPropName: string; const aValue: Variant);
begin
  ViewBase.Remember(aPropName, aValue);
end;

procedure TViewFMXBase.ValidateControls;
begin
end;

{ TViewFMXMain }

constructor TViewFMXMain.Create(AOwner: TComponent);
var
  Controller: TControllerAbstract;
begin
  gAllowDirectConstructorForView := True;
  try
    inherited;
  finally
    gAllowDirectConstructorForView := False;
  end;

  try
    Controller := nil;
    LinkToController({out}Controller);
  except
    on E: EAbstractError do
      raise Exception.CreateFmt('MVC_FMX: %s should override LinkToController virtual procedure',
        [ClassName]);
  else
    raise;
  end;

  if not Assigned(Controller) then
    raise Exception.CreateFmt('MVC_FMX: procedure LinkToController out param aController is not assigned.', [ClassName]);

  ViewBase.RegisterInController(Controller);
end;

{ TFrameHelper }

procedure TFrameHelper.FireEvent(var aViewBase: IViewBase;
  const aEventName: string);
begin
  if not Owner.InheritsFrom(TViewFMXBase) then
    raise Exception.Create('TFrameHelper.GetViewBase: Owner of TFrame must inherits from TViewFMXBase.');

  if not Assigned(aViewBase) then
  begin
    aViewBase := MakeViewBase(Self);
    aViewBase.EventProc := GetOwnerViewBase.EventProc;
  end;

  aViewBase.FireEvent(aEventName);
end;

function TFrameHelper.GetOwnerViewBase: IViewBase;
begin
  if not Owner.InheritsFrom(TViewFMXBase) then
    raise Exception.Create('TFrameHelper.GetViewBase: Owner of TFrame must inherits from TViewFMXBase.');

  Result := TViewFMXBase(Owner).ViewBase;
end;

procedure TFrameHelper.RegisterFrame(var aViewBase: IViewBase);
begin
  FireEvent(aViewBase, mvcRegisterFrame);
  AddFreeNotify(TViewFMXBase(GetOwnerViewBase.View));
end;

end.
