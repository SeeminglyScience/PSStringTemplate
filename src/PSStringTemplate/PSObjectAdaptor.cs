using System;
using System.Linq;
using System.Management.Automation;
using Antlr4.StringTemplate;
using Antlr4.StringTemplate.Misc;

namespace PSStringTemplate
{
    /// <summary>
    /// Provides property binding for <see cref="PSObject"/> objects.
    /// </summary>
    public class PSObjectAdaptor : ObjectModelAdaptor
    {
        /// <summary>
        /// Gets the value of a property if it exists.
        /// </summary>
        /// <param name="interpreter">The current interpreter passed by Antlr.</param>
        /// <param name="frame">The current frame passed by Antlr.</param>
        /// <param name="obj">The target of the property binding</param>
        /// <param name="property">The property passed by Antlr.</param>
        /// <param name="propertyName">The target property name.</param>
        /// <returns>The value of the property if it exists, otherwise <see langword="null"/>.</returns>
        public override object GetProperty(
            Interpreter interpreter,
            TemplateFrame frame,
            object obj,
            object property,
            string propertyName)
        {
            var psObject = obj as PSObject;
            if (psObject == null)
            {
                return base.GetProperty(interpreter, frame, obj, property, propertyName);
            }

            // Check for static property matches if we're processing a type,
            // continue to instance properties if binding fails.
            if (psObject.BaseObject is Type type)
            {
                var typeResult = TypeAdapter.GetProperty(type, propertyName);
                if (typeResult != null)
                {
                    return typeResult;
                }
            }

            var result = psObject.Properties.FirstOrDefault(p => p.Name == propertyName);

            if (result != null)
            {
                return AdapterUtil.NullIfEmpty(result.Value);
            }

            var method = psObject.Methods.FirstOrDefault(
                m =>
                {
                    return
                        m.Name == string.Concat("Get", propertyName) &&
                        m.OverloadDefinitions.FirstOrDefault().Contains(@"()") &&
                        !m.OverloadDefinitions.FirstOrDefault().Contains("void");
                });

            return AdapterUtil.NullIfEmpty(method?.Invoke());
        }
    }
}
