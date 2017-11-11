using System;
using System.Reflection;
using Antlr4.StringTemplate;
using Antlr4.StringTemplate.Misc;

namespace PSStringTemplate
{
    /// <summary>
    /// Provides static property binding for <see cref="Type"/> objects.
    /// </summary>
    public class TypeAdapter : ObjectModelAdaptor
    {
        /// <summary>
        /// Gets the value of a property if it exists.
        /// </summary>
        /// <param name="interpreter">The current interpreter passed by Antlr.</param>
        /// <param name="frame">The current frame passed by Antlr.</param>
        /// <param name="o">The target of the property binding</param>
        /// <param name="property">The property passed by Antlr.</param>
        /// <param name="propertyName">The target property name.</param>
        /// <returns>The value of the property if it exists, otherwise <see langword="null"/>.</returns>
        public override object GetProperty(
            Interpreter interpreter,
            TemplateFrame frame,
            object o,
            object property,
            string propertyName)
        {
            return GetProperty(o as Type, propertyName) ??
                base.GetProperty(interpreter, frame, o, property, propertyName);
        }

        /// <summary>
        /// Gets the value of a static property.
        /// </summary>
        /// <param name="type">The <see cref="Type"/> with the target property.</param>
        /// <param name="propertyName">The name of the property to retrieve.</param>
        /// <returns>The value if the property exists, otherwise <see langword="null"/>.</returns>
        internal static object GetProperty(
            Type type,
            string propertyName)
        {
            if (type == null)
            {
                return null;
            }

            PropertyInfo typeProp = null;
            try
            {
                typeProp = type
                    .GetProperty(
                        propertyName,
                        BindingFlags.Static | BindingFlags.Public);
            }
            catch (AmbiguousMatchException)
            {
                // Treat ambiguous matches as if the property wasn't found
            }

            return AdapterUtil.NullIfEmpty(typeProp?.GetValue(null));
        }
    }
}
