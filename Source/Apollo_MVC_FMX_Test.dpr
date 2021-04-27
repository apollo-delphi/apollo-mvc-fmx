program Apollo_MVC_FMX_Test;

{$STRONGLINKTYPES ON}
uses
  FMX.Forms,
  System.SysUtils,
  DUnitX.Loggers.GUIX,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  tstApollo_MVC_FMX in 'tstApollo_MVC_FMX.pas',
  Apollo_MVC_FMX in 'Apollo_MVC_FMX.pas' {ViewFMXMain},
  Apollo_MVC_Core in '..\Vendors\Apollo_MVC_Core\Apollo_MVC_Core.pas';

begin
  Application.Initialize;
  Application.Title := 'DUnitX';
  Application.CreateForm(TGUIXTestRunner, GUIXTestRunner);
  Application.Run;
end.
