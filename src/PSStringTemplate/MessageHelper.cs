using System.Management.Automation.Language;
using Antlr.Runtime;
using Antlr4.StringTemplate.Misc;
using System.Linq;

namespace PSStringTemplate
{
    /// <summary>
    /// Helper class to get only the pieces of a TemplateMessage that we need to create
    /// an error record for PowerShell to consume.
    /// </summary>
    internal class MessageHelper
    {
        /// <summary>
        /// A summary of the error from the <see cref="TemplateMessage"/>.
        /// </summary>
        internal string ErrorDescription { get; }
        /// <summary>
        /// The approximate location of the invalid syntax.
        /// </summary>
        internal ScriptExtent ErrorExtent { get; }

        private readonly TemplateMessage _message;
        private readonly CommonToken _token;
        private readonly RecognitionException _cause;

        internal MessageHelper(TemplateMessage msg)
        {
            _message = msg;
            _token = GetToken();
            // TODO: Get the type of exception before casting and include that in the error.
            _cause = msg.Cause as RecognitionException;

            // TODO: Include the "Expecting" property that is sometimes included in the exception.
            ErrorDescription = GetDescription();
            ErrorExtent = GetScriptExtent();

        }

        private ScriptExtent GetScriptExtent()
        {
            var startOffsetInLine = _cause?.CharPositionInLine
                                    ?? _token?.CharPositionInLine
                                    ?? 0;

            // Prefer the input stream from cause if possible, the token is more likely to
            // only be a portion of the source, which causes the extent to be off.
            var fullText = (_cause?.Input ?? _token?.InputStream)?.ToString() ?? string.Empty;
            var lines = fullText.Replace("\r", string.Empty).Split('\n');

            // The line number in the template message isn't reliable, sometimes it's zero based,
            // sometimes it's one based.
            var lineNumber = fullText
                .Take(_cause?.Index ?? _token?.StartIndex ?? 0)
                .Count(c => c == '\n');

            var line = lines.Length > lineNumber
                ? lines[lineNumber]
                : string.Empty;


            var start = new ScriptPosition(string.Empty,
                _cause?.Line ?? 0,
                startOffsetInLine + 1,
                line);

            return new ScriptExtent(start, start);
        }

        private string GetDescription()
        {
            // Lexer is the only message type that doesn't use the Arg property.
            return (_message as TemplateLexerMessage)?.Message
                   ?? _message.Arg as string
                   ?? string.Empty;
        }

        private CommonToken GetToken()
        {
            // Lexer again likes to break the mold.  May remove the check for a token in cause, haven't
            // seen it used yet.
            var result = (_message as TemplateCompiletimeMessage)?.Token
                         ?? (_message as TemplateLexerMessage)?.TemplateToken
                         ?? (_message.Cause as RecognitionException)?.Token;
            return result as CommonToken;
        }
    }
}
