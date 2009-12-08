package htemplate;

/**
 * Can be any object with properties or a Hash.
 */
typedef PropertyObject = Dynamic;

class HTemplate 
{
	private var template : String;
	
	public function new(template : String)
	{
		this.template = template;
	}
	
	public function execute(?content : PropertyObject) : String
	{
		var buffer = new StringBuf();
		
		// Parse the template into TBlocks for the HTemplateParser
		var parsedBlocks = new HTemplateParser().parse(template);
		
		// Make a hscript with the buffer as context.
		var script = new ScriptBuilder('__b__', 'add').build(parsedBlocks);
		
		// Make hscript parse and interpret the script.
		var parser = new hscript.Parser();
		var program = parser.parseString(script);
		
		var interp = new hscript.Interp();
		
		setInterpreterVars(interp, content);
		
		interp.variables.set('__b__', buffer); // Connect the buffer to the script
		interp.execute(program);

		// The buffer now holds the output.
		return buffer.toString();
	}
	
	private function setInterpreterVars(interp : hscript.Interp, content : PropertyObject) : Void
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