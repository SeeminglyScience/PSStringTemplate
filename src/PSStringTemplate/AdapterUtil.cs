using System.Management.Automation;

namespace PSStringTemplate
{
    /// <summary>
    /// Provides shared utility methods for adapters.
    /// </summary>
    internal static class AdapterUtil
    {
        /// <summary>
        /// Filter empty adapter results to allow PowerShell-like
        /// treatment of objects as true or false.
        /// </summary>
        /// <param name="value">The value to filter.</param>
        /// <returns> Either <see langword="null"/> if empty or the value.</returns>
        internal static object NullIfEmpty(object value)
        {
            return value == null
                ? null
                : LanguagePrimitives.IsTrue(value)
                    ? value
                    : null;
        }
    }
}
