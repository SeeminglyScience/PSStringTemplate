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
                return psObject
                           .Properties
                           .First(p => p.Name == propertyName)
                           .Value
                       ?? psObject.Methods.First(
                           m => m.Name == string.Concat("Get", propertyName) &&
                                m.OverloadDefinitions.First().Contains(@"()") &&
                                !m.OverloadDefinitions.First().Contains("void")).Invoke();

            }

            return base.GetProperty(interpreter, frame, obj, property, propertyName);
        }
    }
}
