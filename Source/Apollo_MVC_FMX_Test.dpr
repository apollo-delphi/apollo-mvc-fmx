program Apollo_MVC_FMX_Test;

{$STRONGLINKTYPES ON}
uses
  Vcl.Forms,
  System.SysUtils,
  DUnitX.Loggers.GUI.VCL,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  tstApollo_MVC_FMX in 'tstApollo_MVC_FMX.pas',
  Apollo_MVC_FMX in 'Apollo_MVC_FMX.pas' {Form1},
  Apollo_MVC_Core in '..\Vendors\Apollo_MVC_Core\Apollo_MVC_Core.pas';

begin
  Application.Initialize;
  Application.Title := 'DUnitX';
  Application.CreateForm(TGUIVCLTestRunner, GUIVCLTestRunner);
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
