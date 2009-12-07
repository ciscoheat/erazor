/**
 * ...
 * @author $(DefaultUser)
 */

package htemplate;

typedef PropertyObject = Dynamic;

class HTemplate 
{
	private var template : String;
	
	public function new(template : String)
	{
		this.template = template;
	}
	
	public function execute(content : PropertyObject) : String
	{
		var buffer = new StringBuf();
		
		var parsedBlocks = new HTemplateParser().parse(template);
		var script = new ScriptBuilder('__b__', 'add').build(parsedBlocks);
		
		var parser = new hscript.Parser();
		var program = parser.parseString(script);
		
		var interp = new hscript.Interp();
		
		for(field in Reflect.fields(content))
		{
			interp.variables.set(field, Reflect.field(content, field));
		}
		
		interp.variables.set('__b__', buffer);		
		interp.execute(program);
		
		return buffer.toString();
	}
}