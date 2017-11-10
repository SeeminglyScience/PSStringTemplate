using System;
using System.Management.Automation;
using Antlr4.StringTemplate;
using Antlr4.StringTemplate.Misc;

namespace PSStringTemplate
{
    /// <summary>
    /// The New-StringTemplateGroup cmdlet creates a <see cref="TemplateGroupInfo"/> object
    /// from either a group or template definition string.
    /// </summary>
    [Cmdlet(VerbsCommon.New, "StringTemplateGroup", DefaultParameterSetName = "ByTemplateDefinition")]
    [OutputType(typeof(TemplateGroupInfo))]
    public class NewStringTemplateGroupCommand : Cmdlet
    {
        /// <summary>
        /// The following is the definition of the input parameter "Definition".
        /// Specifies a string to use to create a template group.
        /// </summary>
        [Parameter(Mandatory = true)]
        [ValidateNotNullOrEmpty]
        public string Definition { get; set; }

        /// <summary>
        /// EndProcessing method.
        /// </summary>
        protected override void EndProcessing()
        {
            var group = new TemplateGroupString(Definition) { Listener = new ErrorListener(this) };

            var groupInfo = new TemplateGroupInfo(group);

            group.RegisterModelAdaptor(typeof(PSObject), new PSObjectAdaptor());
            group.RegisterModelAdaptor(typeof(Type), new TypeAdapter());
            group.RegisterRenderer(typeof(DateTime), new DateRenderer());
            group.RegisterRenderer(typeof(DateTimeOffset), new DateRenderer());
            group.Listener = ErrorManager.DefaultErrorListener;

            WriteObject(groupInfo);
        }
    }
}
