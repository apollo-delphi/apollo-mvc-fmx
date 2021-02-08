unit Apollo_MVC_FMX;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  Apollo_MVC_Core;

type
  TViewFMXBase = class(TForm, IViewBase, IViewMain)
    procedure FormCreate(Sender: TObject);
  private
    FBaseView: IViewBase;
    function GetBaseView: IViewBase;
    property BaseView: IViewBase read GetBaseView implements IViewBase;
  protected
    function SubscribeController: TControllerAbstract; virtual; abstract;
    procedure FireEvent(const aEventName: string);
  public
  end;

  TControllerFMX = class(TControllerAbstract)
  end;

implementation

{$R *.fmx}

{ TViewFMXBase }

procedure TViewFMXBase.FireEvent(const aEventName: string);
begin
  BaseView.FireEvent(aEventName);
end;

procedure TViewFMXBase.FormCreate(Sender: TObject);
begin
  BaseView.EventProc := SubscribeController.ViewEventsObserver;
end;

function TViewFMXBase.GetBaseView: IViewBase;
begin
  if not Assigned(FBaseView) then
    FBaseView := TViewBase.Create(Self);
  Result := FBaseView;
end;

end.
