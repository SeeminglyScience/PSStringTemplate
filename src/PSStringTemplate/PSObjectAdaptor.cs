using System;
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

            if (result != null) return AdapterUtil.NullIfEmpty(result.Value);

            var method = psObject.Methods.FirstOrDefault(
                m => m.Name == string.Concat("Get", propertyName) &&
                        m.OverloadDefinitions.FirstOrDefault().Contains(@"()") &&
                    !m.OverloadDefinitions.FirstOrDefault().Contains("void"));
            
            return AdapterUtil.NullIfEmpty(method?.Invoke());
        }
    }
}
