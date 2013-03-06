package erazor;

import hscript.Interp;
import erazor.hscript.EnhancedInterp;
#if haxe3
import haxe.ds.StringMap in Hash;
#end

/**
 * Can be any object with properties or a Hash.
 */
typedef PropertyObject = Dynamic;

class Template
{
	private var template : String;
	
	public var variables(default, null) : Hash<Dynamic>;
	
	public function new(template : String)
	{
		this.template = template;
	}
	
	public function execute(?content : PropertyObject) : String
	{
		var buffer = new StringBuf();
		
		// Parse the template into TBlocks for the HTemplateParser
		var parsedBlocks = new Parser().parse(template);
		
		// Make a hscript with the buffer as context.
		var script = new ScriptBuilder('__b__').build(parsedBlocks);
		
		// Make hscript parse and interpret the script.
		var parser = new hscript.Parser();
		var program = parser.parseString(script);
		
		var interp = new EnhancedInterp();
		
		variables = interp.variables;
		
		var bufferStack = [];
		
		setInterpreterVars(interp, content);
		
		interp.variables.set('__b__', buffer); // Connect the buffer to the script
		interp.variables.set('__string_buf__', function(current) {
			bufferStack.push(current);
			return new StringBuf();
		});
		
		interp.variables.set('__restore_buf__', function() {
			return bufferStack.pop();
		});
		
		interp.execute(program);

		// The buffer now holds the output.
		return buffer.toString();
	}
	
	private function setInterpreterVars(interp : Interp, content : PropertyObject) : Void
	{
		if(Std.is(content, Hash))
		{
			var hash : Hash<Dynamic> = cast content;
			
			for(field in hash.keys())
			{
				interp.variables.set(field, hash.get(field));
			}
		}
		else
		{
			for(field in Reflect.fields(content))
			{
				interp.variables.set(field, Reflect.field(content, field));
			}
		}
	}
}