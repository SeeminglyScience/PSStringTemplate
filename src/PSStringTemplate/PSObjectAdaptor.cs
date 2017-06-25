using System.Linq;
using System.Management.Automation;
using Antlr4.StringTemplate;
using Antlr4.StringTemplate.Misc;

namespace PSStringTemplate
{
    class PSObjectAdaptor : ObjectModelAdaptor
    {
        public override object GetProperty(Interpreter interpreter,
                                           TemplateFrame frame,
                                           object obj,
                                           object property,
                                           string propertyName)
        {
            if (obj is PSObject psObject)
            {
                var result = psObject.Properties.FirstOrDefault(p => p.Name == propertyName);

                if (result != null) return ProcessValue(result.Value);

                var method = psObject.Methods.FirstOrDefault(
                    m => m.Name == string.Concat("Get", propertyName) &&
                         m.OverloadDefinitions.FirstOrDefault().Contains(@"()") &&
                        !m.OverloadDefinitions.FirstOrDefault().Contains("void"));
                
                return method != null
                    ? ProcessValue(method?.Invoke())
                    : null;
            }

            return base.GetProperty(interpreter, frame, obj, property, propertyName);
        }
        private static object ProcessValue(object value)
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
