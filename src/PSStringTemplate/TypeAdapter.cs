using Antlr4.StringTemplate.Misc;
using Antlr4.StringTemplate;
using System;
using System.Reflection;

namespace PSStringTemplate
{
    public class TypeAdapter : ObjectModelAdaptor
    {
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