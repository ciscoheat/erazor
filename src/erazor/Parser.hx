package erazor;
import erazor.error.ParserError;

private typedef Block = {
	var block : TBlock;
	var start : Int;
	var length : Int;
}

private enum ParseContext {
	literal;
	code;
}

private enum ParseResult {
	keepGoing;
	doneIncludeCurrent;
	doneSkipCurrent;
}

class Parser
{
	private static var at = '@';

	private var condMatch : EReg;
	private var inConditionalMatch : EReg;
	//private var variableMatch : EReg;
	private var variableChar : EReg;

	// State variables for the parser
	private var context : ParseContext;
	private var bracketStack : Array<ParseContext>;
	private var conditionalStack : Int;

	private var pos : Int;

	private static var bracketMismatch = "Bracket mismatch! Inside template, non-paired brackets, '{' or '}', should be replaced by @{'{'} and @{'}'}.";

	function parseScriptPart(template : String, startBrace : String, endBrace : String) : String
	{
		var insideSingleQuote = false;
		var insideDoubleQuote = false;

		// If startbrace is empty, assume we are in the script already.
		var stack = (startBrace == '') ? 1 : 0;
		var i = -1;

		while(++i < template.length)
		{
			var char = template.charAt(i);

			if(!insideDoubleQuote && !insideSingleQuote)
			{
				if (char == startBrace)
				{
					++stack;
				} else if (char == endBrace) {
					--stack;

					if(stack == 0)
						return template.substr(0, i+1);
					if (stack < 0)
						throw new ParserError( 'Unbalanced braces for block: ', pos,  template.substr(0, 100) );
				} else if (char == '"') {
					insideDoubleQuote = true;
				} else if (char == "'") {
					insideSingleQuote = true;
				}
			}
			else if(insideDoubleQuote && char == '"' && template.charAt(i-1) != '\\')
			{
				insideDoubleQuote = false;
			}
			else if(insideSingleQuote && char == "'" && template.charAt(i-1) != '\\')
			{
				insideSingleQuote = false;
			}
		}

		//trace(startBrace); trace(endBrace);
		throw new ParserError( 'Failed to find a closing delimiter for the script block: ', this.pos, template.substr(0, 100) );
	}

	function parseContext(template : String) : ParseContext
	{
		// If a single @ is found, go into code context.
		if (peek(template) == Parser.at && peek(template, 1) != Parser.at)
			return ParseContext.code;

		// Same if we're inside a conditional and a } is found.
		if (conditionalStack > 0 && peek(template) == '}')
			switch(bracketStack[bracketStack.length - 1]) {
				case code: return ParseContext.code;
				default:
			}

		// Otherwise parse pure text.
		return ParseContext.literal;
	}

	function accept(template : String, acceptor : String -> Bool, throwAtEnd : Bool)
	{
		return parseString(template, function(chr : String) {
			return acceptor(chr) ? ParseResult.keepGoing : ParseResult.doneSkipCurrent;
		}, throwAtEnd);
	}

	function isIdentifier(char : String, first = true)
	{
		return first
			? (char >= 'a' && char <= 'z') || (char >= 'A' && char <= 'Z') || char == '_'
			: (char >= 'a' && char <= 'z') || (char >= 'A' && char <= 'Z') || (char >= '0' && char <= '9') || char == '_';
	}

	function acceptIdentifier(template : String)
	{
		var first = true;
		var self = this;

		return accept(template, function(chr : String) {
			var status = self.isIdentifier(chr, first);
			first = false;
			return status;
		}, false);
	}

	function acceptBracket(template : String, bracket : String)
	{
		return parseScriptPart(template, bracket, bracket == '(' ? ')' : ']');
	}

	/**
	 * Main block parse method, called from parse().
	 */
	function parseBlock(template : String) : Block
	{
		//trace(">>> " + (template.length > 30 ? template.substr(0, 30) + '...' : template));
		return (context == ParseContext.code) ? parseCodeBlock(template) : parseLiteral(template);
	}

	function parseConditional(template : String) : Block
	{
		var str = parseScriptPart(template, '', '{');
		return { block: TBlock.codeBlock(str.substr(1)), length: str.length, start:this.pos };
	}

	function peek(template : String, offset = 0)
	{
		return template.length > offset ? template.charAt(offset) : null;
	}

	function parseVariable(template : String) : Block
	{
		var output = "";
		var char : String = null;
		var part : String = null;

		// Remove @
		template = template.substr(1);

		do
		{
			// Parse identifier
			part = acceptIdentifier(template);
			template = template.substr(part.length);

			output += part;
			char = peek(template);

			// Look for brackets
			while (char == '(' || char == '[')
			{
				part = acceptBracket(template, char);
				template = template.substr(part.length);

				output += part;
				char = peek(template);
			}

			// Look for . and if the char after that is an identifier
			if (char == '.' && isIdentifier(peek(template, 1)))
			{
				template = template.substr(1);

				output += '.';
			}
			else
			{
				break;
			}
		} while (char != null);

		return { block: TBlock.printBlock(output), length: output.length + 1, start:this.pos };
	}

	function parseVariableChar(char : String) : ParseResult
	{
		return (variableChar.match(char)#if macro && variableChar.matchedPos().pos == 0 #end) ? ParseResult.keepGoing : ParseResult.doneSkipCurrent;
	}

	function parseCodeBlock(template : String) : Block
	{
		// Test if at end of a conditional
		if (bracketStack.length > 0 && peek(template) == '}')
		{
			// It may not be an end, just a continuation (else if, else)
			if (inConditionalMatch.match(template) #if macro && inConditionalMatch.matchedPos().pos == 0 #end)
			{
				var str = parseScriptPart(template, '', '{');
				return { block: TBlock.codeBlock(str), length: str.length, start:this.pos };
			}

			if (switch (bracketStack.pop()) {
				case code: --conditionalStack < 0;
				default: true;
			}) throw new ParserError( bracketMismatch, this.pos );

			return { block: TBlock.codeBlock('}'), length: 1, start:this.pos };
		}

		// Test for conditional code block
		if (condMatch.match(template) #if macro && condMatch.matchedPos().pos == 0 #end)
		{
			bracketStack.push(code);
			++conditionalStack;

			return parseConditional(template);
		}

		// Test for variable like @name
		if (peek(template) == '@' && isIdentifier(peek(template, 1)))
			return parseVariable(template);

		// Test for code or print block @{ or @(
		var startBrace = peek(template, 1);
		var endBrace = (startBrace == '{') ? '}' : ')';

		var str = parseScriptPart(template.substr(1), startBrace, endBrace);
		var noBraces = StringTools.trim(str.substr(1, str.length - 2));

		if(startBrace == '{')
			return { block: TBlock.codeBlock(noBraces), length: str.length + 1, start:this.pos };
		else // (
			return { block: TBlock.printBlock(noBraces), length: str.length + 1, start:this.pos };
	}

	private function parseString(str : String, modifier : String -> ParseResult, throwAtEnd : Bool) : String
	{
		var insideSingleQuote = false;
		var insideDoubleQuote = false;

		var i = -1;
		while(++i < str.length)
		{
			var char = str.charAt(i);

			if(!insideDoubleQuote && !insideSingleQuote)
			{
				switch(modifier(char))
				{
					case ParseResult.doneIncludeCurrent:
						return str.substr(0, i + 1);

					case ParseResult.doneSkipCurrent:
						return str.substr(0, i);

					case ParseResult.keepGoing:
						// Just do as he says!
				}

				if (char == '"')
					insideDoubleQuote = true;
				else if (char == "'")
					insideSingleQuote = true;
			}
			else if(insideDoubleQuote && char == '"' && str.charAt(i-1) != '\\')
			{
				insideDoubleQuote = false;
			}
			else if(insideSingleQuote && char == "'" && str.charAt(i-1) != '\\')
			{
				insideSingleQuote = false;
			}
		}

		if(throwAtEnd)
			throw new ParserError( 'Failed to find a closing delimiter: ', this.pos, str.substr(0, 100) );

		return str;
	}

	function parseLiteral(template : String) : Block
	{
		var len = template.length;
		var i = -1;

		while (++i < len) {
			var char = template.charAt(i);
			switch(char) {
				case Parser.at:
					// Test for escaped @
					if (len > i + 1 && template.charAt(i + 1) != Parser.at) {
						return {
							block: TBlock.literal(escapeLiteral(template.substr(0, i))),
							length: i,
							start: this.pos
						};
					}
					++i;
				case '}':
					if (bracketStack.length > 0) {
						switch (bracketStack[bracketStack.length - 1]) {
							case code:
								return {
									block: TBlock.literal(escapeLiteral(template.substr(0, i))),
									length: i,
									start:this.pos
								};
							case literal:
								bracketStack.pop();
						}
					} else {
						 throw new ParserError( bracketMismatch, this.pos );
					}
				case '{':
					bracketStack.push(literal);
			}
		}

		return {
			block: TBlock.literal(escapeLiteral(template)),
			length: len,
			start: this.pos
		};
	}

	function escapeLiteral(input : String) : String
	{
		return StringTools.replace(input, Parser.at + Parser.at, Parser.at);
	}

	/**
	 * Takes a template string as input and returns an AST made of TBlock instances.
	 * @param	template
	 * @return
	 */
	public function parse(template : String) : Array<TBlock>
	{
		this.pos = 0;

		var output = new Array<TBlock>();
		bracketStack = [];
		conditionalStack = 0;

		while (template != '')
		{
			context = parseContext(template);
			var block = parseBlock(template);

			if(block.block != null)
				output.push(block.block);

			template = template.substr(block.length);
			this.pos += block.length;
		}

		if (bracketStack.length != 0) throw new ParserError( bracketMismatch, this.pos );

		return output;
	}

	public function parseWithPosition(template:String) : Array<Block>
	{
		this.pos = 0;

		var output = new Array<Block>();
		bracketStack = [];
		conditionalStack = 0;

		while (template != '')
		{
			context = parseContext(template);
			var block = parseBlock(template);

			if(block.block != null)
				output.push(block);

			template = template.substr(block.length);
			this.pos += block.length;
		}

		if (bracketStack.length != 0) throw new ParserError( bracketMismatch, this.pos );

		return output;
	}

	// Constructor must be put at end of class to prevent intellisense problems with regexps
	public function new()
	{
		// Some are quite simple, could be made with string functions instead for speed
#if macro
		condMatch = ~/^@(if|for|while)[^A-Za-z0-9]/;
		inConditionalMatch = ~/^(}[ \t\r\n]*else if[^A-Za-z0-9]|}[ \t\r\n]*else[ \t\r\n]*{)/;
		//variableMatch = ~/^@[_A-Za-z][\w\.]*([\(\[])?/;
		variableChar = ~/^[_A-Za-z0-9\.]$/;
#else
		condMatch = ~/^@(?:if|for|while)\b/;
		inConditionalMatch = ~/^(?:\}[\s\r\n]*else if\b|\}[\s\r\n]*else[\s\r\n]*\{)/;
		//variableMatch = ~/^@[_A-Za-z][\w\.]*([\(\[])?/;
		variableChar = ~/^[_\w\.]$/;
#end
	}
}
