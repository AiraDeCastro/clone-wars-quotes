// Adapted from Microsoft's "Implement a widget provider in a C# Windows
// App" walkthrough. Registers WidgetProvider with OLE so the Widgets Board
// host can activate it via COM.
// https://learn.microsoft.com/windows/apps/develop/widgets/implement-widget-provider-cs

using System.Runtime.InteropServices;
using ColdOpen.WidgetProvider;
using ColdOpen.WidgetProvider.Com;

[DllImport("kernel32.dll")]
static extern IntPtr GetConsoleWindow();

[DllImport("ole32.dll")]
static extern int CoRegisterClassObject(
    [MarshalAs(UnmanagedType.LPStruct)] Guid rclsid,
    [MarshalAs(UnmanagedType.IUnknown)] object pUnk,
    uint dwClsContext,
    uint flags,
    out uint lpdwRegister);

[DllImport("ole32.dll")]
static extern int CoRevokeClassObject(uint dwRegister);

Console.WriteLine("Registering Cold Open widget provider...");

// PLACEHOLDER GUID — generated once for this scaffold (via
// crypto.randomUUID(), not Visual Studio's Tools > Create GUID, since no
// Visual Studio is available in this environment). It's consistent with
// the com:Class Id and CreateInstance ClassId in
// WidgetProvider.Package/Package.appxmanifest — all three must match. If
// you regenerate it, update all three places.
var clsidFactory = Guid.Parse("6041f1cb-d544-4bec-8d4b-fd9e733060f5");

var registered = CoRegisterClassObject(
    clsidFactory,
    new WidgetProviderFactory<ColdOpenWidgetProvider>(),
    0x4,
    0x1,
    out var cookie);

if (registered != 0)
{
    Marshal.ThrowExceptionForHR(registered);
}

Console.WriteLine("Registered successfully.");

if (GetConsoleWindow() != IntPtr.Zero)
{
    Console.WriteLine("Press ENTER to exit.");
    Console.ReadLine();
}
else
{
    using var emptyWidgetListEvent = ColdOpenWidgetProvider.GetEmptyWidgetListEvent();
    emptyWidgetListEvent.WaitOne();
}

CoRevokeClassObject(cookie);
