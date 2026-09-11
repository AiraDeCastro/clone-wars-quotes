// Adapted near-verbatim from Microsoft's "Implement a widget provider in a
// C# Windows App" walkthrough — this is standard COM class-factory
// boilerplate, not specific to widget providers except for the generic
// constraint on T.
// https://learn.microsoft.com/windows/apps/develop/widgets/implement-widget-provider-cs

using System.Runtime.InteropServices;
using ColdOpen.WidgetProvider;
using Microsoft.Windows.Widgets.Providers;
using WinRT;

namespace ColdOpen.WidgetProvider.Com;

internal static class Guids
{
    public const string IClassFactory = "00000001-0000-0000-C000-000000000046";
    public const string IUnknown = "00000000-0000-0000-C000-000000000046";
}

[ComImport, ComVisible(false), InterfaceType(ComInterfaceType.InterfaceIsIUnknown), Guid(Guids.IClassFactory)]
internal interface IClassFactory
{
    [PreserveSig]
    int CreateInstance(IntPtr pUnkOuter, ref Guid riid, out IntPtr ppvObject);

    [PreserveSig]
    int LockServer(bool fLock);
}

[ComVisible(true)]
internal sealed class WidgetProviderFactory<T> : IClassFactory
    where T : IWidgetProvider, new()
{
    private const int ClassENoAggregation = -2147221232;
    private const int ENoInterface = -2147467262;

    public int CreateInstance(IntPtr pUnkOuter, ref Guid riid, out IntPtr ppvObject)
    {
        ppvObject = IntPtr.Zero;

        if (pUnkOuter != IntPtr.Zero)
        {
            Marshal.ThrowExceptionForHR(ClassENoAggregation);
        }

        if (riid == typeof(T).GUID || riid == Guid.Parse(Guids.IUnknown))
        {
            ppvObject = MarshalInspectable<IWidgetProvider>.FromManaged(new T());
        }
        else
        {
            Marshal.ThrowExceptionForHR(ENoInterface);
        }

        return 0;
    }

    int IClassFactory.LockServer(bool fLock) => 0;
}
