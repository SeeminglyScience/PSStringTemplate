using System;
using System.Collections;
using System.Collections.Generic;
using System.Diagnostics;
using System.Diagnostics.CodeAnalysis;
using System.Globalization;
using System.Linq;
using System.Management.Automation;
using System.Reflection;
using System.Text.RegularExpressions;

using Strings = PSStringTemplate.Properties.Resources;

namespace PSStringTemplate
{
    /// <summary>
    /// The Invoke-StringTemplate cmdlet adds arguments to a template object
    /// (either existing or created by this cmdlet) and returns the rendered
    /// string.
    /// </summary>
    [Cmdlet(VerbsLifecycle.Invoke, "StringTemplate")]
    [OutputType(typeof(string))]
    public class InvokeStringTemplateCommand : Cmdlet
    {
        private TemplateInfo _currentTemplate;

        /// <summary>
        /// Gets or sets the string template definition to invoke.
        /// </summary>
        [Parameter(Mandatory = true, ParameterSetName = "ByDefinition")]
        [ValidateNotNullOrEmpty]
        public string Definition { get; set; }

        /// <summary>
        /// Gets or sets the target template group.
        /// </summary>
        [Parameter(
            Mandatory = true,
            Position = 0,
            ValueFromPipeline = true,
            ValueFromPipelineByPropertyName = true,
            ParameterSetName = "ByGroup")]
        [ValidateNotNullOrEmpty]
        public TemplateGroupInfo Group { get; set; }

        /// <summary>
        /// Gets or sets the name of the template to invoke.
        /// </summary>
        [Parameter(ValueFromPipelineByPropertyName = true, ParameterSetName = "ByGroup")]
        [ValidateNotNullOrEmpty]
        public string Name { get; set; }

        /// <summary>
        /// Gets or sets the template parameters.
        /// </summary>
        [Parameter(Position = 0, ValueFromPipeline = true)]
        [ValidateNotNullOrEmpty]
        public PSObject Parameters { get; set; }

        /// <summary>
        /// ProcessRecord method.
        /// </summary>
        protected override void ProcessRecord()
        {
            TemplateGroupInfo group = null;
            if (Group != null)
            {
                group = Group;
                group.Bind(this);
                var templateNames = group.Templates.Select(t => t.Name);
                var safeTemplateNames = templateNames as string[] ?? templateNames.ToArray();

                var name = Name ?? safeTemplateNames.FirstOrDefault();

                if (!safeTemplateNames.Contains(name))
                {
                    var nameString = string.Join(
                        CultureInfo.CurrentCulture.TextInfo.ListSeparator,
                        safeTemplateNames);

                    var msg = string.Format(
                        CultureInfo.CurrentCulture,
                        Strings.TemplateNotFound,
                        name,
                        nameString);

                    var error = new ErrorRecord(
                        new InvalidOperationException(msg),
                        nameof(Strings.TemplateNotFound),
                        ErrorCategory.ObjectNotFound,
                        name);

                    ThrowTerminatingError(error);
                }

                _currentTemplate = group.Templates
                    .FirstOrDefault(t => t.Name == name);
            }

            if (Definition != null)
            {
                group = TemplateGroupInfo.CreateFromTemplateDefinition(this, Definition);
                _currentTemplate = group.Templates.FirstOrDefault();
            }

            Debug.Assert(_currentTemplate != null, "_currentTemplate != null");
            if (Parameters != null)
            {
                if (Parameters.BaseObject is IDictionary asDictionary)
                {
                    foreach (DictionaryEntry keyValuePair in asDictionary)
                    {
                        AddTemplateArgument(keyValuePair.Key as string, keyValuePair.Value);
                    }
                }
                else
                {
                    ProcessObjectAsArguments();
                }
            }

            var result = _currentTemplate.Instance.Render(CultureInfo.CurrentCulture);
            if (result != null)
            {
                WriteObject(result);
            }

            _currentTemplate.ResetInstance();

            group.Unbind();
        }

        /// <summary>
        /// Get the properties of the object in the "Parameter" input parameter and add them as
        /// template arguments.
        /// </summary>
        [SuppressMessage("Microsoft.Design", "CA1031:DoNotCatchGeneralExceptionTypes", Justification = "The exception itself doesn't matter here, only that it's not accessible as a property.")]
        private void ProcessObjectAsArguments()
        {
            if (Parameters.BaseObject is Type type)
            {
                ProcessStaticProperties(type);
            }

            // Add any property with value as an argument.
            var propertyNames = new List<string>();
            foreach (var property in Parameters.Properties)
            {
                // Some properties throw exceptions depending on the object's state, or if not
                // implemented. (TypeInfo.DeclaringMethod for example)
                try
                {
                    if (property.Value == null) continue;
                }
                catch
                {
                    continue;
                }

                AddTemplateArgument(property.Name, property.Value);
                propertyNames.Add(property.Name);
            }

            // Add any method that:
            // 1. Starts with Get and any one upper case alpha character
            // 2. Has no parameters
            // 3. Returns something
            // 4. Doesn't have a matching properties
            foreach (var method in Parameters.Methods)
            {
                if (!Regex.IsMatch(method.Name, @"^Get[A-Z]")) continue;

                var nameAsProperty = Regex.Replace(method.Name, @"^Get", string.Empty);

                if (propertyNames.Contains(nameAsProperty) ||
                    !_currentTemplate.Parameters.Contains(nameAsProperty) ||
                    !method.OverloadDefinitions.First().Contains(@"()") ||
                    method.OverloadDefinitions.First().Contains("void")) continue;

                object result;
                try
                {
                    result = method.Invoke();
                }
                catch
                {
                    WriteDebug(
                        string.Format(
                            CultureInfo.CurrentCulture,
                            Strings.DebugInvokePropertyLikeMethodException,
                            method.Name,
                            nameAsProperty));
                    continue;
                }

                AddTemplateArgument(nameAsProperty, result);
            }
        }

        private void ProcessStaticProperties(Type type)
        {
            Array.ForEach(
                type.GetProperties(BindingFlags.Static | BindingFlags.Public),
                property =>
                {
                    AddTemplateArgument(
                        property.Name,
                        AdapterUtil.NullIfEmpty(
                            property.GetValue(null)));
                });
        }

        /// <summary>
        /// Adds an argument to a template with extra exception handling.
        /// </summary>
        /// <param name="name">The parameter name.</param>
        /// <param name="value">The value to assign to the parameter.</param>
        private void AddTemplateArgument(string name, object value)
        {
            try
            {
                _currentTemplate.Instance.Add(name, value);
                WriteVerbose(
                    string.Format(
                        CultureInfo.CurrentCulture,
                        Strings.VerboseAddedParameter,
                        name,
                        _currentTemplate.Name));
            }
            catch (ArgumentException exception)
            {
                if (exception.Message.StartsWith(
                    @"no such attribute: ",
                    StringComparison.CurrentCulture))
                {
                    WriteDebug(
                        string.Format(
                            CultureInfo.CurrentCulture,
                            Strings.DebugAttributeNotFound,
                            name,
                            _currentTemplate.Name));
                    return;
                }

                throw;
            }
        }
    }
}
