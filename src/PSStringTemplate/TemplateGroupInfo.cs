using System;
using System.Collections.ObjectModel;
using System.Management.Automation;
using Antlr4.StringTemplate;
using Antlr4.StringTemplate.Misc;

using Strings = PSStringTemplate.Properties.Resources;

namespace PSStringTemplate
{
    /// <summary>
    /// Displays <see cref="TemplateGroup"/> object information in a simpler format for use in PowerShell.
    /// </summary>
    public class TemplateGroupInfo
    {
        /// <summary>
        /// Initializes a new instance of the <see cref="TemplateGroupInfo"/> class.
        /// </summary>
        /// <param name="templateGroupInstance">The internal group instance.</param>
        internal TemplateGroupInfo(TemplateGroup templateGroupInstance)
        {
            Instance = templateGroupInstance;
            var templates = new Collection<TemplateInfo>();
            var names = templateGroupInstance.GetTemplateNames();
            foreach (var name in names)
            {
                templates.Add(new TemplateInfo(Instance.GetInstanceOf(name), this));
            }

            Templates = new ReadOnlyCollection<TemplateInfo>(templates);
        }

        /// <summary>
        /// Gets the <see cref="Template"/> objects that belong to this group, wrapped in
        /// <see cref="TemplateInfo"/> objects.
        /// </summary>
        public ReadOnlyCollection<TemplateInfo> Templates { get; }

        /// <summary>
        /// Gets the base <see cref="TemplateGroup"/> that this object wraps.
        /// </summary>
        internal TemplateGroup Instance { get; }

        /// <summary>
        /// Create a <see cref="TemplateGroupString"/> from a template definition string.
        /// </summary>
        /// <param name="context">The error listener attached to the currently running cmdlet.</param>
        /// <param name="templateDefinition">The template source to use.</param>
        /// <returns>The defined template.</returns>
        internal static TemplateGroupInfo CreateFromTemplateDefinition(
            Cmdlet context,
            string templateDefinition)
        {
            var group = new TemplateGroupString(string.Empty);
            Bind(group, context);
            group.DefineTemplate(Strings.DefaultTemplateName, templateDefinition);
            group.GetInstanceOf(Strings.DefaultTemplateName).impl.HasFormalArgs = false;
            return new TemplateGroupInfo(group);
        }

        /// <summary>
        /// Create a template group from a string group definition.
        /// </summary>
        /// <param name="context">The <see cref="Cmdlet"/> context to throw from.</param>
        /// <param name="groupDefinition">The string group definition.</param>
        /// <returns>The compiled template group.</returns>
        internal static TemplateGroupInfo CreateFromGroupDefinition(
            Cmdlet context,
            string groupDefinition)
        {
            var group = new TemplateGroupString(groupDefinition);
            Bind(group, context);
            return new TemplateGroupInfo(group);
        }

        /// <summary>
        /// Attaches a template group to a running <see cref="Cmdlet"/>.
        /// </summary>
        /// <param name="context">The <see cref="Cmdlet"/> instance to attach to.</param>
        internal void Bind(Cmdlet context)
        {
            Bind(Instance, context);
        }

        /// <summary>
        /// Removes the attached <see cref="Cmdlet"/> from a template group.
        /// </summary>
        internal void Unbind()
        {
            Unbind(Instance);
        }

        /// <summary>
        /// Attaches a template group to a running <see cref="Cmdlet"/>.
        /// </summary>
        /// <param name="group">The <see cref="TemplateGroup"/> to attach.</param>
        /// <param name="context">The <see cref="Cmdlet"/> instance to attach to.</param>
        private static void Bind(TemplateGroup group, Cmdlet context)
        {
            group.Listener = new ErrorListener(context);
            group.RegisterModelAdaptor(typeof(PSObject), new PSObjectAdaptor());
            group.RegisterModelAdaptor(typeof(Type), new TypeAdapter());
            group.RegisterRenderer(typeof(DateTime), new DateRenderer());
            group.RegisterRenderer(typeof(DateTimeOffset), new DateRenderer());
        }

        private static void Unbind(TemplateGroup group)
        {
            group.Listener = ErrorManager.DefaultErrorListener;
        }
    }
}
