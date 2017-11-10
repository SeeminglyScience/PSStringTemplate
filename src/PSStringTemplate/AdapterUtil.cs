using System.Management.Automation;

namespace PSStringTemplate
{
    internal static class AdapterUtil
    {
        internal static object NullIfEmpty(object value)
        {
            // Enable treating null-like values like empty strings and arrays from PSObject as null.
            return value == null
                ? null
                : LanguagePrimitives.IsTrue(value)
                    ? value
                    : null;
        }
    }
}